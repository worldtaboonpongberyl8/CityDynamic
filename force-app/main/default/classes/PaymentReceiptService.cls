public without sharing class PaymentReceiptService {
	public static PaymentReceiptService instance;
	public static PaymentReceiptService getInstance() {
		if (instance == null) {
			instance = new PaymentReceiptService();
		}
		return instance;
	}

	/**
	 * Phase2
	 * Details:
	 * - Modify logic to stamp CoBuyerName__c and CoBuyerAccountCode__c to Receipt
	 */
	public PaymentReceipt__c generatePaymentReceiptRelatedToOpportunity(Id opportunityId) {
		CoBuyerService coBuyerService = CoBuyerService.getInstance();
		OpportunitySelector selector = OpportunitySelector.getInstance();
		Map<Id, Opportunity> targetOppMapById = selector.getOpportunityWithCoBuyerMapById(new Set<Id>{opportunityId});
		Opportunity targetOpp = targetOppMapById.get(opportunityId);
		// Phase2: call service to get string of Account Code
		List<CoBuyer__c> coBuyers = targetOpp.Co_Borrowers__r;
		String coBuyerAccountCodeString = coBuyerService.getStringCoBuyerAccountCode(coBuyers);
		PaymentReceipt__c paymentReceipt = new PaymentReceipt__c();
		paymentReceipt.Opportunity__c = opportunityId;
		paymentReceipt.AccountAddress__c = targetOpp.Account.AddressEN__c;
		// Phase2: stamp CoBuyerName__c and CoBuyerAccountCode__c
		paymentReceipt.CoBuyerName__c = targetOpp.CoBuyerName__c;
		paymentReceipt.CoBuyerAccountCode__c = coBuyerAccountCodeString;
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

	/**
	 * Phase2
	 * Details:
	 * - Modify logic to stamp CancelReason__c from Opportunity.LossReason__c
	 */
	public List<PaymentReceipt__c> getCancelPaymentReceiptByOppIdSet(Set<Id> oppIdSet){
		List<PaymentReceipt__c> receiptForCancels = new List<PaymentReceipt__c>();
		List<PaymentReceipt__c> receipts = PaymentReceiptSelector.getInstance().getByOppIdSet(oppIdSet);
		for (PaymentReceipt__c receipt : receipts) {
			String oppLostReason = receipt.Opportunity__r.LossReason__c;
			String receiptLostReason = GlobalConstants.INVOICE_RECEIPT_LOST_REASON_MAP_BY_OPP_LOST_REASON.get(oppLostReason);
			receiptForCancels.add(
				new PaymentReceipt__c(
					Id = receipt.Id,
					// IsCancel__c = true,
					CancelReason__c = receiptLostReason == null ? 'Closed Lost' : receiptLostReason
				)
			);
		}
		return receiptForCancels;
	}

	/**
	 * Phase2
	 * Details:
	 * - add logic to create Payment Receipt for Novation Fee
	 * - stamp CoBuyerName__c and CoBuyerAccountCode__c
	 */
	public PaymentReceipt__c generateNovationPaymentReceiptRelatedToOpportunity(Id opportunityId) {
		CoBuyerService coBuyerService = CoBuyerService.getInstance();
		OpportunitySelector selector = OpportunitySelector.getInstance();
		Map<Id, Opportunity> targetOppMapById = selector.getOpportunityWithCoBuyerMapById(new Set<Id>{opportunityId});
		Opportunity targetOpp = targetOppMapById.get(opportunityId);
		List<CoBuyer__c> coBuyers = targetOpp.Co_Borrowers__r;
		String coBuyerAccountCodeString = coBuyerService.getStringCoBuyerAccountCode(coBuyers);
		PaymentReceipt__c paymentReceipt = new PaymentReceipt__c();
		paymentReceipt.Opportunity__c = opportunityId;
		paymentReceipt.AccountAddress__c = targetOpp.Account.AddressEN__c;
		paymentReceipt.ReceiptType__c = GlobalConstants.RECEIPT_TYPE_NOVATION;
		paymentReceipt.NovationDate__c = targetOpp.NovationDate__c;
		paymentReceipt.CoBuyerName__c = targetOpp.CoBuyerName__c;
		paymentReceipt.CoBuyerAccountCode__c = coBuyerAccountCodeString;
		return paymentReceipt;
	}

	/**
	 * Phase2
	 * Details:
	 * - add logic to create Payment Receipt Line Item for type Novation Fee
	 */
	public List<PaymentReceiptLineItem__c> generateNovationPaymentReceiptLineItem(
		Decimal totalRecievedAmount,
		Id paymentReceiptId,
		Id paymentMethodId
	) {
		List<PaymentReceiptLineItem__c> receiptLineItems = new List<PaymentReceiptLineItem__c>();
		PaymentReceiptLineItem__c receiptLineItem = new PaymentReceiptLineItem__c();
		receiptLineItem.LineNumber__c = 1;
		receiptLineItem.ReceivedAmount__c = totalRecievedAmount;
		receiptLineItem.PreviousRemaining__c = 0;
		receiptLineItem.ReceiptLineItemType__c = 'Operation';
		receiptLineItem.PaymentReceipt__c = paymentReceiptId;
		receiptLineItem.Status__c = 'Fully Paid';
		receiptLineItem.PaymentMethod__c = paymentMethodId;
		receiptLineItem.RemainingAmount__c = 0;
		receiptLineItems.add(receiptLineItem);
		return receiptLineItems;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add new method to re-lookup PaymentReceipt to new OpportunityAccountChangeLog__c
	 * - assign CustomGLKey__c , CustomGLDate__c
	 */
	public List<PaymentReceipt__c> lookupPaymentReceiptToOpportunityAccountChangeLog(Set<Id> opportunityAccountChangeLogIds){
		List<PaymentReceipt__c> paymentReceipts = new List<PaymentReceipt__c>();
		PaymentReceiptSelector paymentReceiptSelector = PaymentReceiptSelector.getInstance();
		OpportunityAccountChangeLogSelector oppAccChangeLogSelector = OpportunityAccountChangeLogSelector.getInstance();
		Map<Id,OpportunityAccountChangeLog__c> opportunityAccountChangeLogWithSnapshotReceipts = oppAccChangeLogSelector.getOpportunityAccountChangeLogWithSnapshotReceipts(opportunityAccountChangeLogIds);
		Set<Id> previousAccountIds = new Set<Id>();
		for (Id oppAccChangeLogId : opportunityAccountChangeLogWithSnapshotReceipts.keySet()){
			OpportunityAccountChangeLog__c targetOppAccChangeLog = opportunityAccountChangeLogWithSnapshotReceipts.get(oppAccChangeLogId);
			previousAccountIds.add(targetOppAccChangeLog.PreviousAccount__c);
		}
		Map<Id,OpportunityAccountChangeLog__c> opportunityAccountChangeLogFromPreviousOpportuntiyIdMapById = oppAccChangeLogSelector.getOpportunityAccountChangeLogFromPreviousOpportuntiyIdMapByPreviousAccountId(previousAccountIds);
		Set<Id> previousOppIds = new Set<Id>();
		for (Id oppAccChangeLogId : opportunityAccountChangeLogWithSnapshotReceipts.keySet()){
			OpportunityAccountChangeLog__c targetOppAccChangeLog = opportunityAccountChangeLogWithSnapshotReceipts.get(oppAccChangeLogId);
			previousOppIds.add(targetOppAccChangeLog.PreviousOpportunity__c);
		}
		List<PaymentReceipt__c> receiptsRelatedWithOpportunity = paymentReceiptSelector.getByOppIdSet(previousOppIds);
		Set<Id> receiptIds = new Set<Id>();
		for (Id oppAccChangeLogId : opportunityAccountChangeLogWithSnapshotReceipts.keySet()){
			OpportunityAccountChangeLog__c targetOppAccChangeLog = opportunityAccountChangeLogWithSnapshotReceipts.get(oppAccChangeLogId);
			for (PaymentReceipt__c receipt : receiptsRelatedWithOpportunity){
				if (receipt.Opportunity__c == targetOppAccChangeLog.PreviousOpportunity__c){
					if (receipt.ReceiptType__c != GlobalConstants.RECEIPT_TYPE_NOVATION){
						receipt.OpportunityAccountChangeLog__c = targetOppAccChangeLog.Id;
						receipt.CustomGLKey__c = 'RP_GL_' + targetOppAccChangeLog.PreviousAccount__r.AccountCode__c + '_' + targetOppAccChangeLog.CurrentOpportunity__r.Project__r.ProjectCode__c + '_' + targetOppAccChangeLog.CurrentOpportunity__r.Unit__r.ProductCode;
						receipt.CustomGLDate__c = Date.today();
						paymentReceipts.add(receipt);
						receiptIds.add(receipt.Id);
					}
				}
			}
		}
		if (!opportunityAccountChangeLogFromPreviousOpportuntiyIdMapById.isEmpty()){
			for (Id oppAccChangeLogId : opportunityAccountChangeLogWithSnapshotReceipts.keySet()){
				OpportunityAccountChangeLog__c targetOppAccChangeLog = opportunityAccountChangeLogWithSnapshotReceipts.get(oppAccChangeLogId);
				OpportunityAccountChangeLog__c previousOpportunityAccountChangeLog = opportunityAccountChangeLogFromPreviousOpportuntiyIdMapById.get(targetOppAccChangeLog.PreviousAccount__c);
				List<PaymentReceipt__c> relatedReceipts = previousOpportunityAccountChangeLog.PaymentReceipts__r ;
				for (PaymentReceipt__c receipt : relatedReceipts){
					if (receiptIds.contains(receipt.Id)){
						continue;
					}
					if (receipt.ReceiptType__c != GlobalConstants.RECEIPT_TYPE_NOVATION){
						System.debug('www receipt: ' + receipt);
						receipt.OpportunityAccountChangeLog__c = targetOppAccChangeLog.Id;
						receipt.CustomGLKey__c = 'RP_GL_' + targetOppAccChangeLog.PreviousAccount__r.AccountCode__c + '_' + targetOppAccChangeLog.CurrentOpportunity__r.Project__r.ProjectCode__c + '_' + targetOppAccChangeLog.CurrentOpportunity__r.Unit__r.ProductCode;
						receipt.CustomGLDate__c = Date.today();
						paymentReceipts.add(receipt);
					}
				}
			}
 		}
		System.debug('www paymentReceipts: ' + paymentReceipts);
		return paymentReceipts;
	}

	/**
	 * Phase2
	 * Details:
	 * - add logic to create Payment Receipt for Upgrade/Downgrade/MovePayment
	 * - stamp CoBuyerName__c and CoBuyerAccountCode__c
	 * - assign CustomGLKey__c
	 */
	public PaymentReceipt__c generateMovingPaymentReceiptRelatedToOpportunity(Id newOpportunityId,Id oldOpportunityId) {
		CoBuyerService coBuyerService = CoBuyerService.getInstance();
		OpportunitySelector selector = OpportunitySelector.getInstance();
		Map<Id, Opportunity> targetOppMapById = selector.getOpportuntiyWithRelatedRecordForNovationMapById(new Set<Id>{newOpportunityId,oldOpportunityId});
		Opportunity targetOpp = targetOppMapById.get(newOpportunityId);
		Opportunity oldOpp = targetOppMapById.get(oldOpportunityId);
		List<CoBuyer__c> coBuyers = targetOpp.Co_Borrowers__r;
		String coBuyerAccountCodeString = coBuyerService.getStringCoBuyerAccountCode(coBuyers);
		PaymentReceipt__c paymentReceipt = new PaymentReceipt__c();
		paymentReceipt.Opportunity__c = newOpportunityId;
		paymentReceipt.AccountAddress__c = targetOpp.Account.AddressEN__c;
		paymentReceipt.ReceiptType__c = GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT;
		paymentReceipt.CoBuyerName__c = targetOpp.CoBuyerName__c;
		paymentReceipt.CoBuyerAccountCode__c = coBuyerAccountCodeString;
		paymentReceipt.PreviousCustomerCode__c = oldOpp.Unit__r.ProductCode == targetOpp.Unit__r.ProductCode ? oldOpp.Account.AccountCode__c : null;
		paymentReceipt.CustomGLKey__c = oldOpp.Unit__r.ProductCode == targetOpp.Unit__r.ProductCode ?
		'RP_GL_' + oldOpp.Account.AccountCode__c + '_' + targetOpp.Project__r.ProjectCode__c + '_' + oldOpp.Unit__r.ProductCode :
		'RP_GL_' + targetOpp.Account.AccountCode__c + '_' + oldOpp.Project__r.ProjectCode__c + '_' + oldOpp.Unit__r.ProductCode;
		paymentReceipt.CustomGLDate__c = Date.today();
		return paymentReceipt;
	}

	/**
	 * Phase2
	 * Details:
	 * - add logic to create Payment Receipt for Operation Fee (Move Payment + Refund)
	 */
	public PaymentReceipt__c generateOperationPaymentReceiptRelatedToOpportunity(Id opportunityId , String type) {
		CoBuyerService coBuyerService = CoBuyerService.getInstance();
		OpportunitySelector selector = OpportunitySelector.getInstance();
		Map<Id, Opportunity> targetOppMapById = selector.getOpportunityWithCoBuyerMapById(new Set<Id>{opportunityId});
		Opportunity targetOpp = targetOppMapById.get(opportunityId);
		List<CoBuyer__c> coBuyers = targetOpp.Co_Borrowers__r;
		String coBuyerAccountCodeString = coBuyerService.getStringCoBuyerAccountCode(coBuyers);
		PaymentReceipt__c paymentReceipt = new PaymentReceipt__c();
		paymentReceipt.Opportunity__c = opportunityId;
		paymentReceipt.AccountAddress__c = targetOpp.Account.AddressEN__c;
		paymentReceipt.ReceiptType__c = type == 'move_payment' ? GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT : GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT;
		paymentReceipt.NovationDate__c = targetOpp.NovationDate__c;
		paymentReceipt.CoBuyerName__c = targetOpp.CoBuyerName__c;
		paymentReceipt.CoBuyerAccountCode__c = coBuyerAccountCodeString;
		return paymentReceipt;
	}

	/**
	 * Phase2
	 * Details:
	 * - add logic to create Payment Receipt Line Item for type Novation Fee
	 */
	public List<PaymentReceiptLineItem__c> generateOperationPaymentReceiptLineItem(
		Decimal totalRecievedAmount,
		Id paymentReceiptId,
		Id paymentMethodId,
		String type
	) {
		List<PaymentReceiptLineItem__c> receiptLineItems = new List<PaymentReceiptLineItem__c>();
		PaymentReceiptLineItem__c receiptLineItem = new PaymentReceiptLineItem__c();
		receiptLineItem.LineNumber__c = 1;
		receiptLineItem.ReceivedAmount__c = totalRecievedAmount;
		receiptLineItem.PreviousRemaining__c = 0;
		receiptLineItem.ReceiptLineItemType__c = type != null? type : 'Operation';
		receiptLineItem.PaymentReceipt__c = paymentReceiptId;
		receiptLineItem.Status__c = 'Fully Paid';
		receiptLineItem.PaymentMethod__c = paymentMethodId;
		receiptLineItem.RemainingAmount__c = 0;
		receiptLineItems.add(receiptLineItem);
		return receiptLineItems;
	}

	/**
	 * Phase2
	 * Details:
	 * - add logic to create Payment Receipt , Line Item, and Method for SIT
	 */
	public void createPaymentReceiptWithLineItem(
        Id opportunityId,
        Decimal amount,
        String receiptType,
        String paymentMethodType
    ) {
        if (opportunityId == null || amount == null) {
            System.debug('OpportunityId and amount must not be null.');
            return;
        }

        OpportunityPaymentService oppPaymentService = OpportunityPaymentService.getInstance();
        OpportunityPaymentSelector oppPaymentSelector = OpportunityPaymentSelector.getInstance();
        PaymentReceiptService paymentReceiptService = PaymentReceiptService.getInstance();

        Savepoint sp = Database.setSavepoint();
        try {
			CoBuyerService coBuyerService = CoBuyerService.getInstance();
			OpportunitySelector selector = OpportunitySelector.getInstance();
			Map<Id, Opportunity> targetOppMapById = selector.getOpportunityWithCoBuyerMapById(new Set<Id>{opportunityId});
			Opportunity targetOpp = targetOppMapById.get(opportunityId);
			List<CoBuyer__c> coBuyers = targetOpp.Co_Borrowers__r;
			String coBuyerAccountCodeString = coBuyerService.getStringCoBuyerAccountCode(coBuyers);
            // 1️⃣ Generate and insert PaymentReceipt
            Integer randomNum = Math.round(Math.random() * 899999) + 100000;
            String runningNumber = '0001'; // You can adjust this logic if needed
            PaymentReceipt__c paymentReceipt = paymentReceiptService.generatePaymentReceiptRelatedToOpportunity(opportunityId);
            paymentReceipt.ReceiptNo__c = 'RP-' + runningNumber + '-' + randomNum;
            paymentReceipt.ReceiptType__c = receiptType;
			paymentReceipt.CoBuyerAccountCode__c = coBuyerAccountCodeString;
            insert paymentReceipt;

            Id paymentMethodId = null;

            // 2️⃣ Generate and insert PaymentMethod with mock fields (if type is NOT null)
            if (paymentMethodType != null) {
                PaymentMethod__c paymentMethod = new PaymentMethod__c(
                    PaymentReceipt__c = paymentReceipt.Id,
                    PaymentDate__c = Date.today(),
                    ReceivedAmount__c = amount,
                    PaymentType__c = paymentMethodType
                );

                if (paymentMethodType == 'Credit Card') {
                    paymentMethod.CreditCardNo__c = '4111XXXXXXXX1234';
                    paymentMethod.BankName__c = 'BBL';
                    paymentMethod.BankBranch__c = 'Central World';
                } else if (paymentMethodType == 'Cashier Cheque') {
                    paymentMethod.BankName__c = 'KBANK';
                    paymentMethod.BankBranch__c = 'Siam Branch';
                    paymentMethod.ChequeNo__c = 'CHQ123456';
                    paymentMethod.BankAccountNo__c = '1234567890';
                    paymentMethod.BankDraftNo__c = 'BD987654';
                } else if (paymentMethodType == 'Cash') {
                    // No extra fields needed for cash
                } else {
                    System.debug('Unknown payment method type: ' + paymentMethodType);
                }

                insert paymentMethod;
                paymentMethodId = paymentMethod.Id;
            }

            // 3️⃣ Query OpportunityPayments
            Map<Id, List<OpportunityPayment__c>> opportunityPaymentMap =
                oppPaymentSelector.getOpportunityPaymentsWithInvoiceLineItemMapByOppId(new Set<Id>{opportunityId});
            List<OpportunityPayment__c> oppPayments = opportunityPaymentMap.get(opportunityId);

            if (oppPayments == null || oppPayments.isEmpty()) {
                System.debug('No OpportunityPayments found for this Opportunity.');
                return;
            }

            // 4️⃣ Generate and insert PaymentReceiptLineItems
            List<PaymentReceiptLineItem__c> paymentReceiptLineItems =
                paymentReceiptService.generatePaymentReceiptLineItemFromTotalReceivedAmount(
                    amount,
                    oppPayments,
                    paymentReceipt.Id,
                    paymentMethodId // 👈 might be null now!
                );
            insert paymentReceiptLineItems;

            // 5️⃣ Update OpportunityPayments
            List<OpportunityPayment__c> updatedOppPayments =
                oppPaymentService.stampFieldFromReceiptLineItem(paymentReceiptLineItems);
            if (!updatedOppPayments.isEmpty()) {
                update updatedOppPayments;
            }

        } catch (Exception e) {
			System.debug('Failed to create payment receipt: ' + e.getMessage() + ' '  + e.getStackTraceString());
            Database.rollback(sp);

        }
    }

	/**
	 * Phase2
	 * Details:
	 * - add logic to create Payment Receipt , Line Item, and Method from Payment Gateway
	 */
	public PaymentReceipt__c createPaymentReceiptWithLineItemFromPaymentGateway(Id opportunityId, Decimal amount, String first4DigitCardNumber, String last4DigitCardNumber, String providerName, String referenceNo) {
		OpportunityPaymentService oppPaymentService = OpportunityPaymentService.getInstance();
		OpportunityPaymentSelector oppPaymentSelector = OpportunityPaymentSelector.getInstance();
		PaymentReceiptService paymentReceiptService = PaymentReceiptService.getInstance();
		Map<String, String> sfProviderNameMapByDFProviderName = new Map<String,String>{
			'VISA' => 'Visa',
			'Master' => 'Master Card',
			'JCB' => 'JCB'
		};
		Savepoint sp = Database.setSavepoint();
		try {
			CoBuyerService coBuyerService = CoBuyerService.getInstance();
			OpportunitySelector selector = OpportunitySelector.getInstance();
			Map<Id, Opportunity> targetOppMapById = selector.getOpportunityWithCoBuyerMapById(new Set<Id>{opportunityId});
			Opportunity targetOpp = targetOppMapById.get(opportunityId);
			List<CoBuyer__c> coBuyers = targetOpp.Co_Borrowers__r;
			String coBuyerAccountCodeString = coBuyerService.getStringCoBuyerAccountCode(coBuyers);

			// 1️⃣ Generate and insert PaymentReceipt (initial insert)
			PaymentReceipt__c paymentReceipt = paymentReceiptService.generatePaymentReceiptRelatedToOpportunity(opportunityId);
			paymentReceipt.ReceiptType__c = GlobalConstants.RECEIPT_TYPE_PAYMENTGATEWAY;
			paymentReceipt.CoBuyerAccountCode__c = coBuyerAccountCodeString;
			insert paymentReceipt;

			// 2️⃣ Generate and update running number
			PaymentReceipt__c paymentReceiptWithRunningNo = paymentReceiptService.generateRunningNo(paymentReceipt);
			update paymentReceiptWithRunningNo;

			// 3️⃣ Construct and insert PaymentMethod__c
			String fullMaskedCard = first4DigitCardNumber + 'XXXXXXXX' + last4DigitCardNumber;
			PaymentMethod__c paymentMethod = new PaymentMethod__c(
				PaymentReceipt__c     = paymentReceiptWithRunningNo.Id,
				PaymentDate__c        = Date.today(),
				ReceivedAmount__c     = amount,
				PaymentType__c        = 'Credit Card',
				CreditCardNo__c       = fullMaskedCard,
				BankName__c           = null,
				ProviderName__c       = sfProviderNameMapByDFProviderName.get(providerName),
				Reference1__c         = referenceNo
			);
			insert paymentMethod;

			// 4️⃣ Query OpportunityPayments
			Map<Id, List<OpportunityPayment__c>> opportunityPaymentMap =
				oppPaymentSelector.getOpportunityPaymentsWithInvoiceLineItemMapByOppId(new Set<Id>{opportunityId});
			List<OpportunityPayment__c> oppPayments = opportunityPaymentMap.get(opportunityId);

			// 5️⃣ Generate and insert PaymentReceiptLineItems
			List<PaymentReceiptLineItem__c> paymentReceiptLineItems =
				paymentReceiptService.generatePaymentReceiptLineItemFromTotalReceivedAmount(
					amount,
					oppPayments,
					paymentReceiptWithRunningNo.Id,
					paymentMethod.Id
				);
			insert paymentReceiptLineItems;

			// 6️⃣ Update OpportunityPayments
			List<OpportunityPayment__c> updatedOppPayments =
				oppPaymentService.stampFieldFromReceiptLineItem(paymentReceiptLineItems);
			if (!updatedOppPayments.isEmpty()) {
				update updatedOppPayments;
			}
			return paymentReceiptWithRunningNo;
		} catch (Exception e) {
			System.debug('Failed to create payment receipt: ' + e.getMessage() + ' '  + e.getStackTraceString());
			Database.rollback(sp);
			return null;
		}
	}

	/**
	 * Phase2
	 * Details:
	 * - add logic to create send Payment Receipt PDF to customer
	 */
	public Messaging.SendEmailResult[] sendEmailWithAttachment(List<PaymentReceipt__c> receipts){
		List<Id> receiptIds = new List<Id>();
		List<Id> oppIds = new List<Id>();
		Set<Id> receiptIdAndOppIdset = new Set<Id>();
		for (PaymentReceipt__c receipt : receipts) {
			receiptIds.add(receipt.Id);
			oppIds.add(receipt.Opportunity__c);
			receiptIdAndOppIdset.add(receipt.Id);
			receiptIdAndOppIdset.add(receipt.Opportunity__c);
		}
		Map<Id, String> receiptNoMapWithReceiptId = getFormatNameMapWithRecordId('PaymentReceipt__c', 'Document', 'Payment Receipt', receiptIds);
		Map<Id, List<Id>> recordContentVerIdsMapByRecordId = ContentVersionService.getInstance().getRecordContentVerIdsMapByRecordIdForInvoice(
			receiptIdAndOppIdset,
			receiptNoMapWithReceiptId,
			new Map<Id, String>()
		);
		List<Messaging.SingleEmailMessage> singleEmails = new List<Messaging.SingleEmailMessage>();
		Id orgWideId = OrgWideEmailAddressSelector.getInstance().getByAddress(EmailUtility.getInstance().emailForOrgWide).get(0).Id;

		List<EmailTemplate> emailTemplates = EmailTemplateSelector.getInstance().getByDeveloperName(
			new Set<String>{'SendReceiptToCustomer'}
		);
		EmailUtility emailUtility = EmailUtility.getInstance();
		EmailTemplate emailTemplate = emailTemplates.get(0);
		Contact dummyContact = ContactSelector.getInstance().getDummy();
		List<Messaging.SingleEmailMessage> tempEmails = new List<Messaging.SingleEmailMessage>();
		for (PaymentReceipt__c receipt : receipts) {
			List<String> toAddresses = new List<String>();
			List<String> ccAddresses = new List<String>();
			List<Messaging.EmailFileAttachment> emailFileAttachments = new List<Messaging.EmailFileAttachment>();
			List<Id> latestContentVersionIds = recordContentVerIdsMapByRecordId.get(receipt.Id) == null ? new List<Id>() : new List<Id>{recordContentVerIdsMapByRecordId.get(receipt.Id)[0]};
			if(String.isBlank(receipt.Opportunity__r.ContactPerson__r.Email)){
				if(String.isNotBlank(receipt.Opportunity__r.Account.Email__c)){
					toAddresses.add(receipt.Opportunity__r.Account.Email__c);
				}
			}
			else{
				toAddresses.add(receipt.Opportunity__r.ContactPerson__r.Email);
			}
			if(String.isNotBlank(receipt.Opportunity__r.Owner.Email)){
				ccAddresses.add(receipt.Opportunity__r.Owner.Email);
			}
			if(String.isNotBlank(receipt.Opportunity__r.CRMinCharge__r.Email)){
				ccAddresses.add(receipt.Opportunity__r.CRMinCharge__r.Email);
			}
			if(toAddresses.isEmpty()){
				continue;
			}
			List<Id> ctVersionIds = new List<Id>();
			Messaging.SingleEmailMessage tempEmail = emailUtility.getSingleEmail(
				orgWideId,
				emailTemplate,
				toAddresses,
				ccAddresses,
				emailFileAttachments,
				latestContentVersionIds,
				receipt.Id,
				dummyContact.Id
			);

			tempEmails.add(tempEmail);
		}
		if(!tempEmails.isEmpty()){
			emailUtility.fakeSendEmails(tempEmails);
			List<Messaging.SingleEmailMessage> actualEmails = new List<Messaging.SingleEmailMessage>();
			for (Messaging.SingleEmailMessage tempEmail : tempEmails) {
				Id receiptId = tempEmail.getWhatId();
				List<Id> latestContentVersionIds = recordContentVerIdsMapByRecordId.get(receiptId) == null ? new List<Id>() : new List<Id>{recordContentVerIdsMapByRecordId.get(receiptId)[0]};
				Messaging.SingleEmailMessage actualEmail = emailUtility.getSingleEmailFromTempEmail(tempEmail,latestContentVersionIds);
				actualEmails.add(actualEmail);
			}
			return emailUtility.sendAllEmailMessage(actualEmails);
		}
		return null;
	}

	@TestVisible
	private Map<Id, String> getFormatNameMapWithRecordId(String objectApiName, String purpose, String documentTemplate, List<Id> recordIds) {
		List<NameFormattingMasterData__c> nameFormattingMasterDatas = NameFormattingMasterDataSelector.getInstance()
			.getByObjTypePurposeDocTemplate(objectApiName, 'Format', purpose, documentTemplate);

		if(nameFormattingMasterDatas.isEmpty()){
			return new Map<Id, String>();
		}

		return RunningNumberUtility.getInstance()
			.generateReplacedFormatName(nameFormattingMasterDatas.get(0), recordIds, objectApiName);
	}
}