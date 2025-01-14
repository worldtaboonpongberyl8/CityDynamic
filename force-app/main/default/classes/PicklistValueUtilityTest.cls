@isTest
private class PicklistValueUtilityTest {

	@isTest
	static void getPicklistEntriesTest() {

		String objectAPIName = 'Account';
		String fieldName = 'AccountSource';
		List<Schema.PicklistEntry> picklistEntries = PicklistValueUtility.getInstance().getPicklistEntries(objectAPIName, fieldName);
		System.assertNotEquals(null, picklistEntries, 'Picklist entries should not be null');
		System.assert(picklistEntries.size() > 0, 'Picklist entries should have values');
		Boolean foundExpectedValue = false;
		for (Schema.PicklistEntry entry : picklistEntries) {
			if (entry.getValue() == 'Advertisement') {
				foundExpectedValue = true;
				break;
			}
		}
		System.assert(foundExpectedValue, 'Expected picklist value "Advertisement" should exist in the picklist entries.');
	}
	@isTest
	static void getDefaultValuePicklistTest() {

		String objectAPIName = 'Account';
		String fieldName = 'AccountSource';
		String defaultPicklistValue  = PicklistValueUtility.getInstance().getDefaultValuePicklist(objectAPIName, fieldName);

		// Validate that the default picklist value is returned correctly
		System.assertEquals('', defaultPicklistValue);

	}
	@isTest
	static void getPicklistComboboxesTest(){
		String objectAPIName = 'Lead';
		String fieldName = 'Status';


		List<ComboboxModel> comboboxes = PicklistValueUtility.getInstance().getPicklistComboboxes(objectAPIName, fieldName);


		System.assertNotEquals(null, comboboxes, 'Comboboxes list should not be null');
		System.assert(comboboxes.size() > 0, 'Comboboxes list should contain values');

		ComboboxModel firstCombobox = comboboxes[0];
		System.assertNotEquals(null, firstCombobox, 'First ComboboxModel should not be null');
		System.assertNotEquals('', firstCombobox.label, 'Combobox label should not be empty');
		System.assertNotEquals('', firstCombobox.value, 'Combobox value should not be empty');

		Boolean foundExpectedCombobox = false;
		for (ComboboxModel combobox : comboboxes) {
			if (combobox.label == 'New' && combobox.value == 'New') {
				foundExpectedCombobox = true;
				break;
			}
		}
		System.assert(foundExpectedCombobox, 'Expected combobox with label "New" should exist.');
	}

}