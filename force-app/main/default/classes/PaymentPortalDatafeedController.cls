public without sharing class PaymentPortalDatafeedController {
    public String ack { get; private set; }

    public PaymentPortalDatafeedController() {


    }

	public PageReference proceedDatafeedResponse(){
		PaymentGatewayReferenceService pgrService = PaymentGatewayReferenceService.getInstance();
		PaymentGatewayReferenceSelector pgrSelector = PaymentGatewayReferenceSelector.getInstance();
		PaymentReceiptService receiptService = PaymentReceiptService.getInstance();
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
 		String successCode;
		PaymentGatewayReference__c paymentGatewayReference;
        try {
			// Always return OK
            ack = 'OK';

            Map<String, String> params = ApexPages.currentPage().getParameters();
            String ref = params.get('Ref');
            successCode = params.get('successcode');
            String amountText = params.get('Amt');
			Decimal amount = amountText != null ? Decimal.valueOf(amountText) : 0;
			String eci = params.get('eci');
			String first4DigitCardNumber = params.get('cc0104');
			String last4DigitCardNumber = params.get('cc1316');
			String cardNo = params.get('CreditCard');
			String providerName = params.get('PayMethod');

			System.debug('Ref: ' + Ref);
			System.debug('eci: ' + eci);
			System.debug('successCode: ' + successCode);
			System.debug('first4DigitCardNumber: ' + first4DigitCardNumber);
			System.debug('last4DigitCardNumber: ' + last4DigitCardNumber);
			System.debug('providerName: ' + providerName);

			Map<String, PaymentGatewayReference__c> paymentGatewayReferenceMapByOrderRef = pgrSelector.getPaymentGatewayReferenceMapByOrderRef(new Set<String>{ref});
			paymentGatewayReference = paymentGatewayReferenceMapByOrderRef.get(ref);

			if (successCode == '0'){
				// Step1 : Create PaymentReceipt__c , PaymentReceiptLineItem__c , and PaymentMethod__c
				PaymentReceipt__c targetRecipt = receiptService.createPaymentReceiptWithLineItemFromPaymentGateway(paymentGatewayReference.OpportunityPayment__r.Opportunity__c, amount, first4DigitCardNumber, last4DigitCardNumber, providerName, ref);
				System.debug('targetRecipt: ' + targetRecipt);
				// Step2 : Create Payment Receipt pdf attached to PaymentReceipt__c record and Send email with attached receipt to the customer
				System.enqueueJob(new GenerateReceiptPDFQueueable(targetRecipt.Id, ref , successCode));
			}
			// Step4 : Stamp result in existing PaymentGatewayReference__c record
			pgrService.stampPaymentGatewayReferenceFromDatafeedResult(paymentGatewayReference,successCode,'0',null);
			update paymentGatewayReference;
        } catch (Exception e) {
			pgrService.stampPaymentGatewayReferenceFromDatafeedResult(paymentGatewayReference,successCode,'1',e.getMessage()+'/'+e.getStackTraceString());
			update paymentGatewayReference;
            System.debug('Exception: ' + e.getMessage() + ' ' + e.getStackTraceString());
            ack = 'OK'; // Still respond OK to meet BBL requirement
        }
		return null;
	}
}