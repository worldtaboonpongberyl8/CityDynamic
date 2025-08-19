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

	/**
	 * Phase2
	 * Details:
	 * - Modify logic to use OpportunitySelector to get Opportunity with CoBuyer
	 */
	public void insertInvoiceAndRelatedRecords(List<OpportunityPayment__c> oppPayments, Date dueDate, Date invoiceDate) {
		Map<Id, List<OpportunityPayment__c>> oppPaymentMapByOppId = getOppPaymentsMapByOppId(oppPayments);

		if (oppPaymentMapByOppId.isEmpty()) {
			return;
		}
		// Phase2: change selector to get related CoBuyer
		Map<Id, Opportunity> opportunityMapById = OpportunitySelector.getInstance().getOpportunityWithCoBuyerMapById(oppPaymentMapByOppId.keySet());
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
				Id recordId = tempEmail.getWhatId();
				Messaging.SingleEmailMessage actualEmail = emailUtility.getSingleEmailFromTempEmail(tempEmail,recordContentVerIdsMapByRecordId.get(recordId));
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

	/**
	 * Phase2
	 * Details:
	 * - Modify logic to stamp CancelReason__c from Opportunity.LossReason__c
	 */
	public List<Invoice__c> getCancelInvoiceByOppIdSet(Set<Id> oppIdSet){
		List<Invoice__c> invoiceForCancels = new List<Invoice__c>();
		List<Invoice__c> invoices = InvoiceSelector.getInstance().getByOppIdSet(oppIdSet);
		for (Invoice__c invoice : invoices) {
			String oppLostReason = invoice.Opportunity__r.LossReason__c;
			String invoiceLostReason = GlobalConstants.INVOICE_RECEIPT_LOST_REASON_MAP_BY_OPP_LOST_REASON.get(oppLostReason);
			invoiceForCancels.add(
				new Invoice__c(
					Id = invoice.Id,
					IsCancel__c = true,
					CancelReason__c = invoiceLostReason == null ? 'Closed Lost' : invoiceLostReason
				)
			);
		}

		return invoiceForCancels;
	}

	/**
	 * Phase2
	 * Details:
	 * - add logic to create Invoice__c and InvoiceLineItem__c
	 */
	public void createInvoiceAndLineItem(Id opportunityId, Date invoiceDate, Date dueDate, String term) {
        if (opportunityId == null || invoiceDate == null || dueDate == null || String.isBlank(term)) {
            System.debug('Missing required inputs.');
            return;
        }

        Savepoint sp = Database.setSavepoint();
        try {
			CoBuyerService coBuyerService = CoBuyerService.getInstance();
			OpportunitySelector selector = OpportunitySelector.getInstance();
			Map<Id, Opportunity> targetOppMapById = selector.getOpportunityWithCoBuyerMapById(new Set<Id>{opportunityId});
			Opportunity targetOpp = targetOppMapById.get(opportunityId);
			List<CoBuyer__c> coBuyers = targetOpp.Co_Borrowers__r;
			String coBuyerAccountCodeString = coBuyerService.getStringCoBuyerAccountCode(coBuyers);
			Integer randomNum = Math.round(Math.random() * 899999) + 100000;
            String runningNumber = '0001'; // You can adjust this logic if needed
            // 🔹 Step 1: Create Invoice
            Invoice__c invoice = new Invoice__c(
                Opportunity__c = opportunityId,
                InvoiceDate__c = invoiceDate,
                DueDate__c = dueDate,
				CoBuyerAccountCode__c = coBuyerAccountCodeString,
				InvoiceNo__c = 'IV-' + runningNumber + '-' + randomNum
            );
            insert invoice;

            // 🔹 Step 2: Get OpportunityPayment__c by term
            List<OpportunityPayment__c> oppPayments = [
                SELECT
                    Id,
                    Remaining__c,
                    DueDate__c,
                    Term__c
                FROM OpportunityPayment__c
                WHERE Opportunity__c = :opportunityId
                    AND IsMasterData__c = TRUE
                    AND Term__c = :term
                LIMIT 1
            ];

            if (!oppPayments.isEmpty()) {
                OpportunityPayment__c oppPayment = oppPayments[0];
                if (oppPayment.Remaining__c != null && oppPayment.Remaining__c > 0) {
                    // 🔹 Step 3: Create InvoiceLineItem
                    InvoiceLineItem__c invoiceLineItem = new InvoiceLineItem__c(
                        LineNumber__c = 1,
                        Invoice__c = invoice.Id,
                        OpportunityPayment__c = oppPayment.Id,
                        DueDate__c = oppPayment.DueDate__c,
                        Amount__c = oppPayment.Remaining__c
                    );
                    insert invoiceLineItem;
                } else {
                    System.debug('No remaining amount for the specified term.');
                }
            } else {
                System.debug('No OpportunityPayment__c found for the specified term.');
            }

        } catch (Exception e) {
			System.debug('Failed to create invoice and line item: ' + e.getMessage() + e.getStackTraceString());
            Database.rollback(sp);
        }
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

	/**
	 * Phase2
	 * Details:
	 * - Modify logic to stamp CoBuyerName__c and CoBuyerAccountCode__c to Invoice
	 */
	@TestVisible
	private Map<Id, Invoice__c> getInvoiceMapByOppId(Map<Id, Opportunity> opportunityMapById, Date dueDate, Date invoiceDate) {
		CoBuyerService coBuyerService = CoBuyerService.getInstance();
		Map<Id, Invoice__c> invoiceMapByOppId = new Map<Id, Invoice__c>();
		for (Id oppId : opportunityMapById.keySet()) {
			Opportunity opportunity = opportunityMapById.get(oppId);
			// Phase2: call service to get string of Account Code
			List<CoBuyer__c> coBuyers = opportunity.Co_Borrowers__r;
			String coBuyerAccountCodeString = coBuyerService.getStringCoBuyerAccountCode(coBuyers);
			invoiceMapByOppId.put(
				oppId,
				new Invoice__c(
					Opportunity__c = oppId,
					InvoiceDate__c = invoiceDate,
					DueDate__c = dueDate,
					DoNotSendInvoice__c = opportunity.DoNotSendInvoice__c,
					AccountAddress__c = opportunity.Account.AddressEN__c,
					CoBuyerName__c = opportunity.CoBuyerName__c,
					CoBuyerAccountCode__c = coBuyerAccountCodeString
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