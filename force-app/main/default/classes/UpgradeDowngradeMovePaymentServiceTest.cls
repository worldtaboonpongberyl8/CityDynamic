@isTest
public with sharing class UpgradeDowngradeMovePaymentServiceTest {
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
		Account account2 = dataMaker.createAccount(recordTypeId, 'Test Account 2');
		Account account3 = dataMaker.createAccount(recordTypeId, 'Test Account 3');
		List<Account> accounts = new List<Account>{account,account2,account3};
		insert accounts;
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
		OpportunityPayment__c reservationOppPayment2 = dataMaker.createOpportunityPayment(
			opportunity2.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		OpportunityPayment__c contractOppPayment2 = dataMaker.createOpportunityPayment(
			opportunity2.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 27),
			2
		);
		OpportunityPayment__c installmentOppPayment2 = dataMaker.createOpportunityPayment(
			opportunity2.Id,
			'Installment 1',
			10000000,
			Date.newInstance(2024, 10, 27),
			3
		);
		OpportunityPayment__c transferOppPayment2 = dataMaker.createOpportunityPayment(
			opportunity2.Id,
			'Transfer',
			4850000,
			Date.newInstance(2025, 10, 27),
			4
		);
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment,
			contractOppPayment,
			installmentOppPayment,
			transferOppPayment,
			reservationOppPayment2,
			contractOppPayment2,
			installmentOppPayment2,
			transferOppPayment2
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

	@IsTest
	static void generateUpgradeDowngradeMovePaymentTest() {
		UpgradeDowngradeMovePaymentService service = UpgradeDowngradeMovePaymentService.getInstance();
		List<Opportunity> opportunities = [SELECT Id,AccountId FROM Opportunity];
		Opportunity oldOpportunity = opportunities[0];
		Opportunity newOpportunity = opportunities[1];
		String url = 'www.google.com';
		Decimal operationFee = 100;
		Test.startTest();
			UpgradeDowngradeMovePayment__c resultUpgrade = service.generateUpgradeDowngradeMovePayment('upgrade', oldOpportunity, newOpportunity, url, operationFee,'');
			System.assertEquals(url, resultUpgrade.URLUpgrade__c);
			System.assertEquals(null, resultUpgrade.URLDowngrade__c);
			System.assertEquals(true, resultUpgrade.IsUpgradeCompleted__c);
			UpgradeDowngradeMovePayment__c resultDowngrade = service.generateUpgradeDowngradeMovePayment('downgrade', oldOpportunity, newOpportunity, url, operationFee,'');
			System.assertEquals(null, resultDowngrade.URLUpgrade__c);
			System.assertEquals(url, resultDowngrade.URLDowngrade__c);
			System.assertEquals(true, resultDowngrade.IsDowngradeCompleted__c);
			UpgradeDowngradeMovePayment__c resultMovePayment = service.generateUpgradeDowngradeMovePayment('move_payment', oldOpportunity, newOpportunity, url, operationFee,'');
			System.assertEquals(true, resultMovePayment.IsMovePaymentCompleted__c);

		Test.stopTest();
	}
}