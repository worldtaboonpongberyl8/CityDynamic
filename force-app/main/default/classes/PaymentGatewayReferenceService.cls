/**
 * Phase2
 * Details:
 * - Init class to be service for PaymentGatewayReference__c
 */
public without sharing class PaymentGatewayReferenceService {

   	public static PaymentGatewayReferenceService instance;
	public static PaymentGatewayReferenceService getInstance() {
		if (instance == null) {
			instance = new PaymentGatewayReferenceService();
		}
		return instance;
	}

	public PaymentGatewayReference__c craetePaymentGatewayReference(String referenceCode, String opportunityPaymentId, Decimal paymentAmount) {
		PaymentGatewayReference__c paymentGatewayReference = new PaymentGatewayReference__c(
			Name = referenceCode,
			OrderReference__c = referenceCode,
			OpportunityPayment__c = opportunityPaymentId,
			ReceivedAmount__c = paymentAmount
		);
		return paymentGatewayReference;
	}

	public PaymentGatewayReference__c stampPaymentGatewayReferenceFromDatafeedResult(PaymentGatewayReference__c paymentGatewayReference, String dfSuccessCode , String sfSuccesCode , String sfErrorMessage) {
		paymentGatewayReference.DatafeedStatus__c = dfSuccessCode == '0' ? GlobalConstants.PGF_STATUS_ACCEPTED : GlobalConstants.PGF_STATUS_REJECTED;
		paymentGatewayReference.SFStatus__c = sfSuccesCode == '0' ? GlobalConstants.PGF_STATUS_SUCCESS : GlobalConstants.PGF_STATUS_FAIL;
		paymentGatewayReference.SFErrorMessage__c = sfErrorMessage;
		return paymentGatewayReference;
	}
}