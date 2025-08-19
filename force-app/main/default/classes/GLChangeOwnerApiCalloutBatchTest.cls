@isTest
public with sharing class GLChangeOwnerApiCalloutBatchTest {

	public static String targetReceiptId;
    public static String targetReceiptLienItemId;

    public class SuccessGLMockResp1 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<PojjamanDataModel.FNGLDocRequest>.class);
            List<PojjamanDataModel.FNGLDocRequest> requestData = ( List<PojjamanDataModel.FNGLDocRequest>)requestDataObj;

            List<PojjamanDataModel.FNGLDocLineItemResponse> responseReceiptLineItemData = new List<PojjamanDataModel.FNGLDocLineItemResponse>();
			PojjamanDataModel.FNGLDocLineItemResponse responseReceiptLineItem = new PojjamanDataModel.FNGLDocLineItemResponse();
            responseReceiptLineItem.ResponseId = 123456;
            responseReceiptLineItem.Message = 'Success';
            responseReceiptLineItem.ResponseCode = 'SC';
            responseReceiptLineItem.SFDocLineId = targetReceiptLienItemId;
            responseReceiptLineItem.Timestamp = System.now();
            responseReceiptLineItemData.add(responseReceiptLineItem);

            // START MOCK RECEIPT RESPONSE
            List<PojjamanDataModel.FNGLDocResponse> responseReceiptData = new List<PojjamanDataModel.FNGLDocResponse>();
			PojjamanDataModel.FNGLDocResponse receiptResponse = new PojjamanDataModel.FNGLDocResponse();
            receiptResponse.SFDocId = targetReceiptId;
            receiptResponse.ResponseId = 123456;
            receiptResponse.ResponseCode = 'SC';
            receiptResponse.Message = 'Success';
            receiptResponse.Timestamp = System.now();
			receiptResponse.DocLine = responseReceiptLineItemData;
            responseReceiptData.add(receiptResponse);
			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseReceiptData));
            res.setStatusCode(200);
            return res;
        }
    }

	/**
	 * Scenario 1: send 1 Set of Receipt related with 1 OpportunityAccountChangeLog
	 */
	@isTest
    static void processApiSuccess1(){
        Test.setMock(HttpCalloutMock.class, new GLChangeOwnerApiCalloutBatchTest.SuccessGLMockResp1());
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
		insert testProduct;
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
		Account targetAccount2 = dataMaker.createAccount(recordTypeId, 'Test Account 2');
		List<Account> accounts = new List<Account>{targetAccount,targetAccount2};
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
		opp1.ReservationDueDate__c = Date.newInstance(2024, 10, 12);

		// opp1.StageName = 'Reservation';
		// update opp1;
		// Contract contract = dataMaker.createContract(opp1.Id,targetAccount.Id);
		// insert contract;
		// contract.Status = 'Signed Contract';
		// contract.ContractSignedDate__c = Date.today();
		// update contract;
		// opp1.StageName = 'Contract';
		// update opp1;
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
		// insert opp2;
		List<Opportunity> opportunities = new List<Opportunity>{ opp1 , opp2};
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

		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment
		};
		insert oppPayments;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opp1.Id , Date.newInstance(2024, 10, 10));
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt};
		receipt.CancelReason__c = GlobalConstants.RECEIPT_LOST_REASON_NOVATION;
		insert receipts;
		targetReceiptId = receipt.Id;
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,null,50000,'Fully Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{ receiptItemReservation };
		insert receiptItems;
		targetReceiptLienItemId = receiptItemReservation.Id;
		// Create Payment Method
		PaymentMethod__c receiptMethod = dataMaker.createPaymentMethod(receipt.Id,'KBANK',Decimal.valueOf(1000000),'Cash','Reservation',Date.today());
		List<PaymentMethod__c> receiptMethods = new List<PaymentMethod__c>{receiptMethod};
		insert receiptMethods;
		// Create Opp Acc Change Log
		OpportunityAccountChangeLog__c oppAccChangeLog = dataMaker.createOpportunityAccountChangeLog(opp1.Id,opp2.Id,opp1.AccountId,opp2.AccountId);
		List<OpportunityAccountChangeLog__c> oppAccChangeLogs = new List<OpportunityAccountChangeLog__c>{oppAccChangeLog};
		insert oppAccChangeLogs;
		// Update Receipt
		PaymentReceipt__c updatedReceipt = new PaymentReceipt__c();
		updatedReceipt.Id = receipt.Id;
		updatedReceipt.OpportunityAccountChangeLog__c = oppAccChangeLog.Id;
		update updatedReceipt;

        Test.startTest();
        GLChangeOwnerApiCalloutBatch batch = new GLChangeOwnerApiCalloutBatch();
        Database.executeBatch(batch, 200);
		Test.stopTest();
		OpportunityAccountChangeLog__c targetOpportunityAccountChangeLog = [SELECT Id,LastGLStatusInPojjaman__c,LastIntegrationDateTime__c,ResponseMessage__c FROM OpportunityAccountChangeLog__c WHERE Id =: oppAccChangeLog.Id LIMIT 1];
		System.assertEquals('Success', targetOpportunityAccountChangeLog.LastGLStatusInPojjaman__c);
    }

	public class SuccessGLMockResp2 implements HttpCalloutMock {

		public List<Id> receiptIds = new List<Id>();
		public List<Id> receiptLineIds = new List<Id>();

		public void addReceiptId(PaymentReceipt__c receipt){
			this.receiptIds.add(receipt.Id);
		}

		public void addReceiptLineId(PaymentReceiptLineItem__c receiptLineItem){
			this.receiptLineIds.add(receiptLineItem.Id);
		}

        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<PojjamanDataModel.FNGLDocRequest>.class);
            List<PojjamanDataModel.FNGLDocRequest> requestData = ( List<PojjamanDataModel.FNGLDocRequest>)requestDataObj;
			List<PojjamanDataModel.FNGLDocResponse> responseReceiptData = new List<PojjamanDataModel.FNGLDocResponse>();
			for (Integer i = 0; i < receiptIds.size() ; i ++){
				List<PojjamanDataModel.FNGLDocLineItemResponse> responseReceiptLineItemData = new List<PojjamanDataModel.FNGLDocLineItemResponse>();
				PojjamanDataModel.FNGLDocLineItemResponse responseReceiptLineItem = new PojjamanDataModel.FNGLDocLineItemResponse();
				responseReceiptLineItem.ResponseId = 123456;
				responseReceiptLineItem.Message = 'Success';
				responseReceiptLineItem.ResponseCode = 'SC';
				responseReceiptLineItem.SFDocLineId = receiptLineIds[i];
				responseReceiptLineItem.Timestamp = System.now();
				responseReceiptLineItemData.add(responseReceiptLineItem);
				PojjamanDataModel.FNGLDocResponse receiptResponse = new PojjamanDataModel.FNGLDocResponse();
				receiptResponse.SFDocId = receiptIds[i];
				receiptResponse.ResponseId = 123456;
				receiptResponse.ResponseCode = 'SC';
				receiptResponse.Message = 'Success';
				receiptResponse.Timestamp = System.now();
				receiptResponse.DocLine = responseReceiptLineItemData;
				responseReceiptData.add(receiptResponse);
			}
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseReceiptData));
            res.setStatusCode(200);
            return res;
        }
    }

	/**
	 * Scenario 2: send multiple Sets of Receipt related with multiple OpportunityAccountChangeLogs
	 */
	@isTest
    static void processApiSuccess2(){
		SuccessGLMockResp2 mock = new SuccessGLMockResp2();
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
		Account targetAccount2 = dataMaker.createAccount(recordTypeId, 'Test Account 2');
		Account targetAccount3 = dataMaker.createAccount(recordTypeId, 'Test Account 3');
		Account targetAccount4 = dataMaker.createAccount(recordTypeId, 'Test Account 4');
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
		PaymentReceipt__c receipt2 = dataMaker.craeteReceipt(opp2.Id , Date.newInstance(2024, 10, 10));
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt,receipt2};
		insert receipts;
		mock.addReceiptId(receipt);
		mock.addReceiptId(receipt2);
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,null,50000,'Fully Paid');
		PaymentReceiptLineItem__c receiptItemReservation2 = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment2.Id,null,50000,'Fully Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{ receiptItemReservation , receiptItemReservation2};
		insert receiptItems;
		mock.addReceiptLineId(receiptItemReservation);
		mock.addReceiptLineId(receiptItemReservation2);
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
		Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        GLChangeOwnerApiCalloutBatch batch = new GLChangeOwnerApiCalloutBatch();
        Database.executeBatch(batch, 200);
		Test.stopTest();
		OpportunityAccountChangeLog__c targetOpportunityAccountChangeLog = [SELECT Id,LastGLStatusInPojjaman__c,LastIntegrationDateTime__c,ResponseMessage__c FROM OpportunityAccountChangeLog__c WHERE Id =: oppAccChangeLog.Id LIMIT 1];
		OpportunityAccountChangeLog__c targetOpportunityAccountChangeLog2 = [SELECT Id,LastGLStatusInPojjaman__c,LastIntegrationDateTime__c,ResponseMessage__c FROM OpportunityAccountChangeLog__c WHERE Id =: oppAccChangeLog2.Id LIMIT 1];
		System.assertEquals('Success', targetOpportunityAccountChangeLog.LastGLStatusInPojjaman__c);
		System.assertEquals('Success', targetOpportunityAccountChangeLog2.LastGLStatusInPojjaman__c);
    }

	public class FailGLMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<PojjamanDataModel.FNGLDocRequest>.class);
            List<PojjamanDataModel.FNGLDocRequest> requestData = ( List<PojjamanDataModel.FNGLDocRequest>)requestDataObj;

            // START MOCK RECEIPT RESPONSE
            List<PojjamanDataModel.FNGLDocResponse> responseData = new List<PojjamanDataModel.FNGLDocResponse>();

			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseData));
            res.setStatusCode(500);
            return res;
        }
    }

	@isTest
    static void processApiFail(){
        Test.setMock(HttpCalloutMock.class, new GLChangeOwnerApiCalloutBatchTest.FailGLMockResp());
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
		insert testProduct;
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
		insert targetAccount;
		Account targetAccount2 = dataMaker.createAccount(recordTypeId, 'Test Account 2');
		insert targetAccount2;
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
		opp1.ReservationDueDate__c = Date.newInstance(2024, 10, 12);
		List<Opportunity> opportunities = new List<Opportunity>{ opp1 };
		insert opportunities;
		Quote__c quote = dataMaker.createQuote(opp1.Id);
		quote.IsSyncing__c = true;
		insert quote;
		opp1.SyncedQuoteId__c = quote.Id;
		User targetUser = [SELECT Id FROM User WHERE Profile.Name LIKE '%CRM%' LIMIT 1];
		opp1.SoldBy__c = 'Agency';
		opp1.CRMinCharge__c = targetUser.Id;
		opp1.StageName = 'Reservation';
		update opp1;
		Contract contract = dataMaker.createContract(opp1.Id,targetAccount.Id);
		insert contract;
		contract.Status = 'Signed Contract';
		contract.ContractSignedDate__c = Date.today();
		update contract;
		opp1.StageName = 'Contract';
		opp1.ActualContractSigningDate__c = Date.today();
		update opp1;
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
		insert opp2;
		oppTriggerHandler.clearBypass();
		// Create Opp Payments
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opp1.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);

		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment
		};
		insert oppPayments;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opp1.Id , Date.newInstance(2024, 10, 10));
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt};
		receipt.CancelReason__c = GlobalConstants.RECEIPT_LOST_REASON_NOVATION;
		insert receipts;
		targetReceiptId = receipt.Id;
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,null,50000,'Fully Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{ receiptItemReservation };
		insert receiptItems;
		targetReceiptLienItemId = receiptItemReservation.Id;
		// Create Payment Method
		PaymentMethod__c receiptMethod = dataMaker.createPaymentMethod(receipt.Id,'KBANK',Decimal.valueOf(1000000),'Cash','Reservation',Date.today());
		List<PaymentMethod__c> receiptMethods = new List<PaymentMethod__c>{receiptMethod};
		insert receiptMethods;
		// Create Opp Acc Change Log
		OpportunityAccountChangeLog__c oppAccChangeLog = dataMaker.createOpportunityAccountChangeLog(opp1.Id,opp2.Id,opp1.AccountId,opp2.AccountId);
		List<OpportunityAccountChangeLog__c> oppAccChangeLogs = new List<OpportunityAccountChangeLog__c>{oppAccChangeLog};
		insert oppAccChangeLogs;
		// Update Receipt
		PaymentReceipt__c updatedReceipt = new PaymentReceipt__c();
		updatedReceipt.Id = receipt.Id;
		updatedReceipt.OpportunityAccountChangeLog__c = oppAccChangeLog.Id;
		update updatedReceipt;

        Test.startTest();
        GLChangeOwnerApiCalloutBatch batch = new GLChangeOwnerApiCalloutBatch();
        Database.executeBatch(batch, 200);
		Test.stopTest();
		OpportunityAccountChangeLog__c targetOpportunityAccountChangeLog = [SELECT Id,LastGLStatusInPojjaman__c,LastIntegrationDateTime__c,ResponseMessage__c FROM OpportunityAccountChangeLog__c WHERE Id =: oppAccChangeLog.Id LIMIT 1];
		System.assertEquals('Fail', targetOpportunityAccountChangeLog.LastGLStatusInPojjaman__c);
    }
}