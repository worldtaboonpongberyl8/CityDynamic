@isTest
public with sharing class DocumentGeneratorControllerTest {
	@isTest
	static void getLanguagesTest() {
		Test.startTest();
		List<ComboboxModel> results = DocumentGeneratorController.getLanguages('Reservation');
		for (ComboboxModel result : results) {
			System.assertEquals('TH/EN', result.label);
			System.assertEquals('TH/EN', result.value);
		}
		Test.stopTest();
	}
}