@isTest
private class ContentDocumentLinkTriggerHandlerTest {
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
	}
	@isTest
	static void afterInsertTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c project = [SELECT Id FROM Project__c WHERE ProjectCode__c = 'AA01'];
		Floor__c floor = [SELECT Id FROM Floor__c WHERE FloorCode__c = 'FF01'];
		ContentVersion testContentVersion =  [SELECT Id , Title ,ContentDocumentId FROM ContentVersion LIMIT 1];
		Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'PP01'];
		ContentDocumentLink contentDocLink = dataMaker.createContentDocumentLink(testProduct.Id,testContentVersion.ContentDocumentId);
		insert contentDocLink;
		System.debug('ContentDocumentLink: '+contentDocLink);
		ContentDocument contentDoc = [SELECT Id, Title FROM ContentDocument WHERE Id =:testContentVersion.ContentDocumentId];
		System.assertEquals('Layout-TestProduct', contentDoc.Title);
		Test.stopTest();
	}
	@isTest
	static void setBypassTest(){
		Test.startTest();
		ContentDocumentLinkTriggerHandler handler = ContentDocumentLinkTriggerHandler.getInstance();
		handler.setBypass();
		System.assertEquals(false, handler.isActive);
		System.assertEquals(false, handler.isTriggerActivated());
		Test.stopTest();
	}

	@isTest
	static void clearBypassTest(){
		Test.startTest();
		ContentDocumentLinkTriggerHandler handler = ContentDocumentLinkTriggerHandler.getInstance();
		handler.clearBypass();
		System.assertEquals(true, handler.isActive);
		System.assertEquals(true, handler.isTriggerActivated());
		Test.stopTest();
	}
}