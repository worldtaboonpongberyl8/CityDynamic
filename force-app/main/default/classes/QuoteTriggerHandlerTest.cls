@isTest
public with sharing class QuoteTriggerHandlerTest {
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
			'Test Product 1',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		testProduct.ReservationPrice__c = 5000;
		Product2 testProduct2 = dataMaker.createUnit(
			'Test Product 2',
			'PP02',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		Product2 testProduct3 = dataMaker.createUnit(
			'Test Product 3',
			'PP03',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		List<Product2> products = new List<Product2>{ testProduct, testProduct2, testProduct3 };
		insert products;
		// Create Pricebook Entry
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 15000000, 20000000,10000000);
		testPricebookEntry1.Pricebook2Id = pricebookId;
		testPricebookEntry1.UseStandardPrice = false;
		insert testPricebookEntry1;
		// Create Promotion Master
		PromotionMaster__c promotionMaster = dataMaker.craeteActivePromotionMaster(testProject.Id,testProduct.Id,'ส่วนลด','Sales','Discount (ส่วนลด)','Add Detail','Description',500.00);
		insert promotionMaster;
		// create Payment Term Master
		PaymentTermMaster__c paymentTermMaster = dataMaker.craetePaymentTermMaster(
			testProject.Id,
			'TQ Series 5-10-85',
			'Series',
			'Thai',
			25
		);
		insert paymentTermMaster;
		// create Payment Term Line Item
		List<PaymentTerm__c> paymentTermLineItems = new List<PaymentTerm__c>();
		PaymentTerm__c contractPaymentTerm = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			1,
			10000,
			null,
			'Contract'
		);
		paymentTermLineItems.add(contractPaymentTerm);
		for (Integer i = 0; i < 12; i++) {
			PaymentTerm__c installmentPaymentTerm = dataMaker.createPaymentTermLineItem(
				paymentTermMaster.Id,
				i + 2,
				5000,
				null,
				'Installment ' + String.valueOf(i + 1)
			);
			paymentTermLineItems.add(installmentPaymentTerm);
		}
		PaymentTerm__c transferPaymentTerm = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			13,
			null,
			null,
			'Transfer'
		);
		paymentTermLineItems.add(transferPaymentTerm);
		insert paymentTermLineItems;
		// Create Account
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
		Account account2 = dataMaker.createAccount(recordTypeId, 'Test Co Buyer');
		Account account3 = dataMaker.createAccount(recordTypeId, 'Test Co Buyer 2');
		Account account4 = dataMaker.createAccount(recordTypeId, 'Test Co Buyer 3');
		List<Account> accounts = new List<Account>{ account, account2, account3, account4 };
		insert accounts;
		// Create Opportunity
		OpportunityTriggerHandler oppTriggerHandler = OpportunityTriggerHandler.getInstance();
		// oppTriggerHandler.setBypass();
		Opportunity opportunity1 = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp with Unit 1',
			Date.today(),
			'Open',
			testProduct.Id,
			'Thai',
			paymentTermMaster.Id,
			testProject.Id
		);
		opportunity1.DiscountAmount__c = 50;
		List<Opportunity> opportunities = new List<Opportunity>{ opportunity1 };
		insert opportunities;
		// oppTriggerHandler.clearBypass();
		// Create Quote
		Quote__c targetQuote = dataMaker.createQuote(opportunity1.Id);
		targetQuote.DiscountAmount__c = 100;
		targetQuote.DiscountPercent__c = 1;
		Quote__c targetQuote2 = dataMaker.createQuote(opportunity1.Id);
		targetQuote2.DiscountAmount__c = 200;
		targetQuote2.DiscountPercent__c = 2;
		List<Quote__c> quotes = new List<Quote__c>{targetQuote,targetQuote2};
		insert quotes;
		// Craete Client Offer
		ClientOffer__c clientOffer = dataMaker.createClientOffer(promotionMaster.Id,opportunity1.Id,null);
		insert clientOffer;
	}

	@isTest
	static void insertQuoteTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c targetProject = [SELECT Id FROM Project__c WHERE ProjectCode__c = 'AA01' LIMIT 1];
		Opportunity opp1 = [SELECT Id , TotalInstallmentAmount__c,TotalInstallmentPercent__c,PaymentTermMaster__c FROM Opportunity WHERE Project__c =: targetProject.Id LIMIT 1];
		List<OpportunityPayment__c> oppPayments = [SELECT Id,Amount__c FROM OpportunityPayment__c WHERE Opportunity__c =: opp1.Id AND IsMasterData__c = true ORDER BY Order__c ];
		Quote__c targetQuote = dataMaker.createQuote(opp1.Id);
		insert targetQuote;
		List<OpportunityPayment__c> resultOppPayments = [SELECT Id,Amount__c,Opportunity__c FROM OpportunityPayment__c WHERE Quote__c =: targetQuote.Id ORDER BY Order__c];
		System.assertEquals(oppPayments.size(), resultOppPayments.size());
		for (Integer i = 0 ; i < resultOppPayments.size(); i++) {
			System.assertEquals(oppPayments[i].Amount__c, resultOppPayments[i].Amount__c);
			System.assertEquals(opp1.Id, resultOppPayments[i].Opportunity__c);
		}
		Test.stopTest();
	}

	@isTest
	static void updateQuoteTest(){
		Test.startTest();
		Opportunity originalOpportunity = [SELECT Id,DiscountAmount__c,DiscountPercent__c FROM Opportunity LIMIT 1];
		Quote__c targetQuote = [SELECT Id, DiscountAmount__c,DiscountPercent__c FROM Quote__c WHERE DiscountAmount__c = 100 LIMIT 1];
		targetQuote.IsSyncing__c = true;
		OpportunityTriggerHandler oppTriggerHandler = OpportunityTriggerHandler.getInstance();
		// oppTriggerHandler.setBypass();
		update targetQuote;
		// oppTriggerHandler.clearBypass();
		Quote__c syncedQuote = [SELECT Id, DiscountAmount__c,DiscountPercent__c FROM Quote__c WHERE DiscountAmount__c = 100 LIMIT 1];
		Quote__c unsyncedQuote = [SELECT Id, DiscountAmount__c,DiscountPercent__c FROM Quote__c WHERE DiscountAmount__c = 200 LIMIT 1];
		Opportunity updatedOpportunity = [SELECT Id,DiscountAmount__c,DiscountPercent__c FROM Opportunity LIMIT 1];
		System.assertNotEquals(originalOpportunity.DiscountAmount__c , updatedOpportunity.DiscountAmount__c);
		System.assertNotEquals(originalOpportunity.DiscountPercent__c , updatedOpportunity.DiscountPercent__c);
		System.assertEquals(syncedQuote.DiscountAmount__c, updatedOpportunity.DiscountAmount__c);
		System.assertEquals(syncedQuote.DiscountPercent__c, updatedOpportunity.DiscountPercent__c);
		System.assertNotEquals(unsyncedQuote.DiscountAmount__c, updatedOpportunity.DiscountAmount__c);
		System.assertNotEquals(unsyncedQuote.DiscountPercent__c, updatedOpportunity.DiscountPercent__c);
		unsyncedQuote.IsSyncing__c = true;
		update unsyncedQuote;
		Opportunity newUpdatedOpportunity = [SELECT Id,DiscountAmount__c,DiscountPercent__c,SyncedQuoteId__c FROM Opportunity LIMIT 1];
		Quote__c newUnsyncedQuote = [SELECT Id, DiscountAmount__c,DiscountPercent__c,IsSyncing__c FROM Quote__c WHERE DiscountAmount__c = 100 LIMIT 1];
		Quote__c newSyncedQuote = [SELECT Id, DiscountAmount__c,DiscountPercent__c,IsSyncing__c FROM Quote__c WHERE DiscountAmount__c = 200 LIMIT 1];
		System.assertEquals(syncedQuote.Id, newUnsyncedQuote.Id);
		System.assertEquals(false, newUnsyncedQuote.IsSyncing__c);
		System.assertEquals(unsyncedQuote.Id, newSyncedQuote.Id);
		System.assertEquals(true, newSyncedQuote.IsSyncing__c);
		Test.stopTest();
	}

	@isTest
	static void setBypassTest(){
		Test.startTest();
		QuoteTriggerHandler handler = QuoteTriggerHandler.getInstance();
		handler.setBypass();
		System.assertEquals(false, handler.isActive);
		System.assertEquals(false, handler.isTriggerActivated());
		Test.stopTest();
	}

	@isTest
	static void clearBypassTest(){
		Test.startTest();
		QuoteTriggerHandler handler = QuoteTriggerHandler.getInstance();
		handler.clearBypass();
		System.assertEquals(true, handler.isActive);
		System.assertEquals(true, handler.isTriggerActivated());
		Test.stopTest();
	}

}