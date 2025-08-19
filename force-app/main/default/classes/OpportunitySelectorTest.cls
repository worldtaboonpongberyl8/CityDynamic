@isTest
public with sharing class OpportunitySelectorTest {
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
		insert testProduct;
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
		insert testPricebookEntry1;
		// Creat Account
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
		insert account;
		// Create Opportunity
		List<Opportunity> opportunities = new List<Opportunity>{
			dataMaker.createOpportunity(
				account.Id,
				'Omitted',
				'Test Opp',
				Date.today(),
				'Open',
				testProduct.Id,
				'Foreign',
				null,
				testProject.Id
			),
			dataMaker.createOpportunity(
				account.Id,
				'Omitted',
				'Test Opp2',
				Date.today(),
				'Open',
				testProduct.Id,
				'Foreign',
				null,
				testProject.Id
			),
			dataMaker.createOpportunity(
				account.Id,
				'Omitted',
				'Test Opp3',
				Date.today(),
				'Open',
				testProduct.Id,
				'Foreign',
				null,
				testProject.Id
			)
		};
		insert opportunities;
	}

	@isTest
	static void getOpportunityMapByIdTest(){
		Test.startTest();
		OpportunitySelector selector = OpportunitySelector.getInstance();
		Map<Id,Opportunity> oppMapById = new Map<Id,Opportunity>([SELECT Id FROM Opportunity]);
		Map<Id,Opportunity> result = selector.getOpportunityMapById(oppMapById.keySet());
		System.assertEquals(oppMapById.values().size(), result.values().size());
		Test.stopTest();
	}

	@isTest
	static void getByIdTest(){
		Test.startTest();
		OpportunitySelector selector = OpportunitySelector.getInstance();
		Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		Opportunity result = selector.getById(opp.Id);
		System.assertEquals(result.Id, opp.Id);
		Test.stopTest();
	}

	@isTest
	static void getOpportunityWithCoBuyerMapByIdTest(){
		Test.startTest();
		OpportunitySelector selector = OpportunitySelector.getInstance();
		Map<Id,Opportunity> oppMapById = new Map<Id,Opportunity>([SELECT Id FROM Opportunity]);
		Map<Id,Opportunity> result = selector.getOpportunityWithCoBuyerMapById(oppMapById.keySet());
		System.assertEquals(oppMapById.values().size(), result.values().size());
		Test.stopTest();
	}

	@isTest
	static void getOpportunityWithSyncedQuotedMapByIdTest(){
		Test.startTest();
		OpportunitySelector selector = OpportunitySelector.getInstance();
		Map<Id,Opportunity> oppMapById = new Map<Id,Opportunity>([SELECT Id FROM Opportunity]);
		Map<Id,Opportunity> result = selector.getOpportunityWithSyncedQuotedMapById(oppMapById.keySet());
		System.assertEquals(oppMapById.values().size(), result.values().size());
		Test.stopTest();
	}

	@isTest
	static void getOpportunityWithClientOfferMapByIdTest(){
		Test.startTest();
		OpportunitySelector selector = OpportunitySelector.getInstance();
		Map<Id,Opportunity> oppMapById = new Map<Id,Opportunity>([SELECT Id FROM Opportunity]);
		Map<Id,Opportunity> result = selector.getOpportunityWithClientOfferMapById(oppMapById.keySet());
		System.assertEquals(oppMapById.values().size(), result.values().size());
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method getOpportuntiyWithRelatedRecordForNovationMapById
	 */
	@isTest
	static void getOpportuntiyWithRelatedRecordForNovationMapByIdTest(){
		Test.startTest();
		OpportunitySelector selector = OpportunitySelector.getInstance();
		Map<Id,Opportunity> oppMapById = new Map<Id,Opportunity>([SELECT Id FROM Opportunity]);
		Map<Id,Opportunity> result = selector.getOpportuntiyWithRelatedRecordForNovationMapById(oppMapById.keySet());
		System.assertEquals(oppMapById.values().size(), result.values().size());
		Test.stopTest();
	}
	/**
	 * Phase2
	 * Details:
	 * -Test Class query Opportunity by oppId and field set
	 */
	@isTest
	static void getOpportunityFieldsetByIdsTest(){
		Test.startTest();
		OpportunitySelector selector = OpportunitySelector.getInstance();
		Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		Map<Id, Opportunity> result = selector.getOpportunityFieldsetByIds(new Set<Id>{opp.Id});
		Test.stopTest();
	}
}