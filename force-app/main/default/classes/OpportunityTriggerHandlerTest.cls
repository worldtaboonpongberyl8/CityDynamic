@isTest
private class OpportunityTriggerHandlerTest {
	@TestSetup
	static void makeData() {
		DataMaker dataMaker = DataMaker.getInstance();
		// Create Account
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account acc = dataMaker.createAccount(recordTypeId, 'Test Account');
		insert acc;
		// Create Project
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		testProject.CompletionDate__c = Date.today().addDays(10);
		insert testProject;
		// Create Floor
		Floor__c testFloor = dataMaker.createFloor('Test Floor', 'FF01', testProject.Id);
		insert testFloor;
		// Create Unit Type
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type', testProject.Id);
		insert unitType;
		// Create Unit
		Product2 testProduct = dataMaker.createUnit(
			'Test Product 1',
			'UN01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		testProduct.ReservationPrice__c = 10000;
		insert testProduct;
		Product2 testProduct2 = dataMaker.createUnit(
			'Test Product 2',
			'UN02',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert testProduct2;
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 150000, 200000,10000000);
		testPricebookEntry1.Pricebook2Id = pricebookId;
		testPricebookEntry1.UseStandardPrice = false;
		insert testPricebookEntry1;
		PricebookEntry testPricebookEntry2 = dataMaker.createPricebookEntries(testProduct2.Id, 150000, 200000,10000000);
		testPricebookEntry2.Pricebook2Id = pricebookId;
		testPricebookEntry2.UseStandardPrice = false;
		insert testPricebookEntry2;
		PaymentTermMaster__c paymentTermMaster = dataMaker.craetePaymentTermMaster(
			testProject.Id,
			'TQ Series 5-10-85',
			'Series',
			'Thai',
			25
		);
		insert paymentTermMaster;
		PaymentTermMaster__c paymentTermMasterFQ = dataMaker.craetePaymentTermMaster(
			testProject.Id,
			'FQ Series 5-10-85',
			'Series',
			'Foreign',
			25
		);
		insert paymentTermMasterFQ;
		PaymentTermMaster__c paymentTermMasterNew = dataMaker.craetePaymentTermMaster(
			testProject.Id,
			'TQ Series 9-10-85',
			'Series',
			'Thai',
			25
		);
		insert paymentTermMasterNew;
		List<PaymentTerm__c> paymentTermWrappers = new List<PaymentTerm__c>();
		PaymentTerm__c paymentTerm1 = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			1,
			null,
			10,
			'Contract'
		);
		PaymentTerm__c paymentTerm2 = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			2,
			null,
			20,
			'Installment 1'
		);
		PaymentTerm__c paymentTerm3 = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			3,
			null,
			null,
			'Transfer'
		);
		paymentTermWrappers.add(paymentTerm1);
		paymentTermWrappers.add(paymentTerm2);
		paymentTermWrappers.add(paymentTerm3);
		insert paymentTermWrappers;

		List<PaymentTerm__c> paymentTermWrapperNews = new List<PaymentTerm__c>{
			dataMaker.createPaymentTermLineItem(paymentTermMasterNew.Id, 1, 100000.00, null, 'Contract'),
			dataMaker.createPaymentTermLineItem(paymentTermMasterNew.Id, 2, null, 20, 'Installment 1'),
			dataMaker.createPaymentTermLineItem(paymentTermMasterNew.Id, 3, null, 20, 'Installment 2'),
			dataMaker.createPaymentTermLineItem(paymentTermMasterNew.Id, 4, null, 30, 'Installment 3'),
			dataMaker.createPaymentTermLineItem(paymentTermMasterNew.Id, 5, null, null, 'Transfer')
		};
		insert paymentTermWrapperNews;
		// Create Promotion Master
		List<PromotionMaster__c> promotionMasters = new List<PromotionMaster__c>{
			dataMaker.craeteActivePromotionMaster(
				null,
				null,
				'ส่วนลด',
				'Sales',
				'Discount (ส่วนลด)',
				'Add Detail',
				'Description',
				200.00
			),
			dataMaker.craeteActivePromotionMaster(
				testProject.Id,
				null,
				'ส่วนลด',
				'Marketing',
				'Discount (ส่วนลด)',
				'Add Detail',
				'Description',
				200.00
			),
			dataMaker.craeteActivePromotionMaster(
				testProject.Id,
				testProduct.Id,
				'ฟรีส่วนกลาง',
				'Marketing',
				'Premium (ของแถม)',
				'Add Detail',
				'Description',
				1000.00
			),
			dataMaker.craeteActivePromotionMaster(
				testProject.Id,
				null,
				'ฟรีส่วนกลาง',
				'Marketing',
				'Premium (ของแถม)',
				'Add Detail',
				'Description',
				1000.00
			)
		};
		insert promotionMasters;
		Opportunity testOpportunity = dataMaker.createOpportunity(
			acc.Id,
			'Omitted',
			'Test Opp with Unit 1',
			Date.today(),
			'Open',
			testProduct.Id,
			'Thai',
			null,
			testProject.Id
		);
		insert testOpportunity;
	}
	@isTest
	static void beforeInsertUnitPriceTQTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Account targetAccount = [SELECT Id, Name FROM Account LIMIT 1];
		Project__c targetProject = [SELECT Id FROM Project__c LIMIT 1];
		Product2 targetUnit = [SELECT Id FROM Product2 WHERE ProductCode = 'UN01' LIMIT 1];
		Opportunity opportunity1 = dataMaker.createOpportunity(
			targetAccount.Id,
			'Omitted',
			'Test Opp with Unit 1',
			Date.today(),
			'Open',
			targetUnit.Id,
			'Thai',
			null,
			targetProject.Id
		);
		insert opportunity1;
		Opportunity result = [SELECT Id, UnitPrice__c FROM Opportunity WHERE Id = :opportunity1.Id LIMIT 1];
		System.assertEquals(150000, result.UnitPrice__c);
		Test.stopTest();
	}
	@isTest
	static void beforeUpdateUnitPriceTQtoFQTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Account targetAccount = [SELECT Id, Name FROM Account LIMIT 1];
		Project__c targetProject = [SELECT Id FROM Project__c LIMIT 1];
		Product2 targetUnit = [SELECT Id FROM Product2 WHERE ProductCode = 'UN01' LIMIT 1];
		Opportunity opportunityOld = [SELECT Id FROM Opportunity WHERE Unit__c = :targetUnit.Id LIMIT 1];
		Opportunity result = [SELECT Id, UnitPrice__c FROM Opportunity WHERE Id = :opportunityOld.Id LIMIT 1];
		System.assertEquals(150000, result.UnitPrice__c);

		Opportunity opportunityNew = [SELECT Id, Quota__c FROM Opportunity WHERE Id = :opportunityOld.Id LIMIT 1];
		opportunityNew.Quota__c = 'Foreign';
		update opportunityNew;

		Opportunity resultNew = [SELECT Id, UnitPrice__c FROM Opportunity WHERE Id = :opportunityNew.Id LIMIT 1];
		System.assertEquals(200000, resultNew.UnitPrice__c);
		Test.stopTest();
	}
	@isTest
	static void beforeInsertAssignInitialPaymentAmount() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c project = [SELECT Id, CompletionDate__c FROM Project__c WHERE ProjectCode__c = 'AA01'];
		System.debug('Test Project: ' + project);
		PaymentTermMaster__c paymentTermMaster = [SELECT Id FROM PaymentTermMaster__c WHERE Name = 'TQ Series 5-10-85'];
		Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'UN01'];
		Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
		Opportunity opp = dataMaker.createOpportunity(
			acc.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Thai',
			paymentTermMaster.Id,
			project.Id
		);
		opp.ReservationDueDate__c = Date.today();
		opp.DiscountPercent__c = 10;
		opp.DiscountAmount__c = 0;
		insert opp;
		List<Opportunity> results = [
			SELECT
				Id,
				ContractAmount__c,
				ContractPercent__c,
				TotalInstallmentAmount__c,
				TotalInstallmentPercent__c,
				UnitPrice__c,
				NetPrice__c,
				Unit__c,
				ReservationDueDate__c,
				PaymentTermMaster__c,
				Project__c
			FROM Opportunity
			WHERE Id = :opp.Id
		];
		System.debug('Result: ' + results);
		System.assertEquals(0, results[0].ContractAmount__c);
		System.assertEquals(10, results[0].ContractPercent__c);
		System.assertEquals(0, results[0].TotalInstallmentAmount__c);
		System.assertEquals(20, results[0].TotalInstallmentPercent__c);
		Test.stopTest();
	}

	@isTest
	static void beforeUpdateAssignInitialPaymentAmount() {
		Test.startTest();
		Project__c project = [SELECT Id, CompletionDate__c FROM Project__c WHERE ProjectCode__c = 'AA01'];
		PaymentTermMaster__c paymentTermMaster = [SELECT Id FROM PaymentTermMaster__c WHERE Name = 'TQ Series 5-10-85'];
		Opportunity targetOpp = [SELECT Id FROM Opportunity WHERE Project__c = :project.Id];
		targetOpp.PaymentTermMaster__c = paymentTermMaster.Id;
		update targetOpp;
		List<Opportunity> results = [
			SELECT
				Id,
				ContractAmount__c,
				ContractPercent__c,
				TotalInstallmentAmount__c,
				TotalInstallmentPercent__c,
				UnitPrice__c,
				NetPrice__c,
				Unit__c,
				ReservationDueDate__c,
				PaymentTermMaster__c,
				Project__c
			FROM Opportunity
			WHERE Id = :targetOpp.Id
		];
		System.assertEquals(0, results[0].ContractAmount__c);
		System.assertEquals(10, results[0].ContractPercent__c);
		System.assertEquals(0, results[0].TotalInstallmentAmount__c);
		System.assertEquals(20, results[0].TotalInstallmentPercent__c);
		Test.stopTest();
	}

	@isTest
	static void beforeInsertStampCoBuyerName() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Account targetAccount = [SELECT Id, Name FROM Account LIMIT 1];
		Project__c targetProject = [SELECT Id FROM Project__c LIMIT 1];
		Product2 targetUnit = [SELECT Id FROM Product2 WHERE ProductCode = 'UN01' LIMIT 1];
		Opportunity opportunity1 = dataMaker.createOpportunity(
			targetAccount.Id,
			'Omitted',
			'Test Opp with Unit 1',
			Date.today(),
			'Open',
			targetUnit.Id,
			'Foreign',
			null,
			targetProject.Id
		);
		insert opportunity1;
		Opportunity resultOpp = [SELECT Id, CoBuyerName__c FROM Opportunity WHERE Id = :opportunity1.Id LIMIT 1];
		System.assertEquals(targetAccount.Name, resultOpp.CoBuyerName__c);
		Test.stopTest();
	}

	@isTest
	static void beforeInsertUnitPriceFQTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Account targetAccount = [SELECT Id, Name FROM Account LIMIT 1];
		Project__c targetProject = [SELECT Id FROM Project__c LIMIT 1];
		Product2 targetUnit = [SELECT Id FROM Product2 WHERE ProductCode = 'UN01' LIMIT 1];
		Opportunity opportunity1 = dataMaker.createOpportunity(
			targetAccount.Id,
			'Omitted',
			'Test Opp with Unit 1',
			Date.today(),
			'Open',
			targetUnit.Id,
			'Foreign',
			null,
			targetProject.Id
		);
		insert opportunity1;
		Opportunity result = [SELECT Id, UnitPrice__c FROM Opportunity WHERE Id = :opportunity1.Id LIMIT 1];
		System.assertEquals(200000, result.UnitPrice__c);
		Test.stopTest();
	}
	@isTest
	static void afterInsertCreateOppPaymentByPaymentMaster() {
		Test.startTest();
		OpportunityTriggerHandler oppTrigger = OpportunityTriggerHandler.getInstance();
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c project = [SELECT Id, CompletionDate__c FROM Project__c WHERE ProjectCode__c = 'AA01'];
		System.debug('Test Project: ' + project);
		PaymentTermMaster__c paymentTermMaster = [SELECT Id FROM PaymentTermMaster__c WHERE Name = 'TQ Series 5-10-85'];
		Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'UN01'];
		Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
		Opportunity opp = dataMaker.createOpportunity(
			acc.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Thai',
			paymentTermMaster.Id,
			project.Id
		);
		opp.ReservationDueDate__c = Date.today();
		opp.DiscountPercent__c = 10;
		opp.DiscountAmount__c = 0;
		insert opp;
		List<Opportunity> results = [
			SELECT Id, UnitPrice__c, NetPrice__c, Unit__c, ReservationDueDate__c, PaymentTermMaster__c, Project__c
			FROM Opportunity
			WHERE Id = :opp.Id
		];
		System.debug('Result: ' + results);
		List<OpportunityPayment__c> resultPayments = [
			SELECT Id, Name, Order__c
			FROM OpportunityPayment__c
			WHERE Opportunity__c = :results[0].Id
		];
		System.assertEquals(4, resultPayments.size());
		for (OpportunityPayment__c oppPayment : resultPayments) {
			System.assertEquals(oppPayment.Order__c, Integer.valueOf(oppPayment.Name));
		}
		Test.stopTest();
	}
	@isTest
	static void afterInsertCreateOppPaymentByPaymentMasterIsNull() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c project = [SELECT Id, CompletionDate__c FROM Project__c WHERE ProjectCode__c = 'AA01'];
		System.debug('Test Project: ' + project);
		Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'UN01'];
		Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
		Opportunity opp = dataMaker.createOpportunity(
			acc.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Thai',
			null,
			project.Id
		);
		opp.ReservationDueDate__c = Date.today();
		opp.DiscountPercent__c = 10;
		opp.DiscountAmount__c = 0;
		opp.UnitPrice__c = 1000000;
		insert opp;
		Opportunity result = [SELECT Id, PaymentTermMaster__c FROM Opportunity WHERE Id = :opp.Id];
		System.assertEquals(null, result.PaymentTermMaster__c);
		Test.stopTest();
	}

	@isTest
	static void afterInsertCreatePromotionOpportunity() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Account targetAccount = [SELECT Id FROM Account LIMIT 1];
		Product2 targetUnit1 = [SELECT Id FROM Product2 WHERE ProductCode = 'UN01' LIMIT 1];
		Product2 targetUnit2 = [SELECT Id FROM Product2 WHERE ProductCode = 'UN02' LIMIT 1];
		Project__c targetProject = [SELECT Id FROM Project__c WHERE ProjectCode__c = 'AA01' LIMIT 1];
		Opportunity opp1 = dataMaker.createOpportunity(
			targetAccount.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			targetUnit1.Id,
			'Thai',
			null,
			targetProject.Id
		);
		Opportunity opp2 = dataMaker.createOpportunity(
			targetAccount.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			targetUnit2.Id,
			'Thai',
			null,
			targetProject.Id
		);
		List<Opportunity> opportunities = new List<Opportunity>{ opp1, opp2 };
		insert opportunities;
		List<PromotionOpportunity__c> opportunityPromotions = [
			SELECT Id, PromotionMaster__c
			FROM PromotionOpportunity__c
			WHERE Opportunity__c = :opp1.Id
		];
		PromotionMaster__c targetPromotionMaster = [
			SELECT Id
			FROM PromotionMaster__c
			WHERE ProjectCode__c = 'AA01' AND UnitCode__c = 'UN01'
			LIMIT 1
		];
		System.assertEquals(1, opportunityPromotions.size());
		System.assertEquals(targetPromotionMaster.Id, opportunityPromotions[0].PromotionMaster__c);
		List<PromotionOpportunity__c> opportunityPromotions2 = [
			SELECT Id
			FROM PromotionOpportunity__c
			WHERE Opportunity__c = :opp2.Id
		];
		System.assertEquals(2, opportunityPromotions2.size());
		Test.stopTest();
	}

	@isTest
	static void afterUpdateAdjustRelatedOppPaymentAfterApplyDiscountTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c project = [SELECT Id, CompletionDate__c FROM Project__c WHERE ProjectCode__c = 'AA01'];
		System.debug('Test Project: ' + project);
		PaymentTermMaster__c paymentTermMaster = [SELECT Id FROM PaymentTermMaster__c WHERE Name = 'TQ Series 5-10-85'];
		Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'UN01'];
		Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
		Opportunity opp = dataMaker.createOpportunity(
			acc.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Thai',
			paymentTermMaster.Id,
			project.Id
		);
		opp.ReservationDueDate__c = Date.today();
		opp.DiscountPercent__c = 10;
		opp.DiscountAmount__c = 0;
		insert opp;
		Opportunity resultCreate = [
			SELECT
				Id,
				AccountId,
				Name,
				ForecastCategoryName,
				CloseDate,
				Unit__c,
				Quota__c,
				StageName,
				PaymentTermMaster__c,
				DiscountPercent__c
			FROM Opportunity
			WHERE Id = :opp.Id
		];
		System.assertEquals(10, resultCreate.DiscountPercent__c);
		Opportunity oppUpdate = [
			SELECT
				Id,
				AccountId,
				Name,
				ForecastCategoryName,
				CloseDate,
				Unit__c,
				Quota__c,
				StageName,
				PaymentTermMaster__c
			FROM Opportunity
			WHERE Id = :opp.Id
		];
		oppUpdate.DiscountPercent__c = 20;
		opp.DiscountAmount__c = 0;
		update oppUpdate;
		Opportunity resultUpdate = [
			SELECT
				Id,
				UnitPrice__c,
				NetPrice__c,
				Unit__c,
				ReservationDueDate__c,
				PaymentTermMaster__c,
				Project__c,
				TotalDiscountPercent__c,
				DiscountPercent__c,
				DiscountPercentOfAmount__c
			FROM Opportunity
			WHERE Id = :opp.Id
		];
		System.debug('Result Update: ' + resultUpdate);
		System.assertEquals(20, resultUpdate.DiscountPercent__c);
		List<OpportunityPayment__c> resultOppPayment = [
			SELECT Id, Term__c, Amount__c, Opportunity__c
			FROM OpportunityPayment__c
			WHERE Opportunity__c = :opp.Id
		];
		for (OpportunityPayment__c oppPayment : resultOppPayment) {
			System.debug(oppPayment);
			if (oppPayment.Term__c.contains('Reservation')) {
				System.assertEquals(10000, oppPayment.Amount__c);
			} else if (oppPayment.Term__c == 'Contract') {
				System.assertEquals(15000, oppPayment.Amount__c);
			} else if (oppPayment.Term__c.contains('Installment')) {
				System.assertEquals(30000, oppPayment.Amount__c);
			} else if (oppPayment.Term__c.contains('Transfer')) {
				System.assertEquals(65000, oppPayment.Amount__c);
			}
		}
		Test.stopTest();
	}
	@isTest
	static void afterUpdateOpportunityPaymentByPaymentMasterTest() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c project = [SELECT Id, CompletionDate__c FROM Project__c WHERE ProjectCode__c = 'AA01'];
		System.debug('Test Project: ' + project);
		Product2 testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'UN01'];
		Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
		PaymentTermMaster__c paymentTermMaster = [SELECT Id FROM PaymentTermMaster__c WHERE Name = 'TQ Series 5-10-85'];
		PaymentTermMaster__c paymentTermMasterNew = [
			SELECT Id
			FROM PaymentTermMaster__c
			WHERE Name = 'TQ Series 9-10-85'
		];
		Opportunity opp = dataMaker.createOpportunity(
			acc.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Thai',
			paymentTermMaster.Id,
			project.Id
		);
		opp.ReservationDueDate__c = Date.today();
		opp.DiscountPercent__c = 10;
		insert opp;
		Opportunity oppUpdate = [
			SELECT
				Id,
				AccountId,
				Name,
				ForecastCategoryName,
				CloseDate,
				Unit__c,
				Quota__c,
				StageName,
				PaymentTermMaster__c,
				NetPrice__c
			FROM Opportunity
			WHERE Id = :opp.Id
		];
		oppUpdate.PaymentTermMaster__c = paymentTermMasterNew.Id;
		update oppUpdate;
		Opportunity result = [SELECT Id, PaymentTermMaster__c FROM Opportunity WHERE Id = :opp.Id];
		List<OpportunityPayment__c> oppPaymentTerms = [
			SELECT Id, Order__c, Name
			FROM OpportunityPayment__c
			WHERE PaymentTermMaster__c = :result.PaymentTermMaster__c
		];
		List<OpportunityPayment__c> oppPaymentOldTerms = [
			SELECT Id
			FROM OpportunityPayment__c
			WHERE PaymentTermMaster__c = :paymentTermMaster.Id
		];
		System.assertEquals(0, oppPaymentOldTerms.size());
		System.assertEquals(paymentTermMasterNew.Id, result.PaymentTermMaster__c);
		System.assertEquals(6, oppPaymentTerms.size());
		for (OpportunityPayment__c oppPayment : oppPaymentTerms) {
			System.assertEquals(oppPayment.Order__c, Integer.valueOf(oppPayment.Name));
		}
		Test.stopTest();
	}

	@isTest
	static void afterUpdateChangeOpportunityPromotion() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Account targetAccount = [SELECT Id FROM Account LIMIT 1];
		Product2 targetUnit1 = [SELECT Id FROM Product2 WHERE ProductCode = 'UN01' LIMIT 1];
		Product2 targetUnit2 = [SELECT Id FROM Product2 WHERE ProductCode = 'UN02' LIMIT 1];
		Project__c targetProject = [SELECT Id FROM Project__c WHERE ProjectCode__c = 'AA01' LIMIT 1];
		Opportunity opp1 = dataMaker.createOpportunity(
			targetAccount.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			targetUnit1.Id,
			'Thai',
			null,
			targetProject.Id
		);
		Opportunity opp2 = dataMaker.createOpportunity(
			targetAccount.Id,
			'Omitted',
			'Test Opp 2',
			Date.today(),
			'Open',
			targetUnit2.Id,
			'Thai',
			null,
			targetProject.Id
		);
		List<Opportunity> opportunities = new List<Opportunity>{ opp1, opp2 };
		insert opportunities;
		Opportunity targetOppAfterInsert = [
			SELECT Id, Unit__c
			FROM Opportunity
			WHERE Unit__c = :targetUnit2.Id
			LIMIT 1
		];
		targetOppAfterInsert.Unit__c = targetUnit1.Id;
		update targetOppAfterInsert;
		List<PromotionOpportunity__c> opportunityPromotions = [
			SELECT Id, PromotionMaster__c
			FROM PromotionOpportunity__c
			WHERE Opportunity__c = :opp1.Id
		];
		PromotionMaster__c targetPromotionMaster = [
			SELECT Id
			FROM PromotionMaster__c
			WHERE ProjectCode__c = 'AA01' AND UnitCode__c = 'UN01'
			LIMIT 1
		];
		System.assertEquals(1, opportunityPromotions.size());
		System.assertEquals(targetPromotionMaster.Id, opportunityPromotions[0].PromotionMaster__c);
		List<PromotionOpportunity__c> opportunityPromotions2 = [
			SELECT Id, PromotionMaster__c
			FROM PromotionOpportunity__c
			WHERE Opportunity__c = :opp2.Id
		];
		System.assertEquals(1, opportunityPromotions2.size());
		System.assertEquals(targetPromotionMaster.Id, opportunityPromotions2[0].PromotionMaster__c);
		Test.stopTest();
	}

	@isTest
	static void afterUpdateStampUnitTransferredDateAfterTransfer() {
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Account targetAccount = [SELECT Id FROM Account LIMIT 1];
		Product2 targetUnit1 = [
			SELECT Id, TransferredDate__c, Status__c
			FROM Product2
			WHERE ProductCode = 'UN01'
			LIMIT 1
		];
		PaymentTermMaster__c paymentTermMaster = [SELECT Id FROM PaymentTermMaster__c WHERE Quota__c = 'Foreign'];
		Project__c targetProject = [SELECT Id FROM Project__c WHERE ProjectCode__c = 'AA01' LIMIT 1];
		Opportunity opp1 = dataMaker.createOpportunity(
			targetAccount.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			targetUnit1.Id,
			'Foreign',
			paymentTermMaster.Id,
			targetProject.Id
		);
		opp1.ReservationDueDate__c = Date.newInstance(2024, 10, 12);
		List<Opportunity> opportunities = new List<Opportunity>{ opp1 };
		insert opportunities;
		opp1.StageName = 'Reservation';
		update opp1;
		Contract contract = dataMaker.createContract(opp1.Id,targetAccount.Id);
		insert contract;
		contract.Status = 'Signed Contract';
		contract.ContractSignedDate__c = Date.today();
		update contract;
		opp1.StageName = 'Contract';
		update opp1;
		Opportunity targetOppAfterInsert3 = [
			SELECT Id, Unit__c, Quota__c, PaymentTermMaster__c
			FROM Opportunity
			WHERE Id = :opp1.Id
			LIMIT 1
		];
		targetOppAfterInsert3.TransferredDate__c = Date.today();
		targetOppAfterInsert3.StageName = 'Transferred';
		System.debug('Test--Quota' + targetOppAfterInsert3.Quota__c);
		System.debug('Test--PaymentTermMaster ' + targetOppAfterInsert3.PaymentTermMaster__c);
		update targetOppAfterInsert3;
		Product2 targetUnit1AfterUpdate = [
			SELECT Id, TransferredDate__c, Status__c
			FROM Product2
			WHERE ProductCode = 'UN01'
			LIMIT 1
		];
		System.assertNotEquals(targetUnit1.TransferredDate__c, targetUnit1AfterUpdate.TransferredDate__c);
		System.assertEquals(Date.today(), targetUnit1AfterUpdate.TransferredDate__c);
		System.assertNotEquals(targetUnit1.Status__c, targetUnit1AfterUpdate.Status__c);
		System.assertEquals('Transferred', targetUnit1AfterUpdate.Status__c);
		Test.stopTest();
	}

	@isTest
	static void setBypassTest() {
		Test.startTest();
		OpportunityTriggerHandler handler = OpportunityTriggerHandler.getInstance();
		handler.setBypass();
		System.assertEquals(false, handler.isActive);
		System.assertEquals(false, handler.isTriggerActivated());
		Test.stopTest();
	}

	@isTest
	static void clearBypassTest() {
		Test.startTest();
		OpportunityTriggerHandler handler = OpportunityTriggerHandler.getInstance();
		handler.clearBypass();
		System.assertEquals(true, handler.isActive);
		System.assertEquals(true, handler.isTriggerActivated());
		Test.stopTest();
	}
}