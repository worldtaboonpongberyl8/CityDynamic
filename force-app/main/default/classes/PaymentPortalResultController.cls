public with sharing class PaymentPortalResultController {

	public String redirectUrl { get; set; }
	private final String orderRef;

    public PaymentPortalResultController() {
        String ref = ApexPages.currentPage().getParameters().get('Ref');
		this.orderRef = ref;

    }

	public PageReference urlRedirection() {
		if (String.isNotBlank(this.orderRef)) {
            Set<String> orderRefs = new Set<String>{ this.orderRef };

            Map<String, PaymentGatewayReference__c> refMap =
                PaymentGatewayReferenceSelector.getInstance().getPaymentGatewayReferenceMapByOrderRef(orderRefs);

            PaymentGatewayReference__c reference = refMap.get(this.orderRef);

            if (reference != null && reference.OpportunityPayment__r != null &&
                reference.OpportunityPayment__r.Opportunity__r != null) {

                String oppId = reference.OpportunityPayment__r.Opportunity__r.Id;
                String token = reference.OpportunityPayment__r.Opportunity__r.PaymentPortalToken__c;

                // Construct redirect URL (use site base)
               	String host = ApexPages.currentPage().getHeaders().get('Host'); // returns 'computing-page-7437--cddev.sandbox.my.salesforce-sites.com'
				Boolean isSiteContext = host != null && (
					host.contains('.salesforce-sites.com')
				);
				String protocol = 'https'; // Sites are always HTTPS unless explicitly configured otherwise
				String siteBaseUrl = protocol + '://' + host;
				// String redirectUrl;
				if (isSiteContext) {
					this.redirectUrl = siteBaseUrl + '/portal?oppId=' + oppId + '&token=' + token;
				} else {
					this.redirectUrl = '/apex/PaymentPortal?oppId=' + oppId + '&token=' + token;
				}
                // Optional: log it
                System.debug('Redirecting to: ' + redirectUrl);

                // Perform redirect
				// PageReference page = new PageReference(redirectUrl);
				// page.setRedirect(true);
				// return page;
				return null;
                // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Redirecting...'));
                // ApexPages.currentPage().getHeaders().put('Location', redirectUrl);
            }
        }
		return null;
    }

}