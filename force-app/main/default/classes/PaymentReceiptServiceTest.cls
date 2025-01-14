@isTest
public with sharing class PaymentReceiptServiceTest {
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
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice };
		insert invoices;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(
			invoice.Id,
			reservationOppPayment.Id,
			50000,
			Date.newInstance(2024, 12, 1),
			''
		);
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1 };
		insert invoiceLineItems;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opportunity.Id, Date.newInstance(2024, 10, 10));
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{ receipt };
		insert receipts;
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItem = dataMaker.createReceiptLineItem(
			receipt.Id,
			reservationOppPayment.Id,
			invoiceLineItem1.Id,
			50000,
			'Fully Paid'
		);
		PaymentReceiptLineItem__c receiptItem2 = dataMaker.createReceiptLineItem(
			receipt.Id,
			contractOppPayment.Id,
			invoiceLineItem1.Id,
			50000,
			'Partially Paid'
		);
		PaymentReceiptLineItem__c receiptItem3 = dataMaker.createReceiptLineItem(
			receipt.Id,
			contractOppPayment.Id,
			invoiceLineItem1.Id,
			30000,
			'Partially Paid'
		);
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{ receiptItem,receiptItem2,receiptItem3 };
		insert receiptItems;
		// Create Name Formatting
		NameFormattingMasterData__c format = dataMaker.createNameFormattingMasterData(
			'PaymentReceipt__c', 'Format', 'Object', 'RV-{Opportunity__r.Project__r.ProjectCode__c}{CreatedDate:FORMATDATETIME:yyMM}{RUNNINGNUMBER:000}', 1, null
		);
		insert format;
	}

	@isTest
	static void generatePaymentReceiptRelatedToOpportunityTest() {
		Test.startTest();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		PaymentReceipt__c paymentReceipt = service.generatePaymentReceiptRelatedToOpportunity(opportunity.Id);
		System.assertEquals(opportunity.Id, paymentReceipt.Opportunity__c);
		Test.stopTest();
	}

	@isTest
	static void generateRunningNoTest() {
		Test.startTest();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		PaymentReceipt__c paymentReceipt = [SELECT Id, ReceiptNo__c FROM PaymentReceipt__c LIMIT 1];
		PaymentReceipt__c resultPaymentReceipt = service.generateRunningNo(paymentReceipt);
		// System.assertEquals('RV-AA012410001', resultPaymentReceipt.ReceiptNo__c);
		Test.stopTest();
	}

	@isTest
	static void generatePaymentReceiptLineItemFromTotalReceivedAmount() {
		Test.startTest();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		List<OpportunityPayment__c> oppPayments = [
			SELECT
				Id,
				Remaining__c,
				Amount__c,
				(SELECT Id, Invoice__c, Status__c, PaymentReceiptLineItem__c FROM InvoiceLineItems__r)
			FROM OpportunityPayment__c
			ORDER BY Order__c
		];
		OpportunityPayment__c reservationOppPayments = [
			SELECT Id, Remaining__c, Amount__c
			FROM OpportunityPayment__c
			WHERE Term__c = 'Reservation'
			LIMIT 1
		];
		OpportunityPayment__c contractOppPayments = [
			SELECT Id, Remaining__c, Amount__c
			FROM OpportunityPayment__c
			WHERE Term__c = 'Contract'
			LIMIT 1
		];
		InvoiceLineItem__c reservationInvoiceLine = [
			SELECT Id
			FROM InvoiceLineItem__c
			WHERE OpportunityPayment__c = :reservationOppPayments.Id
			LIMIT 1
		];
		List<PaymentReceiptLineItem__c> resultPaymentReceiptItems1 = service.generatePaymentReceiptLineItemFromTotalReceivedAmount(
			50000,
			oppPayments,
			null,
			null
		);
		System.assertEquals(1, resultPaymentReceiptItems1.size());
		System.assertEquals(50000, resultPaymentReceiptItems1[0].ReceivedAmount__c);
		System.assertEquals('Fully Paid', resultPaymentReceiptItems1[0].Status__c);
		System.assertEquals(reservationOppPayments.Id, resultPaymentReceiptItems1[0].OpportunityPayment__c);
		System.assertEquals(reservationInvoiceLine.Id, resultPaymentReceiptItems1[0].InvoiceLineItem__c);
		List<PaymentReceiptLineItem__c> resultPaymentReceiptItems2 = service.generatePaymentReceiptLineItemFromTotalReceivedAmount(
			70000,
			oppPayments,
			null,
			null
		);
		System.assertEquals(2, resultPaymentReceiptItems2.size());
		System.assertEquals(50000, resultPaymentReceiptItems2[0].ReceivedAmount__c);
		System.assertEquals('Fully Paid', resultPaymentReceiptItems2[0].Status__c);
		System.assertEquals(reservationOppPayments.Id, resultPaymentReceiptItems2[0].OpportunityPayment__c);
		System.assertEquals(reservationInvoiceLine.Id, resultPaymentReceiptItems2[0].InvoiceLineItem__c);
		System.assertEquals(20000, resultPaymentReceiptItems2[1].ReceivedAmount__c);
		System.assertEquals('Partially Paid', resultPaymentReceiptItems2[1].Status__c);
		System.assertEquals(contractOppPayments.Id, resultPaymentReceiptItems2[1].OpportunityPayment__c);
		System.assertEquals(null, resultPaymentReceiptItems2[1].InvoiceLineItem__c);
		Test.stopTest();
	}
	@isTest
	static void aggregatePaymentReceiptLineItems(){
		Test.startTest();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		PaymentReceipt__c paymentReceipt = [SELECT Id, ReceiptNo__c FROM PaymentReceipt__c LIMIT 1];
		List<PaymentReceiptLineItem__c> paymentReceiptItems = [
			SELECT Id,
				InvoiceLineItem__c,
				InvoiceLineItem__r.Invoice__c,
				ReceivedAmount__c,
				RemainingAmount__c,
				Status__c,
				PreviousRemaining__c,
				OpportunityPayment__c,
				OpportunityPayment__r.Term__c,
				OpportunityPayment__r.DueDate__c,
				OpportunityPayment__r.Remaining__c,
				OpportunityPayment__r.ReceivedAmount__c,
				OpportunityPayment__r.PaymentStatus__c,
				TransactionDateTime__c,
				PaymentReceipt__r.TotalReceiveAmount__c
			FROM PaymentReceiptLineItem__c
			WHERE PaymentReceipt__c =: paymentReceipt.Id
		];
		List<PaymentReceiptLineItem__c> resultPaymentReceiptItems = service.aggregatePaymentReceiptLineItems(paymentReceiptItems);
		System.assertEquals(2, resultPaymentReceiptItems.size());

		Test.stopTest();
	}
}