@isTest
public with sharing class InvoiceServiceTest {
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
	}

	@isTest
	static void getOppPaymentsMapByOppIdTest(){
		List<OpportunityPayment__c> oppPayments = [SELECT Id, Opportunity__c FROM OpportunityPayment__c];
		Set<Id> oppIdSet = new Set<Id>();
		for(OpportunityPayment__c oppPayment : oppPayments){
			oppIdSet.add(oppPayment.Opportunity__c);
		}

		Map<Id, List<OpportunityPayment__c>> oppPaymentsMapByOppId = InvoiceService.getInstance().getOppPaymentsMapByOppId(oppPayments);
		System.assertEquals(oppIdSet.size(), oppPaymentsMapByOppId.keySet().size());

		for(Id oppId : oppIdSet){
			System.assert(!(oppPaymentsMapByOppId.get(oppId)).isEmpty());
		}
	}

	@isTest
	static void getInvoiceMapByOppIdTest(){

		List<OpportunityPayment__c> oppPayments = [SELECT Id, Opportunity__c FROM OpportunityPayment__c];
		Set<Id> oppIdSet = new Set<Id>();
		for (OpportunityPayment__c oppPayment : oppPayments) {
			oppIdSet.add(oppPayment.Opportunity__c);
		}

		Map<Id, Opportunity> opportunityMapById = OpportunitySelector.getInstance().getOpportunityMapById(oppIdSet);
		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);

		Map<Id, Invoice__c> invoiceMapByOppId = InvoiceService.getInstance().getInvoiceMapByOppId(opportunityMapById, dueDate, invoiceDate);
		System.assertEquals(oppIdSet.size(), invoiceMapByOppId.keySet().size());

		for (Id oppId : invoiceMapByOppId.keySet()) {
			Opportunity opp = opportunityMapById.get(oppId);
			Invoice__c invoice = invoiceMapByOppId.get(oppId);

			System.assertEquals(oppId ,invoice.Opportunity__c);
			System.assertEquals(invoiceDate, invoice.InvoiceDate__c);
			System.assertEquals(dueDate, invoice.DueDate__c);
			System.assertEquals(opp.DoNotSendInvoice__c, invoice.DoNotSendInvoice__c);
			System.assertEquals(opp.Account.AddressEN__c, invoice.AccountAddress__c);
		}
	}

	@isTest
	static void updateInvoiceNoTest(){
		List<Opportunity> opps = [SELECT Id, Name, DoNotSendInvoice__c, Account.AddressEN__c FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();


		Date dueDate = Date.newInstance(2024, 11, 1);
		Date invoiceDate = Date.newInstance(2024, 10, 27);

		for (Opportunity opp : opps) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opp.Id, dueDate, invoiceDate, opp.DoNotSendInvoice__c, opp.Account.AddressEN__c);
			invoices.add(invoice);
		}

		insert invoices;

		Map<Id, Invoice__c> invoiceMapById = new Map<Id, Invoice__c>([SELECT Id, InvoiceNo__c, Opportunity__r.Project__r.ProjectCode__c, InvoiceDate__c FROM Invoice__c]);

		InvoiceService.getInstance().updateInvoiceNo(invoices);

		DateTime invoiceDT = DateTime.newInstance(invoiceDate.year(), invoiceDate.month(), invoiceDate.day());
		List<Invoice__c> results = [SELECT Id, InvoiceNo__c FROM Invoice__c];
		Integer index = 1;
		for (Invoice__c result : results) {
			Invoice__c invoice = invoiceMapById.get(result.Id);

			String expectedInvNo = 'IV-' + invoice.Opportunity__r.Project__r.ProjectCode__c + invoiceDT.format('yyMM') + '000'.left(3 - String.valueOf(index).length()) + index;
			System.assertEquals(expectedInvNo, result.InvoiceNo__c);

			index++;
		}
	}

	@isTest
	static void setInitailValuesFromInvoicesTest(){
		List<Invoice__c> invoices = new List<Invoice__c>();
		List<Id> invoiceIds = new List<Id>();
		List<Id> oppIds = new List<Id>();
		Set<Id> invoiceIdAndOppIdset = new Set<Id>();

		List<Opportunity> opps = [SELECT Id, Name, DoNotSendInvoice__c, Account.AddressEN__c FROM Opportunity];

		Date dueDate = Date.newInstance(2024, 11, 1);
		Date invoiceDate = Date.newInstance(2024, 10, 27);

		for (Opportunity opp : opps) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opp.Id, dueDate, invoiceDate, opp.DoNotSendInvoice__c, opp.Account.AddressEN__c);
			invoices.add(invoice);
		}

		insert invoices;


		InvoiceService.getInstance().setInitailValuesFromInvoices(invoices, invoiceIds, oppIds, invoiceIdAndOppIdset);

		System.assertEquals(invoices.size(), invoiceIds.size());
		System.assertEquals(invoices.size(), oppIds.size());
		System.assertEquals((invoices.size() + opps.size()), invoiceIdAndOppIdset.size());
	}

	@isTest
	static void getFormatNameMapWithRecordIdTest(){

		List<Opportunity> opps = [SELECT Id, Name, DoNotSendInvoice__c, Account.AddressEN__c FROM Opportunity];

		Date dueDate = Date.newInstance(2024, 11, 1);
		Date invoiceDate = Date.newInstance(2024, 10, 27);

		Integer oppIndex = 1;
		List<Invoice__c> invoices = new List<Invoice__c>();
		for (Opportunity opp : opps) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opp.Id, dueDate, invoiceDate, opp.DoNotSendInvoice__c, opp.Account.AddressEN__c);
			invoice.InvoiceNo__c = 'InvoiceNo-' + oppIndex;
			invoices.add(invoice);
			oppIndex++;
		}

		insert invoices;

		List<Invoice__c> invoiceAfterInserts = [SELECT Id, InvoiceNo__c, Opportunity__c, Opportunity__r.Project__r.ProjectCode__c, InvoiceDate__c FROM Invoice__c];
		Map<Id, Opportunity> oppMapById = new Map<Id, Opportunity>([SELECT Id, Project__r.ProjectCode__c, Unit__r.ProductCode FROM Opportunity]);

		List<Id> invoiceIds = new List<Id>();
		List<Id> oppIds = new List<Id>();
		for (Invoice__c invoiceAfterInsert : invoiceAfterInserts) {
			invoiceIds.add(invoiceAfterInsert.Id);
			oppIds.add(invoiceAfterInsert.Opportunity__c);
		}


		Map<Id, String> invoiceNoMapWithInvoiceId = InvoiceService.getInstance().getFormatNameMapWithRecordId('Invoice__c', 'Object', null, invoiceIds);
		Map<Id, String> invoiceDocNameMapWithInvoiceId = InvoiceService.getInstance().getFormatNameMapWithRecordId('Invoice__c', 'Document', 'Invoice', invoiceIds);
		Map<Id, String> paymentSummaryMapWithOppId = InvoiceService.getInstance().getFormatNameMapWithRecordId('Opportunity', 'Document', 'Payment Summary', oppIds);
		Map<Id, String> paymentNegativeCaseMapWithOppId = InvoiceService.getInstance().getFormatNameMapWithRecordId('Opportunity', 'Document', 'Payment Summary Test', oppIds);

		DateTime invoiceDT = DateTime.newInstance(invoiceDate.year(), invoiceDate.month(), invoiceDate.day());
		List<Invoice__c> results = [SELECT Id, InvoiceNo__c FROM Invoice__c];
		Integer index = 1;
		for (Invoice__c invoiceAfterInsert : invoiceAfterInserts) {
			Opportunity opp = oppMapById.get(invoiceAfterInsert.Opportunity__c);

			String expectedInvNo = 'IV-' + invoiceAfterInsert.Opportunity__r.Project__r.ProjectCode__c + invoiceDT.format('yyMM') + '000'.left(3 - String.valueOf(index).length()) + index;
			String expectedInvDoc = 'InvoiceNo-' + index;
			String expectedPaymentSummary = 'Payment Summary-' + opp.Project__r.ProjectCode__c + '-' + opp.Unit__r.ProductCode;
			System.assertEquals(expectedInvNo, invoiceNoMapWithInvoiceId.get(invoiceAfterInsert.Id));
			System.assertEquals(expectedInvDoc, invoiceDocNameMapWithInvoiceId.get(invoiceAfterInsert.Id));
			System.assertEquals(expectedPaymentSummary, paymentSummaryMapWithOppId.get(opp.Id));

			index++;
		}

		System.assertEquals(0, paymentNegativeCaseMapWithOppId.keySet().size());
	}

	@isTest
	static void insertInvoiceAndRelatedRecordsTest(){
		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);

		List<OpportunityPayment__c> oppPayments = [SELECT Id, Opportunity__c, Term__c, DueDate__c, Amount__c, Remaining__c, PaymentStatus__c
			FROM OpportunityPayment__c
			WHERE Remaining__c > 0
			   AND IsMasterData__c = true
			   AND DueDate__c = :dueDate
			AND Opportunity__r.StageName != 'Closed Lost'
			ORDER BY Opportunity__c
		];

		InvoiceService.getInstance().insertInvoiceAndRelatedRecords(oppPayments, dueDate, invoiceDate);

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
	static void insertInvoiceAndRelatedRecordsNegativeTest(){
		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);

		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>();

		InvoiceService.getInstance().insertInvoiceAndRelatedRecords(oppPayments, dueDate, invoiceDate);

		Set<Id> oppIdSet = new Set<Id>();
		for (OpportunityPayment__c oppPayment : oppPayments) {
			oppIdSet.add(oppPayment.Opportunity__c);
		}

		List<Invoice__c> invoiceResults = [SELECT Id, InvoiceNo__c FROM Invoice__c];
		List<InvoiceLineItem__c> invoiceLineResults = [SELECT Id FROM InvoiceLineItem__c];
		System.assert(invoiceResults.isEmpty());
		System.assert(invoiceLineResults.isEmpty());
	}

	@isTest
	static void insertInvoiceAndPaymentSummaryFilesTest(){
		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);

		List<Opportunity> opportunities = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();

		for (Opportunity opportunity : opportunities) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoices.add(invoice);
		}
		insert invoices;

		set<Id> invoiceIdSet = new Set<Id>();
		for (Invoice__c invoice : invoices) {
			invoiceIdSet.add(invoice.Id);
		}

		InvoiceService.getInstance().insertInvoiceAndPaymentSummaryFiles(invoices);

		List<ContentDocumentLink> contentDocLinkResults = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN: invoiceIdSet];
		System.assertEquals((invoices.size() + opportunities.size()), contentDocLinkResults.size());
	}

	@isTest
	static void sendEmailWithAttachmentToAccountEmailTest(){
		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		DateTime invoiceDT = DateTime.newInstance(invoiceDate.year(), invoiceDate.month(), invoiceDate.day());

		List<Opportunity> opportunities = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c, AccountId, ContactPerson__c, DoNotSendInvoice__c FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();

		Account accountForUpdate = new Account();
		Integer index = 1;
		for (Opportunity opportunity : opportunities) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
            invoice.DoNotSendInvoice__c = opportunity.DoNotSendInvoice__c;
			invoice.InvoiceNo__c = 'IV-' + invoice.Opportunity__r.Project__r.ProjectCode__c + invoiceDT.format('yyMM') + '000'.left(3 - String.valueOf(index).length()) + index;
			invoices.add(invoice);

			accountForUpdate.Id = opportunity.AccountId;
			accountForUpdate.Email__c = 'account@account.com';
			index++;
		}

		insert invoices;
		update accountForUpdate;

		Map<Id, ContentVersion> contentVersionMapByRecordId = new Map<Id, ContentVersion>();
		for (Invoice__c invoice : invoices) {
			contentVersionMapByRecordId.put(
				invoice.Id,
				DataMaker.getInstance().createContentVersion(invoice.InvoiceNo__c, (invoice.InvoiceNo__c + '.pdf'))
			);
		}
		insert contentVersionMapByRecordId.values();

		Set<Id> contentVerIdSet = new Set<Id>();
		Map<Id, Id> recordIdMapByContentVerId = new Map<Id, Id>();
		for (Id recordId : contentVersionMapByRecordId.keySet()) {
			recordIdMapByContentVerId.put(contentVersionMapByRecordId.get(recordId).Id, recordId);
			contentVerIdSet.add(contentVersionMapByRecordId.get(recordId).Id);
		}

		List<ContentVersion> contentVersions = [
				SELECT Id, ContentDocumentId, Title, VersionData
				FROM ContentVersion
				WHERE Id IN: contentVerIdSet
					AND IsLatest = true
		];

		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		for (ContentVersion contentVersion : contentVersions) {
			contentDocumentLinks.add(
				new ContentDocumentLink(
					LinkedEntityId = recordIdMapByContentVerId.get(contentVersion.Id),
					ContentDocumentId = contentVersion.ContentDocumentId
				)
			);
		}
		insert contentDocumentLinks;

		set<Id> invoiceIdSet = new Set<Id>();
		for (Invoice__c invoice : invoices) {
			invoiceIdSet.add(invoice.Id);
		}

		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account dummyAccount = DataMaker.getInstance().createAccount(recordTypeId, 'Dummy Accouny');
		insert dummyAccount;
		Contact dummyContact = DataMaker.getInstance().createContact(dummyAccount.Id, 'Dummy', 'Contact', 'dummyContact@dummy.com', '0111111111');
		dummyContact.IsDummy__c = true;
		insert dummyContact;

		List<Invoice__c> invoiceForSendEmails = [
			SELECT Id, Name, Opportunity__c, InvoiceDate__c, DueDate__c, DoNotSendInvoice__c, Opportunity__r.ContactPerson__c,
				Opportunity__r.ContactPerson__r.Name, Opportunity__r.ContactPerson__r.Email, Opportunity__r.Account.Email__c
			FROM Invoice__c
		];
		Messaging.SendEmailResult[] results = InvoiceService.getInstance().sendEmailWithAttachment(invoiceForSendEmails);

		List<Invoice__c> sendEmailResults = [
			SELECT Id, Opportunity__c, InvoiceDate__c, DueDate__c, DoNotSendInvoice__c, Opportunity__r.ContactPerson__r.Email,
				Opportunity__r.Account.Email__c
			FROM Invoice__c
			WHERE DueDate__c =: dueDate
				AND DoNotSendInvoice__c = false
		];

		system.assertEquals(sendEmailResults.size(), results.size(), 'An email should be sent');

		for (Messaging.SendEmailResult result : results) {
			// System.assertEquals(true, result.success);
		}
	}

	@isTest
	static void sendEmailWithAttachmentToContactEmailTest(){
		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		DateTime invoiceDT = DateTime.newInstance(invoiceDate.year(), invoiceDate.month(), invoiceDate.day());

		List<Opportunity> opportunities = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c, AccountId, ContactPerson__c, DoNotSendInvoice__c FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();

		Contact oppContact = DataMaker.getInstance().createContact(opportunities.get(0).AccountId, 'Test', 'Contact', 'contact@contact.com', '0111111111');
		insert oppContact;

		Integer index = 1;
		List<Opportunity> oppForUpdates = new List<Opportunity>();
		for (Opportunity opportunity : opportunities) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
            invoice.DoNotSendInvoice__c = opportunity.DoNotSendInvoice__c;
			invoice.InvoiceNo__c = 'IV-' + invoice.Opportunity__r.Project__r.ProjectCode__c + invoiceDT.format('yyMM') + '000'.left(3 - String.valueOf(index).length()) + index;
			invoices.add(invoice);

			oppForUpdates.add(
				new Opportunity(
					Id = opportunity.Id,
					ContactPerson__c = oppContact.Id
				)
			);
			index++;
		}
		update oppForUpdates;
		insert invoices;

		Map<Id, ContentVersion> contentVersionMapByRecordId = new Map<Id, ContentVersion>();
		for (Invoice__c invoice : invoices) {
			contentVersionMapByRecordId.put(
				invoice.Id,
				DataMaker.getInstance().createContentVersion(invoice.InvoiceNo__c, (invoice.InvoiceNo__c + '.pdf'))
			);
		}
		insert contentVersionMapByRecordId.values();

		Set<Id> contentVerIdSet = new Set<Id>();
		Map<Id, Id> recordIdMapByContentVerId = new Map<Id, Id>();
		for (Id recordId : contentVersionMapByRecordId.keySet()) {
			recordIdMapByContentVerId.put(contentVersionMapByRecordId.get(recordId).Id, recordId);
			contentVerIdSet.add(contentVersionMapByRecordId.get(recordId).Id);
		}

		List<ContentVersion> contentVersions = [
				SELECT Id, ContentDocumentId, Title, VersionData
				FROM ContentVersion
				WHERE Id IN: contentVerIdSet
					AND IsLatest = true
		];

		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		for (ContentVersion contentVersion : contentVersions) {
			contentDocumentLinks.add(
				new ContentDocumentLink(
					LinkedEntityId = recordIdMapByContentVerId.get(contentVersion.Id),
					ContentDocumentId = contentVersion.ContentDocumentId
				)
			);
		}
		insert contentDocumentLinks;

		set<Id> invoiceIdSet = new Set<Id>();
		for (Invoice__c invoice : invoices) {
			invoiceIdSet.add(invoice.Id);
		}

		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account dummyAccount = DataMaker.getInstance().createAccount(recordTypeId, 'Dummy Accouny');
		insert dummyAccount;
		Contact dummyContact = DataMaker.getInstance().createContact(dummyAccount.Id, 'Dummy', 'Contact', 'dummyContact@dummy.com', '0111111111');
		dummyContact.IsDummy__c = true;
		insert dummyContact;

		List<Invoice__c> invoiceForSendEmails = [
			SELECT Id, Name, Opportunity__c, InvoiceDate__c, DueDate__c, DoNotSendInvoice__c, Opportunity__r.ContactPerson__c,
				Opportunity__r.ContactPerson__r.Name, Opportunity__r.ContactPerson__r.Email, Opportunity__r.Account.Email__c
			FROM Invoice__c
		];
		Messaging.SendEmailResult[] results = InvoiceService.getInstance().sendEmailWithAttachment(invoiceForSendEmails);

		List<Invoice__c> sendEmailResults = [
			SELECT Id, Opportunity__c, InvoiceDate__c, DueDate__c, DoNotSendInvoice__c, Opportunity__r.ContactPerson__r.Email,
				Opportunity__r.Account.Email__c
			FROM Invoice__c
			WHERE DueDate__c =: dueDate
				AND DoNotSendInvoice__c = false
		];

		System.debug('sendEmailResults: ' + sendEmailResults);
		System.debug('results: ' + results);

		system.assertEquals(sendEmailResults.size(), results.size(), 'An email should be sent');

		for (Messaging.SendEmailResult result : results) {
			// System.assertEquals(true, result.success);
		}
	}

	@isTest
	static void sendEmailWithAttachmentToNoEmailTest(){
		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);

		List<Opportunity> opportunities = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c, AccountId, ContactPerson__c FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();

		for (Opportunity opportunity : opportunities) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoices.add(invoice);
		}
		insert invoices;

		set<Id> invoiceIdSet = new Set<Id>();
		for (Invoice__c invoice : invoices) {
			invoiceIdSet.add(invoice.Id);
		}

		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account dummyAccount = DataMaker.getInstance().createAccount(recordTypeId, 'Dummy Accouny');
		insert dummyAccount;
		Contact dummyContact = DataMaker.getInstance().createContact(dummyAccount.Id, 'Dummy', 'Contact', 'dummyContact@dummy.com', '0111111111');
		dummyContact.IsDummy__c = true;
		insert dummyContact;

		List<Invoice__c> invoiceForSendEmails = [
			SELECT Id, Name, Opportunity__c, InvoiceDate__c, DueDate__c, DoNotSendInvoice__c, Opportunity__r.ContactPerson__c,
				Opportunity__r.ContactPerson__r.Name, Opportunity__r.ContactPerson__r.Email, Opportunity__r.Account.Email__c
			FROM Invoice__c
		];
		Messaging.SendEmailResult[] results = InvoiceService.getInstance().sendEmailWithAttachment(invoiceForSendEmails);

		List<Invoice__c> sendEmailResults = [
			SELECT Id, Opportunity__c, InvoiceDate__c, DueDate__c, DoNotSendInvoice__c, Opportunity__r.ContactPerson__r.Email,
				Opportunity__r.Account.Email__c
			FROM Invoice__c
			WHERE DueDate__c =: dueDate
				AND DoNotSendInvoice__c = false
		];

		system.assertEquals(null, results, 'An email should not be sent');
	}

	@isTest
	static void getCancelInvoiceByOppIdSetTest(){
		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		Set<Id> oppIdSet = new Set<Id>();
		List<Invoice__c> invoices = new List<Invoice__c>();

		List<Opportunity> opportunities = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c, AccountId, ContactPerson__c FROM Opportunity];

		for (Opportunity opportunity : opportunities) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoices.add(invoice);
			oppIdSet.add(opportunity.Id);
		}

		insert invoices;

		List<Invoice__c> invoiceResults = InvoiceService.getInstance().getCancelInvoiceByOppIdSet(oppIdSet);

		System.assertEquals(invoices.size(), invoiceResults.size());
		for (Invoice__c invoiceResult : invoiceResults) {
			System.assertEquals(true, invoiceResult.IsCancel__c);
			System.assertEquals('Closed Lost', invoiceResult.CancelReason__c);
		}
	}

	@isTest
	static void insertInvoicesTest(){
		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		List<Invoice__c> invoices = new List<Invoice__c>();

		List<Opportunity> opportunities = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c, AccountId, ContactPerson__c FROM Opportunity];

		for (Opportunity opportunity : opportunities) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoices.add(invoice);
		}

		Database.SaveResult[] insertResults = InvoiceService.getInstance().insertInvoices(invoices);

		List<Id> invoiceIds = new List<Id>();
		for (Database.SaveResult insertResult : insertResults) {
			System.assertEquals(true, insertResult.success);
			System.assertNotEquals(null, insertResult.id);

			invoiceIds.add(insertResult.id);
		}

		List<Invoice__c> invoiceResults = [SELECT Id FROM Invoice__c WHERE Id IN: invoiceIds];
		System.assertEquals(invoices.size(), invoiceResults.size());
	}

	@isTest
	static void updateInvoicesTest(){
		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		List<Invoice__c> invoices = new List<Invoice__c>();

		List<Opportunity> opportunities = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c, AccountId, ContactPerson__c FROM Opportunity];

		for (Opportunity opportunity : opportunities) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoices.add(invoice);
		}
		insert invoices;

		List<Invoice__c> invoiceForUpdates = new List<Invoice__c>();
		for (Integer i = 0; i < invoices.size(); i++) {
			Invoice__c invoice = invoices.get(i);

			invoiceForUpdates.add(
				new Invoice__c(
					Id = invoice.Id,
					InvoiceNo__c = 'InvoiceNo ' + (i+1)
				)
			);
		}
		Map<Id, Invoice__c> invoiceMapById = new Map<Id, Invoice__c>(invoiceForUpdates);

		Database.SaveResult[] updateResults = InvoiceService.getInstance().updateInvoices(invoiceForUpdates);

		List<Id> invoiceIds = new List<Id>();
		for (Database.SaveResult updateResult : updateResults) {
			System.assertEquals(true, updateResult.success);
			System.assertNotEquals(null, updateResult.id);

			invoiceIds.add(updateResult.id);
		}

		List<Invoice__c> invoiceResults = [SELECT Id, InvoiceNo__c FROM Invoice__c WHERE Id IN: invoiceIds];
		System.assertEquals(invoices.size(), invoiceResults.size());

		for (Invoice__c invoiceResult : invoiceResults) {
			System.assertEquals(invoiceMapById.get(invoiceResult.Id).InvoiceNo__c, invoiceResult.InvoiceNo__c);
		}
	}
}