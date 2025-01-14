public with sharing class OpportunityTriggerHandler {
	public OpportunityTriggerHandler() {
	}
	public static OpportunityTriggerHandler instance;
	public static OpportunityTriggerHandler getInstance() {
		if (instance == null) {
			instance = new OpportunityTriggerHandler();
		}
		return instance;
	}

	public Boolean isActive = true;
	public List<Opportunity> newRecords;
	public Map<Id, Opportunity> oldMap;

	private final String STAGE_NAME_QUOTATION = 'Quotation';
	private final String STAGE_NAME_RESERVATION = 'Reservation';
	private final String STAGE_NAME_CONTRACT = 'Contract';
	private final String STAGE_NAME_TRANSFERRED = 'Transferred';
	private final String STAGE_NAME_CLOSED_LOST = 'Closed Lost';
	private final String STAGE_NAME_CLOSED_WON = 'Closed Won';

	public Boolean isTriggerActivated() {
		if (TriggerActivation__mdt.getInstance('OpportunityTrigger') != null) {
			return this.isActive && TriggerActivation__mdt.getInstance('OpportunityTrigger').isActive__c;
		}
		return this.isActive;
	}
	public void setParams(List<Opportunity> newRecords, Map<Id, Opportunity> oldMap) {
		this.newRecords = newRecords;
		this.oldMap = oldMap;
	}
	public void setBypass() {
		this.isActive = false;
	}

	public void clearBypass() {
		this.isActive = true;
	}
	public void executeBeforeInsert() {
		this.stampOpportunityName();
		this.stampCoBuyerName();
		this.assignUnitPriceToOpportunity();
		this.assignInitialPaymentAmount();
		this.stampLeadSourceFromAccountSource();
		this.stampCloseDateForCoAgentOpportunity();
	}
	public void executeAfterInsert() {
		this.createOpportunityPaymentByPaymentMaster();
		this.createPromotionOpportunity();
	}

	public void executeBeforeUpdate() {
		this.validateUpdatedFieldInClosedLostOpportunity();
		this.stampOpportunityNameBeforeUpdate();
		this.assignUnitPriceToOpportunityBeforeUpdate();
		this.assignInitialPaymentAmount();
		this.stampCloseLostDateAfterOppClosedLost();
	}

	public void executeAfterUpdate() {
		this.updateOpportunityPaymentByPaymentMaster();
		this.adjustRelatedOpportunityPaymentAfterApplyDiscount();
		this.adjustRelatedOpportunityPaymentAfterChangeReservationDueDate();
		this.changeUnitStageToBookOrSold();
		this.changeUnitStatusBackToAvailable();
		this.changeOpportunityPromotion();
		this.cancelInvoiceAndReceiptAfterOppClosedLost();
	}

	// ----- start before insert -----
	private void stampOpportunityName() {
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> resultOpportunities = service.stampOpportunitiesName(this.newRecords);
	}

	private void stampCoBuyerName() {
		OpportunityService service = OpportunityService.getInstance();
		service.stampCoBuyerName(this.newRecords);
	}

	private void assignUnitPriceToOpportunity() {
		OpportunityService service = OpportunityService.getInstance();
		service.assignUnitPriceToOpportunity(this.newRecords);
	}

	private void assignInitialPaymentAmount(){
		OpportunityService service = OpportunityService.getInstance();
		service.stampContractAmountAndPercent(this.newRecords);
		service.stampTotalInstallmentAmountAndPercent(this.newRecords);
	}

	/**
	 * Phase: 1
	 * UAT Issue: DF-UAT-022
	 */
	private void stampCloseDateForCoAgentOpportunity(){
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> filteredOpportunitities = new List<Opportunity>();
		Id targetRecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('CoAgent').getRecordTypeId();
		for (Opportunity opportunity : this.newRecords){
			if (opportunity.RecordTypeId == targetRecordTypeId){
				filteredOpportunitities.add(opportunity);
			}
		}
		if (!filteredOpportunitities.isEmpty()){
			service.stampCloseDate90Days(filteredOpportunitities);
		}
	}

	/**
	 * Phase: 1
	 * UAT Issue: DF-UAT-024
	 */
	private void stampLeadSourceFromAccountSource(){
		OpportunityService service = OpportunityService.getInstance();
		service.stampLeadSourceFromAccount(this.newRecords);
	}


	// ----- end before insert -----

	// ----- start after insert -----
	private void createOpportunityPaymentByPaymentMaster() {
		OpportunityPaymentService service = OpportunityPaymentService.getInstance();
		List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
		for (Opportunity opp : this.newRecords) {
			if (opp.PaymentTermMaster__c != null) {
				opportunitiesToInsert.add(opp);
			}
		}
		if (!opportunitiesToInsert.isEmpty()) {
			List<OpportunityPayment__c> listForCreate = service.createOpportunityPayments(opportunitiesToInsert);
			insert listForCreate;
		}
	}

	private void createPromotionOpportunity() {
		PromotionOpportunityService service = PromotionOpportunityService.getInstance();
		service.createPromotionOpportunityRelateToOpportunity(this.newRecords);
	}
	// ----- end after insert -----

	// ----- start before update -----
	private void stampOpportunityNameBeforeUpdate() {
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> filteredOpportunities = new List<Opportunity>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oppOldRecord = this.oldMap.get(opp.Id);
			if (
				opp.StageName == STAGE_NAME_QUOTATION ||
				oppOldRecord.Unit__c != opp.Unit__c ||
				oppOldRecord.Project__c != opp.Project__c
			) {
				filteredOpportunities.add(opp);
			}
		}
		if (!filteredOpportunities.isEmpty()) {
			service.stampOpportunitiesName(filteredOpportunities);
		}
	}

	private void assignUnitPriceToOpportunityBeforeUpdate() {
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> filteredOpp = new List<Opportunity>();
		for (Opportunity opportunity : this.newRecords) {
			Opportunity oldOpp = this.oldMap.get(opportunity.Id);
			if (opportunity.Unit__c != oldOpp.Unit__c || opportunity.Quota__c != oldOpp.Quota__c) {
				filteredOpp.add(opportunity);
			}
		}
		if (!filteredOpp.isEmpty()) {
			service.assignUnitPriceToOpportunity(filteredOpp);
		}
	}

	private void stampCloseLostDateAfterOppClosedLost(){
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> filteredOpportunities = new List<Opportunity>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oppOldRecord = this.oldMap.get(opp.Id);
			if (oppOldRecord.StageName != opp.StageName && opp.StageName == STAGE_NAME_CLOSED_LOST) {
				filteredOpportunities.add(opp);
			}
		}
		if (!filteredOpportunities.isEmpty()){
			service.stampCloseLostDate(filteredOpportunities);
		}
	}

	/**
	 * Phase: 1
	 * UAT Issue: DF-UAT-017, after GL service fire, unable to update result to Closed Opportunity
	 */
	private void validateUpdatedFieldInClosedLostOpportunity(){
		Set<String> exceptFields = new Set<String>{
		   'CreatedDate','LastModifiedById','LastModifiedDate','SystemModstamp','LastGLStatusInPojjaman__c','PaymentSummaryDocId__c','ReservationDocId__c'
		};
		Set<String> exceptProfileName = new Set<String>{'Senior Sales Manager' , 'Sales Director'};
		UserSelector userSelector = UserSelector.getInstance();
        User thisUser = userSelector.getUserById(UserInfo.getUserId());
        String profileName = thisUser.Profile.Name;
		for (Opportunity opp : this.newRecords) {
			if (opp.StageName == STAGE_NAME_CLOSED_LOST || opp.StageName == STAGE_NAME_CLOSED_WON){
				Opportunity oppOldRecord = this.oldMap.get(opp.Id);
				if((oppOldRecord.StageName != STAGE_NAME_CLOSED_WON && opp.StageName == STAGE_NAME_CLOSED_LOST) ||
					(oppOldRecord.StageName != STAGE_NAME_CLOSED_LOST && opp.StageName == STAGE_NAME_CLOSED_WON)){
						continue;
				}
				Set<String> fields = new Set<String>();
				for (String field : opp.getPopulatedFieldsAsMap().keySet()) {
					if ((field == 'LossReason__c' || field == 'OtherLostRejectReason__c') && exceptProfileName.contains(profileName)) continue;
					if(exceptFields.contains(field)) continue;
					if(oppOldRecord.get(field) != opp.get(field)){
						fields.add(field);
					}
				}
				if(!fields.isEmpty()){
					String errorMessage = opp.StageName == STAGE_NAME_CLOSED_LOST ? 'Cannot edit all informations when the opportunity is Closed Lost' : 'Cannot edit all informations when the opportunity is Closed Won';
					opp.addError(errorMessage);
				}
			}
		}
	}
	// ----- end before update -----

	// ----- start after update -----
	private void updateOpportunityPaymentByPaymentMaster() {
		OpportunityPaymentService service = OpportunityPaymentService.getInstance();
		List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oppOldRecord = this.oldMap.get(opp.Id);
			if (oppOldRecord.PaymentTermMaster__c != opp.PaymentTermMaster__c) {
				opportunitiesToUpdate.add(opp);
			}
		}
		if (!opportunitiesToUpdate.isEmpty()) {
			List<OpportunityPayment__c> listForCreate = service.updateOpportunityPaymentByPaymentMaster(opportunitiesToUpdate);
			insert listForCreate;
		}
	}

	private void adjustRelatedOpportunityPaymentAfterApplyDiscount() {
		OpportunityPaymentService service = OpportunityPaymentService.getInstance();
		List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oppOldRecord = this.oldMap.get(opp.Id);
			if (
				oppOldRecord.DiscountPercent__c != opp.DiscountPercent__c ||
				oppOldRecord.DiscountAmount__c != opp.DiscountAmount__c ||
				oppOldRecord.Unit__c != opp.Unit__c
			) {
				opportunitiesToUpdate.add(opp);
			}
		}
		if (!opportunitiesToUpdate.isEmpty()) {
			List<OpportunityPayment__c> listForUpdate = service.adjustRelatedOpportunityPaymentAfterApplyDiscount(opportunitiesToUpdate);
			update listForUpdate;
		}
	}

	private void adjustRelatedOpportunityPaymentAfterChangeReservationDueDate() {
		OpportunityPaymentService service = OpportunityPaymentService.getInstance();
		List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oppOldRecord = this.oldMap.get(opp.Id);
			if (oppOldRecord.ReservationDueDate__c != opp.ReservationDueDate__c ) {
				opportunitiesToUpdate.add(opp);
			}
		}
		if (!opportunitiesToUpdate.isEmpty()) {
			List<OpportunityPayment__c> listForUpdate = service.adjustRelatedOpportunityPaymentAfterChangeReservationDueDate(opportunitiesToUpdate);
			update listForUpdate;
		}
	}

	private void changeUnitStageToBookOrSold() {
		Product2Service service = Product2Service.getInstance();
		List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oppOldRecord = this.oldMap.get(opp.Id);
			if (
				(oppOldRecord.StageName != opp.StageName) &&
				(opp.StageName == STAGE_NAME_RESERVATION ||
				opp.StageName == STAGE_NAME_TRANSFERRED ||
				opp.StageName == STAGE_NAME_CONTRACT)
			) {
				opportunitiesToUpdate.add(opp);
			}
		}
		if (!opportunitiesToUpdate.isEmpty()) {
			List<Product2> products = service.changeUnitStageToBookOrSoldByOpportunityStage(opportunitiesToUpdate);
			if(!products.isEmpty()){
				update products;
			}
		}
	}

	private void changeUnitStatusBackToAvailable() {
		Product2Service service = Product2Service.getInstance();
		List<Opportunity> filteredOpportunities = new List<Opportunity>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oppOldRecord = this.oldMap.get(opp.Id);
			if (
				(oppOldRecord.StageName != opp.StageName) &&
				(opp.StageName == STAGE_NAME_CLOSED_LOST)
			) {
				filteredOpportunities.add(opp);
			}
		}
		if (!filteredOpportunities.isEmpty()) {
			service.changeUnitStatusToAvailableByClosedLostOpportunity(filteredOpportunities);
		}
	}

	private void changeOpportunityPromotion() {
		List<Opportunity> filteredOpportunities = new List<Opportunity>();
		PromotionOpportunityService service = PromotionOpportunityService.getInstance();
		for (Opportunity opp : this.newRecords) {
			Opportunity oppOldRecord = this.oldMap.get(opp.Id);
			if ((oppOldRecord.Project__c != opp.Project__c) || (oppOldRecord.Unit__c != opp.Unit__c)) {
				filteredOpportunities.add(opp);
			}
		}
		if (!filteredOpportunities.isEmpty()) {
			service.deleteAndCreateNewPromotionOpportunity(filteredOpportunities);
		}
	}

	private void cancelInvoiceAndReceiptAfterOppClosedLost() {
		PaymentReceiptTriggerHandler paymentReceiptTriggerHandler = PaymentReceiptTriggerHandler.getInstance();
		Set<Id> filteredOppIdSet = new Set<Id>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oppOldRecord = this.oldMap.get(opp.Id);
			if (oppOldRecord.StageName != opp.StageName && opp.StageName == STAGE_NAME_CLOSED_LOST) {
				filteredOppIdSet.add(opp.Id);
			}
		}
		if (!filteredOppIdSet.isEmpty()) {
			List<Invoice__c> invoiceForCancels = InvoiceService.getInstance().getCancelInvoiceByOppIdSet(filteredOppIdSet);
			List<PaymentReceipt__c> receiptForCancels = PaymentReceiptService.getInstance().getCancelPaymentReceiptByOppIdSet(filteredOppIdSet);

			if(!invoiceForCancels.isEmpty()){
				update invoiceForCancels;
			}

			if(!receiptForCancels.isEmpty()){
				paymentReceiptTriggerHandler.setBypass();
				update receiptForCancels;
				paymentReceiptTriggerHandler.clearBypass();
			}
		}
	}
	// ----- end after update -----




}