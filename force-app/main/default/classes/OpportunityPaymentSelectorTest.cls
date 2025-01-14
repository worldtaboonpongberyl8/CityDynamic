@isTest
public with sharing class OpportunityPaymentSelectorTest {
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
		// Create Pricebook
		Pricebook2 testPricebook = dataMaker.createPricebook('Test Pricebook', testProduct.Id);
		insert testPricebook;
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
			1000000,
			Date.newInstance(2024, 10, 27),
			3
		);
		OpportunityPayment__c transferOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
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
		// Create Invoice
		Invoice__c invoice = dataMaker.createInvoice(opportunity.Id, Date.newInstance(2024, 11, 6), Date.newInstance(2024, 11, 1),  true, 'Address');
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice };
		insert invoices;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(invoice.Id,reservationOppPayment.Id,10000,Date.newInstance(2024, 12, 1),'');
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1 };
		insert invoiceLineItems;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opportunity.Id , Date.newInstance(2024, 11, 1));
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt};
		insert receipts;
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItem = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,invoiceLineItem1.Id,10000,'Fully Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{receiptItem};
		insert receiptItems;
	}

	@isTest
	static void getOpportunityPaymentsMapByOppIdTest() {
		Test.startTest();
		OpportunityPaymentSelector selector = OpportunityPaymentSelector.getInstance();
		Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		List<OpportunityPayment__c> oppPayments = [
			SELECT Id, Opportunity__c, Amount__c, DueDate__c, Order__c, Term__c
			FROM OpportunityPayment__c
			WHERE Opportunity__c = :opp.Id
		];
		Map<Id, List<OpportunityPayment__c>> targetMap = selector.getOpportunityPaymentsMapByOppId(
			new Set<Id>{ opp.Id }
		);
		System.assertEquals(opp.Id, new List<Id>(targetMap.keyset())[0]);
		System.assertEquals(oppPayments.size(), targetMap.values()[0].size());
		Test.stopTest();
	}

	@isTest
	static void getOpportunityPaymentMapByIdTest() {
		Test.startTest();
		OpportunityPaymentSelector selector = OpportunityPaymentSelector.getInstance();
		List<OpportunityPayment__c> oppPayments = [
			SELECT Id, Opportunity__c, Amount__c, DueDate__c, Order__c, Term__c
			FROM OpportunityPayment__c
		];
		Set<Id> oppPaymentIds = new Set<Id>();
		for (OpportunityPayment__c oppPayment : oppPayments) {
			oppPaymentIds.add(oppPayment.Id);
		}
		Map<Id, OpportunityPayment__c> opportunityPaymentMapById = selector.getOpportunityPaymentMapById(oppPaymentIds);
		System.assertEquals(oppPayments.size(), opportunityPaymentMapById.values().size());
		Test.stopTest();
	}

	@isTest
	static void getOpportunityPaymentWithInvoiceLineItemMapByIdTest() {
		Test.startTest();
		OpportunityPaymentSelector selector = OpportunityPaymentSelector.getInstance();
		List<OpportunityPayment__c> oppPayments = [
			SELECT Id, Opportunity__c, Amount__c, DueDate__c, Order__c, Term__c
			FROM OpportunityPayment__c
		];
		Set<Id> oppPaymentIds = new Set<Id>();
		for (OpportunityPayment__c oppPayment : oppPayments) {
			oppPaymentIds.add(oppPayment.Id);
		}
		Map<Id, OpportunityPayment__c> opportunityPaymentMapById = selector.getOpportunityPaymentWithInvoiceLineItemMapById(
			oppPaymentIds
		);
		System.assertEquals(oppPayments.size(), opportunityPaymentMapById.values().size());
		for (Id oppPaymentId : opportunityPaymentMapById.keySet()){
			OpportunityPayment__c targetOppPayment = opportunityPaymentMapById.get(oppPaymentId);
			if (targetOppPayment.Term__c == 'Reservation'){
				System.assertNotEquals(0, targetOppPayment.InvoiceLineItems__r.size());
			} else {
				System.assertEquals(0, targetOppPayment.InvoiceLineItems__r.size());
			}
		}
		Test.stopTest();
	}

	@isTest
	static void getOpportunityPaymentWithReceiptLineItemMapByIdTest(){
		Test.startTest();
		OpportunityPaymentSelector selector = OpportunityPaymentSelector.getInstance();
		List<OpportunityPayment__c> oppPayments = [
			SELECT Id, Opportunity__c, Amount__c, DueDate__c, Order__c, Term__c
			FROM OpportunityPayment__c
		];
		Set<Id> oppPaymentIds = new Set<Id>();
		for (OpportunityPayment__c oppPayment : oppPayments) {
			oppPaymentIds.add(oppPayment.Id);
		}
		Map<Id, OpportunityPayment__c> opportunityPaymentMapById = selector.getOpportunityPaymentWithReceiptLineItemMapById(
			oppPaymentIds
		);
		System.assertEquals(oppPayments.size(), opportunityPaymentMapById.values().size());
		for (Id oppPaymentId : opportunityPaymentMapById.keySet()){
			OpportunityPayment__c targetOppPayment = opportunityPaymentMapById.get(oppPaymentId);
			if (targetOppPayment.Term__c == 'Reservation'){
				System.assertNotEquals(0, targetOppPayment.Payment_Receipt_Line_Item__r.size());
			} else {
				System.assertEquals(0, targetOppPayment.Payment_Receipt_Line_Item__r.size());
			}
		}
		Test.stopTest();
	}
}