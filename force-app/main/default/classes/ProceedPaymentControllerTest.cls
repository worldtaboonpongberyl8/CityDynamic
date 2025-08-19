@isTest
public with sharing class ProceedPaymentControllerTest {
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
			'Thai',
			null,
			testProject.Id
		);
		insert opportunity;
		// Create Opp Payments
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		OpportunityPayment__c contractOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 27),
			2
		);
		OpportunityPayment__c installmentOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Installment 1',
			10000000,
			Date.newInstance(2024, 10, 27),
			3
		);
		OpportunityPayment__c transferOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Transfer',
			4850000,
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
		// Create Invoice
		Invoice__c invoice = dataMaker.createInvoice(opportunity.Id, Date.newInstance(2024, 10, 6), Date.newInstance(2024, 10, 1), true, 'Address');
		Invoice__c invoice2 = dataMaker.createInvoice(opportunity.Id, Date.newInstance(2024, 11, 6), Date.newInstance(2024, 11, 1),  true, 'Address');
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice, invoice2 };
		insert invoices;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(
			invoice.Id,
			reservationOppPayment.Id,
			50000,
			Date.newInstance(2024, 12, 1),
			''
		);
		InvoiceLineItem__c invoiceLineItem2 = dataMaker.createInvoiceLineItem(
			invoice2.Id,
			contractOppPayment.Id,
			100000,
			Date.newInstance(2025, 1, 1),
			''
		);
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1, invoiceLineItem2 };
		insert invoiceLineItems;
		// Create Name Formatting
		NameFormattingMasterData__c format = dataMaker.createNameFormattingMasterData(
			'PaymentReceipt__c', 'Format', 'Object', 'RV-{Opportunity__r.Project__r.ProjectCode__c}{{CreatedDate:FORMATDATETIME:yyMM}{RUNNINGNUMBER:000}', 1, null
		);
		insert format;
	}

	@isTest
	static void getMakeAPaymentConfigTest() {
		Test.startTest();
		List<MakeAPaymentConfig__mdt> configs = ProceedPaymentController.getMakeAPaymentConfig();
		Test.stopTest();
	}

	@isTest
	static void getPicklistValuesTest() {
		Test.startTest();
		List<ComboboxModel> picklists = ProceedPaymentController.getPicklistValues(
			'PaymentMethod__c',
			'PaymentType__c'
		);
		Test.stopTest();
	}

	@isTest
	static void proceedPaymentTest() {
		Test.startTest();
		Opportunity opportuntiy = [SELECT Id FROM Opportunity LIMIT 1];
		List<PaymentMethod__c> paymentMethods = new List<PaymentMethod__c>{
			new PaymentMethod__c(PaymentType__c = 'Credit Card', ReceivedAmount__c = 10000),
			new PaymentMethod__c(PaymentType__c = 'Credit Card', ReceivedAmount__c = 40000)
		};
		Map<String, List<SObject>> result = ProceedPaymentController.proceedPayment(
			opportuntiy.Id,
			50000,
			paymentMethods,
			null,
			false
		);
		PaymentReceipt__c paymentReceipt = [SELECT Id, ReceiptNo__c FROM PaymentReceipt__c LIMIT 1];
		System.assertEquals(paymentReceipt.Id, result.get('PaymentReceipt__c')[0].Id);
		System.assertEquals(paymentReceipt.ReceiptNo__c, result.get('PaymentReceipt__c')[0].get('ReceiptNo__c'));
		List<PaymentReceiptLineItem__c> paymentReceiptLineItems = [
			SELECT Id, ReceivedAmount__c, PaymentReceipt__c, Status__c, OpportunityPayment__c, InvoiceLineItem__c
			FROM PaymentReceiptLineItem__c
			WHERE PaymentReceipt__c = :paymentReceipt.Id
		];
		InvoiceLineItem__c reservationInvoiceLine = [
			SELECT Id, PaymentReceiptLineItem__c
			FROM InvoiceLineItem__c
			WHERE OpportunityPayment__r.Term__c = 'Reservation'
			LIMIT 1
		];
		System.assertEquals(1, paymentReceiptLineItems.size());
		OpportunityPayment__c reservationOppPayment = [SELECT Id, ReceivedAmount__c, Remaining__c FROM OpportunityPayment__c WHERE Term__c = 'Reservation'];
		System.assertEquals(0, reservationOppPayment.Remaining__c);
		System.assertEquals(2, result.get('PaymentMethod__c').size());
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - add test method for getCompanyBanks
	 */
	@isTest
	static void getCompanyBanksTest() {
		Test.startTest();
		Opportunity opportunity = [SELECT Id,IsPaidNovationFee__c FROM Opportunity LIMIT 1];
		List<ComboboxModel> picklistValues = ProceedPaymentController.getCompanyBanks(opportunity.Id);
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - add test method for proceedNovationPayment
	 */
	@isTest
	static void proceedNovationPaymentTest() {
		Test.startTest();
		Opportunity opportunity = [SELECT Id,IsPaidNovationFee__c FROM Opportunity LIMIT 1];
		System.assertEquals(false, opportunity.IsPaidNovationFee__c);
		List<PaymentMethod__c> paymentMethods = new List<PaymentMethod__c>{
			new PaymentMethod__c(PaymentType__c = 'Credit Card', ReceivedAmount__c = 50000)
		};
		Map<String, List<SObject>> result = ProceedPaymentController.proceedNovationPayment(
			opportunity.Id,
			50000,
			paymentMethods
		);
		PaymentReceipt__c paymentReceipt = [SELECT Id, ReceiptNo__c,ReceiptType__c FROM PaymentReceipt__c LIMIT 1];
		System.assertEquals(paymentReceipt.Id, result.get('PaymentReceipt__c')[0].Id);
		System.assertEquals(paymentReceipt.ReceiptNo__c, result.get('PaymentReceipt__c')[0].get('ReceiptNo__c'));
		System.assertEquals(GlobalConstants.RECEIPT_TYPE_NOVATION, paymentReceipt.ReceiptType__c);
		List<PaymentReceiptLineItem__c> paymentReceiptLineItems = [
			SELECT Id, ReceivedAmount__c, PaymentReceipt__c, Status__c, OpportunityPayment__c, InvoiceLineItem__c
			FROM PaymentReceiptLineItem__c
			WHERE PaymentReceipt__c = :paymentReceipt.Id
		];
		System.assertEquals(1, paymentReceiptLineItems.size());
		System.assertEquals(50000, paymentReceiptLineItems[0].ReceivedAmount__c);
		Opportunity updatedOpportunity = [SELECT Id,IsPaidNovationFee__c FROM Opportunity WHERE Id =: opportunity.Id LIMIT 1];
		System.assertEquals(true, updatedOpportunity.IsPaidNovationFee__c);
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - add test method for getAreaDetails
	 */
	@isTest
	static void getAreaDetailsTest(){
		Test.startTest();
		Opportunity opportunity = [SELECT Id,Project__c FROM Opportunity LIMIT 1];
		Map<String,Decimal> result = ProceedPaymentController.getAreaDetails(opportunity.Id);
		System.assertEquals(0, result.get('areaBookedOrSoldAsFQQuota'));
		Test.stopTest();
	}


	/**
	 * Phase2
	 * Details:
	 * - add test method for proceedPaymentTest in case Recurring Payment
	 */
	@isTest
	static void proceedPaymentRecurringTest() {
		Test.startTest();
		Opportunity opportuntiy = [SELECT Id FROM Opportunity LIMIT 1];
		List<PaymentMethod__c> paymentMethods = new List<PaymentMethod__c>{
			new PaymentMethod__c(PaymentType__c = 'Credit Card', ReceivedAmount__c = 10000),
			new PaymentMethod__c(PaymentType__c = 'Credit Card', ReceivedAmount__c = 40000)
		};
		Map<String, List<SObject>> result = ProceedPaymentController.proceedPayment(
			opportuntiy.Id,
			50000,
			paymentMethods,
			null,
			true
		);
		PaymentReceipt__c paymentReceipt = [SELECT Id, ReceiptNo__c,ReceiptType__c FROM PaymentReceipt__c LIMIT 1];
		System.assertEquals(paymentReceipt.Id, result.get('PaymentReceipt__c')[0].Id);
		System.assertEquals(paymentReceipt.ReceiptNo__c, result.get('PaymentReceipt__c')[0].get('ReceiptNo__c'));
		System.assertEquals(paymentReceipt.ReceiptType__c, GlobalConstants.RECEIPT_TYPE_RECURRING);
		List<PaymentReceiptLineItem__c> paymentReceiptLineItems = [
			SELECT Id, ReceivedAmount__c, PaymentReceipt__c, Status__c, OpportunityPayment__c, InvoiceLineItem__c
			FROM PaymentReceiptLineItem__c
			WHERE PaymentReceipt__c = :paymentReceipt.Id
		];
		InvoiceLineItem__c reservationInvoiceLine = [
			SELECT Id, PaymentReceiptLineItem__c
			FROM InvoiceLineItem__c
			WHERE OpportunityPayment__r.Term__c = 'Reservation'
			LIMIT 1
		];
		System.assertEquals(1, paymentReceiptLineItems.size());
		OpportunityPayment__c reservationOppPayment = [SELECT Id, ReceivedAmount__c, Remaining__c FROM OpportunityPayment__c WHERE Term__c = 'Reservation'];
		System.assertEquals(0, reservationOppPayment.Remaining__c);
		System.assertEquals(2, result.get('PaymentMethod__c').size());
		Test.stopTest();
	}

}