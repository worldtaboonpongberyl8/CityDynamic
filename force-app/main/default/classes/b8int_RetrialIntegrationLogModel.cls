public without sharing class b8int_RetrialIntegrationLogModel extends b8log_IntegrationLogModel {
    
    @TestVisible protected Boolean isRequireRetry = false;

    public b8int_RetrialIntegrationLogModel(b8log_Integration_Log__c intLog) {
        super(intLog);
    }

    //TODO Remove this function
    public b8int_RetrialIntegrationLogModel updateRequiredRetry() {
        return this;
    }

    public b8int_RetrialIntegrationLogModel setIsRequireRetry(Boolean isRequireRetry) {
        this.isRequireRetry = isRequireRetry;

        if(this.isRequireRetry) {
            if(this.integrationLog.Number_Of_Retry__c >= b8int_RetrialIntegrationService.MAX_RETRY) {
                this.isRequireRetry = false;
            }
        }
        return this;
    }
    
    public b8int_BaseHttpCallout getCalloutInstance(Map<Id, Map<String, Attachment>> attachmentMap) {
        b8int_BaseHttpCallout calloutInstance = this.getClassInstance();
        return calloutInstance;
    }
    
    public b8int_BaseHttpCallout getClassInstance() {
        Type t = getClassType(this.integrationLog.Interface_Name__c);
        if(t==null) { return null; }

        // Create an instance to confirm the type
        object classInstance = t.newInstance();
        if(!(classInstance instanceOf b8int_BaseHttpCallout)) {
            return null;
        }

        b8int_BaseHttpCallout calloutInstance = (b8int_BaseHttpCallout)classInstance;
        calloutInstance.setRetry(this);
        return calloutInstance;
    }

    public Type getClassType(String className) {
        Type t = Type.forName(className);
        if(t == null && className != null) {
            // Attempt to get the type again with the namespace explicitly set to blank
            t = Type.forName('', className);
        }
        if(t == null) { return null; }
        return t;
    }

}