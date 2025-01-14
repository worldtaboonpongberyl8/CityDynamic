public with sharing class WordContentMasterSelector {
	public static WordContentMasterSelector instance;

	public static WordContentMasterSelector getInstance() {
		if (instance == null) {
			instance = new WordContentMasterSelector();
		}
		return instance;
	}

    public List<WordContentMaster__c> getByZipId(String zipId){
        return [
            SELECT Id, Name, ZipFileMasterId__c, KeyToReplace__c, ObjectToQuery__c, FieldToQuery__c,
                ConditionToQuery__c, LookupFieldToQuery__c, WordContentExternalKey__c, FormatType__c,
                DocumentPathName__c, SourceObject__c, SourceField__c
            FROM WordContentMaster__c 
            WHERE ZipFileMasterId__c =: zipId
        ];
    }

    public List<WordContentMaster__c> getByZipIdSetAndFormatTypeSet(Set<Id> zipIdSet, Set<String> formatTypeSet){
        return [
            SELECT Id, Name, ZipFileMasterId__c, KeyToReplace__c, ObjectToQuery__c, FieldToQuery__c,
                ConditionToQuery__c, LookupFieldToQuery__c, WordContentExternalKey__c, FormatType__c,
                DocumentPathName__c, SourceObject__c, SourceField__c
            FROM WordContentMaster__c 
            WHERE ZipFileMasterId__c IN: zipIdSet
                AND FormatType__c IN: formatTypeSet
        ];
    }
}