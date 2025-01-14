public with sharing class InvoiceService {
	public static InvoiceService instance;
	public static InvoiceService getInstance() {
		if (instance == null) {
			instance = new InvoiceService();
		}
		return instance;
	}

	private final String OBJECT_API_NAME = 'Invoice__c';
	private final String PDF_FORM_INVOICE = 'InvoiceForm';
	private final String PDF_FORM_PAYMENT_SUMMARY = 'PaymentSummaryForm';

	public void insertInvoiceAndRelatedRecords(List<OpportunityPayment__c> oppPayments, Date dueDate, Date invoiceDate) {
		Map<Id, List<OpportunityPayment__c>> oppPaymentMapByOppId = getOppPaymentsMapByOppId(oppPayments);

		if (oppPaymentMapByOppId.isEmpty()) {
			return;
		}

		Map<Id, Opportunity> opportunityMapById = OpportunitySelector.getInstance().getOpportunityMapById(oppPaymentMapByOppId.keySet());
		Map<Id, Invoice__c> invoiceMapByOppId = getInvoiceMapByOppId(opportunityMapById, dueDate, invoiceDate);
		insertInvoices(invoiceMapByOppId.values());
		updateInvoiceNo(invoiceMapByOppId.values());

		List<InvoiceLineItem__c> invoiceLineItems = InvoiceLineItemService.getInstance().getNewInvoiceLineItems(invoiceMapByOppId, oppPaymentMapByOppId);
		InvoiceLineItemService.getInstance().insertInvoiceLineItems(invoiceLineItems);
	}

	public void insertInvoiceAndPaymentSummaryFiles(List<Invoice__c> invoices) {
		List<Id> oppIds = new List<Id>();
		List<Id> invoiceIds = new List<Id>();
		Map<Id, Id> invoiceIdMapByOppId = new Map<Id, Id>();
		for (Invoice__c invoice : invoices) {
			invoiceIds.add(invoice.Id);
			oppIds.add(invoice.Opportunity__c);
			invoiceIdMapByOppId.put(invoice.Opportunity__c, invoice.Id);
		}

		// query 2
		Map<Id, String> invoiceNameMapWithInvoiceId = getFormatNameMapWithRecordId(OBJECT_API_NAME, 'Document', 'Invoice', invoiceIds);
		// query 2
		Map<Id, String> paymentSummaryNameMapWithOppId = getFormatNameMapWithRecordId('Opportunity', 'Document', 'Payment Summary', oppIds);

		// query 2N + 1
		// ต้องการ save file ที่ record ของตัวเองเลย(invoice)
		// ทุกครั้งที่ createPdfFileToRecord จะแตก async ออกมาเป็น 1 task
		// เอกสาร invoice
		PDFUtility.getInstance().createPdfFileToRecord(PDF_FORM_INVOICE, invoiceNameMapWithInvoiceId, invoiceIds, null);

		// query 3N + อีก 1
		// ต้องการ save file ที่ record ของ invoice
		// ทุกครั้งที่ createPdfFileToRecord จะแตก async ออกมาเป็น 1 task
		// เอกสาร payment summary
		PDFUtility.getInstance().createPdfFileToRecord(PDF_FORM_PAYMENT_SUMMARY, paymentSummaryNameMapWithOppId, oppIds, invoiceIdMapByOppId);
	}

	// ทำการสร้างเอกสาร Invoice และ Payment Summary และทำการส่ง email ไปหาลูกค้าโดยการแนบเอกสาร Invoice และ Payment Summary ไปท้าย email
	public Messaging.SendEmailResult[] sendEmailWithAttachment(List<Invoice__c> invoices) {
		// List<Invoice__c> invoiceForSendEmails = InvoiceSelector.getInstance().getForSendEmail(dueDate);
		List<Invoice__c> invoiceForSendEmails = new List<Invoice__c>();
		for (Invoice__c invoice : invoices) {
			if(!invoice.DoNotSendInvoice__c){
				invoiceForSendEmails.add(invoice);
			}
		}

		List<Id> invoiceIds = new List<Id>();
		List<Id> oppIds = new List<Id>();
		Set<Id> invoiceIdAndOppIdset = new Set<Id>();
		setInitailValuesFromInvoices(invoiceForSendEmails, invoiceIds, oppIds, invoiceIdAndOppIdset);

		Map<Id, String> invoiceNoMapWithInvoiceId = getFormatNameMapWithRecordId(OBJECT_API_NAME, 'Document', 'Invoice', invoiceIds);
		Map<Id, String> paymentSummaryNameMapWithInvoiceId = getFormatNameMapWithRecordId('Opportunity', 'Document', 'Payment Summary', oppIds);
		Map<Id, List<Id>> recordContentVerIdsMapByRecordId = ContentVersionService.getInstance().getRecordContentVerIdsMapByRecordIdForInvoice(
			invoiceIdAndOppIdset,
			invoiceNoMapWithInvoiceId,
			paymentSummaryNameMapWithInvoiceId
		);

		List<Messaging.SingleEmailMessage> singleEmails = new List<Messaging.SingleEmailMessage>();
		Id orgWideId = OrgWideEmailAddressSelector.getInstance().getByAddress(EmailUtility.getInstance().emailForOrgWide).get(0).Id;

		List<EmailTemplate> emailTemplates = EmailTemplateSelector.getInstance().getByDeveloperName(
			new Set<String>{'SendInvoiceToCustomer'}
		);

		EmailUtility emailUtility = EmailUtility.getInstance();
		EmailTemplate emailTemplate = emailTemplates.get(0);
		Contact dummyContact = ContactSelector.getInstance().getDummy();
		List<Messaging.SingleEmailMessage> tempEmails = new List<Messaging.SingleEmailMessage>();
		for (Invoice__c invoiceForSendEmail : invoiceForSendEmails) {
			List<String> toAddresses = new List<String>();
			List<Messaging.EmailFileAttachment> emailFileAttachments = new List<Messaging.EmailFileAttachment>();

			if(String.isBlank(invoiceForSendEmail.Opportunity__r.ContactPerson__r.Email)){
				if(String.isNotBlank(invoiceForSendEmail.Opportunity__r.Account.Email__c)){
					toAddresses.add(invoiceForSendEmail.Opportunity__r.Account.Email__c);
				}
			}
			else{
				toAddresses.add(invoiceForSendEmail.Opportunity__r.ContactPerson__r.Email);
			}

			if(toAddresses.isEmpty()){
				continue;
			}

			List<Id> ctVersionIds = new List<Id>();
			Messaging.SingleEmailMessage tempEmail = emailUtility.getSingleEmail(
				orgWideId,
				emailTemplate,
				toAddresses,
				null,
				emailFileAttachments,
				recordContentVerIdsMapByRecordId.get(invoiceForSendEmail.Id),
				invoiceForSendEmail.Id,
				dummyContact.Id
			);

			tempEmails.add(tempEmail);
		}

		if(!tempEmails.isEmpty()){
			emailUtility.fakeSendEmails(tempEmails);

			List<Messaging.SingleEmailMessage> actualEmails = new List<Messaging.SingleEmailMessage>();
			for (Messaging.SingleEmailMessage tempEmail : tempEmails) {
				Messaging.SingleEmailMessage actualEmail = emailUtility.getSingleEmailFromTempEmail(tempEmail);
				actualEmails.add(actualEmail);
			}

			return emailUtility.sendAllEmailMessage(actualEmails);
		}

		return null;
	}

	public Database.SaveResult[] insertInvoices(List<Invoice__c> invoices) {
		Database.SaveResult[] insertResults;

		if (!invoices.isEmpty()) {
			insertResults = Database.insert(invoices, false);
		}

		return insertResults;
	}

	public Database.SaveResult[] updateInvoices(List<Invoice__c> invoices) {
		Database.SaveResult[] updateResults;

		if (!invoices.isEmpty()) {
			updateResults = Database.update(invoices, false);
		}

		return updateResults;
	}

	public List<Invoice__c> getCancelInvoiceByOppIdSet(Set<Id> oppIdSet){
		List<Invoice__c> invoiceForCancels = new List<Invoice__c>();

		List<Invoice__c> invoices = InvoiceSelector.getInstance().getByOppIdSet(oppIdSet);
		for (Invoice__c invoice : invoices) {
			invoiceForCancels.add(
				new Invoice__c(
					Id = invoice.Id,
					IsCancel__c = true,
					CancelReason__c = 'Closed Lost'
				)
			);
		}

		return invoiceForCancels;
	}

	// ----- Start Private Service -----
	@TestVisible
	private Map<Id, List<OpportunityPayment__c>> getOppPaymentsMapByOppId(List<OpportunityPayment__c> oppPayments) {
		Map<Id, List<OpportunityPayment__c>> oppPaymentsMapByOppId = new Map<Id, List<OpportunityPayment__c>>();
		for (OpportunityPayment__c oppPayment : oppPayments) {
			List<OpportunityPayment__c> opportunityPayments = oppPaymentsMapByOppId.get(oppPayment.Opportunity__c);

			if (opportunityPayments == null) {
				oppPaymentsMapByOppId.put(oppPayment.Opportunity__c, new List<OpportunityPayment__c>{ oppPayment });
			} else {
				opportunityPayments.add(oppPayment);
			}
		}
		return oppPaymentsMapByOppId;
	}

	@TestVisible
	private Map<Id, Invoice__c> getInvoiceMapByOppId(Map<Id, Opportunity> opportunityMapById, Date dueDate, Date invoiceDate) {
		Map<Id, Invoice__c> invoiceMapByOppId = new Map<Id, Invoice__c>();
		for (Id oppId : opportunityMapById.keySet()) {
			Opportunity opportunity = opportunityMapById.get(oppId);
			invoiceMapByOppId.put(
				oppId,
				new Invoice__c(
					Opportunity__c = oppId,
					InvoiceDate__c = invoiceDate,
					DueDate__c = dueDate,
					DoNotSendInvoice__c = opportunity.DoNotSendInvoice__c,
					AccountAddress__c = opportunity.Account.AddressEN__c
				)
			);
		}
		return invoiceMapByOppId;
	}

	@TestVisible
	private void updateInvoiceNo(List<Invoice__c> invoices) {
		List<Id> invoiceIds = new List<Id>();
		for (Invoice__c invoice : invoices) {
			invoiceIds.add(invoice.Id);
		}

		Map<Id, String> invoiceNoMapWithInvoiceId = getFormatNameMapWithRecordId(OBJECT_API_NAME, 'Object', null, invoiceIds);

		List<Invoice__c> invoiceForUpdates = new List<Invoice__c>();
		for (Id invoiceId : invoiceNoMapWithInvoiceId.keySet()) {
			String invoiceNo = invoiceNoMapWithInvoiceId.get(invoiceId);
			invoiceForUpdates.add(
				new Invoice__c(
					Id = invoiceId,
					InvoiceNo__c = invoiceNoMapWithInvoiceId.get(invoiceId)
				)
			);
		}

		updateInvoices(invoiceForUpdates);

	}

	@TestVisible
	private void setInitailValuesFromInvoices(List<Invoice__c> invoiceForSendEmails, List<Id> invoiceIds, List<Id> oppIds, Set<Id> invoiceIdAndOppIdset) {
		for (Invoice__c invoiceForSendEmail : invoiceForSendEmails) {
			invoiceIds.add(invoiceForSendEmail.Id);
			oppIds.add(invoiceForSendEmail.Opportunity__c);

			invoiceIdAndOppIdset.add(invoiceForSendEmail.Id);
			invoiceIdAndOppIdset.add(invoiceForSendEmail.Opportunity__c);
		}
	}

	@TestVisible
	private Map<Id, String> getFormatNameMapWithRecordId(String objectApiName, String purpose, String documentTemplate, List<Id> recordIds) {
		List<NameFormattingMasterData__c> nameFormattingMasterDatas = NameFormattingMasterDataSelector.getInstance()
			.getByObjTypePurposeDocTemplate(objectApiName, 'Format', purpose, documentTemplate);

		if(nameFormattingMasterDatas.isEmpty()){
			return new Map<Id, String>();
		}

		return RunningNumberUtility.getInstance()
			.generateReplacedFormatName(nameFormattingMasterDatas.get(0), recordIds, objectApiName);
	}
	// ----- End Private Service -----
}