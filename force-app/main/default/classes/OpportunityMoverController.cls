/**
 * Phase2
 * Details:
 * - Init Controller for opportunityMover
 */
public class OpportunityMoverController {

	/**
	 * Phase2
	 * Details:
	 * - add method to return OpportunityDetails to lwc
	 */
    @AuraEnabled
    public static OpportunityDetails getOpportunityDetails(Id opportunityId) {
		try {
			OpportunitySelector oppSelector = OpportunitySelector.getInstance();
			Map<Id, Opportunity> opportunityMapById = oppSelector.getOpportuntiyWithRelatedRecordForNovationMapById(new Set<Id>{opportunityId});
			Opportunity targetOpp = opportunityMapById.get(opportunityId);
			OpportunityDetails oppDetails = new OpportunityDetails(targetOpp);
			return oppDetails;
		} catch (Exception e) {
			System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
		}
	}

	/**
	 * Phase2
	 * Details:
	 * - add method to perform complete
	 */
	@AuraEnabled
	public static MoveOpportunityResult completeAction(
		Id currentOpportunityId,
		String action,
		String moveReason,
		Decimal operationFee,
		Decimal receivedAmount,
		String url,
		String newOpportunityItemJSON,
		PaymentMethod__c paymentMethod,
		List<Id> selectedPromotionAndClientOfferIds,
		Boolean isFirstTime
		)
	{
		Savepoint sp = Database.setSavepoint();
		try {
			MoveOpportunityResult result = new MoveOpportunityResult();
			// ----- SERVICE -----
			OpportunityPaymentService oppPaymentService = OpportunityPaymentService.getInstance();
			PaymentReceiptService paymentReceiptService = PaymentReceiptService.getInstance();
			ContractService contractService = ContractService.getInstance();
			OpportunityService oppService = OpportunityService.getInstance();
			UpgradeDowngradeMovePaymentService upgradeDowngradeMovePaymentService = UpgradeDowngradeMovePaymentService.getInstance();
			// ----- SELECTOR -----
            OpportunityPaymentSelector oppPaymentSelector = OpportunityPaymentSelector.getInstance();
			OpportunitySelector oppSelector = OpportunitySelector.getInstance();
			// ----- Deserialized -----
			NewOpportunityItem newOpportunityItem =
				(NewOpportunityItem) JSON.deserialize(newOpportunityItemJSON, NewOpportunityItem.class);
			// ----- Get Map -----
			Map<Id, Opportunity> oppMapById = oppSelector.getOpportuntiyWithRelatedRecordForNovationMapById(new Set<Id>{currentOpportunityId,newOpportunityItem.opportunityId});
			Map<Id, List<OpportunityPayment__c>> opportunityPaymentMapByOppId = oppPaymentSelector.getOpportunityPaymentsWithInvoiceLineItemMapByOppId(
                new Set<Id>{newOpportunityItem.opportunityId}
            );
			// ----- STEP 1: Update Old Opp to Close Lost -> Cancel all Invoices and Receipts -> change Unit Status to Block
			Opportunity oldOpp = oppMapById.get(currentOpportunityId);
			Opportunity newOpp = oppMapById.get(newOpportunityItem.opportunityId);
			if (isFirstTime){
				Opportunity closedOldOpp = oppService.getOpportunityAfterMovingProcess(oldOpp,newOpp,action);
				update closedOldOpp;
				result.currentOpportunity = closedOldOpp;
			} else {
				result.currentOpportunity = oldOpp;
			}
			Opportunity updatedNewOpp = oppService.getNewOpportunityAfterMovingProcess(oldOpp,newOpp,action);
			update updatedNewOpp;
			result.newOpportunity = updatedNewOpp;
			// ----- STEP 2: Create Promotion Opportunity and Client Offer
			List<PromotionOpportunity__c> promotionOldOpps = oldOpp.Promotion_Transactions__r;
			List<PromotionOpportunity__c> clonedPromotionOpps = new List<PromotionOpportunity__c>();
			for (PromotionOpportunity__c promotionOldOpp : promotionOldOpps){
				if (selectedPromotionAndClientOfferIds.contains(promotionOldOpp.Id)){
					PromotionOpportunity__c clonedRecord = promotionOldOpp.clone(false,false,false,false);
					clonedRecord.Opportunity__c = updatedNewOpp.Id;
					clonedPromotionOpps.add(clonedRecord);
				}
			}
			List<ClientOffer__c> clientOffersOldOpps = oldOpp.Client_Offers__r;
			List<ClientOffer__c> clonedClientOffersOldOpps = new List<ClientOffer__c>();
			for (ClientOffer__c clientOfferOldOpp : clientOffersOldOpps){
				if (selectedPromotionAndClientOfferIds.contains(clientOfferOldOpp.Id)){
					ClientOffer__c clonedRecord = clientOfferOldOpp.clone(false,false,false,false);
					clonedRecord.Opportunity__c = updatedNewOpp.Id;
					clonedClientOffersOldOpps.add(clonedRecord);
				}
			}
			if (!clonedPromotionOpps.isEmpty()){
				insert clonedPromotionOpps;
			}
			result.clonedPromotionOpps = clonedPromotionOpps;
			if (!clonedClientOffersOldOpps.isEmpty()){
				insert clonedClientOffersOldOpps;
			}
			result.clonedClientOffers = clonedClientOffersOldOpps;
			// ----- STEP 3: Update Contract under old opp to Cancel
			if (isFirstTime){
				List<Contract> contracts = oldOpp.Contracts__r;
				List<Contract> canceledContracts = contractService.getContractAfterMovingProcess(contracts, action);
				update canceledContracts;
				result.contracts = canceledContracts;
			}
			// ----- STEP 4: Generate Receipt from Moving Amount
			PaymentReceipt__c paymentReceipt = paymentReceiptService.generateMovingPaymentReceiptRelatedToOpportunity(newOpportunityItem.opportunityId,currentOpportunityId);
			if (oldOpp.Unit__r.ProductCode == newOpp.Unit__r.ProductCode){
				paymentReceipt.ReceiptType__c = GlobalConstants.RECEIPT_TYPE_MOVEPAYMENTNOOPERATION;
			}
			insert paymentReceipt;
			PaymentReceipt__c paymentReceiptWithRunningNo = paymentReceiptService.generateRunningNo(paymentReceipt);
			update paymentReceiptWithRunningNo;
			result.receipt = paymentReceiptWithRunningNo;
			paymentMethod.PaymentReceipt__c = paymentReceipt.Id;
			insert paymentMethod;
			result.paymentMethod = paymentMethod;
            List<OpportunityPayment__c> oppPayments = opportunityPaymentMapByOppId.get(newOpportunityItem.opportunityId);
			List<PaymentReceiptLineItem__c> paymentReceiptLineItems = paymentReceiptService.generatePaymentReceiptLineItemFromTotalReceivedAmount(receivedAmount,oppPayments,paymentReceipt.Id,paymentMethod.Id);
            insert paymentReceiptLineItems;
			result.receiptLine = paymentReceiptLineItems;
			List<OpportunityPayment__c> updatedOppPayments = oppPaymentService.stampFieldFromReceiptLineItem(paymentReceiptLineItems);
            update updatedOppPayments;
			result.oppPayments = updatedOppPayments;
			// ----- STEP 4.2: Generate Operation Fee Receipt
			if (isFirstTime){
				if (operationFee != null && operationFee != 0){
					PaymentReceipt__c operationPaymentReceipt = paymentReceiptService.generateOperationPaymentReceiptRelatedToOpportunity(currentOpportunityId,'move_payment');
					operationPaymentReceipt.CustomGLKey__c = paymentReceipt.CustomGLKey__c;
					operationPaymentReceipt.CustomGLDate__c = Date.today();
					insert operationPaymentReceipt;
					PaymentReceipt__c operationPaymentReceiptWithRunningNo = paymentReceiptService.generateRunningNo(operationPaymentReceipt);
					update operationPaymentReceiptWithRunningNo;
					List<PaymentReceiptLineItem__c> operationPaymentReceiptLineItems = paymentReceiptService.generateOperationPaymentReceiptLineItem(operationFee,operationPaymentReceipt.Id,null,null);
					insert operationPaymentReceiptLineItems;
				}
			}
			// ----- STEP 5: Generate UpgradeDowngradeMovePayment__c
			UpgradeDowngradeMovePayment__c upgradeDowngradeOppPayment = upgradeDowngradeMovePaymentService.generateUpgradeDowngradeMovePayment(action,oldOpp,updatedNewOpp,url,operationFee,moveReason);
			insert upgradeDowngradeOppPayment;
			result.upgradeDowngradeMovePayment = upgradeDowngradeOppPayment;
			return result;
		} catch (Exception e) {
			Database.rollback(sp);
			System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
			throw new applicationException('You cant do that here: ' + e.getStackTraceString() + ' ' + e.getMessage());
			// throw new AuraHandledException('Error in completeAction: ' + e.getMessage() + ' ' + e.getStackTraceString());
		}
	}

