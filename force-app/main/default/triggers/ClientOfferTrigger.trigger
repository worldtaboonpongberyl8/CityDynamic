trigger ClientOfferTrigger on ClientOffer__c (before insert) {
    ClientOfferTriggerHandler handler = ClientOfferTriggerHandler.getInstance();
    if (!handler.isTriggerActivated()) return;
    handler.setParams(Trigger.new, Trigger.oldMap);
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.executeBeforeInsert();
        }
    }
}