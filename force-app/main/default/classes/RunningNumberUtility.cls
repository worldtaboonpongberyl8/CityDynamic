public without sharing class RunningNumberUtility {
	private final String TYPE_RUNNING_NUMBER = 'Running Number';

	private final String PURPOSE_OBJECT = 'Object';
	private final String PRINTDATETIME = 'PRINTDATETIME';
	private final String FORMATDATE = ':FORMATDATE:';
	private final String FORMATDATETIME = ':FORMATDATETIME:';
	private final String FORMATDATETH = ':FORMATDATETH:';
	private final String RUNNINGNUMBER = 'RUNNINGNUMBER:';

	public static RunningNumberUtility instance;

	public static RunningNumberUtility getInstance() {
		if (instance == null) {
			instance = new RunningNumberUtility();
		}
		return instance;
	}

	public String generateReplacedFormatName(NameFormattingMasterData__c nameFormattingMasterData, Id recordId, String objectApiName){
		String nameFormatWithRunningKey = getNameFormat(nameFormattingMasterData, recordId, objectApiName);
		if(nameFormattingMasterData.RunningFormat__c.contains(RUNNINGNUMBER)){
			return getRunningNumberKey(nameFormatWithRunningKey, nameFormattingMasterData);
		}
		else{
			return nameFormatWithRunningKey;
		}
	}

	public Map<Id, String> generateReplacedFormatName(NameFormattingMasterData__c nameFormattingMasterData, List<Id> recordIds, String objectApiName){
		Map<Id, String> nameFormatWithRunningKeyMapByRecId = getNameFormat(nameFormattingMasterData, recordIds, objectApiName);
		if(nameFormattingMasterData.RunningFormat__c.contains(RUNNINGNUMBER)){
			return getRunningNumberKeyMapByRecId(nameFormatWithRunningKeyMapByRecId, nameFormattingMasterData);
		}
		else{
			return nameFormatWithRunningKeyMapByRecId;
		}
	}

	@TestVisible
	private String getRunningNumberKey(String nameFormatWithRunningKey, NameFormattingMasterData__c nameFormattingMasterData){
		Integer currentRunningNumber = 1;
		List<NameFormattingMasterData__c> runningFormatRecords = NameFormattingMasterDataSelector.getInstance().getByObjTypePurposeDocTemplateRunningKey(
			nameFormattingMasterData.ObjectName__c,
			TYPE_RUNNING_NUMBER,
			nameFormattingMasterData.RunningPurpose__c,
			nameFormattingMasterData.DocumentTemplateMappingType__c,
			new Set<String>{nameFormatWithRunningKey}
		);

		if(runningFormatRecords.isEmpty()){
			insert new NameFormattingMasterData__c(
				RunningKey__c = nameFormatWithRunningKey,
				Type__c = TYPE_RUNNING_NUMBER,
				CurrentRunningNumber__c = 1,
				ObjectName__c = nameFormattingMasterData.ObjectName__c,
				RunningPurpose__c = nameFormattingMasterData.RunningPurpose__c,
				DocumentTemplateMappingType__c = nameFormattingMasterData.DocumentTemplateMappingType__c
			);
		}
		else{
			NameFormattingMasterData__c runningFormat = runningFormatRecords.get(0);
			update new NameFormattingMasterData__c(
				Id = runningFormat.Id,
				CurrentRunningNumber__c = runningFormat.CurrentRunningNumber__c + 1
			);

			currentRunningNumber = Integer.valueOf(runningFormat.CurrentRunningNumber__c + 1);
		}

		return getNameWithReplacedRunningNumber(nameFormatWithRunningKey, currentRunningNumber);
	}

	@TestVisible
	private Map<Id, String> getRunningNumberKeyMapByRecId(Map<Id, String> nameFormatWithRunningKeyMapByRecId, NameFormattingMasterData__c nameFormattingMasterData){
		Map<String, Integer> currentNumberMapByRunningKey = new Map<String, Integer>();
		Set<String> runningKeySet = new Set<String>();
		for(String nameFormatWithRunningKey : nameFormatWithRunningKeyMapByRecId.values()){
			runningKeySet.add(nameFormatWithRunningKey);
			currentNumberMapByRunningKey.put(nameFormatWithRunningKey, 0);
		}

		List<NameFormattingMasterData__c> runningFormatRecords = NameFormattingMasterDataSelector.getInstance().getByObjTypePurposeDocTemplateRunningKey(
			nameFormattingMasterData.ObjectName__c,
			TYPE_RUNNING_NUMBER,
			nameFormattingMasterData.RunningPurpose__c,
			nameFormattingMasterData.DocumentTemplateMappingType__c,
			runningKeySet
		);

		Map<String, NameFormattingMasterData__c> nameFormatMasterMapByRunningKey = new Map<String, NameFormattingMasterData__c>();
		for(NameFormattingMasterData__c runningFormatRecord : runningFormatRecords){
			Integer currentRunning = currentNumberMapByRunningKey.get(runningFormatRecord.RunningKey__c);
			if(currentRunning != null){
				currentNumberMapByRunningKey.put(
					runningFormatRecord.RunningKey__c,
					Integer.valueOf((runningFormatRecord.CurrentRunningNumber__c))
				);
			}
			nameFormatMasterMapByRunningKey.put(runningFormatRecord.RunningKey__c, runningFormatRecord);
		}

		Map<Id, String> nameReplacedRunnningMapByRecId = new Map<Id, String>();
		for (Id recordId : nameFormatWithRunningKeyMapByRecId.keySet()) {
			String nameFormatWithRunningKey = nameFormatWithRunningKeyMapByRecId.get(recordId);
			Integer runningNumber = currentNumberMapByRunningKey.get(nameFormatWithRunningKey) + 1;

			nameReplacedRunnningMapByRecId.put(
				recordId,
				getNameWithReplacedRunningNumber(nameFormatWithRunningKey, runningNumber)
			);

			currentNumberMapByRunningKey.put(nameFormatWithRunningKey, (runningNumber));
		}

		List<NameFormattingMasterData__c> nameFormatForUpserts = new List<NameFormattingMasterData__c>();
		for(String runningKey : currentNumberMapByRunningKey.keySet()){
			Integer currentRunningNumber = currentNumberMapByRunningKey.get(runningKey);
			NameFormattingMasterData__c nameFormatMaster = nameFormatMasterMapByRunningKey.get(runningKey);

			// ยังไม่เคยมี record ต้อง insert
			if(nameFormatMaster == null){
				nameFormatForUpserts.add(
					new NameFormattingMasterData__c(
						RunningKey__c = runningKey,
						Type__c = TYPE_RUNNING_NUMBER,
						CurrentRunningNumber__c = currentRunningNumber,
						ObjectName__c = nameFormattingMasterData.ObjectName__c,
						RunningPurpose__c = nameFormattingMasterData.RunningPurpose__c,
						DocumentTemplateMappingType__c = nameFormattingMasterData.DocumentTemplateMappingType__c
					)
				);
			}
			else{
				nameFormatForUpserts.add(
					new NameFormattingMasterData__c(
						Id = nameFormatMaster.Id,
						CurrentRunningNumber__c = currentRunningNumber
					)
				);
			}
		}
		upsert nameFormatForUpserts;

		return nameReplacedRunnningMapByRecId;
	}

	@TestVisible
	private String getNameWithReplacedRunningNumber(String nameFormatWithRunningKey, Integer currentRunningNumber){
		String replacedRunningName = '';
		String currentRunningNumberTxt = String.valueOf(currentRunningNumber);
		List<String> nameFormatSplitRunnings = nameFormatWithRunningKey.split('\\{RUNNINGNUMBER:');

		for (String nameFormatSplitRunning : nameFormatSplitRunnings) {
			if(nameFormatSplitRunning.contains('}')){
				List<String> nameFormatSplitEndBraces = nameFormatSplitRunning.split('}');
				String formatToReplace = nameFormatSplitEndBraces.get(0);

				if(currentRunningNumberTxt.length() > formatToReplace.length()){
					throw new CustomException(
						'running format (' + nameFormatWithRunningKey + ') doesn\'t match with ' +
						'current running number (' + currentRunningNumberTxt +')'
					);
				}
				else if(formatToReplace.left(1) == '0'){
					replacedRunningName += formatToReplace.left(formatToReplace.length() - currentRunningNumberTxt.length());
					replacedRunningName += currentRunningNumberTxt;
				}
				else if(formatToReplace.left(1) == '#'){
					replacedRunningName += currentRunningNumberTxt;
				}

				if(nameFormatSplitEndBraces.size() > 1){
					// value After End Brace
					replacedRunningName += nameFormatSplitEndBraces.get(1);
				}
			}
			else{
				replacedRunningName += nameFormatSplitRunning;
			}
		}
		return replacedRunningName;
	}

	@TestVisible
	private String getNameFormat(NameFormattingMasterData__c nameFormattingMasterData, Id recordId, String objectApiName){
		if (nameFormattingMasterData == null) {
			throw new CustomException('not found running format');
		}

		String runningFormat = nameFormattingMasterData.RunningFormat__c;
		Set<String> fieldToQuerySet = new Set<String>();
		List<String> fieldFormats = runningFormat.split('\\{');
		Map<String, String> valueToReplaceMap = new Map<String, String>();

		setFieldToQuerySet(fieldToQuerySet, fieldFormats);

		SObject sObjectRecord;
		if(!fieldToQuerySet.isEmpty()){
			sObjectRecord = SObjectUtility.getInstance().querySObject(
				String.join(new List<String>(fieldToQuerySet), ', '),
				objectApiName,
				('id = ' + '\'' + recordId + '\'')
			);

			for (String fieldToQuery : fieldToQuerySet) {
				valueToReplaceMap.put(('{' + fieldToQuery + '}'), SObjectUtility.getInstance().getRecordFieldValue(sObjectRecord, fieldToQuery));
			}
		}

		return getFormatWithReplacedValue(fieldFormats, valueToReplaceMap, sObjectRecord);
	}

	@TestVisible
	private Map<Id, String> getNameFormat(NameFormattingMasterData__c nameFormattingMasterData, List<Id> recordIds, String objectApiName){
		if (nameFormattingMasterData == null) {
			throw new CustomException('not found running format');
		}

		Set<String> fieldToQuerySet = new Set<String>();
		List<String> fieldFormats = nameFormattingMasterData.RunningFormat__c.split('\\{');
		Map<String, String> initialValueToReplaceMap = new Map<String, String>();

		setFieldToQuerySet(fieldToQuerySet, fieldFormats);

		Map<Id, Map<String, String>> valueToReplaceMapMapById = new Map<Id, Map<String, String>>();
		Map<Id, SObject> sObjectRecordMapById = new Map<Id, SObject>();
		if(!fieldToQuerySet.isEmpty()){
			List<SObject> sObjectRecords = SObjectUtility.getInstance().querySObjects(
				String.join(new List<String>(fieldToQuerySet), ', '),
				objectApiName,
				('Id IN (' + '\'' + String.join(recordIds, '\', \'') + '\')')
			);

			for (SObject sObjectRecord : sObjectRecords) {
				Id recordId = SObjectUtility.getInstance().getRecordFieldValue(sObjectRecord, 'Id');
				sObjectRecordMapById.put(recordId, sObjectRecord);

				Map<String, String> valueToReplaceMap = new Map<String, String>();
				valueToReplaceMap.putAll(initialValueToReplaceMap);

				for (String fieldToQuery : fieldToQuerySet) {
					valueToReplaceMap.put(('{' + fieldToQuery + '}'), SObjectUtility.getInstance().getRecordFieldValue(sObjectRecord, fieldToQuery));
				}

				valueToReplaceMapMapById.put(recordId, valueToReplaceMap);
			}
		}

		Map<Id, String> resultFormatMapByRecordId = new Map<Id, String>();
		for (Id recordId : valueToReplaceMapMapById.keySet()) {
			Map<String, String> valueToReplaceMap = valueToReplaceMapMapById.get(recordId);
			SObject sObjectRecord = sObjectRecordMapById.get(recordId);
			String resultFormat = getFormatWithReplacedValue(fieldFormats, valueToReplaceMap, sObjectRecord);
			resultFormatMapByRecordId.put(recordId, resultFormat);
		}

		return resultFormatMapByRecordId;
	}

	private void setFieldToQuerySet(Set<String> fieldToQuerySet, List<String> fieldFormats){
		for (String fieldFormat : fieldFormats) {
			if(!fieldFormat.contains('}') || fieldFormat.contains(PRINTDATETIME) || fieldFormat.contains(RUNNINGNUMBER)){
				continue;
			}

			String fieldFormatNoBrace = fieldFormat.split('\\}').get(0);
			String fieldFormatNoBraceLowerCase = fieldFormatNoBrace.toLowerCase();
			String fieldFormatBrace = '{' + fieldFormatNoBrace + '}';

			if (fieldFormatBrace.contains(FORMATDATE)) {
				fieldToQuerySet.add(fieldFormatNoBrace.split(FORMATDATE).get(0));
			}
			else if (fieldFormatBrace.contains(FORMATDATETH)) {
				fieldToQuerySet.add(fieldFormatNoBrace.split(FORMATDATETH).get(0));
			}
			else if (fieldFormatBrace.contains(FORMATDATETIME)) {
				fieldToQuerySet.add(fieldFormatNoBrace.split(FORMATDATETIME).get(0));
			}
			else{
				fieldToQuerySet.add(fieldFormatNoBrace);
			}
		}
	}

	private String getFormatWithReplacedValue(List<String> fieldFormats, Map<String, String> valueToReplaceMap, SObject sObjectRecord){
		List<String> resultFormats = new List<String>();

		for (String fieldFormat : fieldFormats) {
			if(!fieldFormat.contains('}')){
				resultFormats.add(fieldFormat);
				continue;
			}

			String fieldFormatNoBrace = fieldFormat.split('\\}').get(0);
			String fieldFormatBrace = '{' + fieldFormatNoBrace + '}';

			String valueToReplace = valueToReplaceMap.get(fieldFormatBrace);
			if(valueToReplace != null){
				resultFormats.add(valueToReplace);
			}
			else if(fieldFormatNoBrace.contains(FORMATDATE)){
				resultFormats.add(getFormatDateTxt(fieldFormatNoBrace, FORMATDATE, sObjectRecord));

			}
			else if(fieldFormatNoBrace.contains(FORMATDATE)){
				resultFormats.add(getFormatDateTxt(fieldFormatNoBrace, FORMATDATE, sObjectRecord));

			}
			else if(fieldFormatNoBrace.contains(FORMATDATETH)){
				resultFormats.add(getFormatDateTxt(fieldFormatNoBrace, FORMATDATETH, sObjectRecord));

			}
			else if(fieldFormatNoBrace.contains(FORMATDATETIME)){
				resultFormats.add(getFormatDateTimeTxt(fieldFormatNoBrace, FORMATDATETIME, sObjectRecord));
			}
			else if(fieldFormatNoBrace.contains(RUNNINGNUMBER)){
				resultFormats.add(fieldFormatBrace);
			}

			if(fieldFormat.right(1) != '}'){
				resultFormats.add(fieldFormat.split('\\}').get(1));
			}
		}

		return String.join(resultFormats, '');
	}

	private String getFormatDateTimeTxt(String fieldFormatNoBrace, String delimeter, SObject sObjectRecord){
		List<String> splitFormatDateTimes = fieldFormatNoBrace.split(delimeter);
		DateTime dt;
		if (splitFormatDateTimes.get(0) == PRINTDATETIME) {
			dt = System.now();
		}
		else{
			dt = (DateTime) sObjectRecord.get(splitFormatDateTimes.get(0));
		}
		return DateUtility.getInstance().toDateTimeString(splitFormatDateTimes.get(1), dt);
	}

	private String getFormatDateTxt(String fieldFormatNoBrace, String delimeter, SObject sObjectRecord){
		List<String> splitFormatDates = fieldFormatNoBrace.split(delimeter);

		Date d = (Date) sObjectRecord.get(splitFormatDates.get(0));
		if (delimeter == FORMATDATETH) {
			return DateUtility.getInstance().toDateTHString(splitFormatDates.get(1), d);
		}

		return DateUtility.getInstance().toDateString(splitFormatDates.get(1), d);
	}
}