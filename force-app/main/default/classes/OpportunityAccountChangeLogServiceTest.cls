/**
 * Phase2
 * Details:
 * - Add new class to be test class of OpportunityAccountChangeLogService
 */
@isTest
public class OpportunityAccountChangeLogServiceTest {
    @TestSetup
	static void makeData() {
		DataMaker dataMaker = DataMaker.getInstance();
		// Create Project
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		testProject.NovationFee__c = 1000;
		insert testProject;
		// Craete Floor
		Floor__c testFloor = dataMaker.createFloor('Test Floor', 'FF01', testProject.Id);
		insert testFloor;
		// Create Unit Type
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type', testProject.Id);
		insert unitType;
		// Create Unit
		Product2 testProduct = dataMaker.createUnit(
			'Test Product 1',
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
		List<Product2> products = new List<Product2>{ testProduct, testProduct2, testProduct3 };
		insert products;
		// create Payment Term Master
		PaymentTermMaster__c paymentTermMaster = dataMaker.craetePaymentTermMaster(
			testProject.Id,
			'TQ Series 5-10-85',
			'Series',
			'Thai',
			25
		);
		insert paymentTermMaster;
		// create Payment Term Line Item
		List<PaymentTerm__c> paymentTermLineItems = new List<PaymentTerm__c>();
		PaymentTerm__c contractPaymentTerm = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			1,
			10000,
			null,
			'Contract'
		);
		paymentTermLineItems.add(contractPaymentTerm);
		for (Integer i = 0; i < 12; i++) {
			PaymentTerm__c installmentPaymentTerm = dataMaker.createPaymentTermLineItem(
				paymentTermMaster.Id,
				i + 2,
				5000,
				null,
				'Installment ' + String.valueOf(i + 1)
			);
			paymentTermLineItems.add(installmentPaymentTerm);
		}
		PaymentTerm__c transferPaymentTerm = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			13,
			null,
			null,
			'Transfer'
		);
		paymentTermLineItems.add(transferPaymentTerm);
		insert paymentTermLineItems;
		// Create Account
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
		insert account;
		Account account2 = dataMaker.createAccount(recordTypeId, 'Test Account 2');
		insert account2;
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 150000, 200000,10000000);
		testPricebookEntry1.Pricebook2Id = pricebookId;
		testPricebookEntry1.UseStandardPrice = false;
		insert testPricebookEntry1;
		PricebookEntry testPricebookEntry2 = dataMaker.createPricebookEntries(testProduct2.Id, 150000, 200000,10000000);
		testPricebookEntry2.Pricebook2Id = pricebookId;
		testPricebookEntry2.UseStandardPrice = false;
		insert testPricebookEntry2;
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
			'Thai',
			paymentTermMaster.Id,
			testProject.Id
		);
		Opportunity opportunity2 = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp with Unit 2',
			Date.today(),
			'Open', //Reservation
			testProduct2.Id,
			'Foreign',
			null,
			testProject.Id
		);
		Opportunity opportunity3 = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp with Unit 3',
			Date.today(),
			'Open', //Transfer
			testProduct3.Id,
			'Foreign',
			null,
			testProject.Id
		);
		List<Opportunity> opportunities = new List<Opportunity>{ opportunity1, opportunity2, opportunity3 };
		insert opportunities;
		oppTriggerHandler.clearBypass();
		// Craete OpportunityAccountChangeLog__c
		OpportunityAccountChangeLog__c oppAccChangeLog = dataMaker.createOpportunityAccountChangeLog(opportunity1.Id,opportunity2.Id,opportunity1.AccountId,opportunity2.AccountId);
		List<OpportunityAccountChangeLog__c> oppAccChangeLogs = new List<OpportunityAccountChangeLog__c>{oppAccChangeLog};
		insert oppAccChangeLogs;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method craeteOpportunityAccountChangeLogFromPreviousAndCurrentOpportunity
	 */
	@isTest
	static void craeteOpportunityAccountChangeLogFromPreviousAndCurrentOpportunityTest(){
		Test.startTest();
		OpportunityAccountChangeLogService service = OpportunityAccountChangeLogService.getInstance();
		List<Opportunity> opportunities = [SELECT Id,AccountId FROM Opportunity];
		Opportunity targetOpportunity1 = opportunities[0];
		Opportunity targetOpportunity2 = opportunities[1];
		OpportunityAccountChangeLog__c oppAccChangeLog = service.craeteOpportunityAccountChangeLogFromPreviousAndCurrentOpportunity(targetOpportunity1,targetOpportunity2);
		System.assertEquals(targetOpportunity1.Id, oppAccChangeLog.PreviousOpportunity__c);
		System.assertEquals(targetOpportunity1.AccountId, oppAccChangeLog.PreviousAccount__c);
		System.assertEquals(targetOpportunity2.Id, oppAccChangeLog.CurrentOpportunity__c);
		System.assertEquals(targetOpportunity2.AccountId, oppAccChangeLog.CurrentAccount__c);
		System.assertEquals(Datetime.now(), oppAccChangeLog.ChangedDatetime__c);
		Test.stopTest();
	}
}