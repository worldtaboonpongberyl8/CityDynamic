public with sharing class DocumentDetailWrapper {
    @AuraEnabled
    public String RecordId {get;set;}
    @AuraEnabled
    public String ObjectAPIName {get;set;}
    @AuraEnabled
    public String DocumentId {get;set;}
    @AuraEnabled
    public String DocumentName {get;set;}
    @AuraEnabled
    public String RunningNumber {get;set;}
    @AuraEnabled
    public String ErrorMessage {get;set;}
    // @AuraEnabled
    // public Map<String, DocumentTemplateMapping__mdt> MapDocumentTemplate {get;set;}
    @AuraEnabled
    public DocumentTemplateMapping__mdt DocumentTemplateMappingMDT {get;set;}
    // @AuraEnabled
    // public List<Integer> TableRowToRemoves {get;set;}
    @AuraEnabled
    public String ParamInput {get;set;}
}