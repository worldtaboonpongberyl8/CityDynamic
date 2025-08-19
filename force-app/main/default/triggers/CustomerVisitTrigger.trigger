trigger CustomerVisitTrigger on CustomerVisit__c (after insert) {
	CustomerVisitTriggerHandler handler = CustomerVisitTriggerHandler.getInstance();
    if (!handler.isTriggerActivated()) return;
    handler.setParams(Trigger.new, Trigger.oldMap);
    switch on Trigger.operationType {
		when AFTER_INSERT{
			handler.executeAfterInsert();
		}
    }
}