	/**
	 * Phase2
	 * Details:
	 * - add method to insert Task
	 */
	@AuraEnabled
	public static MoveOpportunityResult insertTask(String taskItemJSON) {
		Savepoint sp = Database.setSavepoint();
		try {
			MoveOpportunityResult result = new MoveOpportunityResult();
			TaskService taskService = TaskService.getInstance();
			List<TaskItem> taskItems = (List<TaskItem>) JSON.deserialize(taskItemJSON, List<TaskItem>.class);
			List<Task> tasks = new List<Task>();
			for (TaskItem taskItem : taskItems){
				Task task = taskService.generateTask(taskItem.subject, taskItem.description, taskItem.oppId);
				tasks.add(task);
			}
			insert tasks;
			result.tasks = tasks;
			return result;
		} catch (Exception e) {
			Database.rollback(sp);
			System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
			throw new applicationException('You cant do that here: ' + e.getStackTraceString() + ' ' + e.getMessage());
			// throw new AuraHandledException('Error in completeAction: ' + e.getMessage());
		}
	}

	/**
	 * Phase2
	 * Details:
	 * - add method to check outstanding payment
	 */
	@AuraEnabled
	public static Boolean hasOutstandingPayments(List<Id> opportunityIds) {
		try {
			List<OpportunityPayment__c> unpaidPayments = [
				SELECT Id
				FROM OpportunityPayment__c
				WHERE Opportunity__c IN :opportunityIds
				AND DueDate__c <= :Date.today()
				AND PaymentStatus__c != 'Fully Paid'
				AND IsMasterData__c = TRUE
			];
			return !unpaidPayments.isEmpty();
		} catch (Exception e) {
			throw new AuraHandledException('Error validating payment statuses: ' + e.getMessage());
		}
	}


