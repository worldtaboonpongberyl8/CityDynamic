public with sharing class SyncQuoteCtrl {
        @AuraEnabled
        public static Quote__c syncQuoteFromOpportunity(Id quoteId){
            try {
                QuoteService quoteService = QuoteService.getInstance();
                QuoteSelector quoteSelector = QuoteSelector.getInstance();
                Map<Id,Quote__c> quote = quoteSelector.getQuoteById(new Set<Id>{quoteId});
                Map<String, SObject> mapQuoteAndOpp = quoteService.getMapForSyncQuoteToOpp(quote.values());
                Quote__c quoteToUpdate = (Quote__c) mapQuoteAndOpp.get('Quote__c');
                Opportunity oppToUpdate = (Opportunity) mapQuoteAndOpp.get('Opportunity');
                if(oppToUpdate != null){
                    update oppToUpdate;
                }
                if(quoteToUpdate != null){
                    update quoteToUpdate;
                }
                return quoteToUpdate;
            } catch (Exception e) {
                System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
            }
        }
}