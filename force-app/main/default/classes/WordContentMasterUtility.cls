public with sharing class WordContentMasterUtility {
	private final String TAG_START_FIELD = '{FIELD:';
	private final String TAG_START_LOOP_RELATED_OBJECT = '{LOOPRELATEDOBJECT:';
	private final String TAG_START_IMAGE_LOOP_RELATED_OBJECT = '{IMAGELOOPRELATEDOBJECT:';
	private final String TAG_START_IMAGE_OBJECT = '{IMAGEOBJECT:';
	private final String TAG_START_IFF = '{IFF:';
	private final String TAG_START_MDT = '{MDT:';

	private final String TAG_END_FIELD = '/}';
	private final String TAG_END_IMAGE_LOOP_RELATED_OBJECT = '{/IMAGELOOPRELATEDOBJECT}';
	private final String TAG_END_LOOP_RELATED_OBJECT = '{/LOOPRELATEDOBJECT}';
	private final String TAG_END_IMAGE_OBJECT = '{/IMAGEOBJECT}';
	private final String TAG_END_IFF = '{/IFF}';
	private final String TAG_END_MDT = '{/MDT}';
	
	private final String TAG_FIELDS_TO_QUERY = ';FIELDS:';
	private final String TAG_ALL_FIELDS_TO_QUERY = ':ALLFIELDS:';
	private final String TAG_MDT_FIELDS_TO_QUERY = ';MDTFIELDS:';
	private final String TAG_LOOKUP_FIELD_TO_QUERY = ';LOOKUPFIELD:';
	private final String TAG_CONDITION_TO_QUERY = ';CONDITION:';
	private final String TAG_SOURCE_OBJECT = ':SOURCEOBJECT:';
	private final String TAG_SOURCE_FIELD = ';SOURECEFIELD:';
	private final String TAG_LOOP_SOURCE_OBJECT = ';SOURCEOBJECT:';

	private final String SEMI_COLON = ';';
	private final String END_BRACE_FOR_SPLIT = '\\}';

	private final String WORD_TAG_START_WP = '<w:p ';
	private final String WORD_TAG_END_WP = '</w:p>';

	private final String GT_TAG = '>';
	private final String TAG_START_CONTENT_MASTER = '<!-- {CONTENTMASTER:';
	
	private final Integer REGEX_MAXLENGTH = 500000;

	public static WordContentMasterUtility instance;

	public static WordContentMasterUtility getInstance() {
		if (instance == null) {
			instance = new WordContentMasterUtility();
		}
		return instance;
	}

	public Blob getWordDocumentXMLWithExternalKey(Id zipId, Blob contentBlob, string documentPath){
		String contentXml = contentBlob.toString();
		String contentPlainTxt = contentXml.stripHtmlTags();
		List<String> sortingPlainFormatMapKeys = new List<String>();
		Map<String, Set<String>> keyToReplaceSetMapWithExtKey = new Map<String, Set<String>>();
		
		Map<String, String> plainFormatMapWithExternalKey = getPlainFormatMapWithExternalKey(zipId, contentXml, sortingPlainFormatMapKeys, keyToReplaceSetMapWithExtKey);

		insertWordContentMaster(zipId, plainFormatMapWithExternalKey, keyToReplaceSetMapWithExtKey, documentPath);
		
		return getContentXMLWithExternalKey(contentXml, plainFormatMapWithExternalKey, sortingPlainFormatMapKeys);
	}

	private Map<String, String> getPlainFormatMapWithExternalKey(
		Id zipId,
		String contentXml,
		List<String> sortingPlainFormatMapKeys,
		Map<String, Set<String>> keyToReplaceSetMapWithExtKey
	){

		// ExternalKey = zipId_StartTagIndex_endTagIndex 
		Map<String, String> plainFormatMapWithExternalKey = new Map<String, String>();
		Set<String> tagStartSet = new Set<String>{
			TAG_START_FIELD, TAG_START_IMAGE_LOOP_RELATED_OBJECT, TAG_START_IMAGE_OBJECT, TAG_START_LOOP_RELATED_OBJECT, TAG_START_IFF, TAG_START_MDT
		};
		Set<String> tagEndSet = new Set<String>{
			TAG_END_FIELD, TAG_END_LOOP_RELATED_OBJECT, TAG_END_IMAGE_OBJECT, TAG_END_IMAGE_LOOP_RELATED_OBJECT, TAG_END_IFF, TAG_END_MDT
		};

		PlainFormatWithExternalKeyWrapper plainFormatExtKeyWrapper = new PlainFormatWithExternalKeyWrapper();
		plainFormatExtKeyWrapper.startTagIndex = 0;
		plainFormatExtKeyWrapper.wpIndex = 0;
		plainFormatExtKeyWrapper.tagStartSet = tagStartSet;
		plainFormatExtKeyWrapper.tagEndSet = tagEndSet;

		String previousXML = '';
		Integer splitContentStartIndex = 0;
		Integer splitContentEndIndex = REGEX_MAXLENGTH;
		Decimal splitContentAmount = Math.ceil( (Decimal.valueOf(contentXml.length()) / Decimal.valueOf(REGEX_MAXLENGTH)) );

		for (Integer i = 0; i < splitContentAmount; i++) {
			String splitContentXML = getSplitContentXML(splitContentStartIndex, splitContentEndIndex, contentXml, previousXML);
			
			List<String> contentNoWPs = splitContentXML.split(WORD_TAG_START_WP);
			String lastContentNoWP = contentNoWPs.get( (contentNoWPs.size() - 1) );
			
			if(lastContentNoWP.endsWith(WORD_TAG_END_WP)){
				previousXML = '';
			}
			// loop สุดท้าย add ทุกตัว
			else if(i < splitContentAmount - 1){
				previousXML = lastContentNoWP;
				contentNoWPs.remove(contentNoWPs.size() - 1);
			}
			
			setPlainFormatMapWithExternalKey(
				zipId,
				plainFormatMapWithExternalKey,
				keyToReplaceSetMapWithExtKey,
				sortingPlainFormatMapKeys,
				contentNoWPs,
				plainFormatExtKeyWrapper
			);

			splitContentStartIndex = splitContentEndIndex;
			splitContentEndIndex += REGEX_MAXLENGTH;
		}
		return plainFormatMapWithExternalKey;
	}

	private void setPlainFormatMapWithExternalKey(
		Id zipId,
		Map<String, String> plainFormatMapWithExternalKey,
		Map<String, Set<String>> keyToReplaceSetMapWithExtKey,
		List<String> sortingPlainFormatMapKeys,
		List<String> contentNoWPs,
		PlainFormatWithExternalKeyWrapper plainFormatExtKeyWrapper
	) {
		String externalKey;
		Boolean isImageTag;
		Set<String> keyToReplaceSet;

		for (Integer i = 0; i < contentNoWPs.size(); i++) {
			String contentWP = WORD_TAG_START_WP + contentNoWPs.get(i);
			String contentPlainTxt = contentWP.stripHtmlTags();
			Boolean isStartTag = false;
			if (plainFormatExtKeyWrapper.formatStartTag == null) {
				for (String tagStart : plainFormatExtKeyWrapper.tagStartSet) {
					if(contentPlainTxt.contains(tagStart)){
						plainFormatExtKeyWrapper.formatStartTag = tagStart;
						plainFormatExtKeyWrapper.startTagIndex = plainFormatExtKeyWrapper.wpIndex;
						plainFormatExtKeyWrapper.externalKey = zipId + '_' + plainFormatExtKeyWrapper.startTagIndex + '_' + plainFormatExtKeyWrapper.startTagIndex;
						isStartTag = true;
						plainFormatExtKeyWrapper.keyToReplaceSet = new Set<String>();
						plainFormatMapWithExternalKey.put(plainFormatExtKeyWrapper.externalKey, contentPlainTxt);
						if(tagStart == TAG_START_IMAGE_LOOP_RELATED_OBJECT || tagStart == TAG_START_IMAGE_OBJECT){
							plainFormatExtKeyWrapper.isImageTag = true;
						}
						else{
							plainFormatExtKeyWrapper.isImageTag = false;
						}
						break;
					}
				}
			}
			
			if(!isStartTag && plainFormatExtKeyWrapper.formatStartTag != null){
				plainFormatExtKeyWrapper.formatWording = plainFormatMapWithExternalKey.get(plainFormatExtKeyWrapper.externalKey) + contentPlainTxt;
				plainFormatMapWithExternalKey.put(plainFormatExtKeyWrapper.externalKey, plainFormatExtKeyWrapper.formatWording);
				if(plainFormatExtKeyWrapper.isImageTag && contentWP.contains('{SOURCE:')){
					plainFormatExtKeyWrapper.keyToReplaceSet.add(contentWP.split('\\{SOURCE:').get(1).split('/}').get(0));
				}
			}
			
			for (String tagEnd : plainFormatExtKeyWrapper.tagEndSet) {
				if(contentPlainTxt.contains(tagEnd)){
					String key = (zipId + '_' + plainFormatExtKeyWrapper.startTagIndex + '_' + plainFormatExtKeyWrapper.wpIndex);
					if(plainFormatMapWithExternalKey.get(key) == null){
						plainFormatMapWithExternalKey.remove(plainFormatExtKeyWrapper.externalKey);
						plainFormatMapWithExternalKey.put(key, plainFormatExtKeyWrapper.formatWording);
					}
					
					if(plainFormatExtKeyWrapper.keyToReplaceSet != null && !plainFormatExtKeyWrapper.keyToReplaceSet.isEmpty()){
						keyToReplaceSetMapWithExtKey.put(key, plainFormatExtKeyWrapper.keyToReplaceSet);
					}
					sortingPlainFormatMapKeys.add(key);
					plainFormatExtKeyWrapper.formatStartTag = null;
					plainFormatExtKeyWrapper.formatWording = null;
					break;
				}
			}

			plainFormatExtKeyWrapper.wpIndex += 1;
		}
	}

	private void insertWordContentMaster(
		Id zipId,
		Map<String, String> plainFormatMapWithExternalKey,
		Map<String, Set<String>> keyToReplaceSetMapWithExtKey,
		string documentPath
	){
		List<WordContentMaster__c> wordCtMasters = new List<WordContentMaster__c>();
		
		Set<String> tagStartSet = new Set<String>{
			TAG_START_FIELD, TAG_START_IMAGE_LOOP_RELATED_OBJECT, TAG_START_IMAGE_OBJECT, TAG_START_LOOP_RELATED_OBJECT, TAG_START_IFF, TAG_START_MDT
		};

		for (String externalKey : plainFormatMapWithExternalKey.keySet()) {
			String plainFormat = plainFormatMapWithExternalKey.get(externalKey);
			
			if(plainFormat == null){
				continue;
			}

			WordContentMaster__c wordCtMaster = new WordContentMaster__c(
				ZipFileMasterId__c = zipId,
				WordContentExternalKey__c = externalKey,
				DocumentPathName__c = documentPath
			);
			
			if(!keyToReplaceSetMapWithExtKey.isEmpty() && keyToReplaceSetMapWithExtKey.get(externalKey) != null){
				wordCtMaster.KeyToReplace__c = String.join(keyToReplaceSetMapWithExtKey.get(externalKey), ', ');
			}

			if(plainFormat.contains(TAG_START_FIELD)){
				setWordCtMasterFormatField(wordCtMaster, plainFormat);
			}
			else if(plainFormat.contains(TAG_START_IFF)){
				setWordCtMasterFormatIff(wordCtMaster, plainFormat);
			}
			else if(plainFormat.contains(TAG_START_MDT)){
				setWordCtMasterFormatMdt(wordCtMaster, plainFormat);
			}
			else if(plainFormat.contains(TAG_START_LOOP_RELATED_OBJECT)){
				setWordCtMasterFormatLoopRelatedObject(wordCtMaster, plainFormat);
			}
			else if(plainFormat.contains(TAG_START_IMAGE_LOOP_RELATED_OBJECT)){
				setWordCtMasterFormatImageLoopRelatedObject(wordCtMaster, plainFormat);
			}
			else if(plainFormat.contains(TAG_START_IMAGE_OBJECT)){
				setWordCtMasterFormatImageObject(wordCtMaster, plainFormat);
			}

			wordCtMasters.add(wordCtMaster);
		}

		insert wordCtMasters;
	}

	private Blob getContentXMLWithExternalKey(
		String contentXml,
		Map<String, String> plainFormatMapWithExternalKey,
		List<String> sortingPlainFormatMapKeys
	){
		if(sortingPlainFormatMapKeys.isEmpty()){
			return Blob.valueOf(contentXml);
		}
		ContentWithExternalKeyWrapper contentExtKeyWrapper = new ContentWithExternalKeyWrapper();
		contentExtKeyWrapper.externalKey = sortingPlainFormatMapKeys.get(0);
		contentExtKeyWrapper.externalKeySplits = contentExtKeyWrapper.externalKey.split('_');
		contentExtKeyWrapper.startIndex = Integer.valueOf(contentExtKeyWrapper.externalKeySplits.get(1));
		contentExtKeyWrapper.endIndex = Integer.valueOf(contentExtKeyWrapper.externalKeySplits.get(2));
		contentExtKeyWrapper.externalKeysIndex = 1;
		contentExtKeyWrapper.wpIndex = 0;
		
		List<String> contents = new List<String> ();
		String previousXML = '';
		Integer splitContentStartIndex = 0;
		Integer splitContentEndIndex = REGEX_MAXLENGTH;
		Decimal splitContentAmount = Math.ceil( (Decimal.valueOf(contentXml.length()) / Decimal.valueOf(REGEX_MAXLENGTH)) );
		for (Integer i = 0; i < splitContentAmount; i++) {
			String splitContentXML = getSplitContentXML(splitContentStartIndex, splitContentEndIndex, contentXml, previousXML);
			List<String> contentNoWPs = splitContentXML.split(WORD_TAG_START_WP);
			String lastContentNoWP = contentNoWPs.get( (contentNoWPs.size() - 1) );
			
			if(lastContentNoWP.endsWith(WORD_TAG_END_WP)){
				previousXML = '';
			}
			// loop สุดท้าย add ทุกตัว
			else if(i < splitContentAmount - 1){
				previousXML = lastContentNoWP;
				contentNoWPs.remove(contentNoWPs.size() - 1);
			}
			
			addExternalKeyToContents(contents, contentNoWPs, sortingPlainFormatMapKeys, contentExtKeyWrapper);

			splitContentStartIndex = splitContentEndIndex;
			splitContentEndIndex += REGEX_MAXLENGTH;
		}

		return Blob.valueOf(String.join(contents, ''));
	}

	private void addExternalKeyToContents(
		List<String> contents,
		List<String> contentNoWPs,
		List<String> sortingPlainFormatMapKeys,
		ContentWithExternalKeyWrapper contentExtKeyWrapper
	){

		for (Integer i = 0; i < contentNoWPs.size(); i++) {
			String contentNoWP = contentNoWPs.get(i);
			
			if(contentExtKeyWrapper.wpIndex == 0){
				contents.add(contentNoWP);
				contentExtKeyWrapper.wpIndex += 1;
				continue;
			}

			List<String> contentSplitEndTags = contentNoWP.split(GT_TAG);
			
			// <w:p 
			contents.add(WORD_TAG_START_WP);
			// w14:paraId="4FD4196F" w14:textId="59368358" w:rsidR="002965CE" w:rsidRDefault="002965CE">
			contents.add( (contentSplitEndTags.get(0) + GT_TAG) );
			
			if( 
				contentExtKeyWrapper.wpIndex >= contentExtKeyWrapper.startIndex && 
				contentExtKeyWrapper.wpIndex <= contentExtKeyWrapper.endIndex
			){
				// {CONTENTMASTER:a0N0T000002w1nfUAA_1_3}
				contents.add( (TAG_START_CONTENT_MASTER + contentExtKeyWrapper.externalKey + '} -->') );

				if(
					contentExtKeyWrapper.externalKeysIndex < sortingPlainFormatMapKeys.size() && 
					contentExtKeyWrapper.wpIndex == contentExtKeyWrapper.endIndex
				){
					contentExtKeyWrapper.externalKey = sortingPlainFormatMapKeys.get(contentExtKeyWrapper.externalKeysIndex);
					contentExtKeyWrapper.externalKeySplits = contentExtKeyWrapper.externalKey.split('_');
					contentExtKeyWrapper.startIndex = Integer.valueOf(contentExtKeyWrapper.externalKeySplits.get(1));
					contentExtKeyWrapper.endIndex = Integer.valueOf(contentExtKeyWrapper.externalKeySplits.get(2));
					contentExtKeyWrapper.externalKeysIndex += 1;
				}
			}

			// <w:r w:rsidRPr="00004F0B"> <w:t> start date: </w:t> </w:r>
			for (Integer splitEndTagIndex = 1; splitEndTagIndex < contentSplitEndTags.size(); splitEndTagIndex++) {
				contents.add( contentSplitEndTags.get(splitEndTagIndex) + GT_TAG );
			}

			contentExtKeyWrapper.wpIndex += 1;
		}
	}

	private void setWordCtMasterFormatField(WordContentMaster__c wordCtMaster, String plainFormat){
		List<String> plainFormatSplits = plainFormat.split('\\{FIELD:');
		List<String> fieldToQuerys = new List<String>();
		for (Integer i = 1; i < plainFormatSplits.size(); i++) {
			// add ค่าหลัง tag {FIELD: => 
			// {FIELD:Building__r.Company__r.Name} => Building__r.Company__r.Name
			// แต่ถ้ามีหลาย field จะมาต่อกันด้วย ', '
			fieldToQuerys.add(plainFormatSplits.get(i).split(TAG_END_FIELD).get(0));

		}

		wordCtMaster.ObjectToQuery__c = 'Main';
		wordCtMaster.FieldToQuery__c = String.join(fieldToQuerys, ', ');
		wordCtMaster.FormatType__c = 'FIELD';
	}

	private void setWordCtMasterFormatIff(WordContentMaster__c wordCtMaster, String plainFormat){
		wordCtMaster.ObjectToQuery__c = 'Main';
		wordCtMaster.FieldToQuery__c = getSplitPlainFormatTxt(plainFormat, TAG_ALL_FIELDS_TO_QUERY, SEMI_COLON);
		wordCtMaster.KeyToReplace__c = getSplitPlainFormatTxt(plainFormat, TAG_CONDITION_TO_QUERY, END_BRACE_FOR_SPLIT);
		wordCtMaster.FormatType__c = 'IFF';
	}

	private void setWordCtMasterFormatMdt(WordContentMaster__c wordCtMaster, String plainFormat){
		wordCtMaster.ObjectToQuery__c = 'Main';
		wordCtMaster.FieldToQuery__c = getSplitPlainFormatTxt(plainFormat, TAG_ALL_FIELDS_TO_QUERY, SEMI_COLON);
		wordCtMaster.KeyToReplace__c = getSplitPlainFormatTxt(plainFormat, TAG_MDT_FIELDS_TO_QUERY, END_BRACE_FOR_SPLIT);
		wordCtMaster.FormatType__c = 'MDT';
	}

	private void setWordCtMasterFormatLoopRelatedObject(WordContentMaster__c wordCtMaster, String plainFormat){
		wordCtMaster.ObjectToQuery__c = getSplitPlainFormatTxt(plainFormat, '\\{LOOPRELATEDOBJECT:', SEMI_COLON);
		wordCtMaster.FieldToQuery__c = getSplitPlainFormatTxt(plainFormat, TAG_FIELDS_TO_QUERY, END_BRACE_FOR_SPLIT);
		wordCtMaster.FormatType__c = 'LOOPRELATEDOBJECT';
		wordCtMaster.LookupFieldToQuery__c = getSplitPlainFormatTxt(plainFormat, TAG_LOOKUP_FIELD_TO_QUERY, SEMI_COLON);
		
		if(plainFormat.contains(TAG_CONDITION_TO_QUERY)){
			wordCtMaster.ConditionToQuery__c = getSplitPlainFormatTxt(plainFormat, TAG_CONDITION_TO_QUERY, SEMI_COLON);
		}
	}

	private void setWordCtMasterFormatImageLoopRelatedObject(WordContentMaster__c wordCtMaster, String plainFormat){
		System.debug('--Test-- plainFormat: ' + plainFormat);
		wordCtMaster.ObjectToQuery__c = getSplitPlainFormatTxt(plainFormat, '\\{IMAGELOOPRELATEDOBJECT:', SEMI_COLON);
		wordCtMaster.FieldToQuery__c = getSplitPlainFormatTxt(plainFormat, TAG_FIELDS_TO_QUERY, SEMI_COLON);
		wordCtMaster.FormatType__c = 'IMAGELOOPRELATEDOBJECT';
		wordCtMaster.LookupFieldToQuery__c = getSplitPlainFormatTxt(plainFormat, TAG_LOOKUP_FIELD_TO_QUERY, SEMI_COLON);
		wordCtMaster.SourceObject__c = getSplitPlainFormatTxt(plainFormat, TAG_LOOP_SOURCE_OBJECT, SEMI_COLON);
		wordCtMaster.SourceField__c = getSplitPlainFormatTxt(plainFormat, TAG_SOURCE_FIELD, END_BRACE_FOR_SPLIT);

		if(plainFormat.contains(TAG_CONDITION_TO_QUERY)){
			wordCtMaster.ConditionToQuery__c = getSplitPlainFormatTxt(plainFormat, TAG_CONDITION_TO_QUERY, SEMI_COLON);
		}
	}

	private void setWordCtMasterFormatImageObject(WordContentMaster__c wordCtMaster, String plainFormat){
		wordCtMaster.ObjectToQuery__c = 'Main';
		wordCtMaster.FieldToQuery__c = getSplitPlainFormatTxt(plainFormat, TAG_FIELDS_TO_QUERY, END_BRACE_FOR_SPLIT);
		wordCtMaster.FormatType__c = 'IMAGEOBJECT';
		wordCtMaster.SourceObject__c = getSplitPlainFormatTxt(plainFormat, TAG_SOURCE_OBJECT, SEMI_COLON);
		wordCtMaster.SourceField__c = getSplitPlainFormatTxt(plainFormat, TAG_SOURCE_FIELD, SEMI_COLON);
		
		if(plainFormat.contains(TAG_CONDITION_TO_QUERY)){
			wordCtMaster.ConditionToQuery__c = getSplitPlainFormatTxt(plainFormat, TAG_CONDITION_TO_QUERY, SEMI_COLON);
		}
	}

	private String getSplitPlainFormatTxt(String plainFormat, String firstTxtForSpliting, String lastTxtForSpliting){
		return plainFormat.split(firstTxtForSpliting).get(1).split(lastTxtForSpliting).get(0);
	}
	
	private string getSplitContentXML(Integer startIndex, Integer endIndex, String fullContentXML, String previousXML){
		String result = '';

		if(!String.isEmpty(previousXML)){
			result += previousXML;
		}
		if(endIndex > fullContentXML.length()){
			endIndex = fullContentXML.length() - 1;
		}

		result += fullContentXML.substring(startIndex, endIndex);
		return result;
	}

	private class PlainFormatWithExternalKeyWrapper {
		Integer startTagIndex {get;set;}
		Integer wpIndex {get;set;}
		String formatStartTag {get;set;}
		String formatWording {get;set;}
		Set<String> tagStartSet {get;set;}
		Set<String> tagEndSet {get;set;}
		List<String> contentNoWPs {get;set;}
		String externalKey {get;set;}
		Boolean isImageTag {get;set;}
		Set<String> keyToReplaceSet {get;set;}
	}

	private class ContentWithExternalKeyWrapper {
		String externalKey {get;set;}
		List<String> externalKeySplits {get;set;}
		Integer startIndex {get;set;}
		Integer endIndex {get;set;}
		Integer externalKeysIndex {get;set;}
		Integer wpIndex {get;set;}
	}
}