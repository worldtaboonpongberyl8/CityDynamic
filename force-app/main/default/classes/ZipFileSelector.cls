public with sharing class ZipFileSelector {
	public static List<ZipFile__c> getByNameAndRecordType(Set<String> targetTemplateNameSet, String recTypeId){
		return [
			SELECT Id, Name, RecordTypeId 
			FROM ZipFile__c 
			WHERE Name IN: targetTemplateNameSet AND RecordTypeId =: recTypeId
		];
	}
	
	public static List<ZipFile__c> getByIdSetAndRecType(Set<String> zipFileIdSet, String recTypeId){
		return [
			SELECT Id, Name, RecordTypeId 
			FROM ZipFile__c
			WHERE Id IN: zipFileIdSet AND RecordTypeId =: recTypeId
		];
	}
	
	public static ZipFile__c getById(Id zipFileId){
		return [
			SELECT Id, Name, RecordTypeId 
			FROM ZipFile__c
			WHERE Id =: zipFileId
		];
	}
	
	public static List<ZipFile__c> getByIdSet(Set<Id> zipFileIdSet){
		return [
			SELECT Id, Name, RecordTypeId 
			FROM ZipFile__c
			WHERE Id IN: zipFileIdSet
		];
	}
}