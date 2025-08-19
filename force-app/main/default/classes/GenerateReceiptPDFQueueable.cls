public without sharing class GenerateReceiptPDFQueueable implements Queueable, Database.AllowsCallouts {
    private Id receiptId;
	private String ref;
	private String successCode;

    public GenerateReceiptPDFQueueable(Id receiptId,String ref,String successCode) {
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
            System.debug('🔁 Queue Job Started for Generate Receipt PDF ID: ' + receiptId);
            // Step 1: Generate PDF
            PDFGeneratorController.createPDFFileFromPaymentGateway(
                receiptId,
                'PaymentReceiptForm',
                'Document',
                'Payment Receipt',
                null
            );
            System.debug('✅ PDF Created');
			// Step 2: Send Email
			if (!Test.isRunningTest()){
				System.enqueueJob(new SendReceiptViaEmailQueueable(receiptId, ref , successCode));
			}
        } catch (Exception e) {
			pgrService.stampPaymentGatewayReferenceFromDatafeedResult(paymentGatewayReference,successCode,'1',e.getMessage()+'/'+e.getStackTraceString());
			update paymentGatewayReference;
            System.debug('❌ Exception in GenerateAndEmailReceiptJob: ' + e.getMessage() + e.getStackTraceString());
        }
    }
}