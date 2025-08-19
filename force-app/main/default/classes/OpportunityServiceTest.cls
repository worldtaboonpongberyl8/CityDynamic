@isTest
public with sharing class OpportunityServiceTest {
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
		account.Nationality__c = 'Thai';
		account.TaxID__c = '1234';
		insert account;
		Account account2 = dataMaker.createAccount(recordTypeId, 'Test Account 2');
		insert account2;
		Account account3 = dataMaker.createAccount(recordTypeId, 'Test Account 3');
		account3.Nationality__c = 'Thai';
		account3.TaxID__c = '9999';
		insert account3;
		Account account4 = dataMaker.createAccount(recordTypeId, 'Test Account 4');
		account4.Nationality__c = 'Thai';
		account4.TaxID__c = '5678';
		insert account4;
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 150000, 200000,10000000);
		testPricebookEntry1.Pricebook2Id = pricebookId;
		testPricebookEntry1.UseStandardPrice = false;
		testPricebookEntry1.IsActive = true;
		insert testPricebookEntry1;
		PricebookEntry testPricebookEntry2 = dataMaker.createPricebookEntries(testProduct2.Id, 150000, 200000,10000000);
		testPricebookEntry2.Pricebook2Id = pricebookId;
		testPricebookEntry2.UseStandardPrice = false;
		testPricebookEntry2.IsActive = true;
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
		// Create Cobuyer
		CoBuyer__c targetCoBuyer = dataMaker.createCoBuyer(opportunity1.Id,account3.Id,'1');
		CoBuyer__c targetCoBuyer2 = dataMaker.createCoBuyer(opportunity1.Id,account4.Id,'1');
		List<CoBuyer__c> coBuyers = new List<CoBuyer__c>{targetCoBuyer,targetCoBuyer2};
		insert coBuyers;
	}

	@isTest
	static void assignUnitPriceTQToOpportunityTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'PP01'];
		Opportunity opp = [SELECT Id , AccountId ,Name ,ForecastCategoryName,CloseDate,Unit__c,Quota__c,StageName,PaymentTermMaster__c,NetPrice__c FROM Opportunity WHERE Unit__c =: product.Id AND Quota__c = 'Thai'];
		List<Opportunity> oppList = new List<Opportunity>();
		oppList.add(opp);
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> result = service.assignUnitPriceAndPeriodToOpportunity(oppList);
		System.assertEquals(10000000, result[0].UnitPrice__c);
		Test.stopTest();
	}

	@isTest
	static void assignUnitPriceFQToOpportunityTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'PP02'];
		Opportunity opp = [SELECT Id , AccountId ,Name ,ForecastCategoryName,CloseDate,Unit__c,Quota__c,StageName,PaymentTermMaster__c,NetPrice__c FROM Opportunity WHERE Unit__c =: product.Id AND Quota__c = 'Foreign'];
		List<Opportunity> oppList = new List<Opportunity>();
		oppList.add(opp);
		System.debug('Size Opp: '+oppList.size());
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> result = service.assignUnitPriceAndPeriodToOpportunity(oppList);
		System.assertEquals(10000000, result[0].UnitPrice__c);
		Test.stopTest();
	}

	@isTest
	static void stampOpportunitiesNameTest() {
		Test.startTest();
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> originalOpportunities = [
			SELECT Id, Name, Project__r.Name, Unit__r.ProductCode, AccountName__c
			FROM Opportunity
		];
		List<Opportunity> opportunities = [
			SELECT Id, Name, Project__r.Name, Unit__r.ProductCode, AccountName__c, OppNameFormat__c
			FROM Opportunity
		];
		service.stampOpportunitiesName(opportunities);
		for (Integer i = 0; i < opportunities.size(); i++) {
			System.assertNotEquals(originalOpportunities[i].Name, opportunities[i].Name);
		}
		Test.stopTest();
	}

	@isTest
	static void stampCoBuyerNameTest() {
		Test.startTest();
		OpportunityService service = OpportunityService.getInstance();
		DataMaker dataMaker = DataMaker.getInstance();
		Opportunity originalOpportunities = [
			SELECT Id, AccountName__c, CoBuyerName__c, IsCoBuyer__c
			FROM Opportunity
			LIMIT 1
		];
		Opportunity targetOpp = [SELECT Id, AccountName__c, CoBuyerName__c, IsCoBuyer__c FROM Opportunity LIMIT 1];
		Account targetAcc = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
		CoBuyer__c targetCoBuyer = dataMaker.createCoBuyer(targetOpp.Id, targetAcc.Id, '1');
		insert targetCoBuyer;
		List<Opportunity> opportunities = service.stampCoBuyerName(new List<Opportunity>{targetOpp});
		Opportunity updatedOpp = opportunities[0];
		System.assertEquals(true,updatedOpp.IsCoBuyer__c);
		System.assertNotEquals(originalOpportunities.CoBuyerName__c,updatedOpp.CoBuyerName__c);
		Test.stopTest();
	}

	@isTest
	static void stampContractAmountAndPercentTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Account targetAccount = [SELECT Id FROM Account LIMIT 1];
		Product2 targetUnit1 = [SELECT Id,TransferredDate__c,Status__c FROM Product2 WHERE ProductCode = 'PP01' LIMIT 1 ];
		PaymentTermMaster__c paymentTermMaster = [SELECT Id FROM PaymentTermMaster__c WHERE Quota__c = 'Thai'];
		Project__c targetProject = [SELECT Id FROM Project__c WHERE ProjectCode__c = 'AA01' LIMIT 1];
		Opportunity opp1 = [SELECT Id , ContractAmount__c,ContractPercent__c,PaymentTermMaster__c FROM Opportunity WHERE Name = 'Test Opp with Unit 1'];
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> result = service.stampContractAmountAndPercent(new List<Opportunity>{opp1});
		System.debug('Test Result Contract '+result);
		System.assertEquals(10000, result[0].ContractAmount__c);
		System.assertEquals(0, result[0].ContractPercent__c);
		Test.stopTest();
	}

	@isTest
	static void stampTotalInstallmentAmountAndPercentTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Account targetAccount = [SELECT Id FROM Account LIMIT 1];
		Product2 targetUnit1 = [SELECT Id,TransferredDate__c,Status__c FROM Product2 WHERE ProductCode = 'PP01' LIMIT 1 ];
		PaymentTermMaster__c paymentTermMaster = [SELECT Id FROM PaymentTermMaster__c WHERE Quota__c = 'Thai'];
		Project__c targetProject = [SELECT Id FROM Project__c WHERE ProjectCode__c = 'AA01' LIMIT 1];
		Opportunity opp1 = [SELECT Id , TotalInstallmentAmount__c,TotalInstallmentPercent__c,PaymentTermMaster__c FROM Opportunity WHERE Name = 'Test Opp with Unit 1'];

		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> result = service.stampTotalInstallmentAmountAndPercent(new List<Opportunity>{opp1});
		System.debug('Test Result Installment '+result);
		System.assertEquals(60000, result[0].TotalInstallmentAmount__c);
		System.assertEquals(0, result[0].TotalInstallmentPercent__c);
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method stampDefaultNovationFeeFromProject
	 */
	@isTest
	static void stampDefaultNovationFeeFromProjectTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Account targetAccount = [SELECT Id FROM Account LIMIT 1];
		Product2 targetUnit1 = [SELECT Id,TransferredDate__c,Status__c FROM Product2 WHERE ProductCode = 'PP01' LIMIT 1 ];
		PaymentTermMaster__c paymentTermMaster = [SELECT Id FROM PaymentTermMaster__c WHERE Quota__c = 'Thai'];
		Project__c targetProject = [SELECT Id,NovationFee__c FROM Project__c WHERE ProjectCode__c = 'AA01' LIMIT 1];
		Opportunity opp1 = [SELECT Id , TotalInstallmentAmount__c,TotalInstallmentPercent__c,PaymentTermMaster__c,Project__c,OperationFeeNovation__c,ActualOperationFeeNovation__c FROM Opportunity WHERE Name = 'Test Opp with Unit 1'];
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> result = service.stampDefaultNovationFeeFromProject(new List<Opportunity>{opp1});
		System.assertEquals(targetProject.NovationFee__c, result[0].OperationFeeNovation__c);
		System.assertEquals(targetProject.NovationFee__c, result[0].ActualOperationFeeNovation__c);
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method getClonedOpportunityForNovationProcess
	 */
	@isTest
	static void getClonedOpportunityForNovationProcessTest(){
		Test.startTest();
		OpportunityService service = OpportunityService.getInstance();
		Opportunity opportunity = [SELECT Id,NewCoOwner__c,StageName,NewCoOwner__r.Nationality__c FROM Opportunity LIMIT 1];
		Opportunity clonedOpp = service.getClonedOpportunityForNovationProcess(opportunity);
		System.assertEquals(opportunity.NewCoOwner__c, clonedOpp.AccountId);
		System.assertEquals(opportunity.Id, clonedOpp.NovateFromOpportunity__c);
		System.assertEquals(GlobalConstants.OPP_STAGENAME_SIGNEDNOVATION, clonedOpp.StageName);
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method getOpportunityAfterNovationProcess
	 */
	@isTest
	static void getOpportunityAfterNovationProcessTest(){
		Test.startTest();
		OpportunityService service = OpportunityService.getInstance();
		Opportunity opportunity = [SELECT Id,NewCoOwner__c,NovateFromOpportunity__c FROM Opportunity LIMIT 1];
		Opportunity updatedOpp = service.getOpportunityAfterNovationProcess(opportunity, new Opportunity());
		System.assertEquals(true, updatedOpp.IsNovationCompleted__c);
		System.assertEquals(null, updatedOpp.NovateFromOpportunity__c);
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method clonedRecordRelateWithOpportunity
	 */
	@isTest
	static void clonedRecordRelateWithOpportunityTest(){
		Test.startTest();
		OpportunityService service = OpportunityService.getInstance();
		Opportunity opportunity = [SELECT Id,NewCoOwner__c,NovateFromOpportunity__c FROM Opportunity LIMIT 1];
		List<SObject> results = service.clonedRecordRelateWithOpportunity(
			new List<OpportunityPayment__c>{
				new OpportunityPayment__c(),
				new OpportunityPayment__c()
			},
			opportunity.Id
		);
		for (SObject record : results){
			System.assertEquals(opportunity.Id, record.get('Opportunity__c'));
		}
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method stampFQQuotaIfForeignCoOwnerExists
	 */
	@isTest
	static void stampFQQuotaIfForeignCoOwnerExists(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		OpportunityService service = OpportunityService.getInstance();
		Opportunity opportunity = [SELECT Id,Quota__c FROM Opportunity WHERE Quota__c = 'Thai' LIMIT 1];
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account foreignAccount = dataMaker.createAccount(recordTypeId, 'Test Foreign Account');
		foreignAccount.Nationality__c = 'Chinese';
		foreignAccount.TaxID__c = '12345555';
		insert foreignAccount;
		CoBuyerTriggerHandler.getInstance().setBypass();
		CoBuyer__c foreignCoBuyer = dataMaker.createCoBuyer(opportunity.Id,foreignAccount.Id,'1');
		insert foreignCoBuyer;
		CoBuyerTriggerHandler.getInstance().clearBypass();
		List<Opportunity> updatedOpportunities = service.stampFQQuotaIfForeignCoOwnerExists(new List<Opportunity>{opportunity});
		Opportunity updatedOpportunity = updatedOpportunities[0];
		System.assertEquals('Foreign', updatedOpportunity.Quota__c);
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method validateIsQuotaAreaExceed
	 */
	@isTest
	static void validateIsQuotaAreaExceedTest(){
		Test.startTest();
		OpportunityService service = OpportunityService.getInstance();
		DataMaker dataMaker = DataMaker.getInstance();
		// Create Project
		Project__c testProject = dataMaker.createProject('Test Project 2', 'AA02', 'CD');
		testProject.NovationFee__c = 1000;
		testProject.TotalSalesAreaSqm__c = 10000;
		insert testProject;
		Test.stopTest();
		// Craete Floor
		Floor__c testFloor = dataMaker.createFloor('Test Floor 2', 'FF02', testProject.Id);
		insert testFloor;
		// Create Unit Type
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type 2', testProject.Id);
		insert unitType;
		// Create Unit
		Product2 testProduct = dataMaker.createUnit(
			'Test Product 4',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		testProduct.AreaSqm__c = 5000;
		List<Product2> products = new List<Product2>{ testProduct};
		insert products;
		// Get Account
		Account account = [SELECT Id FROM Account LIMIT 1];
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
		List<Opportunity> opportunities = new List<Opportunity>{ opportunity1 };
		insert opportunities;
		oppTriggerHandler.clearBypass();
		Opportunity opportunity = opportunities[0];
		List<Opportunity> targetOpps = [SELECT Id,Unit__r.AreaSqm__c,Project__c,AreaSqm__c FROM Opportunity WHERE Id =: opportunity.Id];
		Map<Id,Boolean> result = service.validateIsQuotaAreaExceed(targetOpps);
		System.assertEquals(false, result.get(opportunity1.Id));
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method getOpportunityAfterMovingProcess
	 */
	@isTest
	static void getOpportunityAfterMovingProcessTest(){
		Test.startTest();
		OpportunityService service = OpportunityService.getInstance();
		Opportunity oldOpp = [SELECT Id,UpgradeTo__c,DowngradeTo__c FROM Opportunity LIMIT 1];
		DataMaker dataMaker = DataMaker.getInstance();
		// Create Project
		Project__c testProject = dataMaker.createProject('Test Project 2', 'AA02', 'CD');
		testProject.NovationFee__c = 1000;
		testProject.TotalSalesAreaSqm__c = 10000;
		insert testProject;
		Test.stopTest();
		// Craete Floor
		Floor__c testFloor = dataMaker.createFloor('Test Floor 2', 'FF02', testProject.Id);
		insert testFloor;
		// Create Unit Type
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type 2', testProject.Id);
		insert unitType;
		// Create Unit
		Product2 testProduct = dataMaker.createUnit(
			'Test Product 4',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		testProduct.AreaSqm__c = 5000;
		List<Product2> products = new List<Product2>{ testProduct};
		insert products;
		// Get Account
		Account account = [SELECT Id FROM Account LIMIT 1];
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
		List<Opportunity> opportunities = new List<Opportunity>{ opportunity1 };
		insert opportunities;
		oppTriggerHandler.clearBypass();
		Opportunity newOpp = opportunities[0];
		Opportunity upgradedOldOpp = service.getOpportunityAfterMovingProcess(oldOpp,newOpp,'upgrade');
		System.assertEquals(newOpp.Id, upgradedOldOpp.UpgradeTo__c);
		Opportunity downgradeOldOpp = service.getOpportunityAfterMovingProcess(oldOpp,newOpp,'downgrade');
		System.assertEquals(newOpp.Id, downgradeOldOpp.DowngradeTo__c);
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method getNewOpportunityAfterMovingProcess
	 */
	@isTest
	static void getNewOpportunityAfterMovingProcessTest(){
		Test.startTest();
		OpportunityService service = OpportunityService.getInstance();
		Opportunity oldOpp = [SELECT Id,UpgradeTo__c,DowngradeTo__c FROM Opportunity LIMIT 1];
		DataMaker dataMaker = DataMaker.getInstance();
		// Create Project
		Project__c testProject = dataMaker.createProject('Test Project 2', 'AA02', 'CD');
		testProject.NovationFee__c = 1000;
		testProject.TotalSalesAreaSqm__c = 10000;
		insert testProject;
		Test.stopTest();
		// Craete Floor
		Floor__c testFloor = dataMaker.createFloor('Test Floor 2', 'FF02', testProject.Id);
		insert testFloor;
		// Create Unit Type
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type 2', testProject.Id);
		insert unitType;
		// Create Unit
		Product2 testProduct = dataMaker.createUnit(
			'Test Product 4',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		testProduct.AreaSqm__c = 5000;
		List<Product2> products = new List<Product2>{ testProduct};
		insert products;
		// Get Account
		Account account = [SELECT Id FROM Account LIMIT 1];
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
		List<Opportunity> opportunities = new List<Opportunity>{ opportunity1 };
		insert opportunities;
		oppTriggerHandler.clearBypass();
		Opportunity newOpp = opportunities[0];
		Opportunity upgradedNewOpp = service.getNewOpportunityAfterMovingProcess(oldOpp,newOpp,'upgrade');
		System.assertEquals(oldOpp.Id, upgradedNewOpp.UpgradeFrom__c);
		Opportunity downgradeNewdOpp = service.getNewOpportunityAfterMovingProcess(oldOpp,newOpp,'downgrade');
		System.assertEquals(oldOpp.Id, upgradedNewOpp.DowngradeFrom__c);
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method generateAndStampPortalToken
	 */
	@isTest
	static void generateAndStampPortalTokenTest(){
		Opportunity opportunity = [SELECT Id,AccountId
		,PaymentPortalToken__c
		FROM Opportunity LIMIT 1];
		String base = String.valueOf(opportunity.Id) + String.valueOf(opportunity.AccountId);
		OpportunityService service = OpportunityService.getInstance();
		Test.startTest();
			Opportunity updatedOpp = service.generateAndStampPortalToken(new List<Opportunity>{opportunity})[0];
		Test.stopTest();
		System.assertEquals(EncodingUtil.base64Encode(Blob.valueOf(base)), updatedOpp.PaymentPortalToken__c);
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method checkHasOutstandingPayment
	 */
	@isTest
	static void checkHasOutstandingPayment(){
		Opportunity opportunity = [SELECT Id,AccountId
		,PaymentPortalToken__c
		FROM Opportunity LIMIT 1];
		OpportunityService service = OpportunityService.getInstance();
		Test.startTest();
			Map<Id, Boolean> outstandingPaymentResultMapByOppId = service.checkHasOutstandingPayment(new List<Id>{opportunity.Id});
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - add test method to test closeLostOpportunityRefundForfeit
	 */
	@isTest
	static void closeLostOpportunityRefundForfeitTest(){
		OpportunityService service = OpportunityService.getInstance();
		List<Opportunity> testedOpportunities = new List<Opportunity>{
			new Opportunity(
				CancellationTerminationType__c = GlobalConstants.OPP_TERMINATION_TYPE_CANCELLATION,
				CancellationTerminationSubType__c =  GlobalConstants.OPP_TERMINATION_SUBTYPE_FORFEIT
			),
			new Opportunity(
				CancellationTerminationType__c = GlobalConstants.OPP_TERMINATION_TYPE_TERMINATION,
				CancellationTerminationSubType__c =  GlobalConstants.OPP_TERMINATION_SUBTYPE_FORFEIT
			),
			new Opportunity(
				CancellationTerminationType__c = GlobalConstants.OPP_TERMINATION_TYPE_CANCELLATION,
				CancellationTerminationSubType__c =  GlobalConstants.OPP_TERMINATION_SUBTYPE_REFUND
			),
			new Opportunity(
				CancellationTerminationType__c = GlobalConstants.OPP_TERMINATION_TYPE_TERMINATION,
				CancellationTerminationSubType__c =  GlobalConstants.OPP_TERMINATION_SUBTYPE_REFUND
			)
		};
		Test.startTest();
			List<Opportunity> resultOpportunitites = service.closeLostOpportunityRefundForfeit(testedOpportunities);
			for (Opportunity opportunity : resultOpportunitites){
				System.assertEquals(true, opportunity.IsRefundForfeitCompleted__c);
				System.assertEquals(GlobalConstants.OPP_STAGENAME_CLOSED_LOST, opportunity.StageName);
			}
		Test.stopTest();
	}
	/**
	 * Phase2
	 * Details:
	 * - Test Class set Recurring Text to use create text file by use field set
	 */
	@isTest
	static void getOpportunityTextMapByFieldsetTest(){
		Opportunity opportunity = [SELECT Id,AccountId
		,PaymentPortalToken__c
		FROM Opportunity LIMIT 1];
		OpportunityService service = OpportunityService.getInstance();
		Test.startTest();
		Map<Id, String> result = service.getOpportunityTextMapByFieldset(new List<Opportunity>{opportunity});
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - Unit test to test method stampTourAnalysisFromCustomerVisit
	 */
	@isTest
	static void stampTourAnalysisFromCustomerVisitTest(){
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		CustomerVisit__c customerVisit = new CustomerVisit__c(
			OpportunityName__c = opportunity.Id,
			TourAnalysis__c = 'Inspector'
		);
		Test.startTest();
			OpportunityService service = OpportunityService.getInstance();
			List<Opportunity> opportunites = service.stampTourAnalysisFromCustomerVisit(new List<CustomerVisit__c>{customerVisit});
		Test.stopTest();
		System.AssertEquals(opportunites[0].TourAnalysis__c, 'Inspector');
	}
}