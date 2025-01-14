trigger QuoteTrigger on Quote__c (after insert, after update) {
    QuoteTriggerHandler handler = QuoteTriggerHandler.getInstance();
    if (!handler.isTriggerActivated()) return;
    handler.setParams(Trigger.new, Trigger.oldMap);
    switch on Trigger.operationType {
        when AFTER_INSERT{
            handler.executeAfterInsert();
        }
        when AFTER_UPDATE {
            handler.executeAfterUpdate();
        }
    }
}