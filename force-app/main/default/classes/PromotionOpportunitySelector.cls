public with sharing class PromotionOpportunitySelector {
	public static PromotionOpportunitySelector instance;
	public static PromotionOpportunitySelector getInstance() {
		if (instance == null) {
			instance = new PromotionOpportunitySelector();
		}
		return instance;
	}

	public Map<Id, List<PromotionOpportunity__c>> getPromotionOpportunitiesMapByOppId(Set<Id> oppIds) {
		Map<Id, List<PromotionOpportunity__c>> promotionOpportunitiesMapByOppId = new Map<Id, List<PromotionOpportunity__c>>();
		List<PromotionOpportunity__c> promotionOpportunities = [
			SELECT Id, Opportunity__c, PromotionMaster__c
			FROM PromotionOpportunity__c
			WHERE Opportunity__c IN :oppIds
		];
		for (PromotionOpportunity__c promotionOpportunity : promotionOpportunities){
			if (!promotionOpportunitiesMapByOppId.containsKey(promotionOpportunity.Opportunity__c)){
				promotionOpportunitiesMapByOppId.put(promotionOpportunity.Opportunity__c , new List<PromotionOpportunity__c>());
			}
			promotionOpportunitiesMapByOppId.get(promotionOpportunity.Opportunity__c).add(promotionOpportunity);
		}
		return promotionOpportunitiesMapByOppId;
	}
}