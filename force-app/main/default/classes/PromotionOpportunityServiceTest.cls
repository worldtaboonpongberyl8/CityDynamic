@isTest
public with sharing class PromotionOpportunityServiceTest {
	@TestSetup
	static void makeData() {
		DataMaker dataMaker = DataMaker.getInstance();
		// Create Project
		Project__c testProject = dataMaker.createProject('Test Project', 'PJ01', 'CD');
		insert testProject;
		Project__c testProject2 = dataMaker.createProject('Test Project 2', 'PJ02', 'CD');
		insert testProject2;
		// Craete Floor
		Floor__c testFloor = dataMaker.createFloor('Test Floor', 'FF01', testProject.Id);
		insert testFloor;
		Floor__c testFloor2 = dataMaker.createFloor('Test Floor 2', 'FF02', testProject2.Id);
		insert testFloor2;
		// Create Unit Type
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type', testProject.Id);
		insert unitType;
		UnitType__c unitType2 = dataMaker.createUnitType('Test Unit Type', testProject2.Id);
		insert unitType2;
		// Create Unit
		Product2 testProduct = dataMaker.createUnit(
			'Test Product 1',
			'UN01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert testProduct;
		Product2 testProduct2 = dataMaker.createUnit(
			'Test Product 1',
			'UN02',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert testProduct2;
		Product2 testProduct3 = dataMaker.createUnit(
			'Test Product 3',
			'UN03',
			testProject2.Id,
			testFloor2.Id,
			'Available',
			unitType2.Id
		);
		insert testProduct3;
		Product2 testProduct4 = dataMaker.createUnit(
			'Test Product 4',
			'UN04',
			testProject2.Id,
			testFloor2.Id,
			'Available',
			unitType2.Id
		);
		insert testProduct4;
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
		// Create Account
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
		insert account;
		// Create Opportunity
		OpportunityTriggerHandler oppTriggerHandler = OpportunityTriggerHandler.getInstance();
		oppTriggerHandler.setBypass();
		Opportunity opportunity1 = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp with Unit 1',
			Date.today(),
			'Open',
			testProduct.Id,
			'Foreign',
			null,
			testProject.Id
		);
		insert opportunity1;
		Opportunity opportunity2 = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp with Unit 3',
			Date.today(),
			'Open',
			testProduct3.Id,
			'Foreign',
			null,
			testProject2.Id
		);
		insert opportunity2;
	}

	@isTest
	static void createPromotionOpportunityRelateToOpportunityTest() {
		Test.startTest();
		PromotionOpportunityService service = PromotionOpportunityService.getInstance();
		List<Opportunity> opportunities = [SELECT Id, ProjectCode__c, UnitCode__c FROM Opportunity];
		Opportunity targetOpp1 = opportunities[0];
		System.debug('key for opp1: ' + targetOpp1.ProjectCode__c + '_' + targetOpp1.UnitCode__c);
		Opportunity targetOpp2 = opportunities[1];
		System.debug('key for opp2: ' + targetOpp2.ProjectCode__c + '_' + targetOpp2.UnitCode__c);
		List<PromotionOpportunity__c> promotionOpportunities = service.createPromotionOpportunityRelateToOpportunity(
			opportunities
		);
		System.assertEquals(3, promotionOpportunities.size());
		List<PromotionOpportunity__c> promotionOpportunitiesInOpp1 = new List<PromotionOpportunity__c>();
		List<PromotionOpportunity__c> promotionOpportunitiesInOpp2 = new List<PromotionOpportunity__c>();
		for (PromotionOpportunity__c promotionOpportunity : promotionOpportunities) {
			if (promotionOpportunity.Opportunity__c == targetOpp1.Id) {
				promotionOpportunitiesInOpp1.add(promotionOpportunity);
			} else if (promotionOpportunity.Opportunity__c == targetOpp2.Id) {
				promotionOpportunitiesInOpp2.add(promotionOpportunity);
			}
		}
		System.assertEquals(1, promotionOpportunitiesInOpp1.size());
		System.assertEquals(2, promotionOpportunitiesInOpp2.size());
		Test.stopTest();
	}

	@isTest
	static void createPromotionOpportunityRelateToOpportunityNegativeTest() {
		Test.startTest();
		PromotionOpportunityService service = PromotionOpportunityService.getInstance();
		List<Opportunity> opportunities = [SELECT Id, Project__c,ProjectCode__c, UnitCode__c FROM Opportunity];
		Opportunity targetOpp1 = opportunities[0];
		targetOpp1.Project__c = null;
		OpportunityTriggerHandler.getInstance().setBypass();
		update targetOpp1;
		OpportunityTriggerHandler.getInstance().clearBypass();
		List<Opportunity> updatedOpportunities = [SELECT Id, Project__c,ProjectCode__c, UnitCode__c FROM Opportunity];
		List<PromotionOpportunity__c> promotionOpportunities = service.createPromotionOpportunityRelateToOpportunity(
			updatedOpportunities
		);
		Test.stopTest();
	}

	@isTest
	static void deleteAndCreateNewPromotionOpportunityTest(){
		Test.startTest();
		PromotionOpportunityService service = PromotionOpportunityService.getInstance();
		Product2 targetUnit = [SELECT Id FROM Product2 WHERE ProductCode = 'UN01' LIMIT 1];
		List<Opportunity> opportunities = [SELECT Id, Unit__c, ProjectCode__c, UnitCode__c FROM Opportunity];
		PromotionMaster__c targetPromotionMaster = [SELECT Id FROM PromotionMaster__c WHERE Unit__r.ProductCode = 'UN01' LIMIT 1];
		opportunities[1].Unit__c = targetUnit.Id;
		List<PromotionOpportunity__c> promotionOpportunities = service.deleteAndCreateNewPromotionOpportunity(opportunities);
		Test.stopTest();
	}
}