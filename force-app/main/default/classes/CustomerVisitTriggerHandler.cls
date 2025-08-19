public with sharing class CustomerVisitTriggerHandler {
    public static CustomerVisitTriggerHandler instance;
    public static CustomerVisitTriggerHandler getInstance() {
        if (instance == null) {
            instance = new CustomerVisitTriggerHandler();
        }
        return instance;
    }

    public Boolean isActive = true;
    public List<CustomerVisit__c> newRecords;
    public Map<Id, CustomerVisit__c> oldMap;

    public Boolean isTriggerActivated() {
        if (TriggerActivation__mdt.getInstance('CustomerVisitTrigger') != null) {
            return this.isActive && TriggerActivation__mdt.getInstance('CustomerVisitTrigger').isActive__c;
        }
        return this.isActive;
    }

    public void setParams(List<CustomerVisit__c> newRecords, Map<Id, CustomerVisit__c> oldMap) {
        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }

    public void setBypass() {
        this.isActive = false;
    }

    public void clearBypass() {
        this.isActive = true;
    }

	public void executeAfterInsert(){
		this.updateOpportunityTourAnalysisFromCustomerVisit();
	}

	private void updateOpportunityTourAnalysisFromCustomerVisit(){
		OpportunityService oppService = OpportunityService.getInstance();
		List<Opportunity> opportunitiesList = oppService.stampTourAnalysisFromCustomerVisit(this.newRecords);
		if(!opportunitiesList.isEmpty()) {
			OpportunityTriggerHandler.getInstance().setBypass();
			update opportunitiesList;
			OpportunityTriggerHandler.getInstance().clearBypass();
		}
	}
}