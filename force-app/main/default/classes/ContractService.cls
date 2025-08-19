public with sharing class ContractService {
    public static ContractService instance;
    public static ContractService getInstance(){
        if (instance == null){
            instance = new ContractService();
        }
        return instance;
    }

    public List<Contract> generateContractsFromOpportunities(List<Opportunity> opportunities){
        List<Contract> targetContracts = new List<Contract>();
        for (Opportunity opportunity : opportunities){
            Contract targetContract = new Contract();
            targetContract.Status = 'Draft';
            targetContract.Opportunity__c = opportunity.Id;
            targetContract.AccountId = opportunity.AccountId;
            targetContract.Project__c = opportunity.Project__c;
            targetContract.Unit__c = opportunity.Unit__c;
            targetContract.DiscountAmount__c = opportunity.DiscountAmount__c;
            targetContract.DiscountPercent__c = opportunity.DiscountPercent__c;
            List<Quote__c> syncedQuotes = opportunity.Quote__r;
            if (!syncedQuotes.isEmpty()){
                Quote__c syncedQuote = syncedQuotes[0];
                targetContract.AddressEN__c = syncedQuote.AddressEN__c;
                targetContract.AddressTH__c = syncedQuote.AddressTH__c;
            }
            targetContracts.add(targetContract);
        }
        return targetContracts;
    }

    public List<Contract> stampContractName(List<Contract> contracts){
        for (Contract contract : contracts){
            contract.Name = contract.FormatContractName__c;
        }
        return contracts;
    }

    public List<ClientOffer__c> makeRelationshipWithClientOffer(List<Contract> contracts){
        OpportunitySelector oppSelector = OpportunitySelector.getInstance();
        List<ClientOffer__c> updatedClientOffers = new List<ClientOffer__c>();
        Set<Id> oppIds = new Set<Id>();
        for (Contract contract : contracts){
            oppIds.add(contract.Opportunity__c);
        }
        Map<Id, Opportunity> opportunityWithClientOffer = oppSelector.getOpportunityWithClientOfferMapById(oppIds);
        for (Contract contract : contracts){
            Opportunity targetOpp = opportunityWithClientOffer.get(contract.Opportunity__c);
            List<ClientOffer__c> clientOffers = targetOpp.Client_Offers__r;
            if (!clientOffers.isEmpty()){
                for (ClientOffer__c clientOffer : clientOffers){
                    clientOffer.Contract__c = contract.Id;
                    updatedClientOffers.add(clientOffer);
                }
            }
        }
        return updatedClientOffers;
    }
/**
    * UAT Issue: DF-UAT-037
    */
    public Map<Id, Boolean> checkFullyPaidStatusForCompleteContract(List<Contract> contracts){
        OpportunityPaymentSelector oppPaymentSelector = OpportunityPaymentSelector.getInstance();
        Map<Id, Boolean> checkFullyPaidStatusOppPaymentMapByContractId = new Map<Id, Boolean>();
        Set<Id> oppIds = new Set<Id>();
        for (Contract contract : contracts){
            oppIds.add(contract.Opportunity__c);
        }
        Map<Id, List<OpportunityPayment__c>> opportunityPaymentMapById = oppPaymentSelector.getOpportunityPaymentsMapByOppId(oppIds);
        for(Contract contract : contracts){
            List<OpportunityPayment__c> oppPaymentForCheckStatus = opportunityPaymentMapById.get(contract.Opportunity__c) == null ? new List<OpportunityPayment__c>() : opportunityPaymentMapById.get(contract.Opportunity__c);
            for(OpportunityPayment__c oppPayment : oppPaymentForCheckStatus){
                if(oppPayment.Term__c.contains('Contract') && oppPayment.PaymentStatus__c != 'Fully Paid'){
                    checkFullyPaidStatusOppPaymentMapByContractId.put(contract.Id, false);
                    break;
                }
            }
        }
        return checkFullyPaidStatusOppPaymentMapByContractId;
    }
    public List<Opportunity> stampCompleteContractStatusToOpp(List<Contract> contracts){
        OpportunitySelector oppSelector = OpportunitySelector.getInstance();
        List<Opportunity> updatedOpportunities = new List<Opportunity>();
        Set<Id> oppIds = new Set<Id>();
        for (Contract contract : contracts){
            oppIds.add(contract.Opportunity__c);
        }
        Map<Id, Opportunity> opportunityMapById = oppSelector.getOpportunityMapById(oppIds);
        for (Opportunity opportunity : opportunityMapById.values()){
            opportunity.IsCompletedContract__c = true;
            updatedOpportunities.add(opportunity);
        }
        return updatedOpportunities;
    }

	/**
	 * Phase2
	 * Details:
	 * - Add method to stamp field to Contract after Novation Process
	 */
	public List<Contract> getContractAfterNovationProcess(List<Contract> oldContracts){
		for (Contract oldContract : oldContracts){
			oldContract.Status = 'Cancel';
			oldContract.CancelReason__c = GlobalConstants.OPP_LOST_REASON_NOVATION;
		}
		return oldContracts;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to stamp field to Contract after Moving Process
	 */
	public List<Contract> getContractAfterMovingProcess(List<Contract> oldContracts, String action){
		for (Contract oldContract : oldContracts){
			oldContract.Status = 'Cancel';
			oldContract.CancelReason__c = action == 'upgrade' ? GlobalConstants.OPP_LOST_REASON_UPGRADE :
										action == 'downgrade' ? GlobalConstants.OPP_LOST_REASON_DOWNGRADE :
										GlobalConstants.OPP_LOST_REASON_MOVEPAYMENT;
		}
		return oldContracts;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to stamp field to Contract after Moving Process
	 */
	public List<Contract> getContractAfterRefundForfeitProcess(List<Contract> oldContracts, String cancelReason){
		for (Contract oldContract : oldContracts){
			oldContract.Status = 'Cancel';
			oldContract.CancelReason__c = cancelReason;
		}
		return oldContracts;
	}
}