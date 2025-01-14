public with sharing class ProceedPaymentController {

    @AuraEnabled(cacheable=true)
    public static List<MakeAPaymentConfig__mdt> getMakeAPaymentConfig() {
        try{
            List<MakeAPaymentConfig__mdt> configs;
            Map<String,MakeAPaymentConfig__mdt> configMapByName = MakeAPaymentConfig__mdt.getAll();
            configs = configMapByName != null ? configMapByName.values() : new List<MakeAPaymentConfig__mdt>();
            return configs;
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ComboboxModel> getPicklistValues(String objectName, String fieldName) {
        List<ComboboxModel> values = new List<ComboboxModel>{};
        PicklistValueUtility utility = PicklistValueUtility.getInstance();
        try {
            values = utility.getPicklistComboboxes(objectName, fieldName);
            return values;
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

	@AuraEnabled(cacheable=true)
	public static List<ComboboxModel> getCompanyBanks(Id opportunityId){
		try {
			List<ComboboxModel> comboboxes = new List<ComboboxModel>();
			OpportunitySelector oppSelector = OpportunitySelector.getInstance();
			ProjectSelector projectSelector = ProjectSelector.getInstance();
			Opportunity targetOpportunity = oppSelector.getById(opportunityId);
			Id proojectId = targetOpportunity.Project__c;
			Map<Id, Project__c> projectWithActiveCompanyBankMapById = projectSelector.getProjectWithActiveCompanyBankMapById(new Set<Id>{proojectId});
			Project__c targetProject = projectWithActiveCompanyBankMapById.get(proojectId);
			List<Bank__c> banks = targetProject.Bank__r == null ? new List<Bank__c>() : targetProject.Bank__r;
			for (Bank__c bank : banks){
				comboboxes.add(new ComboboxModel(bank.DisplayName__c, bank.Id , bank.IsDefault__c));
			}
			return comboboxes;
		} catch (Exception e) {
			System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
		}
	}

    @AuraEnabled
    public static Map<String,List<SObject>> proceedPayment(Id opportunityId, Decimal recievedAmount, List<PaymentMethod__c> paymentMethods , Id receiptId) {
        Savepoint sp = Database.setSavepoint();
        try{
            Map<String,List<SObject>> resultMap = new Map<String,List<SObject>>();
            OpportunityPaymentSelector oppPaymentSelector = OpportunityPaymentSelector.getInstance();
            OpportunityPaymentService oppPaymentService = OpportunityPaymentService.getInstance();
            PaymentReceiptService paymentReceiptService = PaymentReceiptService.getInstance();
            InvoiceService invoiceService = InvoiceService.getInstance();
            Map<Id, List<OpportunityPayment__c>> opportunityPaymentMapByOppId = oppPaymentSelector.getOpportunityPaymentsWithInvoiceLineItemMapByOppId(
                new Set<Id>{opportunityId}
            );
            List<OpportunityPayment__c> oppPayments = opportunityPaymentMapByOppId.get(opportunityId);
            if (receiptId == null){
                PaymentReceipt__c paymentReceipt = paymentReceiptService.generatePaymentReceiptRelatedToOpportunity(opportunityId);
                insert paymentReceipt;
                PaymentReceipt__c paymentReceiptWithRunningNo = paymentReceiptService.generateRunningNo(paymentReceipt);
                update paymentReceiptWithRunningNo;
                receiptId = paymentReceiptWithRunningNo.Id;
                resultMap.put('PaymentReceipt__c' , new List<PaymentReceipt__c>{paymentReceiptWithRunningNo});
            }
            for (PaymentMethod__c paymentMethod : paymentMethods){
                paymentMethod.PaymentReceipt__c = receiptId;
            }
            insert paymentMethods;
            resultMap.put('PaymentMethod__c', paymentMethods);
            List<PaymentReceiptLineItem__c> paymentReceiptLineItems = paymentReceiptService.generatePaymentReceiptLineItemFromTotalReceivedAmount(recievedAmount,oppPayments,receiptId,paymentMethods[0].Id);
            insert paymentReceiptLineItems;
            List<OpportunityPayment__c> updatedOppPayments = oppPaymentService.stampFieldFromReceiptLineItem(paymentReceiptLineItems);
            update updatedOppPayments;
            return resultMap;
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
}