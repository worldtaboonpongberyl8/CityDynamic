public with sharing class CreateReceiptApiClient extends b8int_BaseHttpClient{

    public CreateReceiptApiClient() {
		super('Pojjaman'); // named Credential
        this.setAutoRetryIfUnauthorize(true);
    }

	public override void initCredential() {
        // this.headerOptions.put('AccessId', 'MTY0N0JGMEEtN0FDOS00RTA3LTg4MkUtQTVGMTdBNEZDNjA3');
		// this.headerOptions.put('AccessToken', 'EAAAAO7+cLywFO+1ezCSeDY5g8eRULZ49qOawvdrRIusivfWZ4d34qbHWnwG1FtOABeNDHchPXtCUFUyAanBzEJM4MI=');
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
			CreateReceiptApiCallout.ResponseDataModel responseDataModel = new CreateReceiptApiCallout.ResponseDataModel();
			List<CreateReceiptApiCallout.ReceiptResponse> receiptResponses = (List<CreateReceiptApiCallout.ReceiptResponse>)JSON.deserialize(stringBody, List<CreateReceiptApiCallout.ReceiptResponse>.class);
			responseDataModel.isSuccess = true;
			responseDataModel.responses = receiptResponses;
            // if(responseDataModel == null) {
            //     response.failed('cannot deserialize response data');
            //     return;
            // }
			b8int_BaseResponseDataModel dataModel = (b8int_BaseResponseDataModel)responseDataModel;
			response.setResponseDataModel(dataModel);
        } catch(Exception e) {
            response.failed(e.getMessage());
        }
	}
}