@isTest
public with sharing class ContractServiceTest {
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
		// Create Promotion Master
		PromotionMaster__c promotionMaster = dataMaker.craeteActivePromotionMaster(
			testProject.Id,
			testProduct.Id,
			'ส่วนลด',
			'Sales',
			'Discount (ส่วนลด)',
			'Add Detail',
			'Description',
			500.00
		);
		insert promotionMaster;
		// Create Account
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
		Account account2 = dataMaker.createAccount(recordTypeId, 'Test Co Buyer');
		Account account3 = dataMaker.createAccount(recordTypeId, 'Test Co Buyer 2');
		Account account4 = dataMaker.createAccount(recordTypeId, 'Test Co Buyer 3');
		List<Account> accounts = new List<Account>{ account, account2, account3, account4 };
		insert accounts;
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
		// Create Quote
		Quote__c targetSyncedQuote = dataMaker.createQuote(opportunity1.Id);
		targetSyncedQuote.IsSyncing__c = true;
		insert targetSyncedQuote;
		// Create Contract
		ContractTriggerHandler contractTrigger = ContractTriggerHandler.getInstance();
		contractTrigger.setBypass();
		Contract contract = dataMaker.createContract(opportunity1.Id, opportunity1.AccountId);
		insert contract;
		contractTrigger.clearBypass();
		// Craete Client Offer
		ClientOffer__c clientOffer = dataMaker.createClientOffer(promotionMaster.Id, opportunity1.Id, null);
		insert clientOffer;
	}

	@isTest
	static void generateContractsFromOpportunities() {
		Test.startTest();
		List<Opportunity> testOpp = [
			SELECT
				Id,
				Project__c,
				Unit__c,
				Promotion__c,
				StageName,
				Quota__c,
				AccountId,
				DiscountAmount__c,
				DiscountPercent__c,
				DiscountPercentOfAmount__c,
				TotalDiscountPercent__c,
				UnitPrice__c,
				NetPrice__c,
				PaymentTermMaster__c,
				ContractId,
				TotalDiscountAmount__c,
				ContactPerson__c,
				SyncedQuoteId__c,
				(
					SELECT Id, AddressEN__c, AddressTH__c
					FROM Quote__r
					WHERE IsSyncing__c = TRUE
				)
			FROM Opportunity
		];
		ContractService service = ContractService.getInstance();
		List<Contract> contracts = service.generateContractsFromOpportunities(testOpp);
		System.assertEquals(testOpp.size(), contracts.size());
		for (Integer i = 0; i < contracts.size(); i++) {
			System.assertEquals(testOpp[i].Id, contracts[i].Opportunity__c);
			System.assertEquals(testOpp[i].AccountId, contracts[i].AccountId);
		}
		Test.stopTest();
	}

	@isTest
	static void stampContractName() {
		Test.startTest();
		List<Contract> contracts = [SELECT Id, Opportunity__c, FormatContractName__c FROM Contract];
		ContractService service = ContractService.getInstance();
		List<Contract> updatedContracts = service.stampContractName(contracts);
		for (Contract contract : updatedContracts) {
			System.assertEquals(contract.FormatContractName__c, contract.Name);
		}
		Test.stopTest();
	}

	@isTest
	static void makeRelationshipWithClientOfferTest() {
		Test.startTest();
		List<Contract> contracts = [SELECT Id, Name, FormatContractName__c, Opportunity__c FROM Contract];
		ContractService service = ContractService.getInstance();
		List<ClientOffer__c> updatedClientOffers = service.makeRelationshipWithClientOffer(contracts);
		for (ClientOffer__c clientOffer : updatedClientOffers) {
			System.assertEquals(contracts[0].Id, clientOffer.Contract__c);
		}
		Test.stopTest();
	}

	@isTest
	static void stampCompleteContractStatusToOppTest() {
		Test.startTest();
		List<Contract> contracts = [SELECT Id, Opportunity__c FROM Contract];
		ContractService service = ContractService.getInstance();
		List<Opportunity> updatedOpportunities = service.stampCompleteContractStatusToOpp(contracts);
		for (Opportunity opportunity : updatedOpportunities) {
			System.assertEquals(true, opportunity.IsCompletedContract__c);
		}
		Test.stopTest();
	}
	@isTest
	static void checkFullyPaidStatusForCompleteContractTest(){
		Test.startTest();
		List<Contract> contracts = [SELECT Id, Opportunity__c FROM Contract];
		// Create Opp Payments
		DataMaker dataMaker = DataMaker.getInstance();
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			contracts[0].Opportunity__c,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		OpportunityPayment__c contractOppPayment = dataMaker.createOpportunityPayment(
			contracts[0].Opportunity__c,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 27),
			2
		);
		OpportunityPayment__c installmentOppPayment = dataMaker.createOpportunityPayment(
			contracts[0].Opportunity__c,
			'Installment 1',
			10000000,
			Date.newInstance(2024, 10, 27),
			3
		);
		OpportunityPayment__c transferOppPayment = dataMaker.createOpportunityPayment(
			contracts[0].Opportunity__c,
			'Transfer',
			4850000,
			Date.newInstance(2025, 10, 27),
			4
		);
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment,
			contractOppPayment,
			installmentOppPayment,
			transferOppPayment
		};
		insert oppPayments;
		ContractService service = ContractService.getInstance();
		Map<Id,Boolean> result = service.checkFullyPaidStatusForCompleteContract(contracts);
		System.assertEquals(False,result.get(contracts[0].Id));
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test method to test getContractAfterNovationProcess
	 */
	@isTest
	static void getContractAfterNovationProcessTest() {
		Test.startTest();
		List<Contract> contracts = [SELECT Id, Opportunity__c, CancelReason__c FROM Contract];
		ContractService service = ContractService.getInstance();
		List<Contract> updatedContracts = service.getContractAfterNovationProcess(contracts);
		for (Contract contract : updatedContracts) {
			System.assertEquals(GlobalConstants.OPP_LOST_REASON_NOVATION, contract.CancelReason__c);
		}
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - Add test method to test getContractAfterMovingProcess
	 */
	@isTest
	static void getContractAfterMovingProcessTest() {
		Test.startTest();
		List<Contract> contracts = [SELECT Id, Opportunity__c, CancelReason__c FROM Contract];
		ContractService service = ContractService.getInstance();
		List<Contract> updatedContractsWithUpgrade = service.getContractAfterMovingProcess(contracts,'upgrade');
		for (Contract contract : updatedContractsWithUpgrade) {
			System.assertEquals(GlobalConstants.OPP_LOST_REASON_UPGRADE, contract.CancelReason__c);
		}
		List<Contract> updatedContractsWithDowngrade = service.getContractAfterMovingProcess(contracts,'downgrade');
		for (Contract contract : updatedContractsWithDowngrade) {
			System.assertEquals(GlobalConstants.OPP_LOST_REASON_DOWNGRADE, contract.CancelReason__c);
		}
		List<Contract> updatedContractsWithMovePayment = service.getContractAfterMovingProcess(contracts,'move_payment');
		for (Contract contract : updatedContractsWithMovePayment) {
			System.assertEquals(GlobalConstants.OPP_LOST_REASON_MOVEPAYMENT, contract.CancelReason__c);
		}
		Test.stopTest();
	}
}