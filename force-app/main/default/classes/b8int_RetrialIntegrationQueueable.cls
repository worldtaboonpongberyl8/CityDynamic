public without sharing class b8int_RetrialIntegrationQueueable extends b8int_BaseHttpCallout {
    public b8int_RetrialIntegrationQueueable(String test) {
        super(test);
    }

    public override Object buildRequestDataModel() {
        return null;
    }

    public override Boolean processSuccessResponse() {
        return true;
    }

    public override Boolean processFailedResponse() {
        return true;
    }
    
}