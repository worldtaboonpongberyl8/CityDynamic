@isTest
public with sharing class CreateRelatedInvFilesNSendEmailBatchTest {
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
	static void batchTest(){
		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);

		List<Opportunity> opportunities = [SELECT Id, Name, AccountId, DoNotSendInvoice__c FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();

		Account accountForUpdate = new Account();
		for (Opportunity opportunity : opportunities) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoice.DoNotSendInvoice__c = opportunity.DoNotSendInvoice__c;
			invoices.add(invoice);

			accountForUpdate.Id = opportunity.AccountId;
			accountForUpdate.Email__c = 'account@account.com';
		}
		insert invoices;
		update accountForUpdate;

		Test.startTest();
		Database.executeBatch(new CreateRelatedInvFilesAndSendEmailBatch(dueDate));
		Test.stopTest();

		set<Id> invoiceIdSet = new Set<Id>();
		for (Invoice__c invoice : invoices) {
			invoiceIdSet.add(invoice.Id);
		}

		List<ContentDocumentLink> contentDocLinkResults = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN: invoiceIdSet];
		System.assertEquals((invoices.size() + opportunities.size()), contentDocLinkResults.size());
	}
}