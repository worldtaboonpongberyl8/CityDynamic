trigger CoBuyerTrigger on CoBuyer__c (after insert, after update, after delete) {
    CoBuyerTriggerHandler handler = CoBuyerTriggerHandler.getInstance();
    if (!handler.isTriggerActivated()) return;
    handler.setParams(Trigger.new, Trigger.oldMap);
    switch on Trigger.operationType {
        when AFTER_INSERT {
            handler.executeAfterInsert();
        }
        when AFTER_UPDATE{
            handler.executeAfterUpdate();
        }
        when AFTER_DELETE{
            handler.executeAfterDelete();
        }
    }
}