public with sharing class CreateInvoiceApiCalloutBatch implements Database.Batchable<SObject>, Database.AllowsCallouts{
    public CreateInvoiceApiCalloutBatch() {

    }

	public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT
                Id,
                Opportunity__r.Account.AccountCode__c,
                Opportunity__r.Project__r.ProjectCode__c,
                CreatedDate,
                InvoiceNo__c,
                GLKey__c,
                ResponseCode__c,
                ResponseMessage__c,
                LastIntegrationDateTime__c,
                LastCreatedStatusInPojjaman__c,
                LastGLStatusInPojjaman__c,
				CoBuyerAccountCode__c,
                (
                    SELECT
                        Id,
                        Invoice__r.Opportunity__r.Unit__r.ProductCode,
                        OpportunityPayment__r.Remaining__c,
                        Term__c,
                        Amount__c,
                        Status__c,
                        DueDate__c,
                        ResponseCode__c,
                        ResponseMessage__c,
                        LastIntegrationDateTime__c
                    FROM InvoiceLineItems__r
                )
            FROM Invoice__c
            WHERE
                (LastModifiedDate = TODAY
                OR LastCreatedStatusInPojjaman__c = 'Fail'
				OR LastCreatedStatusInPojjaman__c = null)
			ORDER BY CreatedDate ASC
        ]);
    }

	public void execute(Database.BatchableContext bc, List<SObject> scope) {
		CreateInvoiceApiCallout callout = new CreateInvoiceApiCallout(scope);
        callout.execute();
    }

	public void finish(Database.BatchableContext bc) {
        System.debug('Batch processing finished.');
		// execute next batch
		CreateReceiptApiCalloutBatch createReceiptApiCalloutBatch = new CreateReceiptApiCalloutBatch();
        Database.executeBatch(createReceiptApiCalloutBatch, 25);
    }
}