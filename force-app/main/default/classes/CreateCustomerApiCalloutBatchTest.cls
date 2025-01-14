@isTest
public with sharing class CreateCustomerApiCalloutBatchTest {

	public static String targetSuccessAccountId;
	public static String targetFailAccountId;
	public static String targetSuccessContact1;
	public static String targetSuccessContact2;

	public class SuccessAccountMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<CreateCustomerApiCallout.RequestDataModel>.class);
            List<CreateCustomerApiCallout.RequestDataModel> requestData = ( List<CreateCustomerApiCallout.RequestDataModel>)requestDataObj;
			// START MOCK RESPONSE
            List<CreateCustomerApiCallout.AccountResponse> responseAccountData = new List<CreateCustomerApiCallout.AccountResponse>();
			CreateCustomerApiCallout.AccountResponse accountResponse = new CreateCustomerApiCallout.AccountResponse();
			accountResponse.Contacts = new List<CreateCustomerApiCallout.ContactResponse>();
			accountResponse.SFCustomerId = targetSuccessAccountId;
			accountResponse.CustomerCode = '1234';
			accountResponse.ResponseCode = 'SC';
			accountResponse.Message = 'Success';
			responseAccountData.add(accountResponse);
			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseAccountData));
            res.setStatusCode(200);
            return res;
        }
    }

	@isTest
	static void craeteAccountCalloutTestSuccess(){
		Test.setMock(HttpCalloutMock.class, new CreateCustomerApiCalloutBatchTest.SuccessAccountMockResp());
		DataMaker dataMaker = DataMaker.getInstance();
		// CREATE ACCOUNT
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'BE8');
		insert account;
		targetSuccessAccountId = account.Id;
		Test.startTest();
		// EXECUTE BATCH
		CreateCustomerApiCalloutBatch batch = new CreateCustomerApiCalloutBatch();
		Database.executeBatch(batch, 2000);
		Test.stopTest();
		Account targetAccount = [SELECT Id,AccountCode__c,ResponseMessage__c,ResponseCode__c FROM Account WHERE Id =: account.Id LIMIT 1];
		System.assertEquals('Success', targetAccount.ResponseMessage__c);
		System.assertEquals('SC', targetAccount.ResponseCode__c);
		System.assertEquals('1234', targetAccount.AccountCode__c);
		List<b8log_Integration_Log__c> intLogs = [SELECT Id, Status__c FROM b8log_Integration_Log__c];
        System.assertEquals(1, intLogs.size());
        System.assertEquals(b8log.IntegrationStatus.SUCCESS.name(), intLogs.get(0).Status__c);
	}

	public class FailAccountMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<CreateCustomerApiCallout.RequestDataModel>.class);
            List<CreateCustomerApiCallout.RequestDataModel> requestData = ( List<CreateCustomerApiCallout.RequestDataModel>)requestDataObj;
			// START MOCK RESPONSE
            List<CreateCustomerApiCallout.AccountResponse> responseAccountData = new List<CreateCustomerApiCallout.AccountResponse>();
			// SUCCESS RESPONSE
			CreateCustomerApiCallout.AccountResponse accountSuccessResponse = new CreateCustomerApiCallout.AccountResponse();
			accountSuccessResponse.Contacts = new List<CreateCustomerApiCallout.ContactResponse>();
			accountSuccessResponse.SFCustomerId = targetSuccessAccountId;
			accountSuccessResponse.CustomerCode = '1234';
			accountSuccessResponse.ResponseCode = 'SC';
			accountSuccessResponse.Message = 'Success';
			responseAccountData.add(accountSuccessResponse);
			// FAIL RESPONSE
			CreateCustomerApiCallout.AccountResponse accountFailResponse = new CreateCustomerApiCallout.AccountResponse();
			accountFailResponse.Contacts = new List<CreateCustomerApiCallout.ContactResponse>();
			accountFailResponse.SFCustomerId = targetFailAccountId;
			accountFailResponse.ResponseCode = 'DP';
			accountFailResponse.Message = 'Duplicated';
			responseAccountData.add(accountFailResponse);
			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseAccountData));
            res.setStatusCode(200);
            return res;
        }
    }

	@isTest
	static void craeteAccountCalloutTestFail(){
		Test.setMock(HttpCalloutMock.class, new CreateCustomerApiCalloutBatchTest.FailAccountMockResp());
		DataMaker dataMaker = DataMaker.getInstance();
		// CREATE ACCOUNT
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account1 = dataMaker.createAccount(recordTypeId, 'BE8');
		Account account2 = dataMaker.createAccount(recordTypeId, 'BE8-Fail');
		insert new List<Account>{account1 , account2};
		targetSuccessAccountId = account1.Id;
		targetFailAccountId = account2.Id;
		Test.startTest();
		// EXECUTE BATCH
		CreateCustomerApiCalloutBatch batch = new CreateCustomerApiCalloutBatch();
		Database.executeBatch(batch, 2000);
		Test.stopTest();
		Account targetSuccessAccount = [SELECT Id,AccountCode__c,ResponseMessage__c,ResponseCode__c FROM Account WHERE Id =: account1.Id LIMIT 1];
		System.assertEquals('Success', targetSuccessAccount.ResponseMessage__c);
		System.assertEquals('SC', targetSuccessAccount.ResponseCode__c);
		System.assertEquals('1234', targetSuccessAccount.AccountCode__c);
		Account targetFailAccount = [SELECT Id,AccountCode__c,ResponseMessage__c,ResponseCode__c FROM Account WHERE Id =: account2.Id LIMIT 1];
		System.assertEquals('Duplicated', targetFailAccount.ResponseMessage__c);
		System.assertEquals('DP', targetFailAccount.ResponseCode__c);
		System.assertEquals(null, targetFailAccount.AccountCode__c);
		List<b8log_Integration_Log__c> intLogs = [SELECT Id, Status__c FROM b8log_Integration_Log__c];
        System.assertEquals(1, intLogs.size());
        System.assertEquals(b8log.IntegrationStatus.SUCCESS.name(), intLogs.get(0).Status__c);
	}

	public class FailAndRetryAccountMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<CreateCustomerApiCallout.RequestDataModel>.class);
            List<CreateCustomerApiCallout.RequestDataModel> requestData = ( List<CreateCustomerApiCallout.RequestDataModel>)requestDataObj;
			// START MOCK RESPONSE
            List<CreateCustomerApiCallout.AccountResponse> responseAccountData = new List<CreateCustomerApiCallout.AccountResponse>();
			// SUCCESS RESPONSE
			CreateCustomerApiCallout.AccountResponse accountSuccessResponse = new CreateCustomerApiCallout.AccountResponse();
			accountSuccessResponse.Contacts = new List<CreateCustomerApiCallout.ContactResponse>();
			accountSuccessResponse.SFCustomerId = targetSuccessAccountId;
			accountSuccessResponse.CustomerCode = '0001';
			accountSuccessResponse.ResponseCode = 'SC';
			accountSuccessResponse.Message = 'Success';
			responseAccountData.add(accountSuccessResponse);
			// FAIL RESPONSE
			CreateCustomerApiCallout.AccountResponse accountFailResponse = new CreateCustomerApiCallout.AccountResponse();
			accountFailResponse.Contacts = new List<CreateCustomerApiCallout.ContactResponse>();
			accountFailResponse.SFCustomerId = targetFailAccountId;
			accountFailResponse.ResponseCode = 'SC';
			accountFailResponse.Message = 'Success';
			accountFailResponse.CustomerCode = '0002';
			responseAccountData.add(accountFailResponse);
			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseAccountData));
            res.setStatusCode(200);
            return res;
        }
    }

	@isTest
	static void craeteAccountCalloutTestFailAndRetrySuccess(){
		Test.setMock(HttpCalloutMock.class, new CreateCustomerApiCalloutBatchTest.FailAndRetryAccountMockResp());
		DataMaker dataMaker = DataMaker.getInstance();
		// CREATE ACCOUNT
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account1 = dataMaker.createAccount(recordTypeId, 'BE8');
		Account account2 = dataMaker.createAccount(recordTypeId, 'BE8-Fail');
		account2.ResponseMessage__c = 'Duplicated';
		account2.ResponseCode__c = 'DP';
		insert new List<Account>{account1 , account2};
		targetSuccessAccountId = account1.Id;
		targetFailAccountId = account2.Id;
		Test.startTest();
		// EXECUTE BATCH
		CreateCustomerApiCalloutBatch batch = new CreateCustomerApiCalloutBatch();
		Database.executeBatch(batch, 2000);
		Test.stopTest();
		Account targetSuccessAccount = [SELECT Id,AccountCode__c,ResponseMessage__c,ResponseCode__c FROM Account WHERE Id =: account1.Id LIMIT 1];
		System.assertEquals('Success', targetSuccessAccount.ResponseMessage__c);
		System.assertEquals('SC', targetSuccessAccount.ResponseCode__c);
		System.assertEquals('0001', targetSuccessAccount.AccountCode__c);
		Account targetRetryFailAccount = [SELECT Id,AccountCode__c,ResponseMessage__c,ResponseCode__c FROM Account WHERE Id =: account2.Id LIMIT 1];
		System.assertEquals('Success', targetRetryFailAccount.ResponseMessage__c);
		System.assertEquals('SC', targetRetryFailAccount.ResponseCode__c);
		System.assertEquals('0002', targetRetryFailAccount.AccountCode__c);
		List<b8log_Integration_Log__c> intLogs = [SELECT Id, Status__c FROM b8log_Integration_Log__c];
        System.assertEquals(1, intLogs.size());
        System.assertEquals(b8log.IntegrationStatus.SUCCESS.name(), intLogs.get(0).Status__c);
	}

	public class SuccessAccountAndContactMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<CreateCustomerApiCallout.RequestDataModel>.class);
            List<CreateCustomerApiCallout.RequestDataModel> requestData = ( List<CreateCustomerApiCallout.RequestDataModel>)requestDataObj;
			// START MOCK RESPONSE
            List<CreateCustomerApiCallout.AccountResponse> responseAccountData = new List<CreateCustomerApiCallout.AccountResponse>();
			CreateCustomerApiCallout.AccountResponse accountResponse = new CreateCustomerApiCallout.AccountResponse();
			accountResponse.Contacts = new List<CreateCustomerApiCallout.ContactResponse>();
			accountResponse.SFCustomerId = targetSuccessAccountId;
			accountResponse.CustomerCode = '0001';
			accountResponse.ResponseCode = 'SC';
			accountResponse.Message = 'Success';
			CreateCustomerApiCallout.ContactResponse contactResponse1 = new CreateCustomerApiCallout.ContactResponse();
			contactResponse1.SFContactId = targetSuccessContact1;
			contactResponse1.ResponseCode = 'SCC';
			contactResponse1.Message = 'Success';
			accountResponse.Contacts.add(contactResponse1);
			CreateCustomerApiCallout.ContactResponse contactResponse2 = new CreateCustomerApiCallout.ContactResponse();
			contactResponse2.SFContactId = targetSuccessContact2;
			contactResponse2.ResponseCode = 'SCC';
			contactResponse2.Message = 'Success';
			accountResponse.Contacts.add(contactResponse2);
			responseAccountData.add(accountResponse);
			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseAccountData));
            res.setStatusCode(200);
            return res;
        }
    }

	@isTest
	static void craeteAccountAndContactCalloutTestSuccess(){
		Test.setMock(HttpCalloutMock.class, new CreateCustomerApiCalloutBatchTest.SuccessAccountAndContactMockResp());
		DataMaker dataMaker = DataMaker.getInstance();
		// CREATE ACCOUNT
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'BE8');
		insert account;
		Contact contact1 = dataMaker.createContact(account.Id, 'Nont', 'Tab', 'nont@gmail.com.invalid', '0111111111');
		Contact contact2 = dataMaker.createContact(account.Id, 'Nont2', 'Tab2', 'nont2@gmail.com.invalid', '0111111112');
		insert new List<Contact>{contact1,contact2};
		targetSuccessAccountId = account.Id;
		targetSuccessContact1 = contact1.Id;
		targetSuccessContact2 = contact2.Id;
		Test.startTest();
		// EXECUTE BATCH
		CreateCustomerApiCalloutBatch batch = new CreateCustomerApiCalloutBatch();
		Database.executeBatch(batch, 2000);
		Test.stopTest();
		Account targetAccount = [SELECT Id,AccountCode__c,ResponseMessage__c,ResponseCode__c,LastContactIntegrationStatus__c FROM Account WHERE Id =: account.Id LIMIT 1];
		System.assertEquals('Success', targetAccount.ResponseMessage__c);
		System.assertEquals('SC', targetAccount.ResponseCode__c);
		System.assertEquals('0001', targetAccount.AccountCode__c);
		System.assertEquals('Success', targetAccount.LastContactIntegrationStatus__c);
		Contact targetContact1 = [SELECT Id,ResponseMessage__c,ResponseCode__c,LastCreatedStatusInPojjaman__c FROM Contact WHERE Id =: contact1.Id LIMIT 1];
		System.assertEquals('Success', targetContact1.ResponseMessage__c);
		System.assertEquals('SCC', targetContact1.ResponseCode__c);
		System.assertEquals('Success', targetContact1.LastCreatedStatusInPojjaman__c);
		Contact targetContact2 = [SELECT Id,ResponseMessage__c,ResponseCode__c,LastCreatedStatusInPojjaman__c FROM Contact WHERE Id =: contact2.Id LIMIT 1];
		System.assertEquals('Success', targetContact2.ResponseMessage__c);
		System.assertEquals('SCC', targetContact2.ResponseCode__c);
		System.assertEquals('Success', targetContact2.LastCreatedStatusInPojjaman__c);
		List<b8log_Integration_Log__c> intLogs = [SELECT Id, Status__c FROM b8log_Integration_Log__c];
        System.assertEquals(1, intLogs.size());
        System.assertEquals(b8log.IntegrationStatus.SUCCESS.name(), intLogs.get(0).Status__c);
	}

	public class SystemFailAccountAndContactMockResp implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), List<CreateCustomerApiCallout.RequestDataModel>.class);
			System.debug('** test **: ' + requestDataObj);
            List<CreateCustomerApiCallout.RequestDataModel> requestData = ( List<CreateCustomerApiCallout.RequestDataModel>)requestDataObj;
			// START MOCK RESPONSE
            List<CreateCustomerApiCallout.AccountResponse> responseAccountData = new List<CreateCustomerApiCallout.AccountResponse>();
			// END MOCK RESPONSE
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseAccountData));
            res.setStatusCode(500);
            return res;
        }
    }

	@isTest
	static void craeteAccountAndContactCalloutTestSystemFail(){
		Test.setMock(HttpCalloutMock.class, new CreateCustomerApiCalloutBatchTest.SystemFailAccountAndContactMockResp());
		DataMaker dataMaker = DataMaker.getInstance();
		// CREATE ACCOUNT
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'BE8');
		insert account;
		Contact contact1 = dataMaker.createContact(account.Id, 'Nont', 'Tab', 'nont@gmail.com.invalid', '0111111111');
		Contact contact2 = dataMaker.createContact(account.Id, 'Nont2', 'Tab2', 'nont2@gmail.com.invalid', '0111111112');
		insert new List<Contact>{contact1,contact2};
		targetSuccessAccountId = account.Id;
		targetSuccessContact1 = contact1.Id;
		targetSuccessContact2 = contact2.Id;
		Test.startTest();
		// EXECUTE BATCH
		CreateCustomerApiCalloutBatch batch = new CreateCustomerApiCalloutBatch();
		Database.executeBatch(batch, 2000);
		Test.stopTest();
		Account targetAccount = [SELECT Id,AccountCode__c,ResponseMessage__c,ResponseCode__c,LastContactIntegrationStatus__c FROM Account WHERE Id =: account.Id LIMIT 1];
		System.assertEquals('ERR', targetAccount.ResponseCode__c);
		System.assertEquals('Fail', targetAccount.LastContactIntegrationStatus__c);
		Contact targetContact1 = [SELECT Id,ResponseMessage__c,ResponseCode__c,LastCreatedStatusInPojjaman__c FROM Contact WHERE Id =: contact1.Id LIMIT 1];
		System.assertEquals('ERR', targetContact1.ResponseCode__c);
		Contact targetContact2 = [SELECT Id,ResponseMessage__c,ResponseCode__c,LastCreatedStatusInPojjaman__c FROM Contact WHERE Id =: contact2.Id LIMIT 1];
		System.assertEquals('ERR', targetContact2.ResponseCode__c);
		List<b8log_Integration_Log__c> intLogs = [SELECT Id, Status__c FROM b8log_Integration_Log__c];
        System.assertEquals(1, intLogs.size());
        // System.assertEquals(b8log.IntegrationStatus.SUCCESS.name(), intLogs.get(0).Status__c);
	}


}