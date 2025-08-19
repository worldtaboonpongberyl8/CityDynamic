public with sharing class CreateInvoiceApiCallout extends b8int_BaseHttpCallout {

	private List<Invoice__c> invoices = new List<Invoice__c>();

    public CreateInvoiceApiCallout(List<Invoice__c> invoices) {
		super('Invoice');
		this.invoices = invoices;
        this.setCalloutType(b8int_BaseHttpCallout.HttpCalloutType.REALTIME);
        this.setIsRequireRetry(false);
        this.setMethod(b8int_BaseHttpRequest.HttpMethod.POST);
        this.setClient(new CreateInvoiceApiClient());
        this.setContentType(b8int_BaseHttpRequest.ContentType.JSON);
        this.setEndpoint('api/CityDynamic/CreateFN_GL');
        // Phase2: change parameter to send to setRequestDataModelClass as PojjamanDataModel.FNGLDocRequest.class instead of RequestDataModel.class
        this.setRequestDataModelClass(PojjamanDataModel.FNGLDocRequest.class);
		// Phase2: change parameter to send to setResponseDataModelClass as PojjamanDataModel.ResponseDataModel.class instead of ResponseDataModel.class
        this.setResponseDataModelClass(PojjamanDataModel.ResponseDataModel.class);
    }

	public override Object buildRequestDataModel() {
		List<PojjamanDataModel.FNGLDocRequest> requestDataModels = new List<PojjamanDataModel.FNGLDocRequest>();
		for (Invoice__c invoice : this.invoices){
			PojjamanDataModel.FNGLDocRequest requestDataModel = new PojjamanDataModel.FNGLDocRequest();
			requestDataModel.CustomerCode = invoice.Opportunity__r.Account.AccountCode__c;
			requestDataModel.ProjectCode = invoice.Opportunity__r.Project__r.ProjectCode__c;
			requestDataModel.SFDocId = invoice.Id;
			requestDataModel.DocDate = invoice.CreatedDate.date();
			requestDataModel.DocType = 'IV';
			requestDataModel.InvoiceCode = invoice.InvoiceNo__c;
			requestDataModel.Indicator = 0;
			requestDataModel.CoBuyerCustomerCode = invoice.CoBuyerAccountCode__c == null ? null : invoice.CoBuyerAccountCode__c == 'x' ? new List<String>{''} : this.splitPreserveEmpty(invoice.CoBuyerAccountCode__c , ',');
			List<InvoiceLineItem__c> invoiceLineItems = invoice.InvoiceLineItems__r;
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = new List<PojjamanDataModel.FNGLDocLineRequest>();
			for (InvoiceLineItem__c invoiceLineItem : invoiceLineItems){
				PojjamanDataModel.FNGLDocLineRequest docLine = new PojjamanDataModel.FNGLDocLineRequest();
				docLine.LineNumber = 1;
				docLine.UnitCode = invoiceLineItem.Invoice__r.Opportunity__r.Unit__r.ProductCode;
				docLine.Type = invoiceLineItem.Term__c;
				docLine.Amount = invoiceLineItem.Amount__c;
				docLine.SFDocLineId = invoiceLineItem.Id;
				docLine.Status = invoiceLineItem.Status__c;
				docLine.DueDate = invoiceLineItem.DueDate__c;
				docLines.add(docLine);
			}
			requestDataModel.DocLine = !docLines.isEmpty() ? docLines : null;
			requestDataModels.add(requestDataModel);
		}
		return requestDataModels;
	}

	public override Boolean processFailedResponse() {
		b8int_BaseHttpRequest request = this.getRequestModel();
		b8int_BaseHttpResponse response = this.getResponseModel();
		List<PojjamanDataModel.FNGLDocRequest> targetRequests = (List<PojjamanDataModel.FNGLDocRequest>)request.getRequestBody();
		String errorDescription = response.getDescription();
		List<Invoice__c> updatedInvoices = new List<Invoice__c>();
		List<InvoiceLineItem__c> updatedInvoiceLineItems = new List<InvoiceLineItem__c>();
		for (PojjamanDataModel.FNGLDocRequest eachRequest : targetRequests){
			Invoice__c updatedInvoice = new Invoice__c(
				Id = eachRequest.SFDocId,
				ResponseCode__c = 'ERR',
				ResponseMessage__c = errorDescription,
				LastIntegrationDateTime__c = System.now()
			);
			updatedInvoices.add(updatedInvoice);
			List<PojjamanDataModel.FNGLDocLineRequest> invoiceLineItemRequests = eachRequest.DocLine;
			for (PojjamanDataModel.FNGLDocLineRequest invoiceLineItemRequest : invoiceLineItemRequests){
				InvoiceLineItem__c updatedInvoiceLineItem = new InvoiceLineItem__c(
					Id = invoiceLineItemRequest.SFDocLineId,
					ResponseCode__c = 'ERR',
					ResponseMessage__c = errorDescription,
					LastIntegrationDateTime__c = System.now()
				);
				updatedInvoiceLineItems.add(updatedInvoiceLineItem);
			}
		}
		if (!updatedInvoices.isEmpty()) {
			update updatedInvoices;
		}
		if (!updatedInvoiceLineItems.isEmpty()) {
			update updatedInvoiceLineItems;
		}
		return true;
	}

	public override Boolean processSuccessResponse() {
		b8int_BaseHttpResponse response = this.getResponseModel();
		PojjamanDataModel.ResponseDataModel targetResponse = (PojjamanDataModel.ResponseDataModel)response.getResponseDataModel();
		List<PojjamanDataModel.FNGLDocResponse> invoiceResponses = targetResponse.responses;
		List<Invoice__c> updatedInvoices = new List<Invoice__c>();
		List<InvoiceLineItem__c> updatedInvoiceLineItems = new List<InvoiceLineItem__c>();
		for (PojjamanDataModel.FNGLDocResponse invoiceRespone : invoiceResponses){
			Invoice__c invoice = new Invoice__c(
			Id = invoiceRespone.SFDocId,
			ResponseCode__c = invoiceRespone.ResponseCode,
			ResponseMessage__c = invoiceRespone.Message,
			LastIntegrationDateTime__c = invoiceRespone.Timestamp,
			LastCreatedStatusInPojjaman__c = invoiceRespone.ResponseCode == 'SC' ? 'Success' : 'Fail'
			);
			updatedInvoices.add(invoice);
			List<PojjamanDataModel.FNGLDocLineItemResponse> invoiceLineItemResponses = invoiceRespone.DocLine;
			for (PojjamanDataModel.FNGLDocLineItemResponse invoiceLineItemResponse : invoiceLineItemResponses) {
				InvoiceLineItem__c invoiceLineItem = new InvoiceLineItem__c(
				Id = invoiceLineItemResponse.SFDocLineId,
				ResponseCode__c = invoiceLineItemResponse.ResponseCode,
				ResponseMessage__c = invoiceLineItemResponse.Message,
				LastIntegrationDateTime__c = invoiceLineItemResponse.Timestamp
				);
				updatedInvoiceLineItems.add(invoiceLineItem);
			}
		}
		if (!updatedInvoices.isEmpty()) {
			update updatedInvoices;
		}
		if (!updatedInvoiceLineItems.isEmpty()) {
			update updatedInvoiceLineItems;
		}
		return true;
	}

	private List<String> splitPreserveEmpty(String input, String delimiter) {
		List<String> result = new List<String>();
		Integer start = 0;
		Integer delimLength = delimiter.length();

		while (start <= input.length()) {
			Integer index = input.indexOf(delimiter, start);
			if (index == -1) {
				// Add the last part (even if empty)
				result.add(input.substring(start));
				break;
			}
			result.add(input.substring(start, index));
			start = index + delimLength;
		}

		return result;
	}

}