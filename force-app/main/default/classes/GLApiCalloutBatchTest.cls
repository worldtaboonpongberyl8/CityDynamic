@isTest
public with sharing class GLApiCalloutBatchTest {
    public static String targetInvoiceId;
    public static String targetInvoiceLienItemId;

	public class SuccessGLMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<GLApiCallout.RequestDataModel>.class);
            List<GLApiCallout.RequestDataModel> requestData = ( List<GLApiCallout.RequestDataModel>)requestDataObj;

            List<GLApiCallout.GLLineItemResponse> responseInvoiceLineItemData = new List<GLApiCallout.GLLineItemResponse>();
			GLApiCallout.GLLineItemResponse responseInvoiceLineItem = new GLApiCallout.GLLineItemResponse();
            responseInvoiceLineItem.ResponseId = 123456;
            responseInvoiceLineItem.Message = 'Success';
            responseInvoiceLineItem.ResponseCode = 'SC';
            responseInvoiceLineItem.SFDocLineId = targetInvoiceLienItemId;
            responseInvoiceLineItem.Timestamp = System.now();
            responseInvoiceLineItemData.add(responseInvoiceLineItem);

            // START MOCK RECEIPT RESPONSE
            List<GLApiCallout.GLResponse> responseInvoiceData = new List<GLApiCallout.GLResponse>();
			GLApiCallout.GLResponse invoiceResponse = new GLApiCallout.GLResponse();
            invoiceResponse.SFDocId = targetInvoiceId;
            invoiceResponse.ResponseId = 123456;
            invoiceResponse.ResponseCode = 'SC';
            invoiceResponse.Message = 'Success';
            invoiceResponse.Timestamp = System.now();
			invoiceResponse.DocLine = responseInvoiceLineItemData;
            responseInvoiceData.add(invoiceResponse);
			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseInvoiceData));
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void processApiSuccess(){
        Test.setMock(HttpCalloutMock.class, new GLApiCalloutBatchTest.SuccessGLMockResp());
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
		System.debug(testProduct+'<---HERE');
		opp1.StageName = 'Reservation';
		update opp1;

		Contract contract = dataMaker.createContract(opp1.Id,targetAccount.Id);
		insert contract;
		contract.Status = 'Signed Contract';
		contract.ContractSignedDate__c = Date.today();
		update contract;
		opp1.StageName = 'Contract';
		update opp1;
		Opportunity targetOppAfterInsert3 = [
			SELECT Id, Unit__c, Quota__c, PaymentTermMaster__c
			FROM Opportunity
			WHERE Id = :opp1.Id
			LIMIT 1
		];
		targetOppAfterInsert3.TransferredDate__c = Date.today();
		targetOppAfterInsert3.StageName = 'Transferred';
		update targetOppAfterInsert3;
		oppTriggerHandler.clearBypass();
		Opportunity targetOppAfterInsert5 = [
			SELECT Id, Unit__c, Quota__c, PaymentTermMaster__c
			FROM Opportunity
			WHERE Id = :opp1.Id
			LIMIT 1
		];
		System.debug(testProduct+'<---HERE');
		testProduct.Status__c = 'Transferred';
		update testProduct;
		oppTriggerHandler.setBypass();
		System.debug(testProduct+'<---HERE Status ');
		targetOppAfterInsert5.LossReason__c = 'No Interest';
		targetOppAfterInsert5.CloseDate = Date.today();
		targetOppAfterInsert5.StageName = 'Closed Lost';
		targetOppAfterInsert5.ClosedLostDate__c = Date.today();
		update targetOppAfterInsert5;
		oppTriggerHandler.clearBypass();
		System.debug(targetOppAfterInsert5+'----->');
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
		// Create Invoice
		Invoice__c invoice = dataMaker.createInvoice(targetOppAfterInsert5.Id, Date.newInstance(2024, 10, 6), Date.newInstance(2024, 10, 1), true, 'Address');
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice };
		insert invoices;
		System.debug(invoice + '------>');
        targetInvoiceId = invoice.Id;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(invoice.Id,reservationOppPayment.Id,50000,Date.newInstance(2024, 12, 1),'');
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1 };
		insert invoiceLineItems;
        targetInvoiceLienItemId = invoiceLineItem1.Id;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(targetOppAfterInsert5.Id , Date.newInstance(2024, 10, 10));
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt};
		receipt.CancelReason__c = 'Closed Lost';
		insert receipts;

		System.debug('Payment Receipt: '+receipt);
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,invoiceLineItem1.Id,50000,'Fully Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{ receiptItemReservation };
		insert receiptItems;

		PaymentMethod__c receiptMethod = dataMaker.createPaymentMethod(receipt.Id,'KBANK',Decimal.valueOf(1000000),'Cash','Reservation',Date.today());
		List<PaymentMethod__c> receiptMethods = new List<PaymentMethod__c>{receiptMethod};
		insert receiptMethods;

        Test.startTest();
        GLApiCalloutBatch batch = new GLApiCalloutBatch();
        Database.executeBatch(batch, 200);
		Test.stopTest();
        Invoice__c targetInvoice = [SELECT Id,ResponseMessage__c,ResponseCode__c,LastCreatedStatusInPojjaman__c FROM Invoice__c WHERE Id =: invoice.Id LIMIT 1];
		InvoiceLineItem__c targetInvoiceLineItem = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM InvoiceLineItem__c WHERE Id =: invoiceLineItem1.Id LIMIT 1];
		System.assertEquals('Success', targetInvoice.ResponseMessage__c);
		System.assertEquals('SC', targetInvoice.ResponseCode__c);
		System.assertEquals('Success', targetInvoiceLineItem.ResponseMessage__c);
		System.assertEquals('SC', targetInvoiceLineItem.ResponseCode__c);
    }
	public class FailGLMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<GLApiCallout.RequestDataModel>.class);
            List<GLApiCallout.RequestDataModel> requestData = ( List<GLApiCallout.RequestDataModel>)requestDataObj;

            // START MOCK RECEIPT RESPONSE
            List<GLApiCallout.GLResponse> responseInvoiceData = new List<GLApiCallout.GLResponse>();

			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseInvoiceData));
            res.setStatusCode(500);
            return res;
        }
    }
    @isTest
    static void processApiFail(){
        Test.setMock(HttpCalloutMock.class, new GLApiCalloutBatchTest.FailGLMockResp());
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
		opp1.ReservationDueDate__c = Date.newInstance(2024, 10, 12);
		opp1.LastGLStatusInPojjaman__c = 'Fail';
		insert opp1;
		// Create Opp Payments
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opp1.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);

		insert reservationOppPayment;
		// Create Invoice
		Invoice__c invoice = dataMaker.createInvoice(opp1.Id, Date.newInstance(2024, 10, 6), Date.newInstance(2024, 10, 1), true, 'Address');
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice };
		insert invoices;
		System.debug(invoice + '------>');
        targetInvoiceId = invoice.Id;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(invoice.Id,reservationOppPayment.Id,50000,Date.newInstance(2024, 12, 1),'');
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1 };
		insert invoiceLineItems;
        targetInvoiceLienItemId = invoiceLineItem1.Id;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opp1.Id , Date.newInstance(2024, 10, 10));
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt};
		receipt.CancelReason__c = 'Closed Lost';
		insert receipts;

		System.debug('Payment Receipt: '+receipt);
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,invoiceLineItem1.Id,50000,'Fully Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{ receiptItemReservation };
		insert receiptItems;

		PaymentMethod__c receiptMethod = dataMaker.createPaymentMethod(receipt.Id,'KBANK',Decimal.valueOf(1000000),'Cash','Reservation',Date.today());
		List<PaymentMethod__c> receiptMethods = new List<PaymentMethod__c>{receiptMethod};
		insert receiptMethods;

        Test.startTest();
        GLApiCalloutBatch batch = new GLApiCalloutBatch();
        Database.executeBatch(batch, 200);
		Test.stopTest();
        Invoice__c targetInvoice = [SELECT Id,ResponseMessage__c,ResponseCode__c,LastCreatedStatusInPojjaman__c FROM Invoice__c WHERE Id =: invoice.Id LIMIT 1];
		InvoiceLineItem__c targetInvoiceLineItem = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM InvoiceLineItem__c WHERE Id =: invoiceLineItem1.Id LIMIT 1];

		System.assertEquals('ERR', targetInvoice.ResponseCode__c);

		System.assertEquals('ERR', targetInvoiceLineItem.ResponseCode__c);
    }
}