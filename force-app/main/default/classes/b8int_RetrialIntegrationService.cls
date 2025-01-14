public without sharing class b8int_RetrialIntegrationService {
    @TestVisible private final static String SCHEDULER_NAME_PREFIX = 'Auto Retry Integration-';
    @TestVisible private final static String CRON_JOB_NAME = 'b8int_RetrialIntegration';
    @TestVisible private final static Integer NEXT_RETRY_IN_MINUTE = b8int_Settings__c.getOrgDefaults().Next_Retry_In_Minute__c != null
                                                                        ? Integer.valueOf(b8int_Settings__c.getOrgDefaults().Next_Retry_In_Minute__c) 
                                                                        : 3;
    public final static Integer MAX_RETRY = b8int_Settings__c.getOrgDefaults().Max_Retrial_Count__c != null 
                                                ? Integer.valueOf(b8int_Settings__c.getOrgDefaults().Max_Retrial_Count__c) 
                                                : 3;
    

    public static DateTime getNextRetryDateTime(Integer numberOfRetry) {
        if(numberOfRetry == null) {
            numberOfRetry = 0;
        }

        if(numberOfRetry > MAX_RETRY) {
            return null;
        }
        
        numberOfRetry = numberOfRetry + 1;
        Integer addMins = Integer.valueOf(numberOfRetry*NEXT_RETRY_IN_MINUTE);
        return System.now().addMinutes(addMins);
    }

    public static void retryIntegrationLog(Id intLogId) {
        List<b8log_Integration_Log__c> intLogs = [SELECT Id, Interface_Name__c, Request__c, Request_Store_Type__c, Number_Of_Retry__c, Reference_Id__c 
                                                    FROM b8log_Integration_Log__c 
                                                    WHERE
                                                        Status__c = :b8log.IntegrationStatus.REQUIRED_RETRY.name()
                                                        AND Number_Of_Retry__c < :b8int_RetrialIntegrationService.MAX_RETRY
                                                        AND Id = :intLogId];
        if(intLogs.isEmpty()) {
            return;
        }
        b8int_RetrialIntegrationLogModel retryLogModel = new b8int_RetrialIntegrationLogModel(intLogs.get(0));
        Map<Id, Map<String, Attachment>> attachmentMapById = b8log_IntegrationLogAttachment.getRequestAttachmentMap(new Set<Id>{intLogs.get(0).Id}); 
        retryLogModel.setAttachmentPayload(attachmentMapById);
        b8int_BaseHttpCallout callout = retryLogModel.getCalloutInstance(null);
        callout.setCalloutType(b8int_BaseHttpCallout.HttpCalloutType.REALTIME);
        callout.execute();
    }

    public static void setNextRetrialIntSchedule() {
        DateTime now  = DateTime.now();
        DateTime nextRunTime = now.addMinutes(NEXT_RETRY_IN_MINUTE);
        Integer year = nextRunTime.year() > 2500 ? nextRunTime.year() - 543 : nextRunTime.year();
        String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + year;
        String schedulerName = SCHEDULER_NAME_PREFIX + toReadable(nextRunTime, '-', ' ', ':');

        if(!Test.isRunningTest() || !b8int_Mocker_Test.alreadySetRetrialSchd) {
            System.schedule(schedulerName, cronString, new b8int_RetrialIntegrationSchd());
            b8int_Mocker_Test.alreadySetRetrialSchd = true;
        }
    }

    public static Id executeNextRetrialIntModel() {
        List<b8log_Integration_Log__c> intLogs = [SELECT Id, Interface_Name__c, Request__c, Request_Store_Type__c, Number_Of_Retry__c, Reference_Id__c 
                                                    FROM b8log_Integration_Log__c 
                                                    WHERE
                                                        Status__c = :b8log.IntegrationStatus.REQUIRED_RETRY.name()
                                                        AND Number_Of_Retry__c < :b8int_RetrialIntegrationService.MAX_RETRY
                                                        AND Next_Retry_DateTime__c < :System.now()
                                                        ORDER BY Next_Retry_DateTime__c ASC
                                                        LIMIT 1];
        if(intLogs.isEmpty()) {
            return null;
        }
        b8int_RetrialIntegrationLogModel retryLogModel = new b8int_RetrialIntegrationLogModel(intLogs.get(0));
        Map<Id, Map<String, Attachment>> attachmentMapById = b8log_IntegrationLogAttachment.getRequestAttachmentMap(new Set<Id>{intLogs.get(0).Id}); 
        retryLogModel.setAttachmentPayload(attachmentMapById);
        b8int_BaseHttpCallout callout = retryLogModel.getCalloutInstance(null);
        be8_QueueableService.getInstance().addToQueue(callout);
        Id jobId;
        try {
            jobId = be8_QueueableService.getInstance().executeQueue();
        } catch(AsyncException e) {
            return null;
        }
        return jobId;
    }

    public static void deleteOldSchedule() {
        try {
            String nameCondition = SCHEDULER_NAME_PREFIX + '%';
            DateTime previousFireTimeCondition = System.now().addHours(-1);
            for(CronTrigger eachCronTrigger : [SELECT Id, CronJobDetail.Name, NextFireTime, PreviousFireTime, State, TimesTriggered 
                                                FROM CronTrigger 
                                                WHERE State = 'DELETED'
                                                    AND NextFireTime  = null 
                                                    AND CronJobDetail.Name LIKE :nameCondition 
                                                    AND PreviousFireTime < :previousFireTimeCondition 
                                                LIMIT 20]) {
                System.abortJob(eachCronTrigger.Id);
            }
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, e);
        }   
    }
    
    @TestVisible private static String toReadable(DateTime sfdcDateTime, String dateSeparator, String datetimeSeparator, String timeSeparator) {
        if(sfdcDateTime == null) {
            return '';
        }
        Integer year = sfdcDateTime.year() > 2500 ? sfdcDateTime.year() - 543 : sfdcDateTime.year();
        String month = ('0' + String.valueOf(sfdcDateTime.month())).right(2);
        String day = ('0' + String.valueOf(sfdcDateTime.day())).right(2);
        String hh = ('0' + String.valueOf(sfdcDateTime.hour())).right(2);
        String mm = ('0' + String.valueOf(sfdcDateTime.minute())).right(2);
        String ss = ('0' + String.valueOf(sfdcDateTime.second())).right(2);

        return year + dateSeparator + month + dateSeparator + day + datetimeSeparator + hh + timeSeparator + mm + timeSeparator + ss;
    }
}