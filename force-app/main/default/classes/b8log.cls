public without sharing class b8log {
    public enum AppLogType {ERROR, WARN, INFO, DEBUG}
    public enum PayloadStoreType {FIELD, FILE}
    public enum IntegrationStatus {SUCCESS, FAILED, REQUIRED_RETRY}
    public enum InsertLogType {QUEUE, REALTIME, DISABLE}

    public static AppLogType getAppLogLevel() {
        AppLogType currentAppLogType;
        b8log_Settings__c setting = b8log_Settings__c.getOrgDefaults();
        if(setting != null && String.isNotBlank(setting.Application_Log_Level__c)) {
            try {
                currentAppLogType = b8log.AppLogType.valueOf(setting.Application_Log_Level__c);
            } catch(NoSuchElementException e) {
                System.debug(LoggingLevel.WARN, 'b8log.getAppLogLevel: Invalid Application_Log_Level__c:' + setting.Application_Log_Level__c);
            }
        }
        if(currentAppLogType == null) {
            currentAppLogType = AppLogType.INFO;
        }
        return currentAppLogType;
    }
}