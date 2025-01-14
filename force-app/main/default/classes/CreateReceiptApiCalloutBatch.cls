public with sharing class CreateReceiptApiCalloutBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
	public CreateReceiptApiCalloutBatch() {
	}
	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(
			[
				SELECT
					Id,
					AccountAddress__c,
					CreatedDate,
					DueDate__c,
					IsCancel__c,
					CancelReason__c,
					LastIntegrationDateTime__c,
					LastCreatedStatusInPojjaman__c,
					LastCancelledStatusInPojjaman__c,
					Opportunity__c,
					ReceiptNo__c,
					ResponseCode__c,
					ResponseMessage__c,
					TotalReceiveAmount__c,
					GLKey__c,
					GLDate__c,
					Opportunity__r.Account.AccountCode__c,
					Opportunity__r.Project__r.ProjectCode__c,
					(
						SELECT
							Id,
							InvoiceLineItem__c,
							InvoiceLineItem__r.Invoice__c,
							ReceivedAmount__c,
							RemainingAmount__c,
							Status__c,
							PreviousRemaining__c,
							OpportunityPayment__c,
							OpportunityPayment__r.Term__c,
							OpportunityPayment__r.DueDate__c,
							OpportunityPayment__r.Remaining__c,
							OpportunityPayment__r.ReceivedAmount__c,
							OpportunityPayment__r.PaymentStatus__c,
							OpportunityPayment__r.Order__c,
							TransactionDateTime__c,
							PaymentReceipt__r.TotalReceiveAmount__c,
							PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode,
							ResponseCode__c,
							ResponseMessage__c,
							LastIntegrationDateTime__c
						FROM Payment_Transactions__r
						ORDER BY OpportunityPayment__r.Order__c, Name
					),
					(
						SELECT
							Id,
							PaymentType__c,
							CreditCardNo__c,
							DebitCardNo__c,
							ChequeNo__c,
							BankBranch__c,
							BankName__c,
							BankAccountNo__c,
							CompanyBank__r.BankAccountNumber__c,
							PaymentDate__c,
							ReceivedAmount__c,
							InternationalBankName__c,
							ResponseCode__c,
							ResponseMessage__c,
							LastIntegrationDateTime__c
						FROM PaymentMethods__r
					)
				FROM PaymentReceipt__c
				WHERE (LastModifiedDate = TODAY
				OR LastCreatedStatusInPojjaman__c = null
				OR LastCreatedStatusInPojjaman__c = 'Fail'
				OR LastCancelledStatusInPojjaman__c = 'Fail')
				ORDER BY CreatedDate ASC
			]
		);
	}

	public void execute(Database.BatchableContext bc, List<SObject> scope) {
		CreateReceiptApiCallout callout = new CreateReceiptApiCallout(scope);
		callout.execute();
	}

	public void finish(Database.BatchableContext bc) {
		System.debug('Batch processing finished.');
		// execute next batch
		GLApiCalloutBatch glApiCalloutBatch = new GLApiCalloutBatch();
        Database.executeBatch(glApiCalloutBatch, 25);
	}
}