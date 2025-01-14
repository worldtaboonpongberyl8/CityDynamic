public with sharing class CreateInvoiceBatch implements Database.Batchable<sObject> {
    @TestVisible
    private Date invoiceDate;

    @TestVisible
    private Date dueDate;

    public CreateInvoiceBatch() {
        setDueDate(System.today());
		setInvoiceDate(System.today());
    }

    public CreateInvoiceBatch(Date runBatchDate) {
        setDueDate(runBatchDate);
		setInvoiceDate(runBatchDate);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        List<String> queryStringList = new List<String> {
            'SELECT Id, Opportunity__c, Term__c, DueDate__c, Amount__c, Remaining__c, PaymentStatus__c',
            'FROM OpportunityPayment__c',
            'WHERE Remaining__c > 0',
            '   AND IsMasterData__c = true' +
            '   AND DueDate__c = ' + String.valueOf(dueDate),
			'	AND Opportunity__r.StageName != \'Closed Lost\'',
            'ORDER BY Opportunity__c'
        };

        String queryString = String.join(queryStringList, ' ');

        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext BC, List<OpportunityPayment__c> oppPayments) {
        InvoiceService.getInstance().insertInvoiceAndRelatedRecords(oppPayments, dueDate, invoiceDate);
    }

    public void finish(Database.BatchableContext BC) {
		Database.executeBatch(new CreateRelatedInvFilesAndSendEmailBatch(dueDate), 50);
    }

    private void setDueDate(Date runBatchDate){
        dueDate = runBatchDate.addDays(Integer.valueOf(InvoiceSetting__c.getInstance().DueDate__c));
    }

    private void setInvoiceDate(Date runBatchDate){
        invoiceDate = runBatchDate;
    }
}