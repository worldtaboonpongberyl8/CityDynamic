public with sharing class CoBuyerTriggerHandler {
    public CoBuyerTriggerHandler() {

    }
    public static CoBuyerTriggerHandler instance;
    public static CoBuyerTriggerHandler getInstance(){
        if (instance == null){
            instance = new CoBuyerTriggerHandler();
        }
        return instance;
    }

    public Boolean isActive = true;
    public List<CoBuyer__c> newRecords;
    public Map<Id, CoBuyer__c> oldMap;

    public Boolean isTriggerActivated() {
        if (TriggerActivation__mdt.getInstance('CoBuyerTrigger') != null) {
            return this.isActive && TriggerActivation__mdt.getInstance('CoBuyerTrigger').isActive__c;
        }
        return this.isActive;
    }
    public void setParams(List<CoBuyer__c> newRecords, Map<Id, CoBuyer__c> oldMap) {
        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }
    public void setBypass() {
        this.isActive = false;
    }

    public void clearBypass() {
        this.isActive = true;
    }

    public void executeAfterInsert() {
        this.stampOppCoBuyerNameAndFlag();
    }

    public void executeAfterUpdate() {
        this.stampOppCoBuyerNameAndFlag();
    }

    public void executeAfterDelete() {
        this.stampOppCoBuyerNameAndFlagAfterDelete();
    }

    private void stampOppCoBuyerNameAndFlag(){
        CoBuyerService service = CoBuyerService.getInstance();
        service.stampOppCoBuyerNameAndFlag(this.newRecords);
    }

    private void stampOppCoBuyerNameAndFlagAfterDelete(){
        CoBuyerService service = CoBuyerService.getInstance();
        List<CoBuyer__c> coBuyers = this.oldMap.values();
        service.stampOppCoBuyerNameAndFlag(coBuyers);
    }
}