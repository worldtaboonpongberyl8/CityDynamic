trigger CoBuyerTrigger on CoBuyer__c (before insert, after insert, before update, after update, after delete) {
    CoBuyerTriggerHandler handler = CoBuyerTriggerHandler.getInstance();
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
        when AFTER_UPDATE{
            handler.executeAfterUpdate();
        }
    }
}