@isTest
public class Product2SelectorTest {
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

	}
	@isTest
	static void getProduct2ByIdTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Product2 testProduct = [SELECT Id,Name FROM Product2 WHERE ProductCode = 'PP01'];
		Set<Id> products = new Set<Id>();
		products.add(testProduct.Id);
		Product2Selector productSelector = Product2Selector.getInstance();
		Map<Id,Product2> productMap = productSelector.getProduct2ById(products);
		Product2 productTest = productMap.get(testProduct.Id);
		System.assertEquals(productTest.Name, testProduct.Name );
		Test.stopTest();
	}
}