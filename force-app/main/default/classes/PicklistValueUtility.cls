public with sharing class PicklistValueUtility {
	
	public static PicklistValueUtility instance;

	public static PicklistValueUtility getInstance() {
		if (instance == null) {
			instance = new PicklistValueUtility();
		}
		return instance;
	}
	
	public List<Schema.PicklistEntry> getPicklistEntries(String objectAPIName, String fieldName){ 
		Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectAPIName);//From the Object Api name retrieving the SObject
		Sobject sObj = targetType.newSObject();
		Schema.sObjectType sObjectType = sObj.getSObjectType(); //grab the sobject that was passed
		Schema.DescribeSObjectResult sObjectDescribe = sObjectType.getDescribe(); //describe the sobject
		Map<String, Schema.SObjectField> fieldMap = sObjectDescribe.fields.getMap(); //get a map of fields for the passed sobject
		List<Schema.PicklistEntry> pickListValues = fieldMap.get(fieldName).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
		return pickListValues;
	}

	public String getDefaultValuePicklist(String objectAPIName, String fieldName){ 
		String defaultValue = '';
		List<Schema.PicklistEntry> pickListValues = getPicklistEntries(objectAPIName, fieldName);
		for (Schema.PicklistEntry eachValue : pickListValues) {
			if (eachValue.isDefaultValue()){
				return eachValue.getValue();
			}
		}
		return defaultValue;
	}

	public List<ComboboxModel> getPicklistComboboxes(String objectAPIName, String fieldName){ 
		List<ComboboxModel> comboboxes = new List<ComboboxModel>();
		List<Schema.PicklistEntry> pickListValues = getPicklistEntries(objectAPIName, fieldName);
		for (Schema.PicklistEntry eachValue : pickListValues) {
			comboboxes.add(new ComboboxModel(eachValue.getLabel(), eachValue.getValue()));
		}

		return comboboxes;
	}
}