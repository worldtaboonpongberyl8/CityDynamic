public without sharing class b8log_Logger {
    public static b8log_Logger instance = null;

    public List<b8log_IntegrationLogModel> intLogModelsForInsert = new List<b8log_IntegrationLogModel>();
    public List<b8log_IntegrationLogModel> intLogModelsForUpdate = new List<b8log_IntegrationLogModel>();
    public List<b8log_ApplicationLogModel> appLogModelsForInsert = new List<b8log_ApplicationLogModel>();
    public b8log.AppLogType currentAppLogType = b8log.getAppLogLevel(); 

    public Boolean validateAppLogLevel(b8log.AppLogType targetLogType) {
        return targetLogType.ordinal() <= currentAppLogType.ordinal();
    }

    public static b8log_ApplicationLogModel addAppLog(b8log_ApplicationLogModel appLogModel) {
        return b8log_Logger.getInstance().addAppLogFromInstance(appLogModel);
    }

    public static b8log_IntegrationLogModel addIntLog(b8log_IntegrationLogModel intLogModel) {
        return b8log_Logger.getInstance().addIntLogModelFromInstance(intLogModel);
    }

    public static b8log_IntegrationLogModel addUpdateIntLog(b8log_IntegrationLogModel intLogModel) {
        return b8log_logger.getInstance().addUpdateIntLogModelFromInstance(intLogModel);
    }

    public static b8log_ApplicationLogModel addErrorAppLog(String appName, String appSubName, String referenceId, Exception e) {
        b8log.AppLogType targetLogType = b8log.AppLogType.ERROR;
        DateTime startDateTime = System.now();
        DateTime endDateTime = System.now();
        b8log_ApplicationLogModel log = new b8log_ApplicationLogModel(appName, appSubName, targetLogType);
        log.setReference(referenceId, null);
        log.setException(e);
        log.setStartEndDateTime(startDateTime, endDateTime);
        return b8log_Logger.getInstance().addAppLogFromInstance(log);
    }

    public static b8log_ApplicationLogModel addAppLog(String appName, String appSubName, String referenceId, b8log.AppLogType logType) {
        b8log.AppLogType targetLogType = logType;
        DateTime startDateTime = System.now();
        DateTime endDateTime = System.now();
        b8log_ApplicationLogModel log = new b8log_ApplicationLogModel(appName, appSubName, targetLogType);
        log.setReference(referenceId, null);
        log.setStartEndDateTime(startDateTime, endDateTime);
        return b8log_Logger.getInstance().addAppLogFromInstance(log);
    }

    public static b8log_ApplicationLogModel addInfoAppLog(String appName, String appSubName, String referenceId) {
        return b8log_Logger.addAppLog(appName, appSubName, referenceId, b8log.AppLogType.INFO);
    }

    public static void insertAlls(b8log.InsertLogType insertType) {
        b8log_Logger.getInstance().insertAllsFromInstance(insertType);
    }

    public b8log_IntegrationLogModel addIntLogModelFromInstance(b8log_IntegrationLogModel intLogModel) {
        this.intLogModelsForInsert.add(intLogModel);
        return intLogModel;
    }

    public b8log_IntegrationLogModel addUpdateIntLogModelFromInstance(b8log_IntegrationLogModel intLogModel) {
        this.intLogModelsForUpdate.add(intLogModel);
        return intLogModel;
    }

    public b8log_ApplicationLogModel addAppLogFromInstance(b8log_ApplicationLogModel appLogModel) {
        if(!validateAppLogLevel(appLogModel.getType())) {
            return null;
        }
        this.appLogModelsForInsert.add(appLogModel);
        return appLogModel;
    }

    public void insertAllsFromInstance(b8log.InsertLogType insertType) { 
        if(insertType == b8log.InsertLogType.DISABLE) {
            return;
        } else if(insertType == b8log.InsertLogType.REALTIME) {
            this.immidiateInsertLogs();
        } else if(insertType == b8log.InsertLogType.QUEUE) {
            Boolean canSubmitQueueableJob = Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() && !System.isQueueable();
            if(!canSubmitQueueableJob) { // if cannot insert in real-time, else submit queueable job
                this.immidiateInsertLogs();
                return;
            }

            b8log_UpsertLogQueueable queueableLogger = this.initQueuebleUpsertAllLogs();
            if(queueableLogger != null) {
                System.enqueueJob(queueableLogger);
            }
        }   
    }

    public void immidiateInsertLogs() {
        b8log_UpsertLogService.immidiateInsertLogs(this.intLogModelsForInsert, this.intLogModelsForUpdate, this.appLogModelsForInsert);
        this.intLogModelsForInsert.clear();
        this.intLogModelsForUpdate.clear();
        this.appLogModelsForInsert.clear();
    }
    
    @TestVisible private b8log_UpsertLogQueueable initQueuebleUpsertAllLogs() {
        if(this.intLogModelsForInsert.isEmpty() && this.intLogModelsForUpdate.isEmpty() && this.appLogModelsForInsert.isEmpty()) {
            return null;
        }
        b8log_UpsertLogQueueable upsertLogQueueable = new b8log_UpsertLogQueueable(this.intLogModelsForInsert, this.intLogModelsForUpdate, this.appLogModelsForInsert);
        return upsertLogQueueable;
    }

    public static b8log_Logger getInstance() {
        if(instance == null) {
            instance = new b8log_Logger();
        }
        return instance;
    }

    public static b8log_Logger newInstance() {
        return new b8log_Logger();
    }
}