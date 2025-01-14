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
		this.setRequestDataModelClass(RequestDataModel.class);
		this.setResponseDataModelClass(ResponseDataModel.class);
	}

	public override Object buildRequestDataModel() {
		List<RequestDataModel> requestDataModels = new List<RequestDataModel>();
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		Set<Id> receiptIds = new Set<Id>();
		Set<Id> invoiceIds = new Set<Id>();
		for (Opportunity opportunity : opportunities) {
			List<PaymentReceipt__c> paymentReceipts = opportunity.PaymentReceipt__r;
			for (PaymentReceipt__c paymentReceipt : paymentReceipts) {
				if (
					paymentReceipt.IsCancel__c &&
					paymentReceipt.CancelReason__c == 'Closed Lost' &&
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
		// add invoice which still has remaining > 0
		Map<Id, Invoice__c> invoiceWithInvoiceLineItemsMapById = invoiceSelector.getInvoiceWithInvoiceLineItemsMapById(
			invoiceIds
		);
		List<Invoice__c> invoices = invoiceWithInvoiceLineItemsMapById.values() == null ? new List<Invoice__c>() : invoiceWithInvoiceLineItemsMapById.values();
		for (Invoice__c invoice : invoices) {
			InvoiceLineItem__c invoiceLineItem = invoice.InvoiceLineItems__r[0];
			if (invoiceLineItem.OpportunityPayment__r.Remaining__c > 0) {
				RequestDataModel requestDataModel = new RequestDataModel();
				requestDataModel.CustomerCode = invoice.Opportunity__r.Account.AccountCode__c;
				requestDataModel.ProjectCode = invoice.Opportunity__r.Project__r.ProjectCode__c;
				requestDataModel.SFDocId = invoice.Id;
				requestDataModel.DocDate = invoice.CreatedDate.date();
				requestDataModel.DocType = 'GL';
				requestDataModel.InvoiceCode = invoice.InvoiceNo__c;
				requestDataModel.Indicator = 2;
				requestDataModel.GroupKey = invoice.GLKey__c;
				requestDataModel.GLDate = invoice.GLDate__c;
				System.debug('** test **: ' + invoice.GLDate__c);
				List<DocLine> docLines = new List<DocLine>();
				DocLine docLine = new DocLine();
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
			RequestDataModel requestDataModel = new RequestDataModel();
			requestDataModel.CustomerCode = receipt.Opportunity__r.Account.AccountCode__c;
			requestDataModel.ProjectCode = receipt.Opportunity__r.Project__r.ProjectCode__c;
			requestDataModel.SFDocId = receipt.Id;
			requestDataModel.DocDate = receipt.CreatedDate.date();
			requestDataModel.DocType = 'GL';
			requestDataModel.ReceiptCode = receipt.ReceiptNo__c;
			requestDataModel.Indicator = 0;
			requestDataModel.GroupKey = receipt.GLKey__c;
			requestDataModel.GLDate = receipt.GLDate__c;
			List<PaymentReceiptLineItem__c> receiptLineItems = receipt.Payment_Transactions__r;
			List<DocLine> docLines = new List<DocLine>();
			Integer lineNumber = 1;
			for (PaymentReceiptLineItem__c receiptLineItem : receiptLineItems) {
				DocLine docLine = new DocLine();
				docLine.LineNumber = lineNumber;
				docLine.UnitCode = receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode;
				docLine.Type = receiptLineItem.OpportunityPayment__r.Term__c;
				docLine.Amount = receiptLineItem.ReceivedAmount__c;
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
		System.debug('** test ** response: ' + response);
		List<RequestDataModel> targetRequests = (List<RequestDataModel>) request.getRequestBody();
		String errorDescription = response.getDescription();
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		List<Invoice__c> updatedInvoices = new List<Invoice__c>();
		List<InvoiceLineItem__c> updatedInvoiceLineItems = new List<InvoiceLineItem__c>();
		List<PaymentReceipt__c> updatedReceipts = new List<PaymentReceipt__c>();
		List<PaymentReceiptLineItem__c> updatedReceiptLineItems = new List<PaymentReceiptLineItem__c>();
		Set<Id> docIds = new Set<Id>();
		for (RequestDataModel eachRequest : targetRequests) {
			docIds.add(eachRequest.SFDocId);
		}
		Map<Id, Invoice__c> invoiceWithInvoiceLineItemsMapById = invoiceSelector.getInvoiceWithInvoiceLineItemsMapById(
			docIds
		);
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			docIds
		);
		Id targetOppId;
		System.debug('** test ** targetRequests: ' + targetRequests);
		for (RequestDataModel eachRequest : targetRequests) {
			if (invoiceWithInvoiceLineItemsMapById.containsKey(eachRequest.SFDocId)) {
				Invoice__c targetInvoice = invoiceWithInvoiceLineItemsMapById.get(eachRequest.SFDocId);
				targetOppId = targetInvoice.Opportunity__c;
				// response for invoice
				Invoice__c invoice = new Invoice__c(
					Id = eachRequest.SFDocId,
					ResponseCode__c = 'ERR',
					ResponseMessage__c = errorDescription,
					LastIntegrationDateTime__c = System.now(),
					LastGLStatusInPojjaman__c = 'Fail'
				);
				updatedInvoices.add(invoice);
				List<DocLine> docLines = eachRequest.DocLine;
				for (DocLine docLine : docLines) {
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
				targetOppId = targetReceipt.Opportunity__c;
				// response for receipt
				PaymentReceipt__c receipt = new PaymentReceipt__c(
					Id = eachRequest.SFDocId,
					ResponseCode__c = 'ERR',
					ResponseMessage__c = errorDescription,
					LastIntegrationDateTime__c = System.now(),
					LastGLStatusInPojjaman__c = 'Fail'
				);
				updatedReceipts.add(receipt);
				List<DocLine> docLines = eachRequest.DocLine;
				for (DocLine docLine : docLines) {
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
		Opportunity updatedOpportunity = new Opportunity(
			Id = targetOppId,
			LastGLStatusInPojjaman__c = 'Fail'
		);
		update updatedOpportunity;
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
		ResponseDataModel targetResponse = (ResponseDataModel) response.getResponseDataModel();
		List<GLResponse> glResponses = targetResponse.responses;
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		List<Invoice__c> updatedInvoices = new List<Invoice__c>();
		List<InvoiceLineItem__c> updatedInvoiceLineItems = new List<InvoiceLineItem__c>();
		List<PaymentReceipt__c> updatedReceipts = new List<PaymentReceipt__c>();
		List<PaymentReceiptLineItem__c> updatedReceiptLineItems = new List<PaymentReceiptLineItem__c>();
		Set<Id> docIds = new Set<Id>();
		for (GLResponse glResponse : glResponses) {
			docIds.add(glResponse.SFDocId);
		}
		Map<Id, Invoice__c> invoiceWithInvoiceLineItemsMapById = invoiceSelector.getInvoiceWithInvoiceLineItemsMapById(
			docIds
		);
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			docIds
		);
		Boolean allDocPass = true;
		Id targetOppId;
		Datetime lastIntegrationDateTime;
		System.debug('** test ** glResponses: ' + glResponses);
		for (GLResponse glResponse : glResponses) {
			lastIntegrationDateTime = glResponse.Timestamp;
			if (glResponse.ResponseCode != 'SC'){
				allDocPass = false;
			}
			if (invoiceWithInvoiceLineItemsMapById.containsKey(glResponse.SFDocId)) {
				Invoice__c targetInvoice = invoiceWithInvoiceLineItemsMapById.get(glResponse.SFDocId);
				targetOppId = targetInvoice.Opportunity__c;
				// response for invoice
				Invoice__c invoice = new Invoice__c(
					Id = glResponse.SFDocId,
					ResponseCode__c = glResponse.ResponseCode,
					ResponseMessage__c = glResponse.Message,
					LastIntegrationDateTime__c = glResponse.Timestamp,
					LastGLStatusInPojjaman__c = glResponse.ResponseCode == 'SC' ? 'Success' : 'Fail'
				);
				updatedInvoices.add(invoice);
				List<GLLineItemResponse> glLineItemResponses = glResponse.DocLine;
				for (GLLineItemResponse glLineItemResponse : glLineItemResponses) {
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
				targetOppId = targetReceipt.Opportunity__c;
				// response for receipt
				PaymentReceipt__c receipt = new PaymentReceipt__c(
					Id = glResponse.SFDocId,
					ResponseCode__c = glResponse.ResponseCode,
					ResponseMessage__c = glResponse.Message,
					LastIntegrationDateTime__c = glResponse.Timestamp,
					LastGLStatusInPojjaman__c = glResponse.ResponseCode == 'SC' ? 'Success' : 'Fail'
				);
				updatedReceipts.add(receipt);
				List<GLLineItemResponse> glLineItemResponses = glResponse.DocLine;
				for (GLLineItemResponse glLineItemResponse : glLineItemResponses) {
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
		if (allDocPass){
			Opportunity updatedOpportunity = new Opportunity(
				Id = targetOppId,
				LastGLStatusInPojjaman__c = 'Success'
				// LastIntegrationDateTime__c = lastIntegrationDateTime
			);
			update updatedOpportunity;
		} else {
			Opportunity updatedOpportunity = new Opportunity(
				Id = targetOppId,
				LastGLStatusInPojjaman__c = 'Fail'
				// LastIntegrationDateTime__c = lastIntegrationDateTime
			);
			update updatedOpportunity;
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

	public class RequestDataModel extends b8int_BaseRequestDataModel {
		public String CustomerCode;
		public String ProjectCode;
		public String SFDocId;
		public Date DocDate;
		public String DocType;
		public String InvoiceCode;
		public String ReceiptCode;
		public Integer Indicator;
		public String GroupKey;
		public Date GLDate;
		public List<DocLine> DocLine;
	}

	public class DocLine {
		public Integer LineNumber;
		public String UnitCode;
		public String Type;
		public Decimal Amount;
		public String SFDocLineId;
		public String Status;
		public Date DueDate;
		public String RefInvoiceId;
	}

	public class ResponseDataModel extends b8int_BaseResponseDataModel {
		public Boolean isSuccess;
		public String description;
		public List<GLResponse> responses;

		public override Boolean isValid() {
			return isSuccess;
		}

		public override String getErrorDescription() {
			return this.description;
		}
	}

	public class GLResponse {
		public String SFDocId;
		public Integer ResponseId;
		public String ResponseCode;
		public String Message;
		public Datetime Timestamp;
		public List<GLLineItemResponse> DocLine;
	}

	public class GLLineItemResponse {
		public String SFDocLineId;
		public Integer ResponseId;
		public String ResponseCode;
		public String Message;
		public Datetime Timestamp;
	}
}