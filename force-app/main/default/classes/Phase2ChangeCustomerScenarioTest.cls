@isTest
public class Phase2ChangeCustomerScenarioTest {
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
			'Transferred',
			unitType.Id
		);
		testProduct.ReservationPrice__c = 100000;
		testProduct.TransferredDate__c = Date.today();
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

	}

	@isTest
	static void novationPositiveCase(){
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		Quote__c quote = dataMaker.createQuote(opportunity.Id);
		quote.IsSyncing__c = true;
		insert quote;
		List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test Account 2'];
		Account account2 = accounts[0];
		opportunity.NewCoOwner__c = account2.Id;
		opportunity.SyncedQuoteId__c = quote.Id;
		update opportunity;

		Decimal amount = 100000;
		String receiptType = GlobalConstants.RECEIPT_TYPE_DEFAULT;
		String paymentMethodType = 'Credit Card';
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		service.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(opportunity.Id, 2000, GlobalConstants.RECEIPT_TYPE_NOVATION, paymentMethodType);
		Map<String,List<SObject>> result = CompleteNovationController.completeNovation(opportunity.Id);
		List<OpportunityAccountChangeLog__c> oppAccChangeLogs =
			[
				SELECT
					Id,
					CurrentAccount__r.AccountCode__c,
					PreviousAccount__r.AccountCode__c,
					LastGLStatusInPojjaman__c,
					LastIntegrationDateTime__c,
					ResponseMessage__c,
					(
						SELECT
							Id,
							IsCancel__c,
							CancelReason__c,
							LastGLStatusInPojjaman__c
						FROM PaymentReceipts__r
						ORDER BY CreatedDate ASC
					)
				FROM OpportunityAccountChangeLog__c
				WHERE (LastGLStatusInPojjaman__c = null OR LastGLStatusInPojjaman__c = 'Fail')
				ORDER BY LastModifiedDate ASC
			];
		Set<Id> receiptIds = new Set<Id>();
		Map<Id,OpportunityAccountChangeLog__c> oppAccChangeLogMapByReceiptId = new Map<Id,OpportunityAccountChangeLog__c>();
		for (OpportunityAccountChangeLog__c oppAccountChangeLog : oppAccChangeLogs) {
			List<PaymentReceipt__c> paymentReceipts = oppAccountChangeLog.PaymentReceipts__r;
			for (PaymentReceipt__c paymentReceipt : paymentReceipts) {
				if (
					paymentReceipt.IsCancel__c &&
					paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_CRM
				) {
					continue;
				}
				oppAccChangeLogMapByReceiptId.put(paymentReceipt.Id, oppAccountChangeLog);
				receiptIds.add(paymentReceipt.Id);
			}
		}
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			receiptIds
		);
		List<PaymentReceipt__c> receipts = receiptWithReceiptLineItemsMapById.values() == null ? new List<PaymentReceipt__c>() : receiptWithReceiptLineItemsMapById.values();
		GLChangeOwnerApiCallout callout = new GLChangeOwnerApiCallout(oppAccChangeLogs);
		Test.startTest();
			Object request = callout.buildRequestDataModel();
		Test.stopTest();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(0, requestModels.size());
		System.assertNotEquals(null, request);
		System.assertEquals( 1 , oppAccChangeLogs.size());
		System.assertEquals( receipts.size() , requestModels.size());
		for (Integer i = 0; i < receipts.size(); i++){
			PojjamanDataModel.FNGLDocRequest requestModel = requestModels[i];
			PaymentReceipt__c receipt = receipts[i];
			OpportunityAccountChangeLog__c oppAccChangeLog = oppAccChangeLogMapByReceiptId.get(receipt.Id);
			System.assertNotEquals(null, requestModel.CustomerCode);
			System.assertEquals(oppAccChangeLog.CurrentAccount__r.AccountCode__c, requestModel.CustomerCode);
			System.assertNotEquals(null, requestModel.PreviousCustomerCode);
			System.assertEquals(oppAccChangeLog.PreviousAccount__r.AccountCode__c, requestModel.PreviousCustomerCode);
			System.assertNotEquals(null, requestModel.ProjectCode);
			System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestModel.ProjectCode);
			System.assertNotEquals(null, requestModel.SFDocId);
			System.assertEquals(receipt.Id, requestModel.SFDocId);
			System.assertNotEquals(null, requestModel.DocDate);
			System.assertEquals(receipt.CreatedDate.date(), requestModel.DocDate);
			System.assertEquals('GL', requestModel.DocType);
			System.assertEquals(null, requestModel.InvoiceCode);
			System.assertEquals(receipt.ReceiptNo__c, requestModel.ReceiptCode);
			System.assertEquals(0, requestModel.Indicator);
			System.assertNotEquals(null, requestModel.GroupKey);
			System.assertEquals(receipt.CustomGLKey__c, requestModel.GroupKey);
			System.assertNotEquals(null, requestModel.GLDate);
			System.assertEquals(receipt.CustomGLDate__c, requestModel.GLDate);
			List<PaymentReceiptLineItem__c> receiptLineItems = receipt.Payment_Transactions__r;
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = requestModel.DocLine == null ? new List<PojjamanDataModel.FNGLDocLineRequest>() : requestModel.DocLine;
			System.assertEquals(docLines.size(), receiptLineItems.size());
			for (Integer j = 0; j < receiptLineItems.size(); j ++){
				PaymentReceiptLineItem__c receiptLineItem = receiptLineItems[j];
				PojjamanDataModel.FNGLDocLineRequest docLine = docLines[j];
				System.assertEquals(j+1, docLine.LineNumber);
				System.assertNotEquals(null, requestModel.GroupKey);
				System.assertEquals(receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode, docLine.UnitCode);
				System.assertEquals(receiptLineItem.OpportunityPayment__r.Term__c, docLine.Type);
				System.assertEquals(receiptLineItem.ReceivedAmount__c, docLine.Amount);
				System.assertEquals(null, docLine.IsDebit);
				System.assertNotEquals(null, docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Id, docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Status__c, docLine.Status);
				System.assertEquals(receiptLineItem.InvoiceLineItem__r.Invoice__c, docLine.RefInvoiceId);
			}
			System.assertEquals(null, requestModel.PaymentMethod);
		}

	}

	@isTest
	static void novation2StepPositiveCase(){
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		Quote__c quote = dataMaker.createQuote(opportunity.Id);
		quote.IsSyncing__c = true;
		insert quote;
		List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test Account 2'];
		Account account2 = accounts[0];
		opportunity.NewCoOwner__c = account2.Id;
		opportunity.SyncedQuoteId__c = quote.Id;
		update opportunity;

		Decimal amount = 100000;
		String receiptType = GlobalConstants.RECEIPT_TYPE_DEFAULT;
		String paymentMethodType = 'Credit Card';
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		Test.startTest();
		service.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		Map<String,List<SObject>> result = CompleteNovationController.completeNovation(opportunity.Id);
		Opportunity novatedOpportunity = (Opportunity)result.get('novatedOpportunity')[0];
		service.createPaymentReceiptWithLineItem(novatedOpportunity.Id, amount, receiptType, paymentMethodType);
		List<Account> newAccounts = [SELECT Id FROM Account WHERE Name = 'Test Account 3'];
		Account account3 = newAccounts[0];
		novatedOpportunity.NewCoOwner__c = account3.Id;
		update novatedOpportunity;
		Test.stopTest();
		Map<String,List<SObject>> result2 = CompleteNovationController.completeNovation(novatedOpportunity.Id);

		List<OpportunityAccountChangeLog__c> oppAccChangeLogs =
			[
				SELECT
					Id,
					CurrentAccount__r.AccountCode__c,
					PreviousAccount__r.AccountCode__c,
					LastGLStatusInPojjaman__c,
					LastIntegrationDateTime__c,
					ResponseMessage__c,
					(
						SELECT
							Id,
							IsCancel__c,
							CancelReason__c,
							LastGLStatusInPojjaman__c
						FROM PaymentReceipts__r
						ORDER BY CreatedDate ASC
					)
				FROM OpportunityAccountChangeLog__c
				WHERE (LastGLStatusInPojjaman__c = null OR LastGLStatusInPojjaman__c = 'Fail')
				ORDER BY LastModifiedDate ASC
			];
		System.debug('test oppAccChangeLogs size: ' + oppAccChangeLogs.size());
		Set<Id> receiptIds = new Set<Id>();
		Map<Id,OpportunityAccountChangeLog__c> oppAccChangeLogMapByReceiptId = new Map<Id,OpportunityAccountChangeLog__c>();
		for (OpportunityAccountChangeLog__c oppAccountChangeLog : oppAccChangeLogs) {
			List<PaymentReceipt__c> paymentReceipts = oppAccountChangeLog.PaymentReceipts__r;
			for (PaymentReceipt__c paymentReceipt : paymentReceipts) {
				System.debug('test paymentReceipt: ' + paymentReceipt);
				if (
					paymentReceipt.IsCancel__c &&
					paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_CRM
				) {
					continue;
				}
				oppAccChangeLogMapByReceiptId.put(paymentReceipt.Id, oppAccountChangeLog);
				receiptIds.add(paymentReceipt.Id);
			}
		}
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			receiptIds
		);
		List<PaymentReceipt__c> receipts = receiptWithReceiptLineItemsMapById.values() == null ? new List<PaymentReceipt__c>() : receiptWithReceiptLineItemsMapById.values();
		GLChangeOwnerApiCallout callout = new GLChangeOwnerApiCallout(oppAccChangeLogs);
		Object request = callout.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(0, requestModels.size());
		System.assertNotEquals(null, request);
		System.assertEquals( 2 , oppAccChangeLogs.size());
		System.assertEquals( receipts.size() , requestModels.size());
		System.assertEquals( 4 , requestModels.size());
		for (Integer i = 0; i < receipts.size(); i++){
			PojjamanDataModel.FNGLDocRequest requestModel = requestModels[i];
			PaymentReceipt__c receipt = receipts[i];
			OpportunityAccountChangeLog__c oppAccChangeLog = oppAccChangeLogMapByReceiptId.get(receipt.Id);
			System.assertNotEquals(null, requestModel.CustomerCode);
			System.assertEquals(oppAccChangeLog.CurrentAccount__r.AccountCode__c, requestModel.CustomerCode);
			System.assertNotEquals(null, requestModel.PreviousCustomerCode);
			System.assertEquals(oppAccChangeLog.PreviousAccount__r.AccountCode__c, requestModel.PreviousCustomerCode);
			System.assertNotEquals(null, requestModel.ProjectCode);
			System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestModel.ProjectCode);
			System.assertNotEquals(null, requestModel.SFDocId);
			System.assertEquals(receipt.Id, requestModel.SFDocId);
			System.assertNotEquals(null, requestModel.DocDate);
			System.assertEquals(receipt.CreatedDate.date(), requestModel.DocDate);
			System.assertEquals('GL', requestModel.DocType);
			System.assertEquals(null, requestModel.InvoiceCode);
			System.assertEquals(receipt.ReceiptNo__c, requestModel.ReceiptCode);
			System.assertEquals(0, requestModel.Indicator);
			System.assertNotEquals(null, requestModel.GroupKey);
			System.assertEquals(receipt.CustomGLKey__c, requestModel.GroupKey);
			System.assertNotEquals(null, requestModel.GLDate);
			System.assertEquals(receipt.CustomGLDate__c, requestModel.GLDate);
			List<PaymentReceiptLineItem__c> receiptLineItems = receipt.Payment_Transactions__r;
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = requestModel.DocLine == null ? new List<PojjamanDataModel.FNGLDocLineRequest>() : requestModel.DocLine;
			System.assertEquals(docLines.size(), receiptLineItems.size());
			for (Integer j = 0; j < receiptLineItems.size(); j ++){
				PaymentReceiptLineItem__c receiptLineItem = receiptLineItems[j];
				PojjamanDataModel.FNGLDocLineRequest docLine = docLines[j];
				System.assertEquals(j+1, docLine.LineNumber);
				System.assertNotEquals(null, requestModel.GroupKey);
				System.assertEquals(receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode, docLine.UnitCode);
				System.assertEquals(receiptLineItem.OpportunityPayment__r.Term__c, docLine.Type);
				System.assertEquals(receiptLineItem.ReceivedAmount__c, docLine.Amount);
				System.assertEquals(null, docLine.IsDebit);
				System.assertNotEquals(null, docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Id, docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Status__c, docLine.Status);
				System.assertEquals(receiptLineItem.InvoiceLineItem__r.Invoice__c, docLine.RefInvoiceId);
			}
			System.assertEquals(null, requestModel.PaymentMethod);
		}
	}

	@isTest
	static void changePrimaryOwnerPositiveCase(){
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		Account account = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
		Decimal amount = 100000;
		String receiptType = GlobalConstants.RECEIPT_TYPE_DEFAULT;
		String paymentMethodType = 'Credit Card';
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		service.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		Test.startTest();
			opportunity.AccountId = account.Id;
			update opportunity;
		Test.stopTest();
		List<OpportunityAccountChangeLog__c> oppAccChangeLogs =
			[
				SELECT
					Id,
					CurrentAccount__r.AccountCode__c,
					PreviousAccount__r.AccountCode__c,
					LastGLStatusInPojjaman__c,
					LastIntegrationDateTime__c,
					ResponseMessage__c,
					(
						SELECT
							Id,
							IsCancel__c,
							CancelReason__c,
							LastGLStatusInPojjaman__c
						FROM PaymentReceipts__r
						ORDER BY CreatedDate ASC
					)
				FROM OpportunityAccountChangeLog__c
				WHERE (LastGLStatusInPojjaman__c = null OR LastGLStatusInPojjaman__c = 'Fail')
				ORDER BY LastModifiedDate ASC
			];
		Set<Id> receiptIds = new Set<Id>();
		Map<Id,OpportunityAccountChangeLog__c> oppAccChangeLogMapByReceiptId = new Map<Id,OpportunityAccountChangeLog__c>();
		for (OpportunityAccountChangeLog__c oppAccountChangeLog : oppAccChangeLogs) {
			List<PaymentReceipt__c> paymentReceipts = oppAccountChangeLog.PaymentReceipts__r;
			for (PaymentReceipt__c paymentReceipt : paymentReceipts) {
				if (
					paymentReceipt.IsCancel__c &&
					paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_CRM
				) {
					continue;
				}
				oppAccChangeLogMapByReceiptId.put(paymentReceipt.Id, oppAccountChangeLog);
				receiptIds.add(paymentReceipt.Id);
			}
		}
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			receiptIds
		);
		List<PaymentReceipt__c> receipts = receiptWithReceiptLineItemsMapById.values() == null ? new List<PaymentReceipt__c>() : receiptWithReceiptLineItemsMapById.values();

		GLChangeOwnerApiCallout callout = new GLChangeOwnerApiCallout(oppAccChangeLogs);
		Object request = callout.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(0, requestModels.size());
		System.assertNotEquals(null, request);
		System.assertEquals( 1 , oppAccChangeLogs.size());
		System.assertEquals( receipts.size() , requestModels.size());
		System.assertEquals( 3 , requestModels.size());
		for (Integer i = 0; i < receipts.size(); i++){
			PojjamanDataModel.FNGLDocRequest requestModel = requestModels[i];
			PaymentReceipt__c receipt = receipts[i];
			OpportunityAccountChangeLog__c oppAccChangeLog = oppAccChangeLogMapByReceiptId.get(receipt.Id);
			System.assertNotEquals(null, requestModel.CustomerCode);
			System.assertEquals(oppAccChangeLog.CurrentAccount__r.AccountCode__c, requestModel.CustomerCode);
			System.assertNotEquals(null, requestModel.PreviousCustomerCode);
			System.assertEquals(oppAccChangeLog.PreviousAccount__r.AccountCode__c, requestModel.PreviousCustomerCode);
			System.assertNotEquals(null, requestModel.ProjectCode);
			System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestModel.ProjectCode);
			System.assertNotEquals(null, requestModel.SFDocId);
			System.assertEquals(receipt.Id, requestModel.SFDocId);
			System.assertNotEquals(null, requestModel.DocDate);
			System.assertEquals(receipt.CreatedDate.date(), requestModel.DocDate);
			System.assertEquals('GL', requestModel.DocType);
			System.assertEquals(null, requestModel.InvoiceCode);
			System.assertEquals(receipt.ReceiptNo__c, requestModel.ReceiptCode);
			System.assertEquals(0, requestModel.Indicator);
			System.assertNotEquals(null, requestModel.GroupKey);
			System.assertEquals(receipt.CustomGLKey__c, requestModel.GroupKey);
			System.assertNotEquals(null, requestModel.GLDate);
			System.assertEquals(receipt.CustomGLDate__c, requestModel.GLDate);
			List<PaymentReceiptLineItem__c> receiptLineItems = receipt.Payment_Transactions__r;
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = requestModel.DocLine == null ? new List<PojjamanDataModel.FNGLDocLineRequest>() : requestModel.DocLine;
			System.assertEquals(docLines.size(), receiptLineItems.size());
			for (Integer j = 0; j < receiptLineItems.size(); j ++){
				PaymentReceiptLineItem__c receiptLineItem = receiptLineItems[j];
				PojjamanDataModel.FNGLDocLineRequest docLine = docLines[j];
				System.assertEquals(j+1, docLine.LineNumber);
				System.assertNotEquals(null, requestModel.GroupKey);
				System.assertEquals(receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode, docLine.UnitCode);
				System.assertEquals(receiptLineItem.OpportunityPayment__r.Term__c, docLine.Type);
				System.assertEquals(receiptLineItem.ReceivedAmount__c, docLine.Amount);
				System.assertEquals(null, docLine.IsDebit);
				System.assertNotEquals(null, docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Id, docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Status__c, docLine.Status);
				System.assertEquals(receiptLineItem.InvoiceLineItem__r.Invoice__c, docLine.RefInvoiceId);
			}
			System.assertEquals(null, requestModel.PaymentMethod);
		}
	}

	@isTest
	static void changePrimaryOwner2StepPositiveCase(){
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		Account account = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
		Account account2 = [SELECT Id FROM Account WHERE Name = 'Test Account 3' LIMIT 1];
		Decimal amount = 100000;
		String receiptType = GlobalConstants.RECEIPT_TYPE_DEFAULT;
		String paymentMethodType = 'Credit Card';
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		service.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		service.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		opportunity.AccountId = account.Id;
		update opportunity;
		service.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		Test.startTest();
			opportunity.AccountId = account2.Id;
			update opportunity;
		Test.stopTest();
		List<OpportunityAccountChangeLog__c> oppAccChangeLogs =
			[
				SELECT
					Id,
					CurrentAccount__r.AccountCode__c,
					PreviousAccount__r.AccountCode__c,
					LastGLStatusInPojjaman__c,
					LastIntegrationDateTime__c,
					ResponseMessage__c,
					(
						SELECT
							Id,
							IsCancel__c,
							CancelReason__c,
							LastGLStatusInPojjaman__c
						FROM PaymentReceipts__r
						ORDER BY CreatedDate ASC
					)
				FROM OpportunityAccountChangeLog__c
				WHERE (LastGLStatusInPojjaman__c = null OR LastGLStatusInPojjaman__c = 'Fail')
				ORDER BY LastModifiedDate ASC
			];
		Set<Id> receiptIds = new Set<Id>();
		Map<Id,OpportunityAccountChangeLog__c> oppAccChangeLogMapByReceiptId = new Map<Id,OpportunityAccountChangeLog__c>();
		for (OpportunityAccountChangeLog__c oppAccountChangeLog : oppAccChangeLogs) {
			List<PaymentReceipt__c> paymentReceipts = oppAccountChangeLog.PaymentReceipts__r;
			for (PaymentReceipt__c paymentReceipt : paymentReceipts) {
				if (
					paymentReceipt.IsCancel__c &&
					paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_CRM
				) {
					continue;
				}
				oppAccChangeLogMapByReceiptId.put(paymentReceipt.Id, oppAccountChangeLog);
				receiptIds.add(paymentReceipt.Id);
			}
		}
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			receiptIds
		);
		List<PaymentReceipt__c> receipts = receiptWithReceiptLineItemsMapById.values() == null ? new List<PaymentReceipt__c>() : receiptWithReceiptLineItemsMapById.values();

		GLChangeOwnerApiCallout callout = new GLChangeOwnerApiCallout(oppAccChangeLogs);
		Object request = callout.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(0, requestModels.size());
		System.assertNotEquals(null, request);
		System.assertEquals( 2 , oppAccChangeLogs.size());
		System.assertEquals( receipts.size() , requestModels.size());
		System.assertEquals( 3 , requestModels.size());
		for (Integer i = 0; i < receipts.size(); i++){
			PojjamanDataModel.FNGLDocRequest requestModel = requestModels[i];
			PaymentReceipt__c receipt = receipts[i];
			OpportunityAccountChangeLog__c oppAccChangeLog = oppAccChangeLogMapByReceiptId.get(receipt.Id);
			System.assertNotEquals(null, requestModel.CustomerCode);
			System.assertEquals(oppAccChangeLog.CurrentAccount__r.AccountCode__c, requestModel.CustomerCode);
			System.assertNotEquals(null, requestModel.PreviousCustomerCode);
			System.assertEquals(oppAccChangeLog.PreviousAccount__r.AccountCode__c, requestModel.PreviousCustomerCode);
			System.assertNotEquals(null, requestModel.ProjectCode);
			System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestModel.ProjectCode);
			System.assertNotEquals(null, requestModel.SFDocId);
			System.assertEquals(receipt.Id, requestModel.SFDocId);
			System.assertNotEquals(null, requestModel.DocDate);
			System.assertEquals(receipt.CreatedDate.date(), requestModel.DocDate);
			System.assertEquals('GL', requestModel.DocType);
			System.assertEquals(null, requestModel.InvoiceCode);
			System.assertEquals(receipt.ReceiptNo__c, requestModel.ReceiptCode);
			System.assertEquals(0, requestModel.Indicator);
			System.assertNotEquals(null, requestModel.GroupKey);
			System.assertEquals(receipt.CustomGLKey__c, requestModel.GroupKey);
			System.assertNotEquals(null, requestModel.GLDate);
			System.assertEquals(receipt.CustomGLDate__c, requestModel.GLDate);
			List<PaymentReceiptLineItem__c> receiptLineItems = receipt.Payment_Transactions__r;
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = requestModel.DocLine == null ? new List<PojjamanDataModel.FNGLDocLineRequest>() : requestModel.DocLine;
			System.assertEquals(docLines.size(), receiptLineItems.size());
			for (Integer j = 0; j < receiptLineItems.size(); j ++){
				PaymentReceiptLineItem__c receiptLineItem = receiptLineItems[j];
				PojjamanDataModel.FNGLDocLineRequest docLine = docLines[j];
				System.assertEquals(j+1, docLine.LineNumber);
				System.assertNotEquals(null, requestModel.GroupKey);
				System.assertEquals(receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode, docLine.UnitCode);
				System.assertEquals(receiptLineItem.OpportunityPayment__r.Term__c, docLine.Type);
				System.assertEquals(receiptLineItem.ReceivedAmount__c, docLine.Amount);
				System.assertEquals(null, docLine.IsDebit);
				System.assertNotEquals(null, docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Id, docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Status__c, docLine.Status);
				System.assertEquals(receiptLineItem.InvoiceLineItem__r.Invoice__c, docLine.RefInvoiceId);
			}
			System.assertEquals(null, requestModel.PaymentMethod);
		}

	}
}