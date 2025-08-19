public without sharing class ZipUtility {
	public final String MASTER_DATA_RECORDTYPE = Schema.SObjectType.ZipFile__c.getRecordTypeInfosByDeveloperName().get('MasterDataType').getRecordTypeId();
	public final String MERGE_DATA_RECORDTYPE = Schema.SObjectType.ZipFile__c.getRecordTypeInfosByDeveloperName().get('MergeDocumentType').getRecordTypeId();

	public static ZipUtility instance;

	public static ZipUtility getInstance() {
		if (instance == null) {
			instance = new ZipUtility();
		}
		return instance;
	}

	public Map<String, List<Attachment>> createMergeFileWithAttachmentAndImage(
		List<ZipFile__c> zipFileMasters,
		String mergeDocumentRecordType,
		Map<Id, List<ContentVersion>> contentVersionsMapByZipMasterId,
		Set<Id> zipMasterIdHasReplaceImgSet
		// String documentPathName
	) {
		String documentPathName = 'document.xml';
		Map<String, List<Attachment>> attachmentMapByZipMergeId = new Map<String, List<Attachment>>();
		Map<String,String> mapFileNameWithId = new Map<String,String>();
		Map<Id, ZipFile__c> zipFileMergeMapByMasterId = new Map<Id, ZipFile__c>();

		for (ZipFile__c zipFileMaster : zipFileMasters) {
			ZipFile__c zipFileMerge = new ZipFile__c();
			zipFileMerge.Name = zipFileMaster.Name;
			zipFileMerge.RecordTypeId = mergeDocumentRecordType;
			zipFileMergeMapByMasterId.put(zipFileMaster.Id, zipFileMerge);
		}
		if (!zipFileMergeMapByMasterId.isEmpty()) {
			insert zipFileMergeMapByMasterId.values();
		}

		List<Attachment> attachments = AttachmentSelector.getInstance().getByParentIdSet(zipFileMergeMapByMasterId.keySet());
		Map<Id, List<Attachment>> attachmentsMapByZipMasterId = getAttachmentsMapByParentId(attachments);

		List<Attachment> mergeAttachments = new List<Attachment>();
		for (Id zipMasterId : zipFileMergeMapByMasterId.keySet()) {
			Id mergeZipId = zipFileMergeMapByMasterId.get(zipMasterId).Id;
			Attachment relsXMLAttachment;

			List<Attachment> masterAttachments = attachmentsMapByZipMasterId.get(zipMasterId);
			for (Attachment masterAttachment : masterAttachments) {
				Attachment mergeAttachment = new Attachment();
				mergeAttachment.Body = masterAttachment.Body;
				mergeAttachment.Name = masterAttachment.Name;
				mergeAttachment.ParentId = mergeZipId;
				mergeAttachments.add(mergeAttachment);

				if(mergeAttachment.Name == 'word/_rels/' + documentPathName + '.rels'){
					relsXMLAttachment = mergeAttachment;
				}
			}

			// add file image file to folder word/media
			List<String> imageAttachmentNames;
			if(
				contentVersionsMapByZipMasterId.get(zipMasterId) != null && !contentVersionsMapByZipMasterId.get(zipMasterId).isEmpty() &&
				zipMasterIdHasReplaceImgSet.contains(zipMasterId)
			){
				imageAttachmentNames = new List<String>();

				for (ContentVersion imageCtVersion : contentVersionsMapByZipMasterId.get(zipMasterId)) {
					String imageAttachmentName = imageCtVersion.Title + '.' + imageCtVersion.FileExtension;
					Attachment imageAttachment = new Attachment();
					imageAttachment.Body = imageCtVersion.VersionData;
					imageAttachment.Name = 'word/media/' + imageAttachmentName;
					imageAttachment.ParentId = mergeZipId;

					imageAttachmentNames.add(imageAttachmentName);
					mergeAttachments.add(imageAttachment);
				}

				setAttachmentRelsXMLNewBody(relsXMLAttachment, imageAttachmentNames);
			}

			attachmentMapByZipMergeId.put(mergeZipId, mergeAttachments);
		}

		insert mergeAttachments;

		return attachmentMapByZipMergeId;
	}



	public Map<String, List<Attachment>> createMergeFileWithAttachmentAndImage(
		List<ZipFile__c> zipFileMasters,
		String mergeDocumentRecordType,
		// Map<Id, List<ContentVersion>> contentVersionsMapByZipMasterId,
		Map<Id, Map<String, List<ContentVersion>>> contentVersMapByDocPathNameMapByZipMasterId,
		Set<Id> zipMasterIdHasReplaceImgSet
	) {
		String documentPathName = 'document.xml';
		Map<String, List<Attachment>> attachmentMapByZipMergeId = new Map<String, List<Attachment>>();
		Map<String,String> mapFileNameWithId = new Map<String,String>();
		Map<Id, ZipFile__c> zipFileMergeMapByMasterId = new Map<Id, ZipFile__c>();

		for (ZipFile__c zipFileMaster : zipFileMasters) {
			ZipFile__c zipFileMerge = new ZipFile__c();
			zipFileMerge.Name = zipFileMaster.Name;
			zipFileMerge.RecordTypeId = mergeDocumentRecordType;
			zipFileMergeMapByMasterId.put(zipFileMaster.Id, zipFileMerge);
		}
		if (!zipFileMergeMapByMasterId.isEmpty()) {
			insert zipFileMergeMapByMasterId.values();
		}

		List<Attachment> attachments = AttachmentSelector.getInstance().getByParentIdSet(zipFileMergeMapByMasterId.keySet());
		Map<Id, List<Attachment>> attachmentsMapByZipMasterId = getAttachmentsMapByParentId(attachments);

		List<Attachment> mergeAttachments = new List<Attachment>();
		for (Id zipMasterId : zipFileMergeMapByMasterId.keySet()) {
			Id mergeZipId = zipFileMergeMapByMasterId.get(zipMasterId).Id;
			List<String> docPathNames = new List<String>();
			Map<String, Attachment> relsXMLAttachmentMapByDocPathName = new Map<String, Attachment>();
			// Attachment relsXMLAttachment;

			if(
				contentVersMapByDocPathNameMapByZipMasterId != null &&
				contentVersMapByDocPathNameMapByZipMasterId.get(zipMasterId) != null
			){
				for(String docPathName : contentVersMapByDocPathNameMapByZipMasterId.get(zipMasterId).keySet()){
					// docPathName = word/document.xml
					// แต่ format ที่ต้องการคือ word/_rels/document.xml
					List<String> docPathNameSplits = docPathName.split('/');
					docPathNames.add('word/_rels/' + docPathNameSplits.get(docPathNameSplits.size() - 1) + '.rels');
				}
			}

			System.debug('docPathNames: ' + docPathNames);
			List<Attachment> masterAttachments = attachmentsMapByZipMasterId.get(zipMasterId);
			for (Attachment masterAttachment : masterAttachments) {
				Attachment mergeAttachment = new Attachment();
				mergeAttachment.Body = masterAttachment.Body;
				mergeAttachment.Name = masterAttachment.Name;
				mergeAttachment.ParentId = mergeZipId;
				mergeAttachments.add(mergeAttachment);


				if(docPathNames.contains(mergeAttachment.Name)){

					// relsXMLAttachment = mergeAttachment;
					relsXMLAttachmentMapByDocPathName.put(mergeAttachment.Name, mergeAttachment);
				}
			}

			// add file image file to folder word/media
			List<String> imageAttachmentNames;
			if(
				contentVersMapByDocPathNameMapByZipMasterId.get(zipMasterId) != null &&
				!contentVersMapByDocPathNameMapByZipMasterId.get(zipMasterId).isEmpty() &&
				zipMasterIdHasReplaceImgSet.contains(zipMasterId)
			){

				for (String docPathName : contentVersMapByDocPathNameMapByZipMasterId.get(zipMasterId).keySet()) {

					imageAttachmentNames = new List<String>();

					for (ContentVersion imageCtVersion : contentVersMapByDocPathNameMapByZipMasterId.get(zipMasterId).get(docPathName)) {
						String imageAttachmentName = imageCtVersion.Title + '.' + imageCtVersion.FileExtension;
						Attachment imageAttachment = new Attachment();
						imageAttachment.Body = imageCtVersion.VersionData;
						imageAttachment.Name = 'word/media/' + imageAttachmentName;
						imageAttachment.ParentId = mergeZipId;

						imageAttachmentNames.add(imageAttachmentName);
						mergeAttachments.add(imageAttachment);
					}

					List<String> docPathNameSplits = docPathName.split('/');
					String relsPathName = 'word/_rels/' + docPathNameSplits.get(docPathNameSplits.size() - 1) + '.rels';

					setAttachmentRelsXMLNewBody(relsXMLAttachmentMapByDocPathName.get(relsPathName), imageAttachmentNames);
				}

			}

			attachmentMapByZipMergeId.put(mergeZipId, mergeAttachments);
		}

		insert mergeAttachments;

		return attachmentMapByZipMergeId;
	}

	private void setAttachmentRelsXMLNewBody(Attachment relsXMLAttachment, List<String> imageAttachmentNames){
		String relationShipStartTag = '<Relationship ';
		String targetMediaStartTag = 'Target="media/';
		String relsContentXML = relsXMLAttachment.Body.toString();
		List<String> relsCtXMLSplitRelations = relsContentXML.split(relationShipStartTag);
		List<String> newRelsContentXMLs = new List<String>{relsCtXMLSplitRelations.get(0)};
		Integer maxRId;
		String mediaXMLTag;
		String mediaXMLTargetName;
		String mediaXMLRId;

		for (Integer i = 1; i < relsCtXMLSplitRelations.size(); i++) {
			String relsCtXMLSplitRelation = relsCtXMLSplitRelations.get(i);
			Integer rId = Integer.valueOf( (relsCtXMLSplitRelation.split('Id="rId').get(1).split('"').get(0)) );
			if(i == 1){
				maxRId = rId;
			}
			else if(maxRId < rId){
				maxRId = rId;
			}

			if(relsCtXMLSplitRelation.contains(targetMediaStartTag)){
				mediaXMLTag = relationShipStartTag + relsCtXMLSplitRelation;
				mediaXMLRId = 'rId' + rId;
				// image1.jpg
				mediaXMLTargetName = relsCtXMLSplitRelation.split(targetMediaStartTag).get(1).split('"').get(0);
			}

			// ไม่เอาตัวสุดท้าย add มาใน new content เดี๋ยวเอาไว้ add ทีหลังสุด รวมกับ media tag ใหม่
			if(i < relsCtXMLSplitRelations.size() - 1){
				newRelsContentXMLs.add(relationShipStartTag + relsCtXMLSplitRelation);
			}
		}

		List<String> newMediaContent = new List<String>();
		for (Integer i = 0; i < imageAttachmentNames.size(); i++) {
			maxRId++;
			String newMediaXMLRId = 'rId'+ maxRId;

			// System.debug('mediaXMLRId: ' + mediaXMLRId);
			// System.debug('newMediaXMLRId: ' + newMediaXMLRId);
			// System.debug('mediaXMLTargetName: ' + mediaXMLTargetName);
			// System.debug('imageAttachmentNames.get(i): ' + imageAttachmentNames.get(i));

			// <Relationship Id="rId10" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/newName.jpg" />
			newRelsContentXMLs.add(
				mediaXMLTag.replace('</Relationships>', '').replace(mediaXMLRId, newMediaXMLRId).replace(mediaXMLTargetName, imageAttachmentNames.get(i))
			);
		}

		// add ตัวสุดท้าย
		newRelsContentXMLs.add(relationShipStartTag + relsCtXMLSplitRelations.get( relsCtXMLSplitRelations.size()-1 ));

		// set Body ใหม่ที่มี rId ของรูปที่เพิ่มเข้าไปใหม่ ให้ตัว word/_rels/document.xml.rels
		relsXMLAttachment.Body = Blob.valueof( (String.join(newRelsContentXMLs, '')) );
	}

	private Map<Id, List<Attachment>> getAttachmentsMapByParentId(List<Attachment> attachments){
		Map<Id, List<Attachment>> attachmentsMapByParentId = new Map<Id, List<Attachment>>();
		for (Attachment attachment : attachments) {
			if(attachmentsMapByParentId.get(attachment.ParentId) == null){
				attachmentsMapByParentId.put(attachment.ParentId, new List<Attachment>{attachment});
			}
			else{
				attachmentsMapByParentId.get(attachment.ParentId).add(attachment);
			}
		}
		return attachmentsMapByParentId;
	}

	public void deleteZipRecord(Set<Id> recordIdSet){
		// delete file after we are done generate file
		List<ZipFile__c> targetZipFileList = ZipFileSelector.getInstance().getByIdSet(recordIdSet);
		delete targetZipFileList;
	}
}