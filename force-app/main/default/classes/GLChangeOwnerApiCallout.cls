public with sharing class GLChangeOwnerApiCallout extends b8int_BaseHttpCallout{

	private List<OpportunityAccountChangeLog__c> oppAccountChangeLogs = new List<OpportunityAccountChangeLog__c>();

    public GLChangeOwnerApiCallout(List<OpportunityAccountChangeLog__c> oppAccountChangeLogs) {
		super('GLChangeOwner');
		this.oppAccountChangeLogs = oppAccountChangeLogs;
		this.setCalloutType(b8int_BaseHttpCallout.HttpCalloutType.REALTIME);
		this.setIsRequireRetry(false);
		this.setMethod(b8int_BaseHttpRequest.HttpMethod.POST);
		this.setClient(new GLChangeOwnerApiClient());
		this.setContentType(b8int_BaseHttpRequest.ContentType.JSON);
		this.setEndpoint('api/CityDynamic/CreateFN_GL');
		this.setRequestDataModelClass(PojjamanDataModel.FNGLDocRequest.class);
		this.setResponseDataModelClass(PojjamanDataModel.ResponseDataModel.class);
    }

	public override Object buildRequestDataModel() {
		List<PojjamanDataModel.FNGLDocRequest> requestDataModels = new List<PojjamanDataModel.FNGLDocRequest>();
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		Set<Id> receiptIds = new Set<Id>();
		Map<Id,OpportunityAccountChangeLog__c> oppAccChangeLogMapByReceiptId = new Map<Id,OpportunityAccountChangeLog__c>();
		for (OpportunityAccountChangeLog__c oppAccountChangeLog : oppAccountChangeLogs) {
			List<PaymentReceipt__c> paymentReceipts = oppAccountChangeLog.PaymentReceipts__r;
			for (PaymentReceipt__c paymentReceipt : paymentReceipts) {
				if (
					paymentReceipt.IsCancel__c &&
					paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_CRM
				) {
					continue;
				}
				oppAccChangeLogMapByReceiptId.put(paymentReceipt.Id, oppAccountChangeLog);
				receiptIds.add(paymentReceipt.Id);
			}
		}
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			receiptIds
		);
		List<PaymentReceipt__c> receipts = receiptWithReceiptLineItemsMapById.values() == null ? new List<PaymentReceipt__c>() : receiptWithReceiptLineItemsMapById.values();
		for (PaymentReceipt__c receipt : receipts) {
			OpportunityAccountChangeLog__c targetOppAcccChangeLog = oppAccChangeLogMapByReceiptId.get(receipt.Id);
			PojjamanDataModel.FNGLDocRequest requestDataModel = new PojjamanDataModel.FNGLDocRequest();
			requestDataModel.CustomerCode = targetOppAcccChangeLog.CurrentAccount__r.AccountCode__c;
			requestDataModel.PreviousCustomerCode = targetOppAcccChangeLog.PreviousAccount__r.AccountCode__c == null ? '' : targetOppAcccChangeLog.PreviousAccount__r.AccountCode__c;
			requestDataModel.ProjectCode = receipt.Opportunity__r.Project__r.ProjectCode__c;
			requestDataModel.SFDocId = receipt.Id;
			requestDataModel.DocDate = receipt.CreatedDate.date();
			requestDataModel.DocType = 'GL';
			requestDataModel.InvoiceCode = null;
			requestDataModel.ReceiptCode = receipt.ReceiptNo__c;
			requestDataModel.Indicator = 0;
			requestDataModel.GroupKey = receipt.CustomGLKey__c;
			requestDataModel.GLDate = receipt.CustomGLDate__c;
			requestDataModel.Remark = null;
			requestDataModel.CoBuyerCustomerCode = receipt.CoBuyerAccountCode__c == null ? null : receipt.CoBuyerAccountCode__c == 'x' ? new List<String>{''} : this.splitPreserveEmpty(receipt.CoBuyerAccountCode__c , ',');
			List<PaymentReceiptLineItem__c> receiptLineItems = receipt.Payment_Transactions__r;
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = new List<PojjamanDataModel.FNGLDocLineRequest>();
			Integer lineNumber = 1;
			for (PaymentReceiptLineItem__c receiptLineItem : receiptLineItems) {
				PojjamanDataModel.FNGLDocLineRequest docLine = new PojjamanDataModel.FNGLDocLineRequest();
				docLine.LineNumber = lineNumber;
				docLine.UnitCode = receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode;
				docLine.Type = receiptLineItem.OpportunityPayment__r.Term__c;
				docLine.Amount = receiptLineItem.ReceivedAmount__c;
				docLine.IsDebit = null;
				docLine.SFDocLineId = receiptLineItem.Id;
				docLine.Status = receiptLineItem.Status__c;
				docLine.RefInvoiceId = receiptLineItem.InvoiceLineItem__r.Invoice__c;
				docLines.add(docLine);
				lineNumber++;
			}
			requestDataModel.DocLine = docLines;
			requestDataModel.PaymentMethod = null;
			requestDataModels.add(requestDataModel);
		}
		return requestDataModels;
	}

	public override Boolean processFailedResponse() {
		b8int_BaseHttpResponse response = this.getResponseModel();
		String errorDescription = response.getDescription();
		List<OpportunityAccountChangeLog__c> updatedOppAccountChangeLog = new List<OpportunityAccountChangeLog__c>();
		for (OpportunityAccountChangeLog__c oppAccountChangeLog : this.oppAccountChangeLogs){
			oppAccountChangeLog.LastGLStatusInPojjaman__c = 'Fail';
			oppAccountChangeLog.LastIntegrationDateTime__c = System.now();
			oppAccountChangeLog.ResponseMessage__c = errorDescription;
			updatedOppAccountChangeLog.add(oppAccountChangeLog);
		}
		if (!updatedOppAccountChangeLog.isEmpty()){
			update updatedOppAccountChangeLog;
		}
		return true;
	}

	public override Boolean processSuccessResponse() {
		OpportunityAccountChangeLogSelector oppAccChangeLogSelector = OpportunityAccountChangeLogSelector.getInstance();
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		b8int_BaseHttpResponse response = this.getResponseModel();
		PojjamanDataModel.ResponseDataModel targetResponse = (PojjamanDataModel.ResponseDataModel) response.getResponseDataModel();
		List<PojjamanDataModel.FNGLDocResponse> glResponses = targetResponse.responses;
		Set<Id> allDocIds = new Set<Id>();
		Set<Id> failedDocIds = new Set<Id>();
		Set<Id> successedDocIds = new Set<Id>();
		Set<Id> allOppAccChangeLogIds = new Set<Id>();
		List<OpportunityAccountChangeLog__c> updatedOppAccChangeLogs = new List<OpportunityAccountChangeLog__c>();
		// STEP 1: separate between fail and success doc
		for (PojjamanDataModel.FNGLDocResponse glResponse : glResponses) {
			allDocIds.add(glResponse.SFDocId);
			if (glResponse.ResponseCode != 'SC'){
				failedDocIds.add(glResponse.SFDocId);
			} else {
				successedDocIds.add(glResponse.SFDocId);
			}
		}
		// STEP 2: get all receipts
		Map<Id,PaymentReceipt__c> allReceipt = receiptSelector.getPaymentReceiptWithLineItemMapById(allDocIds);
		for (PaymentReceipt__c receipt : allReceipt.values()) {
			allOppAccChangeLogIds.add(receipt.OpportunityAccountChangeLog__c);
		}
		// STEP 3: get all OpportunityAccountChangeLog__c and check if there is any fail doc
		Map<Id,OpportunityAccountChangeLog__c> allOppAccChangeLog = oppAccChangeLogSelector.getOpportunityAccountChangeLogWithSnapshotReceipts(allOppAccChangeLogIds);
		for (OpportunityAccountChangeLog__c oppAccChangeLog : allOppAccChangeLog.values()) {
			Boolean allDocPass = true;
			List<PaymentReceipt__c> paymentReceipts = oppAccChangeLog.PaymentReceipts__r;
			for (PaymentReceipt__c receipt : paymentReceipts) {
				if (failedDocIds.contains(receipt.Id)){
					allDocPass = false;
					break;
				}
			}
			oppAccChangeLog.LastGLStatusInPojjaman__c = allDocPass ? 'Success' : 'Fail';
			oppAccChangeLog.LastIntegrationDateTime__c = System.now();
			updatedOppAccChangeLogs.add(oppAccChangeLog);
		}
		if(!updatedOppAccChangeLogs.isEmpty()){
			update updatedOppAccChangeLogs;
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