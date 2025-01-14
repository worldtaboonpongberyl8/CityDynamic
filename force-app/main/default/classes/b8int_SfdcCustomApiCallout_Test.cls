@isTest
public class b8int_SfdcCustomApiCallout_Test {

    public class b8int_SfdcCustomApiCalloutMockResp implements HttpCalloutMock {
    
        public HTTPResponse respond(HTTPRequest req) {
            Object requestDataObj = JSON.deserialize(req.getBody(), b8int_SfdcCustomApiCallout.RequestDataModel.class);
            b8int_SfdcCustomApiCallout.RequestDataModel requestData = (b8int_SfdcCustomApiCallout.RequestDataModel)requestDataObj;
            b8int_SfdcCustomApiCallout.ResponseDataModel responseData = new b8int_SfdcCustomApiCallout.ResponseDataModel();
            responseData.isSuccess = requestData.expectedSuccessStatus;
    
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(json.serialize(responseData));
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest static void test_success() {
        Test.setMock(HttpCalloutMock.class, new b8int_SfdcCustomApiCallout_Test.b8int_SfdcCustomApiCalloutMockResp());
        b8int_SfdcCustomApiCallout callout = new b8int_SfdcCustomApiCallout();
        callout.expectedSuccessStatus = true;

        Test.startTest();
        callout.execute();
        Test.stopTest();

        List<b8log_Integration_Log__c> intLogs = [SELECT Id, Status__c FROM b8log_Integration_Log__c];
        System.assertEquals(1, intLogs.size());
        System.assertEquals(b8log.IntegrationStatus.SUCCESS.name(), intLogs.get(0).Status__c);

        List<b8log_Application_Log__c> appLogs = [SELECT Id, Type__c FROM b8log_Application_Log__c];
        System.assertEquals(1, appLogs.size());
        System.assertEquals(b8log.AppLogType.INFO.name(), appLogs.get(0).Type__c);
    }

    @isTest static void test_failed() {
        Test.setMock(HttpCalloutMock.class, new b8int_SfdcCustomApiCallout_Test.b8int_SfdcCustomApiCalloutMockResp());
        b8int_SfdcCustomApiCallout callout = new b8int_SfdcCustomApiCallout();
        callout.expectedSuccessStatus = false;

        Test.startTest();
        callout.execute();
        Test.stopTest();

        List<b8log_Integration_Log__c> intLogs = [SELECT Id, Status__c FROM b8log_Integration_Log__c];
        System.assertEquals(1, intLogs.size());
        System.assertEquals(b8log.IntegrationStatus.REQUIRED_RETRY.name(), intLogs.get(0).Status__c);

        List<b8log_Application_Log__c> appLogs = [SELECT Id, Type__c FROM b8log_Application_Log__c];
        System.assertEquals(1, appLogs.size());
        System.assertEquals(b8log.AppLogType.ERROR.name(), appLogs.get(0).Type__c);
    }
}