	public class OpportunityDetails {
		@AuraEnabled public String opportunityName;
		@AuraEnabled public String projectName;
		@AuraEnabled public String unitName;
		@AuraEnabled public String unitCode;
		@AuraEnabled public Decimal netPrice;
		@AuraEnabled public Decimal totalPaidAmount;
		@AuraEnabled public List<PromotionOpportunity> opportunityPromotions;
        @AuraEnabled public List<ClientOffer> clientOffers;
        @AuraEnabled public List<ReceivedPromotion> receivedPromotions;
		@AuraEnabled public String stageName;

		public OpportunityDetails(Opportunity opportunity){
			this.opportunityName = opportunity.Name;
			this.projectName = opportunity.Project__r.Name;
			this.unitName = opportunity.Unit__r.Name;
			this.unitCode = opportunity.Unit__r.ProductCode;
			this.netPrice = opportunity.NetPrice__c;
			this.totalPaidAmount = opportunity.TotalPaidAmount__c;
			this.stageName = opportunity.StageName;
			this.opportunityPromotions = new List<PromotionOpportunity>();
			this.clientOffers = new List<ClientOffer>();
			this.receivedPromotions = new List<ReceivedPromotion>();
			List<PromotionOpportunity__c> targetOppPromotions = opportunity.Promotion_Transactions__r;
			List<ClientOffer__c> targetClientOffers = opportunity.Client_Offers__r;
			for (PromotionOpportunity__c targetOppPromotion : targetOppPromotions){
				this.opportunityPromotions.add(new PromotionOpportunity(targetOppPromotion));
				if (targetOppPromotion.Status__c == 'Received'){
					this.receivedPromotions.add(new ReceivedPromotion(targetOppPromotion.Id, targetOppPromotion.PromotionMaster__r.Name));
				}
			}
			for (ClientOffer__c targetClientOffer : targetClientOffers){
				this.clientOffers.add(new ClientOffer(targetClientOffer));
				if (targetClientOffer.Status__c == 'Received'){
					this.receivedPromotions.add(new ReceivedPromotion(targetClientOffer.Id, targetClientOffer.PromotionMaster__r.Name));
				}
			}
		}
	}

	public class PromotionOpportunity {
		@AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
		@AuraEnabled public String type;
		@AuraEnabled public Boolean isReceived;

		public PromotionOpportunity(PromotionOpportunity__c promotionOpportunity){
			this.id = promotionOpportunity.Id;
			this.name = promotionOpportunity.PromotionMaster__r.Name;
			this.status = promotionOpportunity.Status__c;
			this.type = 'Promotion';
			this.isReceived = promotionOpportunity.Status__c == 'Received';
		}
	}

	public class ClientOffer {
		@AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
		@AuraEnabled public String type;
		@AuraEnabled public Boolean isReceived;

		public ClientOffer(ClientOffer__c clientOffer){
			this.id = clientOffer.Id;
			this.name = clientOffer.PromotionMaster__r.Name;
			this.status = clientOffer.Status__c;
			this.type = 'ClientOffer';
			this.isReceived = clientOffer.Status__c == 'Received';
		}
	}

	public class ReceivedPromotion {
		@AuraEnabled public Id id;
		@AuraEnabled public String name;

		public ReceivedPromotion(Id promotionId ,String name){
			this.id = promotionId;
			this.name = name;
		}
	}

	public class NewOpportunityItem {
		@AuraEnabled public Id opportunityId;
		@AuraEnabled public Decimal amountToMove;
	}

	public class TaskItem {
		@AuraEnabled public Id oppId;
		@AuraEnabled public String subject;
		@AuraEnabled public String description;
	}

	public class MoveOpportunityResult {
		@AuraEnabled public Opportunity currentOpportunity;
		@AuraEnabled public Opportunity newOpportunity;
		@AuraEnabled public List<PromotionOpportunity__c> clonedPromotionOpps;
		@AuraEnabled public List<ClientOffer__c> clonedClientOffers;
		@AuraEnabled public List<Contract> contracts;
		@AuraEnabled public PaymentReceipt__c receipt;
		@AuraEnabled public List<PaymentReceiptLineItem__c> receiptLine;
		@AuraEnabled public PaymentMethod__c paymentMethod;
		@AuraEnabled public List<OpportunityPayment__c> oppPayments;
		@AuraEnabled public UpgradeDowngradeMovePayment__c upgradeDowngradeMovePayment;
		@AuraEnabled public List<Task> tasks;
	}

	public class applicationException extends Exception {}
}