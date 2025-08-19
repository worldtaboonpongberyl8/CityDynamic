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
	/**
	 * Phase2
	 * Details:
	 * - Select more fields
	 * 		- PricingPeriod__c
	 */
    public Map<Id, PricebookEntry> getPricebookEntiesByProductId(Set<Id> productIds){
        Map<Id, PricebookEntry> productPricebookEntiesMap = new Map<Id, PricebookEntry>();
        List<PricebookEntry> pricebookEntries = [
            SELECT Id, Product2Id, UnitPrice,UnitPriceSqm__c,TQUnitPrice__c,FQUnitPrice__c,TQUnitPricesqm__c,FQUnitPricesqm__c
			,PricingPeriod__c
            FROM PricebookEntry
            WHERE Product2Id IN :productIds AND IsActive = TRUE
        ];
        for (PricebookEntry entry : pricebookEntries) {
            productPricebookEntiesMap.put(entry.Product2Id, entry);
        }
        return productPricebookEntiesMap;
    }
}