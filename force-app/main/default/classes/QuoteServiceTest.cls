@isTest
public with sharing class QuoteServiceTest {
	@TestSetup
	static void makeData(){
		DataMaker dataMaker = DataMaker.getInstance();
		// Create Project
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert testProject;
		// Craete Floor
		Floor__c testFloor = dataMaker.createFloor('Test Floor', 'FF01', testProject.Id);
		insert testFloor;
		// Create Unit Type
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type', testProject.Id);
		insert unitType;
		// Create Unit
		Product2 testProduct = dataMaker.createUnit(
			'Test Product',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		testProduct.ReservationPrice__c = 10000;
		insert testProduct;
		// Create Pricebook Entry
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 15000000, 20000000,10000000);
		testPricebookEntry1.Pricebook2Id = pricebookId;
		testPricebookEntry1.UseStandardPrice = false;
		insert testPricebookEntry1;
		// Creat Account
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
		insert account;
		PaymentTermMaster__c paymentTermMasterNew = dataMaker.craetePaymentTermMaster(testProject.Id,'TQ Series 5-10-85', 'Series', 'Thai', 25);
		insert paymentTermMasterNew;
		List<PaymentTerm__c> paymentTermWrappers = new List<PaymentTerm__c>();
		PaymentTerm__c paymentTarm1 = dataMaker.createPaymentTermLineItem(
			paymentTermMasterNew.Id,
			1,
			null,
			10,
			'Contract'
		);
		PaymentTerm__c paymentTarm2 = dataMaker.createPaymentTermLineItem(
			paymentTermMasterNew.Id,
			2,
			null,
			20,
			'Installment 1'
		);
		PaymentTerm__c paymentTarm3 = dataMaker.createPaymentTermLineItem(
			paymentTermMasterNew.Id,
			3,
			null,
			null,
			'Transfer'
		);
		paymentTermWrappers.add(paymentTarm1);
		paymentTermWrappers.add(paymentTarm2);
		paymentTermWrappers.add(paymentTarm3);
		insert paymentTermWrappers;
		// Create Opportunity
		List<Opportunity> opportunities = new List<Opportunity>{
			dataMaker.createOpportunity(
				account.Id,
				'Omitted',
				'Test Opp',
				Date.today(),
				'Open',
				testProduct.Id,
				'Thai',
				paymentTermMasterNew.Id,
				testProject.Id
			)
		};
		insert opportunities;
		Quote__c testQuote = dataMaker.createQuote(
			opportunities[0].Id
		);
		testQuote.DiscountPercent__c = 10;
		testQuote.DiscountAmount__c = 0;
		insert testQuote;
	}
	@isTest
	static void generateQuotesFromOpportunitiesTest(){
		Test.startTest();
		List<Opportunity> testOpp = getOppsForTest();
		QuoteService service = QuoteService.getInstance();
		List<Quote__c> quotes = service.generateQuotesFromOpportunities(testOpp);
		System.assertEquals(testOpp.size(), quotes.size());
		for (Integer i = 0 ; i < quotes.size() ; i++){
			System.assertEquals(testOpp[i].Id, quotes[i].Opportunity__c);
			System.assertEquals(testOpp[i].DiscountPercent__c, quotes[i].DiscountPercent__c);
			System.assertEquals(testOpp[i].PaymentTermMaster__c, quotes[i].PaymentTerm__c);
			System.assertEquals(testOpp[i].DiscountAmount__c, quotes[i].DiscountAmount__c);
			System.assertEquals(testOpp[i].DiscountPercentOfAmount__c, quotes[i].DiscountPercentOfAmount__c);
			System.assertEquals(testOpp[i].TotalDiscountPercent__c, quotes[i].TotalDiscountPercent__c);
			System.assertEquals(testOpp[i].NetPrice__c, quotes[i].TotalPrice__c);
			System.assertEquals(testOpp[i].UnitPrice__c, quotes[i].UnitPrice__c);
			System.assertEquals(testOpp[i].TotalDiscountAmount__c, quotes[i].TotalDiscountAmount__c);
			System.assertEquals(testOpp[i].AccountId, quotes[i].Opportunity__c);
			System.assertEquals(testOpp[i].ContractId, quotes[i].ContactName__c);
			System.assertEquals(testOpp[i].Project__c, quotes[i].ProjectName__c);
			System.assertEquals(testOpp[i].Unit__c, quotes[i].Opportunity__c);

		}
		Test.stopTest();
	}
	@isTest
	static void stampDiscountFromSyncedQuoteToOpportunityTest(){
		Test.startTest();
		List<Quote__c> quotes = [SELECT Id,Opportunity__c , IsSyncing__c,DiscountPercent__c ,DiscountAmount__c FROM Quote__c];
		QuoteService serviceQuote = QuoteService.getInstance();
		List<Opportunity> results = serviceQuote.stampDiscountFromSyncedQuoteToOpportunity(quotes);
		System.assertEquals(results[0].DiscountPercent__c, quotes[0].DiscountPercent__c);
		System.assertEquals(results[0].DiscountAmount__c, quotes[0].DiscountAmount__c);

		Test.stopTest();
	}
	@isTest
	static void getMapForSyncQuoteToOppTest(){
		Test.startTest();
		List<Quote__c> quotes = [SELECT Id,Opportunity__c , IsSyncing__c,DiscountPercent__c ,DiscountAmount__c FROM Quote__c];
		QuoteService serviceQuote = QuoteService.getInstance();
		Map<String, SObject> resultMaps = serviceQuote.getMapForSyncQuoteToOpp(quotes);
		Opportunity opp = [SELECT Id,SyncedQuoteId__c FROM Opportunity LIMIT 1];
		Quote__c resultQuote = (Quote__c) resultMaps.get('Quote__c');
		Opportunity resultOpp = (Opportunity) resultMaps.get('Opportunity');
		System.assertEquals(true, resultQuote.IsSyncing__c);
		System.assertEquals(resultOpp.SyncedQuoteId__c, quotes[0].Id);

		Test.stopTest();
	}

	@isTest
	static void unsetSyncedQuoteFromOthersTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		QuoteService serviceQuote = QuoteService.getInstance();
		List<Quote__c> quotes = [SELECT Id,Opportunity__c , IsSyncing__c,DiscountPercent__c ,DiscountAmount__c FROM Quote__c];
		Map<String, SObject> resultMaps = serviceQuote.getMapForSyncQuoteToOpp(quotes);
		Quote__c resultQuote = (Quote__c) resultMaps.get('Quote__c');
		update resultQuote;
		Opportunity resultOpp = (Opportunity) resultMaps.get('Opportunity');
		update resultOpp;
		Quote__c newSyncedQuote = dataMaker.createQuote(
			resultOpp.Id
		);
		newSyncedQuote.IsSyncing__c = true;
		List<Quote__c> updatedQuotes = serviceQuote.unsetSyncedQuoteFromOthers(new List<Quote__c>{newSyncedQuote});
		for (Quote__c quote : updatedQuotes){
			if (quote.Id == resultQuote.Id){
				System.assertEquals(false, quote.IsSyncing__c);
			}
		}
		Test.stopTest();
	}

	private static List<Opportunity> getOppsForTest() {
		DataMaker dataMaker = DataMaker.getInstance();
		return new List<Opportunity>{
			dataMaker.createOpportunity(null, 'Omitted', 'Test Opp', Date.today(), 'Open',null,'Foreign',null,null),
			dataMaker.createOpportunity(null, 'Omitted', 'Test Opp', Date.today(), 'Open',null,'Thai',null,null)
		};
	}
}