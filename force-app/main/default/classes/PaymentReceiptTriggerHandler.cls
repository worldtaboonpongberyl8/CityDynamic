public with sharing class PaymentReceiptTriggerHandler {
	public static PaymentReceiptTriggerHandler instance;
	public static PaymentReceiptTriggerHandler getInstance() {
		if (instance == null) {
			instance = new PaymentReceiptTriggerHandler();
		}
		return instance;
	}

	public Boolean isActive = true;
	public List<PaymentReceipt__c> newRecords;
	public Map<Id, PaymentReceipt__c> oldMap;

	public Boolean isTriggerActivated() {
		if (TriggerActivation__mdt.getInstance('PaymentReceiptTrigger') != null) {
			return this.isActive && TriggerActivation__mdt.getInstance('PaymentReceiptTrigger').isActive__c;
		}
		return this.isActive;
	}
	public void setParams(List<PaymentReceipt__c> newRecords, Map<Id, PaymentReceipt__c> oldMap) {
		this.newRecords = newRecords;
		this.oldMap = oldMap;
	}
	public void setBypass() {
		this.isActive = false;
	}

	public void clearBypass() {
		this.isActive = true;
	}

	public void executeBeforeUpdate() {
		this.validateIsLastReceiptBeforeCancel();
		this.validateInvoiceBeforeCancel();
	}

	public void executeAfterUpdate() {
		this.cancelReceivedAmountInOpportunityPayment();
	}

	private void validateIsLastReceiptBeforeCancel(){
		PaymentReceiptSelector paymentReceiptSelector = PaymentReceiptSelector.getInstance();
		PaymentReceipt__c targetPaymentReceipt;
		Id targetOppId;
		for (PaymentReceipt__c paymentReceipt : this.newRecords) {
			PaymentReceipt__c oldPaymentReceipt = this.oldMap.get(paymentReceipt.Id);
			if (
				oldPaymentReceipt.IsCancel__c != paymentReceipt.IsCancel__c &&
				paymentReceipt.IsCancel__c == true &&
				paymentReceipt.CancelReason__c != 'Closed Lost'
			) {
				targetOppId = paymentReceipt.Opportunity__c;
				targetPaymentReceipt = paymentReceipt;
			}
		}
		if (targetPaymentReceipt != null){
			Map<Id, PaymentReceipt__c> orderedPaymentReceiptMapById = PaymentReceiptSelector.getOrderedPaymentReceiptByOppIdMapById(targetOppId);
			List<PaymentReceipt__c> orderedPaymentReceipts = orderedPaymentReceiptMapById.values();
			for (PaymentReceipt__c receipt : orderedPaymentReceipts){
				System.debug('**test** receipt: ' + receipt.Id);
			}
			PaymentReceipt__c lastReceipt = orderedPaymentReceipts[0];
			System.debug('**test** targetPaymentReceipt: ' + targetPaymentReceipt);
			System.debug('**test** lastReceipt: ' + lastReceipt);
			if (targetPaymentReceipt.Id != lastReceipt.Id){
				targetPaymentReceipt.addError('Unable to cancel receipt which is not latest receipt');
			}
		}

	}

	private void validateInvoiceBeforeCancel() {
		PaymentReceiptSelector paymentReceiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		Set<Id> paymentReceiptIds = new Set<Id>();
		Id targetOppId;
		for (PaymentReceipt__c paymentReceipt : this.newRecords) {
			PaymentReceipt__c oldPaymentReceipt = this.oldMap.get(paymentReceipt.Id);
			if (
				oldPaymentReceipt.IsCancel__c != paymentReceipt.IsCancel__c &&
				paymentReceipt.IsCancel__c == true &&
				paymentReceipt.CancelReason__c != 'Closed Lost'
			) {
				paymentReceiptIds.add(paymentReceipt.Id);
				targetOppId = paymentReceipt.Opportunity__c;
			}
		}
		if (!paymentReceiptIds.isEmpty()) {
			// Datetime now = System.now();
			Map<Id, PaymentReceipt__c> paymentReceiptMapWithId = paymentReceiptSelector.getPaymentReceiptWithLineItemMapById(
				paymentReceiptIds
			);
			Map<String, Invoice__c> invoiceMapByTerm = invoiceSelector.getInvoiceMapByTerm(targetOppId);
			for (PaymentReceipt__c paymentReceipt : this.newRecords) {
				PaymentReceipt__c targetPaymentReceipt = paymentReceiptMapWithId.get(paymentReceipt.Id);
				List<PaymentReceiptLineItem__c> paymentReceiptLineItems = targetPaymentReceipt.Payment_Transactions__r ==
					null
					? new List<PaymentReceiptLineItem__c>()
					: targetPaymentReceipt.Payment_Transactions__r;
				for (PaymentReceiptLineItem__c paymentReceiptLineItem : paymentReceiptLineItems) {
					Datetime paymentCreatedDate = paymentReceiptLineItem.CreatedDate;
					Invoice__c targetInvoice = invoiceMapByTerm.get(
						paymentReceiptLineItem.OpportunityPayment__r.Term__c
					);
					if (targetInvoice != null && targetInvoice.CreatedDate > paymentCreatedDate) {
						paymentReceipt.addError('Unable to cancel receipt after invoice is created');
					}
				}
			}
		}
	}

	private void cancelReceivedAmountInOpportunityPayment() {
		OpportunityPaymentService service = OpportunityPaymentService.getInstance();
		PaymentReceiptSelector paymentReceiptSelector = PaymentReceiptSelector.getInstance();
		List<PaymentReceipt__c> filteredPaymentReceipt = new List<PaymentReceipt__c>();
		Set<Id> paymentReceiptIds = new Set<Id>();
		for (PaymentReceipt__c paymentReceipt : this.newRecords) {
			PaymentReceipt__c oldPaymentReceipt = this.oldMap.get(paymentReceipt.Id);
			if (oldPaymentReceipt.IsCancel__c != paymentReceipt.IsCancel__c && paymentReceipt.IsCancel__c == true && paymentReceipt.CancelReason__c != 'Closed Lost') {
				filteredPaymentReceipt.add(paymentReceipt);
				paymentReceiptIds.add(paymentReceipt.Id);
			}
		}
		if (!filteredPaymentReceipt.isEmpty()) {
			Map<Id, PaymentReceipt__c> paymentReceiptWithLineItemsMapById = paymentReceiptSelector.getPaymentReceiptWithLineItemMapById(
				paymentReceiptIds
			);
			List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>();
			for (Id paymentReceiptId : paymentReceiptWithLineItemsMapById.keySet()) {
				List<PaymentReceiptLineItem__c> paymentReceiptLineItems = paymentReceiptWithLineItemsMapById.get(
							paymentReceiptId
						)
						.Payment_Transactions__r == null
					? new List<PaymentReceiptLineItem__c>()
					: paymentReceiptWithLineItemsMapById.get(paymentReceiptId).Payment_Transactions__r;
				if (!paymentReceiptLineItems.isEmpty()) {
					oppPayments.addAll(service.cancelRecievedAmountFromReceiptLineItem(paymentReceiptLineItems));
				}
			}
			if (!oppPayments.isEmpty()) {
				update oppPayments;
			}
		}
	}
}