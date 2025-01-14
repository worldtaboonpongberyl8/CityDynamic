@RestResource(urlMapping='/mock_rest_resource/*')
global without sharing class b8int_MockRestResource {

    @HttpPost
    global static void doPost() {
        String jsonString = RestContext.request.requestBody.toString();
        b8int_SfdcCustomApiCallout.RequestDataModel requestData = (b8int_SfdcCustomApiCallout.RequestDataModel)
                                                                    JSON.deserialize(jsonString, b8int_SfdcCustomApiCallout.RequestDataModel.class);

        b8int_SfdcCustomApiCallout.ResponseDataModel responseData = new b8int_SfdcCustomApiCallout.ResponseDataModel();
        responseData.isSuccess = requestData.expectedSuccessStatus;
        if(!responseData.isSuccess) {
            responseData.description = 'error description from apex rest';
        }

        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseData));
    }
    
}