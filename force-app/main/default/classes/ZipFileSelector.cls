public with sharing class ZipFileSelector {
	public static ZipFileSelector instance;

	public static ZipFileSelector getInstance() {
		if (instance == null) {
			instance = new ZipFileSelector();
		}
		return instance;
	}

	public List<ZipFile__c> getByNameAndRecordType(Set<String> targetTemplateNameSet, String recTypeId){
		return [
			SELECT Id, Name, RecordTypeId
			FROM ZipFile__c
			WHERE Name IN: targetTemplateNameSet AND RecordTypeId =: recTypeId
		];
	}

	public List<ZipFile__c> getByIdSetAndRecType(Set<String> zipFileIdSet, String recTypeId){
		return [
			SELECT Id, Name, RecordTypeId
			FROM ZipFile__c
			WHERE Id IN: zipFileIdSet AND RecordTypeId =: recTypeId
		];
	}

	public ZipFile__c getById(Id zipFileId){
		return [
			SELECT Id, Name, RecordTypeId
			FROM ZipFile__c
			WHERE Id =: zipFileId
		];
	}

	public List<ZipFile__c> getByIdSet(Set<Id> zipFileIdSet){
		return [
			SELECT Id, Name, RecordTypeId
			FROM ZipFile__c
			WHERE Id IN: zipFileIdSet
		];
	}
}