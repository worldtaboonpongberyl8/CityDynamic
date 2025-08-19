@IsTest
public with sharing class GenerateReceiptPDFQueueableTest {
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
		PricebookEntry testPricebookEntry2 = dataMaker.createPricebookEntries(
			testProduct2.Id,
			15000000,
			20000000,
			10000000
		);
		testPricebookEntry2.Pricebook2Id = pricebookId;
		testPricebookEntry2.UseStandardPrice = false;
		PricebookEntry testPricebookEntry3 = dataMaker.createPricebookEntries(
			testProduct3.Id,
			15000000,
			20000000,
			10000000
		);
		testPricebookEntry3.Pricebook2Id = pricebookId;
		testPricebookEntry3.UseStandardPrice = false;
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{testPricebookEntry1,testPricebookEntry2,testPricebookEntry3};
		insert pricebookEntries;
		// Creat Account
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
		account.Email__c = 'test@gmail.com.invalid';
		Account account2 = dataMaker.createAccount(recordTypeId, 'Test Account 2');
		Account account3 = dataMaker.createAccount(recordTypeId, 'Test Account 3');
		Account dummyAccount = dataMaker.createAccount(recordTypeId, 'Dummy Accouny');
		dummyAccount.AccountCode__c = '5555';
		List<Account> accounts = new List<Account>{account,account2,account3,dummyAccount};
		insert accounts;
		// Create Dummy Contact
		Contact dummyContact = dataMaker.createContact(dummyAccount.Id, 'Dummy', 'Contact', 'dummyContact@dummy.com', '0111111111');
		dummyContact.IsDummy__c = true;
		List<Contact> contacts = new List<Contact>{dummyContact};
		insert contacts;
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
		Opportunity opportunity2 = dataMaker.createOpportunity(
			account2.Id,
			'Omitted',
			'Test Opp with Unit 2',
			Date.today(),
			'Open', //Reservation
			testProduct2.Id,
			'Foreign',
			null,
			testProject.Id
		);
		Opportunity opportunity3 = dataMaker.createOpportunity(
			account3.Id,
			'Omitted',
			'Test Opp with Unit 3',
			Date.today(),
			'Open', //Transfer
			testProduct3.Id,
			'Foreign',
			null,
			testProject.Id
		);
		List<Opportunity> opportunities = new List<Opportunity>{opportunity,opportunity2,opportunity3};
		insert opportunities;
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
		NameFormattingMasterData__c receiptFormatObject = dataMaker.createNameFormattingMasterData(
			'PaymentReceipt__c', 'Format', 'Object', 'RV-{Opportunity__r.Project__r.ProjectCode__c}{CreatedDate:FORMATDATETIME:yyMM}{RUNNINGNUMBER:000}', 1, null
		);
		NameFormattingMasterData__c receiptFormatDocument = dataMaker.createNameFormattingMasterData(
			'PaymentReceipt__c', 'Format', 'Document', '{ReceiptNo__c}', 1, 'Payment Receipt'
		);
		List<NameFormattingMasterData__c> nameFormattings = new List<NameFormattingMasterData__c>{receiptFormatObject,receiptFormatDocument};
		insert nameFormattings;
	}

	@isTest
    static void generatePDFAndEnqueueEmailTest() {


        PaymentReceipt__c testReceipt = [SELECT Id FROM PaymentReceipt__c LIMIT 1];

        String ref = 'CD-1747720513103-9999'; // make sure this matches the method ref param
        PaymentGatewayReference__c pgr = new PaymentGatewayReference__c(
            Name = 'Test Reference',
            OrderReference__c = ref,
            OpportunityPayment__c = [SELECT Id FROM OpportunityPayment__c WHERE Term__c = 'Reservation' LIMIT 1].Id
        );
        insert pgr;

        GenerateReceiptPDFQueueable queueJob = new GenerateReceiptPDFQueueable(testReceipt.Id, ref, '00');
		Test.startTest();
        	System.enqueueJob(queueJob);
        Test.stopTest();

        List<PaymentGatewayReference__c> pgrs = [
            SELECT Id, OrderReference__c FROM PaymentGatewayReference__c WHERE OrderReference__c = :ref
        ];
        System.assertEquals(1, pgrs.size(), 'PaymentGatewayReference should exist');
    }
}