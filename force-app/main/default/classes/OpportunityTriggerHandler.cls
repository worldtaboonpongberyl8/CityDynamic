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
	/**
	 * Phase2
	 * Details:
	 * - Add attribute to prevent specific method to be executed
	 */
	public Boolean isActiveCreatingPromotionOpportunity = true;
	public Boolean isActiveCreatingOpportunityPayment = true;

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

	/**
	 * Phase2
	 * Details:
	 * - Add method to prevent specific method to be executed
	 */
	public void setBypassCreatingPromotionOpportunity(){
		this.isActiveCreatingPromotionOpportunity = false;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to clear preventing specific method to be executed
	 */
	public void clearBypassCreatingPromotionOpportunity(){
		this.isActiveCreatingPromotionOpportunity = false;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to prevent specific method to be executed
	 */
	public void setBypassCreatingOpportunityPayment(){
		this.isActiveCreatingOpportunityPayment = false;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add method to clear preventing specific method to be executed
	 */
	public void clearBypassCreatingOpportunityPayment(){
		this.isActiveCreatingOpportunityPayment = false;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add logic to stamp NovationFee__c and ActualNovationFee__c default from Project
	 * - Add logic to stamp PaymentPortalToken__c
	 * - Add logic to validate Quota before opp created
	 * - Add logic to stamp default value from Project__c, Unit__c
	 */
	public void executeBeforeInsert() {
		this.validateQuotaBeforeInsert();
		this.stampOpportunityName();
		this.stampCoBuyerName();
		this.assignUnitPriceAndPeriodToOpportunity();
		this.assignInitialPaymentAmount();
		// this.stampLeadSourceFromAccountSource();
		this.stampCloseDateForCoAgentOpportunity();
		this.stampDefaultNovationFee();
		this.stampPaymentPortalToken();
		/**
		 * Phase2
		 * Details:
		 * - Add logic to stamp default value from Project__c, Unit__c
		 */
		this.stampDefaultValueFromProjectAndUnit();


	}

	/**
	 * Phase2
	 * Details:
	 * - Modify logic to check if method to create PromortionOpportunity__c is allowed
	 */
	public void executeAfterInsert() {
		// check if OpportunityPayment__c can be created
		if (this.isActiveCreatingOpportunityPayment){
			this.createOpportunityPaymentByPaymentMaster();
		}
		// check if PromortionOpportunity__c can be created
		if (this.isActiveCreatingPromotionOpportunity){
			this.createPromotionOpportunity();
		}

	}

	/**
	 * Phase2
	 * Details:
	 * - Modify logic to validate if quota changing allowed
	 * - Modify logic to validate if new co owner changing allowed
	 * - Add logic to stamp payment portal token
	 * - Add logic to validate outstanding payment before change new co-owner
	 * - Add logic to validate if stage can be changed to Reservation
	 * - Add logic to stamp default value from Project__c, Unit__c
	 */
	public void executeBeforeUpdate() {
		this.validateQuotaChanged();
		this.validateOutstandingAmount();
		this.validateNewCoOwnerChanged();
		this.validateUpdatedFieldInClosedLostOpportunity();
		this.validateAbleToChangeStageToReservation();
		this.stampDefaultNovationFeeBeforeUpdate();
		this.stampOpportunityNameBeforeUpdate();
		this.assignUnitPriceAndPeriodToOpportunityBeforeUpdate();
		this.assignInitialPaymentAmount();
		this.stampCloseLostDateAfterOppClosedLost();
		this.stampPaymentPortalTokenAfterAccountChanged();
		this.stampDefaultValueFromProjectAndUnit();
	}

	/**
	 * Phase2
	 * Details:
	 * - Modify lofic to call method to create OpportunityAccountChangeLog__c record after account changed
	 */
	public void executeAfterUpdate() {
		this.updateOpportunityPaymentByPaymentMaster();
		this.adjustRelatedOpportunityPaymentAfterApplyDiscount();
		this.adjustRelatedOpportunityPaymentAfterChangeReservationDueDate();
		this.changeUnitStageToBookOrSold();
		this.changeUnitStatusBackToAvailable();
		this.changeOpportunityPromotion();
		/**
		 * Phase2
		 * Details:
		 * - Modify logic to stamp CancelReason__c in Invoice and PaymentReceipt grouping from Opportunity.LossReason__c
		 * - Modify logic to cancel Invoice and Receipt just in case Opportunity is closed with all reasons except Novation
		 * - Add logic to cancel Contract when Opportunity is closed with all reasons except Novation,
		 */
		this.cancelInvoiceAndReceiptAfterOppClosedLost();
		this.createOpportunityAccountChangeLogAfterAccountChanged();
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

	private void assignUnitPriceAndPeriodToOpportunity() {
		OpportunityService service = OpportunityService.getInstance();
		service.assignUnitPriceAndPeriodToOpportunity(this.newRecords);
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

	/**
	 * Phase2
	 * Details:
	 * - Add logic to stamp NovationFee__c and ActualNovationFee__c default from Project
	 */
	private void stampDefaultNovationFee(){
		OpportunityService service = OpportunityService.getInstance();
		service.stampDefaultNovationFeeFromProject(this.newRecords);
	}

	/**
	 * Phase2
	 * Details:
	 * - Add logic to stamp PaymentPortalToken__c before insert
	 */
	private void stampPaymentPortalToken(){
		OpportunityService service = OpportunityService.getInstance();
		service.generateAndStampPortalToken(this.newRecords);
	}

	/**
	 * Phase2
	 * Details:
	 * - Add logic to validate if new co owner changing allowed
	 */
	private void validateQuotaBeforeInsert(){
		OpportunityService opportunitySerivce = OpportunityService.getInstance();
		List<Opportunity> filteredOpportunities = new List<Opportunity>();
		for (Opportunity opp : this.newRecords){
			if (opp.Quota__c == 'Foreign'){
				filteredOpportunities.add(opp);
			}
		}
		if (!filteredOpportunities.isEmpty()){
			Map<Id,Boolean> validateResultMapByOppId = opportunitySerivce.validateIsQuotaAreaExceed(filteredOpportunities);
			for (Opportunity opp : filteredOpportunities){
				Boolean isPassValidate = validateResultMapByOppId.get(opp.Id);
				System.debug('isPassValidate: ' + isPassValidate);
				if (!isPassValidate){
					opp.addError('The Opportunity cannot be created because the Foreign Quota Area of this project exceeds 49%');
				}
			}
		}
	}

	private void stampDefaultValueFromProjectAndUnit(){
		ProjectSelector projectSelector = ProjectSelector.getInstance();
		Product2Selector productSelector = Product2Selector.getInstance();
		Set<Id> projectIds = new Set<Id>();
		Set<Id> productIds = new Set<Id>();
		List<Opportunity> filteredOpportunities = new List<Opportunity>();
		for (Opportunity opp : this.newRecords){
			if (this.oldMap == null){
				filteredOpportunities.add(opp);
				projectIds.add(opp.Project__c);
				productIds.add(opp.Unit__c);
			} else {
				Opportunity oldOpp = this.oldMap.get(opp.Id);
				if (opp.Project__c != oldOpp.Project__c || opp.Unit__c != oldOpp.Unit__c) {
					filteredOpportunities.add(opp);
					projectIds.add(opp.Project__c);
					productIds.add(opp.Unit__c);
				}
			}
		}
		Map<Id, Product2> productMapById = productSelector.getProduct2ById(productIds);
		Map<Id, Project__c> projectMapById = projectSelector.getProjectById(projectIds);
		for (Opportunity opp : filteredOpportunities){
			Project__c targetProject = projectMapById.get(opp.Project__c);
			Product2 targetProduct = productMapById.get(opp.Unit__c);
			opp.Tower__c = targetProject == null ? null : targetProject.Tower__c;
			opp.UnitType__c = targetProduct == null ? null : targetProduct.UnitType__r.Name;
			opp.Floor__c = targetProduct == null ? null : targetProduct.Floor__r.Name;
		}
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
	/**
	 * Phase2
	 * Details:
	 * - Modify logic to stamp Opp name when AccountId changed
	 */
	private void stampOpportunityNameBeforeUpdate() {
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> filteredOpportunities = new List<Opportunity>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oppOldRecord = this.oldMap.get(opp.Id);
			if (
				opp.StageName == STAGE_NAME_QUOTATION ||
				oppOldRecord.Unit__c != opp.Unit__c ||
				oppOldRecord.Project__c != opp.Project__c ||
				oppOldRecord.AccountId != opp.AccountId
			) {
				filteredOpportunities.add(opp);
			}
		}
		if (!filteredOpportunities.isEmpty()) {
			service.stampOpportunitiesName(filteredOpportunities);
		}
	}

	private void assignUnitPriceAndPeriodToOpportunityBeforeUpdate() {
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> filteredOpp = new List<Opportunity>();
		for (Opportunity opportunity : this.newRecords) {
			Opportunity oldOpp = this.oldMap.get(opportunity.Id);
			if (opportunity.Unit__c != oldOpp.Unit__c || opportunity.Quota__c != oldOpp.Quota__c) {
				filteredOpp.add(opportunity);
			}
		}
		if (!filteredOpp.isEmpty()) {
			service.assignUnitPriceAndPeriodToOpportunity(filteredOpp);
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
		   'CreatedDate','LastModifiedById','LastModifiedDate','SystemModstamp','LastGLStatusInPojjaman__c','PaymentSummaryDocId__c','ReservationDocId__c','LastIntegrationDateTime__c','IsRefundForfeitCompleted__c','LossReason__c'
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

	/**
	 * Phase2
	 * Details:
	 * - Add logic to validate if quota changing allowed
	 */
	private void validateQuotaChanged(){
		OpportunityService opportunitySerivce = OpportunityService.getInstance();
		List<Opportunity> filteredOpportunities = new List<Opportunity>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oldOpp = this.oldMap.get(opp.Id);
			if (oldOpp.Quota__c != opp.Quota__c && opp.Quota__c == 'Foreign'){
				filteredOpportunities.add(opp);
			}
		}
		if (!filteredOpportunities.isEmpty()){
			Map<Id,Boolean> validateResultMapByOppId = opportunitySerivce.validateIsQuotaAreaExceed(filteredOpportunities);
			for (Opportunity opp : filteredOpportunities){
				Boolean isPassValidate = validateResultMapByOppId.get(opp.Id);
				if (!isPassValidate){
					opp.addError('The quota cannot be changed because it would cause the Foreign Quota Area of this project to exceed 49%.');
				}
			}
		}
	}

	/**
	 * Phase2
	 * Details:
	 * - Add logic to validate if new co owner changing allowed
	 */
	private void validateNewCoOwnerChanged(){
		OpportunityService opportunitySerivce = OpportunityService.getInstance();
		List<Opportunity> filteredOpportunities = new List<Opportunity>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oldOpp = this.oldMap.get(opp.Id);
			if (opp.NewCoOwner__c != null && oldOpp.NewCoOwner__c != opp.NewCoOwner__c && opp.NewCoOwnerNationality__c != 'Thai'){
				filteredOpportunities.add(opp);
			}
		}
		if (!filteredOpportunities.isEmpty()){
			Map<Id,Boolean> validateResultMapByOppId = opportunitySerivce.validateIsQuotaAreaExceed(filteredOpportunities);
			for (Opportunity opp : filteredOpportunities){
				Boolean isPassValidate = validateResultMapByOppId.get(opp.Id);
				if (!isPassValidate){
					opp.addError('The quota cannot be changed because it would cause the Foreign Quota Area of this project to exceed 49%.');
				}
			}
		}
	}

	/**
	 * Phase2
	 * Details:
	 * - Add logic to validate if new co owner changing allowed
	 */
	private void validateOutstandingAmount(){
		OpportunityService opportunitySerivce = OpportunityService.getInstance();
		List<Opportunity> filteredOpportunities = new List<Opportunity>();
		List<Id> filteredOpportunitieIds = new List<Id>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oldOpp = this.oldMap.get(opp.Id);
			if (oldOpp.NewCoOwner__c != opp.NewCoOwner__c){
				filteredOpportunitieIds.add(opp.Id);
			}
		}
		if (!filteredOpportunitieIds.isEmpty()){
			Map<Id,Boolean> outstandingPaymentResultMapByOppId = opportunitySerivce.checkHasOutstandingPayment(filteredOpportunitieIds);
			for (Opportunity opp : filteredOpportunities){
				Boolean hasOutstandingPayment = outstandingPaymentResultMapByOppId.get(opp.Id);
				if (hasOutstandingPayment){
					opp.addError('New Co Owner cannot be modified due to existing unpaid payments.');
				}
			}
		}
	}

	/**
	 * Phase2
	 * Details:
	 * - Add logic to stamp PaymentPortalToken__c when Account changed
	 */
	private void stampPaymentPortalTokenAfterAccountChanged(){
		OpportunityService service = OpportunityService.getInstance();
		service.generateAndStampPortalToken(this.newRecords);
		List<Opportunity> filteredOpportunities = new List<Opportunity>();
		for (Opportunity opportunity : this.newRecords){
			Opportunity oldOpportunity = this.oldMap.get(opportunity.Id);
			if (oldOpportunity.AccountId != opportunity.AccountId){
				filteredOpportunities.add(opportunity);
			}
		}
		if (!filteredOpportunities.isEmpty()){
			service.generateAndStampPortalToken(filteredOpportunities);
		}
	}

	/**
	 * Phase2
	 * Details:
	 * - Add logic to stamp Novation Fee when Project Changed
	 */
	private void stampDefaultNovationFeeBeforeUpdate(){
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> filteredOpportunities = new List<Opportunity>();
		for (Opportunity opportunity : this.newRecords){
			Opportunity oldOpportunity = this.oldMap.get(opportunity.Id);
			if (oldOpportunity.Project__c != opportunity.Project__c){
				filteredOpportunities.add(opportunity);
			}
		}
		if (!filteredOpportunities.isEmpty()){
			service.stampDefaultNovationFeeFromProject(filteredOpportunities);
		}
	}


	/**
	 * Phase2
	 * Details:
	 * - Add logic to validate if stage can be change to Reservation
	 */
	private void validateAbleToChangeStageToReservation(){
		OpportunityPaymentService oppPaymentService = OpportunityPaymentService.getInstance();
		List<Opportunity> filteredOpportunities = new List<Opportunity>();
		for (Opportunity opportunity : this.newRecords){
			Opportunity oldOpportunity = this.oldMap.get(opportunity.Id);
			if (oldOpportunity.StageName != opportunity.StageName && opportunity.StageName == GlobalConstants.OPP_STAGENAME_RESERVATION){
				filteredOpportunities.add(opportunity);
			}
		}
		if (!filteredOpportunities.isEmpty()){
			Map<Id, Map<String,String>> oppPaymentStatusMapByOppId = oppPaymentService.getOppPaymentStatusMapByOppId(filteredOpportunities);
			for (Opportunity opportuntiy : filteredOpportunities){
				Map<String,String> oppPaymentStatusMapByTerm = oppPaymentStatusMapByOppId.get(opportuntiy.Id);
				String reservationStatus  = oppPaymentStatusMapByTerm.get(GlobalConstants.OPP_STAGENAME_RESERVATION);
				if (reservationStatus != GlobalConstants.OPP_PAYMENT_STATUS_FULLYPAID){
					opportuntiy.addError('The stage cannot be changed to Reservation because the reservation payment has not been fully paid');
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

	/**
	 * Phase2
	 * Details:
	 * - modify logic to filter opp which stage is closed lost and lost reason is because of upgrade/downgrade/move payment
	 */
	private void changeUnitStageToBookOrSold() {
		Product2Service service = Product2Service.getInstance();
		List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oppOldRecord = this.oldMap.get(opp.Id);
			if (
				(oppOldRecord.StageName != opp.StageName) &&
				(opp.StageName == STAGE_NAME_RESERVATION ||
				opp.StageName == STAGE_NAME_TRANSFERRED ||
				opp.StageName == STAGE_NAME_CONTRACT ||
				// Phase2: add criteria
				(opp.StageName == STAGE_NAME_CLOSED_LOST && opp.LossReason__c == GlobalConstants.OPP_LOST_REASON_UPGRADE) ||
				(opp.StageName == STAGE_NAME_CLOSED_LOST && opp.LossReason__c == GlobalConstants.OPP_LOST_REASON_DOWNGRADE) ||
				(opp.StageName == STAGE_NAME_CLOSED_LOST && opp.LossReason__c == GlobalConstants.OPP_LOST_REASON_MOVEPAYMENT) ||
				(opp.StageName == STAGE_NAME_CLOSED_LOST && opp.LossReason__c == GlobalConstants.OPP_LOST_REASON_CANCELFORFEIT) ||
				(opp.StageName == STAGE_NAME_CLOSED_LOST && opp.LossReason__c == GlobalConstants.OPP_LOST_REASON_TERMINATIONFORFEIT) ||
				(opp.StageName == STAGE_NAME_CLOSED_LOST && opp.LossReason__c == GlobalConstants.OPP_LOST_REASON_CANCELREFUND) ||
				(opp.StageName == STAGE_NAME_CLOSED_LOST && opp.LossReason__c == GlobalConstants.OPP_LOST_REASON_TERMINATIONREFUND) )
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


	/**
	 * Phase2
	 * Details:
	 * - Modify logic to bypass changing unit status to available when opportunity lost reason is Novation
	 */
	private void changeUnitStatusBackToAvailable() {
		Product2Service service = Product2Service.getInstance();
		List<Opportunity> filteredOpportunities = new List<Opportunity>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oppOldRecord = this.oldMap.get(opp.Id);
			if (
				(oppOldRecord.StageName != opp.StageName) &&
				(opp.StageName == STAGE_NAME_CLOSED_LOST) &&
				(opp.LossReason__c != GlobalConstants.OPP_LOST_REASON_NOVATION &&
				opp.LossReason__c != GlobalConstants.OPP_LOST_REASON_UPGRADE &&
				opp.LossReason__c != GlobalConstants.OPP_LOST_REASON_DOWNGRADE &&
				opp.LossReason__c != GlobalConstants.OPP_LOST_REASON_MOVEPAYMENT &&
				opp.LossReason__c != GlobalConstants.OPP_LOST_REASON_CANCELFORFEIT &&
				opp.LossReason__c != GlobalConstants.OPP_LOST_REASON_TERMINATIONFORFEIT &&
				opp.LossReason__c != GlobalConstants.OPP_LOST_REASON_CANCELREFUND &&
				opp.LossReason__c != GlobalConstants.OPP_LOST_REASON_TERMINATIONREFUND
				)
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

	/**
	 * Phase2
	 * Details:
	 * - Modify logic to stamp CancelReason__c in Invoice and PaymentReceipt grouping from Opportunity.LossReason__c
	 * - Modify logic to cancel Invoice and Receipt just in case Opportunity is closed with all reasons except Novation
	 */
	private void cancelInvoiceAndReceiptAfterOppClosedLost() {
		PaymentReceiptTriggerHandler paymentReceiptTriggerHandler = PaymentReceiptTriggerHandler.getInstance();
		Set<Id> filteredOppIdSet = new Set<Id>();
		for (Opportunity opp : this.newRecords) {
			Opportunity oppOldRecord = this.oldMap.get(opp.Id);
			// Phase2: add condition to filter just opp.LossReason__c != 'Novation'
			if (oppOldRecord.StageName != opp.StageName && opp.StageName == STAGE_NAME_CLOSED_LOST && opp.LossReason__c != GlobalConstants.OPP_LOST_REASON_NOVATION) {
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

	/**
	 * Phase2
	 * Details:
	 * - Add logic to create OpportunityAccountChangeLog__c record
	 */
	private void createOpportunityAccountChangeLogAfterAccountChanged(){
		PaymentReceiptService receiptService = PaymentReceiptService.getInstance();
		OpportunityAccountChangeLogService oppAccChangeLogService = OpportunityAccountChangeLogService.getInstance();
		List<OpportunityAccountChangeLog__c> oppAccChangeLogs = new List<OpportunityAccountChangeLog__c>();
		for (Opportunity opportunity : this.newRecords){
			Opportunity oldOpportunity = this.oldMap.get(opportunity.Id);
			if (oldOpportunity.AccountId != opportunity.AccountId){
				OpportunityAccountChangeLog__c oppAccChangeLog = oppAccChangeLogService.craeteOpportunityAccountChangeLogFromPreviousAndCurrentOpportunity(oldOpportunity,opportunity);
				oppAccChangeLogs.add(oppAccChangeLog);
			}
		}
		if (!oppAccChangeLogs.isEmpty()){
			insert oppAccChangeLogs;
			Set<Id> oppAccChangeLogIds = new Set<Id>();
			for (OpportunityAccountChangeLog__c oppAccChangeLog : oppAccChangeLogs){
				oppAccChangeLogIds.add(oppAccChangeLog.Id);
			}
			List<PaymentReceipt__c> snapshotReceipts = receiptService.lookupPaymentReceiptToOpportunityAccountChangeLog(oppAccChangeLogIds);
			if (!snapshotReceipts.isEmpty()){
				update snapshotReceipts;
			}
		}

	}
	// ----- end after update -----




}