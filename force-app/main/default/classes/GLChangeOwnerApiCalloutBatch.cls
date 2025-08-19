public with sharing class GLChangeOwnerApiCalloutBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public GLChangeOwnerApiCalloutBatch() {
    }

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(
			[
				SELECT
					Id,
					CurrentAccount__r.AccountCode__c,
					PreviousAccount__r.AccountCode__c,
					LastGLStatusInPojjaman__c,
					LastIntegrationDateTime__c,
					ResponseMessage__c,
					(
						SELECT
							Id,
							IsCancel__c,
							CancelReason__c,
							LastGLStatusInPojjaman__c
						FROM PaymentReceipts__r
						ORDER BY CreatedDate ASC
					)
				FROM OpportunityAccountChangeLog__c
				WHERE (LastGLStatusInPojjaman__c = null OR LastGLStatusInPojjaman__c = 'Fail')
				ORDER BY LastModifiedDate ASC
			]
		);
	}

	public void execute(Database.BatchableContext bc, List<SObject> scope) {
		GLChangeOwnerApiCallout callout = new GLChangeOwnerApiCallout(scope);
		callout.execute();
	}

	public void finish(Database.BatchableContext bc) {
		// execute next batch
		GLChangeUnitApiCalloutBatch glChangeUnitApiCalloutBatch = new GLChangeUnitApiCalloutBatch();
        Database.executeBatch(glChangeUnitApiCalloutBatch, 25);
	}
}