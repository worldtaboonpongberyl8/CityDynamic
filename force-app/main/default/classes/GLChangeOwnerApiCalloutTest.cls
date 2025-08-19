@isTest
public with sharing class GLChangeOwnerApiCalloutTest {
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
		testProduct.ReservationPrice__c = 10000;
		testProduct.TransferredDate__c = Date.today();
		Product2 testProduct2 = dataMaker.createUnit(
			'Test Product 2',
			'UN02',
			testProject.Id,
			testFloor.Id,
			'Transferred',
			unitType.Id
		);
		testProduct2.ReservationPrice__c = 10000;
		testProduct2.TransferredDate__c = Date.today();
		List<Product2> products = new List<Product2>{testProduct,testProduct2};
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
		// Create Pricebook Entry
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 15000000, 20000000,10000000);
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
		OpportunityTriggerHandler oppTriggerHandler = OpportunityTriggerHandler.getInstance();
		oppTriggerHandler.setBypass();
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
			targetAccount2.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Foreign',
			paymentTermMaster.Id,
			testProject.Id
		);
		Opportunity opp3 = dataMaker.createOpportunity(
			targetAccount3.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct2.Id,
			'Foreign',
			paymentTermMaster.Id,
			testProject.Id
		);
		Opportunity opp4 = dataMaker.createOpportunity(
			targetAccount3.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct2.Id,
			'Foreign',
			paymentTermMaster.Id,
			testProject.Id
		);
		List<Opportunity> opportunities = new List<Opportunity>{ opp1 , opp2 , opp3 , opp4 };
		insert opportunities;
		oppTriggerHandler.clearBypass();
		// Create Opp Payments
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opp1.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		OpportunityPayment__c reservationOppPayment2 = dataMaker.createOpportunityPayment(
			opp2.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment,reservationOppPayment2
		};
		insert oppPayments;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opp1.Id , Date.newInstance(2024, 10, 10));
		receipt.CustomGLKey__c = 'TestKey1';
		receipt.CustomGLDate__c = Date.today();
		PaymentReceipt__c receipt2 = dataMaker.craeteReceipt(opp2.Id , Date.newInstance(2024, 10, 10));
		receipt2.CustomGLKey__c = 'TestKey2';
		receipt2.CustomGLDate__c = Date.today();
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt,receipt2};
		insert receipts;
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,null,50000,'Fully Paid');
		PaymentReceiptLineItem__c receiptItemReservation2 = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment2.Id,null,50000,'Fully Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{ receiptItemReservation , receiptItemReservation2};
		insert receiptItems;
		// Create Payment Method
		PaymentMethod__c receiptMethod = dataMaker.createPaymentMethod(receipt.Id,'KBANK',Decimal.valueOf(1000000),'Cash','Reservation',Date.today());
		PaymentMethod__c receiptMethod2 = dataMaker.createPaymentMethod(receipt2.Id,'KBANK',Decimal.valueOf(1000000),'Cash','Reservation',Date.today());
		List<PaymentMethod__c> receiptMethods = new List<PaymentMethod__c>{receiptMethod,receiptMethod2};
		insert receiptMethods;
		// Create Opp Acc Change Log
		OpportunityAccountChangeLog__c oppAccChangeLog = dataMaker.createOpportunityAccountChangeLog(opp1.Id,opp2.Id,opp1.AccountId,opp2.AccountId);
		OpportunityAccountChangeLog__c oppAccChangeLog2 = dataMaker.createOpportunityAccountChangeLog(opp3.Id,opp4.Id,opp3.AccountId,opp4.AccountId);
		List<OpportunityAccountChangeLog__c> oppAccChangeLogs = new List<OpportunityAccountChangeLog__c>{oppAccChangeLog,oppAccChangeLog2};
		insert oppAccChangeLogs;
		// Update Receipt
		PaymentReceipt__c updatedReceipt = new PaymentReceipt__c();
		updatedReceipt.Id = receipt.Id;
		updatedReceipt.OpportunityAccountChangeLog__c = oppAccChangeLog.Id;
		PaymentReceipt__c updatedReceipt2 = new PaymentReceipt__c();
		updatedReceipt2.Id = receipt2.Id;
		updatedReceipt2.OpportunityAccountChangeLog__c = oppAccChangeLog2.Id;
		List<PaymentReceipt__c> updatedPaymentReceipts = new List<PaymentReceipt__c>{updatedReceipt,updatedReceipt2};
		update updatedPaymentReceipts;
	}

    @isTest
	static void testRequestModelGLChangeOwnerApiCallout(){
		List<OpportunityAccountChangeLog__c> oppAccountChangeLogs = [
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
		System.assertEquals(2, oppAccountChangeLogs.size());
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		Set<Id> receiptIds = new Set<Id>();
		Map<Id,OpportunityAccountChangeLog__c> oppAccChangeLogMapByReceiptId = new Map<Id,OpportunityAccountChangeLog__c>();
		for (OpportunityAccountChangeLog__c oppAccountChangeLog : oppAccountChangeLogs) {
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
		GLChangeOwnerApiCallout callout = new GLChangeOwnerApiCallout(oppAccountChangeLogs);
		Object request = callout.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(null, request);
		System.assertEquals(requestModels.size(), receipts.size());
		for (Integer i = 0 ; i < requestModels.size(); i ++){
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