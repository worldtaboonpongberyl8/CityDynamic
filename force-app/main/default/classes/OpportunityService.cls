public with sharing class OpportunityService {
	public OpportunityService() {

	}
	public static OpportunityService instance;

	public static OpportunityService getInstance() {
		if (instance == null) {
			instance = new OpportunityService();
		}
		return instance;
	}
	public List<Opportunity> assignUnitPriceToOpportunity(List<Opportunity> opportunitys){
		Set<Id> productIds = new Set<Id>();
		for(Opportunity opp : opportunitys){
			productIds.add(opp.Unit__c);
		}
		PricebookEntrySelector getPricebookEntry = PricebookEntrySelector.getInstance();
		Map<Id,PricebookEntry> pricebookEntry = getPricebookEntry.getPricebookEntiesByProductId(productIds);
		List<Opportunity> updateOpportunity = new List<Opportunity>();
		for(Opportunity opp : opportunitys){
			PricebookEntry pricebookUnit = pricebookEntry.get(opp.Unit__c);
			if (pricebookUnit != null){
				if(opp.Quota__c == 'Thai'){
					opp.UnitPrice__c = pricebookUnit.TQUnitPrice__c;
					opp.UnitPricePerSqm__c = pricebookUnit.TQUnitPricesqm__c;
				}else if(opp.Quota__c == 'Foreign'){
					opp.UnitPrice__c = pricebookUnit.FQUnitPrice__c;
					opp.UnitPricePerSqm__c = pricebookUnit.FQUnitPricesqm__c;
				}
			} else {
				opp.UnitPrice__c = 0;
				opp.UnitPricePerSqm__c = 0;
			}
			updateOpportunity.add(opp);
		}
		return updateOpportunity;
	}

	public List<Opportunity> stampOpportunitiesName(List<Opportunity> opportunities){
		for (Opportunity opportunity : opportunities){
			opportunity.Name = opportunity.OppNameFormat__c;
		}
		return opportunities;
	}
	public List<Opportunity> stampContractAmountAndPercent(List<Opportunity> opportunities){
		Set<Id> paymentMasterIds = new Set<Id>();
		for(Opportunity opp : opportunities){
			paymentMasterIds.add(opp.PaymentTermMaster__c);
		}
		PaymentTermSelector paymentTermSelector = PaymentTermSelector.getInstance();
		Map<Id,PaymentTermMaster__c> paymentTermMap = paymentTermSelector.getPaymentTermMasterWithLineItemsMapById(paymentMasterIds);
		for(Opportunity opp : opportunities){
			PaymentTermMaster__c paymentTermMaster = paymentTermMap.get(opp.PaymentTermMaster__c);
			List<PaymentTerm__c> paymentTerms = paymentTermMaster == null ? new List<PaymentTerm__c>() : paymentTermMaster.Payment_Term__r;
			for (PaymentTerm__c paymentTerm : paymentTerms){
				if (paymentTerm.Term__c == 'Contract'){
					Decimal contractAmount = paymentTerm.Amount__c != null ? paymentTerm.Amount__c : 0;
					Decimal contractPercent = paymentTerm.Percent__c != null ? paymentTerm.Percent__c : 0;
					opp.ContractAmount__c = contractAmount;
					opp.ContractPercent__c = contractPercent;
					break;
				}
			}
		}
		return opportunities;
	}

	public List<Opportunity> stampTotalInstallmentAmountAndPercent(List<Opportunity> opportunities){
		Set<Id> paymentMasterIds = new Set<Id>();
		for(Opportunity opp : opportunities){
			paymentMasterIds.add(opp.PaymentTermMaster__c);
		}
		PaymentTermSelector paymentTermSelector = PaymentTermSelector.getInstance();
		Map<Id,PaymentTermMaster__c> paymentTermMap = paymentTermSelector.getPaymentTermMasterWithLineItemsMapById(paymentMasterIds);
		for(Opportunity opp : opportunities){
			PaymentTermMaster__c paymentTermMaster = paymentTermMap.get(opp.PaymentTermMaster__c);
			List<PaymentTerm__c> paymentTerms = paymentTermMaster == null ? new List<PaymentTerm__c>() : paymentTermMaster.Payment_Term__r;
			Decimal totalInstallmentAmount = 0;
			Decimal totalInstallmentPercent = 0;
			for (PaymentTerm__c paymentTerm : paymentTerms){
				if (paymentTerm.Term__c.contains('Installment')){
					totalInstallmentAmount = paymentTerm.Amount__c != null ? totalInstallmentAmount + paymentTerm.Amount__c : totalInstallmentAmount;
					totalInstallmentPercent = paymentTerm.Percent__c != null ? totalInstallmentPercent + paymentTerm.Percent__c : totalInstallmentPercent;
				}
			}
			opp.TotalInstallmentAmount__c = totalInstallmentAmount;
			opp.TotalInstallmentPercent__c = totalInstallmentPercent;
		}
		return opportunities;
	}

	public List<Opportunity> stampCoBuyerName(List<Opportunity> opportunities){
		Set<Id> oppIds = new Set<Id>();
		for (Opportunity opportunity : opportunities){
			oppIds.add(opportunity.Id);
		}
		OpportunitySelector oppSelector = OpportunitySelector.getInstance();
		Map<Id, Opportunity> oppWithCoBuyerMapById = oppSelector.getOpportunityWithCoBuyerMapById(oppIds);
		for (Opportunity opportunity : opportunities){
			Opportunity targetOpp = oppWithCoBuyerMapById.get(opportunity.Id);
			String targetName = opportunity.AccountName__c;
			opportunity.CoBuyerName__c = targetName;
			opportunity.IsCoBuyer__c = false;
			if (targetOpp != null){
				List<CoBuyer__c> coBuyers = targetOpp.Co_Borrowers__r;
				if (!coBuyers.isEmpty()){
					for (CoBuyer__c coBuyer : coBuyers){
						targetName = targetName + ' and/or ' + coBuyer.AccountName__c;
					}
					System.debug('targetName: ' + targetName);
					opportunity.CoBuyerName__c = targetName;
					opportunity.IsCoBuyer__c = true;
				}
			}
		}
		return opportunities;
	}

	public List<Opportunity> stampCloseLostDate(List<Opportunity> opportunities){
		for (Opportunity opportunity : opportunities){
			opportunity.ClosedLostDate__c = Date.today();
		}
		return opportunities;
	}

	/**
	 * Phase: 1
	 * UAT Issue: DF-UAT-022
	 */
	public List<Opportunity> stampCloseDate90Days(List<Opportunity> opportunities){
		for (Opportunity opportunity : opportunities){
			opportunity.CloseDate = Date.today().addDays(90);
		}
		return opportunities;
	}

	/**
	 * Phase: 1
	 * UAT Issue: DF-UAT-024
	 */
	public List<Opportunity> stampLeadSourceFromAccount(List<Opportunity> opportunities){
		AccountSelector accountSelector = AccountSelector.getInstance();
		Set<Id> accountIds = new Set<Id>();
		for (Opportunity opportunity : opportunities){
			accountIds.add(opportunity.AccountId);
		}
		Map<Id, Account> accountMapById = accountSelector.getAccountWithContactsMapById(accountIds);
		for (Opportunity opportunity : opportunities){
			Account targetAccount = accountMapById.get(opportunity.AccountId);
			if (targetAccount != null){
				opportunity.LeadSource = targetAccount.AccountSource;
			}
		}
		return opportunities;
	}
}