public with sharing class OpportunityPaymentSelector {
	public static OpportunityPaymentSelector instance;
	public OpportunityPaymentSelector() {
	}

	public static OpportunityPaymentSelector getInstance() {
		if (instance == null) {
			instance = new OpportunityPaymentSelector();
		}
		return instance;
	}

	public Map<Id, OpportunityPayment__c> getOpportunityPaymentMapById(Set<Id> oppPaymentIds) {
		return new Map<Id, OpportunityPayment__c>(
			[
				SELECT
					Opportunity__c,
					Amount__c,
					DueDate__c,
					Order__c,
					ReceivedAmount__c,
					ReceivedDate__c,
					Term__c,
					Opportunity__r.PaymentTermMaster__c,
					Remaining__c,
					PaymentStatus__c
				FROM OpportunityPayment__c
				WHERE Id IN :oppPaymentIds
				ORDER BY Order__c
			]
		);
	}

	public Map<Id, OpportunityPayment__c> getOpportunityPaymentWithInvoiceLineItemMapById(Set<Id> oppPaymentIds) {
		return new Map<Id, OpportunityPayment__c>(
			[
				SELECT
					Opportunity__c,
					Amount__c,
					DueDate__c,
					Order__c,
					ReceivedAmount__c,
					ReceivedDate__c,
					Term__c,
					Opportunity__r.PaymentTermMaster__c,
					Remaining__c,
					PaymentStatus__c,
					(
						SELECT Id, Invoice__c, Status__c, PaymentReceiptLineItem__c
						FROM InvoiceLineItems__r
						ORDER BY CreatedDate DESC
					)
				FROM OpportunityPayment__c
				WHERE Id IN :oppPaymentIds
				ORDER BY Order__c
			]
		);
	}

	public Map<Id, OpportunityPayment__c> getOpportunityPaymentWithReceiptLineItemMapById(set<Id> oppPaymentIds) {
		return new Map<Id, OpportunityPayment__c>(
			[
				SELECT
					Opportunity__c,
					Amount__c,
					DueDate__c,
					Order__c,
					ReceivedAmount__c,
					ReceivedDate__c,
					Term__c,
					Opportunity__r.PaymentTermMaster__c,
					Remaining__c,
					PaymentStatus__c,
					(
						SELECT
							Id,
							InvoiceLineItem__c,
							InvoiceLineItem__r.Invoice__c,
							ReceivedAmount__c,
							RemainingAmount__c,
							Status__c,
							TransactionDateTime__c
						FROM Payment_Receipt_Line_Item__r
					)
				FROM OpportunityPayment__c
				WHERE Id IN :oppPaymentIds
				ORDER BY Order__c
			]
		);
	}

	public Map<Id, List<OpportunityPayment__c>> getOpportunityPaymentsMapByOppId(Set<Id> oppIds) {
		Map<Id, List<OpportunityPayment__c>> opportunityPaymentsMapByOppId = new Map<Id, List<OpportunityPayment__c>>();
		List<OpportunityPayment__c> opportunityPayments = [
			SELECT
				Id,
				Opportunity__c,
				Amount__c,
				DueDate__c,
				Order__c,
				ReceivedAmount__c,
				ReceivedDate__c,
				Term__c,
				Opportunity__r.PaymentTermMaster__c,
				Remaining__c,
				PaymentStatus__c
			FROM OpportunityPayment__c
			WHERE Opportunity__c IN :oppIds AND IsMasterData__c = true
			ORDER BY Order__c
		];
		for (OpportunityPayment__c opportunityPayment : opportunityPayments) {
			if (!opportunityPaymentsMapByOppId.containsKey(opportunityPayment.Opportunity__c)) {
				opportunityPaymentsMapByOppId.put(opportunityPayment.Opportunity__c, new List<OpportunityPayment__c>());
			}
			opportunityPaymentsMapByOppId.get(opportunityPayment.Opportunity__c).add(opportunityPayment);
		}
		return opportunityPaymentsMapByOppId;
	}

	public Map<Id, List<OpportunityPayment__c>> getOpportunityPaymentsWithInvoiceLineItemMapByOppId(Set<Id> oppIds) {
		Map<Id, List<OpportunityPayment__c>> opportunityPaymentsMapByOppId = new Map<Id, List<OpportunityPayment__c>>();
		List<OpportunityPayment__c> opportunityPayments = [
			SELECT
				Id,
				Opportunity__c,
				Amount__c,
				DueDate__c,
				Order__c,
				ReceivedAmount__c,
				ReceivedDate__c,
				Term__c,
				Opportunity__r.PaymentTermMaster__c,
				Remaining__c,
				PaymentStatus__c,
				(SELECT Id, Invoice__c, Status__c, PaymentReceiptLineItem__c FROM InvoiceLineItems__r)
			FROM OpportunityPayment__c
			WHERE Opportunity__c IN :oppIds AND IsMasterData__c = true
			ORDER BY Order__c
		];
		for (OpportunityPayment__c opportunityPayment : opportunityPayments) {
			if (!opportunityPaymentsMapByOppId.containsKey(opportunityPayment.Opportunity__c)) {
				opportunityPaymentsMapByOppId.put(opportunityPayment.Opportunity__c, new List<OpportunityPayment__c>());
			}
			opportunityPaymentsMapByOppId.get(opportunityPayment.Opportunity__c).add(opportunityPayment);
		}
		return opportunityPaymentsMapByOppId;
	}

	public List<OpportunityPayment__c> getForPaymentSummaryForm(Id oppId) {
		return [
			SELECT
				Id,
				Opportunity__c,
				Order__c,
				Term__c,
				DueDate__c,
				Amount__c,
				ReceivedDate__c,
				ReceivedAmount__c,
				Remaining__c,
				PaymentStatus__c
			FROM OpportunityPayment__c
			WHERE Opportunity__c = :oppId
				AND IsMasterData__c = true
				AND Opportunity__r.StageName != 'Closed Lost'
			ORDER BY Order__c
		];
	}

	public List<OpportunityPayment__c> getForInvoiceForm(Id oppId, Date dueDate) {
		return [
			SELECT Id, Opportunity__c, Term__c, DueDate__c, Amount__c, Remaining__c, PaymentStatus__c
			FROM OpportunityPayment__c
			WHERE Opportunity__c = :oppId
				AND Remaining__c > 0
				AND DueDate__c <= :dueDate
				AND IsMasterData__c = true
				AND Opportunity__r.StageName != 'Closed Lost'
				ORDER BY DueDate__c
		];
	}
}