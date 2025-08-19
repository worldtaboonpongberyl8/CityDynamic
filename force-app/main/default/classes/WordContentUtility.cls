/*
	* Description: Replace Record's Data for All Syntax in Word and Export Word
	*
	* Modification Log
	* =======================================================================
	* Ver   Date        Author                      				Modification
	* 1.0   06/06/2024  [Beryl8] Kemika Titithantawatch           Initial version

	Limitation:
		1. Can't put Syntax in Syntax

	Example:
		1. Field
			ห้องเลขที่#{FIELD:RoomNumber__c/}#ชั้น#{FIELD: FloorNumberDocument__c/}

		2. Loop related object
			{LOOPRELATEDOBJECT:ContractPeriod__c;LOOKUPFIELD:Contract__c;CONDITION:CalculationMethod__c IN ('Fixed Price', 'Fixed Measurement', 'Fixed Rental Object', 'GP with Min', 'GP on Top', 'GP no Min') ORDER BY Contract__c, Sequence__c;FIELDS:PeriodFromDocument__c, PeriodToDocument__c, RentContractGradingDetailTH__c, RentContractPriceDetailTH__c}
			[NO/]<ORDINAL> [FIELDS:PeriodFromDocument__c/] ถึงวันที่ [FIELDS:PeriodToDocument__c/] [FIELDS:RentContractGradingDetailTH__c/][FIELDS:RentContractPriceDetailTH__c/]
			{/LOOPRELATEDOBJECT}

		3. Image
			{IMAGELOOPRELATEDOBJECT:ContractLineItem__c;LOOKUPFIELD:Contract__c;FIELDS:RentalObject__r.Building__r.BuildingAbbr__c, RentalObject__r.FloorToFloor__r.FloorShortName__c, RentalObject__r.RONameFormula__c}
 			 [
				รูปภาพ ที่ใส่ path รูปไว้ที่ ALT =>
				{SOURCE:ROImage_[FIELDS:RentalObject__r.Building__r.BuildingAbbr__c/]_[FIELDS:RentalObject__r.FloorToFloor__r.FloorShortName__c/]_[FIELDS:RentalObject__r.RONameFormula__c/].jpg/}
			]
			{/IMAGELOOPRELATEDOBJECT}

		4. IFF
			{IFF:ALLFIELDS:IsRenewContract__c, RentalPeriodDayFromStart__c, ContactPosition__c, RentalPeriodForDocument__c;CONDITION: ContactPosition__c!=null}
			{TRUEOUTPUT}
			ระยะเวลาการเช่า : [FIELDS:RentalPeriodForDocument__c/][FIELDS:IsRenewContract__c/] เท่ากับ
			-#[FIELDS:RentalPeriodForDocument__c/][FIELDS:IsRenewContract__c/]
			{/TRUEOUTPUT}
			{FALSEOUTPUT}
			Null
			{/FALSEOUTPUT}
			{/IFF}

			{IFF:ALLFIELDS:;CONDITION:[PARAM_INPUT] == 'Renew'}
			{TRUEOUTPUT}
			1
			{/TRUEOUTPUT}
			{FALSEOUTPUT}
			null
			{/FALSEOUTPUT}
			{/IFF}

		5. Custom Meta Data
			{MDT:ALLFIELDS: BuildingCode__c, SignaturenoforMemo__c;MDTFIELDS: Field1__c, Field3__c}
			ชื่อ [FIELDS: Field1__c/]([FIELDS: Field3__c/])
			[FIELDS: Field1__c/][FIELDS: Field3__c/]
			{/MDT}

		6. REMOVETABLEROWS
			{REMOVETABLEROWS}
			[ TABLE
				No	Subject	Detail
				1.	Subject  111111	Detail 11111
				2.	Subject 2222222	Detail 222222
				3.	Subject 3333333	Detail 333333
				4.	Subject 4444444	Detail 444444
				5.	Subject 5555555	Detail 555555
			]
			{/REMOVETABLEROWS }

		7. <SHIFTWITHPREVIOUSCONTENT> => เพื่อเอาคำไปต่อท้ายบรรทัดก่อนหน้า
			ฉบับลงวันที่
			<SHIFTWITHPREVIOUSCONTENT>
			6 มิถุนายน 2567
*/

