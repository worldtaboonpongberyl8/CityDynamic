public with sharing class GLChangeUnitApiCallout extends b8int_BaseHttpCallout{

	private List<Opportunity> opportunities = new List<Opportunity>();

    public GLChangeUnitApiCallout(List<Opportunity> opportunities) {
		super('GLChangeUnit');
		this.opportunities = opportunities;
		this.setCalloutType(b8int_BaseHttpCallout.HttpCalloutType.REALTIME);
		this.setIsRequireRetry(false);
		this.setMethod(b8int_BaseHttpRequest.HttpMethod.POST);
		this.setClient(new GLChangeUnitApiClient());
		this.setContentType(b8int_BaseHttpRequest.ContentType.JSON);
		this.setEndpoint('api/CityDynamic/CreateFN_GL');
		this.setRequestDataModelClass(PojjamanDataModel.FNGLDocRequest.class);
		this.setResponseDataModelClass(PojjamanDataModel.ResponseDataModel.class);
	}

	public override Object buildRequestDataModel() {
		List<PojjamanDataModel.FNGLDocRequest> requestDataModels = new List<PojjamanDataModel.FNGLDocRequest>();
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		Set<Id> receiptIds = new Set<Id>();
		Set<Id> invoiceIds = new Set<Id>();
		for (Opportunity opportunity : opportunities) {
			List<Invoice__c> invoices = opportunity.Invoices__r;
			for (Invoice__c invoice : invoices) {
				invoiceIds.add(invoice.Id);
			}
			List<PaymentReceipt__c> paymentReceipts = opportunity.PaymentReceipt__r;
			for (PaymentReceipt__c paymentReceipt : paymentReceipts) {
				receiptIds.add(paymentReceipt.Id);
			}
		}
		// add invoice which still has remaining > 0
		Map<Id, Invoice__c> invoiceWithInvoiceLineItemsMapById = invoiceSelector.getInvoiceWithInvoiceLineItemsMapById(
			invoiceIds
		);
		List<Invoice__c> invoices = invoiceWithInvoiceLineItemsMapById.values() == null ? new List<Invoice__c>() : invoiceWithInvoiceLineItemsMapById.values();
		for (Invoice__c invoice : invoices) {
			InvoiceLineItem__c invoiceLineItem = invoice.InvoiceLineItems__r[0];
			if (invoiceLineItem.OpportunityPayment__r.Remaining__c > 0) {
				PojjamanDataModel.FNGLDocRequest requestDataModel = new PojjamanDataModel.FNGLDocRequest();
				requestDataModel.CustomerCode = invoice.Opportunity__r.Account.AccountCode__c;
				requestDataModel.ProjectCode = invoice.Opportunity__r.Project__r.ProjectCode__c;
				requestDataModel.SFDocId = invoice.Id;
				requestDataModel.DocDate = invoice.CreatedDate.date();
				requestDataModel.DocType = 'GL';
				requestDataModel.InvoiceCode = invoice.InvoiceNo__c;
				requestDataModel.Indicator = 2;
				requestDataModel.GroupKey = invoice.GLKey__c;
				requestDataModel.GLDate = invoice.GLDate__c;
				requestDataModel.CoBuyerCustomerCode = invoice.CoBuyerAccountCode__c == null ? null : invoice.CoBuyerAccountCode__c.split(',');
				List<PojjamanDataModel.FNGLDocLineRequest> docLines = new List<PojjamanDataModel.FNGLDocLineRequest>();
				PojjamanDataModel.FNGLDocLineRequest docLine = new PojjamanDataModel.FNGLDocLineRequest();
				docLine.LineNumber = Integer.valueOf(invoiceLineItem.LineNumber__c);
				docLine.UnitCode = invoiceLineItem.Invoice__r.Opportunity__r.Unit__r.ProductCode;
				docLine.Type = invoiceLineItem.Term__c;
				docLine.Amount = invoiceLineItem.Amount__c;
				docLine.SFDocLineId = invoiceLineItem.Id;
				docLine.Status = invoiceLineItem.Status__c;
				docLine.DueDate = invoiceLineItem.DueDate__c;
				docLines.add(docLine);
				requestDataModel.DocLine = docLines;
				requestDataModels.add(requestDataModel);
			}
		}
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			receiptIds
		);
		List<PaymentReceipt__c> receipts = receiptWithReceiptLineItemsMapById.values() == null ? new List<PaymentReceipt__c>() : receiptWithReceiptLineItemsMapById.values();
		for (PaymentReceipt__c receipt : receipts) {
			PojjamanDataModel.FNGLDocRequest requestDataModel = new PojjamanDataModel.FNGLDocRequest();
			requestDataModel.CustomerCode = receipt.Opportunity__r.Account.AccountCode__c;
			requestDataModel.ProjectCode = receipt.Opportunity__r.Project__r.ProjectCode__c;
			requestDataModel.SFDocId = receipt.Id;
			requestDataModel.DocDate = receipt.CreatedDate.date();
			requestDataModel.DocType = 'GL';
			requestDataModel.ReceiptCode = receipt.ReceiptNo__c;
			// Phase2 : change indicator from 0 to 4 after SIT discussion
			requestDataModel.Indicator = 4;
			requestDataModel.GroupKey = receipt.GLKey__c;
			requestDataModel.GLDate = receipt.GLDate__c;
			requestDataModel.CoBuyerCustomerCode = receipt.CoBuyerAccountCode__c == null ? null : receipt.CoBuyerAccountCode__c.split(',');
			List<PaymentReceiptLineItem__c> receiptLineItems = receipt.Payment_Transactions__r;
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = new List<PojjamanDataModel.FNGLDocLineRequest>();
			Integer lineNumber = 1;
			for (PaymentReceiptLineItem__c receiptLineItem : receiptLineItems) {
				PojjamanDataModel.FNGLDocLineRequest docLine = new PojjamanDataModel.FNGLDocLineRequest();
				docLine.LineNumber = lineNumber;
				docLine.UnitCode = receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode;
				docLine.Type = receiptLineItem.OpportunityPayment__r.Term__c;
				docLine.Amount = receiptLineItem.ReceivedAmount__c;
				docLine.isDebit = true;
				docLine.SFDocLineId = receiptLineItem.Id;
				docLine.Status = receiptLineItem.Status__c;
				docLine.RefInvoiceId = receiptLineItem.InvoiceLineItem__r.Invoice__c;
				docLines.add(docLine);
				lineNumber++;
			}
			requestDataModel.DocLine = docLines;
			requestDataModels.add(requestDataModel);
		}
		return requestDataModels;
	}

	public override Boolean processFailedResponse() {
		b8int_BaseHttpRequest request = this.getRequestModel();
		b8int_BaseHttpResponse response = this.getResponseModel();
		List<PojjamanDataModel.FNGLDocRequest> targetRequests = (List<PojjamanDataModel.FNGLDocRequest>) request.getRequestBody();
		String errorDescription = response.getDescription();
		OpportunitySelector oppSelector = OpportunitySelector.getInstance();
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		List<Invoice__c> updatedInvoices = new List<Invoice__c>();
		List<InvoiceLineItem__c> updatedInvoiceLineItems = new List<InvoiceLineItem__c>();
		List<PaymentReceipt__c> updatedReceipts = new List<PaymentReceipt__c>();
		List<PaymentReceiptLineItem__c> updatedReceiptLineItems = new List<PaymentReceiptLineItem__c>();
		List<Opportunity> updatedOpportunities = new List<Opportunity>();
		Set<Id> docIds = new Set<Id>();
		Set<Id> oppIds = new Set<Id>();
		for (PojjamanDataModel.FNGLDocRequest eachRequest : targetRequests) {
			docIds.add(eachRequest.SFDocId);
		}
		Map<Id, Invoice__c> invoiceWithInvoiceLineItemsMapById = invoiceSelector.getInvoiceWithInvoiceLineItemsMapById(
			docIds
		);
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			docIds
		);
		for (PojjamanDataModel.FNGLDocRequest eachRequest : targetRequests) {
			if (invoiceWithInvoiceLineItemsMapById.containsKey(eachRequest.SFDocId)) {
				Invoice__c targetInvoice = invoiceWithInvoiceLineItemsMapById.get(eachRequest.SFDocId);
				docIds.add(targetInvoice.Opportunity__c);
				Invoice__c invoice = new Invoice__c(
					Id = eachRequest.SFDocId,
					ResponseCode__c = 'ERR',
					ResponseMessage__c = errorDescription,
					LastIntegrationDateTime__c = System.now(),
					LastGLStatusInPojjaman__c = 'Fail'
				);
				updatedInvoices.add(invoice);
				List<PojjamanDataModel.FNGLDocLineRequest> docLines = eachRequest.DocLine;
				for (PojjamanDataModel.FNGLDocLineRequest docLine : docLines) {
					InvoiceLineItem__c invoiceLineItem = new InvoiceLineItem__c(
						Id = docLine.SFDocLineId,
						ResponseCode__c = 'ERR',
						ResponseMessage__c = errorDescription,
						LastIntegrationDateTime__c = System.now()
					);
					updatedInvoiceLineItems.add(invoiceLineItem);
				}
			} else if (receiptWithReceiptLineItemsMapById.containsKey(eachRequest.SFDocId)) {
				PaymentReceipt__c targetReceipt = receiptWithReceiptLineItemsMapById.get(eachRequest.SFDocId);
				docIds.add(targetReceipt.Opportunity__c);
				PaymentReceipt__c receipt = new PaymentReceipt__c(
					Id = eachRequest.SFDocId,
					ResponseCode__c = 'ERR',
					ResponseMessage__c = errorDescription,
					LastIntegrationDateTime__c = System.now(),
					LastGLStatusInPojjaman__c = 'Fail'
				);
				updatedReceipts.add(receipt);
				List<PojjamanDataModel.FNGLDocLineRequest> docLines = eachRequest.DocLine;
				for (PojjamanDataModel.FNGLDocLineRequest docLine : docLines) {
					PaymentReceiptLineItem__c receiptLineItem = new PaymentReceiptLineItem__c(
						Id = docLine.SFDocLineId,
						ResponseCode__c = 'ERR',
						ResponseMessage__c = errorDescription,
						LastIntegrationDateTime__c = System.now()
					);
					updatedReceiptLineItems.add(receiptLineItem);
				}
			}
		}
		if (!oppIds.isEmpty()){
			Map<Id, Opportunity> oppMapById = oppSelector.getOpportunityMapById(oppIds);
			for (Opportunity opp : oppMapById.values()){
				opp.LastGLStatusInPojjaman__c = 'Fail';
				opp.LastIntegrationDateTime__c = System.now();
				updatedOpportunities.add(opp);
			}
		}
		if (!updatedInvoices.isEmpty()) {
			update updatedInvoices;
		}
		if (!updatedInvoiceLineItems.isEmpty()) {
			update updatedInvoiceLineItems;
		}
		if (!updatedReceipts.isEmpty()) {
			update updatedReceipts;
		}
		if (!updatedReceiptLineItems.isEmpty()) {
			update updatedReceiptLineItems;
		}
		if (!updatedOpportunities.isEmpty()) {
			update updatedOpportunities;
		}
		return true;
	}

	public override Boolean processSuccessResponse() {
		b8int_BaseHttpResponse response = this.getResponseModel();
		PojjamanDataModel.ResponseDataModel targetResponse = (PojjamanDataModel.ResponseDataModel) response.getResponseDataModel();
		List<PojjamanDataModel.FNGLDocResponse> glResponses = targetResponse.responses;
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		OpportunitySelector oppSelector = OpportunitySelector.getInstance();
		List<Invoice__c> updatedInvoices = new List<Invoice__c>();
		List<InvoiceLineItem__c> updatedInvoiceLineItems = new List<InvoiceLineItem__c>();
		List<PaymentReceipt__c> updatedReceipts = new List<PaymentReceipt__c>();
		List<PaymentReceiptLineItem__c> updatedReceiptLineItems = new List<PaymentReceiptLineItem__c>();
		List<Opportunity> updatedOpportunities = new List<Opportunity>();
		Set<Id> docIds = new Set<Id>();
		Set<Id> failedOppIds = new Set<Id>();
		Set<Id> successedOppIds = new Set<Id>();
		for (PojjamanDataModel.FNGLDocResponse glResponse : glResponses) {
			docIds.add(glResponse.SFDocId);
		}
		Map<Id, Invoice__c> invoiceWithInvoiceLineItemsMapById = invoiceSelector.getInvoiceWithInvoiceLineItemsMapById(
			docIds
		);
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			docIds
		);
		for (PojjamanDataModel.FNGLDocResponse glResponse : glResponses) {
			if (invoiceWithInvoiceLineItemsMapById.containsKey(glResponse.SFDocId)) {
				Invoice__c targetInvoice = invoiceWithInvoiceLineItemsMapById.get(glResponse.SFDocId);
				Id targetOppId = targetInvoice.Opportunity__c;
				if (glResponse.ResponseCode != 'SC'){
					failedOppIds.add(targetOppId);
				} else {
					successedOppIds.add(targetOppId);
				}
				// response for invoice
				Invoice__c invoice = new Invoice__c(
					Id = glResponse.SFDocId,
					ResponseCode__c = glResponse.ResponseCode,
					ResponseMessage__c = glResponse.Message,
					LastIntegrationDateTime__c = glResponse.Timestamp,
					LastGLStatusInPojjaman__c = glResponse.ResponseCode == 'SC' ? 'Success' : 'Fail'
				);
				updatedInvoices.add(invoice);
				List<PojjamanDataModel.FNGLDocLineItemResponse> glLineItemResponses = glResponse.DocLine;
				for (PojjamanDataModel.FNGLDocLineItemResponse glLineItemResponse : glLineItemResponses) {
					InvoiceLineItem__c invoiceLineItem = new InvoiceLineItem__c(
						Id = glLineItemResponse.SFDocLineId,
						ResponseCode__c = glLineItemResponse.ResponseCode,
						ResponseMessage__c = glLineItemResponse.Message,
						LastIntegrationDateTime__c = glLineItemResponse.Timestamp
					);
					updatedInvoiceLineItems.add(invoiceLineItem);
				}
			} else if (receiptWithReceiptLineItemsMapById.containsKey(glResponse.SFDocId)) {
				PaymentReceipt__c targetReceipt = receiptWithReceiptLineItemsMapById.get(glResponse.SFDocId);
				Id targetOppId = targetReceipt.Opportunity__c;
				if (glResponse.ResponseCode != 'SC'){
					failedOppIds.add(targetOppId);
				} else {
					successedOppIds.add(targetOppId);
				}
				// response for receipt
				PaymentReceipt__c receipt = new PaymentReceipt__c(
					Id = glResponse.SFDocId,
					ResponseCode__c = glResponse.ResponseCode,
					ResponseMessage__c = glResponse.Message,
					LastIntegrationDateTime__c = glResponse.Timestamp,
					LastGLStatusInPojjaman__c = glResponse.ResponseCode == 'SC' ? 'Success' : 'Fail'
				);
				updatedReceipts.add(receipt);
				List<PojjamanDataModel.FNGLDocLineItemResponse> glLineItemResponses = glResponse.DocLine;
				for (PojjamanDataModel.FNGLDocLineItemResponse glLineItemResponse : glLineItemResponses) {
					PaymentReceiptLineItem__c receiptLineItem = new PaymentReceiptLineItem__c(
						Id = glLineItemResponse.SFDocLineId,
						ResponseCode__c = glLineItemResponse.ResponseCode,
						ResponseMessage__c = glLineItemResponse.Message,
						LastIntegrationDateTime__c = glLineItemResponse.Timestamp
					);
					updatedReceiptLineItems.add(receiptLineItem);
				}
			}
		}
		if (!failedOppIds.isEmpty()){
			Map<Id, Opportunity> oppMapById = oppSelector.getOpportunityMapById(failedOppIds);
			for (Opportunity opp : oppMapById.values()){
				opp.LastGLStatusInPojjaman__c = 'Fail';
				opp.LastIntegrationDateTime__c = System.now();
				updatedOpportunities.add(opp);
			}
		}
		if (!successedOppIds.isEmpty()){
			Map<Id, Opportunity> oppMapById = oppSelector.getOpportunityMapById(successedOppIds);
			for (Opportunity opp : oppMapById.values()){
				opp.LastGLStatusInPojjaman__c = 'Success';
				opp.LastIntegrationDateTime__c = System.now();
				updatedOpportunities.add(opp);
			}
		}
		if (!updatedInvoices.isEmpty()) {
			update updatedInvoices;
		}
		if (!updatedInvoiceLineItems.isEmpty()) {
			update updatedInvoiceLineItems;
		}
		if (!updatedReceipts.isEmpty()) {
			update updatedReceipts;
		}
		if (!updatedReceiptLineItems.isEmpty()) {
			update updatedReceiptLineItems;
		}
		if (!updatedOpportunities.isEmpty()){
			update updatedOpportunities;
		}
		return true;
	}
}