@isTest
public class GLChangeUnitApiCalloutBatchTest {

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
			'UN01',
			testProject.Id,
			testFloor.Id,
			'Transferred',
			unitType.Id
		);
		testProduct2.ReservationPrice__c = 10000;
		testProduct2.TransferredDate__c = Date.today();
		Product2 testProduct3 = dataMaker.createUnit(
			'Test Product 3',
			'UN01',
			testProject.Id,
			testFloor.Id,
			'Transferred',
			unitType.Id
		);
		testProduct3.ReservationPrice__c = 10000;
		testProduct3.TransferredDate__c = Date.today();
		List<Product2> products = new List<Product2>{testProduct,testProduct2,testProduct3};
		insert products;
		// Create Pricebook Entry
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 15000000, 20000000,10000000);
		testPricebookEntry1.Pricebook2Id = pricebookId;
		testPricebookEntry1.UseStandardPrice = false;
		PricebookEntry testPricebookEntry2 = dataMaker.createPricebookEntries(testProduct2.Id, 15000000, 20000000,10000000);
		testPricebookEntry2.Pricebook2Id = pricebookId;
		testPricebookEntry2.UseStandardPrice = false;
		PricebookEntry testPricebookEntry3 = dataMaker.createPricebookEntries(testProduct3.Id, 15000000, 20000000,10000000);
		testPricebookEntry3.Pricebook2Id = pricebookId;
		testPricebookEntry3.UseStandardPrice = false;
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{testPricebookEntry1,testPricebookEntry2,testPricebookEntry3};
		insert pricebookEntries;
		// Creat Account
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account targetAccount = dataMaker.createAccount(recordTypeId, 'Test Account');
		insert targetAccount;
		// Create Payment Term Master
		PaymentTermMaster__c paymentTermMaster = dataMaker.craetePaymentTermMaster(
			testProject.Id,
			'FQ Series 5-10-85',
			'Series',
			'Foreign',
			25
		);
		insert paymentTermMaster;
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
		opp1.Quota__c = 'Foreign';
		insert opp1;
		// opp1.ReservationDueDate__c = Date.newInstance(2024, 10, 12);
		// opp1.StageName = 'Reservation';
		// update opp1;

		// Create Opp Payments
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opp1.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		reservationOppPayment.ReceivedAmount__c = 50000;
		OpportunityPayment__c contractOppPayment = dataMaker.createOpportunityPayment(
			opp1.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 15),
			2
		);
		contractOppPayment.ReceivedAmount__c = 100000;
		OpportunityPayment__c installment1OppPayment = dataMaker.createOpportunityPayment(
			opp1.Id,
			'Installment 1',
			8000,
			Date.newInstance(2024, 10, 15),
			3
		);
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment,contractOppPayment,installment1OppPayment
		};
		insert oppPayments;
		// Create Invoice
		Invoice__c invoice = dataMaker.createInvoice(opp1.Id, Date.newInstance(2024, 10, 6), Date.newInstance(2024, 10, 1), true, 'Address');
		Invoice__c invoice2 = dataMaker.createInvoice(opp1.Id, Date.newInstance(2024, 11, 6), Date.newInstance(2024, 11, 1), true, 'Address');
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice , invoice2};
		insert invoices;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(invoice.Id,contractOppPayment.Id,100000,Date.newInstance(2024, 12, 1),'');
		InvoiceLineItem__c invoiceLineItem2 = dataMaker.createInvoiceLineItem(invoice2.Id,installment1OppPayment.Id,8000,Date.newInstance(2025, 1 , 1),'');
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1,invoiceLineItem2 };
		insert invoiceLineItems;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opp1.Id , Date.newInstance(2024, 10, 10));
		receipt.CancelReason__c = GlobalConstants.RECEIPT_LOST_REASON_UPGRADE;
		PaymentReceipt__c receipt2 = dataMaker.craeteReceipt(opp1.Id , Date.newInstance(2024, 10, 10));
		receipt2.CancelReason__c = GlobalConstants.RECEIPT_LOST_REASON_UPGRADE;
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt,receipt2};
		insert receipts;
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,null,50000,'Fully Paid');
		PaymentReceiptLineItem__c receiptItemContract = dataMaker.createReceiptLineItem(receipt2.Id,contractOppPayment.Id,invoiceLineItem1.Id,100000,'Fully Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{ receiptItemReservation,receiptItemContract };
		insert receiptItems;
		// Create Payment method
		PaymentMethod__c receiptMethod = dataMaker.createPaymentMethod(receipt.Id,'KBANK',Decimal.valueOf(50000),'Cash','Reservation',Date.today());
		PaymentMethod__c receiptMethod2 = dataMaker.createPaymentMethod(receipt2.Id,'KBANK',Decimal.valueOf(100000),'Cash','Reservation',Date.today());
		List<PaymentMethod__c> receiptMethods = new List<PaymentMethod__c>{receiptMethod,receiptMethod2};
		insert receiptMethods;
		// update opp stage to Closed Lost
		opp1.StageName = GlobalConstants.OPP_STAGENAME_CLOSED_LOST;
		opp1.LossReason__c = GlobalConstants.OPP_LOST_REASON_DOWNGRADE;
		update opp1;
		oppTriggerHandler.clearBypass();
	}

	public class SuccessGLMockResp1 implements HttpCalloutMock {

		public Id receiptId {get; set;}
		public Id receiptLineId {get; set;}
		public Id invoiceId {get; set;}
		public Id invoiceLineId {get; set;}

        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<PojjamanDataModel.FNGLDocRequest>.class);
            List<PojjamanDataModel.FNGLDocRequest> requestData = ( List<PojjamanDataModel.FNGLDocRequest>)requestDataObj;
            List<PojjamanDataModel.FNGLDocLineItemResponse> responseReceiptLineItemData = new List<PojjamanDataModel.FNGLDocLineItemResponse>();
			PojjamanDataModel.FNGLDocLineItemResponse responseReceiptLineItem = new PojjamanDataModel.FNGLDocLineItemResponse();
            responseReceiptLineItem.ResponseId = 123456;
            responseReceiptLineItem.Message = 'Success';
            responseReceiptLineItem.ResponseCode = 'SC';
            responseReceiptLineItem.SFDocLineId = receiptLineId;
            responseReceiptLineItem.Timestamp = System.now();
            responseReceiptLineItemData.add(responseReceiptLineItem);
			PojjamanDataModel.FNGLDocLineItemResponse responseInvoiceLineItem = new PojjamanDataModel.FNGLDocLineItemResponse();
            responseInvoiceLineItem.ResponseId = 123456;
            responseInvoiceLineItem.Message = 'Success';
            responseInvoiceLineItem.ResponseCode = 'SC';
            responseInvoiceLineItem.SFDocLineId = invoiceLineId;
            responseInvoiceLineItem.Timestamp = System.now();
            responseReceiptLineItemData.add(responseInvoiceLineItem);
            List<PojjamanDataModel.FNGLDocResponse> responseReceiptData = new List<PojjamanDataModel.FNGLDocResponse>();
			PojjamanDataModel.FNGLDocResponse receiptResponse = new PojjamanDataModel.FNGLDocResponse();
            receiptResponse.SFDocId = receiptId;
            receiptResponse.ResponseId = 123456;
            receiptResponse.ResponseCode = 'SC';
            receiptResponse.Message = 'Success';
            receiptResponse.Timestamp = System.now();
			receiptResponse.DocLine = responseReceiptLineItemData;
            responseReceiptData.add(receiptResponse);
			PojjamanDataModel.FNGLDocResponse receiptInvoice = new PojjamanDataModel.FNGLDocResponse();
            receiptInvoice.SFDocId = invoiceId;
            receiptInvoice.ResponseId = 123456;
            receiptInvoice.ResponseCode = 'SC';
            receiptInvoice.Message = 'Success';
            receiptInvoice.Timestamp = System.now();
			receiptInvoice.DocLine = responseReceiptLineItemData;
            responseReceiptData.add(receiptInvoice);
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseReceiptData));
            res.setStatusCode(200);
            return res;
        }
    }

	@isTest
    static void processApiSuccess(){
		PaymentReceipt__c targetReceipt = [SELECT Id FROM PaymentReceipt__c LIMIT 1];
		PaymentReceiptLineItem__c targetReceiptLineItem = [SELECT Id FROM PaymentReceiptLineItem__c WHERE PaymentReceipt__c =: targetReceipt.Id LIMIT 1];
		Invoice__c targetInvoice = [SELECT Id FROM Invoice__c LIMIT 1];
		InvoiceLineItem__c targetInvoiceLineItem = [SELECT Id FROM InvoiceLineItem__c WHERE Invoice__c =: targetInvoice.Id LIMIT 1];
		SuccessGLMockResp1 mock = new SuccessGLMockResp1();
		mock.receiptId = targetReceipt.Id;
		mock.receiptLineId = targetReceiptLineItem.Id;
		mock.invoiceId = targetInvoice.Id;
		mock.invoiceLineId = targetInvoiceLineItem.Id;
		Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
			GLChangeUnitApiCalloutBatch batch = new GLChangeUnitApiCalloutBatch();
			Database.executeBatch(batch, 200);
		Test.stopTest();
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
		Test.setMock(HttpCalloutMock.class, new GLChangeUnitApiCalloutBatchTest.FailGLMockResp());
		Test.startTest();
			GLChangeUnitApiCalloutBatch batch = new GLChangeUnitApiCalloutBatch();
			Database.executeBatch(batch, 200);
		Test.stopTest();
		List<PaymentReceipt__c> allReceipts = [SELECT Id, LastGLStatusInPojjaman__c FROM PaymentReceipt__c];
		for (PaymentReceipt__c eachReceipt : allReceipts){
			System.assertEquals('Fail', eachReceipt.LastGLStatusInPojjaman__c);
		}
	}
}