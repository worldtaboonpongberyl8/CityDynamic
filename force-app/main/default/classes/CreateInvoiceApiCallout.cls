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
        this.setRequestDataModelClass(RequestDataModel.class);
        this.setResponseDataModelClass(ResponseDataModel.class);
    }

	public override Object buildRequestDataModel() {
		List<RequestDataModel> requestDataModels = new List<RequestDataModel>();
		for (Invoice__c invoice : this.invoices){
			RequestDataModel requestDataModel = new RequestDataModel();
			requestDataModel.CustomerCode = invoice.Opportunity__r.Account.AccountCode__c;
			requestDataModel.ProjectCode = invoice.Opportunity__r.Project__r.ProjectCode__c;
			requestDataModel.SFDocId = invoice.Id;
			requestDataModel.DocDate = invoice.CreatedDate.date();
			requestDataModel.DocType = 'IV';
			requestDataModel.InvoiceCode = invoice.InvoiceNo__c;
			requestDataModel.Indicator = 0;
			List<InvoiceLineItem__c> invoiceLineItems = invoice.InvoiceLineItems__r;
			List<InvoiceLineItemRequest> docLines = new List<InvoiceLineItemRequest>();
			for (InvoiceLineItem__c invoiceLineItem : invoiceLineItems){
				InvoiceLineItemRequest docLine = new InvoiceLineItemRequest();
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
		System.debug('** test ** response: ' + response);
		List<RequestDataModel> targetRequests = (List<RequestDataModel>)request.getRequestBody();
		String errorDescription = response.getDescription();
		List<Invoice__c> updatedInvoices = new List<Invoice__c>();
		List<InvoiceLineItem__c> updatedInvoiceLineItems = new List<InvoiceLineItem__c>();
		System.debug('** test ** targetRequests: ' + targetRequests);
		for (RequestDataModel eachRequest : targetRequests){
			Invoice__c updatedInvoice = new Invoice__c(
				Id = eachRequest.SFDocId,
				ResponseCode__c = 'ERR',
				ResponseMessage__c = errorDescription,
				LastIntegrationDateTime__c = System.now()
			);
			updatedInvoices.add(updatedInvoice);
			List<InvoiceLineItemRequest> invoiceLineItemRequests = eachRequest.DocLine;
			for (InvoiceLineItemRequest invoiceLineItemRequest : invoiceLineItemRequests){
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
		ResponseDataModel targetResponse = (ResponseDataModel)response.getResponseDataModel();
		List<InvoiceResponse> invoiceResponses = targetResponse.responses;
		System.debug('** test ** invoiceResponses: ' + invoiceResponses);
		List<Invoice__c> updatedInvoices = new List<Invoice__c>();
		List<InvoiceLineItem__c> updatedInvoiceLineItems = new List<InvoiceLineItem__c>();
		for (InvoiceResponse invoiceRespone : invoiceResponses){
			Invoice__c invoice = new Invoice__c(
			Id = invoiceRespone.SFDocId,
			ResponseCode__c = invoiceRespone.ResponseCode,
			ResponseMessage__c = invoiceRespone.Message,
			LastIntegrationDateTime__c = invoiceRespone.Timestamp,
			LastCreatedStatusInPojjaman__c = invoiceRespone.ResponseCode == 'SC' ? 'Success' : 'Fail'
			);
			updatedInvoices.add(invoice);
			List<InvoiceLineItemResponse> invoiceLineItemResponses = invoiceRespone.DocLine;
			for (InvoiceLineItemResponse invoiceLineItemResponse : invoiceLineItemResponses) {
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

	public class RequestDataModel extends b8int_BaseRequestDataModel {
		public String CustomerCode;
		public String ProjectCode;
		public String SFDocId;
		public Date DocDate;
		public String DocType;
		public String InvoiceCode;
		public Integer Indicator;
		public List<InvoiceLineItemRequest> DocLine;
	}

	public class InvoiceLineItemRequest {
		public Integer LineNumber;
		public String UnitCode;
		public String Type;
		public Decimal Amount;
		public String SFDocLineId;
		public String Status;
		public Date DueDate;
	}

	public class ResponseDataModel extends b8int_BaseResponseDataModel {
		public Boolean isSuccess;
        public String description;
		public List<InvoiceResponse> responses;

        public override Boolean isValid() {
            return isSuccess;
        }

        public override String getErrorDescription() {
            return this.description;
        }
	}

	public class InvoiceResponse{
		public String SFDocId;
		public Integer ResponseId;
		public String ResponseCode;
		public String Message;
		public Datetime Timestamp;
		public List<InvoiceLineItemResponse> DocLine;
	}

	public class InvoiceLineItemResponse{
		public String SFDocLineId;
		public Integer ResponseId;
		public String ResponseCode;
		public String Message;
		public Datetime Timestamp;
	}

}