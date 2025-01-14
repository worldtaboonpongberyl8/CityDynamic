public with sharing class CreateRelatedInvFilesAndSendEmailBatch implements Database.Batchable<sObject> {
    private Date dueDate;

    public CreateRelatedInvFilesAndSendEmailBatch(Date invoiceDueDate) {
        dueDate = invoiceDueDate;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        List<String> queryStringList = new List<String> {
            'SELECT Id, Name, Opportunity__c, InvoiceDate__c, DueDate__c, DoNotSendInvoice__c, Opportunity__r.ContactPerson__r.Email, Opportunity__r.Account.Email__c',
			'FROM Invoice__c',
			'WHERE DueDate__c = ' + String.valueOf(dueDate)
        };

        String queryString = String.join(queryStringList, ' ');

        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext BC, List<Invoice__c> invoices) {
        InvoiceService.getInstance().insertInvoiceAndPaymentSummaryFiles(invoices);
        InvoiceService.getInstance().sendEmailWithAttachment(invoices);
    }

    public void finish(Database.BatchableContext BC) {
    }
}