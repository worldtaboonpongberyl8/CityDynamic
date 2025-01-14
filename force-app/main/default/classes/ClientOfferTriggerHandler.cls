public with sharing class ClientOfferTriggerHandler {
    public static ClientOfferTriggerHandler instance;
    public ClientOfferTriggerHandler() {

    }
    public static ClientOfferTriggerHandler getInstance(){
        if (instance == null) {
            instance = new ClientOfferTriggerHandler();
        }
        return instance;
    }

    public Boolean isActive = true;
    public List<ClientOffer__c> newRecords;
    public Map<Id,ClientOffer__c> oldMap;

    public Boolean isTriggerActivated(){
        if (TriggerActivation__mdt.getInstance('ClientOfferTrigger') != null){
            return this.isActive && TriggerActivation__mdt.getInstance('ClientOfferTrigger').isActive__c;
        }
        return this.isActive;
    }

    public void setBypass(){
        this.isActive = false;
    }

    public void clearBypass(){
        this.isActive = true;
    }

    public void setParams(List<ClientOffer__c> newRecords, Map<Id,ClientOffer__c> oldMap){
        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }

    public void executeBeforeInsert(){
        this.stampOriginalCostFromPromotionMaster();
    }

    private void stampOriginalCostFromPromotionMaster(){
        ClientOfferService service = ClientOfferService.getInstance();
        service.stampOriginalCostFromPromotionMasters(this.newRecords);
    }
}