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

	/**
	 * Phase2
	 * Details:
	 * - add logic to get String of list of AccountCode__c in CoBuyer
	 */
	public String getStringCoBuyerAccountCode(List<CoBuyer__c> coBuyers){
		List<String> accountCodes = new List<String>();
		for (CoBuyer__c coBuyer : coBuyers){
			if (coBuyer.Customer__r.AccountCode__c != null){
				accountCodes.add(coBuyer.Customer__r.AccountCode__c);
			} else {
				accountCodes.add('');
			}
		}
		if (!accountCodes.isEmpty()){
			if (String.join(accountCodes, ',') == ''){
				return 'x';
			}
			return String.join(accountCodes, ',');
		}
		return null;
	}


}