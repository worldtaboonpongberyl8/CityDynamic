@isTest
public with sharing class ContractTriggerHandlerTest {
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
		// Create Promotion Master
		PromotionMaster__c promotionMaster = dataMaker.craeteActivePromotionMaster(testProject.Id,testProduct.Id,'ส่วนลด','Sales','Discount (ส่วนลด)','Add Detail','Description',500.00);
		insert promotionMaster;
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
		oppTriggerHandler.setBypass();
		Opportunity opportunity1 = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp with Unit 1',
			Date.today(),
			'Open',
			testProduct.Id,
			'Foreign',
			null,
			testProject.Id
		);
		List<Opportunity> opportunities = new List<Opportunity>{ opportunity1 };
		insert opportunities;
		oppTriggerHandler.clearBypass();
		// Create Quote
		Quote__c targetSyncedQuote = dataMaker.createQuote(opportunity1.Id);
		targetSyncedQuote.IsSyncing__c = true;
		insert targetSyncedQuote;
		// Craete Client Offer
		ClientOffer__c clientOffer = dataMaker.createClientOffer(promotionMaster.Id,opportunity1.Id,null);
		insert clientOffer;
	}

	@isTest 
	static void insertContractTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity targetOpp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
		ClientOffer__c originalClientOffer = [SELECT Id,Contract__c FROM ClientOffer__c LIMIT 1];
		Contract contract = dataMaker.createContract(targetOpp.Id,targetOpp.AccountId);
		insert contract;
		Contract insertedContract = [SELECT Id,Name,FormatContractName__c FROM Contract LIMIT 1];
		ClientOffer__c updatedClientOffer = [SELECT Id,Contract__c FROM ClientOffer__c LIMIT 1];
		System.assertEquals(insertedContract.FormatContractName__c, insertedContract.Name);
		System.assertEquals(null, originalClientOffer.Contract__c);
		System.assertNotEquals(null, updatedClientOffer.Contract__c);
		System.assertEquals(insertedContract.Id, updatedClientOffer.Contract__c);
		Test.stopTest();
	}

	@isTest 
	static void updateContractTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity targetOpp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
		OpportunityPayment__c contractOppPayment = dataMaker.createOpportunityPayment(
			targetOpp.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 27),
			2
		);
		contractOppPayment.Amount__c = 100000;
		contractOppPayment.ReceivedAmount__c = 100000;
		insert contractOppPayment;
		ClientOffer__c originalClientOffer = [SELECT Id,Contract__c FROM ClientOffer__c LIMIT 1];
		Contract contract = dataMaker.createContract(targetOpp.Id,targetOpp.AccountId);
		insert contract;
		Contract insertedContract = [SELECT Id,Name,FormatContractName__c,Status FROM Contract LIMIT 1];
		insertedContract.Status = 'Signed Contract';
		insertedContract.ContractSignedDate__c = Date.today();
		update insertedContract;
		Contract updatedContract = [SELECT Id,Name,FormatContractName__c,Status FROM Contract LIMIT 1];
		Opportunity updatedOpportunity = [SELECT Id,AccountId,IsCompletedContract__c  FROM Opportunity LIMIT 1];
		System.assertEquals(true, updatedOpportunity.IsCompletedContract__c);
		Test.stopTest();
	}

	@isTest 
	static void setBypassTest(){
		Test.startTest();
		ContractTriggerHandler handler = ContractTriggerHandler.getInstance();
		handler.setBypass();
		System.assertEquals(false, handler.isActive);
		System.assertEquals(false, handler.isTriggerActivated());
		Test.stopTest();
	}

	@isTest 
	static void clearBypassTest(){
		Test.startTest();
		ContractTriggerHandler handler = ContractTriggerHandler.getInstance();
		handler.clearBypass();
		System.assertEquals(true, handler.isActive);
		System.assertEquals(true, handler.isTriggerActivated());
		Test.stopTest();
	} 
}