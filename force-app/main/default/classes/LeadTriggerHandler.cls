public with sharing class LeadTriggerHandler {
    public static LeadTriggerHandler instance;
    public LeadTriggerHandler() {

    }
    public static LeadTriggerHandler getInstance(){
        if (instance == null) {
            instance = new LeadTriggerHandler();
        }
        return instance;
    }

    public Boolean isActive = true;
    public List<Lead> newRecords;
    public Map<Id,Lead> oldMap;

    public Boolean isTriggerActivated(){
        if (TriggerActivation__mdt.getInstance('LeadTrigger') != null){
            return this.isActive && TriggerActivation__mdt.getInstance('LeadTrigger').isActive__c;
        }
        return this.isActive;
    }

    public void setBypass(){
        this.isActive = false;
    }

    public void clearBypass(){
        this.isActive = true;
    }

    public void setParams(List<Lead> newRecords, Map<Id,Lead> oldMap){
        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }

    public void executeBeforeInsert(){
		this.assignCountryFromCountryCode();
		this.stampProjectFromProjectCode();
    }

	public void executeAfterInsert(){
		this.assignLeadToQueueAndRoundRobinFuture();
    }

	/**
	 * Phase: 1
	 * UAT Issue: DF-UAT-004
	*/
	private void assignCountryFromCountryCode(){
		LeadService service = LeadService.getInstance();
		List<Lead> filteredLead = new List<Lead>();
		for (Lead lead : this.newRecords){
			if (lead.LeadOrigin__c == 'Web-to-Lead'){
				filteredLead.add(lead);
			}
		}
        service.assignLeadCountryFromCountryCode(filteredLead);
		service.assignLeadCountryWithCodeFromCountryCode(filteredLead);
	}

	private void stampProjectFromProjectCode(){
		LeadService service = LeadService.getInstance();
		List<Lead> filteredLead = new List<Lead>();
		for (Lead lead : this.newRecords){
			if (lead.LeadOrigin__c == 'Web-to-Lead'){
				filteredLead.add(lead);
			}
		}
		service.stampProjectFromProjectCode(filteredLead);
	}

	private void assignLeadToQueueAndRoundRobinFuture(){
		Set<Id> leadIds = new Set<Id>();
		for (Lead lead : this.newRecords){
			if (lead.LeadOrigin__c == 'Web-to-Lead' || lead.LeadOrigin__c == 'Upload'){
				leadIds.add(lead.Id);
			}
		}
		LeadService.assignLeadToQueueFuture(leadIds);
	}





}