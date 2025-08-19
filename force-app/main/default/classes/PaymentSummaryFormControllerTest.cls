@isTest
private class PaymentSummaryFormControllerTest {
	@TestSetup
	static void makeData(){
		DataMaker dataMaker = DataMaker.getInstance();
		// Create Project
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		testProject.CompanyName__c ='Test Company Name';
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
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 15000000, 20000000,10000000);
		testPricebookEntry1.Pricebook2Id = pricebookId;
		testPricebookEntry1.UseStandardPrice = false;
		testPricebookEntry1.IsActive = true;
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
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(invoice.Id,reservationOppPayment.Id,50000,Date.newInstance(2024, 12, 1),'');
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1 };
		insert invoiceLineItems;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opportunity.Id , Date.newInstance(2024, 10, 10));
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt};
		insert receipts;
		System.debug('Payment Receipt: '+receipt);
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,invoiceLineItem1.Id,50000,'Fully Paid');
		PaymentReceiptLineItem__c receiptItemContract = dataMaker.createReceiptLineItem(receipt.Id,contractOppPayment.Id,null,50000,'Partially Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{receiptItemReservation,receiptItemContract};
		insert receiptItems;

		PaymentMethod__c receiptMethod = dataMaker.createPaymentMethod(receipt.Id,'KBANK',Decimal.valueOf(1000000),'Cash','Reservation',Date.today());
		List<PaymentMethod__c> receiptMethods = new List<PaymentMethod__c>{receiptMethod};
		insert receiptMethods;
	}
	@isTest
	static void paymentSummaryFormControllerTest() {
		Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
		Test.setCurrentPageReference(new PageReference('/apex/PaymentSummaryForm?id=' + testOpportunity.Id));
		PaymentSummaryFormController controller = PaymentSummaryFormController.getInstanceCtrl();
		PaymentSummaryFormController.PaymentSummaryWrapper summaryWrapper = controller.getPaymentSummary();
		System.assertNotEquals(null, summaryWrapper);
		System.assertNotEquals(null, summaryWrapper.oppDetail);
		System.assertNotEquals(null, summaryWrapper.paymentItem);
		System.assertEquals('Test Company Name', summaryWrapper.oppDetail.companyName);
		System.assertEquals(4, summaryWrapper.paymentItem.paymentItemDetails.size(), 'Expected 2 payment receipt line items');
	}
}