trigger AccountTrigger on Account (before update, after update) {
	AccountTriggerHandler handler = AccountTriggerHandler.getInstance();
    if (!handler.isTriggerActivated()) return;
    handler.setParams(Trigger.new, Trigger.oldMap);
    switch on Trigger.operationType {
        when AFTER_UPDATE {
            handler.executeAfterUpdate();
        }
		when BEFORE_UPDATE{
			handler.executeBeforeUpdate();
		}
    }
}