public without sharing class b8int_SfdcHttpClient extends b8int_BaseHttpClient {

    public b8int_SfdcHttpClient() {
        super('Salesforce'); // named Credential
        this.setAutoRetryIfUnauthorize(true);
        // System.debug(URL.getSalesforceBaseUrl().toExternalForm());
    }

    public override void initCredential() {
        this.headerOptions.put('Authorization', 'Bearer ' + b8int_SfdcSessionIdUtils.getSessionIdFromVfPage());
        return;
    }
    
    public override void newCredential() {
        this.headerOptions.put('Authorization', 'Bearer ' + b8int_SfdcSessionIdUtils.getSessionIdFromVfPage());
        return;
    }
}