public with sharing class ContentDocumentLinkTriggerHandler {
    public static ContentDocumentLinkTriggerHandler instance;
    public ContentDocumentLinkTriggerHandler() {

    }
    public static ContentDocumentLinkTriggerHandler getInstance(){
        if (instance == null) {
            instance = new ContentDocumentLinkTriggerHandler();
        }
        return instance;
    }

    public Boolean isActive = true;
    public List<ContentDocumentLink> newRecords;
    public Map<Id,ContentDocumentLink> oldMap;

    public Boolean isTriggerActivated(){
        if (TriggerActivation__mdt.getInstance('ContentDocumentLinkTrigger') != null){
            return this.isActive && TriggerActivation__mdt.getInstance('ContentDocumentLinkTrigger').isActive__c;
        }
        return this.isActive;
    }

    public void setBypass(){
        this.isActive = false;
    }

    public void clearBypass(){
        this.isActive = true;
    }

    public void setParams(List<ContentDocumentLink> newRecords, Map<Id,ContentDocumentLink> oldMap){
        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }

    /**
	* Phase: 1
    * UAT Issue: filtered content document link which attached to Product2 only
    */
    public void executeAfterInsert(){
        ContentDocumentService service = ContentDocumentService.getInstance();
        List<ContentDocumentLink> recordToRenames = new List<ContentDocumentLink>();
        for(ContentDocumentLink contentDocLink : newRecords){
            Schema.SObjectType objectType = contentDocLink.LinkedEntityId.getSObjectType();
            if(String.valueOf(objectType) == 'Product2'){
                recordToRenames.add(contentDocLink);
            }
        }
        if(!recordToRenames.isEmpty()){
            service.renameContentDocumentTitle(recordToRenames);
        }
    }


}