@isTest
private class ContentVersionSelectorTest {
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
	static void getByIdSetTest() {
		ContentVersion testContentVersion = [SELECT Id FROM ContentVersion LIMIT 1];
		List<ContentVersion> selector = ContentVersionSelector.getInstance().getByIdSet(new Set<Id>{testContentVersion.Id});

		System.assertEquals(testContentVersion.Id, selector[0].Id);
		System.assertEquals(1, selector.size());

	}
	@isTest
	static void getByIdTest() {
		ContentVersion testContentVersion = [SELECT Id FROM ContentVersion LIMIT 1];
		ContentVersion selector = ContentVersionSelector.getInstance().getById(testContentVersion.Id);

		System.assertEquals(testContentVersion.Id, selector.Id);

	}
	@isTest
	static void getByDocIdAndTitleAndExtensionSetTest() {
		ContentVersion testContentVersion = [SELECT Id FROM ContentVersion LIMIT 1];
		Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'PP01'];
		ContentDocumentLink contentDocLink = [SELECT Id,LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :testProduct.Id];
		ContentDocument contentDoc = [SELECT Id, Title FROM ContentDocument WHERE Id =:contentDocLink.ContentDocumentId];
		List<ContentVersion> selector = ContentVersionSelector.getInstance().getByDocIdAndTitleAndExtensionSet(new Set<Id>{contentDoc.Id},new Set<String>{contentDoc.Title},new Set<String>{'jpg'});
		System.assertEquals(testContentVersion.Id, selector[0].Id);

	}
}