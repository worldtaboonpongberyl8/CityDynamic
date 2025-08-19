@isTest
public with sharing class PDFGeneratorControllerTest {
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
		Product2 unit1 = dataMaker.createUnit(
			'Test Product',
			'PP01',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		Product2 unit2 = dataMaker.createUnit(
			'Test Product 2',
			'PP02',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		insert new List<Product2>{ unit1, unit2 };
		// Create Promotion Master
		PromotionMaster__c promotionMaster = dataMaker.craeteActivePromotionMaster(testProject.Id,unit1.Id,'ส่วนลด','Sales','Discount (ส่วนลด)','Add Detail','Description',500.00);
		insert promotionMaster;
		// Create Account
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'United Oil & Gas Corp.');
		insert account;
		// Create Opportunity
		OpportunityTriggerHandler oppTriggerHandler = OpportunityTriggerHandler.getInstance();
		oppTriggerHandler.setBypass();

		Opportunity opportunity1 = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.newInstance(2024, 10, 1),
			'Open',
			unit1.Id,
			'Foreign',
			null,
			testProject.Id
		);
		insert new List<Opportunity> { opportunity1 };

		oppTriggerHandler.clearBypass();

		// Create Opp Payments
		// opportunity 1
		OpportunityPayment__c reservationOppPaymentOpp1 = dataMaker.createOpportunityPayment(
			opportunity1.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		OpportunityPayment__c contractOppPaymentOpp1 = dataMaker.createOpportunityPayment(
			opportunity1.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 27),
			2
		);
		OpportunityPayment__c installmentOppPaymentOpp1 = dataMaker.createOpportunityPayment(
			opportunity1.Id,
			'Installment 1',
			10000000,
			Date.newInstance(2024, 10, 27),
			3
		);
		OpportunityPayment__c transferOppPaymentOpp1 = dataMaker.createOpportunityPayment(
			opportunity1.Id,
			'Transfer',
			4850000,
			Date.newInstance(2025, 10, 27),
			4
		);


		// all oppPayments
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPaymentOpp1,
			contractOppPaymentOpp1,
			installmentOppPaymentOpp1,
			transferOppPaymentOpp1
		};
		insert oppPayments;

		NameFormattingMasterData__c runningNumberFormatDocument = dataMaker.createNameFormattingMasterData(
			'Opportunity', 'Format', 'Document', 'Payment Summary-{Project__r.ProjectCode__c}-{Unit__r.ProductCode}', 1, 'Payment Summary'
		);
		insert runningNumberFormatDocument;
	}

	@isTest
	static void createPDFFileAndSaveToExistingTest(){
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];

		PDFGeneratorController.createPDFFile(
			opportunity.Id,
			'PaymentSummaryForm',
			'Document',
			'Payment Summary',
			'PaymentSummaryDocId__c'
		);

		List<ContentDocumentLink> contentDocLinkResults = [
			SELECT LinkedEntityId, ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId =: opportunity.Id
		];
		System.assertEquals(1, contentDocLinkResults.size());

		List<ContentVersion> contentVersionResults = [
			SELECT Title, FileExtension, IsLatest
			FROM ContentVersion
			WHERE ContentDocumentId =: contentDocLinkResults.get(0).ContentDocumentId
		];
		System.assertEquals(1, contentVersionResults.size());
		System.assertEquals('Payment Summary-AA01-PP01', contentVersionResults.get(0).Title);
		System.assertEquals('pdf', contentVersionResults.get(0).FileExtension);
		System.assertEquals(true, contentVersionResults.get(0).IsLatest);

		Opportunity opportunityResult = [SELECT Id, PaymentSummaryDocId__c FROM Opportunity LIMIT 1];
		System.assertEquals(contentDocLinkResults.get(0).ContentDocumentId, opportunityResult.PaymentSummaryDocId__c);
	}

	@isTest
	static void createPDFFileAndSaveToNewTest(){
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];

		PDFGeneratorController.createPDFFile(
			opportunity.Id,
			'PaymentSummaryForm',
			'Document',
			'Payment Summary',
			null
		);

		List<ContentDocumentLink> contentDocLinkResults = [
			SELECT LinkedEntityId, ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId =: opportunity.Id
		];
		System.assertEquals(1, contentDocLinkResults.size());

		List<ContentVersion> contentVersionResults = [
			SELECT Title, FileExtension, IsLatest
			FROM ContentVersion
			WHERE ContentDocumentId =: contentDocLinkResults.get(0).ContentDocumentId
		];
		System.assertEquals(1, contentVersionResults.size());
		System.assertEquals('Payment Summary-AA01-PP01', contentVersionResults.get(0).Title);
		System.assertEquals('pdf', contentVersionResults.get(0).FileExtension);
		System.assertEquals(true, contentVersionResults.get(0).IsLatest);

		Opportunity opportunityResult = [SELECT Id, PaymentSummaryDocId__c FROM Opportunity LIMIT 1];
		System.assertEquals(null, opportunityResult.PaymentSummaryDocId__c);
	}
}