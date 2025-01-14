/**
 * Limitation
 * 1. Maximum to enqueueJob the Queueable from Trigger: 50
 * 2. No limit for depth of chained jobs (For Developer/Trial Edition => Max: 5)
 */
public without sharing class be8_QueueableService {
    @TestVisible private static be8_QueueableService instance;
    @TestVisible private List<be8_Queueable> queueables;
    
    public be8_QueueableService() {
        this.queueables = new List<be8_Queueable>();
    }

    public be8_QueueableService addToQueue(be8_Queueable queueable) {
        if(queueable == null) {
            return this;
        }
        this.queueables.add(queueable);
        return this;
    }

    public be8_QueueableService addToQueues(List<be8_Queueable> queueables) {
        this.queueables.addAll(queueables);
        return this;
    }

    // 🔥 Should call from the last execute such as end of trigger
    public Id executeQueue() {
        if(this.queueables.size() <= 0) {
            return null;
        }
        be8_Queueable firstQueueable = this.queueables.remove(0);   
        if(!this.queueables.isEmpty()) {
            firstQueueable.setNextQueueables(this.queueables);
        }

        if(!System.isQueueable()) {
            return System.enqueueJob(firstQueueable);   
        } else if(Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            if(!Test.isRunningTest()) { // In Test, cannot chanin (max depth=1)
                return System.enqueueJob(firstQueueable);
            }
        }

        return null;
    }

    // In some case, you don't want to use static getInstance, you can init instance by yourself => new be8_QueueableService();
    public static be8_QueueableService getInstance() {
        if(instance == null) {
            instance = new be8_QueueableService();
        }
        return instance;
    }
}