public with sharing class BankService {
	public static BankService instance;
	public static BankService getInstance() {
		if (instance == null) {
			instance = new BankService();
		}
		return instance;
	}

	public final String OBJECT_API_NAME = 'Bank__c';

	public Map<String, String> getBankNameLabelMapByValue() {
		Map<String, String> bankNameLabelMapByValue = new Map<String, String>();

		List<Schema.PicklistEntry> pickListValues = PicklistValueUtility.getInstance().getPicklistEntries(OBJECT_API_NAME, 'BankName__c');
		for (Schema.PicklistEntry pickListValue : pickListValues) {
			bankNameLabelMapByValue.put(pickListValue.getValue(), pickListValue.getLabel());
		}
		return bankNameLabelMapByValue;
	}
}