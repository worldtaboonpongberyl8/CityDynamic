@isTest
public with sharing class OpportunityPaymentAdjustmentCtrlTest {
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
			'Test Product',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert testProduct;
		// Create Pricebook Entry
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(
			testProduct.Id,
			15000000,
			20000000,
			10000000
		);
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
		// Create Opportunity
		Opportunity opportunity = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Foreign',
			null,
			testProject.Id
		);
		insert opportunity;
	}

	@isTest
	static void getOpportunityPaymentTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			dataMaker.createOpportunityPayment(opp.Id, 'Reservation', 50000, Date.newInstance(2024, 10, 15), 1),
			dataMaker.createOpportunityPayment(opp.Id, 'Contract', 100000, Date.newInstance(2024, 10, 27), 2),
			dataMaker.createOpportunityPayment(opp.Id, 'Installment 1', 1000000, Date.newInstance(2024, 10, 27), 3),
			dataMaker.createOpportunityPayment(opp.Id, 'Transfer', 1000000, Date.newInstance(2025, 10, 27), 4)
		};
		insert oppPayments;
		List<OpportunityPayment__c> targetOppPayments = OpportunityPaymentAdjustmentController.getOpportunityPayment(
			opp.Id
		);
		System.assertEquals(oppPayments.size(), targetOppPayments.size());
		for (Integer i = 0; i < oppPayments.size(); i++) {
			System.assertEquals(oppPayments[i].Amount__c, targetOppPayments[i].Amount__c);
			System.assertEquals(oppPayments[i].DueDate__c, targetOppPayments[i].DueDate__c);
			System.assertEquals(oppPayments[i].Order__c, targetOppPayments[i].Order__c);
			System.assertEquals(oppPayments[i].Term__c, targetOppPayments[i].Term__c);
			System.assertEquals(oppPayments[i].Opportunity__c, targetOppPayments[i].Opportunity__c);
		}
		Test.stopTest();
	}

	@isTest
	static void upsertOppPaymentsTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			dataMaker.createOpportunityPayment(opp.Id, 'Reservation', 50000, Date.newInstance(2024, 10, 15), 1),
			dataMaker.createOpportunityPayment(opp.Id, 'Contract', 100000, Date.newInstance(2024, 10, 27), 2),
			dataMaker.createOpportunityPayment(opp.Id, 'Installment 1', 1000000, Date.newInstance(2024, 10, 27), 3),
			dataMaker.createOpportunityPayment(opp.Id, 'Transfer', 1000000, Date.newInstance(2025, 10, 27), 4)
		};
		insert oppPayments;
		List<OpportunityPayment__c> resultOppPayments = [
			SELECT Id, Opportunity__c, Amount__c, DueDate__c, Order__c, Term__c
			FROM OpportunityPayment__c
			WHERE Opportunity__c = :opp.Id
		];
		List<OpportunityPaymentService.OpportunityPaymentWrapper> oppPaymentWrappers = new List<OpportunityPaymentService.OpportunityPaymentWrapper>();
		for (OpportunityPayment__c oppPayment : resultOppPayments){
			OpportunityPaymentService.OpportunityPaymentWrapper reservationPaymentWrapper = new OpportunityPaymentService.OpportunityPaymentWrapper();
			reservationPaymentWrapper.amount = oppPayment.Amount__c + 100;
			reservationPaymentWrapper.dueDate = oppPayment.DueDate__c;
			reservationPaymentWrapper.order = oppPayment.Order__c;
			reservationPaymentWrapper.term = oppPayment.Term__c;
			reservationPaymentWrapper.id = oppPayment.Id;
			reservationPaymentWrapper.oppId = oppPayment.Opportunity__c;
			reservationPaymentWrapper.isNewRecord = false;
			oppPaymentWrappers.add(reservationPaymentWrapper);
		}
		String oppPaymentsJSON = JSON.serialize(oppPaymentWrappers);
		List<OpportunityPayment__c> upsertedOppPayment = OpportunityPaymentAdjustmentController.upsertOppPayments(oppPaymentsJSON);
		List<OpportunityPayment__c> oppPaymentsAfterUpserted = [
			SELECT Id, Opportunity__c, Amount__c, DueDate__c, Order__c, Term__c
			FROM OpportunityPayment__c
			WHERE Opportunity__c = :opp.Id
		];
		System.assertEquals(oppPaymentsAfterUpserted.size(), resultOppPayments.size());
		for (Integer i = 0; i < oppPaymentsAfterUpserted.size(); i++) {
			System.assertEquals(oppPaymentsAfterUpserted[i].Amount__c, resultOppPayments[i].Amount__c + 100);
			System.assertEquals(oppPaymentsAfterUpserted[i].DueDate__c, resultOppPayments[i].DueDate__c);
			System.assertEquals(oppPaymentsAfterUpserted[i].Order__c, resultOppPayments[i].Order__c);
			System.assertEquals(oppPaymentsAfterUpserted[i].Term__c, resultOppPayments[i].Term__c);
			System.assertEquals(oppPaymentsAfterUpserted[i].Opportunity__c, resultOppPayments[i].Opportunity__c);
		}
		Test.stopTest();
	}

	@isTest
	static void deleteOppPaymentsTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			dataMaker.createOpportunityPayment(opp.Id, 'Reservation', 50000, Date.newInstance(2024, 10, 15), 1),
			dataMaker.createOpportunityPayment(opp.Id, 'Contract', 100000, Date.newInstance(2024, 10, 27), 2),
			dataMaker.createOpportunityPayment(opp.Id, 'Installment 1', 1000000, Date.newInstance(2024, 10, 27), 3),
			dataMaker.createOpportunityPayment(opp.Id, 'Transfer', 1000000, Date.newInstance(2025, 10, 27), 4)
		};
		insert oppPayments;
		List<OpportunityPayment__c> resultOppPayments = [
			SELECT Id, Opportunity__c, Amount__c, DueDate__c, Order__c, Term__c
			FROM OpportunityPayment__c
			WHERE Opportunity__c = :opp.Id
		];
		List<OpportunityPaymentService.OpportunityPaymentWrapper> oppPaymentWrappers = new List<OpportunityPaymentService.OpportunityPaymentWrapper>();
		for (OpportunityPayment__c oppPayment : resultOppPayments){
			OpportunityPaymentService.OpportunityPaymentWrapper reservationPaymentWrapper = new OpportunityPaymentService.OpportunityPaymentWrapper();
			reservationPaymentWrapper.amount = oppPayment.Amount__c + 100;
			reservationPaymentWrapper.dueDate = oppPayment.DueDate__c;
			reservationPaymentWrapper.order = oppPayment.Order__c;
			reservationPaymentWrapper.term = oppPayment.Term__c;
			reservationPaymentWrapper.id = oppPayment.Id;
			reservationPaymentWrapper.oppId = oppPayment.Opportunity__c;
			reservationPaymentWrapper.isNewRecord = false;
			oppPaymentWrappers.add(reservationPaymentWrapper);
		}
		String oppPaymentsJSON = JSON.serialize(oppPaymentWrappers);
		List<OpportunityPayment__c> deletedOppPayment = OpportunityPaymentAdjustmentController.deleteOppPayments(oppPaymentsJSON);
		List<OpportunityPayment__c> oppPaymentsAfterDeleted = [
			SELECT Id, Opportunity__c, Amount__c, DueDate__c, Order__c, Term__c
			FROM OpportunityPayment__c
			WHERE Opportunity__c = :opp.Id
		];
		System.assertNotEquals(oppPaymentsAfterDeleted.size(), resultOppPayments.size());
		System.assertEquals(0, oppPaymentsAfterDeleted.size());
		Test.stopTest();
	}

	@isTest
	static void validateIsGrantedProfileProfileTest(){
		Test.startTest();
			Boolean isGrantedProfile = OpportunityPaymentAdjustmentController.validateIsGrantedProfileProfile();
			System.assert(isGrantedProfile);
		Test.stopTest();
	}
}