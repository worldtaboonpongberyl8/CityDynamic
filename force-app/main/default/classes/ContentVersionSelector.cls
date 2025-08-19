public without sharing class ContentVersionSelector {
	public static ContentVersionSelector instance;

	public static ContentVersionSelector getInstance() {
		if (instance == null) {
			instance = new ContentVersionSelector();
		}
		return instance;
	}

	public ContentVersion getById(Id recordId){
		return [
			SELECT Id, ContentDocumentId
			FROM ContentVersion
			WHERE Id =: recordId
				AND IsLatest = true
		];
	}

	public List<ContentVersion> getByIdSet(Set<Id> recordIdSet){
		return [
			SELECT Id, ContentDocumentId, Title, VersionData
			FROM ContentVersion
			WHERE Id IN: recordIdSet
				AND IsLatest = true
		];
	}

	public List<ContentVersion> getByIdSetNoVersionData(Set<Id> recordIdSet){
		return [
			SELECT Id, ContentDocumentId
			FROM ContentVersion
			WHERE Id IN: recordIdSet
				// AND IsLatest = true
		];
	}

	public List<ContentVersion> getByDocIdAndTitleAndExtensionSet(Set<Id> contentDocumentIdSet, Set<String> titleSet, Set<String> extensionSet){
		return [
			SELECT Id, Title, ContentDocumentId, VersionData, FileExtension, LastModifiedDate
			FROM ContentVersion
			WHERE ContentDocumentId IN: contentDocumentIdSet
				AND Title IN: titleSet
				AND FileExtension IN: extensionSet
				AND IsLatest = true
			ORDER BY CreatedDate DESC
		];
	}

	public List<ContentVersion> getForSendEmailBatches(Set<Id> contentDocumentIdSet, Set<String> titleSet, Set<String> extensionSet){
		return [
			SELECT Id, ContentDocumentId
			FROM ContentVersion
			WHERE ContentDocumentId IN: contentDocumentIdSet
				AND Title IN: titleSet
				AND FileExtension IN: extensionSet
				AND IsLatest = true
			ORDER BY CreatedDate DESC
		];
	}
}