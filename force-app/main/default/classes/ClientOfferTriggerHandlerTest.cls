@isTest
public with sharing class ClientOfferTriggerHandlerTest {
	@TestSetup
	static void makeData(){
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
		// Create Promotion Master
		PromotionMaster__c promotionMaster = dataMaker.craeteActivePromotionMaster(testProject.Id,testProduct.Id,'ส่วนลด','Sales','Discount (ส่วนลด)','Add Detail','Description',500.00);
		insert promotionMaster;
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
		oppTriggerHandler.clearBypass();
	}

	@isTest
	static void insertClientOfferTest(){
		Test.startTest();
		ClientOfferService service = ClientOfferService.getInstance();
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		PromotionMaster__c promotionMaster = [SELECT Id,PromotionCost__c FROM PromotionMaster__c LIMIT 1];
		List<ClientOffer__c> clientOffers = new List<ClientOffer__c>{
			dataMaker.createClientOffer(promotionMaster.Id,opportunity.Id,null)
		};
		insert clientOffers;
		List<ClientOffer__c> resultClientOffers = [SELECT Id,OriginalCost__c FROM ClientOffer__c];
		for (ClientOffer__c clientOffer : resultClientOffers){
			System.assertEquals(promotionMaster.PromotionCost__c, clientOffer.OriginalCost__c);
		}
		Test.stopTest();
	}

	@isTest
	static void setBypassTest(){
		Test.startTest();
		ClientOfferTriggerHandler handler = ClientOfferTriggerHandler.getInstance();
		handler.setBypass();
		System.assertEquals(false, handler.isActive);
		System.assertEquals(false, handler.isTriggerActivated());
		Test.stopTest();
	}

	@isTest
	static void clearBypassTest(){
		Test.startTest();
		ClientOfferTriggerHandler handler = ClientOfferTriggerHandler.getInstance();
		handler.clearBypass();
		System.assertEquals(true, handler.isActive);
		System.assertEquals(true, handler.isTriggerActivated());
		Test.stopTest();
	}
}