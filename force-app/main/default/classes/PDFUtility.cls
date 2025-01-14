public with sharing class PDFUtility {
	public static PDFUtility instance;

	public static PDFUtility getInstance() {
		if (instance == null) {
			instance = new PDFUtility();
		}
		return instance;
	}

	public List<ContentDocumentLink> createPdfFileToRecord(
		String pdfPageName,
		Map<Id, String> fileNameMapWithRecordId,
		List<Id> recordIds,
		Map<Id, Id> recordIdToSaveFileMapByRecordId
	) {
		Map<Id, ContentVersion> contentVersionMapByRecordId = new Map<Id, ContentVersion>();

		for (Id recordId : recordIds) {
			String fileName = fileNameMapWithRecordId.get(recordId);

			if(String.isBlank(fileName)){
				fileName = pdfPageName;
			}

			// asynchronous method
			PageReference pdfPage = new PageReference('/apex/' + pdfPageName + '?Id=' + recordId);
			Blob pdfBlob;

			if (Test.isRunningTest()) {
				pdfBlob = blob.valueOf('Unit.Test');
			} else {
				pdfBlob = pdfPage.getContentAsPDF();
			}

			// insert file to ContentVersion
			contentVersionMapByRecordId.put(
				recordId,
				new ContentVersion(
					Title = fileName,
					PathOnClient = fileName + '.pdf',
					VersionData = pdfBlob,
					Origin = 'H'
				)
			);
		}

		ContentDocumentLinkTriggerHandler ctDocLinkTriggerHandler = ContentDocumentLinkTriggerHandler.getInstance();

		ctDocLinkTriggerHandler.setBypass();
		ContentVersionService.getInstance().insertContentVersions(contentVersionMapByRecordId.values());
		ctDocLinkTriggerHandler.clearBypass();

		Map<Id, Id> recordIdMapByContentVerId = new Map<Id, Id>();
		for (Id recordId : contentVersionMapByRecordId.keySet()) {
			recordIdMapByContentVerId.put(contentVersionMapByRecordId.get(recordId).Id, recordId);
		}

		Set<Id> contentVerIdSet = ContentVersionService.getInstance().getContentVerIdSet(contentVersionMapByRecordId);
		List<ContentVersion> contentVersions = ContentVersionSelector.getInstance().getByIdSetNoVersionData(new Set<Id>(contentVerIdSet));

		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		for (ContentVersion contentVersion : contentVersions) {
			Id recordId = recordIdMapByContentVerId.get(contentVersion.Id);
			Id linkEntityId = recordId;
			// กรณีต้องการ insert file ลงใน object อื่น ให้ส่ง Id ของ Object อื่น map กับ record Id ที่สร้าง file มาด้วย
			if(recordIdToSaveFileMapByRecordId != null){
				linkEntityId = recordIdToSaveFileMapByRecordId.get(recordId);
			}

			// insert file to object and file will show on Object in Files Box
			contentDocumentLinks.add(
				new ContentDocumentLink(
					LinkedEntityId = linkEntityId,
					ContentDocumentId = contentVersion.ContentDocumentId
				)
			);
		}

		ctDocLinkTriggerHandler.setBypass();
		ContentDocumentLinkService.getInstance().insertContentDocumentLinks(contentDocumentLinks);
		ctDocLinkTriggerHandler.clearBypass();

		return contentDocumentLinks;
	}

	public String getImageSrc(String htmlString) {
		if(String.isEmpty(htmlString)){
			return '';
		}

		Integer startIndex = htmlString.indexOf('src="') + 5;
		if (startIndex > 4) {
			Integer endIndex = htmlString.indexOf('"', startIndex);
			if (endIndex > startIndex) {
				return(htmlString.substring(startIndex, endIndex).replace('&amp;', '&'));
			}
		}

		return ''; // Return null if src is not found
	}

	public String getContactText(String phone, String email){
		String contact = '';

		if(String.isNotBlank(phone)){
			contact = phone;
		}
		if(String.isNotBlank(email)){
			if(String.isNotBlank(contact)){
				contact += ', ';
			}

			contact += 'Email: ' + email;
		}

		return contact;
	}
}