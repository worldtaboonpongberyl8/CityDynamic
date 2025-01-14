@isTest
public class b8int_RetrialIntegrationService_Test {
    
    @isTest static void test_retryIntegrationLog() {
        b8log_Integration_Log__c mockIntLog = new b8log_Integration_Log__c(
            Interface_Name__c = 'b8int_SfdcCustomApiCallout',
            Request__c = '{"expectedSuccessStatus":true,"expectedStatusCode":"200","dataList":["String1","String2"],"data":"data"}',
            Request_Store_Type__c = b8log.PayloadStoreType.Field.name(),
            Endpoint__c = 'callout:Salesforce/services/apexrest/mock_rest_resource',
            Request_Data_Model_Class__c = 'b8int_SfdcCustomApiCallout.RequestDataModel',
            Status__c = b8log.IntegrationStatus.REQUIRED_RETRY.name(),
            Number_Of_Retry__c = 0
        );
        insert mockIntLog;

        Test.setMock(HttpCalloutMock.class, new b8int_SfdcCustomApiCallout_Test.b8int_SfdcCustomApiCalloutMockResp());

        Test.startTest();
        b8int_RetrialIntegrationService.retryIntegrationLog(mockIntLog.Id);
        Test.stopTest();

        List<b8log_Integration_Log__c> intLogs = [SELECT Id, Status__c FROM b8log_Integration_Log__c];
        System.assertEquals(1, intLogs.size());
        System.assertEquals(b8log.IntegrationStatus.SUCCESS.name(), intLogs.get(0).Status__c);

        List<b8log_Application_Log__c> appLogs = [SELECT Id, Type__c FROM b8log_Application_Log__c];
        System.assertEquals(1, appLogs.size());
        System.assertEquals(b8log.AppLogType.INFO.name(), appLogs.get(0).Type__c);

        System.assertEquals(0, Limits.getQueueableJobs());
    }

    @isTest static void test_setNextRetrialIntSchedule() {
        Test.startTest();
        b8int_RetrialIntegrationService.setNextRetrialIntSchedule();
        Test.stopTest();
    }

    @isTest static void test_deleteOldSchedule() {
        Test.startTest();
        b8int_RetrialIntegrationService.deleteOldSchedule();
        Test.stopTest();
    }

    @isTest static void test_executeNextRetrialIntModel() {
        b8log_Integration_Log__c mockIntLog = new b8log_Integration_Log__c(
            Interface_Name__c = 'b8int_SfdcCustomApiCallout',
            Request__c = '{"expectedSuccessStatus":true,"expectedStatusCode":"200","dataList":["String1","String2"],"data":"data"}',
            Request_Store_Type__c = b8log.PayloadStoreType.Field.name(),
            Endpoint__c = 'callout:Salesforce/services/apexrest/mock_rest_resource',
            Request_Data_Model_Class__c = 'b8int_SfdcCustomApiCallout.RequestDataModel',
            Status__c = b8log.IntegrationStatus.REQUIRED_RETRY.name(),
            Number_Of_Retry__c = 0,
            Next_Retry_DateTime__c = System.now().addMonths(-1)
        );
        insert mockIntLog;

        Test.setMock(HttpCalloutMock.class, new b8int_SfdcCustomApiCallout_Test.b8int_SfdcCustomApiCalloutMockResp());

        Test.startTest();
        b8int_RetrialIntegrationService.executeNextRetrialIntModel();
        Test.stopTest();

        List<b8log_Integration_Log__c> intLogs = [SELECT Id, Status__c FROM b8log_Integration_Log__c];
        System.assertEquals(1, intLogs.size());
        System.assertEquals(b8log.IntegrationStatus.SUCCESS.name(), intLogs.get(0).Status__c);

        List<b8log_Application_Log__c> appLogs = [SELECT Id, Type__c FROM b8log_Application_Log__c];
        System.assertEquals(1, appLogs.size());
        System.assertEquals(b8log.AppLogType.INFO.name(), appLogs.get(0).Type__c);
    }

    @isTest static void test_getNextRetryDateTime() {
        DateTime expectedMin = System.now().addMinutes(9);
        DateTime actual =  b8int_RetrialIntegrationService.getNextRetryDateTime(2);
        DateTime expectedMax = System.now().addMinutes(9);
        System.assert(actual >= expectedMin);
        System.assert(actual <= expectedMax);
        
        actual =  b8int_RetrialIntegrationService.getNextRetryDateTime(4);
        System.assertEquals(null, actual);
    }
}