public without sharing class b8int_BaseHttpResponse {
    @TestVisible private HttpResponse response;
	@TestVisible protected b8int_BaseResponseDataModel responseDataModel;
    @TestVisible private Boolean isSuccess = true;
    @TestVisible private String description;

    public b8int_BaseHttpResponse(HttpResponse response) {
        this.response = response;
    }

    public Boolean isSuccess() {
        if(this.response == null) { return false; }
        if(this.response.getStatusCode() != 200 && this.response.getStatusCode() != 201) {
            return false;
        }
        return this.isSuccess;
    }

    public Integer getStatusCode()  { return this.response.getStatusCode(); }
    public String getBodyAsString() { return this.response.getBody(); }
    public String getDescription()  { return this.description; }
	public b8int_BaseResponseDataModel getResponseDataModel()  { return this.responseDataModel; }

	public b8int_BaseHttpResponse setResponseDataModel(b8int_BaseResponseDataModel dataModel) {
        this.responseDataModel = dataModel;
        return this;
    }

    public b8int_BaseHttpResponse failed(String description) {
        this.isSuccess = false;
        this.description = description;
        return this;
    }
}