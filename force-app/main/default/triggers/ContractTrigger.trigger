trigger ContractTrigger on Contract (before insert ,before update, after insert, after update) {
    ContractTriggerHandler handler = ContractTriggerHandler.getInstance();
    if (!handler.isTriggerActivated()) return;
    handler.setParams(Trigger.new, Trigger.oldMap);
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.executeBeforeInsert();
        }
        when AFTER_INSERT {
            handler.executeAfterInsert();
        }
        when BEFORE_UPDATE{
            handler.executeBeforeUpdate();
        }
        when AFTER_UPDATE {
            handler.executeAfterUpdate();
        }
    }
}