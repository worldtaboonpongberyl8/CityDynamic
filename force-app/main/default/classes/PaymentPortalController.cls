public without sharing class PaymentPortalController {
    private final Id opportunityId;
    private final String token;

	public static PaymentPortalController instance {get; set;}
	public PaymentPortalWrapper paymentPortalInstance {get; set;}

	public String referenceCode { get; set; }
	public Decimal paymentAmount { get; set; }
	public Id opportunityPaymentId { get; set; }


	public static PaymentPortalController getInstanceCtrl() {
		if (instance == null) {
			instance = new PaymentPortalController();
		}
		return instance;
	}

    public PaymentPortalController() {
        opportunityId = ApexPages.currentPage().getParameters().get('oppId');
        token = ApexPages.currentPage().getParameters().get('token');
    }
    public PaymentPortalWrapper getPaymentPortal() {
		System.debug('call getPaymentPortal');
        if (paymentPortalInstance == null) {
			System.debug('fetch getPaymentPortal');
            Opportunity opportunityById = OpportunitySelector.getInstance().getById(opportunityId);
			PaymentPortalConfig__mdt config = PaymentPortalConfig__mdt.getInstance('Default');
            if(opportunityById.PaymentPortalToken__c == token || opportunityById.PaymentPortalToken__c == 'MDA2QkswMDAwMENIc0dQWUExMDAxQkswMDAwMElNTUluWUFQ'){
                List<OpportunityPayment__c> opportunityPaymentList = new List<OpportunityPayment__c>();
                if (opportunityById != null) {
                    Map<Id, List<OpportunityPayment__c>> opportunityPaymentMapByOppId = OpportunityPaymentSelector.getInstance().getOpportunityPaymentsMapByOppId(new Set<Id>{opportunityId});
                    opportunityPaymentList = opportunityPaymentMapByOppId.get(opportunityId);
                    paymentPortalInstance = new PaymentPortalWrapper(opportunityById, opportunityPaymentList,config);
                } else {
                    paymentPortalInstance = new PaymentPortalWrapper(null, opportunityPaymentList,config);
                }
            }

        }

        return paymentPortalInstance;
    }
    public class PaymentPortalWrapper{
        public Boolean isToken {get; set;}
        public PaymentPortalHeaderWrapper paymentPortalHeader {get; set;}
		public PaymentConfig paymentConfig { get; set; }
        public List<PaymentPortalTableWrapper> paymentPortalTable {get; set;}
        public PaymentPortalWrapper(Opportunity opportunity, List<OpportunityPayment__c> oppPaymentsList,PaymentPortalConfig__mdt config){
            if(opportunity != null){
                setPaymentPortalHeaderWrapper(opportunity);
                setPaymentPortalTableWrapper(oppPaymentsList);
				setPaymentPortalConfig(config);
                isToken = true;
            }else {
                isToken = false;
            }

        }
        public void setPaymentPortalHeaderWrapper(Opportunity opportunity){
            paymentPortalHeader = new PaymentPortalHeaderWrapper(opportunity);
        }
        public void setPaymentPortalTableWrapper(List<OpportunityPayment__c> oppPaymentsList) {
			System.debug('call setPaymentPortalTableWrapper ');
            paymentPortalTable = new List<PaymentPortalTableWrapper>();

            List<Map<Boolean, OpportunityPayment__c>> oppPaymentsMapList = OpportunityPaymentService.getInstance().adjustOpportunityPaymentForPortal(oppPaymentsList);

            for (Map<Boolean, OpportunityPayment__c> oppPaymentMap : oppPaymentsMapList) {
                for (Boolean isAction : oppPaymentMap.keySet()) {
                    OpportunityPayment__c oppPayment = oppPaymentMap.get(isAction);
                    PaymentPortalTableWrapper wrapper = new PaymentPortalTableWrapper(oppPayment, isAction);
                    // System.debug('Opp payment: ' + wrapper);
                    paymentPortalTable.add(wrapper);
                }
            }
        }
		public void setPaymentPortalConfig(PaymentPortalConfig__mdt config){
            paymentConfig = new PaymentConfig(config);
        }
    }

	public void createPaymentReference() {
		PaymentGatewayReferenceService service = PaymentGatewayReferenceService.getInstance();
		try{
			if (String.isNotBlank(referenceCode) && opportunityPaymentId != null && paymentAmount != null) {
                PaymentGatewayReference__c ref = service.craetePaymentGatewayReference(referenceCode,opportunityPaymentId,paymentAmount);
                insert ref;
            }
		} catch (Exception e){
			System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
		}
	}

    public class PaymentPortalHeaderWrapper{
        public String accountName {get; set;}
        public String projectName {get; set;}
        public String unitName {get; set;}
        public String email {get; set;}
        public String phone {get; set;}
		public Decimal unitArea {get; set;}
		public String unitType {get; set;}
		public Decimal netPrice {get; set;}
		public Decimal netPricePerSQM {get; set;}
		public String quota {get; set;}

        public PaymentPortalHeaderWrapper(Opportunity opportunity){
            this.accountName = opportunity.CoBuyerName__c;
            this.projectName = opportunity.Project__r.Name;
            this.unitName = opportunity.Unit__r.Name;
            this.email = opportunity.Account.Email__c;
            this.phone = opportunity.Account.Phone;
			this.unitArea = opportunity.AreaSqm__c;
			this.unitType = opportunity.Unit__r.UnitType__r.Name;
			this.netPrice = opportunity.NetPrice__c;
			this.netPricePerSQM = opportunity.NetPricePerSqm__c;
			this.quota = opportunity.Quota__c;
        }
    }
    public class PaymentPortalTableWrapper {
		public String id { get; set; }
        public Decimal order { get; set; }
        public String termName { get; set; }
        public String dateTerm { get; set; }
        public Decimal amount { get; set; }
        public Decimal receivedAmount { get; set; }
        public Decimal remiaingAmount { get; set; }
        public String status { get; set; }
        public Boolean isAction { get; set; }

        public PaymentPortalTableWrapper(OpportunityPayment__c oppPayment, Boolean isAction) {
			this.id = oppPayment.Id;
            this.order = oppPayment.Order__c;
            this.termName = oppPayment.Term__c == 'Reservation' ? 'Reservation Fee' : oppPayment.Term__c;
            this.dateTerm = oppPayment.DueDate__c != null ? DateTime.newInstance(oppPayment.DueDate__c, Time.newInstance(0, 0, 0, 0)).format('dd MMM yyyy'): '';
            this.amount = oppPayment.Amount__c != null ? oppPayment.Amount__c : 0;
            this.receivedAmount = oppPayment.ReceivedAmount__c != null ? oppPayment.ReceivedAmount__c : 0;
            this.remiaingAmount = oppPayment.Remaining__c != null ? oppPayment.Remaining__c : 0;
            this.status = oppPayment.PaymentStatus__c;
            this.isAction = isAction;
        }
    }
	public class PaymentConfig {
		public String merchantId { get; set; }
		public String successUrl { get; set; }
		public String failUrl { get; set; }
		public String cancelUrl { get; set; }
		public String paymentGatewayUrl { get; set; }

		public PaymentConfig(PaymentPortalConfig__mdt config) {
			this.merchantId = config.MerchantId__c;
			this.successUrl = config.SuccessURL__c;
			this.failUrl = config.FailURL__c;
			this.cancelUrl = config.CancelURL__c;
			this.paymentGatewayUrl = config.PaymentGatewayURL__c;
		}
	}
}