public without sharing class ContentDocumentSelector {
	public ContentDocumentSelector() {

	}
	public static ContentDocumentSelector instance;

	public static ContentDocumentSelector getInstance() {
		if (instance == null) {
			instance = new ContentDocumentSelector();
		}
		return instance;
	}

	public List<ContentDocument> getByIdSet(Set<Id> contentDocumentIdSet) {
		return [
			SELECT Id
			FROM ContentDocument
			WHERE Id IN: contentDocumentIdSet
		];
	}

	public Map<Id, ContentDocument> getContentDocumentById(Set<Id> contentDocumentIds) {
		Map<Id, ContentDocument> contentDocMap = new Map<Id, ContentDocument>();
		List<ContentDocument> contentDocRecords = [SELECT Id, Title FROM ContentDocument WHERE Id IN :contentDocumentIds];
		for (ContentDocument contentDoc : contentDocRecords) {
			contentDocMap.put(contentDoc.Id, contentDoc);
		}
		return contentDocMap;
	}
}