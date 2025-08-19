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
		// Phase2: change parameter to send to setRequestDataModelClass as PojjamanDataModel.FNGLDocRequest.class instead of RequestDataModel.class
        this.setRequestDataModelClass(PojjamanDataModel.FNGLDocRequest.class);
		// Phase2: change parameter to send to setResponseDataModelClass as PojjamanDataModel.ResponseDataModel.class instead of ResponseDataModel.class
        this.setResponseDataModelClass(PojjamanDataModel.ResponseDataModel.class);
    }

	public override Object buildRequestDataModel() {
		// Phase2: use data model as PojjamanDataModel.FNGLDocRequest
		List<PojjamanDataModel.FNGLDocRequest> requestDataModels = new List<PojjamanDataModel.FNGLDocRequest>();
		for (PaymentReceipt__c receipt : receipts) {
            PojjamanDataModel.FNGLDocRequest requestDataModel = new PojjamanDataModel.FNGLDocRequest();
			if (receipt.IsCancel__c){
				if (receipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_CRM){
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
						// Phase2: add Remark and CoBuyerCustomerCode
						requestDataModel.Remark = receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_RECURRING ? GlobalConstants.RECEIPT_REMARK_RECURRING :
													receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_PAYMENTGATEWAY ? GlobalConstants.RECEIPT_REMARK_PAYMENTGATEWAY :
													null;
						requestDataModel.CoBuyerCustomerCode = receipt.CoBuyerAccountCode__c == null ? null : receipt.CoBuyerAccountCode__c == 'x' ? new List<String>{''} : this.splitPreserveEmpty(receipt.CoBuyerAccountCode__c , ',');
						List<PaymentReceiptLineItem__c> receiptLineItems = receipt.Payment_Transactions__r;
						List<PojjamanDataModel.FNGLDocLineRequest> docLines = new List<PojjamanDataModel.FNGLDocLineRequest>();
						Integer lineNumber = 1;
						for (PaymentReceiptLineItem__c receiptLineItem : receiptLineItems){
							PojjamanDataModel.FNGLDocLineRequest docLine = new PojjamanDataModel.FNGLDocLineRequest();
							docLine.LineNumber = lineNumber;
							docLine.UnitCode = receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode;
							docLine.Type = receiptLineItem.OpportunityPayment__r.Term__c;
							docLine.Amount = receiptLineItem.ReceivedAmount__c;
							if (receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT){
								docLine.IsDebit = false;
							}
							docLine.SFDocLineId = receiptLineItem.Id;
							docLine.Status = receiptLineItem.Status__c;
							docLine.RefInvoiceId = receiptLineItem.InvoiceLineItem__r.Invoice__c;
							docLines.add(docLine);
							lineNumber++;
						}
						requestDataModel.DocLine = docLines;
						List<PaymentMethod__c> paymentMethods = receipt.PaymentMethods__r;
						List<PojjamanDataModel.FNGLPaymentMethodRequest> paymentMethodRequests = new List<PojjamanDataModel.FNGLPaymentMethodRequest>();
						for (PaymentMethod__c paymentMethod: paymentMethods){
							PojjamanDataModel.FNGLPaymentMethodRequest paymentMethodRequest = new PojjamanDataModel.FNGLPaymentMethodRequest();
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
						PojjamanDataModel.FNGLDocRequest cancelledRequestDataModel = new PojjamanDataModel.FNGLDocRequest();
						cancelledRequestDataModel.CustomerCode = receipt.Opportunity__r.Account.AccountCode__c;
						cancelledRequestDataModel.ProjectCode = receipt.Opportunity__r.Project__r.ProjectCode__c;
						cancelledRequestDataModel.SFDocId = receipt.Id;
						cancelledRequestDataModel.DocDate = receipt.CreatedDate.date();
						cancelledRequestDataModel.DocType = 'RP';
						cancelledRequestDataModel.ReceiptCode = receipt.ReceiptNo__c;
						cancelledRequestDataModel.Indicator = 2;
						// Phase2: add Remark and CoBuyerCustomerCode
						cancelledRequestDataModel.Remark = receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_RECURRING ? GlobalConstants.RECEIPT_REMARK_RECURRING :
															receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_PAYMENTGATEWAY ? GlobalConstants.RECEIPT_REMARK_PAYMENTGATEWAY :
															null;
						cancelledRequestDataModel.CoBuyerCustomerCode = receipt.CoBuyerAccountCode__c == null ? null : receipt.CoBuyerAccountCode__c == 'x' ? new List<String>{''} : this.splitPreserveEmpty(receipt.CoBuyerAccountCode__c , ',');
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
							// Phase2: add Remark and CoBuyerCustomerCode
							requestDataModel.Remark = receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_RECURRING ? GlobalConstants.RECEIPT_REMARK_RECURRING :
														receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_PAYMENTGATEWAY ? GlobalConstants.RECEIPT_REMARK_PAYMENTGATEWAY :
														null;
							requestDataModel.CoBuyerCustomerCode = receipt.CoBuyerAccountCode__c == null ? null : receipt.CoBuyerAccountCode__c == 'x' ? new List<String>{''} : this.splitPreserveEmpty(receipt.CoBuyerAccountCode__c , ',');
							List<PaymentReceiptLineItem__c> receiptLineItems = receipt.Payment_Transactions__r;
							List<PojjamanDataModel.FNGLDocLineRequest> docLines = new List<PojjamanDataModel.FNGLDocLineRequest>();
							Integer lineNumber = 1;
							for (PaymentReceiptLineItem__c receiptLineItem : receiptLineItems){
								PojjamanDataModel.FNGLDocLineRequest docLine = new PojjamanDataModel.FNGLDocLineRequest();
								docLine.LineNumber = lineNumber;
								docLine.UnitCode = receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode;
								docLine.Type = receiptLineItem.OpportunityPayment__r.Term__c;
								docLine.Amount = receiptLineItem.ReceivedAmount__c;
								if (receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT){
									docLine.IsDebit = false;
								}
								docLine.SFDocLineId = receiptLineItem.Id;
								docLine.Status = receiptLineItem.Status__c;
								docLine.RefInvoiceId = receiptLineItem.InvoiceLineItem__r.Invoice__c;
								docLines.add(docLine);
								lineNumber++;
							}
							requestDataModel.DocLine = docLines;
							List<PaymentMethod__c> paymentMethods = receipt.PaymentMethods__r;
							List<PojjamanDataModel.FNGLPaymentMethodRequest> paymentMethodRequests = new List<PojjamanDataModel.FNGLPaymentMethodRequest>();
							for (PaymentMethod__c paymentMethod: paymentMethods){
								PojjamanDataModel.FNGLPaymentMethodRequest paymentMethodRequest = new PojjamanDataModel.FNGLPaymentMethodRequest();
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
				requestDataModel.PreviousCustomerCode = receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENTNOOPERATION ? receipt.PreviousCustomerCode__c : null;
				requestDataModel.ProjectCode = receipt.Opportunity__r.Project__r.ProjectCode__c;
				requestDataModel.SFDocId = receipt.Id;
				requestDataModel.DocDate = receipt.CreatedDate.date();
				requestDataModel.DocType = receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT || receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENTNOOPERATION ? 'GL' : 'RP';
				requestDataModel.ReceiptCode = receipt.ReceiptNo__c;
				// Phase2: change indicator of receipt which type is move payment (include Operation receipt) to '5'
				requestDataModel.Indicator = receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT || receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENTNOOPERATION ? 5 : 0;
				// Phase2: add GroupKey to receipt which type is move payment (include Operation receipt)
				requestDataModel.GroupKey = receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT || receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENTNOOPERATION ? receipt.CustomGLKey__c : null;
				requestDataModel.GLDate = receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT || receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENTNOOPERATION ? receipt.CustomGLDate__c : null;
				// Phase2: add Remark and CoBuyerCustomerCode
				requestDataModel.Remark = receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_RECURRING ? GlobalConstants.RECEIPT_REMARK_RECURRING :
											receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_PAYMENTGATEWAY ? GlobalConstants.RECEIPT_REMARK_PAYMENTGATEWAY :
											null;
				requestDataModel.CoBuyerCustomerCode = receipt.CoBuyerAccountCode__c == null ? null : receipt.CoBuyerAccountCode__c == 'x' ? new List<String>{''} : this.splitPreserveEmpty(receipt.CoBuyerAccountCode__c , ',');
				List<PaymentReceiptLineItem__c> receiptLineItems = receipt.Payment_Transactions__r;
				List<PojjamanDataModel.FNGLDocLineRequest> docLines = new List<PojjamanDataModel.FNGLDocLineRequest>();
				Integer lineNumber = 1;
				for (PaymentReceiptLineItem__c receiptLineItem : receiptLineItems){
					PojjamanDataModel.FNGLDocLineRequest docLine = new PojjamanDataModel.FNGLDocLineRequest();
					docLine.LineNumber = lineNumber;
					docLine.UnitCode = receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode;
					// Phase2: edit doc line type to send 'Operation' in case of Novation and Operation in Upgrade/Downgrade
					docLine.Type = receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_NOVATION || receiptLineItem.ReceiptLineItemType__c == GlobalConstants.RECEIPTLINE_TYPE_OPERATION ? GlobalConstants.RECEIPTLINE_TYPE_OPERATION : receiptLineItem.OpportunityPayment__r.Term__c;
					docLine.Amount = receiptLineItem.ReceivedAmount__c;
					if (receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT || receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENTNOOPERATION){
						docLine.IsDebit = false;
					}
					docLine.SFDocLineId = receiptLineItem.Id;
					docLine.Status = receiptLineItem.Status__c;
					docLine.RefInvoiceId = receiptLineItem.InvoiceLineItem__r.Invoice__c;
					docLines.add(docLine);
					lineNumber++;
				}
				requestDataModel.DocLine = docLines;
				List<PaymentMethod__c> paymentMethods = receipt.PaymentMethods__r;
				List<PojjamanDataModel.FNGLPaymentMethodRequest> paymentMethodRequests = new List<PojjamanDataModel.FNGLPaymentMethodRequest>();
				for (PaymentMethod__c paymentMethod: paymentMethods){
					PojjamanDataModel.FNGLPaymentMethodRequest paymentMethodRequest = new PojjamanDataModel.FNGLPaymentMethodRequest();
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
		List<PojjamanDataModel.FNGLDocRequest> targetRequests = (List<PojjamanDataModel.FNGLDocRequest>)request.getRequestBody();
		String errorDescription = response.getDescription();
		Map<Id,PaymentReceipt__c> updatedReceiptMapById = new Map<Id,PaymentReceipt__c>();
		List<PaymentReceiptLineItem__c> updatedReceiptLineItems = new List<PaymentReceiptLineItem__c>();
		List<PaymentMethod__c> updatedPaymentMethods = new List<PaymentMethod__c>();
		for (PojjamanDataModel.FNGLDocRequest eachRequest : targetRequests){
			PaymentReceipt__c receipt = new PaymentReceipt__c(
				Id = eachRequest.SFDocId,
				ResponseCode__c = 'ERR',
				ResponseMessage__c = errorDescription,
				LastIntegrationDateTime__c = System.now()
			);
			updatedReceiptMapById.put(receipt.Id , receipt);
			List<PojjamanDataModel.FNGLDocLineRequest> receiptLineItemRequests = eachRequest.DocLine;
			for (PojjamanDataModel.FNGLDocLineRequest receiptLineItemRequest : receiptLineItemRequests) {
				PaymentReceiptLineItem__c receiptLineItem = new PaymentReceiptLineItem__c(
					Id = receiptLineItemRequest.SFDocLineId,
					ResponseCode__c = 'ERR',
					ResponseMessage__c = errorDescription,
					LastIntegrationDateTime__c = System.now()
				);
				updatedReceiptLineItems.add(receiptLineItem);
			}
			List<PojjamanDataModel.FNGLPaymentMethodRequest> paymentMethodRequests = eachRequest.PaymentMethod;
			for (PojjamanDataModel.FNGLPaymentMethodRequest paymentMethodRequest : paymentMethodRequests) {
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
		PojjamanDataModel.ResponseDataModel targetResponse = (PojjamanDataModel.ResponseDataModel)response.getResponseDataModel();
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		List<PojjamanDataModel.FNGLDocResponse> receiptResponses = targetResponse.responses;
		List<PaymentReceiptLineItem__c> updatedReceiptLineItems = new List<PaymentReceiptLineItem__c>();
		List<PaymentMethod__c> updatedPaymentMethods = new List<PaymentMethod__c>();
		Set<Id> receiptIds = new Set<Id>();
		for (PojjamanDataModel.FNGLDocResponse receiptResponse : receiptResponses){
			receiptIds.add(receiptResponse.SFDocId);
		}
		Map<Id,PaymentReceipt__c> existingReceiptMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(receiptIds);
		Map<Id,PaymentReceiptLineItem__c> receiptLineItemMapById = new Map<Id,PaymentReceiptLineItem__c>();
		Map<Id,PaymentMethod__c> paymentMethodMapById = new Map<Id,PaymentMethod__c>();
		for (PojjamanDataModel.FNGLDocResponse receiptResponse : receiptResponses){
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
			List<PojjamanDataModel.FNGLDocLineItemResponse> receiptLineItemResponses = receiptResponse.DocLine;
			for (PojjamanDataModel.FNGLDocLineItemResponse receiptLineItemResponse : receiptLineItemResponses) {
				PaymentReceiptLineItem__c receiptLineItem = new PaymentReceiptLineItem__c(
					Id = receiptLineItemResponse.SFDocLineId,
					ResponseCode__c = receiptLineItemResponse.ResponseCode,
					ResponseMessage__c = receiptLineItemResponse.Message,
					LastIntegrationDateTime__c = receiptLineItemResponse.Timestamp
				);
				updatedReceiptLineItems.add(receiptLineItem);
				receiptLineItemMapById.put(receiptLineItemResponse.SFDocLineId , receiptLineItem);
			}
			List<PojjamanDataModel.FNGLPaymentMethodResponse> paymentMethodResponses = receiptResponse.PaymentMethod;
			for (PojjamanDataModel.FNGLPaymentMethodResponse paymentMethodResponse : paymentMethodResponses) {
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