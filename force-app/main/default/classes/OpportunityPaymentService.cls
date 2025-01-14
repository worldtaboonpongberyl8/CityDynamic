public with sharing class OpportunityPaymentService {
	public static OpportunityPaymentService instance;

	public static OpportunityPaymentService getInstance() {
		if (instance == null) {
			instance = new OpportunityPaymentService();
		}
		return instance;
	}

	public List<OpportunityPayment__c> createOpportunityPayments(List<Opportunity> opportunities) {
		List<PaymentTerm__c> paymentTermLineItems = new List<PaymentTerm__c>();
		Map<Id , List<PaymentTerm__c>> paymentTermMapByOppId = new Map<Id , List<PaymentTerm__c>>();
		List<OpportunityPayment__c> listForInsertOpportunityPayments = new List<OpportunityPayment__c>();
		Set<Id> paymentTermMasterIds = new Set<Id>();
		Set<Id> productIds = new Set<Id>();
		Set<Id> oppIds = new Set<Id>();
		Set<Id> projectIds = new Set<Id>();
		// Id oppId;
		Id paymentTermMasterId;
		for (Opportunity opp : opportunities) {
			oppIds.add(opp.Id);
			paymentTermMasterIds.add(opp.PaymentTermMaster__c);
			productIds.add(opp.Unit__c);
			projectIds.add(opp.Project__c);
		}
		PaymentTermSelector selector = PaymentTermSelector.getInstance();
		ProjectSelector projectSelector = ProjectSelector.getInstance();
		Product2Selector productSelector = Product2Selector.getInstance();
		Map<Id, PaymentTermMaster__c> paymentTermMasterWithPaymentTermLineItemMapById = selector.getPaymentTermMasterWithLineItemsMapById(
			paymentTermMasterIds
		);

		Map<Id, Project__c> projectMapById = projectSelector.getProjectById(projectIds);
		Map<Id, Product2> productMapById = productSelector.getProduct2ById(productIds);
		OpportunityPaymentSelector oppPaymentSelector = OpportunityPaymentSelector.getInstance();
		OpportunitySelector oppSelector = OpportunitySelector.getInstance();
		Map<Id, Opportunity> oppMapById = oppSelector.getOpportunityMapById(oppIds);
		for (Opportunity opp : opportunities) {
			PaymentTermMaster__c paymentTermMaster = paymentTermMasterWithPaymentTermLineItemMapById.get(
				opp.PaymentTermMaster__c
			);
			List<PaymentTerm__c> paymentTerms = paymentTermMaster == null
				? new List<PaymentTerm__c>()
				: paymentTermMaster.Payment_Term__r;
			// oppId = opp.Id;
			paymentTermMasterId = opp.PaymentTermMaster__c;
			paymentTermMapByOppId.put(opp.Id , paymentTerms);
			//paymentTermLineItems.addAll(paymentTerms);
		}

		// create map from oppForAdjusts
		Map<Id,List<OpportunityPayment__c>> oppPaymentsMapByOppId = new Map<Id,List<OpportunityPayment__c>>();
		for (Id oppId : oppIds){
			List<OpportunityPayment__c> oppForAdjusts = new List<OpportunityPayment__c>();
			Opportunity targetOpp = oppMapById.get(oppId);
			paymentTermLineItems = paymentTermMapByOppId.get(oppId);
			oppForAdjusts.addAll(generateOpportunityPaymentsFromPaymentTerms(
				paymentTermLineItems,
				targetOpp.PaymentTermMaster__c,
				targetOpp
			));
			oppPaymentsMapByOppId.put(oppId,oppForAdjusts);
		}
		for (Opportunity opp : opportunities) {
			Opportunity targetOpp = oppMapById.get(opp.Id);
			List<OpportunityPayment__c> targetOppPayment = oppPaymentsMapByOppId.get(opp.Id);
			List<OpportunityPayment__c> adjustAmountOpportunityPayments = new List<OpportunityPayment__c>();
			List<OpportunityPayment__c> adjustDueDateOpportunityPayments = new List<OpportunityPayment__c>();
			adjustAmountOpportunityPayments = adjustAmount(
				targetOppPayment,
				targetOpp,
				paymentTermMasterWithPaymentTermLineItemMapById,
				productMapById
			);
			adjustDueDateOpportunityPayments = adjustDueDate(
				adjustAmountOpportunityPayments,
				targetOpp,
				paymentTermMasterWithPaymentTermLineItemMapById,
				projectMapById
			);
			listForInsertOpportunityPayments.addAll(adjustDueDateOpportunityPayments);
		}
		return listForInsertOpportunityPayments;
	}

	public List<OpportunityPayment__c> updateOpportunityPaymentByPaymentMaster(List<Opportunity> opportunitys) {
		Set<Id> oppIds = new Set<Id>();
		List<OpportunityPayment__c> opportunityPaymentsToDelete = new List<OpportunityPayment__c>();
		for (Opportunity opp : opportunitys) {
			oppIds.add(opp.Id);
		}
		OpportunityPaymentSelector selectorOpportunityPayment = OpportunityPaymentSelector.getInstance();
		Map<Id, List<OpportunityPayment__c>> oldOpportunityPayments = selectorOpportunityPayment.getOpportunityPaymentsMapByOppId(
			oppIds
		);
		for (Opportunity opp : opportunitys) {
			opportunityPaymentsToDelete = oldOpportunityPayments.get(opp.Id) == null
				? new List<OpportunityPayment__c>()
				: oldOpportunityPayments.get(opp.Id);
		}
		if (!opportunityPaymentsToDelete.isEmpty()) {
			delete opportunityPaymentsToDelete;
		}
		List<OpportunityPayment__c> result = createOpportunityPayments(opportunitys);
		return result;
	}

	public List<OpportunityPayment__c> adjustRelatedOpportunityPaymentAfterApplyDiscount(
		List<Opportunity> opportunitys
	) {
		List<OpportunityPayment__c> adjustOpportunitys = new List<OpportunityPayment__c>();
		List<OpportunityPayment__c> updateOppPayments = new List<OpportunityPayment__c>();
		Set<Id> oppIds = new Set<Id>();
		Set<Id> paymentMasterIds = new Set<Id>();
		Set<Id> productIds = new Set<Id>();

		for (Opportunity opp : opportunitys) {
			oppIds.add(opp.Id);
			paymentMasterIds.add(opp.PaymentTermMaster__c);
			productIds.add(opp.Unit__c);
		}
		PaymentTermSelector selector = PaymentTermSelector.getInstance();
		Product2Selector productSelector = Product2Selector.getInstance();
		Map<Id, PaymentTermMaster__c> paymentTermMasterWithPaymentTermLineItemMapById = selector.getPaymentTermMasterWithLineItemsMapById(
			paymentMasterIds
		);
		Map<Id, Product2> productMapById = productSelector.getProduct2ById(productIds);
		OpportunityPaymentSelector oppPaymentSelector = OpportunityPaymentSelector.getInstance();
		OpportunitySelector oppSelector = OpportunitySelector.getInstance();
		Map<Id, List<OpportunityPayment__c>> oppPaymentListMapById = oppPaymentSelector.getOpportunityPaymentsMapByOppId(
			oppIds
		);
		Map<Id, Opportunity> oppMapById = oppSelector.getOpportunityMapById(oppIds);
		for (Opportunity opp : opportunitys) {
			List<OpportunityPayment__c> oppPaymentListById = oppPaymentListMapById.get(opp.Id) == null
				? new List<OpportunityPayment__c>()
				: oppPaymentListMapById.get(opp.Id);
			Opportunity oppById = oppMapById.get(opp.Id);
			adjustOpportunitys = adjustAmount(
				oppPaymentListById,
				oppById,
				paymentTermMasterWithPaymentTermLineItemMapById,
				productMapById
			);
			updateOppPayments.addAll(adjustOpportunitys);
		}
		return updateOppPayments;
	}

	public List<OpportunityPayment__c> adjustRelatedOpportunityPaymentAfterChangeReservationDueDate(
		List<Opportunity> opportunitys
	) {
		List<OpportunityPayment__c> adjustOpportunitys = new List<OpportunityPayment__c>();
		List<OpportunityPayment__c> updateOppPayments = new List<OpportunityPayment__c>();
		Set<Id> oppIds = new Set<Id>();
		Set<Id> paymentMasterIds = new Set<Id>();
		Set<Id> projectIds = new Set<Id>();

		for (Opportunity opp : opportunitys) {
			oppIds.add(opp.Id);
			paymentMasterIds.add(opp.PaymentTermMaster__c);
			projectIds.add(opp.Project__c);
		}
		PaymentTermSelector selector = PaymentTermSelector.getInstance();
		ProjectSelector projectSelector = ProjectSelector.getInstance();
		Map<Id, PaymentTermMaster__c> paymentTermMasterWithPaymentTermLineItemMapById = selector.getPaymentTermMasterWithLineItemsMapById(
			paymentMasterIds
		);
		Map<Id, Project__c> getProjectMap = projectSelector.getProjectById(projectIds);
		OpportunityPaymentSelector oppPaymentSelector = OpportunityPaymentSelector.getInstance();
		OpportunitySelector oppSelector = OpportunitySelector.getInstance();
		Map<Id, List<OpportunityPayment__c>> oppPaymentListMapById = oppPaymentSelector.getOpportunityPaymentsMapByOppId(
			oppIds
		);
		Map<Id, Opportunity> oppMapById = oppSelector.getOpportunityMapById(oppIds);
		for (Opportunity opp : opportunitys) {
			List<OpportunityPayment__c> oppPaymentListById = oppPaymentListMapById.get(opp.Id);
			Opportunity oppById = oppMapById.get(opp.Id);
			adjustOpportunitys = adjustDueDate(
				oppPaymentListById,
				oppById,
				paymentTermMasterWithPaymentTermLineItemMapById,
				getProjectMap
			);
			updateOppPayments.addAll(adjustOpportunitys);
		}
		return updateOppPayments;
	}

	public List<OpportunityPayment__c> getOppPaymentsFromJSONString(String oppPaymentJSON) {
		List<OpportunityPayment__c> oppPaymentsResult = new List<OpportunityPayment__c>();
		List<OpportunityPaymentWrapper> opportunityPaymentWrappers = (List<OpportunityPaymentWrapper>) JSON.deserialize(
			oppPaymentJSON,
			List<OpportunityPaymentWrapper>.class
		);
		for (OpportunityPaymentWrapper wrapper : opportunityPaymentWrappers) {
			OpportunityPayment__c oppPayment = new OpportunityPayment__c();
			oppPayment.Id = wrapper.id;
			oppPayment.Order__c = wrapper.order;
			oppPayment.Amount__c = wrapper.amount;
			oppPayment.DueDate__c = wrapper.dueDate;
			oppPayment.Term__c = wrapper.term;
			oppPayment.IsMasterData__c = true;
			oppPayment.Name = String.valueOf(wrapper.order);
			if (wrapper.isNewRecord) {
				oppPayment.Opportunity__c = wrapper.oppId;
			}
			oppPaymentsResult.add(oppPayment);
		}
		return oppPaymentsResult;
	}

	//แยก Method ที่ adjust Due Date
	public List<OpportunityPayment__c> adjustDueDate(
		List<OpportunityPayment__c> oppPayments,
		Opportunity opportunity,
		Map<Id, PaymentTermMaster__c> paymentTermMasterWithPaymentTermLineItemMapById,
		Map<Id, Project__c> getProjectMap
	) {
		Date accumulatorDate = opportunity.ReservationDueDate__c;
		Id paymentMasterId = opportunity.PaymentTermMaster__c;
		PaymentTermMaster__c paymentTermMaster = paymentTermMasterWithPaymentTermLineItemMapById.get(paymentMasterId);
		Integer dueDateOfInstallment = paymentTermMaster == null ? null : Integer.valueOf(paymentTermMaster.DueDate__c);
		// loop over oppPayments to assign DueDate__c
		Integer installmentDateCount = 1;
		Integer contractDateCount = 1;
		Date contractDateForInstallment = accumulatorDate;
		for (OpportunityPayment__c oppPayment : oppPayments) {
			if (oppPayment.Term__c == 'Reservation') {
				oppPayment.DueDate__c = accumulatorDate;
			} else if (oppPayment.Term__c.contains('Contract')) {
				Date contractDate = accumulatorDate?.addDays(14 * contractDateCount);
				System.debug('Date Contract : ' + contractDate);
				oppPayment.DueDate__c = contractDate;
				contractDateForInstallment = contractDate;
				contractDateCount++;
			} else if (oppPayment.Term__c.contains('Installment')) {
				Date installmentDate = contractDateForInstallment?.addMonths(installmentDateCount);
				Integer year = installmentDate?.year();
				Integer month = installmentDate?.month();
				Date installmentDueDate = contractDateForInstallment != null &&
					dueDateOfInstallment != null
					? Date.newInstance(year, month, dueDateOfInstallment)
					: null;
				System.debug('Date Installment : ' + accumulatorDate);
				oppPayment.DueDate__c = installmentDueDate;
				installmentDateCount++;
			} else if (oppPayment.Term__c.contains('Transfer')) {
				Project__c project = getProjectMap.get(opportunity.Project__c);
				oppPayment.DueDate__c = project?.CompletionDate__c;
			}
		}
		return oppPayments;
	}

	public List<OpportunityPayment__c> adjustAmount(
		List<OpportunityPayment__c> oppPayments,
		Opportunity opportunity,
		Map<Id, PaymentTermMaster__c> paymentTermMasterWithPaymentTermLineItemMapById,
		Map<Id, Product2> productMapById
	) {
		Id paymentMasterId = opportunity.PaymentTermMaster__c;
		List<OpportunityPayment__c> resultOppPayments = new List<OpportunityPayment__c>();
		PaymentTermMaster__c paymentTermMaster = paymentTermMasterWithPaymentTermLineItemMapById.get(paymentMasterId);
		List<PaymentTerm__c> paymentTermLineItems = paymentTermMaster == null
			? new List<PaymentTerm__c>()
			: paymentTermMaster.Payment_Term__r;
		Product2 product = productMapById.get(opportunity.Unit__c);
		Map<String, PaymentTerm__c> paymentTermMapByTerm = new Map<String, PaymentTerm__c>();
		for (PaymentTerm__c paymentTerm : paymentTermLineItems) {
			if (paymentTerm.Term__c.contains('Contract')) {
				paymentTermMapByTerm.put(paymentTerm.Term__c, paymentTerm);
			} else if (paymentTerm.Term__c.contains('Installment')) {
				paymentTermMapByTerm.put(paymentTerm.Term__c, paymentTerm);
			} else if (paymentTerm.Term__c.contains('Transfer')) {
				paymentTermMapByTerm.put(paymentTerm.Term__c, paymentTerm);
			}
		}
		list<Decimal> accumulators = new List<Decimal>();
		Decimal accumulator = product?.ReservationPrice__c;
		accumulators.add(accumulator);
		Decimal netPrice = opportunity.NetPrice__c;
		Decimal unitPrice = opportunity.UnitPrice__c;
		System.debug('unitPrice: ' + unitPrice);
		List<OpportunityPayment__c> reservationOppPayment = new List<OpportunityPayment__c>();
		List<OpportunityPayment__c> contractOppPayment = new List<OpportunityPayment__c>();
		List<OpportunityPayment__c> installmentOppPayment = new List<OpportunityPayment__c>();
		List<OpportunityPayment__c> transferOppPayment = new List<OpportunityPayment__c>();
		for (OpportunityPayment__c oppPayment : oppPayments) {
			System.debug('oppPayment: ' + oppPayment);
			if (oppPayment.Term__c == 'Reservation') {
				reservationOppPayment.add(oppPayment);
			} else if (oppPayment.Term__c.contains('Contract')) {
				contractOppPayment.add(oppPayment);
			} else if (oppPayment.Term__c.contains('Installment')) {
				installmentOppPayment.add(oppPayment);
			} else if (oppPayment.Term__c.contains('Transfer')) {
				transferOppPayment.add(oppPayment);
			}
		}
		List<OpportunityPayment__c> resultReservationOppPaymentList = this.calculateReservationAmount(
			reservationOppPayment,
			accumulator
		);
		List<OpportunityPayment__c> resultContractOppPaymentList = this.calculateContractAmount(
			contractOppPayment,
			paymentTermMapByTerm,
			accumulators,
			unitPrice
		);
		List<OpportunityPayment__c> resultInstallmentOppPaymentList = this.calculateInstallmentAmount(
			installmentOppPayment,
			paymentTermMapByTerm,
			accumulators,
			unitPrice
		);
		List<OpportunityPayment__c> resultTransferOppPaymentList = this.calculateTransferAmount(
			transferOppPayment,
			accumulators,
			netPrice
		);

		resultOppPayments.addAll(resultReservationOppPaymentList);
		resultOppPayments.addAll(resultContractOppPaymentList);
		resultOppPayments.addAll(resultInstallmentOppPaymentList);
		resultOppPayments.addAll(resultTransferOppPaymentList);

		return resultOppPayments;
	}

	public List<OpportunityPayment__c> getClonedOpportunityPaymentByQuote(List<Quote__c> quotes) {
		List<OpportunityPayment__c> targetOpportunityPayments = new List<OpportunityPayment__c>();
		OpportunityPaymentSelector selector = OpportunityPaymentSelector.getInstance();
		Set<Id> oppIds = new Set<Id>();
		for (Quote__c quote : quotes) {
			oppIds.add(quote.Opportunity__c);
		}
		Map<Id, List<OpportunityPayment__c>> oppPaymentsMapByOppId = selector.getOpportunityPaymentsMapByOppId(oppIds);
		for (Quote__c quote : quotes) {
			List<OpportunityPayment__c> oppPayments = oppPaymentsMapByOppId.get(quote.Opportunity__c) == null
				? new List<OpportunityPayment__c>()
				: oppPaymentsMapByOppId.get(quote.Opportunity__c);
			for (OpportunityPayment__c oppPayment : oppPayments) {
				OpportunityPayment__c clonedOppPayment = oppPayment.clone(false, false, false, false);
				clonedOppPayment.Quote__c = quote.Id;
				clonedOppPayment.IsMasterData__c = false;
				targetOpportunityPayments.add(clonedOppPayment);
			}
		}
		return targetOpportunityPayments;
	}

	public List<OpportunityPayment__c> stampFieldFromReceiptLineItem(List<PaymentReceiptLineItem__c> receiptLineItems) {
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>();
		OpportunityPaymentSelector selector = OpportunityPaymentSelector.getInstance();
		Set<Id> oppPaymentIds = new Set<Id>();
		Map<Id, Decimal> totalReceivedAmountMapByOppPaymentId = new Map<Id, Decimal>();
		for (PaymentReceiptLineItem__c receiptLineItem : receiptLineItems) {
			System.debug('---test receiptLineItem.ReceivedAmount__c: ' + receiptLineItem.ReceivedAmount__c);
			oppPaymentIds.add(receiptLineItem.OpportunityPayment__c);
			if (!totalReceivedAmountMapByOppPaymentId.containsKey(receiptLineItem.OpportunityPayment__c)) {
				totalReceivedAmountMapByOppPaymentId.put(receiptLineItem.OpportunityPayment__c, 0);
			}
			Decimal receivedAmount = totalReceivedAmountMapByOppPaymentId.get(receiptLineItem.OpportunityPayment__c);
			System.debug('---test receivedAmount: ' + receivedAmount);
			totalReceivedAmountMapByOppPaymentId.put(receiptLineItem.OpportunityPayment__c , receivedAmount + receiptLineItem.ReceivedAmount__c);
		}
		Map<Id, OpportunityPayment__c> oppPaymentMapById = selector.getOpportunityPaymentMapById(oppPaymentIds);
		for (Id oppPaymentId : oppPaymentMapById.keySet()) {
			OpportunityPayment__c targetOppPayment = oppPaymentMapById.get(oppPaymentId);
			targetOppPayment.ReceivedAmount__c = targetOppPayment.ReceivedAmount__c == null
				? totalReceivedAmountMapByOppPaymentId.get(oppPaymentId)
				: targetOppPayment.ReceivedAmount__c + totalReceivedAmountMapByOppPaymentId.get(oppPaymentId);
			oppPayments.add(targetOppPayment);
		}
		return oppPayments;
	}

	public List<OpportunityPayment__c> cancelRecievedAmountFromReceiptLineItem(
		List<PaymentReceiptLineItem__c> receiptLineItems
	) {
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>();
		OpportunityPaymentSelector selector = OpportunityPaymentSelector.getInstance();
		Set<Id> oppPaymentIds = new Set<Id>();
		Map<Id, Decimal> totalReceivedAmountMapByOppPaymentId = new Map<Id, Decimal>();
		for (PaymentReceiptLineItem__c receiptLineItem : receiptLineItems) {
			oppPaymentIds.add(receiptLineItem.OpportunityPayment__c);
			if (!totalReceivedAmountMapByOppPaymentId.containsKey(receiptLineItem.OpportunityPayment__c)) {
				totalReceivedAmountMapByOppPaymentId.put(receiptLineItem.OpportunityPayment__c, 0);
			}
			Decimal receivedAmount = totalReceivedAmountMapByOppPaymentId.get(receiptLineItem.OpportunityPayment__c);
			totalReceivedAmountMapByOppPaymentId.put(receiptLineItem.OpportunityPayment__c , receivedAmount + receiptLineItem.ReceivedAmount__c);
		}
		Map<Id, OpportunityPayment__c> oppPaymentMapById = selector.getOpportunityPaymentMapById(oppPaymentIds);
		for (Id oppPaymentId : oppPaymentMapById.keySet()) {
			OpportunityPayment__c targetOppPayment = oppPaymentMapById.get(oppPaymentId);
			targetOppPayment.ReceivedAmount__c = targetOppPayment.ReceivedAmount__c == null
				? null
				: targetOppPayment.ReceivedAmount__c - totalReceivedAmountMapByOppPaymentId.get(oppPaymentId);
			oppPayments.add(targetOppPayment);
		}
		return oppPayments;
	}

	public Map<Id, List<OpportunityPayment__c>> getOppPaymentsMapByOppId(List<OpportunityPayment__c> oppPayments) {
		Map<Id, List<OpportunityPayment__c>> oppPaymentsMapByOppId = new Map<Id, List<OpportunityPayment__c>>();
		for (OpportunityPayment__c oppPayment : oppPayments) {
			List<OpportunityPayment__c> opportunityPayments = oppPaymentsMapByOppId.get(oppPayment.Opportunity__c);

			if (opportunityPayments == null) {
				oppPaymentsMapByOppId.put(oppPayment.Opportunity__c, new List<OpportunityPayment__c>{ oppPayment });
			} else {
				opportunityPayments.add(oppPayment);
			}
		}
		return oppPaymentsMapByOppId;
	}

	// ----- Start Private Service -----
	private List<OpportunityPayment__c> calculateReservationAmount(
		List<OpportunityPayment__c> reservationOppPayments,
		Decimal accumulator
	) {
		List<OpportunityPayment__c> adjustReservationAmountList = new List<OpportunityPayment__c>();
		for (OpportunityPayment__c oppPayment : reservationOppPayments) {
			oppPayment.Amount__c = accumulator;
			adjustReservationAmountList.add(oppPayment);
		}
		return adjustReservationAmountList;
	}

	/**
	 * Phase: 1
	* UAT Issue: DF-UAT-027
	*/
	private List<OpportunityPayment__c> calculateContractAmount(
		List<OpportunityPayment__c> contractOppPayments,
		Map<String, PaymentTerm__c> paymentTermMapByTerm,
		List<Decimal> accumulators,
		Decimal netPrice
	) {
		List<OpportunityPayment__c> adjustContractAmountList = new List<OpportunityPayment__c>();
		Decimal roundUpAmount;
		for (OpportunityPayment__c oppPayment : contractOppPayments) {
			PaymentTerm__c paymentTermByMap = paymentTermMapByTerm.get('Contract');
			System.debug('paymentTermByMap: ' + paymentTermByMap);
			if (paymentTermByMap.Percent__c == null) {
				oppPayment.Amount__c = paymentTermByMap.Amount__c / contractOppPayments.size();
				accumulators.add(oppPayment.Amount__c);
			} else {
				roundUpAmount = (netPrice * (paymentTermByMap.Percent__c / 100));
				//oppPayment.Amount__c = (netPrice * (paymentTermByMap.Percent__c / 100)) / contractOppPayments.size();
				oppPayment.Amount__c = (roundUpAmount.round(RoundingMode.UP))  / contractOppPayments.size();
				accumulators.add(oppPayment.Amount__c);
			}

			adjustContractAmountList.add(oppPayment);
		}
		return adjustContractAmountList;
	}

	/**
	 * Phase: 1
	* UAT Issue: DF-UAT-027
	*/
	private List<OpportunityPayment__c> calculateInstallmentAmount(
		List<OpportunityPayment__c> installmentOppPayments,
		Map<String, PaymentTerm__c> paymentTermMapByTerm,
		List<Decimal> accumulators,
		Decimal netPrice
	) {
		List<OpportunityPayment__c> adjustInstallmentAmountList = new List<OpportunityPayment__c>();
		Decimal roundUpAmount;
		for (OpportunityPayment__c oppPayment : installmentOppPayments) {
			PaymentTerm__c paymentTermByMap = paymentTermMapByTerm.get(oppPayment.Term__c);
			if (paymentTermByMap.Percent__c == null) {
				oppPayment.Amount__c = paymentTermByMap.Amount__c;
				accumulators.add(oppPayment.Amount__c);
			} else {
				roundUpAmount = (netPrice * (paymentTermByMap.Percent__c / 100));
				//oppPayment.Amount__c = (netPrice * (paymentTermByMap.Percent__c / 100));
				oppPayment.Amount__c = (roundUpAmount.round(RoundingMode.UP));
				accumulators.add(oppPayment.Amount__c);
			}
			adjustInstallmentAmountList.add(oppPayment);
		}
		return adjustInstallmentAmountList;
	}

	private List<OpportunityPayment__c> calculateTransferAmount(
		List<OpportunityPayment__c> transferOppPayments,
		List<Decimal> accumulators,
		Decimal netPrice
	) {
		List<OpportunityPayment__c> adjustTranferAmountList = new List<OpportunityPayment__c>();
		Decimal resultAccumulator = 0;
		for (Decimal accumulator : accumulators) {
			resultAccumulator = accumulator == null ? resultAccumulator + 0 : resultAccumulator + accumulator;
		}
		for (OpportunityPayment__c oppPayment : transferOppPayments) {
			oppPayment.Amount__c = netPrice == null ? netPrice : netPrice - resultAccumulator;
			adjustTranferAmountList.add(oppPayment);
		}
		return adjustTranferAmountList;
	}

	private List<OpportunityPayment__c> generateOpportunityPaymentsFromPaymentTerms(
		List<PaymentTerm__c> paymentTerms,
		Id paymentTermMasterId,
		Opportunity targetOpp
	) {
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>();
		OpportunityPayment__c oppFirstRecord = new OpportunityPayment__c(
			Order__c = 1,
			Name = '1',
			Term__c = 'Reservation',
			Opportunity__c = targetOpp.Id,
			UnitName__c = targetOpp.Unit__r.Name,
			ProjectName__c = targetOpp.Project__r.Name,
			// Unit
			// Project
			IsMasterData__c = true,
			PaymentTermMaster__c = paymentTermMasterId
		);
		oppPayments.add(oppFirstRecord);
		for (PaymentTerm__c payment : paymentTerms) {
			OpportunityPayment__c oppPayment = new OpportunityPayment__c();
			oppPayment.Order__c = payment.Order__c + 1;
			oppPayment.Name = String.valueOf(payment.Order__c + 1);
			oppPayment.Term__c = payment.Term__c;
			oppPayment.Opportunity__c = targetOpp.Id;
			oppPayment.UnitName__c = targetOpp.Unit__r.Name;
			oppPayment.ProjectName__c = targetOpp.Project__r.Name;
			oppPayment.IsMasterData__c = true;
			oppPayment.PaymentTermMaster__c = paymentTermMasterId;
			// Unit
			// Project
			oppPayments.add(oppPayment);
		}
		return oppPayments;
	}
	// ----- End Private Service -----

	// ----- Start Wrapper Class -----
	public class OpportunityPaymentWrapper {
		public Decimal amount;
		public Date dueDate;
		public Decimal order;
		public String term;
		public String id;
		public String oppId;
		public Boolean isNewRecord;
	}
	// ----- End Wrapper Class -----
}