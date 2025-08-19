public without sharing class SObjectUtility {
	public static SObjectUtility instance;

	public static SObjectUtility getInstance() {
		if (instance == null) {
			instance = new SObjectUtility();
		}
		return instance;
	}

    public SObject querySObject(String fieldTxt, String objectApiName, String condition){
        String queryString = 'SELECT '+ fieldTxt + ' FROM ' + objectApiName;
		if(String.isNotBlank(condition)){
			queryString += ' WHERE ' + condition;
		}

        return Database.query(queryString);
    }

    public List<SObject> querySObjects(String fieldTxt, String objectApiName, String condition){
        String queryString = 'SELECT '+ fieldTxt + ' FROM ' + objectApiName;
		if(String.isNotBlank(condition)){
			queryString += ' WHERE ' + condition;
		}

        return Database.query(queryString);
    }

    public List<SObject> queryRelatedSObjects(String fieldTxt, String objectApiName, String condition){
        String queryString = 'SELECT '+ fieldTxt + ' FROM ' + objectApiName;
		if(String.isNotBlank(condition)){
			queryString += ' WHERE ' + condition;
		}

        return Database.query(queryString);
    }

	public String getRecordFieldValue(SObject sObjectRecord, String field){
		String recordValue = '';

		if(sObjectRecord == null){
			return recordValue;
		}

		if(field.contains('.')){
			List<String> fieldSplits = field.split('\\.');
			for (Integer i = 0; i < fieldSplits.size(); i++) {
				if(i == (fieldSplits.size() - 1)){
					recordValue = sObjectRecord.get(fieldSplits.get(i)) == null ? '' : String.valueOf(sObjectRecord.get(fieldSplits.get(i)));
				}
				else{
					sObjectRecord = sObjectRecord.getSobject(fieldSplits.get(i));

					if(sObjectRecord == null){
						return '';
					}
				}
			}
			return recordValue;
		}
		else{
			return sObjectRecord.get(field) == null ? '' : String.valueOf(sObjectRecord.get(field));
		}
	}
}