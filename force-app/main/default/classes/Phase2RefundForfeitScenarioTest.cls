@isTest
public with sharing class Phase2RefundForfeitScenarioTest {
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
		List<Product2> products = new List<Product2>{testProduct};
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
		List<Opportunity> opportunities = new List<Opportunity>{ opp1 };
		insert opportunities;
		// Create Name Formatting
		NameFormattingMasterData__c format = dataMaker.createNameFormattingMasterData(
			'PaymentReceipt__c', 'Format', 'Object', 'RV-{Opportunity__r.Project__r.ProjectCode__c}{CreatedDate:FORMATDATETIME:yyMM}{RUNNINGNUMBER:000}', 1, null
		);
		insert format;
	}

	@isTest
	static void refundForfeitPositiveCase(){
		Opportunity targetOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
		Decimal amount = 100000;
		String receiptType = GlobalConstants.RECEIPT_TYPE_DEFAULT;
		String paymentMethodType = 'Credit Card';
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		service.createPaymentReceiptWithLineItem(targetOpportunity.Id, amount, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(targetOpportunity.Id, amount, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(targetOpportunity.Id, amount, receiptType, paymentMethodType);

		targetOpportunity.NetAgreedForfeitAmount__c = 100000;
		targetOpportunity.CancellationTerminationType__c = GlobalConstants.OPP_TERMINATION_TYPE_CANCELLATION;
		targetOpportunity.CancellationTerminationSubType__c = GlobalConstants.OPP_TERMINATION_SUBTYPE_FORFEIT;
		update targetOpportunity;

		Map<String,List<SObject>> result = CompleteRefundForfeitController.completeRefundForfeit(targetOpportunity.Id);
		List<Opportunity> opportunities = [
			SELECT
				Id,
				LastGLStatusInPojjaman__c,
				TotalOperationFee__c,
				NetAgreedRefundAmount__c,
				NetAgreedForfeitAmount__c,
				(
					SELECT Id, LastGLStatusInPojjaman__c
					FROM Invoices__r
					ORDER BY CreatedDate ASC
				),
				(
					SELECT Id,
					IsCancel__c,
					CancelReason__c, LastGLStatusInPojjaman__c
					FROM PaymentReceipt__r
					WHERE
					CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_CANCELREFUND OR
					CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_CANCELFORFEIT OR
					CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONREFUND OR
					CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONFORFEIT
					ORDER BY CreatedDate ASC
				)
			FROM Opportunity
			WHERE StageName =: GlobalConstants.OPP_STAGENAME_CLOSED_LOST AND
			(LastGLStatusInPojjaman__c = 'Fail' OR LastGLStatusInPojjaman__c = null) AND
			(LossReason__c =: GlobalConstants.OPP_LOST_REASON_CANCELFORFEIT OR
			LossReason__c =: GlobalConstants.OPP_LOST_REASON_TERMINATIONFORFEIT OR
			LossReason__c =: GlobalConstants.OPP_LOST_REASON_CANCELREFUND OR
			LossReason__c =: GlobalConstants.OPP_LOST_REASON_TERMINATIONREFUND )
			ORDER BY LastModifiedDate ASC
		];
		System.assertEquals(1, opportunities.size());
		List<PaymentReceipt__c> operationReceipts = [SELECT Id FROM PaymentReceipt__c WHERE ReceiptType__c =: GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT];
		System.assertEquals(1, operationReceipts.size());
		GLApiCallout callout = new GLApiCallout(opportunities);
		Object request = callout.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		Set<Id> receiptIds = new Set<Id>();
		Set<Id> invoiceIds = new Set<Id>();
		Set<Id> oppIds = new Set<Id>();
		for (Opportunity opportunity : opportunities) {
			oppIds.add(opportunity.Id);
			List<PaymentReceipt__c> paymentReceipts = opportunity.PaymentReceipt__r;
			for (PaymentReceipt__c paymentReceipt : paymentReceipts) {
				if (
					paymentReceipt.IsCancel__c &&
					(paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_CANCELREFUND ||
					paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_CANCELFORFEIT ||
					paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONREFUND ||
					paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONFORFEIT) &&
					(paymentReceipt.LastGLStatusInPojjaman__c == null ||
					paymentReceipt.LastGLStatusInPojjaman__c == 'Fail')
				) {
					receiptIds.add(paymentReceipt.Id);
				}
			}
			List<Invoice__c> invoices = opportunity.Invoices__r;
			for (Invoice__c invoice : invoices) {
				if (invoice.LastGLStatusInPojjaman__c == null || invoice.LastGLStatusInPojjaman__c == 'Fail') {
					invoiceIds.add(invoice.Id);
				}
			}
		}
		Map<Id, Invoice__c> invoiceWithInvoiceLineItemsMapById = invoiceSelector.getInvoiceWithInvoiceLineItemsMapById(
			invoiceIds
		);
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			receiptIds
		);
		Map<Id, List<PaymentReceipt__c>> refundForfeitPaymentReceiptByOppIdMapByOppId = receiptSelector.getRefundForfeitPaymentReceiptByOppIdMapByOppId(oppIds);
		List<PaymentReceipt__c> receipts = receiptWithReceiptLineItemsMapById.values();
		List<Invoice__c> invoices = invoiceWithInvoiceLineItemsMapById.values();
		List<PaymentReceipt__c> refundForfeitPaymentReceipts = refundForfeitPaymentReceiptByOppIdMapByOppId.get(targetOpportunity.Id);
		System.assertEquals(3, receipts.size());
		System.assertEquals(1, refundForfeitPaymentReceipts.size());
		System.assertEquals(0, invoices.size());
		Map<Id,PaymentReceipt__c> receiptMapById = new Map<Id,PaymentReceipt__c>();
		Map<Id,PaymentReceiptLineItem__c> receiptLineItemMapById = new Map<Id,PaymentReceiptLineItem__c>();
		for (PaymentReceipt__c eachReceipt: receipts){
			receiptMapById.put(eachReceipt.Id, eachReceipt);
			List<PaymentReceiptLineItem__c> receiptLines = eachReceipt.Payment_Transactions__r;
			for (PaymentReceiptLineItem__c eachReceiptLine : receiptLines){
				receiptLineItemMapById.put(eachReceiptLine.Id,eachReceiptLine);
			}
		}
		for (PaymentReceipt__c eachRefundReceipt : refundForfeitPaymentReceipts){
			receiptMapById.put(eachRefundReceipt.Id, eachRefundReceipt);
			List<PaymentReceiptLineItem__c> receiptLines = eachRefundReceipt.Payment_Transactions__r;
			for (PaymentReceiptLineItem__c eachReceiptLine : receiptLines){
				receiptLineItemMapById.put(eachReceiptLine.Id,eachReceiptLine);
			}
		}
		List<PojjamanDataModel.FNGLDocRequest> invoiceRequestModels = new List<PojjamanDataModel.FNGLDocRequest>();
		List<PojjamanDataModel.FNGLDocRequest> receiptRequestModels = new List<PojjamanDataModel.FNGLDocRequest>();
		for (PojjamanDataModel.FNGLDocRequest requestModel : requestModels) {
			if (requestModel.InvoiceCode != null){
				invoiceRequestModels.add(requestModel);
			} else {
				receiptRequestModels.add(requestModel);
			}
		}
		// ----- Check Invoice -----
		for (Integer invoiceIdx = 0 ; invoiceIdx < invoiceRequestModels.size(); invoiceIdx ++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = invoiceRequestModels[invoiceIdx];
			Invoice__c invoice = invoices[invoiceIdx];
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
			PaymentReceipt__c receipt = receiptMapById.get(requestDataModel.SFDocId);
			if (receipt.ReceiptType__c != GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT ){
				System.assertNotEquals(null, requestDataModel.CustomerCode);
				System.assertEquals(receipt.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
				System.assertEquals(null, requestDataModel.PreviousCustomerCode);
				System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
				System.assertEquals(receipt.Id, requestDataModel.SFDocId);
				System.assertEquals(receipt.CreatedDate.date(), requestDataModel.DocDate);
				System.assertEquals('GL', requestDataModel.DocType);
				System.assertEquals(receipt.ReceiptNo__c, requestDataModel.ReceiptCode);
				System.assertEquals(null, requestDataModel.InvoiceCode);
				System.assertEquals(0, requestDataModel.Indicator);
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
			} else {
				System.assertNotEquals(null, requestDataModel.CustomerCode);
				System.assertEquals(receipt.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
				System.assertEquals(null, requestDataModel.PreviousCustomerCode);
				System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
				System.assertEquals(receipt.Id, requestDataModel.SFDocId);
				System.assertEquals(receipt.CreatedDate.date(), requestDataModel.DocDate);
				System.assertEquals('GL', requestDataModel.DocType);
				System.assertEquals(receipt.ReceiptNo__c, requestDataModel.ReceiptCode);
				System.assertEquals(null, requestDataModel.InvoiceCode);
				System.assertEquals(0, requestDataModel.Indicator);
				System.assertEquals(receipt.GLKey__c, requestDataModel.GroupKey);
				System.assertEquals(receipt.GLDate__c, requestDataModel.GLDate);
				System.assertEquals(null, requestDataModel.Remark);
				System.assertEquals(null, requestDataModel.CoBuyerCustomerCode);
				List<PojjamanDataModel.FNGLDocLineRequest> docLines = requestDataModel.DocLine;
				List<PaymentReceiptLineItem__c> receiptItems = receipt.Payment_Transactions__r;
				System.assertEquals(2, docLines.size());
				for (Integer receiptLineIdx = 0; receiptLineIdx < docLines.size() ; receiptLineIdx++){
					PojjamanDataModel.FNGLDocLineRequest docLine = docLines[receiptLineIdx];
					PaymentReceiptLineItem__c receiptLineItem = receiptLineItemMapById.get(docLine.SFDocLineId);
					System.assertEquals(receiptLineIdx + 1, docLine.LineNumber);
					System.assertEquals(receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode , docLine.UnitCode);
					System.assertEquals(receiptLineItem.ReceiptLineItemType__c , docLine.Type);
					System.assertEquals(receiptLineItem.ReceivedAmount__c , docLine.Amount);
					System.assertEquals(false , docLine.IsDebit);
					System.assertEquals(receiptLineItem.Id , docLine.SFDocLineId);
					System.assertEquals(receiptLineItem.Status__c , docLine.Status);
					System.assertEquals(null , docLine.DueDate);
					System.assertEquals(null, docLine.RefInvoiceId);
				}
				System.assertEquals(null, requestDataModel.PaymentMethod);
			}
		}
	}
}