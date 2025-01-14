public without sharing class b8log_UpsertLogService {
    public static void immidiateInsertLogs(List<b8log_IntegrationLogModel> intLogModelsForInsert,
                                    List<b8log_IntegrationLogModel> intLogModelsForUpdate,
                                    List<b8log_ApplicationLogModel> appLogModelsForInsert) {        

        List<b8log_Integration_Log__c> intLogsForInsert = b8log_UpsertLogService.insertIntLogModel(intLogModelsForInsert);
        List<b8log_Integration_Log__c> intLogsForUpdate = b8log_UpsertLogService.updateIntLogModel(intLogModelsForUpdate);

        Map<String, Id> referenceIdMapByIntLogId = new Map<String, Id>();
        for(b8log_Integration_Log__c intLog : intLogsForInsert) {
            if(String.isBlank(intLog.Reference_Id__c)) {
                continue;
            }
            referenceIdMapByIntLogId.put(intLog.Reference_Id__c, intLog.Id);
        }
        for(b8log_Integration_Log__c intLog : intLogsForUpdate) {
            if(String.isBlank(intLog.Reference_Id__c)) {
                continue;
            }
            referenceIdMapByIntLogId.put(intLog.Reference_Id__c, intLog.Id);
        }

        b8log_UpsertLogService.insertAttachments(intLogModelsForInsert, intLogModelsForUpdate);
        b8log_UpsertLogService.insertAppLogModel(appLogModelsForInsert, referenceIdMapByIntLogId);
    }

    public static List<b8log_Integration_Log__c> insertIntLogModel(List<b8log_IntegrationLogModel> intLogModelsForInsert) {
        List<b8log_Integration_Log__c> intLogsForInsert = new List<b8log_Integration_Log__c>();
        for(b8log_IntegrationLogModel imModel :  intLogModelsForInsert) {
            intLogsForInsert.add(imModel.get());
        }
        if(!intLogsForInsert.isEmpty()) {
            insert intLogsForInsert;
        }
        return intLogsForInsert;
    }

    public static List<b8log_Integration_Log__c> updateIntLogModel(List<b8log_IntegrationLogModel> intLogModelsForUpsert) {
        List<b8log_Integration_Log__c> intLogsForUpdate = new List<b8log_Integration_Log__c>();
        for(b8log_IntegrationLogModel imModel :  intLogModelsForUpsert) {
            intLogsForUpdate.add(imModel.get());
        }
        if(!intLogsForUpdate.isEmpty()) {
            update intLogsForUpdate;
        }
        return intLogsForUpdate;
    }

    public static List<Attachment> insertAttachments(List<b8log_IntegrationLogModel> intLogModelsForInsert, List<b8log_IntegrationLogModel> intLogModelsForUpdate) {
        List<Attachment> logAttachments = new List<Attachment>();
        for(b8log_IntegrationLogModel imModel :  intLogModelsForInsert) {
            logAttachments.addAll(imModel.updateAttachment());
        }

        for(b8log_IntegrationLogModel imModel :  intLogModelsForUpdate) {
            logAttachments.addAll(imModel.updateAttachment());
        }
        if(!logAttachments.isEmpty()) {
            insert logAttachments;
        }
        return logAttachments;
    }

    public static void insertAppLogModel(List<b8log_ApplicationLogModel> appLogModelsForInsert, Map<String, Id> referenceIdMapByIntLogId) {
        List<b8log_Application_Log__c> appLogsForInsert = new List<b8log_Application_Log__c>();
        for(b8log_ApplicationLogModel appLogModel : appLogModelsForInsert) {
            appLogsForInsert.add(appLogModel.get());
        }

        for(b8log_Application_Log__c appLog : appLogsForInsert) {
            if(String.isBlank(appLog.Reference_Id__c)) {
                continue;
            }   
            if(referenceIdMapByIntLogId.containsKey(appLog.Reference_Id__c)) {
                appLog.Integration_Log__c = referenceIdMapByIntLogId.get(appLog.Reference_Id__c);
            }
        }

        if(!appLogsForInsert.isEmpty()) {
            insert appLogsForInsert;
        }
    }
}