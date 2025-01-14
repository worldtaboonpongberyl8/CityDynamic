public with sharing class PaymentTermLineItemAdjustmentController {
    @AuraEnabled
    public static PaymentTermMaster__c getPaymentTermMasterWithLineItem(Id paymentTermMasterId) {
        try {
            PaymentTermSelector paymentTermSelector = PaymentTermSelector.getInstance();
            Map<Id, PaymentTermMaster__c> paymentTermMasterMapById = paymentTermSelector.getPaymentTermMasterWithLineItemsMapById(
                new Set<Id>{ paymentTermMasterId }
            );
            return paymentTermMasterMapById.get(paymentTermMasterId);
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static List<PaymentTerm__c> upsertPaymentTermLineItem(String paymentTermLineItemToBeUpsertedJSON) {
        try {
            PaymentTermService service = PaymentTermService.getInstance();
            List<PaymentTerm__c> upsertedPaymentTermLineItems = service.getPaymentTermLineItemFromJSONString(
                paymentTermLineItemToBeUpsertedJSON
            );
            upsert upsertedPaymentTermLineItems;
            return upsertedPaymentTermLineItems;
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
}