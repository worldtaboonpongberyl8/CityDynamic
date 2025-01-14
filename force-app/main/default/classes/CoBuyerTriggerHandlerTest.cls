@isTest
public with sharing class CoBuyerTriggerHandlerTest {
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
		Account account2 = dataMaker.createAccount(recordTypeId, 'Test Co Buyer');
		Account account3 = dataMaker.createAccount(recordTypeId, 'Test Co Buyer 2');
		Account account4 = dataMaker.createAccount(recordTypeId, 'Test Co Buyer 3');
		Account account5 = dataMaker.createAccount(recordTypeId, 'Test Account for Opp');
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
	}

	@isTest
	static void afterInsertTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity targetOpp = [SELECT Id FROM Opportunity LIMIT 1];
		Account targetAcc = [SELECT Id FROM Account WHERE Name = 'Test Co Buyer' LIMIT 1];
		CoBuyer__c targetCoBuyer = dataMaker.createCoBuyer(targetOpp.Id,targetAcc.Id,'1');
		insert targetCoBuyer;
		Opportunity updatedOpportunity = [SELECT Id,CoBuyerName__c,IsCoBuyer__c FROM Opportunity WHERE Id =: targetOpp.Id LIMIT 1];
		System.assertEquals('Test Account for Opp and/or Test Co Buyer', updatedOpportunity.CoBuyerName__c);
		System.assertEquals(true, updatedOpportunity.IsCoBuyer__c);
		Account targetAcc2 = [SELECT Id FROM Account WHERE Name = 'Test Co Buyer 2' LIMIT 1];
		CoBuyer__c targetCoBuyer2 = dataMaker.createCoBuyer(targetOpp.Id,targetAcc2.Id,'2');
		insert targetCoBuyer2;
		Opportunity updatedOpportunity2 = [SELECT Id,CoBuyerName__c FROM Opportunity WHERE Id =: targetOpp.Id LIMIT 1];
		System.assertEquals('Test Account for Opp and/or Test Co Buyer and/or Test Co Buyer 2', updatedOpportunity2.CoBuyerName__c);
		Account targetAcc3= [SELECT Id FROM Account WHERE Name = 'Test Co Buyer 3' LIMIT 1];
		CoBuyer__c targetCoBuyer3 = dataMaker.createCoBuyer(targetOpp.Id,targetAcc3.Id,'1');
		insert targetCoBuyer3;
		Opportunity updatedOpportunity3 = [SELECT Id,CoBuyerName__c FROM Opportunity WHERE Id =: targetOpp.Id LIMIT 1];
		System.assertEquals('Test Account for Opp and/or Test Co Buyer and/or Test Co Buyer 3 and/or Test Co Buyer 2', updatedOpportunity3.CoBuyerName__c);
		Test.stopTest();
	}

	@isTest
	static void afterUpdateTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity targetOpp = [SELECT Id FROM Opportunity LIMIT 1];
		Account targetAcc = [SELECT Id FROM Account WHERE Name = 'Test Co Buyer' LIMIT 1];
		CoBuyer__c targetCoBuyer = dataMaker.createCoBuyer(targetOpp.Id,targetAcc.Id,'1');
		insert targetCoBuyer;
		Account targetAcc2 = [SELECT Id FROM Account WHERE Name = 'Test Co Buyer 2' LIMIT 1];
		CoBuyer__c targetCoBuyer2 = dataMaker.createCoBuyer(targetOpp.Id,targetAcc2.Id,'2');
		insert targetCoBuyer2;
		CoBuyer__c updatedCoBuyer2 = [SELECT Id,Priority__c FROM CoBuyer__c WHERE Id =: targetCoBuyer2.Id LIMIT 1];
		updatedCoBuyer2.Priority__c = '1';
		update updatedCoBuyer2;
		Opportunity updatedOpportunity = [SELECT Id,CoBuyerName__c FROM Opportunity WHERE Id =: targetOpp.Id LIMIT 1];
		System.assertEquals('Test Account for Opp and/or Test Co Buyer and/or Test Co Buyer 2', updatedOpportunity.CoBuyerName__c);
		CoBuyer__c updatedCoBuyer1 = [SELECT Id,Priority__c FROM CoBuyer__c WHERE Id =: targetCoBuyer.Id LIMIT 1];
		updatedCoBuyer1.Priority__c = '2';
		update updatedCoBuyer1;
		Opportunity updatedOpportunity2 = [SELECT Id,CoBuyerName__c FROM Opportunity WHERE Id =: targetOpp.Id LIMIT 1];
		System.assertEquals('Test Account for Opp and/or Test Co Buyer 2 and/or Test Co Buyer', updatedOpportunity2.CoBuyerName__c);
		Test.stopTest();
	}

	@isTest
	static void afterDeleteTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity targetOpp = [SELECT Id FROM Opportunity LIMIT 1];
		Account targetAcc = [SELECT Id FROM Account WHERE Name = 'Test Co Buyer' LIMIT 1];
		CoBuyer__c targetCoBuyer = dataMaker.createCoBuyer(targetOpp.Id,targetAcc.Id,'1');
		insert targetCoBuyer;
		Account targetAcc2 = [SELECT Id FROM Account WHERE Name = 'Test Co Buyer 2' LIMIT 1];
		CoBuyer__c targetCoBuyer2 = dataMaker.createCoBuyer(targetOpp.Id,targetAcc2.Id,'2');
		insert targetCoBuyer2;
		Account targetAcc3= [SELECT Id FROM Account WHERE Name = 'Test Co Buyer 3' LIMIT 1];
		CoBuyer__c targetCoBuyer3 = dataMaker.createCoBuyer(targetOpp.Id,targetAcc3.Id,'1');
		insert targetCoBuyer3;
		CoBuyer__c deleteCoBuyer = [SELECT Id FROM CoBuyer__c WHERE Id =: targetCoBuyer2.Id];
		delete deleteCoBuyer;
		Opportunity updatedOpportunity = [SELECT Id,CoBuyerName__c FROM Opportunity WHERE Id =: targetOpp.Id LIMIT 1];
		System.assertEquals('Test Account for Opp and/or Test Co Buyer and/or Test Co Buyer 3', updatedOpportunity.CoBuyerName__c);
		CoBuyer__c deleteCoBuyer2 = [SELECT Id FROM CoBuyer__c WHERE Id =: targetCoBuyer.Id];
		delete deleteCoBuyer2;
		Opportunity updatedOpportunity2 = [SELECT Id,CoBuyerName__c FROM Opportunity WHERE Id =: targetOpp.Id LIMIT 1];
		System.assertEquals('Test Account for Opp and/or Test Co Buyer 3', updatedOpportunity2.CoBuyerName__c);
		CoBuyer__c deleteCoBuyer3 = [SELECT Id FROM CoBuyer__c WHERE Id =: targetCoBuyer3.Id];
		delete deleteCoBuyer3;
		Opportunity updatedOpportunity3 = [SELECT Id,CoBuyerName__c,IsCoBuyer__c FROM Opportunity WHERE Id =: targetOpp.Id LIMIT 1];
		System.assertEquals('Test Account for Opp', updatedOpportunity3.CoBuyerName__c);
		System.assertEquals(false, updatedOpportunity3.IsCoBuyer__c);
		Test.stopTest();
	}

	@isTest
	static void setBypassTest(){
		Test.startTest();
		CoBuyerTriggerHandler handler = CoBuyerTriggerHandler.getInstance();
		handler.setBypass();
		System.assertEquals(false, handler.isActive);
		System.assertEquals(false, handler.isTriggerActivated());
		Test.stopTest();
	}

	@isTest
	static void clearBypassTest(){
		Test.startTest();
		CoBuyerTriggerHandler handler = CoBuyerTriggerHandler.getInstance();
		handler.clearBypass();
		System.assertEquals(true, handler.isActive);
		System.assertEquals(true, handler.isTriggerActivated());
		Test.stopTest();
	}
}