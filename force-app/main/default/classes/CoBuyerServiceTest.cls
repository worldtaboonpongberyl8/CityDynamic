@isTest
public with sharing class CoBuyerServiceTest {
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
		List<Product2> products = new List<Product2>{testProduct,testProduct2,testProduct3};
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
		account.AccountCode__c = '1111';
		Account account2 = dataMaker.createAccount(recordTypeId, 'Test Co Buyer');
		account2.AccountCode__c = '2222';
		Account account3 = dataMaker.createAccount(recordTypeId, 'Test Co Buyer 2');
		Account account4 = dataMaker.createAccount(recordTypeId, 'Test Co Buyer 3');
		account4.AccountCode__c = '9999';
		Account account5 = dataMaker.createAccount(recordTypeId, 'Test Account for Opp');
		account5.AccountCode__c = '1234';
		List<Account> accounts = new List<Account>{account,account2,account3,account4,account5};
		insert accounts;
		// Create Opportunity
		OpportunityTriggerHandler oppTriggerHandler = OpportunityTriggerHandler.getInstance();
		oppTriggerHandler.setBypass();
		Opportunity opportunity1 = dataMaker.createOpportunity(
			account5.Id,
			'Omitted',
			'Test Opp with Unit 1',
			Date.today(),
			'Open',
			testProduct.Id,
			'Foreign',
			null,
			testProject.Id
		);
		Opportunity opportunity2 = dataMaker.createOpportunity(
			account5.Id,
			'Omitted',
			'Test Opp with Unit 2',
			Date.today(),
			'Open',
			testProduct2.Id,
			'Foreign',
			null,
			testProject.Id
		);
		Opportunity opportunity3 = dataMaker.createOpportunity(
			account5.Id,
			'Omitted',
			'Test Opp with Unit 3',
			Date.today(),
			'Open',
			testProduct3.Id,
			'Foreign',
			null,
			testProject.Id
		);
		List<Opportunity> opportunities = new List<Opportunity>{opportunity1,opportunity2,opportunity3};
		insert opportunities;
		oppTriggerHandler.clearBypass();
		// insert Co buyer
		CoBuyer__c targetCoBuyer = dataMaker.createCoBuyer(opportunity1.Id,account.Id,'1');
		CoBuyer__c targetCoBuyer2 = dataMaker.createCoBuyer(opportunity1.Id,account2.Id,'2');
		List<CoBuyer__c> targetCobuyers = new List<CoBuyer__c>{targetCoBuyer,targetCoBuyer2};
		insert targetCobuyers;
	}

	@isTest
	static void stampOppCoBuyerNameAndFlagTest(){
		Test.startTest();
		CoBuyerService service = CoBuyerService.getInstance();
		List<CoBuyer__c> coBuyers = [SELECT Id,Opportunity__c FROM CoBuyer__c];
		List<Opportunity> opportunities = service.stampOppCoBuyerNameAndFlag(coBuyers);
		System.assertEquals(1, opportunities.size());
		System.assertEquals('Test Account for Opp and/or Test Account and/or Test Co Buyer', opportunities[0].CoBuyerName__c);
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - add test method for getStringCoBuyerAccountCode
	 */
	@isTest
	static void getStringCoBuyerAccountCodeTest(){
		Test.startTest();
		CoBuyerService service = CoBuyerService.getInstance();
		List<CoBuyer__c> coBuyers = [SELECT Id,Opportunity__c,Customer__r.AccountCode__c FROM CoBuyer__c];
		String accountCodeString = service.getStringCoBuyerAccountCode(coBuyers);
		System.assertEquals('1111,2222', accountCodeString);
		Test.stopTest();
	}
}