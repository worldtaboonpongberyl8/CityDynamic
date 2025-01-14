public with sharing class CreateRecordFromOpportunityController {
    @AuraEnabled
    public static Quote__c createQuoteFromOpportunity(Id oppId){
        try {
            QuoteService quoteService = QuoteService.getInstance();
            OpportunitySelector oppSelector = OpportunitySelector.getInstance();
            Map<Id,Opportunity> opportunities = oppSelector.getOpportunityMapById(new Set<Id>{oppId});
            List<Quote__c> targetQuotes = quoteService.generateQuotesFromOpportunities(opportunities.values());
            insert targetQuotes;
            return targetQuotes[0];
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static Contract createContractFromOpportunity(Id oppId){
        try {
            ContractService contractService = ContractService.getInstance();
            OpportunitySelector oppSelector = OpportunitySelector.getInstance();
            Map<Id,Opportunity> opportunities = oppSelector.getOpportunityWithSyncedQuotedMapById(new Set<Id>{oppId});
            List<Contract> targetContracts = contractService.generateContractsFromOpportunities(opportunities.values());
            insert targetContracts;
            return targetContracts[0];
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
}