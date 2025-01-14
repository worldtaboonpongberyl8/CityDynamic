@isTest
public with sharing class PromotionOpportunitySelectorTest {
	@TestSetup
	static void makeData() {
		DataMaker dataMaker = DataMaker.getInstance();
		// Create Project
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert testProject;
		Project__c testProject2 = dataMaker.createProject('Test Project 2', 'AA02', 'CD');
		insert testProject2;
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
		// Create Promotion Master
		PromotionMaster__c promotionMasterSales1 = dataMaker.craeteActivePromotionMaster(
			null,
			null,
			'ส่วนลด',
			'Sales',
			'Discount (ส่วนลด)',
			'Add Detail',
			'Description',
			200.00
		);
		PromotionMaster__c promotionMasterMarketing1 = dataMaker.craeteActivePromotionMaster(
			testProject.Id,
			null,
			'ส่วนลด',
			'Marketing',
			'Discount (ส่วนลด)',
			'Add Detail',
			'Description',
			200.00
		);
		PromotionMaster__c promotionMasterMarketing2 = dataMaker.craeteActivePromotionMaster(
			testProject.Id,
			null,
			'ที่จอดรถ',
			'Marketing',
			'Premium (ของแถม)',
			'Add Detail',
			'Description',
			100.00
		);
		PromotionMaster__c promotionMasterMarketing3 = dataMaker.craeteActivePromotionMaster(
			testProject.Id,
			testProduct.Id,
			'ฟรีส่วนกลาง',
			'Marketing',
			'Premium (ของแถม)',
			'Add Detail',
			'Description',
			1000.00
		);
		PromotionMaster__c promotionMasterMarketing4 = dataMaker.craeteActivePromotionMaster(
			testProject2.Id,
			null,
			'ส่วนลด',
			'Marketing',
			'Discount (ส่วนลด)',
			'Add Detail',
			'Description',
			200.00
		);
		PromotionMaster__c promotionMasterMarketing5 = dataMaker.craeteActivePromotionMaster(
			testProject2.Id,
			null,
			'ที่จอดรถ',
			'Marketing',
			'Premium (ของแถม)',
			'Add Detail',
			'Description',
			100.00
		);
		List<PromotionMaster__c> promotionMasters = new List<PromotionMaster__c>{
			promotionMasterSales1,
			promotionMasterMarketing1,
			promotionMasterMarketing2,
			promotionMasterMarketing3,
			promotionMasterMarketing4,
			promotionMasterMarketing5
		};
		insert promotionMasters;
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
		OpportunityTriggerHandler handler = OpportunityTriggerHandler.getInstance();
		handler.setBypass();
		Opportunity opportunity = dataMaker.createOpportunity(
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
		insert opportunity;
		handler.clearBypass();
		// Create Promotion Opportunity
		PromotionOpportunity__c promotionOpp1 = dataMaker.createPromotionOpportunity(
			opportunity.Id,
			promotionMasterMarketing1.Id
		);
		PromotionOpportunity__c promotionOpp2 = dataMaker.createPromotionOpportunity(
			opportunity.Id,
			promotionMasterMarketing2.Id
		);
		List<PromotionOpportunity__c> promotionOpportunities = new List<PromotionOpportunity__c>{
			promotionOpp1,
			promotionOpp2
		};
		insert promotionOpportunities;
	}

	@isTest
	static void getPromotionOpportunitiesMapByOppIdTest() {
		Test.startTest();
		Map<Id, Opportunity> opportunityMapById = new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);
		PromotionOpportunitySelector selector = PromotionOpportunitySelector.getInstance();
		Map<Id, List<PromotionOpportunity__c>> promotionOpportunitiesMapByOppId = selector.getPromotionOpportunitiesMapByOppId(
			opportunityMapById.keySet()
		);
		System.assertEquals(2, promotionOpportunitiesMapByOppId.values()[0].size());
		Test.stopTest();
	}
}