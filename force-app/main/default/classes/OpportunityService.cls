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
	/**
	 * Phase2
	 * Details:
	 * - Modify logic to stamp PricingPeriod__c in Opportunity from PricebookEntry.PricingPeriod__c
	 */
	public List<Opportunity> assignUnitPriceAndPeriodToOpportunity(List<Opportunity> opportunitys){
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
				// Phase2: stamp PricingPeriod__c
				opp.PricingPeriod__c = pricebookUnit.PricingPeriod__c;
				if(opp.Quota__c == 'Thai'){
					opp.UnitPrice__c = pricebookUnit.UnitPrice;
					opp.UnitPricePerSqm__c = pricebookUnit.UnitPriceSqm__c;
				}else if(opp.Quota__c == 'Foreign'){
					opp.UnitPrice__c = pricebookUnit.UnitPrice;
					opp.UnitPricePerSqm__c = pricebookUnit.UnitPriceSqm__c;
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

	/**
	 * Phase2
	 * Details:
	 * - Edit method to stamp CoBuyerName__c just for Active Co-Buyer
	 */
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
						if (coBuyer.Status__c == GlobalConstants.COBUYER_STATUS_ACTIVE){
							targetName = targetName + ' and/or ' + coBuyer.AccountName__c;
						}
					}
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

	/**
	 * Phase2
	 * Details:
	 * - Add method to stamp OperationFeeNovation__c and ActualOperationFeeNovation__c default from Project
	 */
	public List<Opportunity> stampDefaultNovationFeeFromProject(List<Opportunity> opportunities){
		ProjectSelector projectSelector = ProjectSelector.getInstance();
		Set<Id> projectIds = new Set<Id>();
		for (Opportunity opportunity: opportunities){
			projectIds.add(opportunity.Project__c);
		}
		Map<Id, Project__c> projectMapById = projectSelector.getProjectById(projectIds);
		for (Opportunity opportunity: opportunities){
			Project__c targetProject = projectMapById.get(opportunity.Project__c);
			if (targetProject != null){
				opportunity.OperationFeeNovation__c = targetProject.NovationFee__c;
				opportunity.ActualOperationFeeNovation__c = targetProject.NovationFee__c;
			}
		}
		return opportunities;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to cloned child records relate to Opportunity
	 */
	public Opportunity getClonedOpportunityForNovationProcess(Opportunity oldOpportunity){
		Opportunity novatedOpportunity = oldOpportunity.clone(false, false, false, false);
		novatedOpportunity.StageName = GlobalConstants.OPP_STAGENAME_SIGNEDNOVATION;
		novatedOpportunity.AccountId = oldOpportunity.NewCoOwner__c;
		novatedOpportunity.NovateFromOpportunity__c = oldOpportunity.Id;
		novatedOpportunity.NovationDate__c = Date.today();
		if (oldOpportunity.NewCoOwner__r.Nationality__c != 'Thai'){
			novatedOpportunity.Quota__c = 'Foreign';
		}
		novatedOpportunity.NewCoOwner__c = null;
		novatedOpportunity.CoOwnerRelationship__c = null;
		novatedOpportunity.IsNovatedOpp__c = true;
		novatedOpportunity.NovationApprovedDate__c = null;
		novatedOpportunity.NovationStatus__c = null;
		novatedOpportunity.IsPaidNovationFee__c = false;
		novatedOpportunity.URLNovation__c = null;
		novatedOpportunity.NovationDate__c = null;
		return novatedOpportunity;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to stamp field to Opportunity after Novation Process
	 */
	public Opportunity getOpportunityAfterNovationProcess(Opportunity oldOpportunity, Opportunity novatedOpportunity){
		oldOpportunity.IsNovationCompleted__c = true;
		oldOpportunity.NovateToOpportunity__c = novatedOpportunity.Id;
		oldOpportunity.StageName = GlobalConstants.OPP_STAGENAME_CLOSED_LOST;
		oldOpportunity.LossReason__c = GlobalConstants.OPP_LOST_REASON_NOVATION;
		return oldOpportunity;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to cloned child records relate to Opportunity
	 */
	public List<SObject> clonedRecordRelateWithOpportunity(List<SObject> records, Id opportuntiyId){
		List<SObject> clonedRecords = new List<SObject>();
		for (SObject record : records){
			SObject clonedRecord = record.clone(false,false,false,false);
			clonedRecord.put('Opportunity__c',opportuntiyId);
			clonedRecords.add(clonedRecord);
		}
		return clonedRecords;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to stamp Quota__c to 'FQ' if Foreign Co Buyer exists
	 */
	public List<Opportunity> stampFQQuotaIfForeignCoOwnerExists(List<Opportunity> opportunities){
		Set<Id> oppIds = new Set<Id>();
		for (Opportunity opportunity : opportunities){
			oppIds.add(opportunity.Id);
		}
		OpportunitySelector oppSelector = OpportunitySelector.getInstance();
		Map<Id, Opportunity> oppWithCoBuyerMapById = oppSelector.getOpportunityWithCoBuyerMapById(oppIds);
		List<Opportunity> targetOpportunities = new List<Opportunity>();
		for (Opportunity opportunity : opportunities){
			Opportunity targetOpp = oppWithCoBuyerMapById.get(opportunity.Id);
			if (targetOpp != null){
				List<CoBuyer__c> coBuyers = targetOpp.Co_Borrowers__r;
				List<CoBuyer__c> foreignCoBuyers = new List<CoBuyer__c>();
				if (!coBuyers.isEmpty()){
					for (CoBuyer__c coBuyer : coBuyers){
						if (coBuyer.Status__c == GlobalConstants.COBUYER_STATUS_ACTIVE && coBuyer.CoBuyerQuota__c == GlobalConstants.COBUYER_QUOTA_FQ){
							foreignCoBuyers.add(coBuyer);
						}
					}
				}
				if (!foreignCoBuyers.isEmpty() || targetOpp.Account.Nationality__c != 'Thai'){
					opportunity.Quota__c = GlobalConstants.OPP_QUOTA_FOREIGN;
				} else {
					opportunity.Quota__c = GlobalConstants.OPP_QUOTA_THAI;
				}
				targetOpportunities.add(opportunity);
			}
		}
		return targetOpportunities;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to validate if quota area exceed
	 */
	public Map<Id,Boolean> validateIsQuotaAreaExceed(List<Opportunity> opportunities){
		Map<Id,Boolean> validateResultMapByOppId = new Map<Id,Boolean>();
		ProjectService projectService = ProjectService.getInstance();
		ProjectSelector projectSelector = ProjectSelector.getInstance();
		Set<Id> projectIds = new Set<Id>();
		for (Opportunity opportunity : opportunities){
			projectIds.add(opportunity.Project__c);
		}
		Map<Id, Project__c> projectWithForeignOppMapById = projectSelector.getProjectWithForeignOppMapById(projectIds);
		Map<Id,Decimal> areaOfBookedOrSoldFQQuotaMapByProjectId = projectService.calculateAreaBookedOrSoldAsFQQuota(projectIds);
		for (Opportunity opportunity : opportunities){
			Project__c targetProject = projectWithForeignOppMapById.get(opportunity.Project__c);
			Decimal currentArea = opportunity.AreaSqm__c == null ? 0 : opportunity.AreaSqm__c;
			System.debug('currentArea: ' + currentArea);
			Decimal totalForeignBookAndSoldArea = areaOfBookedOrSoldFQQuotaMapByProjectId.get(targetProject.Id);
			System.debug('totalForeignBookAndSoldArea: ' + totalForeignBookAndSoldArea);
			Decimal totalForeignQuotaArea =  targetProject.ForeignQuotaArea__c;
			System.debug('totalForeignQuotaArea: ' + totalForeignQuotaArea);
			if (totalForeignBookAndSoldArea + currentArea > totalForeignQuotaArea){
				validateResultMapByOppId.put(opportunity.Id, false);
			} else {
				validateResultMapByOppId.put(opportunity.Id, true);
			}
		}
		return validateResultMapByOppId;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to stamp field to Opportunity after Upgrade/Downgrade/Move Payment process
	 */
	public Opportunity getOpportunityAfterMovingProcess(Opportunity oldOpportunity, Opportunity newOpportunity, String action){
		oldOpportunity.StageName = GlobalConstants.OPP_STAGENAME_CLOSED_LOST;
		if (action == 'upgrade'){
			oldOpportunity.LossReason__c = GlobalConstants.OPP_LOST_REASON_UPGRADE;
			oldOpportunity.UpgradeTo__c = newOpportunity.Id;
		} else if (action == 'downgrade'){
			oldOpportunity.LossReason__c = GlobalConstants.OPP_LOST_REASON_DOWNGRADE;
			oldOpportunity.DowngradeTo__c = newOpportunity.Id;
		} else if (action == 'move_payment'){
			if (oldOpportunity.UnitCode__c == newOpportunity.UnitCode__c){
				oldOpportunity.LossReason__c = GlobalConstants.OPP_LOST_REASON_PURCHASEOTHERNAME;
			} else {
				oldOpportunity.LossReason__c = GlobalConstants.OPP_LOST_REASON_MOVEPAYMENT;
			}
		}
		return oldOpportunity;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to stamp field to Opportunity after Upgrade/Downgrade/Move Payment process
	 */
	public Opportunity getNewOpportunityAfterMovingProcess(Opportunity oldOpportunity, Opportunity newOpportunity, String action){
		if (action == 'upgrade'){
			newOpportunity.UpgradeFrom__c = oldOpportunity.Id;
		} else if (action == 'downgrade'){
			newOpportunity.DowngradeFrom__c = oldOpportunity.Id;
		}
		return newOpportunity;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to generate token and stamp to PaymentPortalToken__c
	 */
	public List<Opportunity> generateAndStampPortalToken(List<Opportunity> opportunities){
		for (Opportunity opportunity : opportunities){
			String oppId = opportunity.Id;
			String accountId = opportunity.AccountId;
			String base = oppId + accountId;
			String token = EncodingUtil.base64Encode(Blob.valueOf(base));
			opportunity.PaymentPortalToken__c = token;
		}
		return opportunities;
	}

	/**
	 * Phase2
	 * Details:
	 * - add method to check outstanding payment for each Opp
	 */
	public Map<Id,Boolean> checkHasOutstandingPayment(List<Id> opportunityIds) {
		Map<Id, Boolean> outstandingPaymentResultMapByOppId = new Map<Id, Boolean>();
		List<OpportunityPayment__c> unpaidPayments = [
			SELECT Id,Opportunity__c
			FROM OpportunityPayment__c
			WHERE Opportunity__c IN :opportunityIds
			AND DueDate__c <= :Date.today()
			AND PaymentStatus__c != 'Fully Paid'
			AND IsMasterData__c = TRUE
		];
		Set<Id> outstandingOppIds = new Set<Id>();
		for (OpportunityPayment__c unpaidPayment : unpaidPayments) {
			outstandingOppIds.add(unpaidPayment.Opportunity__c);
		}
		for (Id opportunityId : opportunityIds){
			if (outstandingOppIds.contains(opportunityId)){
				outstandingPaymentResultMapByOppId.put(opportunityId,true);
			} else {
				outstandingPaymentResultMapByOppId.put(opportunityId,false);
			}
		}
		return outstandingPaymentResultMapByOppId;
	}

	/**
	 * Phase2
	 * Details:
	 * - add method to check close lost Opp with reason of Refund/Forfeit
	 */
	public List<Opportunity> closeLostOpportunityRefundForfeit(List<Opportunity> opportunities){
		for (Opportunity opportunity : opportunities){
			opportunity.IsRefundForfeitCompleted__c = true;
			opportunity.StageName = GlobalConstants.OPP_STAGENAME_CLOSED_LOST;
			if (opportunity.CancellationTerminationType__c == GlobalConstants.OPP_TERMINATION_TYPE_CANCELLATION &&
			opportunity.CancellationTerminationSubType__c == GlobalConstants.OPP_TERMINATION_SUBTYPE_FORFEIT){
				opportunity.LossReason__c = GlobalConstants.OPP_LOST_REASON_CANCELFORFEIT;
			} else if (opportunity.CancellationTerminationType__c == GlobalConstants.OPP_TERMINATION_TYPE_TERMINATION &&
			opportunity.CancellationTerminationSubType__c == GlobalConstants.OPP_TERMINATION_SUBTYPE_FORFEIT){
				opportunity.LossReason__c = GlobalConstants.OPP_LOST_REASON_TERMINATIONFORFEIT;
			} else if (opportunity.CancellationTerminationType__c == GlobalConstants.OPP_TERMINATION_TYPE_CANCELLATION &&
			opportunity.CancellationTerminationSubType__c == GlobalConstants.OPP_TERMINATION_SUBTYPE_REFUND){
				opportunity.LossReason__c = GlobalConstants.OPP_LOST_REASON_CANCELREFUND;
			} else if (opportunity.CancellationTerminationType__c == GlobalConstants.OPP_TERMINATION_TYPE_TERMINATION &&
			opportunity.CancellationTerminationSubType__c == GlobalConstants.OPP_TERMINATION_SUBTYPE_REFUND){
				opportunity.LossReason__c = GlobalConstants.OPP_LOST_REASON_TERMINATIONREFUND;
			}
		}
		return opportunities;
	}
	/**
	 * Phase2
	 * Details:
	 * - set Recurring Text to use create text file by use field set
	 */
	public Map<Id, String> getOpportunityTextMapByFieldset(List<Opportunity> opportunities) {
		Map<Id, String> recurringOpportunityTextMapByFieldset = new Map<Id, String>();

		if (opportunities == null || opportunities.isEmpty()) {
			return recurringOpportunityTextMapByFieldset;
		}

		Set<Id> oppIds = new Set<Id>();
		for (Opportunity opp : opportunities) {
			oppIds.add(opp.Id);
		}
		Map<Id, Opportunity> oppMap = OpportunitySelector.getInstance().getOpportunityFieldsetByIds(oppIds);
		List<Schema.FieldSetMember> fields = Schema.SObjectType.Opportunity.fieldSets.getMap().get('Recurring').getFields();
		for (Opportunity opp : opportunities) {
			Opportunity loadedOpp = oppMap.get(opp.Id);
			String recurringText = '';
			for (Schema.FieldSetMember field : fields) {
				Object value = loadedOpp.get(field.getFieldPath());
				if(value == null){
					value = '';
				}
				recurringText += String.valueOf(value) +',';

			}
			recurringOpportunityTextMapByFieldset.put(opp.Id, recurringText.trim());
		}
		return recurringOpportunityTextMapByFieldset;
	}

	/**
	 * Phase2
	 * Details:
	 * - add method to stamp TourAnalysis__c from Customer Visit to Opportunity
	 */
	public List<Opportunity> stampTourAnalysisFromCustomerVisit(List<CustomerVisit__c> customerVisits){
		List<Opportunity> opportunities = new List<Opportunity>();
		for (CustomerVisit__c customerVisit : customerVisits){
			opportunities.add(
				new Opportunity (
					Id = customerVisit.OpportunityName__c,
					TourAnalysis__c = customerVisit.TourAnalysis__c
				)
			);
		}
		return opportunities;
	}
}