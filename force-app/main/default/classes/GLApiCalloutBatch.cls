public with sharing class GLApiCalloutBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
	public GLApiCalloutBatch() {
	}
	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(
			[
				SELECT
					Id,
					LastGLStatusInPojjaman__c,
					TotalOperationFee__c,
					NetAgreedRefundAmount__c,
					NetAgreedForfeitAmount__c,
					(
						SELECT Id, LastGLStatusInPojjaman__c
						FROM Invoices__r
						WHERE (LastGLStatusInPojjaman__c = null OR
						LastGLStatusInPojjaman__c = 'Fail')
						ORDER BY CreatedDate ASC
					),
					(
						SELECT Id,
						IsCancel__c,
						CancelReason__c, LastGLStatusInPojjaman__c
						FROM PaymentReceipt__r
						WHERE
						(CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_CANCELREFUND OR
						CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_CANCELFORFEIT OR
						CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONREFUND OR
						CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONFORFEIT) AND
						(LastGLStatusInPojjaman__c = null OR
						LastGLStatusInPojjaman__c = 'Fail')
						ORDER BY CreatedDate ASC
					)
				FROM Opportunity
				WHERE StageName =: GlobalConstants.OPP_STAGENAME_CLOSED_LOST AND
				(LastGLStatusInPojjaman__c = 'Fail' OR LastGLStatusInPojjaman__c = null) AND
				(LossReason__c =: GlobalConstants.OPP_LOST_REASON_CANCELFORFEIT OR
				LossReason__c =: GlobalConstants.OPP_LOST_REASON_TERMINATIONFORFEIT OR
				LossReason__c =: GlobalConstants.OPP_LOST_REASON_CANCELREFUND OR
				LossReason__c =: GlobalConstants.OPP_LOST_REASON_TERMINATIONREFUND )
				ORDER BY LastModifiedDate ASC
			]
		);
	}

	public void execute(Database.BatchableContext bc, List<SObject> scope) {
		GLApiCallout callout = new GLApiCallout(scope);
		callout.execute();
	}

	public void finish(Database.BatchableContext bc) {
		// execute next batch
	}
}