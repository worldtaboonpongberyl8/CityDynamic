@isTest
public with sharing class Phase2ChangeUnitScenarioTest {
    @TestSetup
	static void makeData(){
		DataMaker dataMaker = DataMaker.getInstance();
		// Create Project
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		testProject.CompanyName__c ='Test Company Name';
		insert testProject;
		// Craete Floor
		Floor__c testFloor = dataMaker.createFloor('Test Floor', 'FF01', testProject.Id);
		insert testFloor;
		// Create Unit Type
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type', testProject.Id);
		insert unitType;
		// Create Unit
		Product2 testProduct = dataMaker.createUnit(
			'Test Product 1',
			'UN01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		testProduct.ReservationPrice__c = 100000;
		Product2 testProduct2 = dataMaker.createUnit(
			'Test Product 2',
			'UN02',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		testProduct.ReservationPrice__c = 200000;
		Product2 testProduct3 = dataMaker.createUnit(
			'Test Product 3',
			'UN03',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		testProduct.ReservationPrice__c = 50000;
		List<Product2> products = new List<Product2>{testProduct,testProduct2,testProduct3};
		insert products;
		// Create PaymentTermMaster__c
		PaymentTermMaster__c paymentTermMaster = dataMaker.craetePaymentTermMaster(
			testProject.Id,
			'FQ Series 5-10-85',
			'Series',
			'Foreign',
			25
		);
		insert paymentTermMaster;
		PaymentTerm__c contractLineItem = dataMaker.createPaymentTermLineItem(paymentTermMaster.Id,1,1000000,null,'Contract');
		PaymentTerm__c installment1LineItem = dataMaker.createPaymentTermLineItem(paymentTermMaster.Id,2,100000,null,'Installment 1');
		PaymentTerm__c installment2LineItem = dataMaker.createPaymentTermLineItem(paymentTermMaster.Id,3,100000,null,'Installment 2');
		PaymentTerm__c installment3LineItem = dataMaker.createPaymentTermLineItem(paymentTermMaster.Id,1,100000,null,'Installment 3');
		List<PaymentTerm__c> paymentTermLineItems = new List<PaymentTerm__c>{contractLineItem,installment1LineItem,installment2LineItem,installment3LineItem};
		insert paymentTermLineItems;
		// Create Pricebook Entry
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 15000000, 15000000,15000000);
		testPricebookEntry1.Pricebook2Id = pricebookId;
		testPricebookEntry1.UseStandardPrice = false;
		insert testPricebookEntry1;
		// Creat Account
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account targetAccount = dataMaker.createAccount(recordTypeId, 'Test Account');
		targetAccount.AccountCode__c = '1111';
		Account targetAccount2 = dataMaker.createAccount(recordTypeId, 'Test Account 2');
		targetAccount2.AccountCode__c = '2222';
		Account targetAccount3 = dataMaker.createAccount(recordTypeId, 'Test Account 3');
		targetAccount3.AccountCode__c = '3333';
		Account targetAccount4 = dataMaker.createAccount(recordTypeId, 'Test Account 4');
		targetAccount4.AccountCode__c = '4444';
		List<Account> accounts = new List<Account>{targetAccount,targetAccount2,targetAccount3,targetAccount4};
		insert accounts;
		// Create Opportunity
		Opportunity opp1 = dataMaker.createOpportunity(
			targetAccount.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Foreign',
			paymentTermMaster.Id,
			testProject.Id
		);
		Opportunity opp2 = dataMaker.createOpportunity(
			targetAccount.Id,
			'Omitted',
			'Test Opp 2',
			Date.today(),
			'Open',
			testProduct2.Id,
			'Foreign',
			paymentTermMaster.Id,
			testProject.Id
		);
		Opportunity opp3 = dataMaker.createOpportunity(
			targetAccount.Id,
			'Omitted',
			'Test Opp 3',
			Date.today(),
			'Open',
			testProduct3.Id,
			'Foreign',
			paymentTermMaster.Id,
			testProject.Id
		);
		List<Opportunity> opportunities = new List<Opportunity>{ opp1,opp2,opp3 };
		insert opportunities;
		// Create Name Formatting
		NameFormattingMasterData__c format = dataMaker.createNameFormattingMasterData(
			'PaymentReceipt__c', 'Format', 'Object', 'RV-{Opportunity__r.Project__r.ProjectCode__c}{CreatedDate:FORMATDATETIME:yyMM}{RUNNINGNUMBER:000}', 1, null
		);
		insert format;
	}

	@isTest
	static void upgradePositiveCase(){
		List<Opportunity> opportunities = [SELECT Id FROM Opportunity];
		Opportunity oldOpp = opportunities[0];
        Opportunity newOpp =  opportunities[1];

		String receiptType = GlobalConstants.RECEIPT_TYPE_DEFAULT;
		String paymentMethodType = 'Credit Card';
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		service.createPaymentReceiptWithLineItem(oldOpp.Id, 100000, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(oldOpp.Id, 100000, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(oldOpp.Id, 100000, receiptType, paymentMethodType);

		InvoiceService invoiceService = InvoiceService.getInstance();
		Date invoiceDate = Date.newInstance(2025, 6, 15);
		Date dueDate = invoiceDate.addDays(5); // due date
		String term = 'Installment 3';
		invoiceService.createInvoiceAndLineItem(oldOpp.Id, invoiceDate, dueDate, term);

        // Create PaymentMethod
        PaymentMethod__c paymentMethod = new PaymentMethod__c(
            PaymentType__c = 'Upgrade',
            PaymentDate__c = Date.today(),
            ReceivedAmount__c = 300000
        );

        // Prepare NewOpportunityItem
        OpportunityMoverController.NewOpportunityItem item = new OpportunityMoverController.NewOpportunityItem();
        item.opportunityId = newOpp.Id;
        item.amountToMove = 300000;

        String newOppJSON = JSON.serialize(item);

        List<Id> selectedIds = new List<Id>(); // empty for now

        OpportunityMoverController.MoveOpportunityResult result = OpportunityMoverController.completeAction(
            oldOpp.Id,
            'upgrade',
			'reason',
            10000,
			100000,
            'https://example.com',
            newOppJSON,
            paymentMethod,
            selectedIds,
			true
        );

		List<Opportunity> targetOpportunities = [
			SELECT
					Id,
					Unit__r.ProductCode,
					LastGLStatusInPojjaman__c,
					LastIntegrationDateTime__c,
					(
						SELECT Id, LastGLStatusInPojjaman__c
						FROM Invoices__r
						ORDER BY CreatedDate ASC
					),
					(
						SELECT 	Id,
								IsCancel__c,
								CancelReason__c,
								LastGLStatusInPojjaman__c
						FROM PaymentReceipt__r
						WHERE
							(CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_UPGRADE OR
							CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_DOWNGRADE OR
							CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_MOVEPAYMENT)
						ORDER BY CreatedDate ASC
					)
				FROM Opportunity
				WHERE (
						StageName =: GlobalConstants.OPP_STAGENAME_CLOSED_LOST AND
						(LossReason__c =: GlobalConstants.OPP_LOST_REASON_UPGRADE OR
						LossReason__c =: GlobalConstants.OPP_LOST_REASON_DOWNGRADE OR
						LossReason__c =: GlobalConstants.OPP_LOST_REASON_PURCHASEOTHERNAME OR
						LossReason__c =: GlobalConstants.OPP_LOST_REASON_MOVEPAYMENT ) AND
						(LastGLStatusInPojjaman__c = null OR LastGLStatusInPojjaman__c = 'Fail')
					)
				ORDER BY LastModifiedDate ASC
			];
		System.assertEquals(1, targetOpportunities.size());

		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		Set<Id> receiptIds = new Set<Id>();
		Set<Id> invoiceIds = new Set<Id>();
		for (Opportunity opportunity : targetOpportunities) {
			List<Invoice__c> invoices = opportunity.Invoices__r;
			for (Invoice__c invoice : invoices) {
				invoiceIds.add(invoice.Id);
			}
			List<PaymentReceipt__c> paymentReceipts = opportunity.PaymentReceipt__r;
			for (PaymentReceipt__c paymentReceipt : paymentReceipts) {
				receiptIds.add(paymentReceipt.Id);
			}
		}
		Map<Id, Invoice__c> invoiceWithInvoiceLineItemsMapById = invoiceSelector.getInvoiceWithInvoiceLineItemsMapById(
			invoiceIds
		);
		List<Invoice__c> remainedInvoice = new List<Invoice__c>();
		for(Invoice__c invoice: invoiceWithInvoiceLineItemsMapById.values()){
			InvoiceLineItem__c invoiceLineItem = invoice.InvoiceLineItems__r[0];
			if (invoiceLineItem.OpportunityPayment__r.Remaining__c > 0){
				remainedInvoice.add(invoice);
			}
		}

		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			receiptIds
		);
		GLChangeUnitApiCallout callout = new GLChangeUnitApiCallout(targetOpportunities);
		Object request = callout.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(null, request);
		System.assertEquals(remainedInvoice.size() + receiptWithReceiptLineItemsMapById.values().size(), requestModels.size());
		List<PojjamanDataModel.FNGLDocRequest> invoiceRequestModels = new List<PojjamanDataModel.FNGLDocRequest>();
		List<PojjamanDataModel.FNGLDocRequest> receiptRequestModels = new List<PojjamanDataModel.FNGLDocRequest>();
		for(PojjamanDataModel.FNGLDocRequest requestModel : requestModels ){
			if (requestModel.InvoiceCode != null){
				invoiceRequestModels.add(requestModel);
			} else {
				receiptRequestModels.add(requestModel);
			}
		}
		System.assertEquals(remainedInvoice.size(), invoiceRequestModels.size());
		System.assertEquals(1, remainedInvoice.size());
		System.assertEquals(receiptWithReceiptLineItemsMapById.values().size(), receiptRequestModels.size());
		System.assertEquals(3, receiptRequestModels.size());
		// ----- Check Invoice -----
		for (Integer invoiceIdx = 0 ; invoiceIdx < invoiceRequestModels.size(); invoiceIdx ++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = invoiceRequestModels[invoiceIdx];
			Invoice__c invoice = remainedInvoice[invoiceIdx];
			System.assertNotEquals(null, requestDataModel.CustomerCode);
			System.assertEquals(invoice.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(invoice.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(invoice.Id, requestDataModel.SFDocId);
			System.assertEquals(invoice.CreatedDate.date(), requestDataModel.DocDate);
			System.assertEquals('GL', requestDataModel.DocType);
			System.assertEquals(null, requestDataModel.ReceiptCode);
			System.assertEquals(invoice.InvoiceNo__c, requestDataModel.InvoiceCode);
			System.assertEquals(2, requestDataModel.Indicator);
			System.assertEquals(invoice.GLKey__c, requestDataModel.GroupKey);
			System.assertEquals(invoice.GLDate__c, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(null, requestDataModel.CoBuyerCustomerCode);
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = requestDataModel.DocLine;
			List<InvoiceLineItem__c> invoiceLineItems = invoice.InvoiceLineItems__r;
			System.assertEquals(invoiceLineItems.size(), docLines.size());
			for (Integer invoiceLineIdx = 0; invoiceLineIdx < docLines.size() ; invoiceLineIdx++){
				PojjamanDataModel.FNGLDocLineRequest docLine = docLines[invoiceLineIdx];
				InvoiceLineItem__c invoiceLineItem = invoiceLineItems[invoiceLineIdx];
				System.assertEquals(Integer.valueOf(invoiceLineItem.LineNumber__c), docLine.LineNumber);
				System.assertEquals(invoiceLineItem.Invoice__r.Opportunity__r.Unit__r.ProductCode , docLine.UnitCode);
				System.assertEquals(invoiceLineItem.Term__c , docLine.Type);
				System.assertEquals(invoiceLineItem.Amount__c , docLine.Amount);
				System.assertEquals(null , docLine.IsDebit);
				System.assertEquals(invoiceLineItem.Id , docLine.SFDocLineId);
				System.assertEquals(invoiceLineItem.Status__c , docLine.Status);
				System.assertEquals(invoiceLineItem.DueDate__c , docLine.DueDate);
				System.assertEquals(null, docLine.RefInvoiceId);
			}
			System.assertEquals(null, requestDataModel.PaymentMethod);
		}
		// ----- Check Receipt -----
		for (Integer receiptIdx = 0 ; receiptIdx < receiptRequestModels.size(); receiptIdx ++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = receiptRequestModels[receiptIdx];
			PaymentReceipt__c receipt = receiptWithReceiptLineItemsMapById.values()[receiptIdx];
			System.assertNotEquals(null, requestDataModel.CustomerCode);
			System.assertEquals(receipt.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(receipt.Id, requestDataModel.SFDocId);
			System.assertEquals(receipt.CreatedDate.date(), requestDataModel.DocDate);
			System.assertEquals('GL', requestDataModel.DocType);
			System.assertEquals(receipt.ReceiptNo__c, requestDataModel.ReceiptCode);
			System.assertEquals(null, requestDataModel.InvoiceCode);
			System.assertEquals(4, requestDataModel.Indicator);
			System.assertEquals(receipt.GLKey__c, requestDataModel.GroupKey);
			System.assertEquals(receipt.GLDate__c, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(null, requestDataModel.CoBuyerCustomerCode);
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = requestDataModel.DocLine;
			List<PaymentReceiptLineItem__c> receiptItems = receipt.Payment_Transactions__r;
			System.assertEquals(receiptItems.size(), docLines.size());
			for (Integer receiptLineIdx = 0; receiptLineIdx < docLines.size() ; receiptLineIdx++){
				PojjamanDataModel.FNGLDocLineRequest docLine = docLines[receiptLineIdx];
				PaymentReceiptLineItem__c receiptLineItem = receiptItems[receiptLineIdx];
				System.assertEquals(receiptLineIdx + 1, docLine.LineNumber);
				System.assertEquals(receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode , docLine.UnitCode);
				System.assertEquals(receiptLineItem.OpportunityPayment__r.Term__c , docLine.Type);
				System.assertEquals(receiptLineItem.ReceivedAmount__c , docLine.Amount);
				System.assertEquals(true , docLine.IsDebit);
				System.assertEquals(receiptLineItem.Id , docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Status__c , docLine.Status);
				System.assertEquals(null , docLine.DueDate);
				System.assertEquals(receiptLineItem.InvoiceLineItem__r.Invoice__c, docLine.RefInvoiceId);
			}
			System.assertEquals(null, requestDataModel.PaymentMethod);
		}
		List<PaymentReceipt__c> targetPaymentReceipts = [
			SELECT
				Id,
				AccountAddress__c,
				CreatedDate,
				DueDate__c,
				IsCancel__c,
				CancelReason__c,
				LastIntegrationDateTime__c,
				LastCreatedStatusInPojjaman__c,
				LastCancelledStatusInPojjaman__c,
				Opportunity__c,
				ReceiptNo__c,
				ResponseCode__c,
				ResponseMessage__c,
				TotalReceiveAmount__c,
				GLKey__c,
				GLDate__c,
				CustomGLKey__c,
				CustomGLDate__c,
				Opportunity__r.Account.AccountCode__c,
				Opportunity__r.Project__r.ProjectCode__c,
				CoBuyerAccountCode__c,
				ReceiptType__c,
				PreviousCustomerCode__c,
				(
					SELECT
						Id,
						InvoiceLineItem__c,
						InvoiceLineItem__r.Invoice__c,
						ReceivedAmount__c,
						RemainingAmount__c,
						Status__c,
						PreviousRemaining__c,
						OpportunityPayment__c,
						OpportunityPayment__r.Term__c,
						OpportunityPayment__r.DueDate__c,
						OpportunityPayment__r.Remaining__c,
						OpportunityPayment__r.ReceivedAmount__c,
						OpportunityPayment__r.PaymentStatus__c,
						OpportunityPayment__r.Order__c,
						TransactionDateTime__c,
						PaymentReceipt__r.TotalReceiveAmount__c,
						PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode,
						ResponseCode__c,
						ResponseMessage__c,
						LastIntegrationDateTime__c,
						ReceiptLineItemType__c
					FROM Payment_Transactions__r
					ORDER BY OpportunityPayment__r.Order__c, Name
				),
				(
					SELECT
						Id,
						PaymentType__c,
						CreditCardNo__c,
						DebitCardNo__c,
						ChequeNo__c,
						BankBranch__c,
						BankName__c,
						BankAccountNo__c,
						CompanyBank__r.BankAccountNumber__c,
						PaymentDate__c,
						ReceivedAmount__c,
						InternationalBankName__c,
						ResponseCode__c,
						ResponseMessage__c,
						LastIntegrationDateTime__c
					FROM PaymentMethods__r
				)
			FROM PaymentReceipt__c
			WHERE (LastModifiedDate = TODAY
			OR LastCreatedStatusInPojjaman__c = null
			OR LastCreatedStatusInPojjaman__c = 'Fail'
			OR LastCancelledStatusInPojjaman__c = 'Fail') AND
			ReceiptType__c !=: GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT AND
			(CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_UPGRADE AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_DOWNGRADE AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_MOVEPAYMENT AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_CANCELREFUND AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONREFUND AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_CANCELFORFEIT AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONFORFEIT)
			ORDER BY CreatedDate ASC
		];
		System.assertEquals(2, targetPaymentReceipts.size());
		CreateReceiptApiCallout callout2 = new CreateReceiptApiCallout(targetPaymentReceipts);
		Object request2 = callout2.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels2 = (List<PojjamanDataModel.FNGLDocRequest>) request2;
		System.assertNotEquals(0, requestModels2.size());
		System.assertNotEquals(null, request2);
		System.assertEquals(targetPaymentReceipts.size(), requestModels2.size());
		for (Integer i = 0; i < targetPaymentReceipts.size(); i++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = requestModels2[i];
			PaymentReceipt__c receipt = targetPaymentReceipts[i];
			System.assertEquals(receipt.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(receipt.Id, requestDataModel.SFDocId);
			System.assertEquals(receipt.CreatedDate.date(), requestDataModel.DocDate);
			if (receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT){
				System.assertEquals('GL', requestDataModel.DocType);
			}
			System.assertEquals(receipt.ReceiptNo__c, requestDataModel.ReceiptCode);
			System.assertEquals(null, requestDataModel.InvoiceCode);
			System.assertEquals(5, requestDataModel.Indicator);
			System.assertEquals(receipt.CustomGLKey__c, requestDataModel.GroupKey);
			System.assertEquals(receipt.CustomGLDate__c, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(null, requestDataModel.CoBuyerCustomerCode);
			List<PaymentReceiptLineItem__c> targetReceiptLineItems = receipt.Payment_Transactions__r;
			List<PojjamanDataModel.FNGLDocLineRequest> requestLineModels = requestDataModel.DocLine;
			System.assertEquals(targetReceiptLineItems.size(), requestLineModels.size());
			for (Integer j = 0; j < targetReceiptLineItems.size(); j++){
				PojjamanDataModel.FNGLDocLineRequest docLine = requestLineModels[j];
				PaymentReceiptLineItem__c receiptLineItem = targetReceiptLineItems[j];
				System.assertEquals(1, docLine.LineNumber);
				System.assertEquals(receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode, docLine.UnitCode);
				if (receiptLineItem.ReceiptLineItemType__c == GlobalConstants.RECEIPTLINE_TYPE_OPERATION){
					System.assertEquals(receiptLineItem.ReceiptLineItemType__c, docLine.Type);
				} else {
					System.assertEquals(receiptLineItem.OpportunityPayment__r.Term__c, docLine.Type);
				}
				System.assertEquals(receiptLineItem.ReceivedAmount__c, docLine.Amount);
				if (receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT){
					System.assertEquals(false, docLine.IsDebit);
				}
				System.assertEquals(receiptLineItem.Id, docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Status__c, docLine.Status);
				System.assertEquals(null, docLine.DueDate);
				System.assertEquals(null, docLine.RefInvoiceId);
			}
		}
	}

	@isTest
	static void upgradeNoOperationFeePositiveCase(){
		List<Opportunity> opportunities = [SELECT Id FROM Opportunity];
		Opportunity oldOpp = opportunities[0];
        Opportunity newOpp =  opportunities[1];

		String receiptType = GlobalConstants.RECEIPT_TYPE_DEFAULT;
		String paymentMethodType = 'Credit Card';
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		service.createPaymentReceiptWithLineItem(oldOpp.Id, 100000, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(oldOpp.Id, 100000, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(oldOpp.Id, 100000, receiptType, paymentMethodType);

        // Create PaymentMethod
        PaymentMethod__c paymentMethod = new PaymentMethod__c(
            PaymentType__c = 'Upgrade',
            PaymentDate__c = Date.today(),
            ReceivedAmount__c = 300000
        );

        // Prepare NewOpportunityItem
        OpportunityMoverController.NewOpportunityItem item = new OpportunityMoverController.NewOpportunityItem();
        item.opportunityId = newOpp.Id;
        item.amountToMove = 300000;

        String newOppJSON = JSON.serialize(item);

        List<Id> selectedIds = new List<Id>(); // empty for now

        OpportunityMoverController.MoveOpportunityResult result = OpportunityMoverController.completeAction(
            oldOpp.Id,
            'upgrade',
			'reason',
            0,
			100000,
            'https://example.com',
            newOppJSON,
            paymentMethod,
            selectedIds,
			true
        );

		List<Opportunity> targetOpportunities = [
			SELECT
					Id,
					Unit__r.ProductCode,
					LastGLStatusInPojjaman__c,
					LastIntegrationDateTime__c,
					(
						SELECT Id, LastGLStatusInPojjaman__c
						FROM Invoices__r
						ORDER BY CreatedDate ASC
					),
					(
						SELECT 	Id,
								IsCancel__c,
								CancelReason__c,
								LastGLStatusInPojjaman__c
						FROM PaymentReceipt__r
						WHERE
							(CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_UPGRADE OR
							CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_DOWNGRADE OR
							CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_MOVEPAYMENT)
						ORDER BY CreatedDate ASC
					)
				FROM Opportunity
				WHERE (
						StageName =: GlobalConstants.OPP_STAGENAME_CLOSED_LOST AND
						(LossReason__c =: GlobalConstants.OPP_LOST_REASON_UPGRADE OR
						LossReason__c =: GlobalConstants.OPP_LOST_REASON_DOWNGRADE OR
						LossReason__c =: GlobalConstants.OPP_LOST_REASON_PURCHASEOTHERNAME OR
						LossReason__c =: GlobalConstants.OPP_LOST_REASON_MOVEPAYMENT ) AND
						(LastGLStatusInPojjaman__c = null OR LastGLStatusInPojjaman__c = 'Fail')
					)
				ORDER BY LastModifiedDate ASC
			];
		System.assertEquals(1, targetOpportunities.size());

		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		Set<Id> receiptIds = new Set<Id>();
		Set<Id> invoiceIds = new Set<Id>();
		for (Opportunity opportunity : targetOpportunities) {
			List<Invoice__c> invoices = opportunity.Invoices__r;
			for (Invoice__c invoice : invoices) {
				invoiceIds.add(invoice.Id);
			}
			List<PaymentReceipt__c> paymentReceipts = opportunity.PaymentReceipt__r;
			for (PaymentReceipt__c paymentReceipt : paymentReceipts) {
				receiptIds.add(paymentReceipt.Id);
			}
		}
		Map<Id, Invoice__c> invoiceWithInvoiceLineItemsMapById = invoiceSelector.getInvoiceWithInvoiceLineItemsMapById(
			invoiceIds
		);
		List<Invoice__c> remainedInvoice = new List<Invoice__c>();
		for(Invoice__c invoice: invoiceWithInvoiceLineItemsMapById.values()){
			InvoiceLineItem__c invoiceLineItem = invoice.InvoiceLineItems__r[0];
			if (invoiceLineItem.OpportunityPayment__r.Remaining__c > 0){
				remainedInvoice.add(invoice);
			}
		}

		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			receiptIds
		);
		GLChangeUnitApiCallout callout = new GLChangeUnitApiCallout(targetOpportunities);
		Object request = callout.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(null, request);
		System.assertEquals(remainedInvoice.size() + receiptWithReceiptLineItemsMapById.values().size(), requestModels.size());
		List<PojjamanDataModel.FNGLDocRequest> invoiceRequestModels = new List<PojjamanDataModel.FNGLDocRequest>();
		List<PojjamanDataModel.FNGLDocRequest> receiptRequestModels = new List<PojjamanDataModel.FNGLDocRequest>();
		for(PojjamanDataModel.FNGLDocRequest requestModel : requestModels ){
			if (requestModel.InvoiceCode != null){
				invoiceRequestModels.add(requestModel);
			} else {
				receiptRequestModels.add(requestModel);
			}
		}
		System.assertEquals(remainedInvoice.size(), invoiceRequestModels.size());
		System.assertEquals(0, remainedInvoice.size());
		System.assertEquals(receiptWithReceiptLineItemsMapById.values().size(), receiptRequestModels.size());
		System.assertEquals(3, receiptRequestModels.size());
		// ----- Check Invoice -----
		for (Integer invoiceIdx = 0 ; invoiceIdx < invoiceRequestModels.size(); invoiceIdx ++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = invoiceRequestModels[invoiceIdx];
			Invoice__c invoice = remainedInvoice[invoiceIdx];
			System.assertNotEquals(null, requestDataModel.CustomerCode);
			System.assertEquals(invoice.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(invoice.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(invoice.Id, requestDataModel.SFDocId);
			System.assertEquals(invoice.CreatedDate.date(), requestDataModel.DocDate);
			System.assertEquals('GL', requestDataModel.DocType);
			System.assertEquals(null, requestDataModel.ReceiptCode);
			System.assertEquals(invoice.InvoiceNo__c, requestDataModel.InvoiceCode);
			System.assertEquals(2, requestDataModel.Indicator);
			System.assertEquals(invoice.GLKey__c, requestDataModel.GroupKey);
			System.assertEquals(invoice.GLDate__c, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(null, requestDataModel.CoBuyerCustomerCode);
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = requestDataModel.DocLine;
			List<InvoiceLineItem__c> invoiceLineItems = invoice.InvoiceLineItems__r;
			System.assertEquals(invoiceLineItems.size(), docLines.size());
			for (Integer invoiceLineIdx = 0; invoiceLineIdx < docLines.size() ; invoiceLineIdx++){
				PojjamanDataModel.FNGLDocLineRequest docLine = docLines[invoiceLineIdx];
				InvoiceLineItem__c invoiceLineItem = invoiceLineItems[invoiceLineIdx];
				System.assertEquals(Integer.valueOf(invoiceLineItem.LineNumber__c), docLine.LineNumber);
				System.assertEquals(invoiceLineItem.Invoice__r.Opportunity__r.Unit__r.ProductCode , docLine.UnitCode);
				System.assertEquals(invoiceLineItem.Term__c , docLine.Type);
				System.assertEquals(invoiceLineItem.Amount__c , docLine.Amount);
				System.assertEquals(null , docLine.IsDebit);
				System.assertEquals(invoiceLineItem.Id , docLine.SFDocLineId);
				System.assertEquals(invoiceLineItem.Status__c , docLine.Status);
				System.assertEquals(invoiceLineItem.DueDate__c , docLine.DueDate);
				System.assertEquals(null, docLine.RefInvoiceId);
			}
			System.assertEquals(null, requestDataModel.PaymentMethod);
		}
		// ----- Check Receipt -----
		for (Integer receiptIdx = 0 ; receiptIdx < receiptRequestModels.size(); receiptIdx ++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = receiptRequestModels[receiptIdx];
			PaymentReceipt__c receipt = receiptWithReceiptLineItemsMapById.values()[receiptIdx];
			System.assertNotEquals(null, requestDataModel.CustomerCode);
			System.assertEquals(receipt.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(receipt.Id, requestDataModel.SFDocId);
			System.assertEquals(receipt.CreatedDate.date(), requestDataModel.DocDate);
			System.assertEquals('GL', requestDataModel.DocType);
			System.assertEquals(receipt.ReceiptNo__c, requestDataModel.ReceiptCode);
			System.assertEquals(null, requestDataModel.InvoiceCode);
			System.assertEquals(4, requestDataModel.Indicator);
			System.assertEquals(receipt.GLKey__c, requestDataModel.GroupKey);
			System.assertEquals(receipt.GLDate__c, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(null, requestDataModel.CoBuyerCustomerCode);
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = requestDataModel.DocLine;
			List<PaymentReceiptLineItem__c> receiptItems = receipt.Payment_Transactions__r;
			System.assertEquals(receiptItems.size(), docLines.size());
			for (Integer receiptLineIdx = 0; receiptLineIdx < docLines.size() ; receiptLineIdx++){
				PojjamanDataModel.FNGLDocLineRequest docLine = docLines[receiptLineIdx];
				PaymentReceiptLineItem__c receiptLineItem = receiptItems[receiptLineIdx];
				System.assertEquals(receiptLineIdx + 1, docLine.LineNumber);
				System.assertEquals(receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode , docLine.UnitCode);
				System.assertEquals(receiptLineItem.OpportunityPayment__r.Term__c , docLine.Type);
				System.assertEquals(receiptLineItem.ReceivedAmount__c , docLine.Amount);
				System.assertEquals(true , docLine.IsDebit);
				System.assertEquals(receiptLineItem.Id , docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Status__c , docLine.Status);
				System.assertEquals(null , docLine.DueDate);
				System.assertEquals(receiptLineItem.InvoiceLineItem__r.Invoice__c, docLine.RefInvoiceId);
			}
			System.assertEquals(null, requestDataModel.PaymentMethod);
		}
		List<PaymentReceipt__c> targetPaymentReceipts = [
			SELECT
				Id,
				AccountAddress__c,
				CreatedDate,
				DueDate__c,
				IsCancel__c,
				CancelReason__c,
				LastIntegrationDateTime__c,
				LastCreatedStatusInPojjaman__c,
				LastCancelledStatusInPojjaman__c,
				Opportunity__c,
				ReceiptNo__c,
				ResponseCode__c,
				ResponseMessage__c,
				TotalReceiveAmount__c,
				CustomGLKey__c,
				CustomGLDate__c,
				GLKey__c,
				GLDate__c,
				Opportunity__r.Account.AccountCode__c,
				Opportunity__r.Project__r.ProjectCode__c,
				CoBuyerAccountCode__c,
				ReceiptType__c,
				PreviousCustomerCode__c,
				(
					SELECT
						Id,
						InvoiceLineItem__c,
						InvoiceLineItem__r.Invoice__c,
						ReceivedAmount__c,
						RemainingAmount__c,
						Status__c,
						PreviousRemaining__c,
						OpportunityPayment__c,
						OpportunityPayment__r.Term__c,
						OpportunityPayment__r.DueDate__c,
						OpportunityPayment__r.Remaining__c,
						OpportunityPayment__r.ReceivedAmount__c,
						OpportunityPayment__r.PaymentStatus__c,
						OpportunityPayment__r.Order__c,
						TransactionDateTime__c,
						PaymentReceipt__r.TotalReceiveAmount__c,
						PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode,
						ResponseCode__c,
						ResponseMessage__c,
						LastIntegrationDateTime__c,
						ReceiptLineItemType__c
					FROM Payment_Transactions__r
					ORDER BY OpportunityPayment__r.Order__c, Name
				),
				(
					SELECT
						Id,
						PaymentType__c,
						CreditCardNo__c,
						DebitCardNo__c,
						ChequeNo__c,
						BankBranch__c,
						BankName__c,
						BankAccountNo__c,
						CompanyBank__r.BankAccountNumber__c,
						PaymentDate__c,
						ReceivedAmount__c,
						InternationalBankName__c,
						ResponseCode__c,
						ResponseMessage__c,
						LastIntegrationDateTime__c
					FROM PaymentMethods__r
				)
			FROM PaymentReceipt__c
			WHERE (LastModifiedDate = TODAY
			OR LastCreatedStatusInPojjaman__c = null
			OR LastCreatedStatusInPojjaman__c = 'Fail'
			OR LastCancelledStatusInPojjaman__c = 'Fail') AND
			ReceiptType__c !=: GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT AND
			(CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_UPGRADE AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_DOWNGRADE AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_MOVEPAYMENT AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_CANCELREFUND AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONREFUND AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_CANCELFORFEIT AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONFORFEIT)
			ORDER BY CreatedDate ASC
		];
		System.assertEquals(1, targetPaymentReceipts.size());
		CreateReceiptApiCallout callout2 = new CreateReceiptApiCallout(targetPaymentReceipts);
		Object request2 = callout2.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels2 = (List<PojjamanDataModel.FNGLDocRequest>) request2;
		System.assertNotEquals(0, requestModels2.size());
		System.assertNotEquals(null, request2);
		System.assertEquals(targetPaymentReceipts.size(), requestModels2.size());
		for (Integer i = 0; i < targetPaymentReceipts.size(); i++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = requestModels2[i];
			PaymentReceipt__c receipt = targetPaymentReceipts[i];
			System.assertEquals(receipt.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(receipt.Id, requestDataModel.SFDocId);
			System.assertEquals(receipt.CreatedDate.date(), requestDataModel.DocDate);
			if (receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT){
				System.assertEquals('GL', requestDataModel.DocType);
			}
			System.assertEquals(receipt.ReceiptNo__c, requestDataModel.ReceiptCode);
			System.assertEquals(null, requestDataModel.InvoiceCode);
			System.assertEquals(5, requestDataModel.Indicator);
			System.assertEquals(receipt.CustomGLKey__c, requestDataModel.GroupKey);
			System.assertEquals(receipt.CustomGLDate__c, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(null, requestDataModel.CoBuyerCustomerCode);
			List<PaymentReceiptLineItem__c> targetReceiptLineItems = receipt.Payment_Transactions__r;
			List<PojjamanDataModel.FNGLDocLineRequest> requestLineModels = requestDataModel.DocLine;
			System.assertEquals(targetReceiptLineItems.size(), requestLineModels.size());
			for (Integer j = 0; j < targetReceiptLineItems.size(); j++){
				PojjamanDataModel.FNGLDocLineRequest docLine = requestLineModels[j];
				PaymentReceiptLineItem__c receiptLineItem = targetReceiptLineItems[j];
				System.assertEquals(1, docLine.LineNumber);
				System.assertEquals(receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode, docLine.UnitCode);
				if (receiptLineItem.ReceiptLineItemType__c == GlobalConstants.RECEIPTLINE_TYPE_OPERATION){
					System.assertEquals(receiptLineItem.ReceiptLineItemType__c, docLine.Type);
				} else {
					System.assertEquals(receiptLineItem.OpportunityPayment__r.Term__c, docLine.Type);
				}
				System.assertEquals(receiptLineItem.ReceivedAmount__c, docLine.Amount);
				if (receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT){
					System.assertEquals(false, docLine.IsDebit);
				}
				System.assertEquals(receiptLineItem.Id, docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Status__c, docLine.Status);
				System.assertEquals(null, docLine.DueDate);
				System.assertEquals(null, docLine.RefInvoiceId);
			}
		}
	}

	@isTest
	static void movePaymentNoOperationFeePositiveCase(){
		List<Opportunity> opportunities = [SELECT Id FROM Opportunity];
		Opportunity oldOpp = opportunities[0];
        Opportunity newOpp =  opportunities[1];
		Opportunity anotherNewOpp =  opportunities[2];

		String receiptType = GlobalConstants.RECEIPT_TYPE_DEFAULT;
		String paymentMethodType = 'Credit Card';
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		Test.startTest();
		service.createPaymentReceiptWithLineItem(oldOpp.Id, 100000, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(oldOpp.Id, 100000, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(oldOpp.Id, 100000, receiptType, paymentMethodType);

		service.createPaymentReceiptWithLineItem(newOpp.Id, 100000, receiptType, paymentMethodType);

		service.createPaymentReceiptWithLineItem(anotherNewOpp.Id, 100000, receiptType, paymentMethodType);
		Test.stopTest();

        // Create PaymentMethod
        PaymentMethod__c paymentMethod = new PaymentMethod__c(
            PaymentType__c = 'Move Payment',
            PaymentDate__c = Date.today(),
            ReceivedAmount__c = 150000
        );

		PaymentMethod__c paymentMethod2 = new PaymentMethod__c(
            PaymentType__c = 'Move Payment',
            PaymentDate__c = Date.today(),
            ReceivedAmount__c = 150000
        );

        // Prepare NewOpportunityItem
        OpportunityMoverController.NewOpportunityItem item = new OpportunityMoverController.NewOpportunityItem();
        item.opportunityId = newOpp.Id;
        item.amountToMove = 300000;

        String newOppJSON = JSON.serialize(item);

		OpportunityMoverController.NewOpportunityItem item2 = new OpportunityMoverController.NewOpportunityItem();
        item2.opportunityId = anotherNewOpp.Id;
        item2.amountToMove = 300000;

        String newOppJSON2 = JSON.serialize(item2);

        List<Id> selectedIds = new List<Id>(); // empty for now

        OpportunityMoverController.MoveOpportunityResult result = OpportunityMoverController.completeAction(
            oldOpp.Id,
            'move_payment',
			'reason',
            0,
			150000,
            'https://example.com',
            newOppJSON,
            paymentMethod,
            selectedIds,
			true
        );

		OpportunityMoverController.MoveOpportunityResult result2 = OpportunityMoverController.completeAction(
            oldOpp.Id,
            'move_payment',
			'reason',
            0,
			150000,
            'https://example.com',
            newOppJSON2,
            paymentMethod2,
            selectedIds,
			false
        );

		List<Opportunity> targetOpportunities = [
			SELECT
					Id,
					Unit__r.ProductCode,
					LastGLStatusInPojjaman__c,
					LastIntegrationDateTime__c,
					(
						SELECT Id, LastGLStatusInPojjaman__c
						FROM Invoices__r
						ORDER BY CreatedDate ASC
					),
					(
						SELECT 	Id,
								IsCancel__c,
								CancelReason__c,
								LastGLStatusInPojjaman__c
						FROM PaymentReceipt__r
						WHERE
							(CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_UPGRADE OR
							CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_DOWNGRADE OR
							CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_MOVEPAYMENT)
						ORDER BY CreatedDate ASC
					)
				FROM Opportunity
				WHERE (
						StageName =: GlobalConstants.OPP_STAGENAME_CLOSED_LOST AND
						(LossReason__c =: GlobalConstants.OPP_LOST_REASON_UPGRADE OR
						LossReason__c =: GlobalConstants.OPP_LOST_REASON_DOWNGRADE OR
						LossReason__c =: GlobalConstants.OPP_LOST_REASON_PURCHASEOTHERNAME OR
						LossReason__c =: GlobalConstants.OPP_LOST_REASON_MOVEPAYMENT ) AND
						(LastGLStatusInPojjaman__c = null OR LastGLStatusInPojjaman__c = 'Fail')
					)
				ORDER BY LastModifiedDate ASC
			];
		System.assertEquals(1, targetOpportunities.size());

		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		Set<Id> receiptIds = new Set<Id>();
		Set<Id> invoiceIds = new Set<Id>();
		for (Opportunity opportunity : targetOpportunities) {
			List<Invoice__c> invoices = opportunity.Invoices__r;
			for (Invoice__c invoice : invoices) {
				invoiceIds.add(invoice.Id);
			}
			List<PaymentReceipt__c> paymentReceipts = opportunity.PaymentReceipt__r;
			for (PaymentReceipt__c paymentReceipt : paymentReceipts) {
				receiptIds.add(paymentReceipt.Id);
			}
		}
		Map<Id, Invoice__c> invoiceWithInvoiceLineItemsMapById = invoiceSelector.getInvoiceWithInvoiceLineItemsMapById(
			invoiceIds
		);
		List<Invoice__c> remainedInvoice = new List<Invoice__c>();
		for(Invoice__c invoice: invoiceWithInvoiceLineItemsMapById.values()){
			InvoiceLineItem__c invoiceLineItem = invoice.InvoiceLineItems__r[0];
			if (invoiceLineItem.OpportunityPayment__r.Remaining__c > 0){
				remainedInvoice.add(invoice);
			}
		}

		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			receiptIds
		);
		GLChangeUnitApiCallout callout = new GLChangeUnitApiCallout(targetOpportunities);
		Object request = callout.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(null, request);
		System.assertEquals(remainedInvoice.size() + receiptWithReceiptLineItemsMapById.values().size(), requestModels.size());
		List<PojjamanDataModel.FNGLDocRequest> invoiceRequestModels = new List<PojjamanDataModel.FNGLDocRequest>();
		List<PojjamanDataModel.FNGLDocRequest> receiptRequestModels = new List<PojjamanDataModel.FNGLDocRequest>();
		for(PojjamanDataModel.FNGLDocRequest requestModel : requestModels ){
			if (requestModel.InvoiceCode != null){
				invoiceRequestModels.add(requestModel);
			} else {
				receiptRequestModels.add(requestModel);
			}
		}
		System.assertEquals(remainedInvoice.size(), invoiceRequestModels.size());
		System.assertEquals(0, remainedInvoice.size());
		System.assertEquals(receiptWithReceiptLineItemsMapById.values().size(), receiptRequestModels.size());
		System.assertEquals(3, receiptRequestModels.size());
		// ----- Check Invoice -----
		for (Integer invoiceIdx = 0 ; invoiceIdx < invoiceRequestModels.size(); invoiceIdx ++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = invoiceRequestModels[invoiceIdx];
			Invoice__c invoice = remainedInvoice[invoiceIdx];
			System.assertNotEquals(null, requestDataModel.CustomerCode);
			System.assertEquals(invoice.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(invoice.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(invoice.Id, requestDataModel.SFDocId);
			System.assertEquals(invoice.CreatedDate.date(), requestDataModel.DocDate);
			System.assertEquals('GL', requestDataModel.DocType);
			System.assertEquals(null, requestDataModel.ReceiptCode);
			System.assertEquals(invoice.InvoiceNo__c, requestDataModel.InvoiceCode);
			System.assertEquals(2, requestDataModel.Indicator);
			System.assertEquals(invoice.GLKey__c, requestDataModel.GroupKey);
			System.assertEquals(invoice.GLDate__c, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(null, requestDataModel.CoBuyerCustomerCode);
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = requestDataModel.DocLine;
			List<InvoiceLineItem__c> invoiceLineItems = invoice.InvoiceLineItems__r;
			System.assertEquals(invoiceLineItems.size(), docLines.size());
			for (Integer invoiceLineIdx = 0; invoiceLineIdx < docLines.size() ; invoiceLineIdx++){
				PojjamanDataModel.FNGLDocLineRequest docLine = docLines[invoiceLineIdx];
				InvoiceLineItem__c invoiceLineItem = invoiceLineItems[invoiceLineIdx];
				System.assertEquals(Integer.valueOf(invoiceLineItem.LineNumber__c), docLine.LineNumber);
				System.assertEquals(invoiceLineItem.Invoice__r.Opportunity__r.Unit__r.ProductCode , docLine.UnitCode);
				System.assertEquals(invoiceLineItem.Term__c , docLine.Type);
				System.assertEquals(invoiceLineItem.Amount__c , docLine.Amount);
				System.assertEquals(null , docLine.IsDebit);
				System.assertEquals(invoiceLineItem.Id , docLine.SFDocLineId);
				System.assertEquals(invoiceLineItem.Status__c , docLine.Status);
				System.assertEquals(invoiceLineItem.DueDate__c , docLine.DueDate);
				System.assertEquals(null, docLine.RefInvoiceId);
			}
			System.assertEquals(null, requestDataModel.PaymentMethod);
		}
		// ----- Check Receipt -----
		for (Integer receiptIdx = 0 ; receiptIdx < receiptRequestModels.size(); receiptIdx ++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = receiptRequestModels[receiptIdx];
			PaymentReceipt__c receipt = receiptWithReceiptLineItemsMapById.values()[receiptIdx];
			System.assertNotEquals(null, requestDataModel.CustomerCode);
			System.assertEquals(receipt.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(receipt.Id, requestDataModel.SFDocId);
			System.assertEquals(receipt.CreatedDate.date(), requestDataModel.DocDate);
			System.assertEquals('GL', requestDataModel.DocType);
			System.assertEquals(receipt.ReceiptNo__c, requestDataModel.ReceiptCode);
			System.assertEquals(null, requestDataModel.InvoiceCode);
			System.assertEquals(4, requestDataModel.Indicator);
			System.assertEquals(receipt.GLKey__c, requestDataModel.GroupKey);
			System.assertEquals(receipt.GLDate__c, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(null, requestDataModel.CoBuyerCustomerCode);
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = requestDataModel.DocLine;
			List<PaymentReceiptLineItem__c> receiptItems = receipt.Payment_Transactions__r;
			System.assertEquals(receiptItems.size(), docLines.size());
			for (Integer receiptLineIdx = 0; receiptLineIdx < docLines.size() ; receiptLineIdx++){
				PojjamanDataModel.FNGLDocLineRequest docLine = docLines[receiptLineIdx];
				PaymentReceiptLineItem__c receiptLineItem = receiptItems[receiptLineIdx];
				System.assertEquals(receiptLineIdx + 1, docLine.LineNumber);
				System.assertEquals(receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode , docLine.UnitCode);
				System.assertEquals(receiptLineItem.OpportunityPayment__r.Term__c , docLine.Type);
				System.assertEquals(receiptLineItem.ReceivedAmount__c , docLine.Amount);
				System.assertEquals(true , docLine.IsDebit);
				System.assertEquals(receiptLineItem.Id , docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Status__c , docLine.Status);
				System.assertEquals(null , docLine.DueDate);
				System.assertEquals(receiptLineItem.InvoiceLineItem__r.Invoice__c, docLine.RefInvoiceId);
			}
			System.assertEquals(null, requestDataModel.PaymentMethod);
		}
		List<PaymentReceipt__c> targetPaymentReceipts = [
			SELECT
				Id,
				AccountAddress__c,
				CreatedDate,
				DueDate__c,
				IsCancel__c,
				CancelReason__c,
				LastIntegrationDateTime__c,
				LastCreatedStatusInPojjaman__c,
				LastCancelledStatusInPojjaman__c,
				Opportunity__c,
				ReceiptNo__c,
				ResponseCode__c,
				ResponseMessage__c,
				TotalReceiveAmount__c,
				GLKey__c,
				GLDate__c,
				CustomGLKey__c,
				CustomGLDate__c,
				Opportunity__r.Account.AccountCode__c,
				Opportunity__r.Project__r.ProjectCode__c,
				CoBuyerAccountCode__c,
				ReceiptType__c,
				PreviousCustomerCode__c,
				(
					SELECT
						Id,
						InvoiceLineItem__c,
						InvoiceLineItem__r.Invoice__c,
						ReceivedAmount__c,
						RemainingAmount__c,
						Status__c,
						PreviousRemaining__c,
						OpportunityPayment__c,
						OpportunityPayment__r.Term__c,
						OpportunityPayment__r.DueDate__c,
						OpportunityPayment__r.Remaining__c,
						OpportunityPayment__r.ReceivedAmount__c,
						OpportunityPayment__r.PaymentStatus__c,
						OpportunityPayment__r.Order__c,
						TransactionDateTime__c,
						PaymentReceipt__r.TotalReceiveAmount__c,
						PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode,
						ResponseCode__c,
						ResponseMessage__c,
						LastIntegrationDateTime__c,
						ReceiptLineItemType__c
					FROM Payment_Transactions__r
					ORDER BY OpportunityPayment__r.Order__c, Name
				),
				(
					SELECT
						Id,
						PaymentType__c,
						CreditCardNo__c,
						DebitCardNo__c,
						ChequeNo__c,
						BankBranch__c,
						BankName__c,
						BankAccountNo__c,
						CompanyBank__r.BankAccountNumber__c,
						PaymentDate__c,
						ReceivedAmount__c,
						InternationalBankName__c,
						ResponseCode__c,
						ResponseMessage__c,
						LastIntegrationDateTime__c
					FROM PaymentMethods__r
				)
			FROM PaymentReceipt__c
			WHERE (LastModifiedDate = TODAY
			OR LastCreatedStatusInPojjaman__c = null
			OR LastCreatedStatusInPojjaman__c = 'Fail'
			OR LastCancelledStatusInPojjaman__c = 'Fail') AND
			ReceiptType__c !=: GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT AND
			(CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_UPGRADE AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_DOWNGRADE AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_MOVEPAYMENT AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_CANCELREFUND AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONREFUND AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_CANCELFORFEIT AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONFORFEIT)
			ORDER BY CreatedDate ASC
		];
		System.assertEquals(4, targetPaymentReceipts.size());
		CreateReceiptApiCallout callout2 = new CreateReceiptApiCallout(targetPaymentReceipts);
		Object request2 = callout2.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels2 = (List<PojjamanDataModel.FNGLDocRequest>) request2;
		System.assertNotEquals(0, requestModels2.size());
		System.assertNotEquals(null, request2);
		System.assertEquals(targetPaymentReceipts.size(), requestModels2.size());
		for (Integer i = 0; i < targetPaymentReceipts.size(); i++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = requestModels2[i];
			PaymentReceipt__c receipt = targetPaymentReceipts[i];
			System.assertEquals(receipt.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(receipt.Id, requestDataModel.SFDocId);
			System.assertEquals(receipt.CreatedDate.date(), requestDataModel.DocDate);
			if (receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT){
				System.assertEquals('GL', requestDataModel.DocType);
			}
			System.assertEquals(receipt.ReceiptNo__c, requestDataModel.ReceiptCode);
			System.assertEquals(null, requestDataModel.InvoiceCode);
			if (receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT){
			// 	System.assertEquals(5, requestDataModel.Indicator);
			// } else {
				System.assertEquals(5, requestDataModel.Indicator);
			}
			System.assertEquals(receipt.CustomGLKey__c, requestDataModel.GroupKey);
			System.assertEquals(receipt.CustomGLDate__c, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(null, requestDataModel.CoBuyerCustomerCode);
			List<PaymentReceiptLineItem__c> targetReceiptLineItems = receipt.Payment_Transactions__r;
			List<PojjamanDataModel.FNGLDocLineRequest> requestLineModels = requestDataModel.DocLine;
			System.assertEquals(targetReceiptLineItems.size(), requestLineModels.size());
			for (Integer j = 0; j < targetReceiptLineItems.size(); j++){
				PojjamanDataModel.FNGLDocLineRequest docLine = requestLineModels[j];
				PaymentReceiptLineItem__c receiptLineItem = targetReceiptLineItems[j];
				System.assertEquals(1, docLine.LineNumber);
				System.assertEquals(receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode, docLine.UnitCode);
				System.assertEquals(receiptLineItem.OpportunityPayment__r.Term__c, docLine.Type);
				System.assertEquals(receiptLineItem.ReceivedAmount__c, docLine.Amount);
				if (receipt.ReceiptType__c == GlobalConstants.RECEIPT_TYPE_MOVEPAYMENT){
					System.assertEquals(false, docLine.IsDebit);
				}
				System.assertEquals(receiptLineItem.Id, docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Status__c, docLine.Status);
				System.assertEquals(null, docLine.DueDate);
				System.assertEquals(null, docLine.RefInvoiceId);
			}
		}
	}



}