@isTest
public class b8int_MockRestResource_Test {
    
    @isTest static void test() {
        b8int_SfdcCustomApiCallout.RequestDataModel requestData = new b8int_SfdcCustomApiCallout.RequestDataModel();
        requestData.expectedSuccessStatus = false;
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestBody = Blob.valueOf(JSON.serialize(requestData));
        RestContext.request = req;
        RestContext.response = res;
        b8int_MockRestResource.doPost();
    }
}