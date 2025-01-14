@isTest
public with sharing class PromotionMasterSelectorTest {

	@TestSetup
	static void makeData(){
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
		PromotionMaster__c promotionMasterSales1 = dataMaker.craeteActivePromotionMaster(null,null,'ส่วนลด','Sales','Discount (ส่วนลด)','Add Detail','Description',200.00);
		insert promotionMasterSales1;
		PromotionMaster__c promotionMasterMarketing1 = dataMaker.craeteActivePromotionMaster(testProject.Id,null,'ส่วนลด','Marketing','Discount (ส่วนลด)','Add Detail','Description',200.00);
		insert promotionMasterMarketing1;
		PromotionMaster__c promotionMasterMarketing2 = dataMaker.craeteActivePromotionMaster(testProject.Id,null,'ที่จอดรถ','Marketing','Premium (ของแถม)','Add Detail','Description',100.00);
		insert promotionMasterMarketing2;
		PromotionMaster__c promotionMasterMarketing3 = dataMaker.craeteActivePromotionMaster(testProject.Id,testProduct.Id,'ฟรีส่วนกลาง','Marketing','Premium (ของแถม)','Add Detail','Description',1000.00);
		insert promotionMasterMarketing3;
		PromotionMaster__c promotionMasterMarketing4 = dataMaker.craeteActivePromotionMaster(testProject2.Id,null,'ส่วนลด','Marketing','Discount (ส่วนลด)','Add Detail','Description',200.00);
		insert promotionMasterMarketing4;
		PromotionMaster__c promotionMasterMarketing5 = dataMaker.craeteActivePromotionMaster(testProject2.Id,null,'ที่จอดรถ','Marketing','Premium (ของแถม)','Add Detail','Description',100.00);
		insert promotionMasterMarketing5;
		PromotionMaster__c promotionMasterMarketing6 = dataMaker.craeteActivePromotionMaster(testProject2.Id,testProduct3.Id,'ฟรีส่วนกลาง','Marketing','Premium (ของแถม)','Add Detail','Description',1000.00);
		insert promotionMasterMarketing6;
	}


	@isTest
	static void getPromotionMasterMapByIdTest(){
		Test.startTest();
		PromotionMasterSelector selector = PromotionMasterSelector.getInstance();
		List<PromotionMaster__c> targetPromotionMasters = [ SELECT Id FROM PromotionMaster__c];
		Set<Id> promotionMasterIds = new Set<Id>();
		for (PromotionMaster__c promotionMaster : targetPromotionMasters){
			promotionMasterIds.add(promotionMaster.Id);
		}
		Map<Id, PromotionMaster__c> promotionMasterMapById = selector.getPromotionMasterMapById(promotionMasterIds);
		for (Integer i = 0; i < targetPromotionMasters.size(); i ++){
			System.assertEquals(targetPromotionMasters[i].Id , promotionMasterMapById.values()[i].Id);
		}
		Test.stopTest();
	}

	@isTest
	static void getMarketingPromotionsMapByKeyTest(){
		Test.startTest();
		PromotionMasterSelector selector = PromotionMasterSelector.getInstance();
		Set<String> projectCodes = new Set<String>{'PJ01','PJ02'};
		Set<String> unitCodes = new Set<String>{'UN01','UN02','UN03','UN04'};
		Map<String, List<PromotionMaster__c>> marketingPromotionMapByKey = selector.getMarketingPromotionsMapByKey(projectCodes,unitCodes);
		List<String> keyList = new List<String>(marketingPromotionMapByKey.keySet());
		System.assertEquals(4, keyList.size());
		// System.assertEquals('PJ01', keyList[0]);
		// System.assertEquals('PJ01_UN01', keyList[1]);
		// System.assertEquals('PJ02', keyList[2]);
		// System.assertEquals('PJ02_UN03', keyList[3]);
		Test.stopTest();
	}
}