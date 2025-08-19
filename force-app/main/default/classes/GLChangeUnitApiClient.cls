public with sharing class GLChangeUnitApiClient extends b8int_BaseHttpClient  {

    public GLChangeUnitApiClient() {
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

        try {
			PojjamanDataModel.ResponseDataModel responseDataModel = new PojjamanDataModel.ResponseDataModel();
			List<PojjamanDataModel.FNGLDocResponse> glResponses = (List<PojjamanDataModel.FNGLDocResponse>)JSON.deserialize(stringBody, List<PojjamanDataModel.FNGLDocResponse>.class);
			responseDataModel.isSuccess = true;
			responseDataModel.responses = glResponses;
			b8int_BaseResponseDataModel dataModel = (b8int_BaseResponseDataModel)responseDataModel;
			response.setResponseDataModel(dataModel);
        } catch(Exception e) {
            response.failed(e.getMessage());
        }
	}
}