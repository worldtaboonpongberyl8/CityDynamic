public with sharing class PromotionOpportunityService {

    public static PromotionOpportunityService instance;
    public static PromotionOpportunityService getInstance(){
        if (instance == null){
            instance = new PromotionOpportunityService();
        }
        return instance;
    }

    public List<PromotionOpportunity__c> createPromotionOpportunityRelateToOpportunity(List<Opportunity> opportunities){
        PromotionMasterSelector selector = PromotionMasterSelector.getInstance();
        List<PromotionOpportunity__c> promotionOpportunities = new List<PromotionOpportunity__c>();
        Set<String> projectCodes = new Set<String>();
        Set<String> unitCodes = new Set<String>();
        for (Opportunity opportunity : opportunities){
            projectCodes.add(opportunity.ProjectCode__c);
            unitCodes.add(opportunity.UnitCode__c);
        }
        Map<String, List<PromotionMaster__c>> promotionMastersMapByKey = selector.getMarketingPromotionsMapByKey(projectCodes,unitCodes);
        if (!promotionMastersMapByKey.isEmpty()){
            for (Opportunity opportunity : opportunities){
                String keyWithUnit = opportunity.ProjectCode__c + '_' + opportunity.UnitCode__c;
                String keyWithoutUnit = opportunity.ProjectCode__c;
                List<PromotionMaster__c> promotionMasters = promotionMastersMapByKey.containsKey(keyWithUnit) ? promotionMastersMapByKey.get(keyWithUnit) : promotionMastersMapByKey.get(keyWithoutUnit);
                if (promotionMasters != null){
                    List<PromotionOpportunity__c> promotionOpportunitiesFromPromotionMaster = this.createPromotionOpportunityFromPromotionMaster(promotionMasters);
                    for (PromotionOpportunity__c promotionOpportunity : promotionOpportunitiesFromPromotionMaster){
                        promotionOpportunity.Opportunity__c = opportunity.Id;
                    }
                    promotionOpportunities.addAll(promotionOpportunitiesFromPromotionMaster);
                }
            }
            insert promotionOpportunities;
        }
        return promotionOpportunities;
    }

    public List<PromotionOpportunity__c> createPromotionOpportunityFromPromotionMaster(List<PromotionMaster__c> promotionMasters){
        List<PromotionOpportunity__c> promotionOpportunities = new List<PromotionOpportunity__c>();
        for (PromotionMaster__c promotionMaster : promotionMasters){
            // tbc : mapping more field
            PromotionOpportunity__c promotionOpportunity = new PromotionOpportunity__c();
            promotionOpportunity.PromotionMaster__c = promotionMaster.Id;
            promotionOpportunities.add(promotionOpportunity);
        }
        return promotionOpportunities;
    }

    public List<PromotionOpportunity__c> deleteAndCreateNewPromotionOpportunity(List<Opportunity> opportunities){
        PromotionOpportunitySelector promotionOppSelector = PromotionOpportunitySelector.getInstance();
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opportunity : opportunities){
            oppIds.add(opportunity.Id);
        }
        Map<Id, List<PromotionOpportunity__c>> promotionOpportunitiesMapByOppId = promotionOppSelector.getPromotionOpportunitiesMapByOppId(oppIds);
        List<PromotionOpportunity__c> promotionOpportunitiesToDelete = new List<PromotionOpportunity__c>();
        for (Id oppId : promotionOpportunitiesMapByOppId.keySet()){
            List<PromotionOpportunity__c> promotionOpportunities = promotionOpportunitiesMapByOppId.get(oppId);
            promotionOpportunitiesToDelete.addAll(promotionOpportunities);
        }
        if (!promotionOpportunitiesToDelete.isEmpty()){
            delete promotionOpportunitiesToDelete;
        }
        return this.createPromotionOpportunityRelateToOpportunity(opportunities);
    }
}