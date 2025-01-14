public with sharing class PaymentReceiptLineItemSelector {
	public static PaymentReceiptLineItemSelector instance;
	public static PaymentReceiptLineItemSelector getInstance() {
		if (instance == null) {
			instance = new PaymentReceiptLineItemSelector();
		}
		return instance;
	}

	public List<PaymentReceiptLineItem__c> getByOpportunityId(Id oppId){
		return [
			SELECT Opportunity__c, OpportunityPayment__c, LineNumber__c, OpportunityPayment__r.Order__c,
				OpportunityPayment__r.Term__c, Status__c, ReceivedDate__c, ReceivedAmount__c,
				RemainingAmount__c
			FROM PaymentReceiptLineItem__c
			WHERE PaymentReceipt__r.Opportunity__c  =: oppId
				AND PaymentReceipt__r.IsCancel__c = false
			ORDER BY OpportunityPayment__r.Order__c, CreatedDate, LineNumber__c
		];
	}
}