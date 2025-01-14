public abstract without sharing class b8int_BaseHttpClient {
    @TestVisible protected String namedCredential;
    @TestVisible protected String baseUrl;
    @TestVisible protected Boolean autoRetryIfUnauthorize = false;
    @TestVisible protected Map<String, String> headerOptions = new Map<String, String>();
    
    public abstract void initCredential(); // init credential, may be retrive access token from cache, if not available then call newCredential
    public abstract void newCredential(); // authentication to retrieve access token

    public b8int_BaseHttpClient(String namedCredential) {
        this.namedCredential = namedCredential;
        if(String.isNotBlank(this.namedCredential)) {
            this.setBaseUrl('callout:'+this.namedCredential);
        }
    }

    public Map<String, String> getHeaderOptions() { return this.headerOptions; } 
    public Boolean isAutoRetryIfUnauthorize() { return this.autoRetryIfUnauthorize; }
    public b8int_BaseHttpClient setAutoRetryIfUnauthorize(Boolean autoRetry) { this.autoRetryIfUnauthorize = autoRetry; return this; }

    public String getBaseUrl() { return this.baseUrl; }
    
    @TestVisible protected void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }
    
    /**
     * @description: build generic request body for this client
     */
    public virtual Object buildRequestBody(Object requestBody, String calloutClassName, b8int_BaseHttpRequest.ContentType contentType) {
        if(requestBody != null) {
            if(contentType == b8int_BaseHttpRequest.ContentType.JSON) {
                return JSON.serialize(requestBody, true);
            }
        }
        return null;
    } 
    
    public virtual void processResponse(b8int_BaseHttpResponse response, Type responseDataModelClass) {
        if(response == null) { return; }

        String stringBody = response.getBodyAsString();
        if(String.isBlank(stringBody)) {
            return;
        }

        if(responseDataModelClass == null) {
            return;
        }

        try {   
            Object responseDataModel = JSON.deserialize(stringBody, responseDataModelClass); 
            if(responseDataModel == null) {
                response.failed('cannot deserialize response data');
                return;
            }

            if(responseDataModel instanceof b8int_BaseResponseDataModel) {
                b8int_BaseResponseDataModel dataModel = (b8int_BaseResponseDataModel)responseDataModel;
                response.setResponseDataModel(dataModel);
                if(!dataModel.isValid()) {
                    response.failed(dataModel.getErrorDescription());
                }
            }
        } catch(Exception e) {
            response.failed(e.getMessage());
        }
    }
}