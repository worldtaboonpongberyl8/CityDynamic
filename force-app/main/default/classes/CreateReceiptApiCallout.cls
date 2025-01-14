public with sharing class CreateReceiptApiCallout extends b8int_BaseHttpCallout {

	private List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>();

    public CreateReceiptApiCallout(List<PaymentReceipt__c> receipts) {
		super('Receipt');
		this.receipts = receipts;
        this.setCalloutType(b8int_BaseHttpCallout.HttpCalloutType.REALTIME);
        this.setIsRequireRetry(false);
        this.setMethod(b8int_BaseHttpRequest.HttpMethod.POST);
        this.setClient(new CreateReceiptApiClient());
        this.setContentType(b8int_BaseHttpRequest.ContentType.JSON);
        this.setEndpoint('api/CityDynamic/CreateFN_GL');
        this.setRequestDataModelClass(RequestDataModel.class);
        this.setResponseDataModelClass(ResponseDataModel.class);
    }

	public override Object buildRequestDataModel() {
		List<RequestDataModel> requestDataModels = new List<RequestDataModel>();
		for (PaymentReceipt__c receipt : receipts) {
            RequestDataModel requestDataModel = new RequestDataModel();
			if (receipt.IsCancel__c){
				if (receipt.CancelReason__c != 'Closed Lost'){
					// generate request for manual cancel receipt
					if (receipt.LastCreatedStatusInPojjaman__c == null || receipt.LastCreatedStatusInPojjaman__c == 'Fail'){
						// generate request for cancelled receipt which not created in Pojjaman yet
						// put 2 item in requestDataModel
						// first item is created receipt
						requestDataModel.CustomerCode = receipt.Opportunity__r.Account.AccountCode__c;
						requestDataModel.ProjectCode = receipt.Opportunity__r.Project__r.ProjectCode__c;
						requestDataModel.SFDocId = receipt.Id;
						requestDataModel.DocDate = receipt.CreatedDate.date();
						requestDataModel.DocType = 'RP';
						requestDataModel.ReceiptCode = receipt.ReceiptNo__c;
						requestDataModel.Indicator = 0;
						List<PaymentReceiptLineItem__c> receiptLineItems = receipt.Payment_Transactions__r;
						List<ReceiptLineItemRequest> docLines = new List<ReceiptLineItemRequest>();
						Integer lineNumber = 1;
						for (PaymentReceiptLineItem__c receiptLineItem : receiptLineItems){
							ReceiptLineItemRequest docLine = new ReceiptLineItemRequest();
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
						List<PaymentMethod__c> paymentMethods = receipt.PaymentMethods__r;
						List<PaymentMethodRequest> paymentMethodRequests = new List<PaymentMethodRequest>();
						for (PaymentMethod__c paymentMethod: paymentMethods){
							PaymentMethodRequest paymentMethodRequest = new PaymentMethodRequest();
							paymentMethodRequest.SFPaymentMethodId = paymentMethod.Id;
							paymentMethodRequest.Method = paymentMethod.PaymentType__c;
							paymentMethodRequest.CreditCardNo = paymentMethod.PaymentType__c == 'Credit Card' ? paymentMethod.CreditCardNo__c : paymentMethod.PaymentType__c == 'Debit Card' ? paymentMethod.DebitCardNo__c : null;
							paymentMethodRequest.ChequeNo = paymentMethod.PaymentType__c == 'Cashier Cheque' ? paymentMethod.ChequeNo__c : paymentMethod.PaymentType__c == 'Bank Draft' ? paymentMethod.BankDraftNo__c : null ;
							paymentMethodRequest.ChequeBranch = paymentMethod.PaymentType__c == 'Cashier Cheque' ? paymentMethod.BankBranch__c : null ;
							paymentMethodRequest.BankBranch = paymentMethod.PaymentType__c != 'Cashier Cheque' ? paymentMethod.BankBranch__c : null;
							paymentMethodRequest.BankName = paymentMethod.PaymentType__c == 'Bank Transfer (International)' ? paymentMethod.InternationalBankName__c : paymentMethod.BankName__c;
							paymentMethodRequest.BankAccountNo = paymentMethod.BankAccountNo__c;
							paymentMethodRequest.RVBankAccountNo = paymentMethod.PaymentType__c == 'Bank Transfer (International)' || paymentMethod.PaymentType__c == 'Bank Transfer (Local)' ? paymentMethod.CompanyBank__r.BankAccountNumber__c : null;
							paymentMethodRequest.PaymentDate = paymentMethod.PaymentDate__c;
							paymentMethodRequest.Amount = paymentMethod.ReceivedAmount__c;
							paymentMethodRequests.add(paymentMethodRequest);
						}
						requestDataModel.PaymentMethod = paymentMethodRequests;
						requestDataModels.add(requestDataModel);
						// second item is cancelled receipt
						RequestDataModel cancelledRequestDataModel = new RequestDataModel();
						cancelledRequestDataModel.CustomerCode = receipt.Opportunity__r.Account.AccountCode__c;
						cancelledRequestDataModel.ProjectCode = receipt.Opportunity__r.Project__r.ProjectCode__c;
						cancelledRequestDataModel.SFDocId = receipt.Id;
						cancelledRequestDataModel.DocDate = receipt.CreatedDate.date();
						cancelledRequestDataModel.DocType = 'RP';
						cancelledRequestDataModel.ReceiptCode = receipt.ReceiptNo__c;
						cancelledRequestDataModel.Indicator = 2;
						cancelledRequestDataModel.DocLine = docLines;
						cancelledRequestDataModel.PaymentMethod = paymentMethodRequests;
						requestDataModels.add(cancelledRequestDataModel);
					} else {
						// if (receipt.LastCancelledStatusInPojjaman__c == null || receipt.LastCancelledStatusInPojjaman__c == 'Fail'){
							// generate request for cancelled receipt which already created in Pojjaman
							// put 1 item in requestDataModel
							requestDataModel.CustomerCode = receipt.Opportunity__r.Account.AccountCode__c;
							requestDataModel.ProjectCode = receipt.Opportunity__r.Project__r.ProjectCode__c;
							requestDataModel.SFDocId = receipt.Id;
							requestDataModel.DocDate = receipt.CreatedDate.date();
							requestDataModel.DocType = 'RP';
							requestDataModel.ReceiptCode = receipt.ReceiptNo__c;
							requestDataModel.Indicator = 2;
							List<PaymentReceiptLineItem__c> receiptLineItems = receipt.Payment_Transactions__r;
							List<ReceiptLineItemRequest> docLines = new List<ReceiptLineItemRequest>();
							Integer lineNumber = 1;
							for (PaymentReceiptLineItem__c receiptLineItem : receiptLineItems){
								ReceiptLineItemRequest docLine = new ReceiptLineItemRequest();
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
							List<PaymentMethod__c> paymentMethods = receipt.PaymentMethods__r;
							List<PaymentMethodRequest> paymentMethodRequests = new List<PaymentMethodRequest>();
							for (PaymentMethod__c paymentMethod: paymentMethods){
								PaymentMethodRequest paymentMethodRequest = new PaymentMethodRequest();
								paymentMethodRequest.SFPaymentMethodId = paymentMethod.Id;
								paymentMethodRequest.Method = paymentMethod.PaymentType__c;
								paymentMethodRequest.CreditCardNo = paymentMethod.PaymentType__c == 'Credit Card' ? paymentMethod.CreditCardNo__c : paymentMethod.PaymentType__c == 'Debit Card' ? paymentMethod.DebitCardNo__c : null;
								paymentMethodRequest.ChequeNo = paymentMethod.PaymentType__c == 'Cashier Cheque' ? paymentMethod.ChequeNo__c : paymentMethod.PaymentType__c == 'Bank Draft' ? paymentMethod.BankDraftNo__c : null ;
								paymentMethodRequest.ChequeBranch = paymentMethod.PaymentType__c == 'Cashier Cheque' ? paymentMethod.BankBranch__c : null ;
								paymentMethodRequest.BankBranch = paymentMethod.PaymentType__c != 'Cashier Cheque' ? paymentMethod.BankBranch__c : null;
								paymentMethodRequest.BankName = paymentMethod.PaymentType__c == 'Bank Transfer (International)' ? paymentMethod.InternationalBankName__c : paymentMethod.BankName__c;
								paymentMethodRequest.BankAccountNo = paymentMethod.BankAccountNo__c;
								paymentMethodRequest.RVBankAccountNo = paymentMethod.PaymentType__c == 'Bank Transfer (International)' || paymentMethod.PaymentType__c == 'Bank Transfer (Local)' ? paymentMethod.CompanyBank__r.BankAccountNumber__c : null;
								paymentMethodRequest.PaymentDate = paymentMethod.PaymentDate__c;
								paymentMethodRequest.Amount = paymentMethod.ReceivedAmount__c;
								paymentMethodRequests.add(paymentMethodRequest);
							}
							requestDataModel.PaymentMethod = paymentMethodRequests;
							requestDataModels.add(requestDataModel);
						// }
					}
				}
			} else {
				if (receipt.LastCreatedStatusInPojjaman__c == 'Success'){
					continue;
				}
				// generate normal request
				// created receipt
				requestDataModel.CustomerCode = receipt.Opportunity__r.Account.AccountCode__c;
				requestDataModel.ProjectCode = receipt.Opportunity__r.Project__r.ProjectCode__c;
				requestDataModel.SFDocId = receipt.Id;
				requestDataModel.DocDate = receipt.CreatedDate.date();
				requestDataModel.DocType = 'RP';
				requestDataModel.ReceiptCode = receipt.ReceiptNo__c;
				requestDataModel.Indicator = 0;
				List<PaymentReceiptLineItem__c> receiptLineItems = receipt.Payment_Transactions__r;
				List<ReceiptLineItemRequest> docLines = new List<ReceiptLineItemRequest>();
				Integer lineNumber = 1;
				for (PaymentReceiptLineItem__c receiptLineItem : receiptLineItems){
					ReceiptLineItemRequest docLine = new ReceiptLineItemRequest();
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
				List<PaymentMethod__c> paymentMethods = receipt.PaymentMethods__r;
				List<PaymentMethodRequest> paymentMethodRequests = new List<PaymentMethodRequest>();
				for (PaymentMethod__c paymentMethod: paymentMethods){
					PaymentMethodRequest paymentMethodRequest = new PaymentMethodRequest();
					paymentMethodRequest.SFPaymentMethodId = paymentMethod.Id;
					paymentMethodRequest.Method = paymentMethod.PaymentType__c;
					paymentMethodRequest.CreditCardNo = paymentMethod.PaymentType__c == 'Credit Card' ? paymentMethod.CreditCardNo__c : paymentMethod.PaymentType__c == 'Debit Card' ? paymentMethod.DebitCardNo__c : null;
					paymentMethodRequest.ChequeNo = paymentMethod.PaymentType__c == 'Cashier Cheque' ? paymentMethod.ChequeNo__c : paymentMethod.PaymentType__c == 'Bank Draft' ? paymentMethod.BankDraftNo__c : null ;
					paymentMethodRequest.ChequeBranch = paymentMethod.PaymentType__c == 'Cashier Cheque' ? paymentMethod.BankBranch__c : null ;
					paymentMethodRequest.BankBranch = paymentMethod.PaymentType__c != 'Cashier Cheque' ? paymentMethod.BankBranch__c : null;
					paymentMethodRequest.BankName = paymentMethod.PaymentType__c == 'Bank Transfer (International)' ? paymentMethod.InternationalBankName__c : paymentMethod.BankName__c;
					paymentMethodRequest.BankAccountNo = paymentMethod.BankAccountNo__c;
					paymentMethodRequest.RVBankAccountNo = paymentMethod.PaymentType__c == 'Bank Transfer (International)' || paymentMethod.PaymentType__c == 'Bank Transfer (Local)' ? paymentMethod.CompanyBank__r.BankAccountNumber__c : null;
					paymentMethodRequest.PaymentDate = paymentMethod.PaymentDate__c;
					paymentMethodRequest.Amount = paymentMethod.ReceivedAmount__c;
					paymentMethodRequests.add(paymentMethodRequest);
				}
				requestDataModel.PaymentMethod = paymentMethodRequests;
				requestDataModels.add(requestDataModel);
			}
		}
		return requestDataModels;
	}

	public override Boolean processFailedResponse() {
		b8int_BaseHttpRequest request = this.getRequestModel();
		b8int_BaseHttpResponse response = this.getResponseModel();
		System.debug('** test ** response: ' + response);
		List<RequestDataModel> targetRequests = (List<RequestDataModel>)request.getRequestBody();
		String errorDescription = response.getDescription();
		Map<Id,PaymentReceipt__c> updatedReceiptMapById = new Map<Id,PaymentReceipt__c>();
		List<PaymentReceiptLineItem__c> updatedReceiptLineItems = new List<PaymentReceiptLineItem__c>();
		List<PaymentMethod__c> updatedPaymentMethods = new List<PaymentMethod__c>();
		System.debug('** test ** targetRequests: ' + targetRequests);
		for (RequestDataModel eachRequest : targetRequests){
			PaymentReceipt__c receipt = new PaymentReceipt__c(
				Id = eachRequest.SFDocId,
				ResponseCode__c = 'ERR',
				ResponseMessage__c = errorDescription,
				LastIntegrationDateTime__c = System.now()
			);
			updatedReceiptMapById.put(receipt.Id , receipt);
			List<ReceiptLineItemRequest> receiptLineItemRequests = eachRequest.DocLine;
			for (ReceiptLineItemRequest receiptLineItemRequest : receiptLineItemRequests) {
				PaymentReceiptLineItem__c receiptLineItem = new PaymentReceiptLineItem__c(
					Id = receiptLineItemRequest.SFDocLineId,
					ResponseCode__c = 'ERR',
					ResponseMessage__c = errorDescription,
					LastIntegrationDateTime__c = System.now()
				);
				updatedReceiptLineItems.add(receiptLineItem);
			}
			List<PaymentMethodRequest> paymentMethodRequests = eachRequest.PaymentMethod;
			for (PaymentMethodRequest paymentMethodRequest : paymentMethodRequests) {
				PaymentMethod__c paymentMethod = new PaymentMethod__c(
					Id = paymentMethodRequest.SFPaymentMethodId,
					ResponseCode__c = 'ERR',
					ResponseMessage__c = errorDescription,
					LastIntegrationDateTime__c = System.now()
				);
				updatedPaymentMethods.add(paymentMethod);
			}
		}
		if (!updatedReceiptMapById.values().isEmpty()){
			update updatedReceiptMapById.values();
		}
		if (!updatedReceiptLineItems.isEmpty()){
			update updatedReceiptLineItems;
		}
		if (!updatedPaymentMethods.isEmpty()){
			update updatedPaymentMethods;
		}
		return true;
	}

	public override Boolean processSuccessResponse() {
		b8int_BaseHttpResponse response = this.getResponseModel();
		ResponseDataModel targetResponse = (ResponseDataModel)response.getResponseDataModel();
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		List<ReceiptResponse> receiptResponses = targetResponse.responses;
		List<PaymentReceiptLineItem__c> updatedReceiptLineItems = new List<PaymentReceiptLineItem__c>();
		List<PaymentMethod__c> updatedPaymentMethods = new List<PaymentMethod__c>();
		Set<Id> receiptIds = new Set<Id>();
		for (ReceiptResponse receiptResponse : receiptResponses){
			receiptIds.add(receiptResponse.SFDocId);
		}
		Map<Id,PaymentReceipt__c> existingReceiptMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(receiptIds);
		Map<Id,PaymentReceiptLineItem__c> receiptLineItemMapById = new Map<Id,PaymentReceiptLineItem__c>();
		Map<Id,PaymentMethod__c> paymentMethodMapById = new Map<Id,PaymentMethod__c>();
		System.debug('** test ** receiptResponses: ' + receiptResponses);
		for (ReceiptResponse receiptResponse : receiptResponses){
			PaymentReceipt__c existingReceipt = existingReceiptMapById.get(receiptResponse.SFDocId);
			existingReceipt.ResponseCode__c = receiptResponse.ResponseCode;
			existingReceipt.ResponseMessage__c = receiptResponse.Message;
			existingReceipt.LastIntegrationDateTime__c = receiptResponse.Timestamp;
			if (receiptResponse.ResponseCode == 'SC'){
				existingReceipt.LastCreatedStatusInPojjaman__c = 'Success' ;
			} else if (receiptResponse.ResponseCode == 'CSC'){
				existingReceipt.LastCancelledStatusInPojjaman__c = 'Success';
			} else {
				if (existingReceipt.LastCreatedStatusInPojjaman__c == null){
					existingReceipt.LastCreatedStatusInPojjaman__c = 'Fail';
				} else {
					existingReceipt.LastCancelledStatusInPojjaman__c = 'Fail';
				}
			}
			existingReceiptMapById.put(existingReceipt.Id , existingReceipt);
			List<ReceiptLineItemResponse> receiptLineItemResponses = receiptResponse.DocLine;
			for (ReceiptLineItemResponse receiptLineItemResponse : receiptLineItemResponses) {
				PaymentReceiptLineItem__c receiptLineItem = new PaymentReceiptLineItem__c(
					Id = receiptLineItemResponse.SFDocLineId,
					ResponseCode__c = receiptLineItemResponse.ResponseCode,
					ResponseMessage__c = receiptLineItemResponse.Message,
					LastIntegrationDateTime__c = receiptLineItemResponse.Timestamp
				);
				updatedReceiptLineItems.add(receiptLineItem);
				receiptLineItemMapById.put(receiptLineItemResponse.SFDocLineId , receiptLineItem);
			}
			List<PaymentMethodResponse> paymentMethodResponses = receiptResponse.PaymentMethod;
			for (PaymentMethodResponse paymentMethodResponse : paymentMethodResponses) {
				PaymentMethod__c paymentMethod = new PaymentMethod__c(
					Id = paymentMethodResponse.SFPaymentMethodId,
					ResponseCode__c = paymentMethodResponse.ResponseCode,
					ResponseMessage__c = paymentMethodResponse.Message,
					LastIntegrationDateTime__c = paymentMethodResponse.Timestamp
				);
				updatedPaymentMethods.add(paymentMethod);
				paymentMethodMapById.put(paymentMethodResponse.SFPaymentMethodId , paymentMethod);
			}
		}
		List<PaymentReceipt__c> updatedPaymentReceipts = existingReceiptMapById.values();
		List<PaymentReceiptLineItem__c> updatedPaymentReceiptLineItems = receiptLineItemMapById.values();
		List<PaymentMethod__c> updatedPaymentMethodList = paymentMethodMapById.values();
		if (!updatedPaymentReceipts.isEmpty()){
			update updatedPaymentReceipts;
		}
		if (!updatedPaymentReceiptLineItems.isEmpty()){
			update updatedPaymentReceiptLineItems;
		}
		if (!updatedPaymentMethodList.isEmpty()){
			update updatedPaymentMethodList;
		}
		return true;
	}

	public class RequestDataModel extends b8int_BaseRequestDataModel {
		public String CustomerCode;
		public String ProjectCode;
		public String SFDocId;
		public Date DocDate;
		public String DocType;
		public String ReceiptCode;
		public Integer Indicator;
		public List<ReceiptLineItemRequest> DocLine;
		public List<PaymentMethodRequest> PaymentMethod;
	}

	public class ReceiptLineItemRequest {
		public Integer LineNumber;
		public String UnitCode;
		public String Type;
		public Decimal Amount;
		public String SFDocLineId;
		public String Status;
		public String RefInvoiceId;
	}

	public class PaymentMethodRequest {
		public String SFPaymentMethodId;
		public String Method;
		public String CreditCardNo;
		public String ChequeNo;
		public String ChequeBranch;
		public String BankBranch;
		public String BankName;
		public String BankAccountNo;
		public String RVBankAccountNo;
		public Date PaymentDate;
		public Decimal Amount;
	}

	public class ResponseDataModel extends b8int_BaseResponseDataModel {
		public Boolean isSuccess;
        public String description;
		public List<ReceiptResponse> responses;

        public override Boolean isValid() {
            return isSuccess;
        }

        public override String getErrorDescription() {
            return this.description;
        }
	}

	public class ReceiptResponse{
		public String SFDocId;
		public Integer ResponseId;
		public String ResponseCode;
		public String Message;
		public Datetime Timestamp;
		public List<ReceiptLineItemResponse> DocLine;
		public List<PaymentMethodResponse> PaymentMethod;
	}

	public class ReceiptLineItemResponse{
		public String SFDocLineId;
		public Integer ResponseId;
		public String ResponseCode;
		public String Message;
		public Datetime Timestamp;
	}

	public class PaymentMethodResponse{
		public String SFPaymentMethodId;
		public Integer ResponseId;
		public String ResponseCode;
		public String Message;
		public Datetime Timestamp;
	}
}