/**
 * Phase2
 * Details:
 * - Add new class to be test class of OpportunityAccountChangeLogSelector
 */
@isTest
public class OpportunityAccountChangeLogSelectorTest {

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
		Opportunity opp1 = dataMaker.createOpportunity(
							account.Id,
							'Omitted',
							'Test Opp',
							Date.today(),
							'Open',
							testProduct.Id,
							'Foreign',
							null,
							testProject.Id
						);
		Opportunity opp2 = dataMaker.createOpportunity(
							account.Id,
							'Omitted',
							'Test Opp2',
							Date.today(),
							'Open',
							testProduct.Id,
							'Foreign',
							null,
							testProject.Id
						);
		Opportunity opp3 = dataMaker.createOpportunity(
							account.Id,
							'Omitted',
							'Test Opp3',
							Date.today(),
							'Open',
							testProduct.Id,
							'Foreign',
							null,
							testProject.Id
						);
		List<Opportunity> opportunities = new List<Opportunity>{opp1,opp2,opp3};
		insert opportunities;
		// Craete OpportunityAccountChangeLog__c
		OpportunityAccountChangeLog__c oppAccChangeLog = dataMaker.createOpportunityAccountChangeLog(opp1.Id,opp2.Id,opp1.AccountId,opp2.AccountId);
		List<OpportunityAccountChangeLog__c> oppAccChangeLogs = new List<OpportunityAccountChangeLog__c>{oppAccChangeLog};
		insert oppAccChangeLogs;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method getOpportunityAccountChangeLogWithSnapshotReceipts
	 */
	@isTest
	static void getOpportunityAccountChangeLogWithSnapshotReceiptsTest(){
		Test.startTest();
		OpportunityAccountChangeLogSelector selector = OpportunityAccountChangeLogSelector.getInstance();
		Map<Id,OpportunityAccountChangeLog__c> oppAccChangeLogMapById = new Map<Id,OpportunityAccountChangeLog__c>([SELECT Id FROM OpportunityAccountChangeLog__c]);
		Map<Id,OpportunityAccountChangeLog__c> targetResult = selector.getOpportunityAccountChangeLogWithSnapshotReceipts(oppAccChangeLogMapById.keySet());
		System.assertEquals(oppAccChangeLogMapById.values().size(), targetResult.values().size());
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method getOpportunityAccountChangeLogFromPreviousOpportuntiyId
	 */
	@isTest
	static void getOpportunityAccountChangeLogFromPreviousOpportuntiyIdTest(){
		Test.startTest();
		OpportunityAccountChangeLogSelector selector = OpportunityAccountChangeLogSelector.getInstance();
		OpportunityAccountChangeLog__c oppAccChangeLog = [SELECT Id,PreviousOpportunity__c,PreviousAccount__c FROM OpportunityAccountChangeLog__c LIMIT 1];
		Map<Id,OpportunityAccountChangeLog__c> targetResult = selector.getOpportunityAccountChangeLogFromPreviousOpportuntiyIdMapByPreviousAccountId(new Set<Id>{oppAccChangeLog.PreviousAccount__c});
		Test.stopTest();
	}
}