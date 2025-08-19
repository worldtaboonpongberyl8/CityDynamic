/**
 * Phase2
 * Details:
 * - add new controller for LWC:completeRefundForfeit
 */
public with sharing class CompleteRefundForfeitController {

    @AuraEnabled
	public static Map<String,List<SObject>> completeRefundForfeit(Id opportunityId){
		Savepoint sp = Database.setSavepoint();
		try {
			Map<String,List<SObject>> resultMap = new Map<String,List<SObject>>();
			ContractService contractService = ContractService.getInstance();
			OpportunitySelector oppSelector = OpportunitySelector.getInstance();
			OpportunityService oppService = OpportunityService.getInstance();
			PaymentReceiptService paymentReceiptService = PaymentReceiptService.getInstance();
			Map<Id, Opportunity> opportunityMapById = oppSelector.getOpportunityMapById(new Set<Id>{opportunityId});
			Map<Id, Opportunity> opportunityWithContractMapById = oppSelector.getOpportuntiyWithRelatedRecordForNovationMapById(new Set<Id>{opportunityId});
			// STEP 1: Closed Lost Opportunity
			Opportunity targetOpportunity = opportunityMapById.get(opportunityId);
			List<Opportunity> closedLostOpportunities = oppService.closeLostOpportunityRefundForfeit(new List<Opportunity>{targetOpportunity});
			update closedLostOpportunities;
			// STEP 2: Create Receipt for Refund/Forfeit/Operation
			PaymentReceipt__c operationPaymentReceipt = paymentReceiptService.generateOperationPaymentReceiptRelatedToOpportunity(targetOpportunity.Id,'refund/forfeit');
			insert operationPaymentReceipt;
			PaymentReceipt__c operationPaymentReceiptWithRunningNo = paymentReceiptService.generateRunningNo(operationPaymentReceipt);
			update operationPaymentReceiptWithRunningNo;
			// STEP 3: Craete Receipt Line Item for Refund/Forfeit/Operation
			List<PaymentReceiptLineItem__c> refundPaymentReceiptLineItems = paymentReceiptService.generateOperationPaymentReceiptLineItem(targetOpportunity.NetAgreedRefundAmount__c,operationPaymentReceiptWithRunningNo.Id,null,GlobalConstants.RECEIPTLINE_TYPE_REFUND);
			List<PaymentReceiptLineItem__c> forfeitPaymentReceiptLineItems = paymentReceiptService.generateOperationPaymentReceiptLineItem(targetOpportunity.NetAgreedForfeitAmount__c,operationPaymentReceiptWithRunningNo.Id,null,GlobalConstants.RECEIPTLINE_TYPE_FORFEIT);
			List<PaymentReceiptLineItem__c> operationPaymentReceiptLineItems = paymentReceiptService.generateOperationPaymentReceiptLineItem(targetOpportunity.TotalOperationFee__c,operationPaymentReceiptWithRunningNo.Id,null,GlobalConstants.RECEIPTLINE_TYPE_OPERATION);
			List<PaymentReceiptLineItem__c> allPaymentReceiptLineItems = new List<PaymentReceiptLineItem__c>();
			allPaymentReceiptLineItems.addAll(refundPaymentReceiptLineItems);
			allPaymentReceiptLineItems.addAll(forfeitPaymentReceiptLineItems);
			allPaymentReceiptLineItems.addAll(operationPaymentReceiptLineItems);
			insert allPaymentReceiptLineItems;
			// STEP 4: Cancel Contract
			Opportunity oppWithContract = opportunityWithContractMapById.get(opportunityId);
			List<Contract> contracts = oppWithContract.Contracts__r;
			List<Contract> updatedContract = contractService.getContractAfterRefundForfeitProcess(contracts,closedLostOpportunities[0].LossReason__c);
			update updatedContract;
			resultMap.put('closedLostOpportunities', closedLostOpportunities);
			resultMap.put('operationPaymentReceiptWithRunningNo' , new List<PaymentReceipt__c>{operationPaymentReceiptWithRunningNo});
			resultMap.put('allPaymentReceiptLineItems' , allPaymentReceiptLineItems);
			resultMap.put('updatedContract', updatedContract);
			return resultMap;
		} catch (Exception e){
			Database.rollback(sp);
            System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
		}
	}

}