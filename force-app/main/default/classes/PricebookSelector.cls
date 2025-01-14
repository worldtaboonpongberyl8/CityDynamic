public with sharing class PricebookSelector {
    public PricebookSelector() {

    }
    public static PricebookSelector instance;
    public static PricebookSelector getInstance(){
        if(instance == null){
            instance = new PricebookSelector();
        }
        return instance;
    }
    public Map<Id, Pricebook2> getPricebookByProductId(Set<Id> productIds){
        Map<Id, Pricebook2> productPricebookMap = new Map<Id, Pricebook2>();
        List<Pricebook2> pricebookEntries = [
            SELECT Id, Product2__c
            FROM Pricebook2
            WHERE Product2__c IN :productIds
        ];
        for (Pricebook2 entry : pricebookEntries) {
                productPricebookMap.put(entry.Product2__c, entry);
        }
        return productPricebookMap;
    }
}