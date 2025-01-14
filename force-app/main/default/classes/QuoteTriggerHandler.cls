public with sharing class QuoteTriggerHandler {
    public QuoteTriggerHandler() {

    }
    public static QuoteTriggerHandler instance;
    public static QuoteTriggerHandler getInstance(){
        if (instance == null){
            instance = new QuoteTriggerHandler();
        }
        return instance;
    }

    public Boolean isActive = true;
    public List<Quote__c> newRecords;
    public Map<Id, Quote__c> oldMap;

    public Boolean isTriggerActivated() {
        if (TriggerActivation__mdt.getInstance('QuoteTrigger') != null) {
            return this.isActive && TriggerActivation__mdt.getInstance('QuoteTrigger').isActive__c;
        }
        return this.isActive;
    }
    public void setParams(List<Quote__c> newRecords, Map<Id, Quote__c> oldMap) {
        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }
    public void setBypass() {
        this.isActive = false;
    }

    public void clearBypass() {
        this.isActive = true;
    }

    public void executeAfterInsert(){
        this.cloneOpportunityPaymentFromOpportunity();
    }

    public void executeAfterUpdate() {
        this.stampDiscountToOppAfterSyncQuote();
        this.unsetPreviousSyncedQuote();
    }

    private void stampDiscountToOppAfterSyncQuote(){
        QuoteService service = QuoteService.getInstance();
        List<Quote__c> filteredQuotes = new List<Quote__c>();
        for (Quote__c quote : this.newRecords){
            Quote__c oldQuote = this.oldMap.get(quote.Id);
            if (oldQuote.IsSyncing__c != quote.IsSyncing__c && quote.IsSyncing__c == true){
                filteredQuotes.add(quote);
            }
        }
        if (!filteredQuotes.isEmpty()){
            List<Opportunity> updatedUpportunities = service.stampDiscountFromSyncedQuoteToOpportunity(filteredQuotes);
            update updatedUpportunities;
        }
    }

    private void unsetPreviousSyncedQuote(){
        QuoteService service = QuoteService.getInstance();
        List<Quote__c> filteredQuotes = new List<Quote__c>();
        for (Quote__c quote : this.newRecords){
            Quote__c oldQuote = this.oldMap.get(quote.Id);
            if (oldQuote.IsSyncing__c != quote.IsSyncing__c && quote.IsSyncing__c == true){
                filteredQuotes.add(quote);
            }
        }
        if (!filteredQuotes.isEmpty()){
            List<Quote__c> unsyncedQuote = service.unsetSyncedQuoteFromOthers(filteredQuotes);
            if (!unsyncedQuote.isEmpty()){
                update unsyncedQuote;
            }
        }
    }

    private void cloneOpportunityPaymentFromOpportunity(){
        OpportunityPaymentService oppPaymentService = OpportunityPaymentService.getInstance();
        List<OpportunityPayment__c> oppPayments = oppPaymentService.getClonedOpportunityPaymentByQuote(this.newRecords);
        if (!oppPayments.isEmpty()){
            insert oppPayments;
        }
    }

    
}