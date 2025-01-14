public without sharing class b8log_ApplicationLogModel {

    @TestVisible private b8log_Application_Log__c appLog;

    public static final Integer MAX_DESC_LENGTH = Integer.valueOf(b8log_Application_Log__c.Description__c.getDescribe().getLength());
    public static final Integer MAX_STACKTRACE_LENGTH = Integer.valueOf(b8log_Application_Log__c.Stack_Trace__c.getDescribe().getLength());
    public static final Integer MAX_REFERENCEINFO_LENGTH = Integer.valueOf(b8log_Application_Log__c.Reference_Info__c.getDescribe().getLength());
    public static final Integer MAX_REFERENCEID_LENGTH = Integer.valueOf(b8log_Application_Log__c.Reference_Id__c.getDescribe().getLength());
    
    public b8log_ApplicationLogModel(String appName, String subName, b8log.AppLogType appLogType) {
        appLog = new b8log_Application_Log__c(
            Application_Name__c = appName,
            Application_Sub_Name__c = subName,
            Start_DateTime__c = System.now(),
            Type__c = appLogType.name()
        );
    }

    public b8log_Application_Log__c get()   { return this.appLog; }
    public b8log.AppLogType getType()       { return b8log.AppLogType.valueOf(this.appLog.Type__c); }

    public b8log_ApplicationLogModel setLogType(b8log.AppLogType newLogType) {
        this.appLog.Type__c = newLogType.name();
        return this;
    }

    public b8log_ApplicationLogModel setDescription(String description) {
        if(String.isNotBlank(description)) {
            this.appLog.Description__c = description.left(MAX_DESC_LENGTH);
        }
        return this;
    }

    public b8log_ApplicationLogModel setStartEndDateTime(DateTime startDateTime, DateTime endDateTime) {
        if(startDateTime != null) {
            appLog.Start_DateTime__c = startDateTime;
        }

        if(endDateTime != null) {
            appLog.End_DateTime__c = endDateTime;
        }
        return this;
    }

    public b8log_ApplicationLogModel setReference(String referenceId, String referenceInfo) {
        if(String.isNotBlank(referenceId)) {
            appLog.Reference_Id__c = referenceId.left(MAX_REFERENCEID_LENGTH);
        } else {
            appLog.Reference_Id__c = referenceId;
        }
        
        if(String.isNotBlank(referenceInfo)) {
            appLog.Reference_Info__c = referenceInfo.left(MAX_REFERENCEINFO_LENGTH);
        } else {
            appLog.Reference_Info__c = referenceInfo;
        }
        return this;
    }

    public b8log_ApplicationLogModel setException(Exception e) {
        if(e != null) {
            appLog.Type__c = b8log.AppLogType.ERROR.name();
            appLog.Stack_Trace__c = e.getStackTraceString().left(MAX_STACKTRACE_LENGTH);
            this.setDescription(e.getMessage());
        }
        return this;
    }
}