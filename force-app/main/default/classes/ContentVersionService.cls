public with sharing class ContentVersionService {
	public static ContentVersionService instance;

	public static ContentVersionService getInstance() {
		if (instance == null) {
			instance = new ContentVersionService();
		}
		return instance;
	}

	public Database.SaveResult[] insertContentVersions(List<ContentVersion> contentVersions) {
		Database.SaveResult[] insertContentVerResults;

		if (!contentVersions.isEmpty()) {
			insertContentVerResults = Database.insert(contentVersions, false);
		}

		return insertContentVerResults;
	}

    public Set<Id> getContentVerIdSet(Map<Id, ContentVersion> contentVerMapByInvoiceId) {
        Set<Id> contentVerIdSet = new Set<Id>();
        for (ContentVersion contentVersion : contentVerMapByInvoiceId.values()) {
            if (contentVersion.Id == null) {
                continue;
            }

            contentVerIdSet.add(contentVersion.Id);
        }
        return contentVerIdSet;
    }

	public Map<Id, List<Id>> getRecordContentVerIdsMapByRecordIdForInvoice(
		Set<Id> invoiceIdAndOppIdset,
		Map<Id, String> invoiceNoMapWithInvoiceId,
		Map<Id, String> paymentSummaryNameMapWithInvoiceId
	){
		List<ContentDocumentLink> ctDocLinks = ContentDocumentLinkSelector.getInstance().getByLinkEntityIdSet(invoiceIdAndOppIdset);
		Map<Id, Id> contentDocIdMapByRecordId = new Map<Id, Id>();
		for (ContentDocumentLink ctDocLink : ctDocLinks) {
			contentDocIdMapByRecordId.put(ctDocLink.ContentDocumentId, ctDocLink.LinkedEntityId);
		}

		Set<String> fileExtensionSet = new Set<String>{'pdf'};
		Set<String> fileNameSet = new Set<String>();
		fileNameSet.addAll(new Set<String>(invoiceNoMapWithInvoiceId.values()));
		fileNameSet.addAll(new Set<String>(paymentSummaryNameMapWithInvoiceId.values()));

		List<ContentVersion> contentVersions = ContentVersionSelector.getInstance().getForSendEmailBatches(
			contentDocIdMapByRecordId.keySet(), fileNameSet, fileExtensionSet
		);

		Map<Id, ContentVersion> contentVerMapByContentDocId = new Map<Id, ContentVersion>();
		for (ContentVersion contentVersion : contentVersions) {
			contentVerMapByContentDocId.put( contentVersion.ContentDocumentId, contentVersion );
		}

		Map<Id, List<Id>> recordContentVerIdsMapByRecordId = new Map<Id, List<Id>>();
		for (Id contentDocId : contentVerMapByContentDocId.keySet()) {
			List<Id> contentVerIds = recordContentVerIdsMapByRecordId.get(contentDocIdMapByRecordId.get(contentDocId));
			if(contentVerIds == null){
				recordContentVerIdsMapByRecordId.put(
					contentDocIdMapByRecordId.get(contentDocId), // record id
					new List<Id>{ contentVerMapByContentDocId.get(contentDocId).Id } // file content version Id
				);
			}
			else{
				contentVerIds.add(contentVerMapByContentDocId.get(contentDocId).Id);
			}
		}

		return recordContentVerIdsMapByRecordId;
	}
}