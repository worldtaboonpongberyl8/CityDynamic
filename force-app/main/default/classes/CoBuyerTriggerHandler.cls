public with sharing class CoBuyerTriggerHandler {
    public CoBuyerTriggerHandler() {

    }
    public static CoBuyerTriggerHandler instance;
    public static CoBuyerTriggerHandler getInstance(){
        if (instance == null){
            instance = new CoBuyerTriggerHandler();
        }
        return instance;
    }

    public Boolean isActive = true;
    public List<CoBuyer__c> newRecords;
    public Map<Id, CoBuyer__c> oldMap;

    public Boolean isTriggerActivated() {
        if (TriggerActivation__mdt.getInstance('CoBuyerTrigger') != null) {
            return this.isActive && TriggerActivation__mdt.getInstance('CoBuyerTrigger').isActive__c;
        }
        return this.isActive;
    }
    public void setParams(List<CoBuyer__c> newRecords, Map<Id, CoBuyer__c> oldMap) {
        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }
    public void setBypass() {
        this.isActive = false;
    }

    public void clearBypass() {
        this.isActive = true;
    }

	/**
	 * Phase2
	 * Details:
	 * - Add method to validate quota before adding co buyer
	 */
	public void executeBeforeInsert(){
		this.validateQuotaBeforeInsertCoBuyer();
	}

	/**
	 * Phase2
	 * Details:
	 * - Edit method to call method to stamp opp quota after insert
	 */
    public void executeAfterInsert() {
        this.stampOppCoBuyerNameAndFlag();
		this.stampOpportunityQuotaAfterInsert();
    }

	/**
	 * Phase2
	 * Details:
	 * - Add method to validate quota when co buyer change status
	 */
	public void executeBeforeUpdate(){
		this.validateQuotaBeforeUpdateCoBuyer();
	}

	/**
	 * Phase2
	 * Details:
	 * - Edit method to call method to stamp co buyer name after change status
	 * - Edit method to call method to stamp opp quota after change status
	 */
    public void executeAfterUpdate() {
        this.stampOppCoBuyerNameAndFlagAfterChangedStatus();
		this.stampOpportunityQuotaAfterUpdate();
    }

    private void stampOppCoBuyerNameAndFlag(){
        CoBuyerService service = CoBuyerService.getInstance();
        service.stampOppCoBuyerNameAndFlag(this.newRecords);
    }

	/**
	 * Phase2
	 * Details:
	 * - Add method to validate quota before insert co buyer
	 */
	private void validateQuotaBeforeInsertCoBuyer(){
		OpportunityService oppService = OpportunityService.getInstance();
		OpportunitySelector oppSelector = OpportunitySelector.getInstance();
		Set<Id> oppIds = new Set<Id>();
		Map<Id,List<CoBuyer__c>> coBuyersMapByOpportunityId = new Map<Id,List<CoBuyer__c>>();
		for (CoBuyer__c coBuyer : this.newRecords){
			if (coBuyer.CoBuyerQuota__c == 'Foreign'){
				oppIds.add(coBuyer.Opportunity__c);
				if (!coBuyersMapByOpportunityId.containsKey(coBuyer.Opportunity__c)){
					coBuyersMapByOpportunityId.put(coBuyer.Opportunity__c, new List<CoBuyer__c>());
				}
				coBuyersMapByOpportunityId.get(coBuyer.Opportunity__c).add(coBuyer);
			}
		}
		if (!oppIds.isEmpty()){
			Map<Id, Opportunity> opportuntiyMapById = oppSelector.getOpportunityMapById(oppIds);
			Map<Id,Boolean> validateResultMapByOppId = oppService.validateIsQuotaAreaExceed(opportuntiyMapById.values());
			for (Id oppId : coBuyersMapByOpportunityId.keySet()){
				List<CoBuyer__c> coBuyers = coBuyersMapByOpportunityId.get(oppId);
				Boolean validateResult = validateResultMapByOppId.get(oppId);
				if (!validateResult){
					for (CoBuyer__c coBuyer : coBuyers){
						coBuyer.addError('The quota cannot be changed because it would cause the Foreign Quota Area of this project to exceed 49%.');
					}
				}
			}
		}
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to stamp co buyer name after change status
	 */
	private void stampOppCoBuyerNameAndFlagAfterChangedStatus(){
        CoBuyerService service = CoBuyerService.getInstance();
		List<CoBuyer__c> filteredCoBuyer = new List<CoBuyer__c>();
		for (CoBuyer__c coBuyer : this.newRecords){
			CoBuyer__c oldCoBuyer = this.oldMap.get(coBuyer.Id);
			if (coBuyer.Status__c != oldCoBuyer.Status__c){
				filteredCoBuyer.add(coBuyer);
			}
		}
		if (!filteredCoBuyer.isEmpty()){
			service.stampOppCoBuyerNameAndFlag(this.newRecords);
		}
    }

	/**
	 * Phase2
	 * Details:
	 * - Add method to stamp update Opportunity if foreign CoBuyer__c exists after insert
	 */
	private void stampOpportunityQuotaAfterInsert(){
		OpportunityService opportunityService = OpportunityService.getInstance();
		OpportunitySelector opportunitySelector = OpportunitySelector.getInstance();
		Set<Id> oppIds = new Set<Id>();
        for (CoBuyer__c coBuyer : this.newRecords){
            oppIds.add(coBuyer.Opportunity__c);
        }
        Map<Id, Opportunity> oppMapById = opportunitySelector.getOpportunityWithCoBuyerMapById(oppIds);
        List<Opportunity> opportunities = oppMapById.values();
		List<Opportunity> updatedOpportunities = opportunityService.stampFQQuotaIfForeignCoOwnerExists(opportunities);
		if (!updatedOpportunities.isEmpty()){
			update updatedOpportunities;
		}
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to validate quota before update co buyer status
	 */
	private void validateQuotaBeforeUpdateCoBuyer(){
		OpportunityService oppService = OpportunityService.getInstance();
		OpportunitySelector oppSelector = OpportunitySelector.getInstance();
		Set<Id> oppIds = new Set<Id>();
		Map<Id,List<CoBuyer__c>> coBuyersMapByOpportunityId = new Map<Id,List<CoBuyer__c>>();
		for (CoBuyer__c coBuyer : this.newRecords){
			CoBuyer__c oldCoBuyer = this.oldMap.get(coBuyer.Id);
			if (coBuyer.Status__c != oldCoBuyer.Status__c && coBuyer.CoBuyerQuota__c == 'Foreign'){
				oppIds.add(coBuyer.Opportunity__c);
				if (!coBuyersMapByOpportunityId.containsKey(coBuyer.Opportunity__c)){
					coBuyersMapByOpportunityId.put(coBuyer.Opportunity__c, new List<CoBuyer__c>());
				}
				coBuyersMapByOpportunityId.get(coBuyer.Opportunity__c).add(coBuyer);
			}
		}
		if (!oppIds.isEmpty()){
			Map<Id, Opportunity> opportuntiyMapById = oppSelector.getOpportunityMapById(oppIds);
			Map<Id,Boolean> validateResultMapByOppId = oppService.validateIsQuotaAreaExceed(opportuntiyMapById.values());
			for (Id oppId : coBuyersMapByOpportunityId.keySet()){
				List<CoBuyer__c> coBuyers = coBuyersMapByOpportunityId.get(oppId);
				Boolean validateResult = validateResultMapByOppId.get(oppId);
				if (!validateResult){
					for (CoBuyer__c coBuyer : coBuyers){
						coBuyer.addError('The quota cannot be changed because it would cause the Foreign Quota Area of this project to exceed 49%.');
					}
				}
			}
		}
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to stamp update Opportunity if foreign CoBuyer__c exists after update
	 */
	private void stampOpportunityQuotaAfterUpdate(){
		OpportunityService opportunityService = OpportunityService.getInstance();
		OpportunitySelector opportunitySelector = OpportunitySelector.getInstance();
		Set<Id> oppIds = new Set<Id>();
        for (CoBuyer__c coBuyer : this.newRecords){
			CoBuyer__c oldCoBuyer = this.oldMap.get(coBuyer.Id);
			if (coBuyer.Status__c != oldCoBuyer.Status__c){
				oppIds.add(coBuyer.Opportunity__c);
			}
        }
		if (!oppIds.isEmpty()){
			Map<Id, Opportunity> oppMapById = opportunitySelector.getOpportunityWithCoBuyerMapById(oppIds);
			List<Opportunity> opportunities = oppMapById.values();
			List<Opportunity> updatedOpportunities = opportunityService.stampFQQuotaIfForeignCoOwnerExists(opportunities);
			if (!updatedOpportunities.isEmpty()){
				update updatedOpportunities;
			}
		}
	}
}