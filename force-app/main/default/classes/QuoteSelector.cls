public with sharing class QuoteSelector {
    public QuoteSelector() {

    }
    public static QuoteSelector instance;
    public static QuoteSelector getInstance(){
        if(instance == null){
            instance = new QuoteSelector();
        }
        return instance;
    }
    public Map<Id,Quote__c> getQuoteById(Set<Id> quoteIds){
        Map<Id, Quote__c> quoteMap = new Map<Id, Quote__c>();
        List<Quote__c> quoteRecords = [SELECT Id, Name, Opportunity__c FROM Quote__c WHERE Id IN :quoteIds];
        for (Quote__c quote : quoteRecords) {
            quoteMap.put(quote.Id, quote);
        }
        return quoteMap;
    }
}