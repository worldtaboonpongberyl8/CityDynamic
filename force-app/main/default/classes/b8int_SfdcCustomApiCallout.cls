public without sharing class b8int_SfdcCustomApiCallout extends b8int_BaseHttpCallout {
    public String expectedStatusCode = '200';
    public Boolean expectedSuccessStatus = false;

    public b8int_SfdcCustomApiCallout() {
        super('Mock_CustomApi');
        this.setCalloutType(b8int_BaseHttpCallout.HttpCalloutType.REALTIME);
        this.setIsRequireRetry(true);
        this.setMethod(b8int_BaseHttpRequest.HttpMethod.POST);
        this.setClient(new b8int_SfdcHttpClient());
        this.setContentType(b8int_BaseHttpRequest.ContentType.JSON);
        this.setEndpoint('services/apexrest/mock_rest_resource');
        this.setRequestDataModelClass(RequestDataModel.class);
        this.setResponseDataModelClass(ResponseDataModel.class);
    }

    public override Object buildRequestDataModel() {
        RequestDataModel requestDartaModel = new RequestDataModel();
        requestDartaModel.dataList.add('String1');
        requestDartaModel.dataList.add('String2');
        requestDartaModel.expectedStatusCode = this.expectedStatusCode;
        requestDartaModel.expectedSuccessStatus = this.expectedSuccessStatus;
        return requestDartaModel;
    }
    
    public override Boolean processFailedResponse() {
        return true; 
    }

    public override Boolean processSuccessResponse() {
        // RequestDataModel requestData = (RequestDataModel)this.getRequestModel().getRequestBody();
        return true; 
    }

    public class RequestDataModel extends b8int_BaseRequestDataModel {
        public String data = 'data';
        public List<String> dataList = new List<String>();
        public String expectedStatusCode;
        public Boolean expectedSuccessStatus;
    }

    public class ResponseDataModel extends b8int_BaseResponseDataModel {
        public Boolean isSuccess;
        public String description;

        public override Boolean isValid() {
            return isSuccess;
        }

        public override String getErrorDescription() {
            return this.description;
        }

    }
}