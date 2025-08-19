public without sharing class ContentDocumentLinkSelector {
    public static ContentDocumentLinkSelector instance;

    public static ContentDocumentLinkSelector getInstance() {
        if (instance == null) {
            instance = new ContentDocumentLinkSelector();
        }
        return instance;
    }

	public List<ContentDocumentLink> getByLinkEntityIdSet(Set<String> linkEntityIdSet){
		if(linkEntityIdSet.isEmpty()){
			return new List<ContentDocumentLink>();
		}

		return [
			SELECT Id, LinkedEntityId, ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId IN: linkEntityIdSet
		];
	}

	public List<ContentDocumentLink> getByLinkEntityIdSet(Set<Id> linkEntityIdSet){
		if(linkEntityIdSet.isEmpty()){
			return new List<ContentDocumentLink>();
		}

		return [
			SELECT Id, LinkedEntityId, ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId IN: linkEntityIdSet
		];
	}

	/**
	 * Phase2
	 * Details:
	 * - add logic to get content distribution
	 */
	public List<ContentDistribution> getContentDistributionByContentDocumentId(Set<Id> contentDocumentIds){
		if(contentDocumentIds.isEmpty()){
			return new List<ContentDistribution>();
		}
		return [
			SELECT DistributionPublicUrl,ContentDownloadUrl
			FROM ContentDistribution
			WHERE ContentDocumentId IN: contentDocumentIds
		];
	}
}