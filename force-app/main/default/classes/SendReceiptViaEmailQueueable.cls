public without sharing class SendReceiptViaEmailQueueable implements Queueable, Database.AllowsCallouts{

	private Id receiptId;
	private String ref;
	private String successCode;

    public SendReceiptViaEmailQueueable(Id receiptId,String ref,String successCode) {
		this.receiptId = receiptId;
		this.ref = ref;
		this.successCode = successCode;
    }

	public void execute(QueueableContext context) {
		PaymentGatewayReferenceService pgrService = PaymentGatewayReferenceService.getInstance();
		PaymentGatewayReferenceSelector pgrSelector = PaymentGatewayReferenceSelector.getInstance();
		Map<String, PaymentGatewayReference__c> paymentGatewayReferenceMapByOrderRef = pgrSelector.getPaymentGatewayReferenceMapByOrderRef(new Set<String>{ref});
		PaymentGatewayReference__c paymentGatewayReference = paymentGatewayReferenceMapByOrderRef.get(ref);
		try {
			System.debug('🔁 Queue Job Started for Send Receipt Via Email ID: ' + receiptId);
			// Step 2: Send Email
			PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
			PaymentReceiptService receiptService = PaymentReceiptService.getInstance();

			Map<Id, PaymentReceipt__c> receiptMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(new Set<Id>{receiptId});
			PaymentReceipt__c updatedReceipt = receiptMapById.get(receiptId);

			if (updatedReceipt != null) {
				receiptService.sendEmailWithAttachment(new List<PaymentReceipt__c>{ updatedReceipt });
				System.debug('📧 Email Sent Successfully');
			} else {
				System.debug('⚠️ Could not find PaymentReceipt__c with Id: ' + receiptId);
			}
		} catch (Exception e) {
			pgrService.stampPaymentGatewayReferenceFromDatafeedResult(paymentGatewayReference,successCode,'1',e.getMessage()+'/'+e.getStackTraceString());
			update paymentGatewayReference;
            System.debug('❌ Exception in GenerateAndEmailReceiptJob: ' + e.getMessage() + e.getStackTraceString());
        }

	}
}