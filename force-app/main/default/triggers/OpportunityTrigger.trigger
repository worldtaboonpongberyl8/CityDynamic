trigger OpportunityTrigger on Opportunity (before insert ,after insert , before update, after update) {
    OpportunityTriggerHandler handler = OpportunityTriggerHandler.getInstance();
    if (!handler.isTriggerActivated()) return;
    handler.setParams(Trigger.new, Trigger.oldMap);
    switch on Trigger.operationType {
        when AFTER_INSERT {
            handler.executeAfterInsert();
        }
        when AFTER_UPDATE{
            handler.executeAfterUpdate();
        }
        when BEFORE_INSERT{
            handler.executeBeforeInsert();
        }
        when BEFORE_UPDATE{
            handler.executeBeforeUpdate();
        }
    }
}