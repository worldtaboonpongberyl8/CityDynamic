public with sharing class PaymentTermSelector {
    public static PaymentTermSelector instance;
    public PaymentTermSelector() {
    }
    public static PaymentTermSelector getInstance() {
        if (instance == null) {
            instance = new PaymentTermSelector();
        }
        return instance;
    }

    // get Payment Term Master with Payment Term Line item
    public Map<Id,PaymentTermMaster__c> getPaymentTermMasterWithLineItemsMapById(Set<Id> paymentTermIds) {
        return new Map<Id,PaymentTermMaster__c>([
            SELECT
                Id,
                Name,
                ActiveFrom__c,
                ActiveTo__c,
                DueDate__c,
                NoofInstallment__c,
                Project__c,
                Quota__c,
                Type__c,
                (SELECT Id, Amount__c, Percent__c, Term__c, Order__c, PaymentTermMaster__c,IsAllowedPaymentByGateway__c FROM Payment_Term__r)
            FROM PaymentTermMaster__c
            WHERE Id IN :paymentTermIds
        ]);
    }
}