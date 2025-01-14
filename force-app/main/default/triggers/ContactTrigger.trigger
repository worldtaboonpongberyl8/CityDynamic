trigger ContactTrigger on Contact (after insert, before update , after update) {
    ContactTriggerHandler handler = ContactTriggerHandler.getInstance();
    if (!handler.isTriggerActivated()) return;
    handler.setParams(Trigger.new, Trigger.oldMap);
    switch on Trigger.operationType {
		when AFTER_INSERT{
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