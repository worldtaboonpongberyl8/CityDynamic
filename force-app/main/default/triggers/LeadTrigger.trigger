trigger LeadTrigger on Lead (before insert, after insert) {
    LeadTriggerHandler handler = LeadTriggerHandler.getInstance();
    if (!handler.isTriggerActivated()) return;
    handler.setParams(Trigger.new, Trigger.oldMap);
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.executeBeforeInsert();
        }
		when AFTER_INSERT{
			handler.executeAfterInsert();
		}
    }
}