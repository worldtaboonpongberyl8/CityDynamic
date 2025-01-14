public with sharing class CoBuyerService {
    public static CoBuyerService instance;
    public static CoBuyerService getInstance(){
        if (instance == null){
            instance = new CoBuyerService();
        }
        return instance;
    }

    public List<Opportunity> stampOppCoBuyerNameAndFlag(List<CoBuyer__c> coBuyers){
        OpportunityService oppService = OpportunityService.getInstance();
        List<CoBuyer__c> testCoBuyers = [SELECT Id FROM CoBuyer__c];

        OpportunitySelector oppSelector = OpportunitySelector.getInstance();
        Set<Id> oppIds = new Set<Id>();
        for (CoBuyer__c coBuyer : coBuyers){
            oppIds.add(coBuyer.Opportunity__c);
        }
        Map<Id, Opportunity> oppMapById = oppSelector.getOpportunityWithCoBuyerMapById(oppIds);
        List<Opportunity> opportunities = oppMapById.values();
        List<Opportunity> updatedOpportunities = oppService.stampCoBuyerName(opportunities);
        update updatedOpportunities;
        return updatedOpportunities;
    }
}