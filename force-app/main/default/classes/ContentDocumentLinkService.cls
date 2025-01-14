public with sharing class ContentDocumentLinkService {
	public static ContentDocumentLinkService instance;

	public static ContentDocumentLinkService getInstance() {
		if (instance == null) {
			instance = new ContentDocumentLinkService();
		}
		return instance;
	}

	public Database.SaveResult[] insertContentDocumentLinks(List<ContentDocumentLink> contentDocumentLinks) {
		Database.SaveResult[] insertContentVerResults;

		if (!contentDocumentLinks.isEmpty()) {
			insertContentVerResults = Database.insert(contentDocumentLinks, false);
		}

		return insertContentVerResults;
	}
}