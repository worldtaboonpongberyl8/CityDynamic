public without sharing class b8int_BaseHttpRequest {
	public enum HttpMethod {GET, PUT, POST, PATCH}
	public enum ContentType {XML, XMLTEXT, JSON, IMAGE, URLENCODED, ODATA, ODATAVERBOSECONTENT, TEXT}

    // @TestVisible HttpRequest request = new HttpRequest();

    @TestVisible private Integer timeout = 120000;
    @TestVisible protected Object requestBody;
    @TestVisible protected HttpMethod method;
    @TestVisible protected Map<String, String> headerOptions;
    @TestVisible protected ContentType thisContentType = ContentType.JSON;
    @TestVisible protected String serverUrl;
    @TestVisible protected String pathUrl;

    public b8int_BaseHttpRequest() {
        this.headerOptions = new Map<String, String>();
    }

    public Boolean validate() {
        if(this.method == null) {
            throw new b8int_CustomException('method is null');
        }
        return true;
    }
    
    public String getRequestBodyAsString() {
        if(this.requestBody == null) {
            return null;
        }

        if(this.requestBody instanceof String) {
            return (String)this.requestBody;
        } 

        if(thisContentType == ContentType.JSON) {
            return JSON.serialize(this.requestBody);
        }
        return null;
    }

    public HttpRequest generateHttpRequest() {
        HttpRequest request = new HttpRequest();
        if(this.requestBody != null) {
            if(this.requestBody instanceof Blob) {
                request.setBodyAsBlob((Blob)this.requestBody);
            } else {
                request.setBody(this.getRequestBodyAsString());
            }
        }

        for(String key: this.headerOptions.keySet()) {
            request.setHeader(key, this.headerOptions.get(key));
        }

        request.setMethod(this.method.name());
        request.setEndpoint(this.serverUrl+this.pathUrl);

        return request;
    }

    public b8int_BaseHttpRequest setBody(Object requestBody) {
        this.requestBody = requestBody;
        return this;
    }

    public b8int_BaseHttpRequest addHeaderOption(Map<String, String> newHeaderOptions) {
        this.headerOptions.putAll(newHeaderOptions);
        return this;
    }

    public b8int_BaseHttpRequest setHeaderOption(String key, String value) {
        this.headerOptions.put(key, value);
        return this;
    }

    public b8int_BaseHttpRequest setContentType(ContentType newContentType) {
        this.thisContentType = newContentType;
		this.setHeaderOption(b8int_WebSvcConstant.HEADER_CONTENT_TYPE, b8int_WebSvcConstant.HTTP_CONTENT_TYPE.get(newContentType));
        return this;
    }


    public b8int_BaseHttpRequest setEndpoint(String baseUrl, String endpoint) {
        this.serverUrl = baseUrl;
        this.pathUrl = endpoint;
        if(String.isNotBlank(this.pathUrl) && !this.pathUrl.startsWith('/')) {
            this.pathUrl = '/' + this.pathUrl;
        }
        if(String.isNotBlank(this.serverUrl) && this.serverUrl.endsWith('/')) {
            this.serverUrl = this.serverUrl.removeEnd('/');
        }
        return this;
    }

    public Object getRequestBody()      { return this.requestBody; }
    public ContentType getContentType() { return this.thisContentType; }
    public String getFullEndpoint()     { return this.serverUrl+this.pathUrl; }

    public b8int_BaseHttpRequest setMethod(HttpMethod newMethod) {
        this.method = newMethod;
        return this;
    }
}