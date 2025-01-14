public with sharing class RoundRobinAssignmentSelector {
    public static RoundRobinAssignmentSelector instance;

    public RoundRobinAssignmentSelector() {
    }

    public static RoundRobinAssignmentSelector getInstance() {
        if (instance == null) {
            instance = new RoundRobinAssignmentSelector();
        }
        return instance;
    }

    // get Round Robin Assignment for Lead object map by Queue name
    public Map<String, RoundRobinAssignment__c> getLeadRoundRobinAssignmentMapByQueueName(Set<String> queueNames) {
        Map<String, RoundRobinAssignment__c> rrAssignmentMapByQueueName = new Map<String, RoundRobinAssignment__c>();
        List<RoundRobinAssignment__c> rrAssignments = [
            SELECT Id, QueueName__c, LastAssignedUser__c, TargetObject__c
            FROM RoundRobinAssignment__c
            WHERE QueueName__c IN :queueNames AND TargetObject__c = 'Lead'
        ];
        for (RoundRobinAssignment__c rrAssignment : rrAssignments) {
            rrAssignmentMapByQueueName.put(rrAssignment.QueueName__c, rrAssignment);
        }
        return rrAssignmentMapByQueueName;
    }
}