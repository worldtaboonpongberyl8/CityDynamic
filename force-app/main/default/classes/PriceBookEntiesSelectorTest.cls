@isTest
private class PriceBookEntiesSelectorTest {
	@TestSetup
	static void makeData(){
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert testProject;
		Floor__c testFloor =dataMaker.createFloor('Test Floor', 'FF01' , testProject.Id);
		insert testFloor;
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type', testProject.Id);
		insert unitType;
		Product2 testProduct = dataMaker.createUnit('Test Product','PP01',testProject.Id,testFloor.Id,'Available',unitType.Id);
		insert testProduct;
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 150000, 200000,10000000);
		testPricebookEntry1.Pricebook2Id = pricebookId;
		testPricebookEntry1.UseStandardPrice = false;
		testPricebookEntry1.IsActive = true;
		insert testPricebookEntry1;
	}
	@isTest
	static void getPricebookEntiesByProductIdTest() {
		Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'PP01'];
		Map<Id, PricebookEntry> resultMap = PriceBookEntrySelector.getInstance().getPricebookEntiesByProductId(new Set<Id>{testProduct.Id});
		PricebookEntry resultPricebookEntry = [SELECT Id, Product2Id, TQUnitPrice__c,FQUnitPrice__c,TQUnitPricesqm__c,FQUnitPricesqm__c FROM PricebookEntry WHERE Product2Id =: testProduct.Id AND IsActive = true];
		// System.assertEquals(resultPricebookEntry, resultMap.get(resultPricebookEntry.Product2Id));
	}
}