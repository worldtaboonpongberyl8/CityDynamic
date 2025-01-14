@isTest
public without sharing class b8int_Mocker_Test {

    public static Boolean alreadySetRetrialSchd = false;

    public class MockClient extends b8int_BaseHttpClient {
        public MockClient() {
            super('NAME_CREDENTIAL');
        }
        public override void initCredential() {
            System.debug(System.LoggingLevel.INTERNAL, 'initCredential');
        }
        public override void newCredential() {
            System.debug(System.LoggingLevel.INTERNAL, 'newCredential');
        }
    }
    
    public class MockCallout extends b8int_BaseHttpCallout {
        public MockCallout() {
            super('Mock_CustomApi');
            this.setMethod(b8int_BaseHttpRequest.HttpMethod.POST);
            this.setClient(new MockClient());
            this.setContentType(b8int_BaseHttpRequest.ContentType.JSON);
            this.setEndpoint('services/apexrest/mock_rest_resource');
            this.setRequestDataModelClass(MockRequestDataModel.class);
            this.setResponseDataModelClass(MockResponseDataModel.class);
        }

        public override Object buildRequestDataModel()      { return null; }
        public override Boolean processSuccessResponse()    { return true; }
        public override Boolean processFailedResponse()     { return true; }
    }

    public class MockCalloutResp implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            return response;
        }
    }

    public class MockRequestDataModel extends b8int_BaseRequestDataModel {

    }

    public class MockResponseDataModel extends b8int_BaseResponseDataModel {

    }
}