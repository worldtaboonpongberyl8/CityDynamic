@isTest
public with sharing class CreateReceiptApiCalloutBatchTest {
    public static String targetSuccessReceiptId;
    public static String targetSuccessReceiptLienItemId;
    public static String targetSuccessPaymentMethodId;

	public class SuccessReceiptMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<CreateReceiptApiCallout.RequestDataModel>.class);
            List<CreateReceiptApiCallout.RequestDataModel> requestData = ( List<CreateReceiptApiCallout.RequestDataModel>)requestDataObj;

            List<CreateReceiptApiCallout.ReceiptLineItemResponse> responseReceiptLineItemData = new List<CreateReceiptApiCallout.ReceiptLineItemResponse>();
			CreateReceiptApiCallout.ReceiptLineItemResponse responseReceiptLineItem = new CreateReceiptApiCallout.ReceiptLineItemResponse();
            responseReceiptLineItem.Message = 'Success';
            responseReceiptLineItem.ResponseCode = 'SC';
            responseReceiptLineItem.SFDocLineId = targetSuccessReceiptLienItemId;
            responseReceiptLineItem.Timestamp = System.now();
            responseReceiptLineItemData.add(responseReceiptLineItem);

            List<CreateReceiptApiCallout.PaymentMethodResponse> responsePaymentMethodData = new List<CreateReceiptApiCallout.PaymentMethodResponse>();
			CreateReceiptApiCallout.PaymentMethodResponse responsePaymentMethod = new CreateReceiptApiCallout.PaymentMethodResponse();
            responsePaymentMethod.Message = 'Success';
            responsePaymentMethod.ResponseCode = 'SC';
            responsePaymentMethod.ResponseId = 123456;
            responsePaymentMethod.SFPaymentMethodId = targetSuccessPaymentMethodId;
            responsePaymentMethod.Timestamp = System.now();
            responsePaymentMethodData.add(responsePaymentMethod);

            // START MOCK RECEIPT RESPONSE
            List<CreateReceiptApiCallout.ReceiptResponse> responseReceiptData = new List<CreateReceiptApiCallout.ReceiptResponse>();
			CreateReceiptApiCallout.ReceiptResponse receiptResponse = new CreateReceiptApiCallout.ReceiptResponse();
            receiptResponse.SFDocId = targetSuccessReceiptId;
            receiptResponse.ResponseId = 123456;
            receiptResponse.ResponseCode = 'SC';
            receiptResponse.Message = 'Success';
            receiptResponse.Timestamp = System.now();
			receiptResponse.DocLine = responseReceiptLineItemData;
            receiptResponse.PaymentMethod = responsePaymentMethodData;
            responseReceiptData.add(receiptResponse);
			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseReceiptData));
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void createReceiptApiSuccess(){
        Test.setMock(HttpCalloutMock.class, new CreateReceiptApiCalloutBatchTest.SuccessReceiptMockResp());
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
			'Test Product',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert testProduct;
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
		Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
		insert account;
		// Create Opportunity
		Opportunity opportunity = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Thai',
			null,
			testProject.Id
		);
		insert opportunity;
		// Create Opp Payments
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		OpportunityPayment__c contractOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 27),
			2
		);
		OpportunityPayment__c installmentOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Installment 1',
			10000000,
			Date.newInstance(2024, 10, 27),
			3
		);
		OpportunityPayment__c transferOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Transfer',
			4850000,
			Date.newInstance(2025, 10, 27),
			4
		);
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment,
			contractOppPayment,
			installmentOppPayment,
			transferOppPayment
		};
		insert oppPayments;
		// Create Invoice
		Invoice__c invoice = dataMaker.createInvoice(opportunity.Id, Date.newInstance(2024, 10, 6), Date.newInstance(2024, 10, 1), true, 'Address');
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice };
		insert invoices;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(invoice.Id,reservationOppPayment.Id,50000,Date.newInstance(2024, 12, 1),'');
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1 };
		insert invoiceLineItems;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opportunity.Id , Date.newInstance(2024, 10, 10));
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt};
		insert receipts;
        targetSuccessReceiptId = receipt.Id;
		System.debug('Payment Receipt: '+receipt);
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,invoiceLineItem1.Id,50000,'Fully Paid');
		PaymentReceiptLineItem__c receiptItemContract = dataMaker.createReceiptLineItem(receipt.Id,contractOppPayment.Id,null,50000,'Partially Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{receiptItemReservation,receiptItemContract};
		insert receiptItems;
        targetSuccessReceiptLienItemId = receiptItemReservation.Id;
		PaymentMethod__c receiptMethod = dataMaker.createPaymentMethod(receipt.Id,'KBANK',Decimal.valueOf(1000000),'Cash','Reservation',Date.today());
		List<PaymentMethod__c> receiptMethods = new List<PaymentMethod__c>{receiptMethod};
		insert receiptMethods;
        targetSuccessPaymentMethodId = receiptMethod.Id;
        Test.startTest();
        CreateReceiptApiCalloutBatch batch = new CreateReceiptApiCalloutBatch();
        Database.executeBatch(batch, 200);
		Test.stopTest();
        PaymentReceipt__c targetPaymentReceipt = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM PaymentReceipt__c WHERE Id =: receipt.Id LIMIT 1];
        PaymentReceiptLineItem__c targetPaymentReceiptLineItem = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM PaymentReceiptLineItem__c WHERE Id =: receiptItemReservation.Id LIMIT 1];
		PaymentMethod__c targetPaymentMethod = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM PaymentMethod__c WHERE Id =: receiptMethod.Id LIMIT 1];
		System.assertEquals('Success', targetPaymentReceipt.ResponseMessage__c);
		System.assertEquals('SC', targetPaymentReceipt.ResponseCode__c);
       
        System.assertEquals('Success', targetPaymentReceiptLineItem.ResponseMessage__c);
		System.assertEquals('SC', targetPaymentReceiptLineItem.ResponseCode__c);
       
        System.assertEquals('Success', targetPaymentMethod.ResponseMessage__c);
		System.assertEquals('SC', targetPaymentMethod.ResponseCode__c);
       
    }
	public class SuccessReceiptCancelMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<CreateReceiptApiCallout.RequestDataModel>.class);
            List<CreateReceiptApiCallout.RequestDataModel> requestData = ( List<CreateReceiptApiCallout.RequestDataModel>)requestDataObj;

            List<CreateReceiptApiCallout.ReceiptLineItemResponse> responseReceiptLineItemData = new List<CreateReceiptApiCallout.ReceiptLineItemResponse>();
			CreateReceiptApiCallout.ReceiptLineItemResponse responseReceiptLineItem = new CreateReceiptApiCallout.ReceiptLineItemResponse();
            responseReceiptLineItem.Message = 'Success';
            responseReceiptLineItem.ResponseCode = 'SC';
            responseReceiptLineItem.SFDocLineId = targetSuccessReceiptLienItemId;
            responseReceiptLineItem.Timestamp = System.now();
            responseReceiptLineItemData.add(responseReceiptLineItem);

            List<CreateReceiptApiCallout.PaymentMethodResponse> responsePaymentMethodData = new List<CreateReceiptApiCallout.PaymentMethodResponse>();
			CreateReceiptApiCallout.PaymentMethodResponse responsePaymentMethod = new CreateReceiptApiCallout.PaymentMethodResponse();
            responsePaymentMethod.Message = 'Success';
            responsePaymentMethod.ResponseCode = 'SC';
            responsePaymentMethod.ResponseId = 123456;
            responsePaymentMethod.SFPaymentMethodId = targetSuccessPaymentMethodId;
            responsePaymentMethod.Timestamp = System.now();
            responsePaymentMethodData.add(responsePaymentMethod);

            // START MOCK RECEIPT RESPONSE
            List<CreateReceiptApiCallout.ReceiptResponse> responseReceiptData = new List<CreateReceiptApiCallout.ReceiptResponse>();
			CreateReceiptApiCallout.ReceiptResponse receiptResponse = new CreateReceiptApiCallout.ReceiptResponse();
            receiptResponse.SFDocId = targetSuccessReceiptId;
            receiptResponse.ResponseId = 123456;
            receiptResponse.ResponseCode = 'SC';
            receiptResponse.Message = 'Success';
            receiptResponse.Timestamp = System.now();
			receiptResponse.DocLine = responseReceiptLineItemData;
            receiptResponse.PaymentMethod = responsePaymentMethodData;
            responseReceiptData.add(receiptResponse);
			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseReceiptData));
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void createReceiptApiSuccessAndIsCancel(){
        Test.setMock(HttpCalloutMock.class, new CreateReceiptApiCalloutBatchTest.SuccessReceiptCancelMockResp());
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
			'Test Product',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert testProduct;
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
		Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
		insert account;
		// Create Opportunity
		Opportunity opportunity = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Thai',
			null,
			testProject.Id
		);
		insert opportunity;
		// Create Opp Payments
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		OpportunityPayment__c contractOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 27),
			2
		);
		OpportunityPayment__c installmentOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Installment 1',
			10000000,
			Date.newInstance(2024, 10, 27),
			3
		);
		OpportunityPayment__c transferOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Transfer',
			4850000,
			Date.newInstance(2025, 10, 27),
			4
		);
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment,
			contractOppPayment,
			installmentOppPayment,
			transferOppPayment
		};
		insert oppPayments;
		// Create Invoice
		Invoice__c invoice = dataMaker.createInvoice(opportunity.Id, Date.newInstance(2024, 10, 6), Date.newInstance(2024, 10, 1), true, 'Address');
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice };
		insert invoices;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(invoice.Id,reservationOppPayment.Id,50000,Date.newInstance(2024, 12, 1),'');
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1 };
		insert invoiceLineItems;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opportunity.Id , Date.newInstance(2024, 10, 10));
		receipt.CancelReason__c ='Cancel by CRM';
		receipt.CancelReasonforCRM__c ='Test';
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt};
		insert receipts;
        targetSuccessReceiptId = receipt.Id;
		System.debug('Payment Receipt: '+receipt);
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,invoiceLineItem1.Id,50000,'Fully Paid');
		PaymentReceiptLineItem__c receiptItemContract = dataMaker.createReceiptLineItem(receipt.Id,contractOppPayment.Id,null,50000,'Partially Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{receiptItemReservation,receiptItemContract};
		insert receiptItems;
        targetSuccessReceiptLienItemId = receiptItemReservation.Id;
		PaymentMethod__c receiptMethod = dataMaker.createPaymentMethod(receipt.Id,'KBANK',Decimal.valueOf(1000000),'Cash','Reservation',Date.today());
		List<PaymentMethod__c> receiptMethods = new List<PaymentMethod__c>{receiptMethod};
		insert receiptMethods;
        targetSuccessPaymentMethodId = receiptMethod.Id;
        Test.startTest();
        CreateReceiptApiCalloutBatch batch = new CreateReceiptApiCalloutBatch();
        Database.executeBatch(batch, 200);
		Test.stopTest();
        PaymentReceipt__c targetPaymentReceipt = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM PaymentReceipt__c WHERE Id =: receipt.Id LIMIT 1];
        PaymentReceiptLineItem__c targetPaymentReceiptLineItem = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM PaymentReceiptLineItem__c WHERE Id =: receiptItemReservation.Id LIMIT 1];
		PaymentMethod__c targetPaymentMethod = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM PaymentMethod__c WHERE Id =: receiptMethod.Id LIMIT 1];
		System.assertEquals('Success', targetPaymentReceipt.ResponseMessage__c);
		System.assertEquals('SC', targetPaymentReceipt.ResponseCode__c);
       
        System.assertEquals('Success', targetPaymentReceiptLineItem.ResponseMessage__c);
		System.assertEquals('SC', targetPaymentReceiptLineItem.ResponseCode__c);
       
        System.assertEquals('Success', targetPaymentMethod.ResponseMessage__c);
		System.assertEquals('SC', targetPaymentMethod.ResponseCode__c);
       
    }
	public class SuccessReceiptCancelStatusInPojjamanFailMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<CreateReceiptApiCallout.RequestDataModel>.class);
            List<CreateReceiptApiCallout.RequestDataModel> requestData = ( List<CreateReceiptApiCallout.RequestDataModel>)requestDataObj;

            List<CreateReceiptApiCallout.ReceiptLineItemResponse> responseReceiptLineItemData = new List<CreateReceiptApiCallout.ReceiptLineItemResponse>();
			CreateReceiptApiCallout.ReceiptLineItemResponse responseReceiptLineItem = new CreateReceiptApiCallout.ReceiptLineItemResponse();
            responseReceiptLineItem.Message = 'Success';
            responseReceiptLineItem.ResponseCode = 'SC';
            responseReceiptLineItem.SFDocLineId = targetSuccessReceiptLienItemId;
            responseReceiptLineItem.Timestamp = System.now();
            responseReceiptLineItemData.add(responseReceiptLineItem);

            List<CreateReceiptApiCallout.PaymentMethodResponse> responsePaymentMethodData = new List<CreateReceiptApiCallout.PaymentMethodResponse>();
			CreateReceiptApiCallout.PaymentMethodResponse responsePaymentMethod = new CreateReceiptApiCallout.PaymentMethodResponse();
            responsePaymentMethod.Message = 'Success';
            responsePaymentMethod.ResponseCode = 'SC';
            responsePaymentMethod.ResponseId = 123456;
            responsePaymentMethod.SFPaymentMethodId = targetSuccessPaymentMethodId;
            responsePaymentMethod.Timestamp = System.now();
            responsePaymentMethodData.add(responsePaymentMethod);

            // START MOCK RECEIPT RESPONSE
            List<CreateReceiptApiCallout.ReceiptResponse> responseReceiptData = new List<CreateReceiptApiCallout.ReceiptResponse>();
			CreateReceiptApiCallout.ReceiptResponse receiptResponse = new CreateReceiptApiCallout.ReceiptResponse();
            receiptResponse.SFDocId = targetSuccessReceiptId;
            receiptResponse.ResponseId = 123456;
            receiptResponse.ResponseCode = 'SC';
            receiptResponse.Message = 'Success';
            receiptResponse.Timestamp = System.now();
			receiptResponse.DocLine = responseReceiptLineItemData;
            receiptResponse.PaymentMethod = responsePaymentMethodData;
            responseReceiptData.add(receiptResponse);
			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseReceiptData));
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void createReceiptApiSuccessAndIsCancelCloseLost(){
        Test.setMock(HttpCalloutMock.class, new CreateReceiptApiCalloutBatchTest.SuccessReceiptCancelStatusInPojjamanFailMockResp());
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
			'Test Product',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert testProduct;
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
		Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
		insert account;
		// Create Opportunity
		Opportunity opportunity = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Thai',
			null,
			testProject.Id
		);
		insert opportunity;
		// Create Opp Payments
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		OpportunityPayment__c contractOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 27),
			2
		);
		OpportunityPayment__c installmentOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Installment 1',
			10000000,
			Date.newInstance(2024, 10, 27),
			3
		);
		OpportunityPayment__c transferOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Transfer',
			4850000,
			Date.newInstance(2025, 10, 27),
			4
		);
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment,
			contractOppPayment,
			installmentOppPayment,
			transferOppPayment
		};
		insert oppPayments;
		// Create Invoice
		Invoice__c invoice = dataMaker.createInvoice(opportunity.Id, Date.newInstance(2024, 10, 6), Date.newInstance(2024, 10, 1), true, 'Address');
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice };
		insert invoices;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(invoice.Id,reservationOppPayment.Id,50000,Date.newInstance(2024, 12, 1),'');
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1 };
		insert invoiceLineItems;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opportunity.Id , Date.newInstance(2024, 10, 10));
		receipt.CancelReason__c ='Cancel by CRM';
		receipt.CancelReasonforCRM__c ='Test';
		receipt.LastCancelledStatusInPojjaman__c = 'Test';
		receipt.LastCreatedStatusInPojjaman__c = 'Test';
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt};
		insert receipts;
        targetSuccessReceiptId = receipt.Id;
		System.debug('Payment Receipt: '+receipt);
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,invoiceLineItem1.Id,50000,'Fully Paid');
		PaymentReceiptLineItem__c receiptItemContract = dataMaker.createReceiptLineItem(receipt.Id,contractOppPayment.Id,null,50000,'Partially Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{receiptItemReservation,receiptItemContract};
		insert receiptItems;
        targetSuccessReceiptLienItemId = receiptItemReservation.Id;
		PaymentMethod__c receiptMethod = dataMaker.createPaymentMethod(receipt.Id,'KBANK',Decimal.valueOf(1000000),'Cash','Reservation',Date.today());
		List<PaymentMethod__c> receiptMethods = new List<PaymentMethod__c>{receiptMethod};
		insert receiptMethods;
        targetSuccessPaymentMethodId = receiptMethod.Id;
        Test.startTest();
        CreateReceiptApiCalloutBatch batch = new CreateReceiptApiCalloutBatch();
        Database.executeBatch(batch, 200);
		Test.stopTest();
        PaymentReceipt__c targetPaymentReceipt = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM PaymentReceipt__c WHERE Id =: receipt.Id LIMIT 1];
        PaymentReceiptLineItem__c targetPaymentReceiptLineItem = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM PaymentReceiptLineItem__c WHERE Id =: receiptItemReservation.Id LIMIT 1];
		PaymentMethod__c targetPaymentMethod = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM PaymentMethod__c WHERE Id =: receiptMethod.Id LIMIT 1];
		System.assertEquals('Success', targetPaymentReceipt.ResponseMessage__c);
		System.assertEquals('SC', targetPaymentReceipt.ResponseCode__c);
       
        System.assertEquals('Success', targetPaymentReceiptLineItem.ResponseMessage__c);
		System.assertEquals('SC', targetPaymentReceiptLineItem.ResponseCode__c);
       
        System.assertEquals('Success', targetPaymentMethod.ResponseMessage__c);
		System.assertEquals('SC', targetPaymentMethod.ResponseCode__c);
       
    }
    ////////////////////////////////////////////////////////////////
    public class FailReceiptMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<CreateReceiptApiCallout.RequestDataModel>.class);
            List<CreateReceiptApiCallout.RequestDataModel> requestData = ( List<CreateReceiptApiCallout.RequestDataModel>)requestDataObj;

            // START MOCK RECEIPT RESPONSE
            List<CreateReceiptApiCallout.ReceiptResponse> responseReceiptData = new List<CreateReceiptApiCallout.ReceiptResponse>();
			
			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseReceiptData));
            res.setStatusCode(500);
            return res;
        }
    }
    @isTest
    static void createReceiptApiFail(){
        Test.setMock(HttpCalloutMock.class, new CreateReceiptApiCalloutBatchTest.FailReceiptMockResp());
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
			'Test Product',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert testProduct;
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
		Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
		insert account;
		// Create Opportunity
		Opportunity opportunity = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Thai',
			null,
			testProject.Id
		);
		insert opportunity;
		// Create Opp Payments
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		OpportunityPayment__c contractOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 27),
			2
		);
		OpportunityPayment__c installmentOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Installment 1',
			10000000,
			Date.newInstance(2024, 10, 27),
			3
		);
		OpportunityPayment__c transferOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Transfer',
			4850000,
			Date.newInstance(2025, 10, 27),
			4
		);
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment,
			contractOppPayment,
			installmentOppPayment,
			transferOppPayment
		};
		insert oppPayments;
		// Create Invoice
		Invoice__c invoice = dataMaker.createInvoice(opportunity.Id, Date.newInstance(2024, 10, 6), Date.newInstance(2024, 10, 1), true, 'Address');
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice };
		insert invoices;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(invoice.Id,reservationOppPayment.Id,50000,Date.newInstance(2024, 12, 1),'');
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1 };
		insert invoiceLineItems;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opportunity.Id , Date.newInstance(2024, 10, 10));
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt};
		insert receipts;
        targetSuccessReceiptId = receipt.Id;
		System.debug('Payment Receipt: '+receipt);
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,invoiceLineItem1.Id,50000,'Fully Paid');
		PaymentReceiptLineItem__c receiptItemContract = dataMaker.createReceiptLineItem(receipt.Id,contractOppPayment.Id,null,50000,'Partially Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{receiptItemReservation,receiptItemContract};
		insert receiptItems;
        targetSuccessReceiptLienItemId = receiptItemReservation.Id;
		PaymentMethod__c receiptMethod = dataMaker.createPaymentMethod(receipt.Id,'KBANK',Decimal.valueOf(1000000),'Cash','Reservation',Date.today());
		List<PaymentMethod__c> receiptMethods = new List<PaymentMethod__c>{receiptMethod};
		insert receiptMethods;
        targetSuccessPaymentMethodId = receiptMethod.Id;
        Test.startTest();
        CreateReceiptApiCalloutBatch batch = new CreateReceiptApiCalloutBatch();
        Database.executeBatch(batch, 200);
		Test.stopTest();
        PaymentReceipt__c targetPaymentReceipt = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM PaymentReceipt__c WHERE Id =: receipt.Id LIMIT 1];
        PaymentReceiptLineItem__c targetPaymentReceiptLineItem = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM PaymentReceiptLineItem__c WHERE Id =: receiptItemReservation.Id LIMIT 1];
		PaymentMethod__c targetPaymentMethod = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM PaymentMethod__c WHERE Id =: receiptMethod.Id LIMIT 1];
        System.assertEquals('ERR', targetPaymentReceipt.ResponseCode__c);
        System.assertEquals('ERR', targetPaymentReceiptLineItem.ResponseCode__c);
        System.assertEquals('ERR', targetPaymentMethod.ResponseCode__c);
        
        
    }

}