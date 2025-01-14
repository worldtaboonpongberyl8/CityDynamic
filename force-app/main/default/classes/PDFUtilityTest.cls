@isTest
private class PDFUtilityTest {
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
		Opportunity opportunity = dataMaker.createOpportunity(
			account.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Thai',
			null,
			testProject.Id
		);
		insert opportunity;
		// Create Opp Payments
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		OpportunityPayment__c contractOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 27),
			2
		);
		OpportunityPayment__c installmentOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Installment 1',
			10000000,
			Date.newInstance(2024, 10, 27),
			3
		);
		OpportunityPayment__c transferOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
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
		// Create Invoice
		Invoice__c invoice = dataMaker.createInvoice(opportunity.Id, Date.newInstance(2024, 10, 6), Date.newInstance(2024, 10, 1), true, 'Address');
		Invoice__c invoice2 = dataMaker.createInvoice(opportunity.Id, Date.newInstance(2024, 11, 6), Date.newInstance(2024, 11, 1),  true, 'Address');
        Invoice__c invoice3 = dataMaker.createInvoice(opportunity.Id, Date.newInstance(2024, 10, 6), Date.newInstance(2024, 10, 1), false, 'Address');
		Invoice__c invoice4 = dataMaker.createInvoice(opportunity.Id, Date.newInstance(2024, 11, 6), Date.newInstance(2024, 11, 1), false, 'Address');
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice, invoice2,invoice3,invoice4 };
		insert invoices;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(
			invoice.Id,
			reservationOppPayment.Id,
			50000,
			Date.newInstance(2024, 12, 1),
			''
		);
		InvoiceLineItem__c invoiceLineItem2 = dataMaker.createInvoiceLineItem(
			invoice2.Id,
			contractOppPayment.Id,
			100000,
			Date.newInstance(2025, 1, 1),
			''
		);
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1, invoiceLineItem2 };
		insert invoiceLineItems;
		// Create Name Formatting
		NameFormattingMasterData__c format = dataMaker.createNameFormattingMasterData(
			'PaymentReceipt__c', 'Format', 'Object', 'RV-{Opportunity__r.Project__r.ProjectCode__c}{{CreatedDate:FORMATDATETIME:yyMM}{RUNNINGNUMBER:000}', 1, null
		);
		insert format;
	}

	// createPdfFileToRecord()
	@isTest
	static void createPdfFileToOwnRecordTest() {
		List<Invoice__c> invoices = [SELECT Id, Opportunity__c FROM Invoice__c];
		Map<Id, String> fileNameMapWithRecordId = new Map<Id, String>{
			invoices[0].Id => 'IV-AA012410001'
		};

		List<ContentDocumentLink> results = PDFUtility.getInstance().createPdfFileToRecord(
			'InvoiceForm',
			fileNameMapWithRecordId,
			new List<Id>{ invoices[0].Id },
			null
		);
		System.assertEquals(1, results.size());
		System.assertNotEquals(null, results.get(0).Id);
		System.assertEquals(invoices[0].Id, results.get(0).LinkedEntityId);

		List<ContentDocumentLink> contentDocLinkResults = [
			SELECT LinkedEntityId, ContentDocumentId
			FROM ContentDocumentLink
			WHERE Id =: results.get(0).Id
		];
		System.assertEquals(1, contentDocLinkResults.size());
		System.assertEquals(invoices[0].Id, contentDocLinkResults.get(0).LinkedEntityId);

		List<ContentVersion> contentVersionResults = [
			SELECT Title, FileExtension, IsLatest
			FROM ContentVersion
			WHERE ContentDocumentId =: results.get(0).ContentDocumentId
		];
		System.assertEquals(1, contentVersionResults.size());
		System.assertEquals(fileNameMapWithRecordId.get(invoices[0].Id), contentVersionResults.get(0).Title);
		System.assertEquals('pdf', contentVersionResults.get(0).FileExtension);
		System.assertEquals(true, contentVersionResults.get(0).IsLatest);
	}

	@isTest
	static void createPdfFileToOtherRecordTest() {
		List<Invoice__c> invoices = [SELECT Id,Opportunity__c FROM Invoice__c];
		Map<Id, String> fileNameMapWithRecordId = new Map<Id, String>{
			invoices[0].Opportunity__c => 'Payment Summary-AA01'
		};

		Map<Id, Id> recordIdToSaveFileMapByRecordId = new Map<Id, Id>{
			invoices[0].Opportunity__c => invoices[0].Id
		};

		List<ContentDocumentLink> results = PDFUtility.getInstance().createPdfFileToRecord(
			'PaymentSummaryForm',
			fileNameMapWithRecordId,
			new List<Id>{ invoices[0].Opportunity__c },
			recordIdToSaveFileMapByRecordId
		);
		System.assertEquals(1, results.size());
		System.assertNotEquals(null, results.get(0).Id);
		System.assertEquals(invoices[0].Id, results.get(0).LinkedEntityId);

		List<ContentDocumentLink> contentDocLinkResults = [
			SELECT LinkedEntityId, ContentDocumentId
			FROM ContentDocumentLink
			WHERE Id =: results.get(0).Id
		];
		System.assertEquals(1, contentDocLinkResults.size());
		System.assertEquals(invoices[0].Id, contentDocLinkResults.get(0).LinkedEntityId);

		List<ContentVersion> contentVersionResults = [
			SELECT Title, FileExtension, IsLatest
			FROM ContentVersion
			WHERE ContentDocumentId =: results.get(0).ContentDocumentId
		];
		System.assertEquals(1, contentVersionResults.size());
		System.assertEquals(fileNameMapWithRecordId.get(invoices[0].Opportunity__c), contentVersionResults.get(0).Title);
		System.assertEquals('pdf', contentVersionResults.get(0).FileExtension);
		System.assertEquals(true, contentVersionResults.get(0).IsLatest);
	}

	@isTest
	static void createPdfFileTNoFileNameTest() {
		List<Invoice__c> invoices = [SELECT Id, Opportunity__c FROM Invoice__c];
		Map<Id, String> fileNameMapWithRecordId = new Map<Id, String>{
			invoices[0].Id => null
		};

		List<ContentDocumentLink> results = PDFUtility.getInstance().createPdfFileToRecord(
			'InvoiceForm',
			fileNameMapWithRecordId,
			new List<Id>{ invoices[0].Id },
			null
		);
		System.assertEquals(1, results.size());
		System.assertNotEquals(null, results.get(0).Id);
		System.assertEquals(invoices[0].Id, results.get(0).LinkedEntityId);

		List<ContentDocumentLink> contentDocLinkResults = [
			SELECT LinkedEntityId, ContentDocumentId
			FROM ContentDocumentLink
			WHERE Id =: results.get(0).Id
		];
		System.assertEquals(1, contentDocLinkResults.size());
		System.assertEquals(invoices[0].Id, contentDocLinkResults.get(0).LinkedEntityId);

		List<ContentVersion> contentVersionResults = [
			SELECT Title, FileExtension, IsLatest
			FROM ContentVersion
			WHERE ContentDocumentId =: results.get(0).ContentDocumentId
		];
		System.assertEquals(1, contentVersionResults.size());
		System.assertEquals('InvoiceForm', contentVersionResults.get(0).Title);
		System.assertEquals('pdf', contentVersionResults.get(0).FileExtension);
		System.assertEquals(true, contentVersionResults.get(0).IsLatest);
	}

	// getImageSrc()
	@isTest
	static void getImageSrcTest(){
		// Test Case 1: Valid HTML string with an image tag
		String htmlStringWithImage = '<img src="https://example.com/image.png" alt="Example Image">';
		String expectedSrc = 'https://example.com/image.png';
		String actualSrc = PDFUtility.getInstance().getImageSrc(htmlStringWithImage);
		System.assertEquals(expectedSrc, actualSrc, 'The extracted src value should be https://example.com/image.png');

		// Test Case 2: HTML string without an image tag
		String htmlStringWithoutImage = '<div>No image here</div>';
		actualSrc = PDFUtility.getInstance().getImageSrc(htmlStringWithoutImage);
		System.assertEquals('', actualSrc, 'The src value should be an empty string when no image tag is present');

		// Test Case 3: Empty HTML string
		String emptyHtmlString = '';
		actualSrc = PDFUtility.getInstance().getImageSrc(emptyHtmlString);
		System.assertEquals('', actualSrc, 'The src value should be an empty string for an empty input');

		// Test Case 4: HTML string with multiple attributes, checking if &amp; is correctly replaced
		String htmlStringWithSpecialChars = '<img src="https://example.com/image&amp;id=123.png" alt="Example Image">';
		expectedSrc = 'https://example.com/image&id=123.png';
		actualSrc = PDFUtility.getInstance().getImageSrc(htmlStringWithSpecialChars);
		System.assertEquals(expectedSrc, actualSrc, 'The extracted src value should replace &amp; with &');

		// Test Case 5: HTML string with no src attribute
		String htmlStringNoSrc = '<img alt="No src">';
		actualSrc = PDFUtility.getInstance().getImageSrc(htmlStringNoSrc);
		System.assertEquals('', actualSrc, 'The src value should be an empty string when no src attribute is present');
	}

	// getContactText()
	@isTest
	static void getContactTextTest(){
		Map<String, String> testCaseMap = new Map<String, String>{
            '081-111-1111_test1@test.com' => '081-111-1111, Email: test1@test.com',
            '081-222-2222_' => '081-222-2222',
            '_test2@test.com' => 'Email: test2@test.com',
            '' => ''
        };

		for (String input : testCaseMap.keySet()) {
			List<String> parameters = input.split('_');
			String expectedResult = testCaseMap.get(input);
			if(parameters.size() < 2){
				parameters.add('');
				parameters.add('');
			}
			string actualResult = PDFUtility.getInstance().getContactText(parameters.get(0), parameters.get(1));
			System.assertEquals(expectedResult, actualResult);
		}
	}
}