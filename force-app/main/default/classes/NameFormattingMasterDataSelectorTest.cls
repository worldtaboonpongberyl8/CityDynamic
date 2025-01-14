@isTest
public with sharing class NameFormattingMasterDataSelectorTest {
	@TestSetup
	static void makeData() {
		DataMaker dataMaker = DataMaker.getInstance();
		// Create Name Formatting
		NameFormattingMasterData__c format = dataMaker.createNameFormattingMasterData(
			'PaymentReceipt__c',
			'Format',
			'Object',
			'RV-{RUNNINGNUMBER:000}',
			1,
			null
		);
		insert format;
	}

	@isTest
	static void getByObjTypePurposeDocTemplateTest() {
		Test.startTest();
		NameFormattingMasterDataSelector selector = NameFormattingMasterDataSelector.getInstance();
		NameFormattingMasterData__c format = [SELECT Id,Type__c FROM NameFormattingMasterData__c LIMIT 1];
		List<NameFormattingMasterData__c> result = selector.getByObjTypePurposeDocTemplate(
			'PaymentReceipt__c',
			'Format',
			'Object',
			null
		);
		System.assertEquals(format.Type__c, result[0].Type__c);
		Test.stopTest();
	}
}