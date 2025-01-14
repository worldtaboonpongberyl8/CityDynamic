@isTest
public with sharing class OpportunityServiceTest {
	@TestSetup
	static void makeData() {
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
		insert account;
		Account account2 = dataMaker.createAccount(recordTypeId, 'Test Account 2');
		insert account2;
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 150000, 200000,10000000);
		testPricebookEntry1.Pricebook2Id = pricebookId;
		testPricebookEntry1.UseStandardPrice = false;
		insert testPricebookEntry1;
		PricebookEntry testPricebookEntry2 = dataMaker.createPricebookEntries(testProduct2.Id, 150000, 200000,10000000);
		testPricebookEntry2.Pricebook2Id = pricebookId;
		testPricebookEntry2.UseStandardPrice = false;
		insert testPricebookEntry2;
		// Create Opportunity
		OpportunityTriggerHandler oppTriggerHandler = OpportunityTriggerHandler.getInstance();
		oppTriggerHandler.setBypass();
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
		Opportunity opportunity2 = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp with Unit 2',
			Date.today(),
			'Open', //Reservation
			testProduct2.Id,
			'Foreign',
			null,
			testProject.Id
		);
		Opportunity opportunity3 = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp with Unit 3',
			Date.today(),
			'Open', //Transfer
			testProduct3.Id,
			'Foreign',
			null,
			testProject.Id
		);
		List<Opportunity> opportunities = new List<Opportunity>{ opportunity1, opportunity2, opportunity3 };
		insert opportunities;
		oppTriggerHandler.clearBypass();
	}

	@isTest
	static void assignUnitPriceTQToOpportunityTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'PP01'];
		Opportunity opp = [SELECT Id , AccountId ,Name ,ForecastCategoryName,CloseDate,Unit__c,Quota__c,StageName,PaymentTermMaster__c,NetPrice__c FROM Opportunity WHERE Unit__c =: product.Id AND Quota__c = 'Thai'];
		List<Opportunity> oppList = new List<Opportunity>();
		oppList.add(opp);
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> result = service.assignUnitPriceToOpportunity(oppList);
		System.assertEquals(150000, result[0].UnitPrice__c);
		Test.stopTest();
	}
	@isTest
	static void assignUnitPriceFQToOpportunityTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'PP02'];
		Opportunity opp = [SELECT Id , AccountId ,Name ,ForecastCategoryName,CloseDate,Unit__c,Quota__c,StageName,PaymentTermMaster__c,NetPrice__c FROM Opportunity WHERE Unit__c =: product.Id AND Quota__c = 'Foreign'];
		List<Opportunity> oppList = new List<Opportunity>();
		oppList.add(opp);
		System.debug('Size Opp: '+oppList.size());
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> result = service.assignUnitPriceToOpportunity(oppList);
		System.assertEquals(200000, result[0].UnitPrice__c);
		Test.stopTest();
	}

	@isTest
	static void stampOpportunitiesNameTest() {
		Test.startTest();
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> originalOpportunities = [
			SELECT Id, Name, Project__r.Name, Unit__r.ProductCode, AccountName__c
			FROM Opportunity
		];
		List<Opportunity> opportunities = [
			SELECT Id, Name, Project__r.Name, Unit__r.ProductCode, AccountName__c, OppNameFormat__c
			FROM Opportunity
		];
		service.stampOpportunitiesName(opportunities);
		for (Integer i = 0; i < opportunities.size(); i++) {
			System.assertNotEquals(originalOpportunities[i].Name, opportunities[i].Name);
		}
		Test.stopTest();
	}

	@isTest
	static void stampCoBuyerNameTest() {
		Test.startTest();
		OpportunityService service = OpportunityService.getInstance();
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity originalOpportunities = [
			SELECT Id, AccountName__c, CoBuyerName__c, IsCoBuyer__c
			FROM Opportunity
			LIMIT 1
		];
		Opportunity targetOpp = [SELECT Id, AccountName__c, CoBuyerName__c, IsCoBuyer__c FROM Opportunity LIMIT 1];
		Account targetAcc = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
		CoBuyer__c targetCoBuyer = dataMaker.createCoBuyer(targetOpp.Id, targetAcc.Id, '1');
		insert targetCoBuyer;
		List<Opportunity> opportunities = service.stampCoBuyerName(new List<Opportunity>{targetOpp});
		Opportunity updatedOpp = opportunities[0];
		System.assertEquals(true,updatedOpp.IsCoBuyer__c);
		System.assertNotEquals(originalOpportunities.CoBuyerName__c,updatedOpp.CoBuyerName__c);
		Test.stopTest();
	}
	@isTest
	static void stampContractAmountAndPercentTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Account targetAccount = [SELECT Id FROM Account LIMIT 1];
		Product2 targetUnit1 = [SELECT Id,TransferredDate__c,Status__c FROM Product2 WHERE ProductCode = 'PP01' LIMIT 1 ];
		PaymentTermMaster__c paymentTermMaster = [SELECT Id FROM PaymentTermMaster__c WHERE Quota__c = 'Thai'];
		Project__c targetProject = [SELECT Id FROM Project__c WHERE ProjectCode__c = 'AA01' LIMIT 1];
		Opportunity opp1 = [SELECT Id , ContractAmount__c,ContractPercent__c,PaymentTermMaster__c FROM Opportunity WHERE Name = 'Test Opp with Unit 1'];
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> result = service.stampContractAmountAndPercent(new List<Opportunity>{opp1});
		System.debug('Test Result Contract '+result);
		System.assertEquals(10000, result[0].ContractAmount__c);
		System.assertEquals(0, result[0].ContractPercent__c);
		Test.stopTest();
	}
	@isTest
	static void stampTotalInstallmentAmountAndPercentTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Account targetAccount = [SELECT Id FROM Account LIMIT 1];
		Product2 targetUnit1 = [SELECT Id,TransferredDate__c,Status__c FROM Product2 WHERE ProductCode = 'PP01' LIMIT 1 ];
		PaymentTermMaster__c paymentTermMaster = [SELECT Id FROM PaymentTermMaster__c WHERE Quota__c = 'Thai'];
		Project__c targetProject = [SELECT Id FROM Project__c WHERE ProjectCode__c = 'AA01' LIMIT 1];
		Opportunity opp1 = [SELECT Id , TotalInstallmentAmount__c,TotalInstallmentPercent__c,PaymentTermMaster__c FROM Opportunity WHERE Name = 'Test Opp with Unit 1'];

		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> result = service.stampTotalInstallmentAmountAndPercent(new List<Opportunity>{opp1});
		System.debug('Test Result Installment '+result);
		System.assertEquals(60000, result[0].TotalInstallmentAmount__c);
		System.assertEquals(0, result[0].TotalInstallmentPercent__c);
		Test.stopTest();
	}
}