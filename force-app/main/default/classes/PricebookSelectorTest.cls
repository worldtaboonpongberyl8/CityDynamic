@isTest
private class PricebookSelectorTest {
	@TestSetup
	static void makeData(){
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert testProject;
		Floor__c testFloor = dataMaker.createFloor('Test Floor', 'FF01' , testProject.Id);
		insert testFloor;
		Project__c project = [SELECT Id FROM Project__c WHERE ProjectCode__c = 'AA01'];
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type', project.Id);
		insert unitType;
		Floor__c floor = [SELECT Id FROM Floor__c WHERE FloorCode__c = 'FF01'];
		Product2 testProduct = dataMaker.createUnit('Test Product','PP01',project.Id,floor.Id,'Available',unitType.Id);
		insert testProduct;
		Pricebook2 testPricebook = dataMaker.createPricebook('Test Pricebook', testProduct.Id);
		insert testPricebook;
	}
	@isTest
	static void getPricebookByProductIdTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c project = [SELECT Id FROM Project__c WHERE ProjectCode__c = 'AA01'];
		Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'PP01'];
		Set<Id> productIds = new Set<Id>();
		productIds.add(product.Id);
		PricebookSelector pricebookSelector = PricebookSelector.getInstance();
		Map<Id, Pricebook2> pricebookMap = pricebookSelector.getPricebookByProductId(productIds);
		Pricebook2 pricebook = pricebookMap.get(product.Id);
		System.assertEquals(product.Id, pricebook.Product2__c);
		Test.stopTest();
	}
}