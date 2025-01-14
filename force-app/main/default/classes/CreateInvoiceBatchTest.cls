@isTest
public with sharing class CreateInvoiceBatchTest {
	@TestSetup
	static void makeData(){
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
		Product2 unit1 = dataMaker.createUnit(
			'Test Product',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		Product2 unit2 = dataMaker.createUnit(
			'Test Product 2',
			'PP02',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert new List<Product2>{ unit1, unit2 };
		// Create Promotion Master
		PromotionMaster__c promotionMaster = dataMaker.craeteActivePromotionMaster(testProject.Id,unit1.Id,'ส่วนลด','Sales','Discount (ส่วนลด)','Add Detail','Description',500.00);
		insert promotionMaster;
		// Create Account
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'United Oil & Gas Corp.');
		insert account;
		// Create Opportunity
		OpportunityTriggerHandler oppTriggerHandler = OpportunityTriggerHandler.getInstance();
		oppTriggerHandler.setBypass();

		Opportunity opportunity1 = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.newInstance(2024, 10, 1),
			'Open',
			unit1.Id,
			'Foreign',
			null,
			testProject.Id
		);
		Opportunity opportunity2 = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.newInstance(2024, 10, 1),
			'Open',
			unit2.Id,
			'Foreign',
			null,
			testProject.Id
		);
		opportunity2.DoNotSendInvoice__c = true;
		insert new List<Opportunity> { opportunity1, opportunity2 };

		oppTriggerHandler.clearBypass();

		// Create Opp Payments
		// opportunity 1
		OpportunityPayment__c reservationOppPaymentOpp1 = dataMaker.createOpportunityPayment(
			opportunity1.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		OpportunityPayment__c contractOppPaymentOpp1 = dataMaker.createOpportunityPayment(
			opportunity1.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 27),
			2
		);
		OpportunityPayment__c installmentOppPaymentOpp1 = dataMaker.createOpportunityPayment(
			opportunity1.Id,
			'Installment 1',
			10000000,
			Date.newInstance(2024, 10, 27),
			3
		);
		OpportunityPayment__c transferOppPaymentOpp1 = dataMaker.createOpportunityPayment(
			opportunity1.Id,
			'Transfer',
			4850000,
			Date.newInstance(2025, 10, 27),
			4
		);

		// opportunity 2
		OpportunityPayment__c reservationOppPaymentOpp2 = dataMaker.createOpportunityPayment(
			opportunity2.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		OpportunityPayment__c contractOppPaymentOpp2 = dataMaker.createOpportunityPayment(
			opportunity2.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 25),
			2
		);
		OpportunityPayment__c installmentOppPaymentOpp2 = dataMaker.createOpportunityPayment(
			opportunity2.Id,
			'Installment 1',
			10000000,
			Date.newInstance(2024, 10, 25),
			3
		);
		OpportunityPayment__c transferOppPaymentOpp2 = dataMaker.createOpportunityPayment(
			opportunity2.Id,
			'Transfer',
			4850000,
			Date.newInstance(2025, 10, 25),
			4
		);

		// all oppPayments
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPaymentOpp1,
			contractOppPaymentOpp1,
			installmentOppPaymentOpp1,
			transferOppPaymentOpp1,
			reservationOppPaymentOpp2,
			contractOppPaymentOpp2,
			installmentOppPaymentOpp2,
			transferOppPaymentOpp2
		};
		insert oppPayments;

		NameFormattingMasterData__c invoiceFormatObject = dataMaker.createNameFormattingMasterData(
			'Invoice__c', 'Format', 'Object', 'IV-{Opportunity__r.Project__r.ProjectCode__c}{InvoiceDate__c:FORMATDATE:yyMM}{RUNNINGNUMBER:000}', 1, null
		);

		NameFormattingMasterData__c invoiceFormatDocument = dataMaker.createNameFormattingMasterData(
			'Invoice__c', 'Format', 'Document', '{InvoiceNo__c}', 1, 'Invoice'
		);

		NameFormattingMasterData__c paymentFormatDocument = dataMaker.createNameFormattingMasterData(
			'Opportunity', 'Format', 'Document', 'Payment Summary-{Project__r.ProjectCode__c}-{Unit__r.ProductCode}', 1, 'Payment Summary'
		);

		insert new List<NameFormattingMasterData__c>{invoiceFormatObject, invoiceFormatDocument, paymentFormatDocument};

		insert dataMaker.createInvoiceSetting();

		Account dummyAccount = dataMaker.createAccount(recordTypeId, 'Dummy Accouny');
		insert dummyAccount;
		Contact dummyContact = dataMaker.createContact(dummyAccount.Id, 'Dummy', 'Contact', 'dummyContact@dummy.com', '0111111111');
		dummyContact.IsDummy__c = true;
		insert dummyContact;
	}

	@isTest
	static void batchTodayTest(){
		Test.startTest();
		CreateInvoiceBatch createInvoiceBatch = new CreateInvoiceBatch();
		Database.executeBatch(createInvoiceBatch);
		Test.stopTest();

		Date dueDate = createInvoiceBatch.dueDate;
		Date invoiceDate = createInvoiceBatch.invoiceDate;

		List<OpportunityPayment__c> oppPayments = [SELECT Id, Opportunity__c, Term__c, DueDate__c, Amount__c, Remaining__c, PaymentStatus__c
			FROM OpportunityPayment__c
			WHERE Remaining__c > 0
			   AND IsMasterData__c = true
			   AND DueDate__c = :dueDate
			AND Opportunity__r.StageName != 'Closed Lost'
			ORDER BY Opportunity__c
		];

		Set<Id> oppIdSet = new Set<Id>();
		for (OpportunityPayment__c oppPayment : oppPayments) {
			oppIdSet.add(oppPayment.Opportunity__c);
		}

		List<Invoice__c> invoiceResults = [SELECT Id, InvoiceNo__c, Opportunity__r.Project__r.ProjectCode__c FROM Invoice__c];
		List<InvoiceLineItem__c> invoiceLineResults = [SELECT Id FROM InvoiceLineItem__c];
		System.assertEquals(oppIdSet.size(), invoiceResults.size());
		System.assertEquals(oppPayments.size(), invoiceLineResults.size());

		DateTime invoiceDT = DateTime.newInstance(invoiceDate.year(), invoiceDate.month(), invoiceDate.day());
		Integer index = 1;
		for (Invoice__c invoiceResult : invoiceResults) {
			String expectedInvNo = 'IV-' + invoiceResult.Opportunity__r.Project__r.ProjectCode__c + invoiceDT.format('yyMM') + '000'.left(3 - String.valueOf(index).length()) + index;
			System.assertEquals(expectedInvNo, invoiceResult.InvoiceNo__c);

			index++;
		}
	}

	@isTest
	static void batchSpecificDateTest(){
		Test.startTest();
		CreateInvoiceBatch createInvoiceBatch = new CreateInvoiceBatch(Date.newInstance(2024, 10, 20));
		Database.executeBatch(createInvoiceBatch);
		Test.stopTest();

		Date dueDate = createInvoiceBatch.dueDate;
		Date invoiceDate = createInvoiceBatch.invoiceDate;

		List<OpportunityPayment__c> oppPayments = [SELECT Id, Opportunity__c, Term__c, DueDate__c, Amount__c, Remaining__c, PaymentStatus__c
			FROM OpportunityPayment__c
			WHERE Remaining__c > 0
			   AND IsMasterData__c = true
			   AND DueDate__c = :dueDate
			AND Opportunity__r.StageName != 'Closed Lost'
			ORDER BY Opportunity__c
		];

		Set<Id> oppIdSet = new Set<Id>();
		for (OpportunityPayment__c oppPayment : oppPayments) {
			oppIdSet.add(oppPayment.Opportunity__c);
		}

		List<Invoice__c> invoiceResults = [SELECT Id, InvoiceNo__c, Opportunity__r.Project__r.ProjectCode__c FROM Invoice__c];
		List<InvoiceLineItem__c> invoiceLineResults = [SELECT Id FROM InvoiceLineItem__c];
		System.assertEquals(oppIdSet.size(), invoiceResults.size());
		System.assertEquals(oppPayments.size(), invoiceLineResults.size());

		DateTime invoiceDT = DateTime.newInstance(invoiceDate.year(), invoiceDate.month(), invoiceDate.day());
		Integer index = 1;
		for (Invoice__c invoiceResult : invoiceResults) {
			String expectedInvNo = 'IV-' + invoiceResult.Opportunity__r.Project__r.ProjectCode__c + invoiceDT.format('yyMM') + '000'.left(3 - String.valueOf(index).length()) + index;
			System.assertEquals(expectedInvNo, invoiceResult.InvoiceNo__c);

			index++;
		}
	}
}