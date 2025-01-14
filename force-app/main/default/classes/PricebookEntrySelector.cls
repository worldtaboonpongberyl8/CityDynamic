public with sharing class PricebookEntrySelector {
    public PricebookEntrySelector() {

    }
    public static PricebookEntrySelector instance;
    public static PricebookEntrySelector getInstance(){
        if(instance == null){
            instance = new PricebookEntrySelector();
        }
        return instance;
    }
    public Map<Id, PricebookEntry> getPricebookEntiesByProductId(Set<Id> productIds){
        Map<Id, PricebookEntry> productPricebookEntiesMap = new Map<Id, PricebookEntry>();
        List<PricebookEntry> pricebookEntries = [
            SELECT Id, Product2Id, TQUnitPrice__c,FQUnitPrice__c,TQUnitPricesqm__c,FQUnitPricesqm__c
            FROM PricebookEntry
            WHERE Product2Id IN :productIds
        ];
        for (PricebookEntry entry : pricebookEntries) {
            productPricebookEntiesMap.put(entry.Product2Id, entry);
        }
        return productPricebookEntiesMap;
    }
}