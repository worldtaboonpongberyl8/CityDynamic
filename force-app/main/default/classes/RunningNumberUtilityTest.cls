@isTest
public with sharing class RunningNumberUtilityTest {
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
		Account account = dataMaker.createAccount(recordTypeId, 'United Oil & Gas Corp.');
		insert account;
		// Create Opportunity
		OpportunityTriggerHandler oppTriggerHandler = OpportunityTriggerHandler.getInstance();
		oppTriggerHandler.setBypass();
		Opportunity opportunity = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.newInstance(2024, 10, 1),
			'Open',
			testProduct.Id,
			'Foreign',
			null,
			testProject.Id
		);
		insert opportunity;

		oppTriggerHandler.clearBypass();
	}

	// generateReplacedFormatName
	@isTest
	public static void testGenerateReplacedFormatName() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Opportunity',
			RunningFormat__c = 'Reservation-{Name}_{Account.Name}_{PRINTDATETIME:FORMATDATETIME:yyMMdd-HHmm}',
			RunningPurpose__c = 'Document',
			DocumentTemplateMappingType__c = 'Reservation',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument};

		Opportunity opportunity = [SELECT Id, Name FROM Opportunity];

		String printDateTime = System.now().format('yyMMdd-HHmm');

		String result = RunningNumberUtility.getInstance().generateReplacedFormatName(runningNumberFormatDocument, opportunity.Id, 'Opportunity');
		System.assertEquals(('Reservation-Test Opp_United Oil & Gas Corp._' + printDateTime), result);

		List<NameFormattingMasterData__c> masterRecords = [SELECT Id FROM NameFormattingMasterData__c WHERE Type__c = 'Format'];
		System.assertEquals(1, masterRecords.size());

		List<NameFormattingMasterData__c> runningFormatRecords = [
			SELECT ObjectName__c, Type__c, RunningFormat__c, RunningKey__c, CurrentRunningNumber__c
			FROM NameFormattingMasterData__c
			WHERE Type__c = 'Running Number'
		];
		System.assertEquals(0, runningFormatRecords.size());
	}

	@isTest
	public static void testGenerateReplacedFormatNameWithRunningNumber() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Opportunity',
			RunningFormat__c = 'Reservation-{Name}_{Account.Name}_{RUNNINGNUMBER:0000}',
			RunningPurpose__c = 'Document',
			DocumentTemplateMappingType__c = 'Reservation',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument};

		Opportunity opportunity = [SELECT Id, Name FROM Opportunity];

		String result = RunningNumberUtility.getInstance().generateReplacedFormatName(runningNumberFormatDocument, opportunity.Id, 'Opportunity');
		System.assertEquals(('Reservation-Test Opp_United Oil & Gas Corp._0001'), result);

		List<NameFormattingMasterData__c> masterRecords = [SELECT Id FROM NameFormattingMasterData__c WHERE Type__c = 'Format'];
		System.assertEquals(1, masterRecords.size());

		List<NameFormattingMasterData__c> runningFormatRecords = [
			SELECT ObjectName__c, Type__c, RunningFormat__c, RunningKey__c, CurrentRunningNumber__c
			FROM NameFormattingMasterData__c
			WHERE Type__c = 'Running Number'
		];
		System.assertEquals(1, runningFormatRecords.size());
		System.assertEquals(1, runningFormatRecords.get(0).CurrentRunningNumber__c);
	}

	@isTest
	public static void testGenerateReplacedFormatNameWithMultiRecords() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Invoice__c',
			RunningFormat__c = 'IV-{Opportunity__r.Project__r.ProjectCode__c}{InvoiceDate__c:FORMATDATE:yyMM}',
			RunningPurpose__c = 'Object',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument};

		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		Opportunity opportunity = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();
		for (Integer i = 0; i < 100; i++) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoices.add(invoice);
		}
		insert invoices;

		List<Id> invoiceIds = new List<Id>();
		for (Invoice__c invoice : invoices) {
			invoiceIds.add(invoice.Id);
		}

		Map<Id, String> resultFormatMapByRecordId = RunningNumberUtility.getInstance().generateReplacedFormatName(
			runningNumberFormatDocument,
			invoiceIds,
			'Invoice__c'
		);

		System.assertEquals(invoices.size(), resultFormatMapByRecordId.keySet().size());
		for (String resultFormat : resultFormatMapByRecordId.values()) {
			System.assertEquals('IV-AA012410', resultFormat);
		}

		List<NameFormattingMasterData__c> masterRecords = [SELECT Id FROM NameFormattingMasterData__c WHERE Type__c = 'Format'];
		System.assertEquals(1, masterRecords.size());

		List<NameFormattingMasterData__c> runningFormatRecords = [
			SELECT ObjectName__c, Type__c, RunningFormat__c, RunningKey__c, CurrentRunningNumber__c
			FROM NameFormattingMasterData__c
			WHERE Type__c = 'Running Number'
		];
		System.assertEquals(0, runningFormatRecords.size());
	}

	@isTest
	public static void testGenerateReplacedFormatWithRunningMultiRecords() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Invoice__c',
			RunningFormat__c = 'IV-{Opportunity__r.Project__r.ProjectCode__c}{InvoiceDate__c:FORMATDATE:yyMM}{RUNNINGNUMBER:000}',
			RunningPurpose__c = 'Object',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument};

		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		Opportunity opportunity = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();
		for (Integer i = 0; i < 100; i++) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoices.add(invoice);
		}
		insert invoices;

		List<Id> invoiceIds = new List<Id>();
		for (Invoice__c invoice : invoices) {
			invoiceIds.add(invoice.Id);
		}

		Map<Id, String> resultFormatMapByRecordId = RunningNumberUtility.getInstance().generateReplacedFormatName(
			runningNumberFormatDocument,
			invoiceIds,
			'Invoice__c'
		);

		System.assertEquals(invoices.size(), resultFormatMapByRecordId.keySet().size());
		for (Integer i = 0; i < resultFormatMapByRecordId.values().size(); i++) {
			String resultFormat = resultFormatMapByRecordId.values().get(i);
			String runningNumber = String.valueOf(i + 1).leftPad(3, '0');
			System.assertEquals('IV-AA012410' + runningNumber, resultFormat);
		}

		List<NameFormattingMasterData__c> masterRecords = [SELECT Id FROM NameFormattingMasterData__c WHERE Type__c = 'Format'];
		System.assertEquals(1, masterRecords.size());

		List<NameFormattingMasterData__c> runningFormatRecords = [
			SELECT ObjectName__c, Type__c, RunningFormat__c, RunningKey__c, CurrentRunningNumber__c
			FROM NameFormattingMasterData__c
			WHERE Type__c = 'Running Number'
		];
		System.assertEquals(1, runningFormatRecords.size());
		System.assertEquals(100, runningFormatRecords.get(0).CurrentRunningNumber__c);
	}

	// getNameFormat
	@isTest
	public static void testGetNameDateTimeFormat() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Opportunity',
			RunningFormat__c = 'Reservation-{Name}_{Account.Name}_{PRINTDATETIME:FORMATDATETIME:yyMMdd-HHmm}_{CreatedDate:FORMATDATETIME:yyMMdd-HHmm}',
			RunningPurpose__c = 'Document',
			DocumentTemplateMappingType__c = 'Reservation',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument};

		Opportunity opportunity = [SELECT Id, Name, CreatedDate FROM Opportunity];

		String printDateTime = System.now().format('yyMMdd-HHmm');
		String createdDateTime = opportunity.CreatedDate.format('yyMMdd-HHmm');

		String result = RunningNumberUtility.getInstance().getNameFormat(runningNumberFormatDocument, opportunity.Id, 'Opportunity');
		System.assertEquals(('Reservation-Test Opp_United Oil & Gas Corp._' + printDateTime + '_' + createdDateTime), result);

		List<NameFormattingMasterData__c> masterRecords = [SELECT Id FROM NameFormattingMasterData__c];
		System.assertEquals(1, masterRecords.size());
	}

	@isTest
	public static void testGetNameDateFormat() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Opportunity',
			RunningFormat__c = 'Reservation_{CloseDate:FORMATDATETH:yyMMdd}_{CloseDate:FORMATDATE:yyMMdd}',
			RunningPurpose__c = 'Document',
			DocumentTemplateMappingType__c = 'Reservation',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument};

		Opportunity opportunity = [SELECT Id, Name FROM Opportunity];

		String result = RunningNumberUtility.getInstance().getNameFormat(runningNumberFormatDocument, opportunity.Id, 'Opportunity');
		System.assertEquals('Reservation_671001_241001', result);

		List<NameFormattingMasterData__c> masterRecords = [SELECT Id FROM NameFormattingMasterData__c];
		System.assertEquals(1, masterRecords.size());
	}

	@isTest
	public static void testGetNameFormatFailCase() {
		Opportunity opportunity = [SELECT Id, Name FROM Opportunity];

		try {
			String result = RunningNumberUtility.getInstance().getNameFormat(null, opportunity.Id, 'Opportunity');
		} catch (Exception e) {
			System.assertEquals('not found running format', e.getMessage());
		}
	}

	@isTest
	public static void testGetNameNormalFormatWithRunningNumber() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Invoice__c',
			RunningFormat__c = 'IV-{Opportunity__r.Project__r.ProjectCode__c}{InvoiceDate__c:FORMATDATE:yyMM}{RUNNINGNUMBER:000}',
			RunningPurpose__c = 'Object',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument};

		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		Opportunity opportunity = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c FROM Opportunity];
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
		insert invoice;

		String result = RunningNumberUtility.getInstance().getNameFormat(runningNumberFormatDocument, invoice.Id, 'Invoice__c');
		System.assertEquals('IV-AA012410{RUNNINGNUMBER:000}', result);

		List<NameFormattingMasterData__c> masterRecords = [SELECT Id FROM NameFormattingMasterData__c];
		System.assertEquals(1, masterRecords.size());
	}

	@isTest
	public static void testGetNameNormalFormatWithMultiRecords() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Invoice__c',
			RunningFormat__c = 'IV-{Opportunity__r.Project__r.ProjectCode__c}{InvoiceDate__c:FORMATDATE:yyMM}',
			RunningPurpose__c = 'Object',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument};

		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		Opportunity opportunity = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();
		for (Integer i = 0; i < 1000; i++) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoices.add(invoice);
		}
		insert invoices;

		List<Id> invoiceIds = new List<Id>();
		for (Invoice__c invoice : invoices) {
			invoiceIds.add(invoice.Id);
		}

		Map<Id, String> resultFormatMapByRecordId = RunningNumberUtility.getInstance().getNameFormat(
			runningNumberFormatDocument,
			invoiceIds,
			'Invoice__c'
		);

		System.assertEquals(invoices.size(), resultFormatMapByRecordId.keySet().size());
		for (String resultFormat : resultFormatMapByRecordId.values()) {
			System.assertEquals('IV-AA012410', resultFormat);
		}

		List<NameFormattingMasterData__c> masterRecords = [SELECT Id FROM NameFormattingMasterData__c];
		System.assertEquals(1, masterRecords.size());
	}

	@isTest
	public static void testGetNameFormatMapFailCase() {
		try {
			Opportunity opportunity = [SELECT Id, Name FROM Opportunity];
			Map<Id, String> resultMapByRecId = RunningNumberUtility.getInstance().getNameFormat(
				null,
				new List<Id>{opportunity.Id},
				'Opportunity'
			);
		} catch (Exception e) {
			System.assertEquals('not found running format', e.getMessage());
		}
	}

	// getNameWithReplacedRunningNumber
	@isTest
	public static void testGetNameWithReplacedRunningNumber() {
		Map<String, String> testCaseMap = new Map<String, String>{
			'IV-AA012409{RUNNINGNUMBER:000}_INPUT:1' => 'IV-AA012409001',
			'IV-AA012409{RUNNINGNUMBER:000}_INPUT:12' => 'IV-AA012409012',
			'IV-AA012409{RUNNINGNUMBER:000}_INPUT:997' => 'IV-AA012409997',
			'IV-AA012409{RUNNINGNUMBER:000}-Test_INPUT:100' => 'IV-AA012409100-Test',
			'IV-AA012409{RUNNINGNUMBER:###}_INPUT:5' => 'IV-AA0124095',
			'IV-AA012409{RUNNINGNUMBER:###}_INPUT:34' => 'IV-AA01240934',
			'IV-AA012409{RUNNINGNUMBER:###}_INPUT:999' => 'IV-AA012409999',
			'IV-AA012409{RUNNINGNUMBER:###}-Test_INPUT:510' => 'IV-AA012409510-Test'
		};

		for (String input : testCaseMap.keySet()) {
			List<String> inputs = input.split('_INPUT:');
			String expectedResult = testCaseMap.get(input);
			string actualResult = RunningNumberUtility.getInstance().getNameWithReplacedRunningNumber(inputs.get(0), Integer.valueOf(inputs.get(1)));
			System.assertEquals(expectedResult, actualResult);
		}
	}

	@isTest
	public static void testGetNameWithReplacedRunningNumberFailCase() {
		Map<String, String> testCaseMap = new Map<String, String>{
			'IV-AA012409{RUNNINGNUMBER:000}_INPUT:1000' => 'running format (IV-AA012409{RUNNINGNUMBER:000}) doesn\'t match with current running number (1000)',
			'IV-AA012409{RUNNINGNUMBER:###}_INPUT:1000' => 'running format (IV-AA012409{RUNNINGNUMBER:###}) doesn\'t match with current running number (1000)'
		};

		for (String input : testCaseMap.keySet()) {
			List<String> inputs = input.split('_INPUT:');
			String expectedResult = testCaseMap.get(input);

			try {
				string actualResult = RunningNumberUtility.getInstance().getNameWithReplacedRunningNumber(inputs.get(0), Integer.valueOf(inputs.get(1)));
			} catch (Exception e) {
				Assert.areEqual(expectedResult, e.getMessage());
			}
		}
	}

	// getRunningNumberKey
	@isTest
	public static void testGetRunningNumberKeyNoOldRunningNumber() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Invoice__c',
			RunningFormat__c = 'IV-{Opportunity__r.Project__r.ProjectCode__c}{InvoiceDate__c:FORMATDATE:yyMM}{RUNNINGNUMBER:000}',
			RunningPurpose__c = 'Object',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument};

		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		Opportunity opportunity = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c FROM Opportunity];
		Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
		insert invoice;

		String result = RunningNumberUtility.getInstance().getRunningNumberKey('IV-AA012410{RUNNINGNUMBER:000}', runningNumberFormatDocument);
		System.assertEquals('IV-AA012410001', result);

		List<NameFormattingMasterData__c> masterRecords = [SELECT Id FROM NameFormattingMasterData__c WHERE Type__c = 'Format'];
		System.assertEquals(1, masterRecords.size());

		List<NameFormattingMasterData__c> runningFormatRecords = [
			SELECT ObjectName__c, Type__c, RunningFormat__c, RunningKey__c, CurrentRunningNumber__c
			FROM NameFormattingMasterData__c
			WHERE Type__c = 'Running Number'
		];
		System.assertEquals(1, runningFormatRecords.size());
		System.assertEquals('Invoice__c', runningFormatRecords.get(0).ObjectName__c);
		System.assertEquals('Running Number', runningFormatRecords.get(0).Type__c);
		System.assertEquals(null, runningFormatRecords.get(0).RunningFormat__c);
		System.assertEquals('IV-AA012410{RUNNINGNUMBER:000}', runningFormatRecords.get(0).RunningKey__c);
		System.assertEquals(1, runningFormatRecords.get(0).CurrentRunningNumber__c);
	}

	@isTest
	public static void testGetRunningNumberKeyWithOldRunningNumber() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Invoice__c',
			RunningFormat__c = 'IV-{Opportunity__r.Project__r.ProjectCode__c}{InvoiceDate__c:FORMATDATE:yyMM}{RUNNINGNUMBER:000}',
			RunningPurpose__c = 'Object',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);

		NameFormattingMasterData__c runningNumberFormatDocument2 = new NameFormattingMasterData__c(
			ObjectName__c = 'Invoice__c',
			RunningFormat__c = null,
			RunningKey__c = 'IV-AA012410{RUNNINGNUMBER:000}',
			RunningPurpose__c = 'Object',
			Type__c = 'Running Number',
			CurrentRunningNumber__c = 14
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument, runningNumberFormatDocument2};

		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		Opportunity opportunity = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c FROM Opportunity];
		Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
		insert invoice;

		String result = RunningNumberUtility.getInstance().getRunningNumberKey('IV-AA012410{RUNNINGNUMBER:000}', runningNumberFormatDocument);
		System.assertEquals('IV-AA012410015', result);

		List<NameFormattingMasterData__c> masterRecords = [SELECT Id FROM NameFormattingMasterData__c WHERE Type__c = 'Format'];
		System.assertEquals(1, masterRecords.size());

		List<NameFormattingMasterData__c> runningFormatRecords = [
			SELECT ObjectName__c, Type__c, RunningFormat__c, RunningKey__c, CurrentRunningNumber__c
			FROM NameFormattingMasterData__c
			WHERE Type__c = 'Running Number'
		];
		System.assertEquals(1, runningFormatRecords.size());
		System.assertEquals('Invoice__c', runningFormatRecords.get(0).ObjectName__c);
		System.assertEquals('Running Number', runningFormatRecords.get(0).Type__c);
		System.assertEquals(null, runningFormatRecords.get(0).RunningFormat__c);
		System.assertEquals('IV-AA012410{RUNNINGNUMBER:000}', runningFormatRecords.get(0).RunningKey__c);
		System.assertEquals(15, runningFormatRecords.get(0).CurrentRunningNumber__c);
	}

	@isTest
	public static void testGetRunningNumberKeyWithOldDiffRunningNumber() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Invoice__c',
			RunningFormat__c = 'IV-{Opportunity__r.Project__r.ProjectCode__c}{InvoiceDate__c:FORMATDATE:yyMM}{RUNNINGNUMBER:000}',
			RunningPurpose__c = 'Object',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);

		NameFormattingMasterData__c runningNumberFormatDocument2 = new NameFormattingMasterData__c(
			ObjectName__c = 'Invoice__c',
			RunningFormat__c = null,
			RunningKey__c = 'IV-AA012409{RUNNINGNUMBER:000}',
			RunningPurpose__c = 'Object',
			Type__c = 'Running Number',
			CurrentRunningNumber__c = 15
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument, runningNumberFormatDocument2};

		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		Opportunity opportunity = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c FROM Opportunity];
		Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
		insert invoice;

		String result = RunningNumberUtility.getInstance().getRunningNumberKey('IV-AA012410{RUNNINGNUMBER:000}', runningNumberFormatDocument);
		System.assertEquals('IV-AA012410001', result);

		List<NameFormattingMasterData__c> masterRecords = [SELECT Id FROM NameFormattingMasterData__c WHERE Type__c = 'Format'];
		System.assertEquals(1, masterRecords.size());

		List<NameFormattingMasterData__c> runningFormatRecords = [
			SELECT ObjectName__c, Type__c, RunningFormat__c, RunningKey__c, CurrentRunningNumber__c
			FROM NameFormattingMasterData__c
			WHERE Type__c = 'Running Number'
			ORDER BY CreatedDate
		];
		System.assertEquals(2, runningFormatRecords.size());
		System.assertEquals(runningNumberFormatDocument2.Id, runningFormatRecords.get(0).Id);
		System.assertEquals('Invoice__c', runningFormatRecords.get(1).ObjectName__c);
		System.assertEquals('Running Number', runningFormatRecords.get(1).Type__c);
		System.assertEquals(null, runningFormatRecords.get(1).RunningFormat__c);
		System.assertEquals('IV-AA012410{RUNNINGNUMBER:000}', runningFormatRecords.get(1).RunningKey__c);
		System.assertEquals(1, runningFormatRecords.get(1).CurrentRunningNumber__c);
	}

	// getRunningNumberKeyMapByRecId
	@isTest
	public static void testGetRunningNumberKeyMapNoOldRunningNumber() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Invoice__c',
			RunningFormat__c = 'IV-{Opportunity__r.Project__r.ProjectCode__c}{InvoiceDate__c:FORMATDATE:yyMM}{RUNNINGNUMBER:000}',
			RunningPurpose__c = 'Object',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument};

		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		Opportunity opportunity = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();
		for (Integer i = 0; i < 100; i++) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoices.add(invoice);
		}
		insert invoices;

		Map<Id, String> nameFormatWithRunningKeyMapByRecId = new Map<Id, String>();
		for (Invoice__c invoice : invoices) {
			nameFormatWithRunningKeyMapByRecId.put(invoice.Id, 'IV-AA012410{RUNNINGNUMBER:000}');
		}

		Map<Id, String> resultFormatMapByRecId = RunningNumberUtility.getInstance().getRunningNumberKeyMapByRecId(nameFormatWithRunningKeyMapByRecId, runningNumberFormatDocument);
		System.assertEquals(invoices.size(), resultFormatMapByRecId.keySet().size());

		Set<String> resultFormatSet = new Set<String>();
		for (String resultFormat : resultFormatMapByRecId.values()) {
			resultFormatSet.add(resultFormat);
		}
		System.assertEquals(invoices.size(), resultFormatSet.size());

		List<NameFormattingMasterData__c> masterRecords = [SELECT Id FROM NameFormattingMasterData__c WHERE Type__c = 'Format'];
		System.assertEquals(1, masterRecords.size());

		List<NameFormattingMasterData__c> runningFormatRecords = [
			SELECT ObjectName__c, Type__c, RunningFormat__c, RunningKey__c, CurrentRunningNumber__c
			FROM NameFormattingMasterData__c
			WHERE Type__c = 'Running Number'
		];
		System.assertEquals(1, runningFormatRecords.size());
		System.assertEquals('Invoice__c', runningFormatRecords.get(0).ObjectName__c);
		System.assertEquals('Running Number', runningFormatRecords.get(0).Type__c);
		System.assertEquals(null, runningFormatRecords.get(0).RunningFormat__c);
		System.assertEquals('IV-AA012410{RUNNINGNUMBER:000}', runningFormatRecords.get(0).RunningKey__c);
		System.assertEquals(100, runningFormatRecords.get(0).CurrentRunningNumber__c);
	}

	@isTest
	public static void testGetRunningNumberKeyMapWithOldRunningNumber() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Invoice__c',
			RunningFormat__c = 'IV-{Opportunity__r.Project__r.ProjectCode__c}{InvoiceDate__c:FORMATDATE:yyMM}{RUNNINGNUMBER:000}',
			RunningPurpose__c = 'Object',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);

		NameFormattingMasterData__c runningNumberFormatDocument2 = new NameFormattingMasterData__c(
			ObjectName__c = 'Invoice__c',
			RunningFormat__c = null,
			RunningKey__c = 'IV-AA012410{RUNNINGNUMBER:000}',
			RunningPurpose__c = 'Object',
			Type__c = 'Running Number',
			CurrentRunningNumber__c = 1
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument, runningNumberFormatDocument2};

		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		Opportunity opportunity = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();
		for (Integer i = 0; i < 9; i++) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoices.add(invoice);
		}
		insert invoices;

		Map<Id, String> nameFormatWithRunningKeyMapByRecId = new Map<Id, String>();
		for (Invoice__c invoice : invoices) {
			nameFormatWithRunningKeyMapByRecId.put(invoice.Id, 'IV-AA012410{RUNNINGNUMBER:000}');
		}

		Map<Id, String> resultFormatMapByRecId = RunningNumberUtility.getInstance().getRunningNumberKeyMapByRecId(nameFormatWithRunningKeyMapByRecId, runningNumberFormatDocument);
		System.assertEquals(invoices.size(), resultFormatMapByRecId.keySet().size());

		Set<String> resultFormatSet = new Set<String>();
		for (String resultFormat : resultFormatMapByRecId.values()) {
			resultFormatSet.add(resultFormat);
		}
		System.assertEquals(invoices.size(), resultFormatSet.size());

		List<NameFormattingMasterData__c> masterRecords = [SELECT Id FROM NameFormattingMasterData__c WHERE Type__c = 'Format'];
		System.assertEquals(1, masterRecords.size());

		List<NameFormattingMasterData__c> runningFormatRecords = [
			SELECT ObjectName__c, Type__c, RunningFormat__c, RunningKey__c, CurrentRunningNumber__c
			FROM NameFormattingMasterData__c
			WHERE Type__c = 'Running Number'
		];
		System.assertEquals(1, runningFormatRecords.size());
		System.assertEquals('Invoice__c', runningFormatRecords.get(0).ObjectName__c);
		System.assertEquals('Running Number', runningFormatRecords.get(0).Type__c);
		System.assertEquals(null, runningFormatRecords.get(0).RunningFormat__c);
		System.assertEquals('IV-AA012410{RUNNINGNUMBER:000}', runningFormatRecords.get(0).RunningKey__c);
		System.assertEquals(10, runningFormatRecords.get(0).CurrentRunningNumber__c);
	}

	@isTest
	public static void testGetRunningNumberKeyMapWithOldDiffRunningNumber() {
		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Invoice__c',
			RunningFormat__c = 'IV-{Opportunity__r.Project__r.ProjectCode__c}{InvoiceDate__c:FORMATDATE:yyMM}{RUNNINGNUMBER:000}',
			RunningPurpose__c = 'Object',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);

		NameFormattingMasterData__c runningNumberFormatDocument2 = new NameFormattingMasterData__c(
			ObjectName__c = 'Invoice__c',
			RunningFormat__c = null,
			RunningKey__c = 'IV-AA012409{RUNNINGNUMBER:000}',
			RunningPurpose__c = 'Object',
			Type__c = 'Running Number',
			CurrentRunningNumber__c = 5
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument, runningNumberFormatDocument2};

		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		Opportunity opportunity = [SELECT Id, Name, CloseDate, Project__r.ProjectCode__c FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();
		for (Integer i = 0; i < 100; i++) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoices.add(invoice);
		}
		insert invoices;

		Map<Id, String> nameFormatWithRunningKeyMapByRecId = new Map<Id, String>();
		for (Invoice__c invoice : invoices) {
			nameFormatWithRunningKeyMapByRecId.put(invoice.Id, 'IV-AA012410{RUNNINGNUMBER:000}');
		}

		Map<Id, String> resultFormatMapByRecId = RunningNumberUtility.getInstance().getRunningNumberKeyMapByRecId(nameFormatWithRunningKeyMapByRecId, runningNumberFormatDocument);
		System.assertEquals(invoices.size(), resultFormatMapByRecId.keySet().size());

		Set<String> resultFormatSet = new Set<String>();
		for (String resultFormat : resultFormatMapByRecId.values()) {
			resultFormatSet.add(resultFormat);
		}
		System.assertEquals(invoices.size(), resultFormatSet.size());

		List<NameFormattingMasterData__c> masterRecords = [SELECT Id FROM NameFormattingMasterData__c WHERE Type__c = 'Format'];
		System.assertEquals(1, masterRecords.size());

		List<NameFormattingMasterData__c> runningFormatRecords = [
			SELECT ObjectName__c, Type__c, RunningFormat__c, RunningKey__c, CurrentRunningNumber__c
			FROM NameFormattingMasterData__c
			WHERE Type__c = 'Running Number'
		];
		System.assertEquals(2, runningFormatRecords.size());
		System.assertEquals(runningNumberFormatDocument2.Id, runningFormatRecords.get(0).Id);
		System.assertEquals('Invoice__c', runningFormatRecords.get(1).ObjectName__c);
		System.assertEquals('Running Number', runningFormatRecords.get(1).Type__c);
		System.assertEquals(null, runningFormatRecords.get(1).RunningFormat__c);
		System.assertEquals('IV-AA012410{RUNNINGNUMBER:000}', runningFormatRecords.get(1).RunningKey__c);
		System.assertEquals(100, runningFormatRecords.get(1).CurrentRunningNumber__c);
	}
}