@isTest
public with sharing class ContentDocumentLinkServiceTest {
	@isTest
	static void insertContentDocumentLinksTest(){
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert testProject;
		Floor__c testFloor = dataMaker.createFloor('Test Floor', 'FF01' , testProject.Id);
		insert testFloor;
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type', testProject.Id);
		insert unitType;
		ContentVersion testContentVersion = dataMaker.createContentVersion('FileName','sample.jpg');
		insert testContentVersion;
		ContentVersion contentVersion = [SELECT Id , ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id];
		Product2 testProduct = dataMaker.createUnit('TestProduct','PP01',testProject.Id,testFloor.Id,'Available',unitType.Id);
		insert testProduct;
		ContentDocumentLink contentDocLink = dataMaker.createContentDocumentLink(testProduct.Id,contentVersion.ContentDocumentId);
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>{contentDocLink};

		Database.SaveResult[] results = ContentDocumentLinkService.getInstance().insertContentDocumentLinks(contentDocumentLinks);
		System.assertEquals(1, results.size());
		System.assertEquals(true, results.get(0).success);

		List<ContentDocumentLink> ctDocLinkResults = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: testProduct.Id];
		System.assertEquals(1, ctDocLinkResults.size());
		System.assertEquals(results.get(0).id, ctDocLinkResults.get(0).Id);
	}
}