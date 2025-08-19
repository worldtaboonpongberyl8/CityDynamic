/**
 * Phase2
 * Details:
 * - add new controller for LWC:completeNovation
 */
public with sharing class CompleteNovationController {
    @AuraEnabled
	public static Map<String,List<SObject>> completeNovation(Id opportunityId){
		Savepoint sp = Database.setSavepoint();
		try {
			Map<String,List<SObject>> resultMap = new Map<String,List<SObject>>();
			ContractService contractService = ContractService.getInstance();
			PaymentReceiptService receiptService = PaymentReceiptService.getInstance();
			OpportunityService opportunityService = OpportunityService.getInstance();
			OpportunityAccountChangeLogService oppAccChangeLogService = OpportunityAccountChangeLogService.getInstance();
			OpportunitySelector opportunitySelector = OpportunitySelector.getInstance();
			Set<Id> oppIds = new Set<Id>{opportunityId};
			Map<Id, Opportunity> opportunityWithRelatedRecordForNovationMapById = opportunitySelector.getOpportuntiyWithRelatedRecordForNovationMapById(oppIds);
			List<OpportunityPayment__c> opportunityPayments = opportunityWithRelatedRecordForNovationMapById.get(opportunityId).Opportunity_Payments__r;
			List<Quote__c> syncedQuotes = opportunityWithRelatedRecordForNovationMapById.get(opportunityId).Quote__r;
			List<ClientOffer__c> clientOffers = opportunityWithRelatedRecordForNovationMapById.get(opportunityId).Client_Offers__r;
			List<PromotionOpportunity__c> promotionOpportunities = opportunityWithRelatedRecordForNovationMapById.get(opportunityId).Promotion_Transactions__r;
			List<CoBuyer__c> coBuyers = opportunityWithRelatedRecordForNovationMapById.get(opportunityId).Co_Borrowers__r;
			List<Contract> contracts = opportunityWithRelatedRecordForNovationMapById.get(opportunityId).Contracts__r;
			Opportunity oldOpporunity = opportunityWithRelatedRecordForNovationMapById.get(opportunityId);
			Opportunity novatedOpportunity = opportunityService.getClonedOpportunityForNovationProcess(oldOpporunity);
			OpportunityTriggerHandler.getInstance().setBypassCreatingPromotionOpportunity();
			OpportunityTriggerHandler.getInstance().setBypassCreatingOpportunityPayment();
			insert novatedOpportunity;
			OpportunityTriggerHandler.getInstance().clearBypassCreatingPromotionOpportunity();
			OpportunityTriggerHandler.getInstance().setBypassCreatingOpportunityPayment();
			oldOpporunity = opportunityService.getOpportunityAfterNovationProcess(oldOpporunity,novatedOpportunity);
			update oldOpporunity;
			List<SObject> clonedOpportunityPayments = opportunityService.clonedRecordRelateWithOpportunity(opportunityPayments,novatedOpportunity.Id);
			List<SObject> clonedSyncedQuotes = opportunityService.clonedRecordRelateWithOpportunity(syncedQuotes,novatedOpportunity.Id);
			List<SObject> clonedClientOffers = opportunityService.clonedRecordRelateWithOpportunity(clientOffers,novatedOpportunity.Id);
			List<SObject> clonedOpportunityPromotions = opportunityService.clonedRecordRelateWithOpportunity(promotionOpportunities,novatedOpportunity.Id);
			List<SObject> clonedCoBuyers = opportunityService.clonedRecordRelateWithOpportunity(coBuyers,novatedOpportunity.Id);
			List<SObject> clonedContracts = opportunityService.clonedRecordRelateWithOpportunity(contracts,novatedOpportunity.Id);
			insert clonedOpportunityPayments;
			insert clonedSyncedQuotes;
			insert clonedClientOffers;
			insert clonedOpportunityPromotions;
			// insert clonedCoBuyers;
			// insert with new status
			for (SObject clonedContract : clonedContracts){
				clonedContract.put('Status','Draft');
			}
			insert clonedContracts;
			// update with Signed Contract
			for (SObject clonedContract : clonedContracts){
				clonedContract.put('Status','Signed Contract');
			}
			update clonedContracts;
			OpportunityAccountChangeLog__c oppAccChangeLog = oppAccChangeLogService.craeteOpportunityAccountChangeLogFromPreviousAndCurrentOpportunity(oldOpporunity,novatedOpportunity);
			insert oppAccChangeLog;
			List<PaymentReceipt__c> snapshotReceipts = receiptService.lookupPaymentReceiptToOpportunityAccountChangeLog(new Set<Id>{oppAccChangeLog.Id});
			update snapshotReceipts;
			List<Contract> updatedContracts = contractService.getContractAfterNovationProcess(contracts);
			update updatedContracts;
			resultMap.put('oldOpportunity',new List<Opportunity>{oldOpporunity});
			resultMap.put('novatedOpportunity', new List<Opportunity>{novatedOpportunity});
			resultMap.put('clonedOpportunityPayments', clonedOpportunityPayments);
			resultMap.put('clonedSyncedQuotes', clonedSyncedQuotes);
			resultMap.put('clonedClientOffers', clonedClientOffers);
			resultMap.put('clonedOpportunityPromotions', clonedOpportunityPromotions);
			resultMap.put('clonedCoBuyers', clonedCoBuyers);
			resultMap.put('clonedContracts', clonedContracts);
			resultMap.put('oppAccChangeLog', new List<OpportunityAccountChangeLog__c>{oppAccChangeLog});
			resultMap.put('snapshotReceipts' , snapshotReceipts);
			return resultMap;
		} catch (Exception e) {
			Database.rollback(sp);
            System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
		}
	}


}