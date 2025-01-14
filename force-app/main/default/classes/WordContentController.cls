public without sharing class WordContentController {

	@AuraEnabled
	public static List<DocumentDetailWrapper> validateRecordIdtoGetDocumentTemplate(
		String targetRecordId,
		String language,
		String templateMappingType,
		String paramInput
	) {
		String recordId = targetRecordId;

		String objectApiName = ((Id) recordId).getSObjectType().getDescribe().getName();
		String queryField = 'Id';
		String queryCondition = 'Id = '+'\''+ recordId +'\'';
		if(String.isEmpty(language)){
			language = 'TH';
		}

		SObject sObjectRecord = SObjectUtility.getInstance().querySObject(queryField, objectApiName, queryCondition);

		// Objective: To get list of contract document template.
		// create zip(merge template) ที่ copy มาจาก zip(master template) และ return zipId ของ merge template ออกไป
		return  getDocumentTemplateNameList(recordId, objectApiName,sObjectRecord, language, templateMappingType, paramInput);
	}

	@AuraEnabled
	public static Map<String, String> startGenerateDocx(String targetRecordId, String documentDetailString) {
		return WordContentUtility.getInstance().generateDocx(documentDetailString);
	}

	private static List<DocumentDetailWrapper> getDocumentTemplateNameList(
        String recordId,
        String objectApiName,
		SObject sObjectRecord,
		String language,
		String templateMappingType,
		String paramInput
	){
		List<DocumentDetailWrapper> documentDetailList = new List<DocumentDetailWrapper>();
		String runningNumber = '';
		String runningNumberInDoc;

		// Map<String, List<Integer>> rowToRemovesMapByDocTemplateName = new Map<String, List<Integer>>();
		Map<String, DocumentTemplateMapping__mdt> docTemplateMdtMapByDocTemplateName = getDocumentTemplateByCriteria(
			recordId, objectApiName, sObjectRecord, language, templateMappingType, paramInput
		);

		List<NameFormattingMasterData__c> nameFormattingMasterDatas = NameFormattingMasterDataSelector.getInstance().getByObjTypePurposeDocTemplate(
			objectApiName, 'Format', 'Document', templateMappingType
		);
		runningNumber = RunningNumberUtility.getInstance().generateReplacedFormatName(nameFormattingMasterDatas.get(0), recordId, objectApiName);

		// Document template consolidation.
		// ได้ zip file ของ master template มา
		List<ZipFile__c> zipFiles = consolidateTemplateZipFile(recordId, objectApiName, docTemplateMdtMapByDocTemplateName.keySet());

		// Build mapping document running no.
		Map<Id, String> docNameMapWithZipId = new Map<Id, String>();
		for ( ZipFile__c zipFile : zipFiles ) {
			docNameMapWithZipId.put(
				zipFile.Id,
				getDocumentName(docTemplateMdtMapByDocTemplateName.get(zipFile.Name), zipFile.Name, runningNumber)
			);
		}

		// Binding document template with running no. and wrapped up by aura component wrapper
		return documentTemplateAuraWrap(
            recordId,
            objectApiName,
            zipFiles,
            docNameMapWithZipId,
            docTemplateMdtMapByDocTemplateName,
            // rowToRemovesMapByDocTemplateName,
            paramInput
        );
	}

	private static List<DocumentDetailWrapper> documentTemplateAuraWrap(
        String recordId,
        String objectApiName,
		List<ZipFile__c> zipFileList,
		Map<Id, String> docNameMapWithZipId,
		Map<String, DocumentTemplateMapping__mdt> docTemplateMdtMapByDocTemplateName,
		// Map<String, List<Integer>> rowToRemovesMapByDocTemplateName,
		String paramInput
	) {
		List<DocumentDetailWrapper> documentDetailList = new List<DocumentDetailWrapper>();
		ZipFile__c zipFileImageTemplate = new ZipFile__c();

		for ( ZipFile__c eachZipMerge : zipFileList ) {
			DocumentDetailWrapper newDocumentDetailWrapper = new DocumentDetailWrapper();
			newDocumentDetailWrapper.RecordId = recordId;
			newDocumentDetailWrapper.ObjectAPIName = objectAPIName;
			newDocumentDetailWrapper.DocumentId = eachZipMerge.Id; // main template id list
			newDocumentDetailWrapper.DocumentName = eachZipMerge.Name; // main template name list
			newDocumentDetailWrapper.RunningNumber = docNameMapWithZipId?.get(eachZipMerge.Id);
			// newDocumentDetailWrapper.MapDocumentTemplate = docTemplateMdtMapByDocTemplateName;
			newDocumentDetailWrapper.DocumentTemplateMappingMDT = docTemplateMdtMapByDocTemplateName.get(eachZipMerge.Name);
			// newDocumentDetailWrapper.TableRowToRemoves = rowToRemovesMapByDocTemplateName.get(eachZipMerge.Name);
			newDocumentDetailWrapper.ErrorMessage = '';
			newDocumentDetailWrapper.ParamInput = paramInput;
			documentDetailList.add(newDocumentDetailWrapper);
		}
		return documentDetailList;
	}

	private static Map<String, DocumentTemplateMapping__mdt> getDocumentTemplateByCriteria(
		String recordId,
        String objectApiName,
		SObject sObjectRecord,
		String language,
		String templateMappingType,
		String paramInput
		// Map<String, List<Integer>> rowToRemovesMapByDocTemplateName
	) {
		Map<String, DocumentTemplateMapping__mdt> docTemplateMdtMapByDocTemplateName = new Map<String, DocumentTemplateMapping__mdt>();

		List<DocumentTemplateMapping__mdt> docTemplateMdts = DocumentTemplateMappingMDTSelector.getInstance().getByObjAPIAndLangAndTemplateMappingType(
			objectApiName, language, templateMappingType
		);

		List<DocumentTemplateMapping__mdt> docTemplateMdtAfterFilters =  getFilterDocTemplateMdtsByAdditionalCondition(
			recordId,
			objectApiName,
			docTemplateMdts
		);

		for(DocumentTemplateMapping__mdt docTemplateMdtAfterFilter : docTemplateMdtAfterFilters) {
			docTemplateMdtMapByDocTemplateName.put(docTemplateMdtAfterFilter.DocumentTemplateName__c, docTemplateMdtAfterFilter);
		}

		// List<DocumentTemplateMapping__mdt> docTemplateMdts;

		// switch on templateMappingType {
		// 	when 'Contract' {
		// 		docTemplateMdts = DocumentTemplateMappingMDTSelector.getByObjAPIAndLangAndTemplateMappingType(
		// 			objectApiName, language, templateMappingType
		// 		);
		// 	}
		// }

		// if(docTemplateMdts != null) {
			// for(DocumentTemplateMapping__mdt docTemplateMdt : docTemplateMdts) {
			// 	docTemplateMdtMapByDocTemplateName.put(docTemplateMdt.DocumentTemplateName__c, docTemplateMdt);
			// }
		// }

		return docTemplateMdtMapByDocTemplateName;
	}

	private static List<DocumentTemplateMapping__mdt> getFilterDocTemplateMdtsByAdditionalCondition(
		String recordId,
		String objectApiName,
		List<DocumentTemplateMapping__mdt> docTemplateMdts
	){
		Set<String> queryFieldSet = new Set<String>{'Id'};

		List<DocumentTemplateMapping__mdt> noAdditionalConDocTemplateMdts = new List<DocumentTemplateMapping__mdt>();
		for (DocumentTemplateMapping__mdt docTemplateMdt : docTemplateMdts) {
			if(String.isBlank(docTemplateMdt.AdditionalCondition__c)){
				noAdditionalConDocTemplateMdts.add(docTemplateMdt);
			}
			else{
				for(String addConitionfield : docTemplateMdt.AdditionalConditionFields__c.split(',')){
					queryFieldSet.add(addConitionfield.trim());
				}
			}
		}

		SObject sObjectRecord;
		if(queryFieldSet.size() > 1){
			String queryCondition = 'Id = '+'\''+ recordId +'\'';
			List<String> queryFields = new List<String>(queryFieldSet);
			String queryField = String.join(queryFields, ', ');
			sObjectRecord = SObjectUtility.getInstance().querySObject(queryField, objectApiName, queryCondition);
		}

		List<DocumentTemplateMapping__mdt> filterDocTemplateMdts = new List<DocumentTemplateMapping__mdt>();

		for (DocumentTemplateMapping__mdt docTemplateMdt : docTemplateMdts) {
			if(String.isBlank(docTemplateMdt.AdditionalCondition__c)){
				continue;
			}
			else{
				RT_Expression expr = RTExpression.parseRTExpress(docTemplateMdt.AdditionalCondition__c, sObjectRecord);
				if(expr.evalBool()){
					filterDocTemplateMdts.add(docTemplateMdt);
				}
			}
		}

		if(filterDocTemplateMdts.isEmpty()){
			filterDocTemplateMdts.addAll(noAdditionalConDocTemplateMdts);
		}

		return filterDocTemplateMdts;
	}

	private static String getDocumentName(
		DocumentTemplateMapping__mdt currentMetadata,
		String zipFileName,
		String runningNumber
	){
		if(runningNumber.contains(',')){
			runningNumber = runningNumber.replace(',', '[COMMA]');
		}
		if(runningNumber.contains('&')){
			runningNumber = runningNumber.replace('&', '[AMPERSAND]');
		}

		return (String.isBlank(runningNumber)) ? zipFileName : runningNumber;
	}

	public static List<ZipFile__c> consolidateTemplateZipFile(String recordId, String objectApiName, Set<String> templateNameSet) {
		List<ZipFile__c> zipFileMasters = ZipFileSelector.getByNameAndRecordType(templateNameSet, ZipUtility.getInstance().MASTER_DATA_RECORDTYPE);

		return consolidateTemplateZipFile(recordId, objectApiName, zipFileMasters);
	}

	public static List<ZipFile__c> consolidateTemplateZipFile(String recordId, String objectApiName, List<ZipFile__c> zipFileMasters) {
		List<ZipFile__c> zipFileMerges = new List<ZipFile__c>();
		if (!zipFileMasters.isEmpty()) {
			Set<Id> zipMasterIdSet = new Set<Id>();
			for (ZipFile__c zipFileMaster : zipFileMasters) {
				zipMasterIdSet.add(zipFileMaster.Id);
			}

			Set<String> imageTypeSet = new Set<String>{'IMAGELOOPRELATEDOBJECT', 'IMAGEOBJECT'};
			List<WordContentMaster__c> allWordContentMaster = [SELECT Id,ZipFileMasterId__c,FormatType__c FROM WordContentMaster__c];
			List<WordContentMaster__c> wordContentMasters = WordContentMasterSelector.getInstance().getByZipIdSetAndFormatTypeSet(zipMasterIdSet, imageTypeSet);
			Map<String, List<Attachment>> mapFileNameWithAttachment;
			Set<Id> zipMasterIdHasReplaceImgSet = new Set<Id>();
			for (WordContentMaster__c wordContentMaster : wordContentMasters) {
				zipMasterIdHasReplaceImgSet.add(wordContentMaster.ZipFileMasterId__c);
			}

			Map<Id, Map<String, List<ContentVersion>>> contentVersMapByDocPathNameMapByZipMasterId = getContentVersMapByDocPathNameMapByZipMasterId(
				recordId,
				objectApiName,
				wordContentMasters
			);

			mapFileNameWithAttachment = ZipUtility.getInstance().createMergeFileWithAttachmentAndImage(
				zipFileMasters,
				ZipUtility.getInstance().MERGE_DATA_RECORDTYPE,
				contentVersMapByDocPathNameMapByZipMasterId,
				zipMasterIdHasReplaceImgSet
			);



			Set<String> zipFileIdSet = mapFileNameWithAttachment.keySet();
			zipFileMerges = ZipFileSelector.getByIdSetAndRecType(zipFileIdSet, ZipUtility.getInstance().MERGE_DATA_RECORDTYPE);
		}
		return zipFileMerges;
	}



	private static void setImageInitialQuery(
		String recordId,
		String objectApiName,
		List<WordContentMaster__c> wordContentMasters,
		Map<String, SObject> mainSObjRecordMap,
		Map<String, String> imageSObjFieldNameMapWithVal,
		Map<String, List<SObject>> imageRelatedRecordsMapByExternalKey
	) {
		Set<String> mainObjFieldSet = new Set<String>();
		Map<String, List<String>> extKeyMapsByRelatedObjQuery = new Map<String, List<String>>();

		for (WordContentMaster__c wordContentMaster : wordContentMasters) {

			if(wordContentMaster.ObjectToQuery__c == null || wordContentMaster.FieldToQuery__c == null){
				continue;
			}

			switch on wordContentMaster.ObjectToQuery__c {
				when 'Main' {
					for (String field : wordContentMaster.FieldToQuery__c.split(',')) {
						mainObjFieldSet.add(field.trim());
					}
				}
				when else {
					String queryStr = wordContentMaster.FieldToQuery__c + '-' + wordContentMaster.ObjectToQuery__c + '-' + wordContentMaster.ConditionToQuery__c + '-' + wordContentMaster.LookupFieldToQuery__c;
					if(extKeyMapsByRelatedObjQuery.get(queryStr) == null){
						extKeyMapsByRelatedObjQuery.put(queryStr, new List<String> {wordContentMaster.WordContentExternalKey__c});
					}
					else{
						extKeyMapsByRelatedObjQuery.get(queryStr).add(wordContentMaster.WordContentExternalKey__c);
					}
				}
			}
		}

		if(!mainObjFieldSet.isEmpty()){
			SObject sObjectRecord = SObjectUtility.getInstance().querySObject(String.join(mainObjFieldSet, ', '), objectApiName, 'Id = \'' + recordId + '\'');
			mainSObjRecordMap.put('main', sObjectRecord);

			for (String fieldName : mainObjFieldSet) {
				imageSObjFieldNameMapWithVal.put(fieldName, WordContentUtility.getInstance().getFieldValue(SObjectUtility.getInstance().getRecordFieldValue(sObjectRecord, fieldName)));
			}
		}

		for (String relatedObjQuery : extKeyMapsByRelatedObjQuery.keySet()) {
			List<String> relatedObjQuerySplit = relatedObjQuery.split('-');
			List<SObject> sObjectRelatedRecords = SObjectUtility.getInstance().queryRelatedSObjects(
				relatedObjQuerySplit.get(0),
				relatedObjQuerySplit.get(1),
				WordContentUtility.getInstance().getConditionLoopQueryString(relatedObjQuerySplit.get(2), relatedObjQuerySplit.get(3), recordId)
			);

			for (String externalKey : extKeyMapsByRelatedObjQuery.get(relatedObjQuery)) {
				imageRelatedRecordsMapByExternalKey.put(externalKey, sObjectRelatedRecords);
			}
		}
	}

	private static Set<Id> getContentDocumentIdSetFromImage(
		List<WordContentMaster__c> wordContentMasters,
		Map<String, String> imageSObjFieldNameMapWithVal,
		Map<String, List<SObject>> imageRelatedRecordsMapByExternalKey
	) {
		Set<Id> contentDocumentIdSet = new Set<Id>();
		Set<String> linkEntityIdSet = new Set<String>();


		for (WordContentMaster__c wordContentMaster : wordContentMasters) {
			String fieldToQueryEntityId = wordContentMaster.SourceField__c;

			switch on wordContentMaster.ObjectToQuery__c {
				when 'Main' {
					if(String.isEmpty(fieldToQueryEntityId) || String.isEmpty(imageSObjFieldNameMapWithVal.get(fieldToQueryEntityId))){
						continue;
					}

					linkEntityIdSet.add(imageSObjFieldNameMapWithVal.get(fieldToQueryEntityId));
				}
				when else {
					List<SObject> sObjectRelatedRecords = imageRelatedRecordsMapByExternalKey.get(wordContentMaster.WordContentExternalKey__c);

					if(String.isEmpty(fieldToQueryEntityId) || sObjectRelatedRecords.isEmpty()){
						continue;
					}

					for (SObject sObjectRelatedRecord : sObjectRelatedRecords) {
						linkEntityIdSet.add(SObjectUtility.getInstance().getRecordFieldValue(sObjectRelatedRecord, fieldToQueryEntityId));
					}
				}
			}
		}

		if(!linkEntityIdSet.isEmpty()){
			for (ContentDocumentLink ctDocLink : ContentDocumentLinkSelector.getInstance().getByLinkEntityIdSet(linkEntityIdSet)) {
				contentDocumentIdSet.add(ctDocLink.ContentDocumentId);
			}
		}

		return contentDocumentIdSet;
	}

	private static Map<Id, Map<String, List<ContentVersion>>> getContentVersMapByDocPathNameMapByZipMasterId(
		String recordId,
		String objectApiName,
		List<WordContentMaster__c> wordContentMasters
	){
		Map<Id, Map<String, List<ContentVersion>>> contentVersMapByDocPathNameMapByZipMasterId = new Map<Id, Map<String, List<ContentVersion>>>();

		Map<String, SObject> mainSObjRecordMap = new Map<String, SObject>();
		Map<String, String> imageSObjFieldNameMapWithVal = new Map<String, String>();
		Map<String, List<SObject>> imageRelatedRecordsMapByExternalKey = new Map<String, List<SObject>>();
		setImageInitialQuery(recordId, objectApiName, wordContentMasters, mainSObjRecordMap, imageSObjFieldNameMapWithVal, imageRelatedRecordsMapByExternalKey);

		SObject mainSObjRecord = mainSObjRecordMap.get('main');

		Set<Id> ctDocIdSet = getContentDocumentIdSetFromImage(wordContentMasters, imageSObjFieldNameMapWithVal, imageRelatedRecordsMapByExternalKey);
		Map<Id, Map<String, Set<String>>> imagePathSetMapbyDocPathNameMapByZipId = getImagePathSetMapbyDocPathNameMapByZipId(
            wordContentMasters,
			mainSObjRecord,
			imageSObjFieldNameMapWithVal,
            imageRelatedRecordsMapByExternalKey,
            ctDocIdSet
        );

		Set<String> imagefileNameSet = new Set<String>();
		Set<String> imageExtensionSet = new Set<String>();

		for (Id zipMasterId : imagePathSetMapbyDocPathNameMapByZipId.keySet()) {
			for (String docPathName : imagePathSetMapbyDocPathNameMapByZipId.get(zipMasterId).keySet()) {
				for (String imageLoopPath : imagePathSetMapbyDocPathNameMapByZipId.get(zipMasterId).get(docPathName)) {
					imagefileNameSet.add(imageLoopPath.substring(0, imageLoopPath.lastIndexOf('.')));
					imageExtensionSet.add(imageLoopPath.substring((imageLoopPath.lastIndexOf('.') + 1), imageLoopPath.length()));
				}
			}
		}

		Map<String, ContentVersion> ctVersionMapByTitle = new Map<String, ContentVersion>();

		for (ContentVersion contentVersion : ContentVersionSelector.getInstance().getByDocIdAndTitleAndExtensionSet(ctDocIdSet, imagefileNameSet, imageExtensionSet)) {
			ctVersionMapByTitle.put( (contentVersion.Title + '.' + contentVersion.FileExtension), contentVersion );
		}

		for (Id zipMasterId : imagePathSetMapbyDocPathNameMapByZipId.keySet()) {

			contentVersMapByDocPathNameMapByZipMasterId.put(zipMasterId, new Map<String, List<ContentVersion>>());

			for (String docPathName : imagePathSetMapbyDocPathNameMapByZipId.get(zipMasterId).keySet()) {

				contentVersMapByDocPathNameMapByZipMasterId.get(zipMasterId).put(docPathName, new List<ContentVersion>());

				for (String imageLoopPath : imagePathSetMapbyDocPathNameMapByZipId.get(zipMasterId).get(docPathName)) {
					ContentVersion contentVersion = ctVersionMapByTitle.get(imageLoopPath);

					if(contentVersion == null){
						continue;
					}

					contentVersMapByDocPathNameMapByZipMasterId.get(zipMasterId).get(docPathName).add(contentVersion);
				}
			}
		}

		return contentVersMapByDocPathNameMapByZipMasterId;
	}

	private static Map<Id, Map<String, Set<String>>> getImagePathSetMapbyDocPathNameMapByZipId(
		List<WordContentMaster__c> wordContentMasters,
		SObject mainSObjRecord,
		Map<String, String> imageSObjFieldNameMapWithVal,
		Map<String, List<SObject>> imageRelatedRecordsMapByExternalKey,
		Set<Id> ctDocIdSet
	) {

		Map<Id, Map<String, Set<String>>> imagePathSetMapbyDocPathNameMapByZipId = new Map<Id, Map<String, Set<String>>>();

		if(ctDocIdSet.isEmpty()){
			return imagePathSetMapbyDocPathNameMapByZipId;
		}

		Map<String, Set<String>> imagePathSetMapbyDocPathName = new Map<String, Set<String>>();
		for (WordContentMaster__c wordContentMaster : wordContentMasters) {
			List<String> imageKeyToReplaces = wordContentMaster.KeyToReplace__c.split(', ');

			Set<String> imagePathSet = imagePathSetMapbyDocPathName.get(wordContentMaster.DocumentPathName__c);
			if(imagePathSet == null){
				imagePathSet = new Set<String>();
				imagePathSetMapbyDocPathName.put(wordContentMaster.DocumentPathName__c, imagePathSet);
			}

			switch on wordContentMaster.ObjectToQuery__c {
				when 'Main' {
					for (String imageKeyToReplace : imageKeyToReplaces) {
						String imagePathName = WordContentUtility.getInstance().getReplacedSourceTagFileName(imageKeyToReplace, mainSObjRecord);
						imagePathSet.add(imagePathName);
					}
				}
				when else {
					List<SObject> sObjectRelatedRecords = imageRelatedRecordsMapByExternalKey.get(wordContentMaster.WordContentExternalKey__c);

					if(sObjectRelatedRecords.isEmpty()){
						continue;
					}

					for (SObject sObjectRelatedRecord : sObjectRelatedRecords) {
						for (String imageKeyToReplace : imageKeyToReplaces) {
							String imagePathName = WordContentUtility.getInstance().getReplacedSourceTagFileName(imageKeyToReplace, sObjectRelatedRecord);
							imagePathSet.add(imagePathName);
						}
					}
				}
			}

			if(imagePathSetMapbyDocPathNameMapByZipId.get(wordContentMaster.ZipFileMasterId__c) == null){
				imagePathSetMapbyDocPathNameMapByZipId.put(wordContentMaster.ZipFileMasterId__c, imagePathSetMapbyDocPathName);
			}
		}

		return imagePathSetMapbyDocPathNameMapByZipId;
	}
}