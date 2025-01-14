@isTest
public with sharing class PojjamanIntegrationSchedulerTest {
    @isTest
	static void executeTest(){
        PojjamanIntegrationScheduler scheduler = PojjamanIntegrationScheduler.getInstance();
        Test.startTest();
        scheduler.runSchedule();
        Test.stopTest();
        // CronTrigger ct = [SELECT Id, State, CronExpression FROM CronTrigger WHERE Id = :jobId];
        // System.assertEquals('WAITING', ct.State, 'The scheduled job should be in WAITING state.');
	}
}