public without sharing class WordContentUtility {
	private String recordId;
	private String objectApiName;

	private final String WORD_TAG_START_WP = '<w:p ';
	private final String WORD_TAG_START_WR = '<w:r';
	private final String WORD_TAG_START_WT = '<w:t>';
	private final String WORD_TAG_START_WTR = '<w:tr ';
	private final String WORD_TAG_START_WT_SPACE_PRESERVE = '<w:t xml:space="preserve">';
	private final String WORD_TAG_WBR = '<w:br/>'; // enter tag in word
	private final String WORD_TAG_END_WR = '</w:r>';
	private final String WORD_TAG_END_WP = '</w:p>';
	private final String WORD_TAG_END_WT = '</w:t>';
	private final String WORD_TAG_END_WTR = '</w:tr>';

	private final String TAG_END_FIELD = '/}';
	private final String TAG_START_CONTENT_MASTER = '<!-- {CONTENTMASTER:';
	// private final String TAG_START_REMOVE_TABLE_ROWS = '{REMOVETABLEROWS}';
	// private final String TAG_END_REMOVE_TABLE_ROWS = '{/REMOVETABLEROWS}';

	private final Integer REGEX_MAXLENGTH = 500000;

	private SObject mainSObjRecord;
	private List<String> tempContentForRelatedLoops = new List<String>();
	private List<String> wordPathRelsDocuments = new List<String>();

	public static WordContentUtility instance;

	public static WordContentUtility getInstance() {
		if (instance == null) {
			instance = new WordContentUtility();
		}
		return instance;
	}

	public Map<String, String> generateDocx(String documentDetailString){
		DocumentDetailWrapper documentDetail = (DocumentDetailWrapper)JSON.deserialize(documentDetailString, DocumentDetailWrapper.class);
		recordId = documentDetail.RecordId;
		objectApiName = documentDetail.ObjectAPIName;

		List<ZipFile__c> masterZipFiles = ZipFileSelector.getInstance().getByNameAndRecordType(new Set<String>{ documentDetail.DocumentName }, ZipUtility.getInstance().MASTER_DATA_RECORDTYPE);
		List<ZipFile__c> mergeZipFiles = ZipFileSelector.getInstance().getByIdSetAndRecType(new Set<String>{ documentDetail.DocumentId }, ZipUtility.getInstance().MERGE_DATA_RECORDTYPE);

		Map<String, WordContentMaster__c> wordCtMastersMapByExtKey = new Map<String, WordContentMaster__c>();
		Map<String, String> sObjFieldNameMapWithVal = new Map<String, String>();
		Map<String, List<SObject>> relatedSObjectMapByWCMExtKey = new Map<String, List<SObject>>();
		Map<String, Attachment> attachmentMapByWordPath = new Map<String, Attachment>();
		List<Attachment> attachmentToUpdateContents = new List<Attachment>();
		// Map<String, String> documentFieldValueMapByMDTFieldName = new Map<String, String>();

		setInitialQuery(
			documentDetail,
			masterZipFiles.get(0).Id,
			mergeZipFiles.get(0).Id,
			wordCtMastersMapByExtKey,
			sObjFieldNameMapWithVal,
			relatedSObjectMapByWCMExtKey,
			attachmentMapByWordPath
            // ,
			// documentFieldValueMapByMDTFieldName
		);

		setContentDocument(
			wordCtMastersMapByExtKey,
			sObjFieldNameMapWithVal,
			relatedSObjectMapByWCMExtKey,
			attachmentMapByWordPath,
			attachmentToUpdateContents,
			// documentFieldValueMapByMDTFieldName,
			documentDetail
		);

		if(!attachmentToUpdateContents.isEmpty()){
			update attachmentToUpdateContents;
		}

		return new Map<String, String> { documentDetail.DocumentId => documentDetail.RunningNumber };

		//TODO if want to debug open this comment  ============================================================
		// throw new CustomException('======================= Debug Mode =========================');
	}

	private void setInitialQuery(
		DocumentDetailWrapper documentDetail,
		Id masterZipId,
		Id mergeZipId,
		Map<String, WordContentMaster__c> wordCtMastersMapByExtKey,
		Map<String, String> sObjFieldNameMapWithVal,
		Map<String, List<SObject>> relatedSObjectMapByWCMExtKey,
		Map<String, Attachment> attachmentMapByWordPath
        // ,
		// Map<String, String> documentFieldValueMapByMDTFieldName
	) {
		List<WordContentMaster__c> wordContentMasters = WordContentMasterSelector.getInstance().getByZipId(masterZipId);

		Set<String> mainObjFieldSet = new Set<String>();
		Map<String, List<String>> extKeyMapsByRelatedObjQuery = new Map<String, List<String>>();
		List<String> fieldMappingMDTs = new List<String>();
		Set<String> documentPathSet = new Set<String>();

		for (WordContentMaster__c wordContentMaster : wordContentMasters) {
			wordCtMastersMapByExtKey.put(wordContentMaster.WordContentExternalKey__c, wordContentMaster);
			documentPathSet.add(wordContentMaster.DocumentPathName__c);

			List<String> docPathNameSplits = wordContentMaster.DocumentPathName__c.split('/');
			String relsPathName = 'word/_rels/' + docPathNameSplits.get(docPathNameSplits.size() - 1) + '.rels';
			documentPathSet.add(relsPathName);
			wordPathRelsDocuments.add(relsPathName);

			if(wordContentMaster.ObjectToQuery__c == null || wordContentMaster.FieldToQuery__c == null){
				continue;
			}

			switch on wordContentMaster.ObjectToQuery__c {
				when 'Main' {
					for (String field : wordContentMaster.FieldToQuery__c.split(',')) {
						mainObjFieldSet.add(field.trim().split(':').get(0));
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

			if(wordContentMaster.FormatType__c == 'MDT'){
				fieldMappingMDTs.addAll(wordContentMaster.KeyToReplace__c.split(','));
			}
		}

		if(!mainObjFieldSet.isEmpty()){
			SObject sObjectRecord = SObjectUtility.getInstance().querySObject(String.join(mainObjFieldSet, ', '), objectApiName, 'Id = \'' + recordId + '\'');
			mainSObjRecord = sObjectRecord;
			for (String fieldName : mainObjFieldSet) {
				sObjFieldNameMapWithVal.put(fieldName, getFieldValue(SObjectUtility.getInstance().getRecordFieldValue(sObjectRecord, fieldName)));
			}
		}

		for (String relatedObjQuery : extKeyMapsByRelatedObjQuery.keySet()) {
			List<String> relatedObjQuerySplit = relatedObjQuery.split('-');
			List<SObject> sObjectRelatedRecords = SObjectUtility.getInstance().queryRelatedSObjects(
				relatedObjQuerySplit.get(0),
				relatedObjQuerySplit.get(1),
				getConditionLoopQueryString(relatedObjQuerySplit.get(2), relatedObjQuerySplit.get(3))
			);

			for (String externalKey : extKeyMapsByRelatedObjQuery.get(relatedObjQuery)) {
				relatedSObjectMapByWCMExtKey.put(externalKey, sObjectRelatedRecords);
			}
		}

		List<Attachment> attachments = AttachmentSelector.getInstance().getByParentIdAndNameSet(mergeZipId, documentPathSet);
		for (Attachment attachment : attachments) {
			attachmentMapByWordPath.put(attachment.Name, attachment);
		}

		// Set<String> fieldMappingMDTSet = new Set<String>();
		// for (String fieldMappingMDT : fieldMappingMDTs) {
		// 	fieldMappingMDTSet.add(fieldMappingMDT.trim());
		// }
		// if(!fieldMappingMDTs.isEmpty()){
		// 	setDocumentFieldValueMapByMDTFieldName(documentDetail.DocumentName, fieldMappingMDTSet, documentFieldValueMapByMDTFieldName);
		// }
	}

	public String getConditionLoopQueryString(String conditionToQuery, String lookupFieldToQuery, String targetId){
		recordId = targetId;
		return getConditionLoopQueryString(conditionToQuery, lookupFieldToQuery);
	}

	private String getConditionLoopQueryString(String conditionToQuery, String lookupFieldToQuery){
		String condition = lookupFieldToQuery + ' = \'' + recordId + '\'';

		if(String.isEmpty(conditionToQuery) || conditionToQuery == 'null'){
			return condition;
		}


		String conditionToQueryTrim = conditionToQuery.toLowerCase().trim();
		if(conditionToQueryTrim.startsWith('order by') || conditionToQueryTrim.startsWith('limit') ||
		conditionToQueryTrim.startsWith('group by')){
			condition += ' ' + conditionToQuery;
		}
		else{
			condition += ' AND ' + conditionToQuery;
		}
		return condition;
	}

	private void setContentDocument(
		Map<String, WordContentMaster__c> wordCtMastersMapByExtKey,
		Map<String, String> sObjFieldNameMapWithVal,
		Map<String, List<SObject>> relatedSObjectMapByWCMExtKey,
		Map<String, Attachment> attachmentMapByWordPath,
		List<Attachment> attachmentToUpdateContents,
		// Map<String, String> documentFieldValueMapByMDTFieldName,
		DocumentDetailWrapper documentDetail
	){
		Map<String, String> relationRIdMapByImageName = new Map<String, String>();
		for (String wordPathRelsDocument : wordPathRelsDocuments) {
			relationRIdMapByImageName.putAll(getRelationRIdMapByImageName(attachmentMapByWordPath.get(wordPathRelsDocument)));
		}

		for (String wordPath : attachmentMapByWordPath.keySet()) {
			if(wordPath.startsWith('word/_rels/')){
				continue;
			}

			Attachment attachment = attachmentMapByWordPath.get(wordPath);
			String contentXML = attachment.Body.toString();
			tempContentForRelatedLoops = new List<String>();
			List<Integer> shiftWithPreviousTagIndexs = new List<Integer>();
			List<Integer> removeTableRowStartIndexs = new List<Integer>();
			List<Integer> removeTableRowEndIndexs = new List<Integer>();

			List<String> contents = new List<String> ();
			String previousXML = '';
			Integer splitContentStartIndex = 0;
			Integer splitContentEndIndex = REGEX_MAXLENGTH;
			Decimal splitContentAmount = Math.ceil( (Decimal.valueOf(contentXml.length()) / Decimal.valueOf(REGEX_MAXLENGTH)) );
			Integer wpIndex = 0;
			for (Integer splitContentIndex = 0; splitContentIndex < splitContentAmount; splitContentIndex++) {
				String splitContentXML = getSplitContentXML(splitContentStartIndex, splitContentEndIndex, contentXml, previousXML);
				List<String> contentNoWPs = splitContentXML.split(WORD_TAG_START_WP);
				String lastContentNoWP = contentNoWPs.get( (contentNoWPs.size() - 1) );

				if(lastContentNoWP.endsWith(WORD_TAG_END_WP)){
					previousXML = '';
				}
				// loop สุดท้าย add ทุกตัว
				else if(splitContentIndex < splitContentAmount - 1){
					previousXML = lastContentNoWP;
					contentNoWPs.remove(contentNoWPs.size() - 1);
				}

				for (Integer i = 0; i < contentNoWPs.size(); i++) {
					String contentNoWP = contentNoWPs.get(i);
					String content = WORD_TAG_START_WP + contentNoWP;
					String contentPlainTxt = content.stripHtmlTags();

					if(wpIndex == 0){
						contents.add(contentNoWP);
						wpIndex += 1;
						continue;
					}

					if(contentNoWP.contains(TAG_START_CONTENT_MASTER)) {
						// w14:paraId="4FD4196F" w14:textId="59368358" w:rsidR="002965CE" w:rsidRDefault="002965CE">
						String wpIdTag = contentNoWPs.get(i).split('>').get(0) + '>';

						replaceValueByContentMaster(
							contents,
							contentNoWP.replace(wpIdTag, ''),
							wpIdTag,
							wordCtMastersMapByExtKey,
							sObjFieldNameMapWithVal,
							relatedSObjectMapByWCMExtKey,
							relationRIdMapByImageName,
							// documentFieldValueMapByMDTFieldName,
							documentDetail
						);
					}
					// else if(contentPlainTxt == TAG_START_REMOVE_TABLE_ROWS){

					// 	contents.add(contentNoWP.split(WORD_TAG_END_WP).get(1));

					// 	removeTableRowStartIndexs.add( contents.size()-1 );
					// }
					// else if(contentPlainTxt == TAG_END_REMOVE_TABLE_ROWS){
					// 	List<String> contentNoEndWPs = contentNoWP.split(WORD_TAG_END_WP);
					// 	if(contentNoEndWPs.size() > 1){
					// 		contents.add(contentNoWP.split(WORD_TAG_END_WP).get(1));
					// 	}

					// 	removeTableRowEndIndexs.add( contents.size() );
					// }
					else if(contentPlainTxt.contains('<SHIFTWITHPREVIOUSCONTENT>')){
						shiftWithPreviousTagIndexs.add( (contents.size()-1) );
					}
					else{
						// <w:p w14:paraId="4FD4196F"> <w:r w:rsidRPr="00004F0B"> <w:t> start date: </w:t> </w:r> </w:p>
						contents.add(WORD_TAG_START_WP + contentNoWP);
					}

					wpIndex += 1;
				}

				splitContentStartIndex = splitContentEndIndex;
				splitContentEndIndex += REGEX_MAXLENGTH;
			}

			setShiftWithPreviousContents(contents, shiftWithPreviousTagIndexs);
			// setRemoveTableRowContents(contents, removeTableRowStartIndexs, removeTableRowEndIndexs, documentDetail.TableRowToRemoves);

			attachmentToUpdateContents.add(
				new Attachment(
					Id = attachment.Id,
					Body = Blob.valueOf(String.join(contents, ''))
				)
			);
		}
	}

	// private void setRemoveTableRowContents(
	// 	List<String> contents,
	// 	List<Integer> removeTableRowStartIndexs,
	// 	List<Integer> removeTableRowEndIndexs,
	// 	List<Integer> rowToRemoves
	// ){
	// 	if(rowToRemoves == null || rowToRemoves.isEmpty()){
	// 		return;
	// 	}

	// 	for (Integer startRmContentIndex = 0; startRmContentIndex < removeTableRowStartIndexs.size(); startRmContentIndex++) {
	// 		String tableXMLTag = '';
	// 		Integer removeTableRowStartIndex = removeTableRowStartIndexs.get(startRmContentIndex);
	// 		for (Integer i = removeTableRowStartIndex; i < removeTableRowEndIndexs.get(startRmContentIndex); i++) {
	// 			tableXMLTag += contents.get(i);
	// 			contents[i] = '';
	// 		}

	// 		String tableAfterRomoveRow = getRemoveTbRows(rowToRemoves, tableXMLTag);
	// 		contents[removeTableRowStartIndex] = tableAfterRomoveRow;
	// 	}
	// }

	// private String getRemoveTbRows(List<Integer> rowToRemoves, String tableXMLTag){
	// 	List<String> tableContents = new List<String>();
	// 	List<String> contentNoWTRs = tableXMLTag.split(WORD_TAG_START_WTR);
	// 	tableContents.add(contentNoWTRs.get(0));

	// 	Integer rowToRemoveIndex = 0;
	// 	for (Integer i = 1; i < contentNoWTRs.size(); i++) {
	// 		if(i == rowToRemoves.get(rowToRemoveIndex)){
	// 			if(rowToRemoveIndex < rowToRemoves.size() - 1){
	// 				rowToRemoveIndex++;
	// 			}
	// 			if(i == contentNoWTRs.size() - 1){
	// 				tableContents.add(contentNoWTRs.get(i).split(WORD_TAG_END_WTR).get(1));
	// 			}
	// 			continue;
	// 		}
	// 		else{
	// 			tableContents.add(WORD_TAG_START_WTR + contentNoWTRs.get(i));
	// 		}
	// 	}
	// 	return String.join(tableContents, '');
	// }

	private void setShiftWithPreviousContents(List<String> contents, List<Integer> shiftWithPreviousTagIndexs){
		for (Integer shiftWithPreviousTagIndex : shiftWithPreviousTagIndexs) {
			String previousContent = contents.get(shiftWithPreviousTagIndex);
			Integer nextContentIndex = shiftWithPreviousTagIndex + 1;
			String nextContent = contents.get(nextContentIndex);
			if(
				nextContentIndex >= contents.size() && (String.isBlank(previousContent) || String.isBlank(nextContent))
				|| !nextContent.startsWith(WORD_TAG_START_WP) || !previousContent.endsWith(WORD_TAG_END_WP)
			){
				continue;
			}
			contents[shiftWithPreviousTagIndex] = contents.get(shiftWithPreviousTagIndex).replace(WORD_TAG_END_WP, '');

			List<String> nextContentNoWPs = nextContent.split(WORD_TAG_START_WP);
			String wpTag = (WORD_TAG_START_WP + (nextContentNoWPs.get(1).split('>').get(0) + '>'));
			contents[nextContentIndex] = nextContent.replace(wpTag, '');
		}
	}

	private string getSplitContentXML(Integer startIndex, Integer endIndex, String fullContentXML, String previousXML){
		String result = '';

		if(!String.isEmpty(previousXML)){
			result += previousXML;
		}
		if(endIndex > fullContentXML.length()){
			endIndex = fullContentXML.length();
		}

		result += fullContentXML.substring(startIndex, endIndex);
		return result;
	}

	// private Map<String, String> setDocumentFieldValueMapByMDTFieldName(String documentName, Set<String> fieldMappingMDTSet, Map<String, String> documentFieldValueMapByMDTFieldName) {
	// 	// Map<String, String> documentFieldValueMapByMDTFieldName = new Map<String, String>();
	// 	List<DocumentFieldMapping__mdt> matchList = new List<DocumentFieldMapping__mdt>();

	// 	Map<String, String> mdtConditionFieldMap = new Map<String, String> {
	// 		'Building__c' => 'BuildingCode__c'
	// 	};

	// 	// Custom Meta Data: Document Field Template
	// 	List<String> query = new List<String> {
	// 		'SELECT Id, Building__c, AdditionalCondition__c, Documents__c, ' + String.join(new List<String>(fieldMappingMDTSet), ','),
	// 		'FROM DocumentFieldMapping__mdt'
	// 	};

	// 	List<DocumentFieldMapping__mdt> documentFieldMappings = Database.query(String.join(query, ' '));

	// 	for ( DocumentFieldMapping__mdt documentFieldMapping: documentFieldMappings ) {
	// 		if(documentFieldMapping.Documents__c == null || !documentFieldMapping.Documents__c.contains(documentName)){
	// 			continue;
	// 		}

	// 		Boolean isMatch = true;
	// 		for ( String mdtFieldName: mdtConditionFieldMap.keySet() ) {
	// 			if ( !isMatch ) break;
	// 			// Matching
	// 			isMatch = isMatch && isMetadataMatchObject(
	// 				(String) documentFieldMapping.get(mdtFieldName),
	// 				(String) mainSObjRecord.get(mdtConditionFieldMap.get(mdtFieldName))
	// 			);
	// 		}
	// 		// Collect match meta data from additional condition
	// 		if ( isMatch ) {
	// 			if ( documentFieldMapping.AdditionalCondition__c != null ) {
	// 				// Additional criteria
	// 				RT_Expression expression = RTExpression.parseRTExpress(
	// 					documentFieldMapping.AdditionalCondition__c,
	// 					mainSObjRecord
	// 				);
	// 				if ( expression.evalBool() ) {
	// 					matchList.add(documentFieldMapping);
	// 					break;
	// 				}
	// 			} else {
	// 				matchList.add(documentFieldMapping);
	// 				break;
	// 			}
	// 		}
	// 	}

	// 	if ( matchList.size() > 0 ) {
	// 		DocumentFieldMapping__mdt matchMDT = matchList.remove(0);
	// 		for ( String fieldMappingMDT : fieldMappingMDTSet ) {
	// 			documentFieldValueMapByMDTFieldName.put(fieldMappingMDT,  getFieldValue((String) matchMDT.get(fieldMappingMDT)));
	// 		}
	// 	}

	// 	return documentFieldValueMapByMDTFieldName;
	// }

	// private Boolean isMetadataMatchObject(String a, String b) {
	// 	return String.isEmpty(a) || a == b;
	// }

	private Map<String, String> getRelationRIdMapByImageName(Attachment relsAttachment){
		Map<String, String> relationRIdMapByImageName = new Map<String, String>();

		if(relsAttachment == null){
			return relationRIdMapByImageName;
		}

		String contentRelsXML = relsAttachment.Body.toString();
		String relationShipStartTag = '<Relationship ';
		String targetMediaStartTag = 'Target="media/';
		List<String> ctRelsXMLSplitRelations = contentRelsXML.split(relationShipStartTag);

		for (Integer i = 1; i < ctRelsXMLSplitRelations.size(); i++) {
			String ctRelsXMLSplitRelation = ctRelsXMLSplitRelations.get(i);
			if(!ctRelsXMLSplitRelation.contains(targetMediaStartTag)){
				continue;
			}
			// 7
			String rId = (ctRelsXMLSplitRelation.split('Id="rId').get(1).split('"').get(0));
			// ROImage_SD_6_0610.jpg
			String mediaXMLTargetName = ctRelsXMLSplitRelation.split(targetMediaStartTag).get(1).split('"').get(0);
			// ROImage_SD_6_0610.jpg => rId7
			relationRIdMapByImageName.put( mediaXMLTargetName, ('rId' + rId) );
		}

		return relationRIdMapByImageName;
	}

	private void replaceValueByContentMaster(
		List<String> contents,
		String contentNoWP,
		String wpIdTag,
		Map<String, WordContentMaster__c> wordCtMastersMapByExtKey,
		Map<String, String> sObjFieldNameMapWithVal,
		Map<String, List<SObject>> relatedSObjectMapByWCMExtKey,
		Map<String, String> relationRIdMapByImageName,
		// Map<String, String> documentFieldValueMapByMDTFieldName,
		DocumentDetailWrapper documentDetail
	){
		String externalKey = contentNoWP.split('<!-- \\{CONTENTMASTER:').get(1).split('\\} -->').get(0);
		String externalKeyTag = '<!-- {CONTENTMASTER:' + externalKey + '} -->';
		WordContentMaster__c wcm = wordCtMastersMapByExtKey.get(externalKey);

		// ใช้ WORD_TAG_END_WR เพราะว่ามีกรณีที่ใช้ tag ต่างกัน <w:r Id=aaaa> และ <w:r> เลยใช้ end tag แทน start tag
		contentNoWP = contentNoWP.replace(externalKeyTag, '');

		switch on wcm.FormatType__c {
			when 'FIELD' {
				replaceFormatFieldValueToContents(contentNoWP, contents, wpIdTag, sObjFieldNameMapWithVal);
			}
			when 'LOOPRELATEDOBJECT' {
				replaceFormatRelatedObjValueToContents(contentNoWP, contents, wpIdTag, relatedSObjectMapByWCMExtKey.get(externalKey));
			}
			when 'IMAGELOOPRELATEDOBJECT' {
				replaceFormatImageRelatedObjValueToContents(contentNoWP, contents, wpIdTag, relatedSObjectMapByWCMExtKey.get(externalKey), relationRIdMapByImageName);
			}
			when 'IMAGEOBJECT' {
				replaceFormatImageObjValueToContents(contentNoWP, contents, wpIdTag, relatedSObjectMapByWCMExtKey.get(externalKey), relationRIdMapByImageName);
			}
			when 'IFF' {
				replaceFormatIFFValueToContents(contentNoWP, contents, wpIdTag, sObjFieldNameMapWithVal, wcm, documentDetail.ParamInput);
			}
			// when 'MDT' {
			// 	replaceFormatMDTValueToContents(contentNoWP, contents, wpIdTag, documentFieldValueMapByMDTFieldName);
			// }
		}
	}

	private void replaceFormatFieldValueToContents(String contentNoWP, List<String> contents, String wpIdTag, Map<String, String> sObjFieldNameMapWithVal){
		// <w:p w14:paraId="4FD4196F" w14:textId="59368358" w:rsidR="002965CE" w:rsidRDefault="002965CE">
		contents.add(WORD_TAG_START_WP + wpIdTag);

		setReplaceFieldValueToContents(
			contentNoWP,
			contents,
			'{',
			'}',
			'{FIELD:',
			1,
			sObjFieldNameMapWithVal,
			null
		);
	}

	private void replaceFormatRelatedObjValueToContents(
		String contentNoWP,
		List<String> contents,
		String wpIdTag,
		List<SObject> sObjectRecords
	){
		String contentPlainTxt = (WORD_TAG_START_WP + wpIdTag + contentNoWP).stripHtmlTags();
		if( contentPlainTxt.contains('{LOOPRELATEDOBJECT:')){
			return;
		}
		if(contentPlainTxt.contains('{/LOOPRELATEDOBJECT}')){
			replaceFormatRelatedValueWithTempLoops(contents, sObjectRecords);
			// add last tag and reset tempContentForRelatedLoops
			addLastContentWhenEndLoopAndResetTempLoop(contentNoWP, contents);
		}
		else{
			tempContentForRelatedLoops.add(WORD_TAG_START_WP + wpIdTag + contentNoWP);
		}
	}

	public String getFieldValue(String fieldValue){
		return (fieldValue == null || fieldValue == 'null') ? '' : fieldValue.replace('&','&amp;');
	}

	private void setReplaceFieldValueToContents(
		String contentNoWP,
		List<String> contents,
		String replaceStartTag,
		String replaceEndTag,
		String replaceFieldStartTag,
		Integer noIndex,
		Map<String, String> fieldNameMapWithVal,
		SObject sObjectRecord
	){
		List<String> contentNoWPNoWRs = contentNoWP.split(WORD_TAG_END_WR);
		String tagToReplaceTxt = '';
		Boolean hasStartReplaceTag = false;
		String tagForReplaceContent = '';
		String startTagPlainText = '';
		String ordinalTag = '';
		Boolean hasStartOrdinalTag = false;
		String noForOrdinalTxt;

		for (Integer i = 0; i < contentNoWPNoWRs.size(); i++) {
			String contentNoWPNoWR = contentNoWPNoWRs.get(i);

			if(i == contentNoWPNoWRs.size() - 1){
				contents.add(contentNoWPNoWR);
				break;
			}

			String plainTxt = (contentNoWPNoWR + WORD_TAG_END_WR).stripHTMLTags();

			if(plainTxt.contains('<')){
				hasStartOrdinalTag = true;
			}
			if(hasStartOrdinalTag){
				ordinalTag += plainTxt;
			}

			if(ordinalTag == '<ORDINAL>'){
				contents.add((contentNoWPNoWR + WORD_TAG_END_WR).replace(plainTxt.escapeHtml4(), NumberUtility.getInstance().getOrdinalNumber(noForOrdinalTxt)));

				ordinalTag = '';
				hasStartOrdinalTag = false;
				continue;
			}

			if(hasStartOrdinalTag){
				continue;
			}

			if(plainTxt.contains(replaceStartTag)){
				hasStartReplaceTag = true;
				// <w:r w:rsidRPr="00004F0B"> <w:t> start date </w:t> </w:r>
				tagForReplaceContent = contentNoWPNoWR + WORD_TAG_END_WR;
				startTagPlainText = plainTxt;
			}

			if(hasStartReplaceTag){
				// [FIELD: ContractStartDate]
				tagToReplaceTxt += plainTxt;
			}
			else{
				// <w:r w:rsidRPr="00004F0B"> <w:t> start date </w:t> </w:r>
				contentNoWPNoWR = getTagPreserveForSpace(contentNoWPNoWR.replace('#', ' '));
				contents.add(contentNoWPNoWR + WORD_TAG_END_WR);
			}

			if(plainTxt.contains(replaceEndTag)){
				List<String> tagToReplaceSplitEndTags = tagToReplaceTxt.split(replaceEndTag);

				String valueForReplace = '';
				String valueBeforeField = '';
				for (Integer tagToReplaceSplitEndTagIndex = 0; tagToReplaceSplitEndTagIndex < tagToReplaceSplitEndTags.size(); tagToReplaceSplitEndTagIndex++) {
					String tagToReplaceSplitEndTag = tagToReplaceSplitEndTags.get(tagToReplaceSplitEndTagIndex);

					if(tagToReplaceSplitEndTagIndex == tagToReplaceSplitEndTags.size() && !tagToReplaceTxt.endsWith(replaceEndTag)){
						hasStartReplaceTag = true;
						tagToReplaceTxt += tagToReplaceSplitEndTag;
						continue;
					}

					if(tagToReplaceSplitEndTag.contains(replaceFieldStartTag) && tagToReplaceSplitEndTag.endsWith('/')){
						if(!tagToReplaceSplitEndTag.startsWith(replaceStartTag)){
							valueBeforeField = tagToReplaceSplitEndTag.split( ('\\' + replaceFieldStartTag) ).get(0);
							if(valueBeforeField != '#'){
								tagToReplaceSplitEndTag = tagToReplaceSplitEndTag.replace(valueBeforeField, '');
							}
							valueForReplace += valueBeforeField;
						}

						String fieldToQuery = tagToReplaceSplitEndTag.replace(replaceFieldStartTag, '').replace('/', '').trim();
						List<String> fieldFormats = new List<String>();

						if(fieldToQuery.contains(':')){
							fieldFormats = fieldToQuery.split(':');
							fieldToQuery = fieldFormats.get(0);
						}

						fieldToQuery = fieldToQuery.replace('#', '');

						String fieldValue;
						if(fieldNameMapWithVal == null){
							fieldValue = getFieldValue(SObjectUtility.getInstance().getRecordFieldValue(sObjectRecord, fieldToQuery));
						}
						else{
							fieldValue = fieldNameMapWithVal.get(fieldToQuery);
						}

						if(!fieldFormats.isEmpty()){
							fieldValue = getFieldByFormat(fieldToQuery, fieldFormats, fieldValue);
						}

						valueForReplace += fieldValue;
						hasStartReplaceTag = false;
						tagToReplaceTxt = '';

						noForOrdinalTxt = fieldValue;
					}
					else if(tagToReplaceSplitEndTag.contains('[NO/')){
						if(!tagToReplaceSplitEndTag.startsWith(replaceStartTag)){
							valueBeforeField = tagToReplaceSplitEndTag.split('[NO/').get(0);
							tagToReplaceSplitEndTag = tagToReplaceSplitEndTag.replace(valueBeforeField, '');
							valueForReplace += valueBeforeField;
						}

						valueForReplace += noIndex;
						hasStartReplaceTag = false;
						tagToReplaceTxt = '';

						noForOrdinalTxt = String.valueOf(noIndex);
					}
					else{
						if(tagToReplaceSplitEndTag.contains(replaceStartTag)){
							hasStartReplaceTag = true;
							tagToReplaceTxt += tagToReplaceSplitEndTag;
						}
						// valueAfterField
						else{
							valueForReplace += tagToReplaceSplitEndTag;
						}
					}
				}

				valueForReplace = valueForReplace.replace('#', ' ').replace('~', '');
				contents.add(
					getTagPreserveForSpace(
						tagForReplaceContent.replace(startTagPlainText, valueForReplace)
					)
				);

				if(!hasStartReplaceTag){
					startTagPlainText = '';
					tagToReplaceTxt = '';
				}
			}
		}
	}

	private String getFieldByFormat(String fieldToQuery, List<String> fieldFormats, String fieldValue){
		String formatting = '';
		String formatType = fieldFormats.get(1);
		if(fieldFormats.size() != 3 && (formatType == 'FORMATDATE' || formatType == 'FORMATDATETH')){
			throw new CustomException('Wrong Format Type: ' + formatType + ' at Field: ' + fieldToQuery);
		}
		if(fieldFormats.size() == 3){
			formatting = fieldFormats.get(2);
		}

		switch on formatType {
			when 'FORMATDATE' {
				return DateUtility.getInstance().toDateString(formatting, fieldValue);
			}
			when 'FORMATDATETH' {
				return DateUtility.getInstance().toDateTHString(formatting, fieldValue);
			}
			when 'FORMATCURRENTCY' {
				return NumberUtility.getInstance().setDecToFormatCommaTwoDigits(fieldValue);
			}
			when 'FORMATCURRENTCYTEXT' {
				return CurrencyUtility.getInstance().getText(fieldValue, formatting);
			}
			when else {
				return '';
			}
		}
	}

	private void replaceFormatRelatedValueWithTempLoops(
		List<String> contents,
		List<SObject> sObjectRecords
	){
		if(sObjectRecords == null || sObjectRecords.isEmpty()){
			return;
		}
		Integer noIndex = 1;
		String noForOrdinalTxt;

		for (SObject sObjectRecord : sObjectRecords) {
			for (Integer tempLoopIndex = 0; tempLoopIndex < tempContentForRelatedLoops.size(); tempLoopIndex++) {
				String tempContentXML = tempContentForRelatedLoops.get(tempLoopIndex);
				List<String> contentNoWPs = tempContentXML.split(WORD_TAG_START_WP);
				// <w:p w14:paraId="4FD4196F" w14:textId="59368358" w:rsidR="002965CE" w:rsidRDefault="002965CE">
				String wpTag = (WORD_TAG_START_WP + (contentNoWPs.get(1).split('>').get(0) + '>'));
				String contentForLoop = (tempContentXML.replace(wpTag, ''));

				contents.add(wpTag);

				setReplaceFieldValueToContents(
					contentForLoop,
					contents,
					'[',
					']',
					'[FIELDS:',
					noIndex,
					null,
					sObjectRecord
				);
			}
			noIndex++;
		}
	}

	private void addLastContentWhenEndLoopAndResetTempLoop(
		String contentNoWP,
		List<String> contents
	){
		List<String> contentNoWPSplitEndWP = contentNoWP.split(WORD_TAG_END_WP);
		if(contentNoWPSplitEndWP.size() > 1 && String.isNotEmpty(contentNoWPSplitEndWP.get(1))){
			contents.add(contentNoWPSplitEndWP.get(1));
		}

		tempContentForRelatedLoops = new List<String>();
	}

	private void replaceFormatImageRelatedObjValueToContents(
		String contentNoWP,
		List<String> contents,
		String wpIdTag,
		List<SObject> sObjectRecords,
		Map<String, String> relationRIdMapByImageName
	){
		String contentPlainTxt = (WORD_TAG_START_WP + wpIdTag + contentNoWP).stripHtmlTags();
		if( contentPlainTxt.contains('{IMAGELOOPRELATEDOBJECT:')){
			return;
		}
		if(contentPlainTxt.contains('{/IMAGELOOPRELATEDOBJECT}')){
			replaceFormatImageRelatedValueWithTempLoops(contents, sObjectRecords, relationRIdMapByImageName);
			// add last tag and reset tempContentForRelatedLoops
			addLastContentWhenEndLoopAndResetTempLoop(contentNoWP, contents);
		}
		else{
			tempContentForRelatedLoops.add(WORD_TAG_START_WP + wpIdTag + contentNoWP);
		}
	}

	private void replaceFormatImageRelatedValueWithTempLoops(
		List<String> contents,
		List<SObject> sObjectRecords,
		Map<String, String> relationRIdMapByImageName
	){

		if(sObjectRecords == null || sObjectRecords.isEmpty()){
			return;
		}

		for (SObject sObjectRecord : sObjectRecords) {
			for (Integer i = 0; i < tempContentForRelatedLoops.size(); i++) {
				String tempContentXML = tempContentForRelatedLoops.get(i);

				if(tempContentXML.contains('{SOURCE:')){
					String fieldPathWithTag = tempContentXML.split('\\{SOURCE:').get(1).split('/}').get(0);
					String imagePathName = getReplacedSourceTagFileName(fieldPathWithTag, sObjectRecord);
					String rIdForReplace = relationRIdMapByImageName.get(imagePathName);
					if(rIdForReplace != null){
						String originRIdTag = '<a:blip r:embed="rId' + tempContentXML.split('<a:blip r:embed="rId').get(1).split('"').get(0);
						contents.add( (tempContentXML.replace(originRIdTag , ('<a:blip r:embed="' + rIdForReplace))) );
					}
				}

				// if(tempContentXML.contains('{SOURCE:')){
				// 	String fieldPathWithTag = tempContentXML.split('\\{SOURCE:').get(1).split('/}').get(0);
				// 	String imagePathName = getReplacedSourceTagFileName(fieldPathWithTag, sObjectRecord);
				// 	String rIdForReplace = relationRIdMapByImageName.get(imagePathName);
				// 	if(rIdForReplace != null){
				// 		String originRIdTag = '<a:blip r:embed="rId' + tempContentXML.split('<a:blip r:embed="rId').get(1).split('"').get(0);
				// 		contents.add( (tempContentXML.replace(originRIdTag , ('<a:blip r:embed="' + rIdForReplace))) );
				// 	}
				// }
				// else{
				// 	String contentPlainTxt = (tempContentXML).stripHtmlTags();
				// 	if(contentPlainTxt.contains('[FIELDS:')){
				// 		// TODO ในกรณีที่อยากให้มีคำใต้รูปที่ต้อง replace ค่า ให้มาทำเพิ่มตรงนี้
				// 	}
				// 	else{
				// 		contents.add(tempContentXML);
				// 	}
				// }
			}
		}
	}

	private void replaceFormatImageObjValueToContents(
		String contentNoWP,
		List<String> contents,
		String wpIdTag,
		List<SObject> sObjectRecords,
		Map<String, String> relationRIdMapByImageName
	){
		String contentPlainTxt = (WORD_TAG_START_WP + wpIdTag + contentNoWP).stripHtmlTags();
		if( contentPlainTxt.contains('{IMAGEOBJECT:')){
			return;
		}
		if(contentPlainTxt.contains('{/IMAGEOBJECT}')){
			replaceFormatImageValueWithTempLoops(contents, relationRIdMapByImageName);
			// add last tag and reset tempContentForRelatedLoops
			addLastContentWhenEndLoopAndResetTempLoop(contentNoWP, contents);
		}
		else{
			tempContentForRelatedLoops.add(WORD_TAG_START_WP + wpIdTag + contentNoWP);
		}
	}

	private void replaceFormatImageValueWithTempLoops(
		List<String> contents,
		Map<String, String> relationRIdMapByImageName
	){
		for (Integer i = 0; i < tempContentForRelatedLoops.size(); i++) {
			String tempContentXML = tempContentForRelatedLoops.get(i);

			if(tempContentXML.contains('{SOURCE:')){
				String fieldPathWithTag = tempContentXML.split('\\{SOURCE:').get(1).split('/}').get(0);
				String imagePathName = getReplacedSourceTagFileName(fieldPathWithTag, mainSObjRecord);
				String rIdForReplace = relationRIdMapByImageName.get(imagePathName);
				if(rIdForReplace != null){
					String originRIdTag = '<a:blip r:embed="rId' + tempContentXML.split('<a:blip r:embed="rId').get(1).split('"').get(0);
					contents.add( (tempContentXML.replace(originRIdTag , ('<a:blip r:embed="' + rIdForReplace))) );
				}
			}
		}
	}

	private void replaceFormatIFFValueToContents(
		String contentNoWP,
		List<String> contents,
		String wpIdTag,
		Map<String, String> sObjFieldNameMapWithVal,
		WordContentMaster__c wcm,
		String paramInput
	){
		String contentPlainTxt = (WORD_TAG_START_WP + wpIdTag + contentNoWP).stripHtmlTags();

		if( contentPlainTxt.contains('{IFF:') ){
			RT_Expression expr;

			if(wcm.KeyToReplace__c.contains('[PARAM_INPUT]')){
				Map<String, Object> exprParmMap = new Map<String, Object>{
					'PARAM_INPUT' => paramInput
				};
				expr = new RT_Expression(wcm.KeyToReplace__c.replace('[PARAM_INPUT]', 'PARAM_INPUT'), exprParmMap);
			}
			else{
				expr = RTExpression.parseRTExpress(wcm.KeyToReplace__c, mainSObjRecord);
			}
			// add evaluate result(true or false) at index 0
			tempContentForRelatedLoops.add( String.valueOf(expr.evalBool()) );
			return;
		}
		else if(contentPlainTxt.contains('{/IFF}')){
			replaceFormatIFFValueWithTempLoops(contents, sObjFieldNameMapWithVal);
			// add last tag and reset tempContentForRelatedLoops
			addLastContentWhenEndLoopAndResetTempLoop(contentNoWP, contents);
		}
		else{
			tempContentForRelatedLoops.add(WORD_TAG_START_WP + wpIdTag + contentNoWP);
		}
	}

	private void replaceFormatIFFValueWithTempLoops(List<String> contents, Map<String, String> sObjFieldNameMapWithVal){
		List<String> resultIFFLoops = new List<String>();
		String result = tempContentForRelatedLoops.get(0);

		Boolean isStartAddLoop = false;
		for (Integer tempLoopIndex = 1; tempLoopIndex < tempContentForRelatedLoops.size(); tempLoopIndex++) {
			String tempContentXML = tempContentForRelatedLoops.get(tempLoopIndex);
			String contentPlainTxt = tempContentXML.stripHtmlTags();
			if(
				(result == 'true' && contentPlainTxt.contains('{TRUEOUTPUT}')) ||
				(result == 'false' && contentPlainTxt.contains('{FALSEOUTPUT}'))
			){
				isStartAddLoop = true;
				continue;
			}
			if(isStartAddLoop){
				if(contentPlainTxt.contains('{/TRUEOUTPUT}') || contentPlainTxt.contains('{/FALSEOUTPUT}')){
					break;
				}
				if(contentPlainTxt.toLowerCase().contains('null')){
					break;
				}
				resultIFFLoops.add(tempContentXML);
			}
		}

		for (Integer i = 0; i < resultIFFLoops.size(); i++) {
			String tempContentXML = resultIFFLoops.get(i);
			List<String> contentNoWPs = tempContentXML.split(WORD_TAG_START_WP);
			// <w:p w14:paraId="4FD4196F" w14:textId="59368358" w:rsidR="002965CE" w:rsidRDefault="002965CE">
			String wpTag = (WORD_TAG_START_WP + (contentNoWPs.get(1).split('>').get(0) + '>'));
			String contentForLoop = (tempContentXML.replace(wpTag, ''));

			contents.add(wpTag);

			setReplaceFieldValueToContents(
				contentForLoop,
				contents,
				'[',
				']',
				'[FIELDS:',
				1,
				sObjFieldNameMapWithVal,
				null
			);
		}
	}

	// private Boolean isLastContentTagPreserveForSpace(String contentNoWPNoWR){
	// 	return contentNoWPNoWR.contains((WORD_TAG_START_WT + ' ')) || contentNoWPNoWR.contains((' ' + WORD_TAG_END_WT));
	// }

	private String getTagPreserveForSpace(String contentNoWPNoWR){
		if( contentNoWPNoWR.contains((WORD_TAG_START_WT + ' ')) || contentNoWPNoWR.contains((' ' + WORD_TAG_END_WT)) ){
			return contentNoWPNoWR.replace( WORD_TAG_START_WT, WORD_TAG_START_WT_SPACE_PRESERVE );
		}
		return contentNoWPNoWR;
	}

    // TODO ปรับให้ MDT Dynamic
	// private void replaceFormatMDTValueToContents(
	// 	String contentNoWP,
	// 	List<String> contents,
	// 	String wpIdTag,
	// 	// Map<String, String> documentFieldValueMapByMDTFieldName
	// ){
	// 	String contentPlainTxt = (WORD_TAG_START_WP + wpIdTag + contentNoWP).stripHtmlTags();
	// 	if( contentPlainTxt.contains('{MDT:')){
	// 		return;
	// 	}
	// 	if(contentPlainTxt.contains('{/MDT}')){
	// 		replaceFormatMDTValueWithTempLoops(contents, documentFieldValueMapByMDTFieldName);
	// 		// add last tag and reset tempContentForRelatedLoops
	// 		addLastContentWhenEndLoopAndResetTempLoop(contentNoWP, contents);
	// 	}
	// 	else{
	// 		tempContentForRelatedLoops.add(WORD_TAG_START_WP + wpIdTag + contentNoWP);
	// 	}
	// }

	// private void replaceFormatMDTValueWithTempLoops(List<String> contents, Map<String, String> documentFieldValueMapByMDTFieldName){
	// 	if(documentFieldValueMapByMDTFieldName.isEmpty()){
	// 		return;
	// 	}

	// 	for (String tempContentXML : tempContentForRelatedLoops) {
	// 		List<String> contentNoWPs = tempContentXML.split(WORD_TAG_START_WP);
	// 		// <w:p w14:paraId="4FD4196F" w14:textId="59368358" w:rsidR="002965CE" w:rsidRDefault="002965CE">
	// 		String wpTag = (WORD_TAG_START_WP + (contentNoWPs.get(1).split('>').get(0) + '>'));
	// 		String contentForLoop = (tempContentXML.replace(wpTag, ''));

	// 		contents.add( wpTag );

	// 		setReplaceFieldValueToContents(
	// 			contentForLoop,
	// 			contents,
	// 			'[',
	// 			']',
	// 			'[FIELDS:',
	// 			1,
	// 			documentFieldValueMapByMDTFieldName,
	// 			null
	// 		);
	// 	}
	// }

	public String getReplacedSourceTagFileName(String sourceFieldTagPath, SObject sObjectRecord){
		List<String> sourceFieldTagPathSplitFields = sourceFieldTagPath.split('\\[FIELDS:');
		String imagePathName = sourceFieldTagPathSplitFields.get(0);

		for (Integer i = 1; i < sourceFieldTagPathSplitFields.size(); i++) {
			List<String> sourceFieldTagPathSplitField = sourceFieldTagPathSplitFields.get(i).split('/]');
			String fieldValue = getFieldValue(SObjectUtility.getInstance().getRecordFieldValue(sObjectRecord, sourceFieldTagPathSplitField.get(0)));

			// imagePathName += field name
			imagePathName += fieldValue;
			if(sourceFieldTagPathSplitField.size() > 1){
				imagePathName += sourceFieldTagPathSplitField.get(1);
			}
		}
		return imagePathName;
	}

	// public String getReplacedSourceTagFileName(String sourceFieldTagPath, SObject sObjectRecord, Boolean isRelatedRecord){
	// 	List<String> sourceFieldTagPathSplitFields = sourceFieldTagPath.split('\\[FIELDS:');
	// 	String imagePathName = sourceFieldTagPathSplitFields.get(0);

	// 	for (Integer i = 1; i < sourceFieldTagPathSplitFields.size(); i++) {
	// 		List<String> sourceFieldTagPathSplitField = sourceFieldTagPathSplitFields.get(i).split('/]');
	// 		String fieldValue = getFieldValue(SObjectUtility.getRecordFieldValue(sObjectRecord, sourceFieldTagPathSplitField.get(0)));

	// 		// imagePathName += field name
	// 		imagePathName += fieldValue;
	// 		if(sourceFieldTagPathSplitField.size() > 1){
	// 			imagePathName += sourceFieldTagPathSplitField.get(1);
	// 		}
	// 	}
	// 	return imagePathName;
	// }
}