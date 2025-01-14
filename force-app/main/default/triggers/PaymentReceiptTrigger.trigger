trigger PaymentReceiptTrigger on PaymentReceipt__c (before update ,after update) {
    PaymentReceiptTriggerHandler handler = PaymentReceiptTriggerHandler.getInstance();
    if (!handler.isTriggerActivated()) return;
    handler.setParams(Trigger.new, Trigger.oldMap);
    switch on Trigger.operationType {
		when BEFORE_UPDATE{
			handler.executeBeforeUpdate();
		}
        when AFTER_UPDATE {
            handler.executeAfterUpdate();
        }
    }
}