public with sharing class DocumentTemplateMappingMDTSelector {
	public static DocumentTemplateMappingMDTSelector instance;

	public static DocumentTemplateMappingMDTSelector getInstance() {
		if (instance == null) {
			instance = new DocumentTemplateMappingMDTSelector();
		}
		return instance;
	}

	public List<DocumentTemplateMapping__mdt> getByObjAPIAndLangAndTemplateMappingType(
		String objectApiName,
		String language,
		String templateMappingType
	) {
		return [
			SELECT Id, DocumentTemplateName__c, IsActive__c, Language__c, ObjectName__c , TemplateMappingType__c, 
				IsSaveToExistingFile__c, FieldAPINameSaveToExistingFile__c, AdditionalCondition__c, AdditionalConditionFields__c
			FROM DocumentTemplateMapping__mdt 
			WHERE ObjectName__c =: objectApiName AND 
				Language__c =: language AND
				TemplateMappingType__c =: templateMappingType AND 
				IsActive__c = true
		];
	}

	public List<DocumentTemplateMapping__mdt> getByTemplateAndMappingType(String templateMappingType) {
		return [
			SELECT Language__c
			FROM DocumentTemplateMapping__mdt 
			WHERE TemplateMappingType__c =: templateMappingType
		];
	}
}