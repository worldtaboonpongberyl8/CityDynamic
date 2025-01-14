public without sharing virtual class b8int_BaseHttpCalloutLogger {
    @TestVisible private b8int_RetrialIntegrationLogModel retryLogModel;
    @TestVisible protected b8log_IntegrationLogModel intLogModel;
    @TestVisible protected b8log_ApplicationLogModel appLogModel;

    @TestVisible protected Boolean isRequireRetry = false;
    @TestVisible protected Boolean isRetrial = false;

    public b8int_BaseHttpCalloutLogger(String className, String subServiceName) {
        this.initAppLogModel(className, subServiceName);
        this.initIntegrationLogModel(className, subServiceName);
    }

    public b8log_ApplicationLogModel getAppLogModel()           { return this.appLogModel; }
    public Boolean isRetrial()                                  { return this.isRetrial; }
    public b8int_RetrialIntegrationLogModel getRetryLogModel()  { return this.retryLogModel; }
    public b8log_IntegrationLogModel getIntLogModel() { 
        if(isRetrial) { return this.retryLogModel; }
        return this.intLogModel; 
    }

    public b8int_BaseHttpCalloutLogger setRetryLogModel(b8int_RetrialIntegrationLogModel retryLogModel) {
        this.isRequireRetry = true;
        this.retryLogModel = retryLogModel;
        this.isRetrial = true;
        return this;
    }

    public b8int_BaseHttpCalloutLogger setIsRequireRetry(Boolean isRequireRetry) {
        this.isRequireRetry = isRequireRetry;
        return this;
    }

    public b8int_BaseHttpCalloutLogger insertAlls(b8log.InsertLogType insertLogType) {
        if(!this.isRetrial) {
            b8log_Logger.addIntLog(this.intLogModel);
        } else {
            b8log_Logger.addUpdateIntLog(this.retryLogModel);
        }
        b8log_Logger.addAppLog(this.appLogModel);
        b8log_Logger.insertAlls(insertLogType);
        return this;
    }
    
    @TestVisible protected virtual void initIntegrationLogModel(String className, String subServiceName) {
        this.intLogModel = new b8log_IntegrationLogModel();
        this.intLogModel.setName(className, subServiceName);
    }

    @TestVisible protected virtual void initAppLogModel(String className, String subServiceName) {
        this.appLogModel = new b8log_ApplicationLogModel(className, subServiceName, b8log.AppLogType.INFO);
        this.appLogModel.setStartEndDateTime(System.now(), null);
    }

    public virtual void updateLogAfterPrepareRequestData(b8int_BaseHttpRequest requestModel, String referenceId, String referenceInfo) {
        this.intLogModel.setReference(referenceId, referenceInfo);
        this.intLogModel.setRequest(requestModel.getRequestBodyAsString());
        this.appLogModel.setReference(referenceId, referenceInfo);
    }

    public virtual void updateLogByResponse(b8int_BaseHttpResponse responseModel) {
        b8log_IntegrationLogModel logModel = !this.isRetrial ? this.intLogModel : this.retryLogModel;
        logModel.setResponse(responseModel.getStatusCode(), responseModel.getBodyAsString());
    }

    @TestVisible public virtual void updateLogForSuccessIntegration(Exception e) {
        if(e == null) {
            if(!this.isRetrial) {
                this.intLogModel.setStatus(b8log.IntegrationStatus.SUCCESS);
            } else {
                this.retryLogModel.setStatus(b8log.IntegrationStatus.SUCCESS);
            }
        } else {
            this.appLogModel.setLogType(b8log.AppLogType.ERROR);
            this.appLogModel.setException(e);
        }
    }

    @TestVisible public virtual void updateLogForFailedIntegration(b8int_BaseHttpResponse responseModel) {
        b8log_IntegrationLogModel logModel = !this.isRetrial ? this.intLogModel : this.retryLogModel;
        logModel.setStatus(b8log.IntegrationStatus.FAILED);
        
        if(this.isRequireRetry) {
            DateTime nextRetryDateTime = b8int_RetrialIntegrationService.getNextRetryDateTime(logModel.getNumberOfRetry());
            if(nextRetryDateTime != null) {
                logModel.setNextRetryDateTime(nextRetryDateTime);
                logModel.setStatus(b8log.IntegrationStatus.REQUIRED_RETRY);
            }
        }
        this.appLogModel.setLogType(b8log.AppLogType.ERROR);
        this.appLogModel.setDescription(responseModel.getDescription());
    }
    
    @TestVisible public virtual b8log_ApplicationLogModel updateLogForSecondFailedProcess(Exception e) {
        b8log_ApplicationLogModel secondAppLogModel = (b8log_ApplicationLogModel)JSON.deserialize(JSON.serialize(this.appLogModel), b8log_ApplicationLogModel.class);
        secondAppLogModel.setLogType(b8log.AppLogType.ERROR);
        secondAppLogModel.setException(e);
        secondAppLogModel.setStartEndDateTime(null, System.now());
        b8log_Logger.addAppLog(secondAppLogModel);
        return secondAppLogModel;
    }

    public Object getRequestBodyOfRetryLog(b8int_BaseHttpRequest.ContentType contentType, Type targetClass) {
        if(this.retryLogModel == null) {
            return null;
        }
        String requestString = this.retryLogModel.getRequestBody();
        if(String.isBlank(requestString)) {
            return '';
        }

        if(targetClass == null) {
            return requestString;
        }

        if(contentType == b8int_BaseHttpRequest.ContentType.JSON) {
            return JSON.deserialize(requestString, targetClass);
        }
        return null;
    }
}