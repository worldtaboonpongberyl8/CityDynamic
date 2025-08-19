public with sharing class PaymentTermService {
    public static PaymentTermService instance;
    public PaymentTermService() {
    }
    public static PaymentTermService getInstance() {
        if (instance == null) {
            instance = new PaymentTermService();
        }
        return instance;
    }

    public List<PaymentTerm__c> getPaymentTermLineItemFromJSONString(String paymentTermLineItemJSON) {
        List<PaymentTerm__c> paymentTermLineItemsResult = new List<PaymentTerm__c>();
        List<PaymentTermLineItemWrapper> paymentTermLineItemWrappers = (List<PaymentTermLineItemWrapper>) JSON.deserialize(
            paymentTermLineItemJSON,
            List<PaymentTermLineItemWrapper>.class
        );
        for (PaymentTermLineItemWrapper wrapper : paymentTermLineItemWrappers) {
            PaymentTerm__c paymentTermLineItem = new PaymentTerm__c();
            paymentTermLineItem.Id = wrapper.id;
            paymentTermLineItem.Order__c = wrapper.order;
            paymentTermLineItem.Amount__c = wrapper.amount;
            paymentTermLineItem.Percent__c = wrapper.percent;
            paymentTermLineItem.Term__c = wrapper.term;
            paymentTermLineItem.IsAllowedPaymentByGateway__c = wrapper.isAllowedPayment;
            paymentTermLineItem.PaymentTermMaster__c = wrapper.paymentTermMasterId;
            paymentTermLineItemsResult.add(paymentTermLineItem);
        }
        return paymentTermLineItemsResult;
    }

    public class PaymentTermLineItemWrapper {
        public Integer order;
        public Decimal amount;
        public Decimal percent;
        public String term;
        public String id;
        public Boolean isAllowedPayment;
        public String paymentTermMasterId;
    }
}