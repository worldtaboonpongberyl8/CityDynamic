public with sharing class OpportunityPaymentAdjustmentController {
    @AuraEnabled
    public static List<OpportunityPayment__c> getOpportunityPayment(Id oppId) {
        try {
            OpportunityPaymentSelector selector = OpportunityPaymentSelector.getInstance();
            Map<Id, List<OpportunityPayment__c>> opportunityPaymentsMapByOppId = selector.getOpportunityPaymentsMapByOppId(
                new Set<Id>{ oppId }
            );
            return opportunityPaymentsMapByOppId.get(oppId);
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static List<OpportunityPayment__c> upsertOppPayments(String oppPaymentsToBeUpsertedJSON) {
        try {
            OpportunityPaymentService service = OpportunityPaymentService.getInstance();
            List<OpportunityPayment__c> upsertedOppPayments = service.getOppPaymentsFromJSONString(
                oppPaymentsToBeUpsertedJSON
            );
            upsert upsertedOppPayments;
            return upsertedOppPayments;
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static List<OpportunityPayment__c> deleteOppPayments(String oppPaymentsToBeDeletedJSON) {
        try {
            OpportunityPaymentService service = OpportunityPaymentService.getInstance();
            List<OpportunityPayment__c> deletedOppPayments = service.getOppPaymentsFromJSONString(
                oppPaymentsToBeDeletedJSON
            );
            delete deletedOppPayments;
            return deletedOppPayments;
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static Boolean validateIsGrantedProfileProfile() {
        try {
            Set<String> grantedProfileNames = new Set<String>{
                'Head of CRM','CRM Officer','System Administrator'
            };
            UserSelector userSelector = UserSelector.getInstance();
            User thisUser = userSelector.getUserById(UserInfo.getUserId());
            String profileName = thisUser.Profile.Name;
            return grantedProfileNames.contains(profileName);
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
}