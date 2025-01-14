public with sharing class PaymentMathodSelector {
	public static PaymentMathodSelector instance;
	public static PaymentMathodSelector getInstance() {
		if (instance == null) {
			instance = new PaymentMathodSelector();
		}
		return instance;
	}
	public PaymentMathodSelector() {

	}
	public Map<Id, List<PaymentMethod__c>> getPaymentMethodMapByPaymentReceiptId(Set<Id> paymentReceiptIds) {
		Map<Id, List<PaymentMethod__c>> paymentMethodMapByPaymentReceiptId = new Map<Id, List<PaymentMethod__c>>();
		List<PaymentMethod__c> paymentMethods = [
				SELECT
							Id,
							PaymentReceipt__c,
							PaymentType__c,
							ChequeNo__c,
							BankName__c,
							BankBranch__c,
							BankAccountNo__c,
							CreditCardNo__c,
							DebitCardNo__c,
							InternationalBankName__c,
							PaymentDate__c,
							BankDraftNo__c,
							ReceivedAmount__c
				FROM PaymentMethod__c
				WHERE PaymentReceipt__c IN :paymentReceiptIds
			];
			for (PaymentMethod__c paymentMethod : paymentMethods) {
				if (!paymentMethodMapByPaymentReceiptId.containsKey(paymentMethod.PaymentReceipt__c)) {
					paymentMethodMapByPaymentReceiptId.put(paymentMethod.PaymentReceipt__c, new List<PaymentMethod__c>());
				}
				paymentMethodMapByPaymentReceiptId.get(paymentMethod.PaymentReceipt__c).add(paymentMethod);
			}
			return paymentMethodMapByPaymentReceiptId;

}
}