public abstract without sharing class be8_Queueable implements Queueable, Database.AllowsCallouts {
    @TestVisible protected List<be8_Queueable> nextQueueables = new List<be8_Queueable>();

    public abstract void execute(QueueableContext context);

    // 🔥 Only allow to called from be8_QueueableService
    public void setNextQueueables(List<be8_Queueable> nextQueueables) {
        this.nextQueueables = nextQueueables;
    }

    @TestVisible protected Boolean hasNextQueuables() {
        return !this.nextQueueables.isEmpty();
    }

    @TestVisible
    protected virtual Id executeNextQueueables() {
        if(this.nextQueueables.size() > 0) {
            be8_QueueableService queueableService = be8_QueueableService.getInstance();
            queueableService.addToQueues(this.nextQueueables);
            return queueableService.executeQueue();
        }
        return null;
    }
}