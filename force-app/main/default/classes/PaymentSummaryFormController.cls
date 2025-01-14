public with sharing class PaymentSummaryFormController {
	private final Id opportunityId;
	public PaymentSummaryWrapper paymentSummaryInstance { get; set; }

	public static PaymentSummaryFormController instance {get; set;}

	public static PaymentSummaryFormController getInstanceCtrl() {
		if (instance == null) {
			instance = new PaymentSummaryFormController();
		}
		return instance;
	}

	public PaymentSummaryFormController() {
		if(opportunityId == null){
			opportunityId = ApexPages.currentPage().getParameters().get('id');
		}
	}

	public PaymentSummaryWrapper getPaymentSummary() {
		if(paymentSummaryInstance == null){
			Opportunity opportunity = OpportunitySelector.getInstance().getById(opportunityId);
			List<OpportunityPayment__c> oppPayments = OpportunityPaymentSelector.getInstance().getForPaymentSummaryForm(opportunityId);
			List<PaymentReceiptLineItem__c> receiptLineItems = PaymentReceiptLineItemSelector.getInstance().getByOpportunityId(opportunityId);

			paymentSummaryInstance = new PaymentSummaryWrapper(opportunity, oppPayments, receiptLineItems);
		}
		return paymentSummaryInstance;
	}

	public class PaymentSummaryWrapper {
		public OppDetailWrapper oppDetail {get; set;}
		public PaymentItemWrapper paymentItem {get; set;}
		public PaymentFooterWrapper paymentFooter {get; set;}

		public PaymentSummaryWrapper(
			Opportunity opportunity,
			List<OpportunityPayment__c> oppPayments,
			List<PaymentReceiptLineItem__c> receiptLineItems
		){
			oppDetail = new OppDetailWrapper(opportunity);
			paymentItem = new PaymentItemWrapper(opportunity, oppPayments, receiptLineItems);
			paymentFooter = new PaymentFooterWrapper();
		}
	}

	public class OppDetailWrapper {
		public String projectLogoUrl {get; set;}
		public String companyName {get; set;}
		public String companyAddress {get; set;}
		public String companyPhone {get; set;}
		public String companyTaxId {get; set;}
		public String printDate {get; set;}
		public String unitName {get; set;}
		public String projectName {get; set;}
		public String paymentSummaryDate {get; set;}

		public String customerName {get; set;}
		public String customerAddress {get; set;}
		public String customerContact {get; set;}
		public String netPrice {get; set;}
		public String netPricePerSqm {get; set;}
		public String unitSize {get; set;}
		public String unitType {get; set;}

		public OppDetailWrapper(Opportunity opportunity){
			projectLogoUrl = PDFUtility.getInstance().getImageSrc(opportunity.Project__r.ProjectLogo__c);
			companyName = opportunity.Project__r.CompanyName__c;
			companyAddress = opportunity.Project__r.CompanyAddress__c;
			companyPhone = opportunity.Project__r.CompanyPhone__c;
			companyTaxId = opportunity.Project__r.CompanyTaxID__c;
			printDate = DateUtility.getInstance().toDateString('d MMM yyyy', System.today());
			unitName = opportunity.Unit__r.Name;
			projectName = opportunity.Project__r.Name;

			customerName = opportunity.CoBuyerName__c;
			customerAddress = opportunity.Account.AddressEN__c;
			netPrice = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(opportunity.NetPrice__c);
			netPricePerSqm = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(opportunity.NetPricePerSqm__c);
			unitSize = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(opportunity.AreaSqm__c);
			unitType = opportunity.Unit__r.UnitType__r.Name;

			customerContact = getCustomerContact(opportunity);
		}

		private String getCustomerContact(Opportunity opportunity){
			String contact = '';
			if(opportunity.ContactPerson__c != null){
				return PDFUtility.getInstance().getContactText(opportunity.ContactPerson__r.MobilePhone, opportunity.ContactPerson__r.Email);
			}
			else{
				return PDFUtility.getInstance().getContactText(opportunity.Account.Phone, opportunity.Account.Email__c);
			}
		}
	}

	public class PaymentItemWrapper {
		public String totalReceiveAmount {get; set;}
		public String totalReceivePercent {get; set;}
		public List<PaymentItemDetailWrapper> paymentItemDetails {get; set;}

		public PaymentItemWrapper(
			Opportunity opportunity,
			List<OpportunityPayment__c> oppPayments,
			List<PaymentReceiptLineItem__c> receiptLineItems
		){
			paymentItemDetails = new List<PaymentItemDetailWrapper>();
			Decimal sumReceiveAmount = 0;

			Map<Id, OpportunityPayment__c> oppPaymentMapById = new Map<Id, OpportunityPayment__c>(oppPayments);
			Map<Id, List<PaymentReceiptLineItem__c>> receiptLinesMapByOppPaymentId = getReceiptLineItemsMapByOppPaymentId(receiptLineItems);

			Integer lineNumber = 1;
			for (Id oppPaymentId : oppPaymentMapById.keySet()) {
				OpportunityPayment__c oppPayment = oppPaymentMapById.get(oppPaymentId);
				List<PaymentReceiptLineItem__c> receiptLines = receiptLinesMapByOppPaymentId.get(oppPaymentId);

				if(receiptLines == null){
					paymentItemDetails.add(new PaymentItemDetailWrapper(oppPayment, lineNumber));
				}
				else{
					for (Integer i = 0; i < receiptLines.size(); i++) {
						PaymentReceiptLineItem__c receiptLine = receiptLines.get(i);
						paymentItemDetails.add(
							new PaymentItemDetailWrapper(
								oppPayment,
								receiptLine,
								lineNumber,
								i == 0
							)
						);

						sumReceiveAmount += receiptLine.ReceivedAmount__c;
					}
				}

				lineNumber++;
			}

			totalReceiveAmount = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(sumReceiveAmount);
			if(sumReceiveAmount == 0){
				totalReceivePercent = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(0.00);
			}
			else {
				totalReceivePercent = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(
					(sumReceiveAmount / opportunity.NetPrice__c *100 )
				);
			}
		}

		private Map<Id, List<PaymentReceiptLineItem__c>> getReceiptLineItemsMapByOppPaymentId(List<PaymentReceiptLineItem__c> receiptLineItems){
			Map<Id, List<PaymentReceiptLineItem__c>> receiptLinesMapByOppPaymentId = new Map<Id, List<PaymentReceiptLineItem__c>>();
			for (PaymentReceiptLineItem__c receiptLineItem : receiptLineItems) {
				List<PaymentReceiptLineItem__c> receiptLines = receiptLinesMapByOppPaymentId.get(receiptLineItem.OpportunityPayment__c);

				if(receiptLines == null){
					receiptLinesMapByOppPaymentId.put(
						receiptLineItem.OpportunityPayment__c,
						new List<PaymentReceiptLineItem__c>{ receiptLineItem }
					);
				}
				else{
					receiptLines.add(receiptLineItem);
				}
			}
			return receiptLinesMapByOppPaymentId;
		}
	}

	public class PaymentItemDetailWrapper {
		public String no {get; set;}
		public String description {get; set;}
		public String dueDate {get; set;}
		public String paymentAmount {get; set;}
		public String paymentStatus {get; set;}
		public String receiveDate {get; set;}
		public String receiveAmount {get; set;}
		public String remainingBalanceAmount {get; set;}

		public PaymentItemDetailWrapper(OpportunityPayment__c oppPayment, Integer lineNumber){
			no = String.valueOf(lineNumber);
			description = oppPayment.Term__c;
			dueDate = DateUtility.getInstance().toDateString('dd MMM yyyy', oppPayment.DueDate__c);
			paymentAmount = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(oppPayment.Amount__c);
			paymentStatus = oppPayment.PaymentStatus__c;
			receiveDate = DateUtility.getInstance().toDateString('dd MMM yyyy', oppPayment.ReceivedDate__c);

			if(String.isBlank(paymentStatus)){
				receiveAmount = '';
				remainingBalanceAmount = '';
			}
			else {
				receiveAmount = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(oppPayment.ReceivedAmount__c);
				remainingBalanceAmount = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(oppPayment.Remaining__c);
			}
		}

		public PaymentItemDetailWrapper(
			OpportunityPayment__c oppPayment,
			PaymentReceiptLineItem__c receiptLine,
			Integer lineNumber,
			Boolean isSetPaymentDescription
		){
			if(isSetPaymentDescription){
				no = String.valueOf(lineNumber);
				description = oppPayment.Term__c;
				dueDate = DateUtility.getInstance().toDateString('dd MMM yyyy', oppPayment.DueDate__c);
				paymentAmount = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(oppPayment.Amount__c);
			}
			paymentStatus = receiptLine.Status__c;
			receiveDate = DateUtility.getInstance().toDateString('dd MMM yyyy', receiptLine.ReceivedDate__c);
			receiveAmount = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(receiptLine.ReceivedAmount__c);
			remainingBalanceAmount = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(receiptLine.RemainingAmount__c);
		}
	}

	public class PaymentFooterWrapper {
		public String issuedBy {get; set;}
		public String printDate {get; set;}

		public PaymentFooterWrapper(){
			issuedBy = UserInfo.getName();
			printDate = DateUtility.getInstance().toDateString('dd MMM yyyy', System.today());
		}
	}

}