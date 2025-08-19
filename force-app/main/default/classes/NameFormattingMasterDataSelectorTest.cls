@isTest
public with sharing class NameFormattingMasterDataSelectorTest {
	@isTest
	static void getByObjTypePurposeDocTemplateTest() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
            ObjectName__c = 'Contract',
            RunningFormat__c = 'Contract_{Account.Name}_{StartDate:FORMATDATETH:d MMMM yyyy}_{EndDate:FORMATDATETH:d MMMM yyyy}_{RUNNINGNUMBER:0000}',
            RunningPurpose__c = 'Document',
            Type__c = 'Format',
            CurrentRunningNumber__c = 1,
            DocumentTemplateMappingType__c = 'Contract'
        );
		insert runningNumberFormatDocument;

		List<NameFormattingMasterData__c> result = NameFormattingMasterDataSelector.getInstance().getByObjTypePurposeDocTemplate(
			'Contract',
			'Format',
			'Document',
			'Contract'
		);

		System.assertEquals(runningNumberFormatDocument.ObjectName__c, result.get(0).ObjectName__c);
		System.assertEquals(runningNumberFormatDocument.Type__c, result.get(0).Type__c);
		System.assertEquals(runningNumberFormatDocument.RunningFormat__c, result.get(0).RunningFormat__c);
		System.assertEquals(runningNumberFormatDocument.RunningPurpose__c, result.get(0).RunningPurpose__c);
		System.assertEquals(runningNumberFormatDocument.DocumentTemplateMappingType__c, result.get(0).DocumentTemplateMappingType__c);
	}

	@isTest
	static void getByObjTypePurposeDocTemplateRunningKeyTest() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Contract',
			RunningFormat__c = null,
			RunningKey__c = 'Contract_United Oil_{RUNNINGNUMBER:0000}',
			RunningPurpose__c = 'Object',
			Type__c = 'Running Number',
			CurrentRunningNumber__c = 5
		);
		insert runningNumberFormatDocument;

		Set<String> runningKeySet = new Set<String>{
			'Contract_United Oil_{RUNNINGNUMBER:0000}'
		};

		List<NameFormattingMasterData__c> result = NameFormattingMasterDataSelector.getInstance().getByObjTypePurposeDocTemplateRunningKey(
			'Contract',
			'Running Number',
			'Object',
			null,
			runningKeySet
		);

		System.assertEquals(runningNumberFormatDocument.ObjectName__c, result.get(0).ObjectName__c);
		System.assertEquals(runningNumberFormatDocument.Type__c, result.get(0).Type__c);
		System.assertEquals(runningNumberFormatDocument.RunningFormat__c, result.get(0).RunningFormat__c);
		System.assertEquals(runningNumberFormatDocument.RunningKey__c, result.get(0).RunningKey__c);
		System.assertEquals(runningNumberFormatDocument.CurrentRunningNumber__c, result.get(0).CurrentRunningNumber__c);
		System.assertEquals(runningNumberFormatDocument.DocumentTemplateMappingType__c, result.get(0).DocumentTemplateMappingType__c);
	}
}