public without sharing class ContentDocumentService {
    public static ContentDocumentService instance;

    public ContentDocumentService() {
    }

    public static ContentDocumentService getInstance() {
        if (instance == null) {
            instance = new ContentDocumentService();
        }
        return instance;
    }

    public void renameContentDocumentTitle(List<ContentDocumentLink> contentDocumentLinks){
        List<ContentDocument> updateContentDocuments = new List<ContentDocument>();
        Product2Selector product2Selector = Product2Selector.getInstance();
        ContentDocumentSelector contentDocumentSelector = ContentDocumentSelector.getInstance();
        Set<Id> product2Ids = new Set<Id>();
        Set<Id> contentDocumentIds = new Set<Id>();
        for(contentDocumentLink contentDocLink : contentDocumentLinks){
            product2Ids.add(contentDocLink.LinkedEntityId);
            contentDocumentIds.add(contentDocLink.ContentDocumentId);
        }
        Map<Id, Product2> product2NameMap = product2Selector.getProduct2ById(product2Ids);
        Map<Id, ContentDocument> contentDocumentMap = contentDocumentSelector.getContentDocumentById(contentDocumentIds);

        List<ContentDocument> contentDocumentsToUpdate = new List<ContentDocument>();

        for (ContentDocumentLink contentDocLink : contentDocumentLinks) {
            ContentDocument contentDoc = contentDocumentMap.get(contentDocLink.ContentDocumentId);
            Product2 product2Name = product2NameMap.get(contentDocLink.LinkedEntityId);

            if (contentDoc != null && product2Name != null) {
                contentDoc.Title = 'Layout-' + product2Name.Name;
                contentDocumentsToUpdate.add(contentDoc);
            }
        }
        if (!contentDocumentsToUpdate.isEmpty()) {
            update contentDocumentsToUpdate;
        }
    }

	public void saveToExistingFile(Id recordId, ContentDocumentLink contentDocLink, String fieldAPISaveToExisting){
		if(String.isBlank(fieldAPISaveToExisting)){
			return;
		}

		String objectAPIName = recordId.getSObjectType().getDescribe().getName();

		SObject sObjectRecord = SObjectUtility.getInstance().querySObject(
			fieldAPISaveToExisting,
			objectAPIName,
			'Id = \'' + recordId + '\''
		);

		String existingDocumentId = SObjectUtility.getInstance().getRecordFieldValue(sObjectRecord, fieldAPISaveToExisting);
		if(String.isNotEmpty(existingDocumentId)){
			List<ContentDocument> ctDocForDels = new List<ContentDocument>();
			// ไป query ก่อนอีกรอบ เผื่อกรณีมีคนลบ file ไป แต่ไม่ได้มาลบ Id ที่ field
			for (ContentDocument ctDoc : ContentDocumentSelector.getInstance().getByIdSet(new Set<Id>{existingDocumentId})) {
				ctDocForDels.add(
					new ContentDocument(
						Id = ctDoc.Id
					)
				);
			}

			delete ctDocForDels;
		}

		SObject objForUpdate = Schema.getGlobalDescribe().get(objectAPIName).newSObject();
		objForUpdate.put('Id', recordId);
		objForUpdate.put(fieldAPISaveToExisting, contentDocLink.ContentDocumentId);
		update objForUpdate;
	}
}