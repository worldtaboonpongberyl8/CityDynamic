public with sharing class PromotionMasterSelector {
	public static PromotionMasterSelector instance;
	public static PromotionMasterSelector getInstance() {
		if (instance == null) {
			instance = new PromotionMasterSelector();
		}
		return instance;
	}
	public Map<Id, PromotionMaster__c> getPromotionMasterMapById(Set<Id> promotionMasterIds) {
		return new Map<Id, PromotionMaster__c>(
			[
				SELECT
					Id,
					ActiveFrom__c,
					ActiveTo__c,
					Description__c,
					IsActive__c,
					Project__c,
					PromotionCost__c,
					AdditionalDetail__c,
					PromotionType__c,
					Source__c,
					Unit__c
				FROM PromotionMaster__c
				WHERE Id IN :promotionMasterIds
			]
		);
	}

	public Map<String, List<PromotionMaster__c>> getMarketingPromotionsMapByKey(
		Set<String> projectCodes,
		Set<String> unitCodes
	) {
		Map<String, List<PromotionMaster__c>> marketingPromotionsMapByKey = new Map<String, List<PromotionMaster__c>>();
		List<PromotionMaster__c> promotionMasters = [
			SELECT
				Id,
				ActiveFrom__c,
				ActiveTo__c,
				Description__c,
				IsActive__c,
				Project__c,
				ProjectCode__c,
				PromotionCost__c,
				AdditionalDetail__c,
				PromotionType__c,
				Source__c,
				Unit__c,
				UnitCode__c,
				PromotionMasterKey__c
			FROM PromotionMaster__c
			WHERE
				(ProjectCode__c IN :projectCodes
				OR UnitCode__c IN :unitCodes)
				AND IsActive__c = TRUE
				AND Source__c = 'Marketing'
			ORDER BY CreatedDate ASC
		];
		for (PromotionMaster__c promotionMaster : promotionMasters) {
			String key = promotionMaster.ProjectCode__c;
			if (promotionMaster.UnitCode__c != null) {
				key = key + '_' + promotionMaster.UnitCode__c;
			}
			if (!marketingPromotionsMapByKey.containsKey(key)) {
				marketingPromotionsMapByKey.put(key, new List<PromotionMaster__c>());
			}
			marketingPromotionsMapByKey.get(key).add(promotionMaster);
		}
		return marketingPromotionsMapByKey;
	}
}