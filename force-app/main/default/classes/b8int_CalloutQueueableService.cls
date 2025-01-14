public without sharing class b8int_CalloutQueueableService {
    private static b8int_CalloutQueueableService instance;
    public List<b8int_BaseHttpCallout> calloutQueues; 
    private static Boolean blockForRunningTest = false;

    public b8int_CalloutQueueableService() {
        this.calloutQueues = new List<b8int_BaseHttpCallout>();
    }

    public b8int_CalloutQueueableService addToQueue(b8int_BaseHttpCallout callout) {
        if(callout == null) {
            return this;
        }
        this.calloutQueues.add(callout);
        return this;
    }

    public b8int_CalloutQueueableService addToQueues(List<b8int_BaseHttpCallout> callouts) {
        this.calloutQueues.addAll(callouts);
        return this;
    }

    public Id executeQueue() {
        if(Test.isRunningTest()) {
            if(b8int_CalloutQueueableService.blockForRunningTest) {
                return null;
            } else {
                b8int_CalloutQueueableService.blockForRunningTest = true;
            }
        }

        if(this.calloutQueues.size() <= 0) {
            return null;
        }
        b8int_BaseHttpCallout firstQueueable = this.calloutQueues.get(0);
        this.calloutQueues.remove(0);
        if(!this.calloutQueues.isEmpty()) {
            firstQueueable.setNextQueueables(this.calloutQueues);
        }
        firstQueueable.setCalloutType(b8int_BaseHttpCallout.HttpCalloutType.QUEUE);
        return firstQueueable.Execute();
    }

    public Id executeQueue(List<b8int_BaseHttpCallout> calloutQueues) {
        this.calloutQueues = calloutQueues;
        return executeQueue();
    }

    public static b8int_CalloutQueueableService getInstance() {
        if(instance == null) {
            instance = new b8int_CalloutQueueableService();
        }
        return instance;
    }
}