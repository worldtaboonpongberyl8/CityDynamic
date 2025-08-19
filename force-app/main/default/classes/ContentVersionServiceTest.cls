@isTest
public with sharing class ContentVersionServiceTest {
	@isTest
	static void insertContentVersionsTest() {
		DataMaker dataMaker = DataMaker.getInstance();
		ContentVersion contentVersion = dataMaker.createContentVersion('FileName','sample.jpg');
		List<ContentVersion> contentVersions = new List<ContentVersion>{ contentVersion };

		Database.SaveResult[] results = ContentVersionService.getInstance().insertContentVersions(contentVersions);
		System.assertEquals(1, results.size());
		System.assertEquals(true, results.get(0).success);

		List<ContentVersion> ctVerResults = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Title = 'FileName'];
		System.assertEquals(1, ctVerResults.size());
		System.assertEquals(results.get(0).id, ctVerResults.get(0).Id);
	}

	@isTest
	static void getContentVerIdSetTest() {
		DataMaker dataMaker = DataMaker.getInstance();
		ContentVersion contentVersion = dataMaker.createContentVersion('FileName','sample.jpg');
		insert contentVersion;

		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert testProject;

		Map<Id, ContentVersion> contentVerMapByRecordId = new Map<Id, ContentVersion>{
			testProject.Id => contentVersion
		};

		Set<Id> resultIdSet = ContentVersionService.getInstance().getContentVerIdSet(contentVerMapByRecordId);
		System.assertEquals(1, resultIdSet.size());
	}

	@isTest
	static void getContentVerIdSetEmptyTest() {
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert testProject;

		Map<Id, ContentVersion> contentVerMapByRecordId = new Map<Id, ContentVersion>{
			testProject.Id => new ContentVersion()
		};

		Set<Id> resultIdSet = ContentVersionService.getInstance().getContentVerIdSet(contentVerMapByRecordId);
		System.assertEquals(0, resultIdSet.size());
	}
}