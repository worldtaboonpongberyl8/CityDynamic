public with sharing class PaymentReceiptSelector {
	public static PaymentReceiptSelector instance;
	public static PaymentReceiptSelector getInstance() {
		if (instance == null) {
			instance = new PaymentReceiptSelector();
		}
		return instance;
	}

	public Map<Id, PaymentReceipt__c> getPaymentReceiptWithLineItemMapById(Set<Id> paymentReceiptIds) {
		return new Map<Id, PaymentReceipt__c>(
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
							LastIntegrationDateTime__c,
							CreatedDate
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
							ResponseCode__c,
							ResponseMessage__c,
							LastIntegrationDateTime__c
						FROM PaymentMethods__r
					)
				FROM PaymentReceipt__c
				WHERE Id IN :paymentReceiptIds

			]
		);
	}

	public Map<Id, PaymentReceipt__c> getOrderedPaymentReceiptByOppIdMapById(Id oppId){
		return new Map<Id, PaymentReceipt__c>(
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
							LastIntegrationDateTime__c,
							CreatedDate
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
							ResponseCode__c,
							ResponseMessage__c,
							LastIntegrationDateTime__c
						FROM PaymentMethods__r
					)
				FROM PaymentReceipt__c
				WHERE Opportunity__c =: oppId
				AND IsCancel__c = FALSE
				ORDER BY CreatedDate DESC
			]
		);
	}



	public List<PaymentReceipt__c> getByOppIdSet(Set<Id> oppIdSet) {
		return [
			SELECT Id, Opportunity__c
			FROM PaymentReceipt__c
			WHERE Opportunity__c IN: oppIdSet
		];
	}
}