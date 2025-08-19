public without sharing class NameFormattingMasterDataSelector {
    public static NameFormattingMasterDataSelector instance;

    public static NameFormattingMasterDataSelector getInstance() {
        if (instance == null) {
            instance = new NameFormattingMasterDataSelector();
        }
        return instance;
    }

	public List<NameFormattingMasterData__c> getByObjTypePurposeDocTemplate(
        String objectName,
        String type,
        String runningPurpose,
        String docTemplateMappingType
    ){
		return [
            SELECT ObjectName__c, Type__c, RunningFormat__c, RunningPurpose__c, DocumentTemplateMappingType__c
            FROM NameFormattingMasterData__c
            WHERE ObjectName__c =: objectName
                AND Type__c =: type
                AND RunningPurpose__c =: runningPurpose
                AND DocumentTemplateMappingType__c =: docTemplateMappingType
        ];
	}

	public List<NameFormattingMasterData__c> getByObjTypePurposeDocTemplateRunningKey(
        String objectName,
        String type,
        String runningPurpose,
        String docTemplateMappingType,
        Set<String> runningKeySet
    ){
		return [
            SELECT ObjectName__c, Type__c, RunningFormat__c, RunningKey__c, CurrentRunningNumber__c, DocumentTemplateMappingType__c
            FROM NameFormattingMasterData__c
            WHERE ObjectName__c =: objectName
                AND Type__c =: type
                AND RunningPurpose__c =: runningPurpose
                AND DocumentTemplateMappingType__c =: docTemplateMappingType
                AND RunningKey__c IN: runningKeySet
        ];
	}
}