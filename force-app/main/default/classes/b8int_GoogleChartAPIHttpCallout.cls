public without sharing class b8int_GoogleChartAPIHttpCallout extends b8int_BaseHttpCallout {
    public Id recordId;

    public b8int_GoogleChartAPIHttpCallout() {
        super('GoogleChartAPI');
        this.setCalloutType(b8int_BaseHttpCallout.HttpCalloutType.REALTIME);
        this.setMethod(b8int_BaseHttpRequest.HttpMethod.GET);
        this.setClient(new b8int_GoogleChartAPIHttpClient());
        this.setContentType(b8int_BaseHttpRequest.ContentType.JSON);
        this.setEndpoint('/');
    }

    public void setUrlForQRCodeByRecordId(Id recordId) {
        this.recordId = recordId;
        this.setUrlForQRCode(URL.getSalesforceBaseUrl().toExternalForm()+'/'+recordId);
    }

    public void setUrlForQRCode(String url) {
        this.setEndpoint('/chart?chs=150x150&cht=qr&chl='+url);
    }

    
    public override void updateReferenceLog() {
        this.referenceId = this.recordId;
        this.referenceInfo = this.recordId;
    }

    public override Object buildRequestDataModel() {
        return null;
    }
    
    public override Boolean processFailedResponse() {
        return true; 
    }

    public override Boolean processSuccessResponse() {
        return true; 
    }
}