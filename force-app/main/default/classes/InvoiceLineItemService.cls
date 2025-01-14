public with sharing class InvoiceLineItemService {
	public static InvoiceLineItemService instance;

	public static InvoiceLineItemService getInstance() {
		if (instance == null) {
			instance = new InvoiceLineItemService();
		}
		return instance;
	}

	public List<InvoiceLineItem__c> getNewInvoiceLineItems(
		Map<Id, Invoice__c> invoiceMapByOppId,
		Map<Id, List<OpportunityPayment__c>> oppPaymentsMapByOppId
	) {
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>();
		for (Invoice__c invoice : invoiceMapByOppId.values()) {
			if (invoice.Id == null) {
				continue;
			}

			List<OpportunityPayment__c> oppPayments = oppPaymentsMapByOppId.get(invoice.Opportunity__c);
			for (Integer i = 0; i < oppPayments.size(); i++) {
				OpportunityPayment__c oppPayment = oppPayments.get(i);
				invoiceLineItems.add(
					new InvoiceLineItem__c(
						LineNumber__c = (i+1),
						Invoice__c = invoice.Id,
						OpportunityPayment__c = oppPayment.Id,
						DueDate__c = oppPayment.DueDate__c,
						Amount__c = oppPayment.Remaining__c
					)
				);
			}
		}
		return invoiceLineItems;
	}

	public Database.SaveResult[] insertInvoiceLineItems(List<InvoiceLineItem__c> invoiceLineItems) {
		Database.SaveResult[] insertResults;

		if (!invoiceLineItems.isEmpty()) {
			insertResults = Database.insert(invoiceLineItems, false);
		}

		return insertResults;
	}
}