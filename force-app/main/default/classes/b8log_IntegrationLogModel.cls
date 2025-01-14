public without sharing virtual class b8log_IntegrationLogModel {
    @TestVisible private static final Integer MAX_PAYLOAD_LENGTH =  Integer.valueOf(b8log_Integration_Log__c.Request__c.getDescribe().getLength());
    @TestVisible private static final Integer MAX_RESPONSE_LENGTH =  Integer.valueOf(b8log_Integration_Log__c.Response__c.getDescribe().getLength());
    @TestVisible private static final Integer MAX_REFERENCEINFO_LENGTH = Integer.valueOf(b8log_Integration_Log__c.Reference_Info__c.getDescribe().getLength());
    @TestVisible private static final Integer MAX_REFERENCEID_LENGTH = Integer.valueOf(b8log_Integration_Log__c.Reference_Id__c.getDescribe().getLength());
    @TestVisible private static final Integer MAX_INTERFACESUBNAME_LENGTH = Integer.valueOf(b8log_Integration_Log__c.Interface_Sub_Name__c.getDescribe().getLength());

    @TestVisible protected b8log_Integration_Log__c integrationLog;
    @TestVisible private Attachment payloadFile; 
    @TestVisible private Attachment responseFile;

    public b8log_IntegrationLogModel(b8log_Integration_Log__c im) {
        this.integrationLog = im;
    }

    public b8log_IntegrationLogModel() {
        this.integrationLog = new b8log_Integration_Log__c();
        this.integrationLog.Number_Of_Retry__c = 0;
    }

    public b8log_Integration_Log__c get()   { return this.integrationLog; }
    public Integer getNumberOfRetry()       { return Integer.valueOf(this.integrationLog.Number_Of_Retry__c); }

    public b8log_IntegrationLogModel setName(String interfaceName, String interfaceSubName) { 
        this.integrationLog.Interface_Name__c = interfaceName; 
        
        if(String.isNotBlank(interfaceSubName)) {
            this.integrationLog.Interface_Sub_Name__c = interfaceSubName.left(MAX_INTERFACESUBNAME_LENGTH); 
        } else {
            this.integrationLog.Interface_Sub_Name__c = interfaceSubName; 
        }

        return this;
    }

    public b8log_IntegrationLogModel setStatus(b8log.IntegrationStatus newStatus) {
        this.integrationLog.Status__c = newStatus.name();
        return this;
    }

    public b8log_IntegrationLogModel setEndpoint(String endpoint) {
        this.integrationLog.Endpoint__c = endpoint;
        return this;
    }

    public b8log_IntegrationLogModel setStartEndDateTime(DateTime startDateTime, DateTime endDateTime) {
        if(startDateTime != null) {
            this.integrationLog.Start_DateTime__c = startDateTime;    
        }

        if(endDateTime != null) {
            this.integrationLog.End_DateTime__c = endDateTime;
        }
        return this;
    }

    public b8log_IntegrationLogModel setReference(String referenceId, String referenceInfo) {
        if(String.isNotBlank(referenceId)) {
            this.integrationLog.Reference_Id__c = referenceId.left(MAX_REFERENCEID_LENGTH);
        } else {
            this.integrationLog.Reference_Id__c = referenceId;
        }
        
        if(String.isNotBlank(referenceInfo)) {
            this.integrationLog.Reference_Info__c = referenceInfo.left(MAX_REFERENCEINFO_LENGTH);
        } else {
            this.integrationLog.Reference_Info__c = referenceInfo;
        }

        return this;
    }

    public b8log_IntegrationLogModel setRequestDataModelClass(String requestDataModelClass) {
        this.integrationLog.Request_Data_Model_Class__c = requestDataModelClass;
        return this;
    }

    public b8log_IntegrationLogModel setRequest(String payload) {
        if(String.isBlank(payload)) { return this; }

        if(payload.length() <= MAX_PAYLOAD_LENGTH) {
            this.integrationLog.Request_Store_Type__c = b8log.PayloadStoreType.Field.name();
            this.integrationLog.Request__c = payload.left(MAX_PAYLOAD_LENGTH);
        } else {
            this.integrationLog.Request_Store_Type__c = b8log.PayloadStoreType.File.name();
            Attachment attachment = new Attachment();
            attachment.Body = Blob.valueOf(payload);
            this.payloadFile = attachment;
        }

        return this;
    }
    
    public b8log_IntegrationLogModel setResponse(Integer statusCode, String responseBody) {
        this.integrationLog.Response_Status_Code__c = statusCode;
        if(String.isBlank(responseBody)) { return this; }

        if(responseBody.length() <= MAX_RESPONSE_LENGTH) {
            this.integrationLog.Response_Store_Type__c = b8log.PayloadStoreType.Field.name();
            this.integrationLog.Response__c = responseBody.left(MAX_RESPONSE_LENGTH);
        } else {
            this.integrationLog.Response_Store_Type__c = b8log.PayloadStoreType.File.name();
            Attachment attachment = new Attachment();
            attachment.Body = Blob.valueOf(responseBody);
            this.responseFile = attachment;
        }
        return this;
    }

    public b8log_IntegrationLogModel setNextRetryDateTime(DateTime nextRetry) {
        this.integrationLog.Next_Retry_DateTime__c = nextRetry;
        return this;
    }

    public b8log_IntegrationLogModel setException(Exception e) {
        if(e != null) {
            this.integrationLog.Exception__c = e.getMessage();
            this.integrationLog.Status__c = b8log.IntegrationStatus.FAILED.name();
        } else {
            this.integrationLog.Status__c = b8log.IntegrationStatus.SUCCESS.name();
        }
        return this;
    }

    public virtual b8log_IntegrationLogModel incrementNumberOfRetry() {
        this.integrationLog.Number_Of_Retry__c = this.integrationLog.Number_Of_Retry__c + 1;
        return this;
    }

    public List<Attachment> updateAttachment() {
        List<Attachment> allAttachments = new List<Attachment>();
        String datetimeFormat = System.now().format('yyyMMdd:HHmmss', 'Asia/Bangkok');
        Integer index = 1;

        Boolean hasNewPayloadFile = this.payloadFile != null && this.payloadFile.Id == null;
        if(hasNewPayloadFile) {
            this.payloadFile.ParentId = this.integrationLog.Id;
            this.payloadFile.Name = b8log_IntegrationLogAttachment.REQUEST_FILE_PREFIX + datetimeFormat + '-' + ('0'+index).right(2)+'.txt';
            allAttachments.add(this.payloadFile);
        }

        Boolean hasNewResponseFile = this.responseFile != null && this.responseFile.Id == null;
        if(hasNewResponseFile) {
            this.responseFile.ParentId = this.integrationLog.Id;
            this.responseFile.Name = b8log_IntegrationLogAttachment.RESPONSE_FILE_PREFIX + datetimeFormat + '-' + ('0'+index).right(2)+'.txt';
            allAttachments.add(this.responseFile);
        }

        return allAttachments;
    }

    /**
     * @input: You can use b8log_IntegrationLogAttachment class to retrieve attachment map
     */
    public b8log_IntegrationLogModel setAttachmentPayload(Map<Id, Map<String, Attachment>> attachmentMapById) {
        if(attachmentMapById == null) { return this; }
        if(!attachmentMapById.containsKey(this.integrationLog.Id)) { return this; }

        Map<String, Attachment> attachmentMap = attachmentMapById.get(this.integrationLog.Id);

        if(attachmentMap.containsKey(b8log_IntegrationLogAttachment.REQUEST_FILE_PREFIX)) {
            this.payloadFile = attachmentMap.get(b8log_IntegrationLogAttachment.REQUEST_FILE_PREFIX);
        }
        if(attachmentMap.containsKey(b8log_IntegrationLogAttachment.RESPONSE_FILE_PREFIX)) {
            this.responseFile = attachmentMap.get(b8log_IntegrationLogAttachment.RESPONSE_FILE_PREFIX);
        }
        return this;
    }
    
    public String getRequestBody() {
        Boolean hasPayloadFile = this.integrationLog.Request_Store_Type__c == b8log.PayloadStoreType.File.name() && this.payloadFile != null;
        if(hasPayloadFile) {
            return this.payloadFile.Body.toString();
        }
        return this.integrationLog.Request__c;
    }
}