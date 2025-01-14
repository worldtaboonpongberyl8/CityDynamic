public with sharing class LeadSelector {
    public static LeadSelector instance;

    public LeadSelector() {
    }

    public static LeadSelector getInstance() {
        if (instance == null) {
            instance = new LeadSelector();
        }
        return instance;
    }

    // get Leads owned by Queue
    public List<Lead> getLeadsOwnedByQueues() {
        return [
            SELECT Id, OwnerId
            FROM Lead
            WHERE OwnerId IN (SELECT Id FROM Group WHERE Type = 'Queue')
        ];
    }

    // get Leads map by Queue
    public Map<Id, List<Lead>> getLeadsMapByQueueId(Set<Id> queueIds) {
        Map<Id, List<Lead>> leadsMapByQueueId = new Map<Id, List<Lead>>();
        List<Lead> leads = [
            SELECT Id, OwnerId
            FROM Lead
            WHERE OwnerId IN :queueIds
        ];
        for (Lead lead : leads) {
            if (!leadsMapByQueueId.containsKey(lead.OwnerId)) {
                leadsMapByQueueId.put(lead.OwnerId, new List<Lead>());
            }
            leadsMapByQueueId.get(lead.OwnerId).add(lead);
        }
        return leadsMapByQueueId;
    }

    public Map<Id, Lead> getLeadMapById(Set<Id> leadIds) {
        return new Map<Id, Lead>(
            [
                SELECT Id, OwnerId, LeadOrigin__c, LeadCountry__c, IsAutoAssingment__c
                FROM Lead
				WHERE Id IN: leadIds
            ]
        );
    }
}