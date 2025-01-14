public with sharing class GLApiCalloutBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
	public GLApiCalloutBatch() {
	}
	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(
			[
				SELECT
					Id,
					LastGLStatusInPojjaman__c,
					(
						SELECT Id, LastGLStatusInPojjaman__c
						FROM Invoices__r
						ORDER BY CreatedDate ASC
					),
					(
						SELECT Id,
						IsCancel__c,
						CancelReason__c, LastGLStatusInPojjaman__c
						FROM PaymentReceipt__r
						WHERE
						CancelReason__c = 'Closed Lost'
						ORDER BY CreatedDate ASC
					)
				FROM Opportunity
				WHERE ((LastModifiedDate = TODAY AND StageName = 'Closed Lost') OR LastGLStatusInPojjaman__c = 'Fail')
				ORDER BY LastModifiedDate ASC
			]
		);
	}

	public void execute(Database.BatchableContext bc, List<SObject> scope) {
		GLApiCallout callout = new GLApiCallout(scope);
		callout.execute();
	}

	public void finish(Database.BatchableContext bc) {
		System.debug('Batch processing finished.');
		// execute next batch
	}
}