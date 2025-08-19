@IsTest
public class UnitReleasingControllerTest {
    @TestSetup
	static void makeData() {
		DataMaker dataMaker = DataMaker.getInstance();
		// Create Project
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert testProject;
		// Craete Floor
		Floor__c testFloor = dataMaker.createFloor('Test Floor', 'FF01', testProject.Id);
		insert testFloor;
		// Create Unit Type
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type', testProject.Id);
		insert unitType;
		// Create Unit
		Product2 testProduct = dataMaker.createUnit(
			'Test Product',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		Product2 testProduct2 = dataMaker.createUnit(
			'Test Product 2',
			'PP02',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		Product2 testProduct3 = dataMaker.createUnit(
			'Test Product 3',
			'PP03',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		List<Product2> products = new List<Product2>{testProduct,testProduct2,testProduct3};
		insert products;
		// Create Pricebook Entry
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(
			testProduct.Id,
			15000000,
			20000000,
			10000000
		);
		testPricebookEntry1.Pricebook2Id = pricebookId;
		testPricebookEntry1.UseStandardPrice = false;
		testPricebookEntry1.IsActive = true;
		PricebookEntry testPricebookEntry2 = dataMaker.createPricebookEntries(
			testProduct2.Id,
			15000000,
			20000000,
			10000000
		);
		testPricebookEntry2.Pricebook2Id = pricebookId;
		testPricebookEntry2.UseStandardPrice = false;
		PricebookEntry testPricebookEntry3 = dataMaker.createPricebookEntries(
			testProduct3.Id,
			15000000,
			20000000,
			10000000
		);
		testPricebookEntry3.Pricebook2Id = pricebookId;
		testPricebookEntry3.UseStandardPrice = false;
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{testPricebookEntry1,testPricebookEntry2,testPricebookEntry3};
		insert pricebookEntries;
		// Creat Account
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
		Account account2 = dataMaker.createAccount(recordTypeId, 'Test Account 2');
		Account account3 = dataMaker.createAccount(recordTypeId, 'Test Account 3');
		List<Account> accounts = new List<Account>{account,account2,account3};
		insert accounts;
		// Create Opportunity
		Opportunity opportunity = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Thai',
			null,
			testProject.Id
		);
		insert opportunity;
	}

	@isTest
	static void completeUnitReleasingTest(){
		List<Product2> products = [SELECT Id FROM Product2];
		Product2 targetProduct = products[0];
		Test.startTest();
			Map<String,List<SObject>> result = UnitReleasingController.completeUnitReleasing(targetProduct.Id);
		Test.stopTest();
		List<Product2> targetResults = result.get('releasedUnit');
		for (Product2 targetResult : targetResults){
			System.assertEquals('Available', targetResult.Status__c);
		}
	}

	@isTest
	static void getUnitPricesFromPricebookEntryTest(){
		Product2 targetUnit = [SELECT Id,TQUnitPrice__c,FQUnitPrice__c FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
		Opportunity targetOpportunity = [SELECT Id FROM Opportunity WHERE Unit__c =: targetUnit.Id ];
		UnitReleasingController.InputWrapper input = new UnitReleasingController.InputWrapper();
		input.opportunityId = targetOpportunity.Id;
		Test.startTest();
			List<UnitReleasingController.OutputWrapper> result = UnitReleasingController.getUnitPricesFromPricebookEntry(new List<UnitReleasingController.InputWrapper>{input});
		Test.stopTest();
	}
}