public with sharing class CreateCustomerApiClient extends b8int_BaseHttpClient {

	public CreateCustomerApiClient() {
        super('Pojjaman'); // named Credential
        this.setAutoRetryIfUnauthorize(true);
    }

    public override void initCredential() {
        return;
    }

    public override void newCredential() {
        this.headerOptions.put('Authorization', 'Bearer ' + b8int_SfdcSessionIdUtils.getSessionIdFromVfPage());
        return;
    }

	public override void processResponse(b8int_BaseHttpResponse response, Type responseDataModelClass) {
		if(response == null) { return; }

        String stringBody = response.getBodyAsString();
        // if(String.isBlank(stringBody)) {
        //     return;
        // }

        // if(responseDataModelClass == null) {
        //     return;
        // }

        try {
			CreateCustomerApiCallout.ResponseDataModel responseDataModel = new CreateCustomerApiCallout.ResponseDataModel();
			List<CreateCustomerApiCallout.AccountResponse> accountResponses = (List<CreateCustomerApiCallout.AccountResponse>)JSON.deserialize(stringBody, List<CreateCustomerApiCallout.AccountResponse>.class);
			responseDataModel.isSuccess = true;
			responseDataModel.responses = accountResponses;
            // if(accountResponses == null) {
            //     response.failed('cannot deserialize response data');
            //     return;
            // }
			b8int_BaseResponseDataModel dataModel = (b8int_BaseResponseDataModel)responseDataModel;
			response.setResponseDataModel(dataModel);
			// if(!dataModel.isValid()) {
			// 	response.failed(dataModel.getErrorDescription());
			// }
        } catch(Exception e) {
			System.debug('**Error**: ' + e.getMessage() + ' ' + e.getStackTraceString());
            response.failed(e.getMessage());
        }
	}
}