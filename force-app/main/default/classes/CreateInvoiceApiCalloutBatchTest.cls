@isTest
public with sharing class CreateInvoiceApiCalloutBatchTest {

	public static String succesDocId;
	public static String succesDocLineId;
	public static String succesDocId2;
	public static String succesDocLineId2;
	public static String targetFailDocId;

    public class SuccessInvoiceMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<CreateInvoiceApiCallout.RequestDataModel>.class);
            List<CreateInvoiceApiCallout.RequestDataModel> requestData = ( List<CreateInvoiceApiCallout.RequestDataModel>)requestDataObj;
			// START MOCK RESPONSE
            List<CreateInvoiceApiCallout.InvoiceResponse> responseInvoiceData = new List<CreateInvoiceApiCallout.InvoiceResponse>();
			CreateInvoiceApiCallout.InvoiceResponse invoiceResponse = new CreateInvoiceApiCallout.InvoiceResponse();
			invoiceResponse.DocLine = new List<CreateInvoiceApiCallout.InvoiceLineItemResponse>();
			invoiceResponse.SFDocId = succesDocId;
			invoiceResponse.ResponseCode = 'SC';
			invoiceResponse.Message = 'Success';
			CreateInvoiceApiCallout.InvoiceLineItemResponse invoiceLineItemResponse = new CreateInvoiceApiCallout.InvoiceLineItemResponse();
			invoiceLineItemResponse.ResponseCode = 'SC';
			invoiceLineItemResponse.SFDocLineId = succesDocLineId;
			invoiceLineItemResponse.Message = 'Success';
			invoiceResponse.DocLine.add(invoiceLineItemResponse);
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
	static void craeteInvoiceCalloutTestSuccess(){
		Test.setMock(HttpCalloutMock.class, new CreateInvoiceApiCalloutBatchTest.SuccessInvoiceMockResp());
		DataMaker dataMaker = DataMaker.getInstance();
		// CREATE PROJECT
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert testProject;
		// CREATE FLOOR
		Floor__c testFloor = dataMaker.createFloor('Test Floor', 'FF01', testProject.Id);
		insert testFloor;
		// CREATE UNIT TYPE
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type', testProject.Id);
		insert unitType;
		// CREATE UNIT
		Product2 unit1 = dataMaker.createUnit(
			'Test Product',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert unit1;
		// CREATE ACCOUNT
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'BE8');
		insert account;
		// CREATE OPPORTUNITY
		Opportunity opp = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.newInstance(2024, 10, 1),
			'Open',
			unit1.Id,
			'Foreign',
			null,
			testProject.Id
		);
		opp.DoNotSendInvoice__c = true;
		insert opp;
		// CREATE OPP PAYMENT
		OpportunityPayment__c reservationOppPaymentOpp1 = dataMaker.createOpportunityPayment(
			opp.Id,
			'opp',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		insert reservationOppPaymentOpp1;
		Date dueDate = Date.newInstance(2024, 11, 1);
		Date invoiceDate = Date.newInstance(2024, 10, 27);
		// CREATE INVOICE
		Invoice__c invoice = dataMaker.createInvoice(opp.Id, dueDate, invoiceDate, opp.DoNotSendInvoice__c, opp.Account.AddressEN__c);
		insert invoice;
		succesDocId = invoice.Id;
		// CREATE INVOICE LINE ITEM
		InvoiceLineItem__c ivline = dataMaker.createInvoiceLineItem(invoice.Id,reservationOppPaymentOpp1.Id,50000,dueDate,'');
		insert ivline;
		succesDocLineId = ivline.Id;
		Test.startTest();
		// EXECUTE BATCH
		CreateInvoiceApiCalloutBatch batch = new CreateInvoiceApiCalloutBatch();
		Database.executeBatch(batch, 2000);
		Test.stopTest();
		Invoice__c targetInvoice = [SELECT Id,ResponseMessage__c,ResponseCode__c,LastCreatedStatusInPojjaman__c FROM Invoice__c WHERE Id =: invoice.Id LIMIT 1];
		InvoiceLineItem__c targetInvoiceLineItem = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM InvoiceLineItem__c WHERE Id =: ivline.Id LIMIT 1];
		System.assertEquals('Success', targetInvoice.ResponseMessage__c);
		System.assertEquals('Success', targetInvoice.LastCreatedStatusInPojjaman__c);
		System.assertEquals('SC', targetInvoice.ResponseCode__c);
		System.assertEquals('Success', targetInvoiceLineItem.ResponseMessage__c);
		System.assertEquals('SC', targetInvoiceLineItem.ResponseCode__c);
	}

	public class SuccessInvoiceRetryMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<CreateInvoiceApiCallout.RequestDataModel>.class);
            List<CreateInvoiceApiCallout.RequestDataModel> requestData = ( List<CreateInvoiceApiCallout.RequestDataModel>)requestDataObj;
			// START MOCK RESPONSE
            List<CreateInvoiceApiCallout.InvoiceResponse> responseInvoiceData = new List<CreateInvoiceApiCallout.InvoiceResponse>();
			CreateInvoiceApiCallout.InvoiceResponse invoiceResponse = new CreateInvoiceApiCallout.InvoiceResponse();
			invoiceResponse.DocLine = new List<CreateInvoiceApiCallout.InvoiceLineItemResponse>();
			invoiceResponse.SFDocId = succesDocId;
			invoiceResponse.ResponseCode = 'SC';
			invoiceResponse.Message = 'Success';
			CreateInvoiceApiCallout.InvoiceLineItemResponse invoiceLineItemResponse = new CreateInvoiceApiCallout.InvoiceLineItemResponse();
			invoiceLineItemResponse.ResponseCode = 'SC';
			invoiceLineItemResponse.SFDocLineId = succesDocLineId;
			invoiceLineItemResponse.Message = 'Success';
			invoiceResponse.DocLine.add(invoiceLineItemResponse);

			CreateInvoiceApiCallout.InvoiceResponse invoiceResponse2 = new CreateInvoiceApiCallout.InvoiceResponse();
			invoiceResponse2.DocLine = new List<CreateInvoiceApiCallout.InvoiceLineItemResponse>();
			invoiceResponse2.SFDocId = succesDocId2;
			invoiceResponse2.ResponseCode = 'SC';
			invoiceResponse2.Message = 'Success';
			CreateInvoiceApiCallout.InvoiceLineItemResponse invoiceLineItemResponse2 = new CreateInvoiceApiCallout.InvoiceLineItemResponse();
			invoiceLineItemResponse2.ResponseCode = 'SC';
			invoiceLineItemResponse2.SFDocLineId = succesDocLineId2;
			invoiceLineItemResponse2.Message = 'Success';
			invoiceResponse.DocLine.add(invoiceLineItemResponse2);

			responseInvoiceData.add(invoiceResponse);
			responseInvoiceData.add(invoiceResponse2);
			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseInvoiceData));
            res.setStatusCode(200);
            return res;
        }
    }

	@isTest
	static void craeteInvoiceCalloutTestRetrySuccess(){
		Test.setMock(HttpCalloutMock.class, new CreateInvoiceApiCalloutBatchTest.SuccessInvoiceRetryMockResp());
		DataMaker dataMaker = DataMaker.getInstance();
		// CREATE PROJECT
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert testProject;
		// CREATE FLOOR
		Floor__c testFloor = dataMaker.createFloor('Test Floor', 'FF01', testProject.Id);
		insert testFloor;
		// CREATE UNIT TYPE
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type', testProject.Id);
		insert unitType;
		// CREATE UNIT
		Product2 unit1 = dataMaker.createUnit(
			'Test Product',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert unit1;
		// CREATE ACCOUNT
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'BE8');
		insert account;
		// CREATE OPPORTUNITY
		Opportunity opp = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.newInstance(2024, 10, 1),
			'Open',
			unit1.Id,
			'Foreign',
			null,
			testProject.Id
		);
		opp.DoNotSendInvoice__c = true;
		insert opp;
		// CREATE OPP PAYMENT
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opp.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		OpportunityPayment__c contractOppPayment = dataMaker.createOpportunityPayment(
			opp.Id,
			'Contract',
			50000,
			Date.newInstance(2024, 11, 15),
			2
		);
		insert new List<OpportunityPayment__c>{reservationOppPayment , contractOppPayment};

		Date dueDate = Date.newInstance(2024, 11, 1);
		Date invoiceDate = Date.newInstance(2024, 10, 27);
		// CREATE INVOICE
		Invoice__c reservationInvoice = dataMaker.createInvoice(opp.Id, dueDate, invoiceDate, opp.DoNotSendInvoice__c, opp.Account.AddressEN__c);
		reservationInvoice.LastCreatedStatusInPojjaman__c = 'Fail';
		Invoice__c contractInvoice = dataMaker.createInvoice(opp.Id, dueDate, invoiceDate, opp.DoNotSendInvoice__c, opp.Account.AddressEN__c);
		insert new List<Invoice__c>{reservationInvoice,contractInvoice};
		succesDocId = reservationInvoice.Id;
		succesDocId2 = contractInvoice.Id;
		// CREATE INVOICE LINE ITEM
		InvoiceLineItem__c ivline = dataMaker.createInvoiceLineItem(reservationInvoice.Id,reservationOppPayment.Id,50000,dueDate,'');
		InvoiceLineItem__c ivline2 = dataMaker.createInvoiceLineItem(contractInvoice.Id,contractOppPayment.Id,50000,dueDate,'');
		insert new List<InvoiceLineItem__c>{ivline,ivline2};
		succesDocLineId = ivline.Id;
		succesDocLineId2 = ivline2.Id;
		Test.startTest();
		// EXECUTE BATCH
		CreateInvoiceApiCalloutBatch batch = new CreateInvoiceApiCalloutBatch();
		Database.executeBatch(batch, 2000);
		Test.stopTest();
		Invoice__c targetInvoice = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM Invoice__c WHERE Id =: reservationInvoice.Id LIMIT 1];
		Invoice__c targetInvoice2 = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM Invoice__c WHERE Id =: contractInvoice.Id LIMIT 1];
		InvoiceLineItem__c targetInvoiceLineItem = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM InvoiceLineItem__c WHERE Id =: ivline.Id LIMIT 1];
		System.assertEquals('Success', targetInvoice.ResponseMessage__c);
		System.assertEquals('SC', targetInvoice.ResponseCode__c);
		System.assertEquals('Success', targetInvoice2.ResponseMessage__c);
		System.assertEquals('SC', targetInvoice2.ResponseCode__c);
		System.assertEquals('Success', targetInvoiceLineItem.ResponseMessage__c);
		System.assertEquals('SC', targetInvoiceLineItem.ResponseCode__c);
	}

	public class SystemFailInvoiceMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<CreateInvoiceApiCallout.RequestDataModel>.class);
            List<CreateInvoiceApiCallout.RequestDataModel> requestData = ( List<CreateInvoiceApiCallout.RequestDataModel>)requestDataObj;
			// START MOCK RESPONSE
            List<CreateInvoiceApiCallout.InvoiceResponse> responseInvoiceData = new List<CreateInvoiceApiCallout.InvoiceResponse>();
			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseInvoiceData));
            res.setStatusCode(500);
            return res;
        }
    }

	@isTest
	static void craeteAccountAndContactCalloutTestSystemFail(){
		Test.setMock(HttpCalloutMock.class, new CreateInvoiceApiCalloutBatchTest.SystemFailInvoiceMockResp());
		DataMaker dataMaker = DataMaker.getInstance();
		// CREATE PROJECT
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert testProject;
		// CREATE FLOOR
		Floor__c testFloor = dataMaker.createFloor('Test Floor', 'FF01', testProject.Id);
		insert testFloor;
		// CREATE UNIT TYPE
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type', testProject.Id);
		insert unitType;
		// CREATE UNIT
		Product2 unit1 = dataMaker.createUnit(
			'Test Product',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert unit1;
		// CREATE ACCOUNT
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'BE8');
		insert account;
		// CREATE OPPORTUNITY
		Opportunity opp = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.newInstance(2024, 10, 1),
			'Open',
			unit1.Id,
			'Foreign',
			null,
			testProject.Id
		);
		opp.DoNotSendInvoice__c = true;
		insert opp;
		// CREATE OPP PAYMENT
		OpportunityPayment__c reservationOppPaymentOpp1 = dataMaker.createOpportunityPayment(
			opp.Id,
			'opp',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		insert reservationOppPaymentOpp1;
		Date dueDate = Date.newInstance(2024, 11, 1);
		Date invoiceDate = Date.newInstance(2024, 10, 27);
		// CREATE INVOICE
		Invoice__c invoice = dataMaker.createInvoice(opp.Id, dueDate, invoiceDate, opp.DoNotSendInvoice__c, opp.Account.AddressEN__c);
		insert invoice;
		succesDocId = invoice.Id;
		// CREATE INVOICE LINE ITEM
		InvoiceLineItem__c ivline = dataMaker.createInvoiceLineItem(invoice.Id,reservationOppPaymentOpp1.Id,50000,dueDate,'');
		insert ivline;
		succesDocLineId = ivline.Id;
		Test.startTest();
		// EXECUTE BATCH
		CreateInvoiceApiCalloutBatch batch = new CreateInvoiceApiCalloutBatch();
		Database.executeBatch(batch, 2000);
		Test.stopTest();
		Invoice__c targetInvoice = [SELECT Id,ResponseMessage__c,ResponseCode__c,LastCreatedStatusInPojjaman__c FROM Invoice__c WHERE Id =: invoice.Id LIMIT 1];
		InvoiceLineItem__c targetInvoiceLineItem = [SELECT Id,ResponseMessage__c,ResponseCode__c FROM InvoiceLineItem__c WHERE Id =: ivline.Id LIMIT 1];
		System.assertEquals('ERR', targetInvoice.ResponseCode__c);
		System.assertEquals('ERR', targetInvoiceLineItem.ResponseCode__c);
	}

}