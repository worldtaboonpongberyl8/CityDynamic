@isTest
public with sharing class PaymentReceiptTriggerHandlerTest {
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
		reservationOppPayment.ReceivedAmount__c = 50000;
		reservationOppPayment.ReceivedDate__c = Date.today();
		OpportunityPayment__c contractOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 27),
			2
		);
		contractOppPayment.ReceivedAmount__c = 50000;
		contractOppPayment.ReceivedDate__c = Date.today();
		OpportunityPayment__c installmentOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Installment 1',
			10000000,
			Date.newInstance(2024, 10, 27),
			3
		);
		OpportunityPayment__c installmentOppPayment2 = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Installment 1',
			10000000,
			Date.newInstance(2024, 10, 27),
			4
		);
		OpportunityPayment__c installmentOppPayment3 = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Installment 2',
			10000000,
			Date.newInstance(2024, 10, 27),
			5
		);
		OpportunityPayment__c transferOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Transfer',
			4850000,
			Date.newInstance(2025, 10, 27),
			5
		);
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment,
			contractOppPayment,
			installmentOppPayment,
			installmentOppPayment2,
			installmentOppPayment3,
			transferOppPayment
		};
		insert oppPayments;
		// Create Invoice
		Invoice__c invoice = dataMaker.createInvoice(
			opportunity.Id,
			Date.newInstance(2024, 10, 6),
			Date.newInstance(2024, 10, 1),
			true,
			'Address'
		);
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
		PaymentReceipt__c receipt2 = dataMaker.craeteReceipt(opportunity.Id, Date.newInstance(2024, 10, 11));
		PaymentReceipt__c receipt3 = dataMaker.craeteReceipt(opportunity.Id, Date.newInstance(2024, 10, 12));
		insert receipt;
		insert receipt2;
		insert receipt3;
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{ receipt, receipt2, receipt3};
		// insert receipts;
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(
			receipt.Id,
			reservationOppPayment.Id,
			invoiceLineItem1.Id,
			50000,
			'Fully Paid'
		);
		PaymentReceiptLineItem__c receiptItemContract = dataMaker.createReceiptLineItem(
			receipt.Id,
			contractOppPayment.Id,
			null,
			10000,
			'Partially Paid'
		);
		PaymentReceiptLineItem__c receiptItemContract2 = dataMaker.createReceiptLineItem(
			receipt.Id,
			contractOppPayment.Id,
			null,
			40000,
			'Partially Paid'
		);
		PaymentReceiptLineItem__c receiptItem2Installment2 = dataMaker.createReceiptLineItem(
			receipt2.Id,
			installmentOppPayment2.Id,
			null,
			10000000,
			'Fully Paid'
		);
		PaymentReceiptLineItem__c receiptItem3Installment3 = dataMaker.createReceiptLineItem(
			receipt3.Id,
			installmentOppPayment3.Id,
			null,
			10000000,
			'Fully Paid'
		);
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{
			receiptItemReservation,
			receiptItemContract,
			receiptItemContract2,
			receiptItem2Installment2,
			receiptItem3Installment3
		};
		insert receiptItems;
		// Create Name Formatting
		NameFormattingMasterData__c format = dataMaker.createNameFormattingMasterData(
			'PaymentReceipt__c',
			'Format',
			'Object',
			'RV-{Opportunity__r.Project__r.ProjectCode__c}{{CreatedDate:FORMATDATETIME:yyMM}{RUNNINGNUMBER:000}',
			1,
			null
		);
		insert format;
	}

	@isTest
	static void updateReceiptTest() {
		Test.startTest();
		PaymentReceiptSelector selector = PaymentReceiptSelector.getInstance();
		List<PaymentReceipt__c> receipts = [
			SELECT Id, IsCancel__c
			FROM PaymentReceipt__c
			ORDER By CreatedDate ASC
		];
		for (PaymentReceipt__c receipt : receipts){
			System.debug('** test ** receipt:' + receipt.Id );
		}
		PaymentReceipt__c receipt = receipts[0];
		Set<Id> oppPaymentIds = new Set<Id>();
		List<PaymentReceiptLineItem__c> receiptLineItems = [
			SELECT Id, OpportunityPayment__c, ReceivedAmount__c
			FROM PaymentReceiptLineItem__c
			WHERE PaymentReceipt__c = :receipt.Id
		];
		for (PaymentReceiptLineItem__c receiptLineItem : receiptLineItems) {
			oppPaymentIds.add(receiptLineItem.OpportunityPayment__c);
		}
		List<OpportunityPayment__c> originalOppPayments = [
			SELECT Id, ReceivedAmount__c, ReceivedDate__c
			FROM OpportunityPayment__c
			WHERE Id IN :oppPaymentIds
			ORDER BY Order__c
		];
		// receipt.IsCancel__c = true;
		receipt.CancelReason__c = 'Closed Lost';
		update receipt;
		List<OpportunityPayment__c> updatedOppPayments = [
			SELECT Id, ReceivedAmount__c, ReceivedDate__c, Term__c
			FROM OpportunityPayment__c
			WHERE Id IN :oppPaymentIds
			ORDER BY Order__c
		];

		PaymentReceipt__c receipt2 = receipts[1];
		receipt2.CancelReason__c = 'Cancel by CRM';
		receipt2.CancelReasonforCRM__c = 'Test';
		update receipt2;
		Test.stopTest();
	}

	@isTest
	static void setBypassTest() {
		Test.startTest();
		PaymentReceiptTriggerHandler handler = PaymentReceiptTriggerHandler.getInstance();
		handler.setBypass();
		System.assertEquals(false, handler.isActive);
		System.assertEquals(false, handler.isTriggerActivated());
		Test.stopTest();
	}

	@isTest
	static void clearBypassTest() {
		Test.startTest();
		PaymentReceiptTriggerHandler handler = PaymentReceiptTriggerHandler.getInstance();
		handler.clearBypass();
		System.assertEquals(true, handler.isActive);
		System.assertEquals(true, handler.isTriggerActivated());
		Test.stopTest();
	}
}