@isTest
private class RecurringTextFileGeneratorControllerTest {

  
    @TestSetup
    static void makeData(){
        DataMaker dataMaker = DataMaker.getInstance();
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		testProject.CompletionDate__c = Date.today().addDays(10);
		insert testProject;
		Floor__c testFloor =dataMaker.createFloor('Test Floor', 'FF01' , testProject.Id);
		insert testFloor;
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type', testProject.Id);
		insert unitType;
		Product2 testProduct = dataMaker.createUnit('Test Product','PP01',testProject.Id,testFloor.Id,'Available',unitType.Id);
		testProduct.ReservationPrice__c = 10000;
		insert testProduct;
		// Pricebook2 testPricebook = dataMaker.createPricebook('Test Pricebook', testProduct.Id, 150000, 200000);
		// insert testPricebook;
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 150000, 200000,10000000);
		testPricebookEntry1.Pricebook2Id = pricebookId;
		testPricebookEntry1.UseStandardPrice = false;
		insert testPricebookEntry1;
		Id recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Co-Owner - Corporate').getRecordTypeId();
		Account acc = dataMaker.createAccount(recordTypeId, 'Test Account');
		insert acc;
		PaymentTermMaster__c paymentTermMaster = dataMaker.craetePaymentTermMaster(testProject.Id,'TQ Series 5-10-85', 'Series', 'Thai', 25);
		insert paymentTermMaster;
		Opportunity opp = dataMaker.createOpportunity(acc.Id, 'Omitted', 'Test Opp1', Date.today(), 'Open',testProduct.Id,'Thai',paymentTermMaster.Id,testProject.Id);
		opp.ReservationDueDate__c = Date.today();
		opp.DiscountPercent__c = 10;
		opp.DiscountAmount__c = 0;
		opp.UnitPrice__c = 1000000;
        opp.CreditCardExpiredDateRecurring__c = '11/23';
        opp.CreditCardNameRecurring__c = 'Poom';
        opp.CreditCardNumberRecurring__c = '12345678910';
		insert opp;
		PaymentTermMaster__c paymentTermMasterNew = dataMaker.craetePaymentTermMaster(testProject.Id,'TQ Series 9-10-85', 'Series', 'Thai', 25);
		insert paymentTermMasterNew;
		List<PaymentTerm__c> paymentTermWrappers = new List<PaymentTerm__c>();
		PaymentTerm__c paymentTarm1 = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			1,
			null,
			10,
			'Contract'
		);
		PaymentTerm__c paymentTarm2 = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			2,
			null,
			20,
			'Installment 1'
		);
		PaymentTerm__c paymentTarm3 = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			3,
			null,
			null,
			'Transfer'
		);
		paymentTermWrappers.add(paymentTarm1);
		paymentTermWrappers.add(paymentTarm2);
		paymentTermWrappers.add(paymentTarm3);
		insert paymentTermWrappers;
        OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opp.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		OpportunityPayment__c contractOppPayment = dataMaker.createOpportunityPayment(
			opp.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 27),
			2
		);
		OpportunityPayment__c installmentOppPayment = dataMaker.createOpportunityPayment(
			opp.Id,
			'Installment 1',
			1000000,
			Date.newInstance(2024, 10, 27),
			3
		);
		OpportunityPayment__c transferOppPayment = dataMaker.createOpportunityPayment(
			opp.Id,
			'Transfer',
			1000000,
			Date.newInstance(2025, 10, 27),
			4
		);
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment,
			contractOppPayment,
			installmentOppPayment,
			transferOppPayment
		};
		insert oppPayments;    
    }

    @isTest
    static void createRecurringTextFileAndDowdloadTest() {
        Project__c testProject = [SELECT Id FROM Project__c WHERE name = 'Test Project' LIMIT 1];
        Test.startTest();
        String result = RecurringTextFileGeneratorController.createRecurringTextFileAndDowdload(testProject.Id);
        Test.stopTest();
        System.debug(result);
        System.assertNotEquals(null, result);
        }
}