@isTest
private class Product2ServiceTest {
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
		insert testProduct;
		Product2 testProduct2 = dataMaker.createUnit(
			'Test Product 2',
			'PP02',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert testProduct2;
		Product2 testProduct3 = dataMaker.createUnit(
			'Test Product 3',
			'PP03',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert testProduct3;
		// create Payment Term Master
		PaymentTermMaster__c paymentTermMaster = dataMaker.craetePaymentTermMaster(
			testProject.Id,
			'FQ Series 5-10-85',
			'Series',
			'Foreign',
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
		insert opportunity1;
		Opportunity opportunity2 = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct2.Id,
			'Foreign',
			paymentTermMaster.Id,
			testProject.Id
		);
		opportunity2.ReservationDueDate__c = Date.today();
		insert opportunity2;
		opportunity2.StageName = 'Reservation';
		update opportunity2;

		Opportunity opportunity3 = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp with Unit 3',
			Date.today(),
			'Open',
			testProduct3.Id,
			'Foreign',
			paymentTermMaster.Id,
			testProject.Id
		);
		opportunity3.ReservationDueDate__c = Date.today();
		insert opportunity3;
		opportunity3.StageName = 'Reservation';
		update opportunity3;
		Contract contract = dataMaker.createContract(opportunity3.Id,account.Id);
		insert contract;
		contract.Status = 'Signed Contract';
		contract.ContractSignedDate__c = Date.today();
		update contract;
		opportunity3.StageName = 'Contract';
		update opportunity3;
		Opportunity targetOppAfterInsert3 = [
			SELECT Id, Unit__c, Quota__c, PaymentTermMaster__c
			FROM Opportunity
			WHERE Id = :opportunity3.Id
			LIMIT 1
		];
		targetOppAfterInsert3.TransferredDate__c = Date.today();
		targetOppAfterInsert3.StageName = 'Transferred';
		System.debug('Test--Quota' + targetOppAfterInsert3.Quota__c);
		System.debug('Test--PaymentTermMaster ' + targetOppAfterInsert3.PaymentTermMaster__c);
		update targetOppAfterInsert3;

		Opportunity opportunity4 = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp with Unit 4',
			Date.today(),
			'Open',
			testProduct3.Id,
			'Foreign',
			paymentTermMaster.Id,
			testProject.Id
		);
		opportunity4.ReservationDueDate__c = Date.today();
		insert opportunity4;
		opportunity4.StageName = 'Reservation';
		update opportunity4;
		Contract contract2 = dataMaker.createContract(opportunity4.Id,account.Id);
		insert contract2;
		contract2.Status = 'Signed Contract';
		contract2.ContractSignedDate__c = Date.today();
		update contract2;
		opportunity4.StageName = 'Contract';
		update opportunity4;
		Opportunity targetOppAfterInsert4 = [
			SELECT Id, Unit__c, Quota__c, PaymentTermMaster__c
			FROM Opportunity
			WHERE Id = :opportunity4.Id
			LIMIT 1
		];
		targetOppAfterInsert4.TransferredDate__c = Date.today();
		targetOppAfterInsert4.StageName = 'Transferred';
		System.debug('Test--Quota' + targetOppAfterInsert3.Quota__c);
		System.debug('Test--PaymentTermMaster ' + targetOppAfterInsert4.PaymentTermMaster__c);
		update targetOppAfterInsert4;
		Opportunity targetOppAfterInsert5 = [
			SELECT Id, Unit__c, Quota__c, PaymentTermMaster__c
			FROM Opportunity
			WHERE Id = :opportunity4.Id
			LIMIT 1
		];
		targetOppAfterInsert5.LossReason__c = 'No Interest';
		targetOppAfterInsert5.CloseDate = Date.today();
		targetOppAfterInsert5.StageName = 'Closed Lost';
		update targetOppAfterInsert5;
		oppTriggerHandler.clearBypass();
	}

	@isTest
	static void changeUnitStageToReservedTest() {
		Test.startTest();
		Product2Service service = Product2Service.getInstance();
		List<Opportunity> opportunitites = [SELECT Id, StageName, Unit__c FROM Opportunity];
		List<Product2> productBeforeUpdate = [SELECT Id, Status__c FROM Product2];
		List<Product2> result = service.changeUnitStageToBookOrSoldByOpportunityStage(opportunitites);
		update result;
		List<Product2> productAfterUpdate = [SELECT Id, Status__c FROM Product2];

		System.assertEquals(productBeforeUpdate[0].Status__c, productAfterUpdate[0].Status__c);
		System.assertNotEquals(productBeforeUpdate[1].Status__c, productAfterUpdate[1].Status__c);
		System.assertEquals('Reserved', productAfterUpdate[1].Status__c);
		System.assertNotEquals(productBeforeUpdate[2].Status__c, productAfterUpdate[2].Status__c);
		System.assertEquals('Transferred', productAfterUpdate[2].Status__c);

		Test.stopTest();
	}
	@isTest
	static void changeUnitStatusToAvailableByClosedLostOpportunityTest() {
		Test.startTest();
		Product2Service service = Product2Service.getInstance();
		List<Opportunity> opportunitites = [SELECT Id, StageName, Unit__c FROM Opportunity];
		List<Product2> productBeforeUpdate = [SELECT Id, Status__c FROM Product2];
		List<Product2> result = service.changeUnitStatusToAvailableByClosedLostOpportunity(opportunitites);
		update result;
		List<Product2> productAfterUpdate = [SELECT Id, Status__c FROM Product2];

		System.assertEquals(productBeforeUpdate[0].Status__c, productAfterUpdate[0].Status__c);


		Test.stopTest();
	}
}