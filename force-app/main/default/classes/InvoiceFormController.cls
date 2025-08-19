public with sharing class InvoiceFormController {
    private final Id invoiceId;

	public static InvoiceFormController instance {get; set;}
	public InvoiceFormWrapper invoiceInstance {get; set;}
	public static InvoiceFormController getInstanceCtrl() {
		if (instance == null) {
			instance = new InvoiceFormController();
		}
		return instance;
	}

    public InvoiceFormController() {
        invoiceId = ApexPages.currentPage().getParameters().get('id');
    }

	public InvoiceFormWrapper getInvoice(){
		if(invoiceInstance == null){
			Invoice__c invoice = InvoiceSelector.getInstance().getById(invoiceId);
			List<OpportunityPayment__c> oppPayments = OpportunityPaymentSelector.getInstance().getForInvoiceForm(
				invoice.Opportunity__c,
				invoice.DueDate__c
			);
			Map<String, String> bankNameLabelMapByValue = BankService.getInstance().getBankNameLabelMapByValue();

			invoiceInstance = new InvoiceFormWrapper(invoice, oppPayments, bankNameLabelMapByValue);
		}

		return invoiceInstance;
	}

	public class InvoiceFormWrapper{
		public InvoiceHeaderWrapper invoiceHeader {get; set;}
		public OppDetailWrapper oppDetail {get; set;}
		public InvoiceItemWrapper invoiceItem {get; set;}
		public DeveloperAccountWrapper developerAccount {get; set;}

		public InvoiceFormWrapper(Invoice__c invoice, List<OpportunityPayment__c> oppPayments, Map<String, String> bankNameLabelMapByValue){
			oppDetail = new OppDetailWrapper(invoice);
			invoiceHeader = new InvoiceHeaderWrapper(invoice);
			invoiceItem = new InvoiceItemWrapper(oppPayments);
			developerAccount = new DeveloperAccountWrapper(invoice, bankNameLabelMapByValue);
		}

	}
	public class OppDetailWrapper {
		public String projectLogoUrl {get; set;}
		public String companyName {get; set;}
		public String companyAddress {get; set;}
		public String companyPhone {get; set;}
		public String companyTaxID {get; set;}
		public String unitName {get; set;}
		public String projectName {get; set;}
		public String towerName {get; set;}
		public String customerName {get; set;}
		public String customerTaxID {get; set;}
		public String customerContact {get; set;}
		public Boolean isTaxId {get; set;}

		public OppDetailWrapper(Invoice__c invoice){
			projectLogoUrl = PDFUtility.getInstance().getImageSrc(invoice.Opportunity__r.Project__r.ProjectLogo__c);
			companyName = invoice.Opportunity__r.Project__r.CompanyName__c;
			companyAddress = invoice.Opportunity__r.Project__r.CompanyAddress__c;
			companyPhone = invoice.Opportunity__r.Project__r.CompanyPhone__c;
			companyTaxID = invoice.Opportunity__r.Project__r.CompanyTaxID__c;
			unitName = invoice.Opportunity__r.Unit__r.Name;
			projectName = invoice.Opportunity__r.Project__r.Name;
			customerName = invoice.Opportunity__r.CoBuyerName__c;
			/**
			 * Phase2
			 * Details:
			 * - Modify method to show Tower Name
			 */
			towerName =  invoice.Opportunity__r.Tower__c;
			if(invoice.Opportunity__r.Account.TaxID__c != null){
				customerTaxID = invoice.Opportunity__r.Account.TaxID__c;
				isTaxId = true;
			}
			else{
				isTaxId = false;
			}

			customerContact = getCustomerContact(invoice);
		}

		private String getCustomerContact(Invoice__c invoice){
			String contact = '';
			if(invoice.Opportunity__r.ContactPerson__c != null){
				return PDFUtility.getInstance().getContactText(invoice.Opportunity__r.ContactPerson__r.MobilePhone, invoice.Opportunity__r.ContactPerson__r.Email);
			}
			else{
				return PDFUtility.getInstance().getContactText(invoice.Opportunity__r.Account.Phone, invoice.Opportunity__r.Account.Email__c);
			}
		}
	}

	/**
	 * Phase2
	 * Details:
	 * - Modify wrapper to receive Invoice__c.CoBuyerName__c
	 */
	public class InvoiceHeaderWrapper{
		public String invoiceNo {get; set;}
		public String accountAddress {get; set;}
		public String invoiceDate {get; set;}
		public Boolean isCancelled {get; set;}
		public String coBuyerName {get; set;}

		public InvoiceHeaderWrapper(Invoice__c invoice){
			DateUtility dateUtility = DateUtility.getInstance();
			NumberUtility numberUtility = NumberUtility.getInstance();
			this.invoiceNo = invoice.InvoiceNo__c;
			this.accountAddress = invoice.AccountAddress__c;
			this.invoiceDate = dateUtility.toDateString('dd MMM yyyy', invoice.InvoiceDate__c);
			this.isCancelled = invoice.IsCancel__c;
			this.coBuyerName = invoice.CoBuyerName__c;
		}
	}

	public class DeveloperAccountWrapper{
		public String accountName {get; set;}
		public String accountNumber {get; set;}
		public String bankName {get; set;}
		public String bankBranch {get; set;}
		public String bankAddress {get; set;}
		public String swiftCode {get; set;}

		public DeveloperAccountWrapper(Invoice__c invoice, Map<String, String> bankNameLabelMapByValue){
			accountName = invoice.Opportunity__r.Project__r.CompanyAccountNameForInvoice__r.Name;
			accountNumber = invoice.Opportunity__r.Project__r.BankAccountNumberForInvoice__c;
			bankName = bankNameLabelMapByValue.get(invoice.Opportunity__r.Project__r.CompanyBankNameForInvoice__c);
			bankBranch = invoice.Opportunity__r.Project__r.BankBranchForInvoice__c;
			bankAddress = invoice.Opportunity__r.Project__r.BankAddressForInvoice__c;
			swiftCode = invoice.Opportunity__r.Project__r.SWIFTCodeForInvoice__c;
		}
	}

	public class InvoiceItemWrapper{
		public String totalRemainingAmount {get; set;}
		public List<InvoiceItemDetailWrapper> invoiceItemDetails {get; set;}

		public InvoiceItemWrapper(List<OpportunityPayment__c> oppPayments){
			invoiceItemDetails = new List<InvoiceItemDetailWrapper>();
			Decimal sumRemainingAmount = 0;

			Integer lineNumber = 1;
			for (Integer i = 0; i < oppPayments.size(); i++) {
				OpportunityPayment__c oppPayment = oppPayments.get(i);

				invoiceItemDetails.add(
					new InvoiceItemDetailWrapper(
						oppPayment,
						lineNumber
					)
				);

				sumRemainingAmount += oppPayment.Remaining__c;
				lineNumber++;
			}

			totalRemainingAmount = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(sumRemainingAmount);
		}
	}

	public class InvoiceItemDetailWrapper {
		public String no {get; set;}
		public String description {get; set;}
		public String dueDate {get; set;}
		public String paymentAmount {get; set;}
		public String paymentStatus {get; set;}
		public String remainingBalanceAmount {get; set;}

		public InvoiceItemDetailWrapper(OpportunityPayment__c oppPayment, Integer lineNumber){
			no = String.valueOf(lineNumber);
			description = oppPayment.Term__c;
			dueDate = DateUtility.getInstance().toDateString('dd MMM yyyy', oppPayment.DueDate__c);
			paymentAmount = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(oppPayment.Amount__c);
			paymentStatus = oppPayment.PaymentStatus__c;
			remainingBalanceAmount = NumberUtility.getInstance().setDecToFormatCommaTwoDigits(oppPayment.Remaining__c);
		}
	}
}