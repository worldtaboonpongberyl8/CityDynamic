/**
 * Phase2
 * Details:
 * - Init class to be selector for PaymentGatewayReference__c
 */
public without sharing class PaymentGatewayReferenceSelector {

	public static PaymentGatewayReferenceSelector instance;
	public static PaymentGatewayReferenceSelector getInstance() {
		if (instance == null) {
			instance = new PaymentGatewayReferenceSelector();
		}
		return instance;
	}

	public Map<String, PaymentGatewayReference__c> getPaymentGatewayReferenceMapByOrderRef(Set<String> orderRefs) {
		Map<String, PaymentGatewayReference__c> paymentGatewayReferenceMapByOrderRef = new Map<String, PaymentGatewayReference__c>();
		List<PaymentGatewayReference__c> paymentGatewayReferences = [
			SELECT
				Id,
				DatafeedStatus__c,
				OpportunityPayment__c,
				OpportunityPayment__r.Opportunity__c,
				OpportunityPayment__r.Opportunity__r.Id,
				OpportunityPayment__r.Opportunity__r.PaymentPortalToken__c,
				OrderReference__c,
				ReceivedAmount__c,
				RejectedReason__c,
				SFErrorMessage__c,
				SFStatus__c
			FROM PaymentGatewayReference__c
			WHERE OrderReference__c IN :orderRefs
		];
		System.debug('paymentGatewayReferences: ' + paymentGatewayReferences);
		for (PaymentGatewayReference__c paymentGatewayReference : paymentGatewayReferences) {
			paymentGatewayReferenceMapByOrderRef.put(paymentGatewayReference.OrderReference__c, paymentGatewayReference);
		}
		return paymentGatewayReferenceMapByOrderRef;
	}
}