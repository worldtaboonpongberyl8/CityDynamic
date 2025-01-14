public with sharing class PaymentReceiptService {
	public static PaymentReceiptService instance;
	public static PaymentReceiptService getInstance() {
		if (instance == null) {
			instance = new PaymentReceiptService();
		}
		return instance;
	}

	public PaymentReceipt__c generatePaymentReceiptRelatedToOpportunity(Id opportunityId) {
		OpportunitySelector selector = OpportunitySelector.getInstance();
		Opportunity targetOpp = selector.getById(opportunityId);
		PaymentReceipt__c paymentReceipt = new PaymentReceipt__c();
		paymentReceipt.Opportunity__c = opportunityId;
		paymentReceipt.AccountAddress__c = targetOpp.Account.AddressEN__c;
		return paymentReceipt;
	}

	public PaymentReceipt__c generateRunningNo(PaymentReceipt__c paymentReceipt){
		String formatNo = this.getFomatName(paymentReceipt.Id);
		paymentReceipt.ReceiptNo__c = formatNo;
		return paymentReceipt;
	}

	public List<PaymentReceiptLineItem__c> generatePaymentReceiptLineItemFromTotalReceivedAmount(
		Decimal totalRecievedAmount,
		List<OpportunityPayment__c> opportunityPayments,
		Id paymentReceiptId,
		Id paymentMethodId
	) {
		List<PaymentReceiptLineItem__c> receiptLineItems = new List<PaymentReceiptLineItem__c>();
		OpportunityPaymentSelector oppPaymentSelector = OpportunityPaymentSelector.getInstance();
		Decimal remainingPayment = totalRecievedAmount;
		// Date today = Date.today();
		// Set<Id> oppPaymentIds = new Set<Id>();
		// for (OpportunityPayment__c payment : opportunityPayments) {
		//     oppPaymentIds.add(payment.Id);
		// }
		// Map<Id, OpportunityPayment__c> oppPaymentWithInvoiceLineItemMapById = oppPaymentSelector.getOpportunityPaymentWithInvoiceLineItemMapById(
		//     oppPaymentIds
		// );
		Integer lineNumber = 1;
		for (OpportunityPayment__c payment : opportunityPayments) {
			if (remainingPayment <= 0) {
				break;
			}
			Decimal remainingBalance = payment.Remaining__c;
			if (remainingBalance > 0) {
				Decimal allocatedAmount = Math.min(remainingBalance, remainingPayment);
				System.debug('--Test-- allocatedAmount: ' + allocatedAmount);
				PaymentReceiptLineItem__c receiptLineItem = new PaymentReceiptLineItem__c();
				receiptLineItem.LineNumber__c = lineNumber;
				lineNumber ++;
				receiptLineItem.ReceivedAmount__c = allocatedAmount;
				// receiptLineItem.Term__c = payment.Term__c;
				// receiptLineItem.ReceiveDate__c = today;
				receiptLineItem.PreviousRemaining__c = remainingBalance;
				receiptLineItem.PaymentReceipt__c = paymentReceiptId;
				receiptLineItem.Status__c = allocatedAmount == payment.Remaining__c ? 'Fully Paid' : 'Partially Paid';
				receiptLineItem.OpportunityPayment__c = payment.Id;
				receiptLineItem.PaymentMethod__c = paymentMethodId;
				remainingPayment -= allocatedAmount;
				receiptLineItem.RemainingAmount__c = payment.Remaining__c - allocatedAmount;
				System.debug('--Test-- remainingPayment: ' + remainingPayment);
				// OpportunityPayment__c targetOppPayment = oppPaymentWithInvoiceLineItemMapById.get(payment.Id);
				List<InvoiceLineItem__c> invoiceLineItems = payment.InvoiceLineItems__r != null
					? payment.InvoiceLineItems__r
					: new List<InvoiceLineItem__c>();
				if (!invoiceLineItems.isEmpty()){
					System.debug('--Test-- invoiceLineItems' + invoiceLineItems);
					System.debug('--Test-- invoiceLineItem' + invoiceLineItems[0]);
					InvoiceLineItem__c targetInvoiceLineItem = invoiceLineItems[0];
					receiptLineItem.InvoiceLineItem__c = targetInvoiceLineItem.Id;
				}
				receiptLineItems.add(receiptLineItem);
			}
		}
		if (remainingPayment > 0){
			// to do next phase
		}
		return receiptLineItems;
	}

	private String getFomatName(Id paymentReceiptId){
		List<NameFormattingMasterData__c> nameFormattingMasterDatas = NameFormattingMasterDataSelector.getInstance().getByObjTypePurposeDocTemplate(
			'PaymentReceipt__c', 'Format', 'Object', null
		);
		return RunningNumberUtility.getInstance().generateReplacedFormatName(
			nameFormattingMasterDatas.get(0),
			paymentReceiptId,
			'PaymentReceipt__c'
		);
	}

	public List<PaymentReceiptLineItem__c> aggregatePaymentReceiptLineItems(List<PaymentReceiptLineItem__c> paymentReceiptLineItems) {
		//paymentReceiptLineItems.sort();
		List<PaymentReceiptLineItem__c> updatedPaymentReceiptLineItems = new List<PaymentReceiptLineItem__c>();
		Set<String> processedTerms = new Set<String>();
		Map<String, PaymentReceiptLineItem__c> termToLineItemMap = new Map<String, PaymentReceiptLineItem__c>();
		System.debug('Item: '+paymentReceiptLineItems);
		for (PaymentReceiptLineItem__c paymentReceiptLineItem : paymentReceiptLineItems) {
			String currentTerm = paymentReceiptLineItem.OpportunityPayment__r.Term__c;
			if (!termToLineItemMap.containsKey(currentTerm)) {
				PaymentReceiptLineItem__c newLineItem = paymentReceiptLineItem.clone(false);
				System.debug('Clone: '+newLineItem);
				System.debug('Payment Receipt : '+paymentReceiptLineItem.ReceivedAmount__c);
				newLineItem.ReceivedAmount__c = paymentReceiptLineItem.ReceivedAmount__c;
				newLineItem.RemainingAmount__c = paymentReceiptLineItem.PreviousRemaining__c;
				newLineItem.Status__c = paymentReceiptLineItem.OpportunityPayment__r.PaymentStatus__c;
				System.debug('Clone: '+newLineItem.Status__c);
				System.debug(newLineItem.OpportunityPayment__r.ReceivedAmount__c);
				termToLineItemMap.put(currentTerm, newLineItem);
			} else  {
				PaymentReceiptLineItem__c existingLineItem = termToLineItemMap.get(currentTerm);
				System.debug('Existing: '+existingLineItem);
				System.debug('Payment Receipt : '+paymentReceiptLineItem.ReceivedAmount__c);
				existingLineItem.ReceivedAmount__c += paymentReceiptLineItem.ReceivedAmount__c;
				//existingLineItem.RemainingAmount__c = paymentReceiptLineItem.PreviousRemaining__c;
				existingLineItem.Status__c = paymentReceiptLineItem.OpportunityPayment__r.PaymentStatus__c;
				System.debug('Existing: '+existingLineItem.Status__c);
				System.debug(existingLineItem.OpportunityPayment__r.ReceivedAmount__c);
			}
		}

		updatedPaymentReceiptLineItems.addAll(termToLineItemMap.values());
		return updatedPaymentReceiptLineItems;
	}

	public List<PaymentReceipt__c> getCancelPaymentReceiptByOppIdSet(Set<Id> oppIdSet){
		List<PaymentReceipt__c> receiptForCancels = new List<PaymentReceipt__c>();

		List<PaymentReceipt__c> receipts = PaymentReceiptSelector.getInstance().getByOppIdSet(oppIdSet);
		for (PaymentReceipt__c receipt : receipts) {
			receiptForCancels.add(
				new PaymentReceipt__c(
					Id = receipt.Id,
					// IsCancel__c = true,
					CancelReason__c = 'Closed Lost'
				)
			);
		}

		return receiptForCancels;
	}
}