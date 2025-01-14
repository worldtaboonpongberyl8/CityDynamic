public with sharing class InvoiceLineItemSelector {
    public static InvoiceLineItemSelector instance;
    public static InvoiceLineItemSelector getInstance() {
        if (instance == null) {
            instance = new InvoiceLineItemSelector();
        }
        return instance;
    }

    public List<InvoiceLineItem__c> getByInvoiceIdSet(Set<Id> invoiceIdSet) {
        return [
            SELECT Id, Invoice__c, OpportunityPayment__c, Term__c, Amount__c, DueDate__c, 
                AmountTHText__c, AmountENText__c, AccountName__c, OpportunityName__c
            FROM InvoiceLineItem__c
            WHERE Invoice__c IN: invoiceIdSet
        ];
    }
}