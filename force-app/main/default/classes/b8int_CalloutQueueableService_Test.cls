@isTest
public class b8int_CalloutQueueableService_Test {
    
    @isTest static void test() {
        Test.setMock(HttpCalloutMock.class, new b8int_Mocker_Test.MockCalloutResp());
        b8int_Mocker_Test.MockCallout callout1 = new b8int_Mocker_Test.MockCallout();
        b8int_Mocker_Test.MockCallout callout2 = new b8int_Mocker_Test.MockCallout();
        b8int_Mocker_Test.MockCallout callout3 = new b8int_Mocker_Test.MockCallout();

        Test.startTest();
        b8int_CalloutQueueableService queueService = b8int_CalloutQueueableService.getInstance();
        queueService.addToQueue(callout1);
        queueService.addToQueue(callout2);
        queueService.addToQueues(new List<b8int_BaseHttpCallout>{callout3});
        queueService.executeQueue();
        Test.stopTest();
    }
}