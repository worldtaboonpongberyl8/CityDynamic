public with sharing class GLChangeUnitApiCalloutBatch implements Database.Batchable<SObject>, Database.AllowsCallouts{

    public GLChangeUnitApiCalloutBatch() {

    }

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(
			[
				SELECT
					Id,
					LastGLStatusInPojjaman__c,
					LastIntegrationDateTime__c,
					(
						SELECT Id, LastGLStatusInPojjaman__c
						FROM Invoices__r
						WHERE ResponseCode__c != 'CSC'
						ORDER BY CreatedDate ASC
					),
					(
						SELECT 	Id,
								IsCancel__c,
								CancelReason__c,
								LastGLStatusInPojjaman__c
						FROM PaymentReceipt__r
						WHERE
							(CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_UPGRADE OR
							CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_DOWNGRADE OR
							CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_MOVEPAYMENT) AND
							ResponseCode__c != 'CSC'
						ORDER BY CreatedDate ASC
					)
				FROM Opportunity
				WHERE (
						StageName =: GlobalConstants.OPP_STAGENAME_CLOSED_LOST AND
						(LossReason__c =: GlobalConstants.OPP_LOST_REASON_UPGRADE OR
						LossReason__c =: GlobalConstants.OPP_LOST_REASON_DOWNGRADE OR
						LossReason__c =: GlobalConstants.OPP_LOST_REASON_PURCHASEOTHERNAME OR
						LossReason__c =: GlobalConstants.OPP_LOST_REASON_MOVEPAYMENT ) AND
						(LastGLStatusInPojjaman__c = null OR LastGLStatusInPojjaman__c = 'Fail')
					)
				ORDER BY LastModifiedDate ASC
			]
		);
	}

	public void execute(Database.BatchableContext bc, List<SObject> scope) {
		GLChangeUnitApiCallout callout = new GLChangeUnitApiCallout(scope);
		callout.execute();
	}

	public void finish(Database.BatchableContext bc) {
		// execute next batch
		CreateInvoiceApiCalloutBatch createInvoiceApiCalloutBatch = new CreateInvoiceApiCalloutBatch();
        Database.executeBatch(createInvoiceApiCalloutBatch, 25);
	}
}