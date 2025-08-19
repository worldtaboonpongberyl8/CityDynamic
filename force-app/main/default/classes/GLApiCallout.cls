public with sharing class GLApiCallout extends b8int_BaseHttpCallout {
	private List<Opportunity> opportunities = new List<Opportunity>();

	public GLApiCallout(List<Opportunity> opportunities) {
		super('GL');
		this.opportunities = opportunities;
		this.setCalloutType(b8int_BaseHttpCallout.HttpCalloutType.REALTIME);
		this.setIsRequireRetry(false);
		this.setMethod(b8int_BaseHttpRequest.HttpMethod.POST);
		this.setClient(new GLApiClient());
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
		Set<Id> oppIds = new Set<Id>();
		for (Opportunity opportunity : opportunities) {
			oppIds.add(opportunity.Id);
			List<PaymentReceipt__c> paymentReceipts = opportunity.PaymentReceipt__r;
			for (PaymentReceipt__c paymentReceipt : paymentReceipts) {
				if (
					paymentReceipt.IsCancel__c &&
					(paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_CANCELREFUND ||
					paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_CANCELFORFEIT ||
					paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONREFUND ||
					paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONFORFEIT) &&
					(paymentReceipt.LastGLStatusInPojjaman__c == null ||
					paymentReceipt.LastGLStatusInPojjaman__c == 'Fail')
				) {
					receiptIds.add(paymentReceipt.Id);
				}
			}
			List<Invoice__c> invoices = opportunity.Invoices__r;
			for (Invoice__c invoice : invoices) {
				if (invoice.LastGLStatusInPojjaman__c == null || invoice.LastGLStatusInPojjaman__c == 'Fail') {
					invoiceIds.add(invoice.Id);
				}
			}
		}
		// add invoice which still has remaining > 0 to GL
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
				System.debug('** test **: ' + invoice.GLKey__c);
				requestDataModel.GLDate = invoice.GLDate__c;
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
		// add receipts to GL
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			receiptIds
		);
		List<PaymentReceipt__c> receipts = receiptWithReceiptLineItemsMapById.values() == null ? new List<PaymentReceipt__c>() : receiptWithReceiptLineItemsMapById.values();
		for (PaymentReceipt__c receipt : receipts) {
			if (receipt.ReceiptType__c != GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT ){
				PojjamanDataModel.FNGLDocRequest requestDataModel = new PojjamanDataModel.FNGLDocRequest();
				requestDataModel.CustomerCode = receipt.Opportunity__r.Account.AccountCode__c;
				requestDataModel.ProjectCode = receipt.Opportunity__r.Project__r.ProjectCode__c;
				requestDataModel.SFDocId = receipt.Id;
				requestDataModel.DocDate = receipt.CreatedDate.date();
				requestDataModel.DocType = 'GL';
				requestDataModel.ReceiptCode = receipt.ReceiptNo__c;
				requestDataModel.Indicator = 0;
				requestDataModel.GroupKey = receipt.GLKey__c;
				System.debug('** test **: ' + receipt.GLKey__c);
				requestDataModel.GLDate = receipt.GLDate__c;
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
		}
		// add refund/forfeit detail
		Map<Id, List<PaymentReceipt__c>> refundForfeitPaymentReceiptByOppIdMapByOppId = receiptSelector.getRefundForfeitPaymentReceiptByOppIdMapByOppId(oppIds);
		for (Id oppId : oppIds){
			List<PaymentReceipt__c> refundForfeitPaymentReceipt = refundForfeitPaymentReceiptByOppIdMapByOppId.get(oppId) == null ? new List<PaymentReceipt__c>() : refundForfeitPaymentReceiptByOppIdMapByOppId.get(oppId);
			for (PaymentReceipt__c receipt : refundForfeitPaymentReceipt) {
				PojjamanDataModel.FNGLDocRequest requestDataModel = new PojjamanDataModel.FNGLDocRequest();
				requestDataModel.CustomerCode = receipt.Opportunity__r.Account.AccountCode__c;
				requestDataModel.ProjectCode = receipt.Opportunity__r.Project__r.ProjectCode__c;
				requestDataModel.SFDocId = receipt.Id;
				requestDataModel.DocDate = receipt.CreatedDate.date();
				requestDataModel.DocType = 'GL';
				requestDataModel.ReceiptCode = receipt.ReceiptNo__c;
				requestDataModel.Indicator = 0;
				requestDataModel.GroupKey = receipt.GLKey__c;
				System.debug('** test refund forfeit**: ' + receipt.GLKey__c);
				requestDataModel.GLDate = receipt.GLDate__c;
				List<PaymentReceiptLineItem__c> receiptLineItems = receipt.Payment_Transactions__r;
				List<PojjamanDataModel.FNGLDocLineRequest> docLines = new List<PojjamanDataModel.FNGLDocLineRequest>();
				Integer lineNumber = 1;
				for (PaymentReceiptLineItem__c receiptLineItem : receiptLineItems) {
					// NOT Include Operation line item
					if (receiptLineItem.ReceiptLineItemType__c != 'Operation'){
						PojjamanDataModel.FNGLDocLineRequest docLine = new PojjamanDataModel.FNGLDocLineRequest();
						docLine.LineNumber = lineNumber;
						docLine.UnitCode = receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode;
						docLine.Type = receiptLineItem.ReceiptLineItemType__c;
						docLine.Amount = receiptLineItem.ReceivedAmount__c;
						docLine.isDebit = false;
						docLine.SFDocLineId = receiptLineItem.Id;
						docLine.Status = receiptLineItem.Status__c;
						docLine.RefInvoiceId = null;
						docLines.add(docLine);
						lineNumber++;
					}
				}
				requestDataModel.DocLine = docLines;
				requestDataModels.add(requestDataModel);
			}
		}
		return requestDataModels;
	}

	public override Boolean processFailedResponse() {
		b8int_BaseHttpRequest request = this.getRequestModel();
		b8int_BaseHttpResponse response = this.getResponseModel();
		List<PojjamanDataModel.FNGLDocRequest> targetRequests = (List<PojjamanDataModel.FNGLDocRequest>) request.getRequestBody();
		String errorDescription = response.getDescription();
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		List<Invoice__c> updatedInvoices = new List<Invoice__c>();
		List<InvoiceLineItem__c> updatedInvoiceLineItems = new List<InvoiceLineItem__c>();
		List<PaymentReceipt__c> updatedReceipts = new List<PaymentReceipt__c>();
		List<PaymentReceiptLineItem__c> updatedReceiptLineItems = new List<PaymentReceiptLineItem__c>();
		Set<Id> docIds = new Set<Id>();
		for (PojjamanDataModel.FNGLDocRequest eachRequest : targetRequests) {
			docIds.add(eachRequest.SFDocId);
		}
		Map<Id, Invoice__c> invoiceWithInvoiceLineItemsMapById = invoiceSelector.getInvoiceWithInvoiceLineItemsMapById(
			docIds
		);
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			docIds
		);
		Set<Id> oppIds = new Set<Id>();
		for (PojjamanDataModel.FNGLDocRequest eachRequest : targetRequests) {
			if (invoiceWithInvoiceLineItemsMapById.containsKey(eachRequest.SFDocId)) {
				Invoice__c targetInvoice = invoiceWithInvoiceLineItemsMapById.get(eachRequest.SFDocId);
				oppIds.add(targetInvoice.Opportunity__c);
				// response for invoice
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
				oppIds.add(targetReceipt.Opportunity__c);
				// response for receipt
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
		List<Opportunity> updatedOpportunities = new List<Opportunity>();
		for (Id eachOppId : oppIds) {
			Opportunity updatedOpportunity = new Opportunity(
				Id = eachOppId,
				LastGLStatusInPojjaman__c = 'Fail'
			);
			updatedOpportunities.add(updatedOpportunity);
		}
		if(!updatedOpportunities.isEmpty()){
			update updatedOpportunities;
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
		return true;
	}

	public override Boolean processSuccessResponse() {
		OpportunityTriggerHandler oppHandler = OpportunityTriggerHandler.getInstance();
		b8int_BaseHttpResponse response = this.getResponseModel();
		PojjamanDataModel.ResponseDataModel targetResponse = (PojjamanDataModel.ResponseDataModel) response.getResponseDataModel();
		List<PojjamanDataModel.FNGLDocResponse> glResponses = targetResponse.responses;
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		List<Invoice__c> updatedInvoices = new List<Invoice__c>();
		List<InvoiceLineItem__c> updatedInvoiceLineItems = new List<InvoiceLineItem__c>();
		List<PaymentReceipt__c> updatedReceipts = new List<PaymentReceipt__c>();
		List<PaymentReceiptLineItem__c> updatedReceiptLineItems = new List<PaymentReceiptLineItem__c>();
		Set<Id> docIds = new Set<Id>();
		for (PojjamanDataModel.FNGLDocResponse glResponse : glResponses) {
			docIds.add(glResponse.SFDocId);
		}
		Map<Id, Invoice__c> invoiceWithInvoiceLineItemsMapById = invoiceSelector.getInvoiceWithInvoiceLineItemsMapById(
			docIds
		);
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			docIds
		);

		Set<Id> failedOppIds = new Set<Id>();
		Set<Id> successOppIds = new Set<Id>();
		Datetime lastIntegrationDateTime;
		for (PojjamanDataModel.FNGLDocResponse glResponse : glResponses) {
			lastIntegrationDateTime = glResponse.Timestamp;
			if (invoiceWithInvoiceLineItemsMapById.containsKey(glResponse.SFDocId)) {
				Invoice__c targetInvoice = invoiceWithInvoiceLineItemsMapById.get(glResponse.SFDocId);
				if (glResponse.ResponseCode != 'SC'){
					failedOppIds.add(targetInvoice.Opportunity__c);
				} else {
					successOppIds.add(targetInvoice.Opportunity__c);
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
				if (glResponse.ResponseCode != 'SC'){
					failedOppIds.add(targetReceipt.Opportunity__c);
				} else {
					successOppIds.add(targetReceipt.Opportunity__c);
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
		oppHandler.setBypass();
		List<Opportunity> updatedOpportunitites = new List<Opportunity>();
		if (!successOppIds.isEmpty()){
			for (Id successOppId : successOppIds){
				Opportunity updatedOpportunity = new Opportunity(
					Id = successOppId,
					LastGLStatusInPojjaman__c = 'Success'
				);
				updatedOpportunitites.add(updatedOpportunity);
			}
		}
		if (!failedOppIds.isEmpty()){
			for (Id failOppId : failedOppIds){
				Opportunity updatedOpportunity = new Opportunity(
					Id = failOppId,
					LastGLStatusInPojjaman__c = 'Fail'
				);
				updatedOpportunitites.add(updatedOpportunity);
			}
		}
		if (!updatedOpportunitites.isEmpty()){
			update updatedOpportunitites;
		}
		oppHandler.clearBypass();
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
		return true;
	}
}