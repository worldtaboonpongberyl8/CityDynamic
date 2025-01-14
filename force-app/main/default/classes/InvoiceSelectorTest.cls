@isTest
public with sharing class InvoiceSelectorTest {
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
        Invoice__c invoice3 = dataMaker.createInvoice(opportunity.Id, Date.newInstance(2024, 10, 6), Date.newInstance(2024, 10, 1), false, 'Address');
		Invoice__c invoice4 = dataMaker.createInvoice(opportunity.Id, Date.newInstance(2024, 11, 6), Date.newInstance(2024, 11, 1), false, 'Address');
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice, invoice2,invoice3,invoice4 };
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
    static void getForSendEmailTest(){
        Test.startTest();
        InvoiceSelector selector = InvoiceSelector.getInstance();
        List<Invoice__c> invoices = selector.getForSendEmail(Date.newInstance(2024, 10, 6));
        System.assertEquals(1, invoices.size());
        Test.stopTest();
    }

    @isTest
    static void getByOppIdSetTest(){
        Test.startTest();
        InvoiceSelector selector = InvoiceSelector.getInstance();
        Opportunity targetOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Invoice__c> invoices = selector.getByOppIdSet(new Set<Id>{targetOpp.Id});
        System.assertEquals(4, invoices.size());
        Test.stopTest();
    }

    @isTest
    static void getByIdTest(){
        Test.startTest();
        InvoiceSelector selector = InvoiceSelector.getInstance();
        Invoice__c targetInvoice = [SELECT Id FROM Invoice__c LIMIT 1];
        Invoice__c invoice = selector.getById(targetInvoice.Id);
        System.assertEquals(targetInvoice.Id, invoice.Id);
        Test.stopTest();
    }
}