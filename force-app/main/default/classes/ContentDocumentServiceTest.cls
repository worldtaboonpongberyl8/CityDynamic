@isTest
private class ContentDocumentServiceTest {
	@TestSetup
	static void makeData(){
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
		insert contentDocLink;
		
	}
	@isTest
	static void renameContentDocumentTitleTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'PP01'];
		ContentDocumentLink contentDocLink = [SELECT Id,LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :testProduct.Id];
		List<ContentDocumentLink> contentDocLinkList = new List<ContentDocumentLink>();
		contentDocLinkList.add(contentDocLink);
		ContentDocumentService service = ContentDocumentService.getInstance();
		service.renameContentDocumentTitle(contentDocLinkList);
		ContentDocument contentDoc = [SELECT Id, Title FROM ContentDocument WHERE Id =:contentDocLink.ContentDocumentId];
		System.assertEquals('Layout-TestProduct', contentDoc.Title);
		Test.stopTest();
	}
}