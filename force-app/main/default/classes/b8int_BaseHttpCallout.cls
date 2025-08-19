public abstract without sharing class b8int_BaseHttpCallout extends be8_Queueable implements Queueable, Database.AllowsCallouts {
    public enum HttpCalloutType {QUEUE, REALTIME}

    @TestVisible private b8int_BaseHttpRequest requestModel = new b8int_BaseHttpRequest();
    @TestVisible private b8int_BaseHttpResponse responseModel;
    @TestVisible private b8int_BaseHttpClient clientModel;

    @TestVisible private HttpCalloutType calloutType = HttpCalloutType.REALTIME;
    @TestVisible private b8log.InsertLogType insertLogType = b8log.InsertLogType.REALTIME;

    @TestVisible private b8int_BaseHttpCalloutLogger logger;

    @TestVisible protected String referenceId;
    @TestVisible protected String referenceInfo;

    @TestVisible protected Type requestDataModelClass;
    @TestVisible protected Type responseDataModelClass;

    public abstract Object buildRequestDataModel();
    public abstract Boolean processSuccessResponse();
    public abstract Boolean processFailedResponse();

    public b8int_BaseHttpCallout(String subServiceName) {
        String className = String.valueOf(this).split(':')[0];
        this.logger = new b8int_BaseHttpCalloutLogger(className, subServiceName);
    }

    public override void execute(QueueableContext context) {
        this.execute();
        this.executeNextQueueables();
    }

    @TestVisible
    protected override Id executeNextQueueables() {
        if (this.hasNextQueuables()) {
            return super.executeNextQueueables();
        }

        if (this.isRetrial()) {
            Id jobId = b8int_RetrialIntegrationService.executeNextRetrialIntModel();
            if (jobId == null) {
                b8int_RetrialIntegrationService.setNextRetrialIntSchedule();
            }
            return jobId;
        }

        return null;
    }

    public Id execute() {
        Boolean immediateExecute = System.isQueueable() || this.calloutType == HttpCalloutType.REALTIME;
        if (immediateExecute) {
            this.prepareRequestData();
            this.sendRequest();
            this.handleResponse();
        } else if (this.calloutType == HttpCalloutType.QUEUE) {
            System.enqueueJob(this);
        }
        return null;
    }

    @TestVisible private void prepareRequestData() {
        if(this.isRetrial()) {
            this.requestModel.setBody(this.logger.getRequestBodyOfRetryLog(this.requestModel.getContentType(), this.requestDataModelClass));
            return;
        }

        if(!this.validateClient()) {
            return;
        }
        if(!this.validateRequest()) {
            return;
        }

        Object requestBody = this.buildRequestDataModel();
		System.debug('** test **: requestBody ' + requestBody);
        // requestBody = this.buildRequestBody(requestBody);
        this.requestModel.setBody(requestBody);
        this.updateReferenceLog();
        this.logger.updateLogAfterPrepareRequestData(this.requestModel, this.referenceId, this.referenceInfo);
    }

    public virtual void updateReferenceLog() {
        this.referenceId = Datetime.now().format('YYYYMMddHHmmss');
        this.referenceInfo = Datetime.now().format('YYYYMMddHHmmss');
    }

    @TestVisible private void handleResponse() {
        this.clientModel.processResponse(this.responseModel, this.responseDataModelClass);
        this.logger.updateLogByResponse(this.responseModel);

        if(this.responseModel.isSuccess()) {
            try {
                this.processSuccessResponse();
                this.logger.updateLogForSuccessIntegration(null);
            } catch(Exception e) {
                this.logger.updateLogForSuccessIntegration(e);
                try {
                    this.processFailedResponse();
                } catch(Exception secondException) {
                    this.logger.updateLogForSecondFailedProcess(secondException);
                }
            }
        } else {
            this.processFailedResponse();
            this.logger.updateLogForFailedIntegration(this.responseModel);
        }

        this.logger.insertAlls(this.insertLogType);
        return;
    }

    @TestVisible
    protected virtual Boolean validateClient() {
        if(this.clientModel == null) {
            throw new b8int_CustomException('b8int_HTTPClient is null');
        }
        return true;
    }

    @TestVisible
    protected virtual Boolean validateRequest() {
        return this.requestModel.validate();
    }


    @TestVisible protected void setIsRequireRetry(Boolean isRequireRetry) {
        this.logger.setIsRequireRetry(isRequireRetry);
    }

    @TestVisible protected void setRequestDataModelClass(Type requestDataModelClass) {
        this.requestDataModelClass = requestDataModelClass;
        this.logger.getIntLogModel().setRequestDataModelClass(requestDataModelClass.getName());
    }

    @TestVisible protected void setResponseDataModelClass(Type responseDataModelClass) {
        this.responseDataModelClass = responseDataModelClass;
    }

    @TestVisible private void sendRequest() {
        this.logger.getIntLogModel().setStartEndDateTime(System.now(), null);
        this.clientModel.initCredential();
        HttpResponse response = this.send();
        if(response != null) {
            this.responseModel = new b8int_BaseHttpResponse(response);
        }
    }

    @TestVisible private HttpResponse send() {
        Http http = new Http();
        HttpResponse response;
        this.logger.getIntLogModel().setStartEndDateTime(System.now(), null);
        this.requestModel.addHeaderOption(this.clientModel.getHeaderOptions());
        HttpRequest request = this.requestModel.generateHttpRequest();
		request.setTimeout(120000);
        response = http.send(request);
        this.logger.getIntLogModel().setStartEndDateTime(null, System.now());
        Boolean retryIfUnauthorize = response.getStatusCode() == 401 && this.clientModel.isAutoRetryIfUnauthorize();
        if(retryIfUnauthorize) {
            this.clientModel.setAutoRetryIfUnauthorize(false);
            this.clientModel.newCredential();
            return this.send();
        }
        return response;
    }

    @TestVisible protected b8int_BaseHttpCallout setContentType(b8int_BaseHttpRequest.ContentType newContentType) {
        this.requestModel.setContentType(newContentType);
        return this;
    }

    @TestVisible protected b8int_BaseHttpCallout setEndpoint(String newEndpoint) {
        if(clientModel == null) {
            throw new b8int_CustomException('b8int_BaseHttpCallout.setEndpoint: Please set http client first');
        }
        this.requestModel.setEndpoint(this.clientModel.getBaseUrl(), newEndpoint);
        this.logger.getIntLogModel().setEndpoint(this.requestModel.getFullEndpoint());
        return this;
    }

    public b8int_BaseHttpCallout setCalloutType(HttpCalloutType newCalloutType) {
        this.calloutType = newCalloutType;
        return this;
    }

    @TestVisible protected b8int_BaseHttpCallout setClient(b8int_BaseHttpClient newClient) {
        this.clientModel = newClient;
        return this;
    }

    @TestVisible protected b8int_BaseHttpCallout setMethod(b8int_BaseHttpRequest.HttpMethod newMethod) {
        this.requestModel.setMethod(newMethod);
        return this;
    }

    public void setRetry(b8int_RetrialIntegrationLogModel retryLogModel) {
        this.logger.setRetryLogModel(retryLogModel);
        this.logger.getRetryLogModel().incrementNumberOfRetry();
        this.calloutType = HttpCalloutType.QUEUE;
    }

    @TestVisible private Boolean isRetrial() {
        return this.logger.isRetrial();
    }

    @TestVisible protected b8int_BaseHttpRequest getRequestModel() {
        return this.requestModel;
    }

	@TestVisible protected b8int_BaseHttpResponse getResponseModel(){
		return this.responseModel;
	}
}