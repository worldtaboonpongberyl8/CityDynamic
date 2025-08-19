public without sharing class PaymentReceiptFormController {
	private final Id paymentReceiptId;


	public static PaymentReceiptFormController instance {get; set;}
	public PaymentReceiptWrapper paymentReceiptInstance {get; set;}
	public static PaymentReceiptFormController getInstanceCtrl() {
		if (instance == null) {
			instance = new PaymentReceiptFormController();
		}
		return instance;
	}
	public PaymentReceiptFormController() {
		paymentReceiptId = ApexPages.currentPage().getParameters().get('Id');

	}
	public PaymentReceiptWrapper getPaymentReceipt(){
		if(paymentReceiptInstance == null){
			Map<Id, PaymentReceipt__c> paymentReceiptMapById = PaymentReceiptSelector.getInstance().getPaymentReceiptWithLineItemMapById(new Set<Id>{paymentReceiptId});
			Map<Id, List<PaymentMethod__c>> paymentMethodMapById = PaymentMathodSelector.getInstance().getPaymentMethodMapByPaymentReceiptId(new Set<Id>{paymentReceiptId});
			List<PaymentMethod__c> paymentMethods = paymentMethodMapById.get(paymentReceiptId);
			PaymentReceipt__c paymentReceipt = paymentReceiptMapById.get(paymentReceiptId);
			Opportunity opportunity = OpportunitySelector.getInstance().getById(paymentReceipt.Opportunity__c);
			Map<Id,Project__c> projectMapById = ProjectSelector.getInstance().getProjectById(new Set<Id>{opportunity.Project__c});
			Project__c getProject = projectMapById.get(opportunity.Project__c);
			// String imageUrl = PDFUtility.getInstance().getImageSrc(getProject.ProjectLogo__c);
			String imageUrl = getProject.ProjectLogoPublicURL__c;
			List<PaymentReceiptLineItem__c> paymentReceiptLineItems = paymentReceipt.Payment_Transactions__r;
			List<PaymentReceiptLineItem__c> updatePaymentReceiptLineItems = PaymentReceiptService.getInstance().aggregatePaymentReceiptLineItems(paymentReceiptLineItems);
			paymentReceiptInstance = new PaymentReceiptWrapper(paymentReceipt,opportunity,updatePaymentReceiptLineItems,paymentMethods,imageUrl);
		}
		return paymentReceiptInstance;
	}

	public class PaymentReceiptWrapper{
		public Boolean isCash {get; set;}
		public Boolean isCreditCard {get; set;}
		public Boolean isDebitCard {get; set;}
		public Boolean isCheque  {get; set;}
		public Boolean isBankTransferLocal {get; set;}
		public Boolean isBankTransferInter {get; set;}
		public Boolean isBankDraft {get; set;}
		// Phase2: add new variable
		public Boolean isUpgrade {get; set;}
		public Boolean isDowngrade {get; set;}
		public Boolean isMovePayment {get; set;}
		public PaymentReceiptHeaderWrapper paymentReceiptHeader {get; set;}
		public OpportunityWrapper oppWrapper {get; set;}
		public List<PaymentReceiptLineItemWrapper> paymentReceiptLineItemWrapper {get; set;}
		public Map<String , PaymentMethodWrapper> paymentMethodWrapperMap {get; set;}
		public PaymentReceiptWrapper(){

		}
		/**
		 * Phase2
		 * Details:
		 * - Modify logic to send PaymentReceipt__c.CoBuyerName__c to constructor
		 */
		public PaymentReceiptWrapper(PaymentReceipt__c paymentReceipt, Opportunity opportunity,List<PaymentReceiptLineItem__c> paymentReceiptLineItems,  List<PaymentMethod__c> paymentMethods, String imgUrl){
			setPaymentReceiptHeader(paymentReceipt.ReceiptNo__c, paymentReceipt.AccountAddress__c, paymentReceiptLineItems[0].PaymentReceipt__r.TotalReceiveAmount__c, imgUrl, paymentReceipt.IsCancel__c , paymentReceipt.CoBuyerName__c);
			setOpportunity(opportunity);
			setPaymentReceiptLineItem(paymentReceiptLineItems);
			setPaymentMethod(paymentMethods);
		}
		/**
		 * Phase2
		 * Details:
		 * - Modify logic to send PaymentReceipt__c.CoBuyerName__c to constructor
		 */
		public void setPaymentReceiptHeader(String receiptNo, String accountAddress, Decimal totalReceiveAmount,String imageUrl , Boolean isCancelled , String coBuyerName){
			paymentReceiptHeader = new PaymentReceiptHeaderWrapper(receiptNo,accountAddress,totalReceiveAmount,imageUrl,isCancelled,coBuyerName);
		}
		public void setOpportunity(Opportunity opportunity){
			oppWrapper = new OpportunityWrapper(opportunity);
		}
		public void setPaymentReceiptLineItem(List<PaymentReceiptLineItem__c> paymentReceiptLineItems){
			paymentReceiptLineItemWrapper = new List<PaymentReceiptLineItemWrapper>();
			Integer count = 1;
			for(PaymentReceiptLineItem__c paymentReceiptLineItem : paymentReceiptLineItems){
				PaymentReceiptLineItemWrapper lineItemWrapper = new PaymentReceiptLineItemWrapper(paymentReceiptLineItem,count);
				paymentReceiptLineItemWrapper.add(lineItemWrapper);
				count++;
			}
		}
		/**
		 * Phase2
		 * Details:
		 * - Modify logic to mapping new PaymentType__c
		 */
		public void setPaymentMethod(List<PaymentMethod__c> paymentMethods){
			paymentMethodWrapperMap = new Map<String, PaymentMethodWrapper>();

			for(PaymentMethod__c paymentMethod : paymentMethods){
				PaymentMethodWrapper paymentMethodWrapper = paymentMethodWrapperMap.get(paymentMethod.PaymentType__c);
				if(paymentMethodWrapper == null){
					paymentMethodWrapperMap.put(paymentMethod.PaymentType__c, new PaymentMethodWrapper(paymentMethod));
				}
				else{
					paymentMethodWrapper.addPaymentMethodList(paymentMethod);
				}
				PaymentMethodItemWrapper paymentMethodDetail = new PaymentMethodItemWrapper(paymentMethod);
			}
			isCash = paymentMethodWrapperMap.get('Cash') != null;
			isCreditCard =  paymentMethodWrapperMap.get('Credit Card') != null;
			isDebitCard = paymentMethodWrapperMap.get('Debit Card') != null;
			isCheque = paymentMethodWrapperMap.get('Cashier Cheque') != null;
			isBankTransferLocal = paymentMethodWrapperMap.get('Bank Transfer (Local)') != null;
			isBankTransferInter = paymentMethodWrapperMap.get('Bank Transfer (International)') != null;
			isBankDraft = paymentMethodWrapperMap.get('Bank Draft') != null;
			isUpgrade = paymentMethodWrapperMap.get('Upgrade') != null;
			isDowngrade = paymentMethodWrapperMap.get('Downgrade') != null;
			isMovePayment = paymentMethodWrapperMap.get('Move Payment') != null;
		}

	}
	public class OpportunityWrapper {
		public String companyName {get; set;}
		public String companyAddress {get; set;}
		public String companyPhone{get; set;}
		public String companyTaxID{get; set;}
		public String unitName{get; set;}
		public String towerName{get; set;}
		public String projectName{get; set;}
		public String coBuyerName{get; set;}
		public String accountTaxID{get; set;}
		public String customerContact{get; set;}
		public Boolean isTaxId {get; set;}
		public OpportunityWrapper(){ }

		public OpportunityWrapper(Opportunity opportunity){
			companyName = opportunity.Project__r.CompanyName__c;
			companyAddress = opportunity.Project__r.CompanyAddress__c;
			companyPhone = opportunity.Project__r.CompanyPhone__c;
			companyTaxID = opportunity.Project__r.CompanyTaxID__c;
			unitName = opportunity.Unit__r.Name;
			projectName = opportunity.Project__r.Name;
			coBuyerName = opportunity.CoBuyerName__c;
			/**
			 * Phase2
			 * Details:
			 * - Modify method to show Tower Name
			 */
			towerName = opportunity.Tower__c;
			if(opportunity.Account.TaxID__c != null){
				accountTaxID = opportunity.Account.TaxID__c;
				isTaxId = true;
			}else{
				isTaxId = false;
			}

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


	public class PaymentReceiptLineItemWrapper {
		public String order{get;set;}
		public String oppPaymentTerm{get; set;}
		public String oppPaymentDueDate{get; set;}
		public String oppPaymentRemainingAmount{get; set;}
		public String status{get; set;}
		public String oppPaymentReceiptAmount{get; set;}

		public PaymentReceiptLineItemWrapper(){

		}

		/**
		 * Phase2
		 * Details:
		 * - Modify method to show detail for Novation Receipt
		 */
		public PaymentReceiptLineItemWrapper(PaymentReceiptLineItem__c paymentReceiptLineItem,Integer orderInt){
			DateUtility dateUtility = DateUtility.getInstance();
			NumberUtility numberUtility = NumberUtility.getInstance();
			Boolean isNovatedReceipt = paymentReceiptLineItem.PaymentReceipt__r.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_NOVATION;
			order = String.valueOf(orderInt);
			oppPaymentTerm =  isNovatedReceipt ? GlobalConstants.RECEIPT_TYPE_NOVATION : paymentReceiptLineItem.OpportunityPayment__r.Term__c;
			oppPaymentDueDate = isNovatedReceipt ? dateUtility.toDateString('dd MMM yyyy', paymentReceiptLineItem.PaymentReceipt__r.NovationDate__c) : dateUtility.toDateString('dd MMM yyyy', paymentReceiptLineItem.OpportunityPayment__r.DueDate__c);
			oppPaymentRemainingAmount = numberUtility.setDecToFormatCommaTwoDigits(paymentReceiptLineItem.RemainingAmount__c);
			status = isNovatedReceipt? GlobalConstants.OPP_PAYMENT_STATUS_FULLYPAID : paymentReceiptLineItem.Status__c;
			oppPaymentReceiptAmount = numberUtility.setDecToFormatCommaTwoDigits(paymentReceiptLineItem.ReceivedAmount__c);

		}
	}
	public class PaymentMethodWrapper{
		public List<PaymentMethodItemWrapper> paymentMethodList {get; set;}

		public PaymentMethodWrapper(PaymentMethod__c paymentMethod){
			if(paymentMethodList == null){
				paymentMethodList = new List<PaymentMethodItemWrapper>{
					new PaymentMethodItemWrapper(paymentMethod)
				};
			}
		}

		public void addPaymentMethodList(PaymentMethod__c paymentMethod){
			paymentMethodList.add(new PaymentMethodItemWrapper(paymentMethod));
		}
	}

	public class PaymentMethodItemWrapper{
		public String paymentType{get; set;}
		public String creditCardNo{get; set;}
		public String bankName{get; set;}
		public String debitCardNo{get; set;}
		public String chequeNo{get; set;}
		public String intelBankName{get; set;}
		public String bankBranch{get; set;}
		public String paymentDate{get; set;}
		public String bankAccountNo{get; set;}
		public String bankDraftNo{get; set;}
		public String receiedAmount{get; set;}

		public PaymentMethodItemWrapper(PaymentMethod__c paymentMethod){
			DateUtility dateUtility = DateUtility.getInstance();
			NumberUtility numberUtility = NumberUtility.getInstance();
			receiedAmount = numberUtility.setDecToFormatCommaTwoDigits(paymentMethod.ReceivedAmount__c);
			paymentType = paymentMethod.PaymentType__c;
			creditCardNo =  String.valueOf(paymentMethod.CreditCardNo__c);
			bankName = paymentMethod.PaymentReceipt__r.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_PAYMENTGATEWAY ? 'Payment Gateway' : paymentMethod.BankName__c;
			intelBankName = paymentMethod.InternationalBankName__c;
			debitCardNo = String.valueOf(paymentMethod.DebitCardNo__c);
			chequeNo = String.valueOf(paymentMethod.ChequeNo__c);
			bankBranch = paymentMethod.BankBranch__c;
			bankAccountNo = paymentMethod.BankAccountNo__c;
			paymentDate = dateUtility.toDateString('dd MMM yyyy',paymentMethod.PaymentDate__c);
			bankDraftNo = String.valueOf(paymentMethod.BankDraftNo__c);
		}
	}

	/**
	 * Phase2
	 * Details:
	 * - Modify wrapper to receive PaymentReceipt__c.CoBuyerName__c
	 */
	public class PaymentReceiptHeaderWrapper{

		public String coBuyerName {get; set;}
		public String receiptNo {get; set;}
		public String accountAddress {get; set;}
		public String dateReceipt {get; set;}
		public String totalReceiveAmount{get; set;}
		public String imageUrl {get; set;}
		public Boolean isCancelled {get; set;}

		public PaymentReceiptHeaderWrapper(String receiptNo, String accountAddress, Decimal totalReceiveAmount,String imageUrl , Boolean isCancelled , String coBuyerName){
			DateUtility dateUtility = DateUtility.getInstance();
			NumberUtility numberUtility = NumberUtility.getInstance();
			this.coBuyerName = coBuyerName;
			this.receiptNo = receiptNo;
			this.accountAddress = accountAddress;
			this.dateReceipt = dateUtility.toDateString('dd MMM yyyy', System.today());
			this.totalReceiveAmount = numberUtility.setDecToFormatCommaTwoDigits(totalReceiveAmount);
			this.imageUrl = imageUrl;
			this.isCancelled = isCancelled;
		}
	}
}