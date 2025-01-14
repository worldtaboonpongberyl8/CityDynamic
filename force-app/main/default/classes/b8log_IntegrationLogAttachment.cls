public without sharing class b8log_IntegrationLogAttachment {
    public static final String REQUEST_FILE_PREFIX = 'b8log-req-';
    public static final String RESPONSE_FILE_PREFIX = 'b8log-res-';

    public static Map<Id, Map<String, Attachment>> getRequestAttachmentMap(Set<Id> attachmentParentIds) {
        return b8log_IntegrationLogAttachment.getAttachmentMap(attachmentParentIds, true, false);
    }

    public static Map<Id, Map<String, Attachment>> getAttachmentMap(Set<Id> attachmentParentIds, Boolean needRequestFile, Boolean needResponseFile) {
        Map<Id, Map<String, Attachment>> attachmentMap = new Map<Id, Map<String, Attachment>>();
        if(attachmentParentIds.isEmpty()) {
            return attachmentMap;
        }

        for(Attachment attach : [SELECT Id, Name, ParentId, Body FROM Attachment WHERE ParentId = :attachmentParentIds ORDER BY LastModifiedDate DESC]) {
            if(!attachmentMap.containsKey(attach.ParentId)) {
                attachmentMap.put(attach.ParentId, new Map<String, Attachment>());
            }

            Boolean isRequestFile = needRequestFile && attach.Name.startsWithIgnoreCase(b8log_IntegrationLogAttachment.REQUEST_FILE_PREFIX);
            Boolean isResponseFile = needResponseFile && attach.Name.startsWithIgnoreCase(b8log_IntegrationLogAttachment.RESPONSE_FILE_PREFIX);

            if(isRequestFile) {
                if(!attachmentMap.get(attach.ParentId).containsKey(b8log_IntegrationLogAttachment.REQUEST_FILE_PREFIX)) {
                    attachmentMap.get(attach.ParentId).put(b8log_IntegrationLogAttachment.REQUEST_FILE_PREFIX, attach);
                }
            } else if(isResponseFile) {
                if(!attachmentMap.get(attach.ParentId).containsKey(b8log_IntegrationLogAttachment.RESPONSE_FILE_PREFIX)) {
                    attachmentMap.get(attach.ParentId).put(b8log_IntegrationLogAttachment.RESPONSE_FILE_PREFIX, attach);
                }
            }
        }
        return attachmentMap;
    }
}