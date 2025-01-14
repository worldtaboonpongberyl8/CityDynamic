@isTest
public class b8int_GoogleChartAPIHttpCallout_Test {
    
    public class b8int_GoogleChartAPIHttpCalloutMockResp implements HttpCalloutMock {
    
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('success');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest static void test_success() {
        Test.setMock(HttpCalloutMock.class, new b8int_GoogleChartAPIHttpCalloutMockResp());
        b8int_GoogleChartAPIHttpCallout callout = new b8int_GoogleChartAPIHttpCallout();
        callout.setUrlForQRCodeByRecordId('0012w00001LcuokAAB');

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
}