@isTest
private class EmailUtilityTest {
	@TestSetup
	static void makeData(){
		DataMaker dataMaker = DataMaker.getInstance();
		// System.runAs ( new User(Id = UserInfo.getUserId()) ) {
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
		// Create Contact
		Contact contact1 = dataMaker.createContact(account.Id, 'Tony', 'Parker', 'contact@contact.com', '0111111111');
		contact1.IsPrimaryContact__c = true;
		List<Contact> contacts = new List<Contact>{contact1};
		insert contacts;
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
		opportunity.ContactPerson__c = contact1.Id;
		insert opportunity;
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opportunity.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment
		};
		insert oppPayments;
	}

	@isTest
	static void getSingleEmailTest(){
		Id orgWideId = OrgWideEmailAddressSelector.getInstance().getByAddress(EmailUtility.getInstance().emailForOrgWide).get(0).Id;

		EmailTemplate emailTemplate =  [
			SELECT Id, Body, Subject, DeveloperName, HtmlValue, TemplateType
			FROM EmailTemplate
			WHERE DeveloperName = 'SendInvoiceToCustomer'
			LIMIT 1
		];

		List<String> toAddresses = new List<String>{'toEmail@toEmail.com'};
		List<String> ccAddresses = new List<String>{'ccEmail@ccEmail.com'};
		List<Messaging.EmailFileAttachment> emailFileAttachments = new List<Messaging.EmailFileAttachment>();

		Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
		attachment.filename = 'testAttachment.pdf';
		attachment.body = Blob.valueOf('content file');
		emailFileAttachments.add(attachment);

		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		List<Opportunity> opportunities = [SELECT Id, Name, Project__r.ProjectCode__c, AccountId, ContactPerson__c, ContactPerson__r.Email FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();
		for (Opportunity opportunity : opportunities) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoices.add(invoice);
		}
		insert invoices;

		Messaging.SingleEmailMessage result = EmailUtility.getInstance().getSingleEmail(
			orgWideId, emailTemplate, toAddresses, ccAddresses, emailFileAttachments, null, invoices.get(0).Id, opportunities.get(0).ContactPerson__c
		);

		System.assertEquals(toAddresses, result.getToAddresses());
		System.assertEquals(ccAddresses, result.getCcAddresses());
		System.assertEquals(emailFileAttachments, result.getFileAttachments());
		System.assertEquals(orgWideId, result.getOrgWideEmailAddressId());
		System.assertEquals(emailTemplate.Id, result.getTemplateId());
		System.assertEquals(invoices.get(0).Id, result.getWhatId());
		System.assertEquals(opportunities.get(0).ContactPerson__c, result.getTargetObjectId());
	}

	@isTest
	static void sendAllEmailMessageTest(){
		EmailTemplate emailTemplate =  [
			SELECT Id, Body, Subject, DeveloperName, HtmlValue, TemplateType
			FROM EmailTemplate
			WHERE DeveloperName = 'SendInvoiceToCustomer'
			LIMIT 1
		];
		List<String> toAddresses = new List<String>{'toEmail@toEmail.com'};

		Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
		singleEmail.setTemplateId(emailTemplate.Id); // Replace with your actual template ID
		singleEmail.setToAddresses( toAddresses );
		singleEmail.setSaveAsActivity(false);

		List<Messaging.SingleEmailMessage> singleEmails = new List<Messaging.SingleEmailMessage>();
		singleEmails.add(singleEmail);
		Messaging.SendEmailResult[] results = EmailUtility.getInstance().sendAllEmailMessage(singleEmails);

		System.assertEquals(singleEmails.size(), results.size());
	}

	@isTest
	static void sendNullEmailMessageTest(){
		Messaging.SendEmailResult[] results = EmailUtility.getInstance().sendAllEmailMessage(null);

		System.assertEquals(null, results);
	}

	@isTest
	static void sendEmptyEmailMessageTest(){
		List<Messaging.SingleEmailMessage> singleEmails = new List<Messaging.SingleEmailMessage>();
		Messaging.SendEmailResult[] results = EmailUtility.getInstance().sendAllEmailMessage(singleEmails);

		System.assertEquals(null, results);
	}

	@isTest
	static void getFileAttachmentTest(){
		String filename = 'testAttachment.pdf';
		Blob body = Blob.valueOf('content file');
		Messaging.EmailFileAttachment result = EmailUtility.getInstance().getFileAttachment(filename, body);

		System.assertEquals(filename, result.filename);
		System.assertEquals(body, result.body);
	}

	@isTest
	static void fakeSendEmailsTest(){
		Id orgWideId = OrgWideEmailAddressSelector.getInstance().getByAddress(EmailUtility.getInstance().emailForOrgWide).get(0).Id;

		EmailTemplate emailTemplate =  [
			SELECT Id, Body, Subject, DeveloperName, HtmlValue, TemplateType
			FROM EmailTemplate
			WHERE DeveloperName = 'SendInvoiceToCustomer'
			LIMIT 1
		];

		List<String> toAddresses = new List<String>{'toEmail@toEmail.com'};
		List<Messaging.EmailFileAttachment> emailFileAttachments = new List<Messaging.EmailFileAttachment>();

		Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
		attachment.filename = 'testAttachment.pdf';
		attachment.body = Blob.valueOf('content file');
		emailFileAttachments.add(attachment);

		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		List<Opportunity> opportunities = [SELECT Id, Name, Project__r.ProjectCode__c, AccountId, ContactPerson__c, ContactPerson__r.Email FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();
		for (Opportunity opportunity : opportunities) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoices.add(invoice);
		}
		insert invoices;

		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account dummyAccount = DataMaker.getInstance().createAccount(recordTypeId, 'Dummy Accouny');
		insert dummyAccount;
		Contact dummyContact = DataMaker.getInstance().createContact(dummyAccount.Id, 'Dummy', 'Contact', 'dummyContact@dummy.com', '0111111111');
		dummyContact.IsDummy__c = true;
		insert dummyContact;

		Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
		singleEmail.setTemplateId(emailTemplate.Id);
		singleEmail.setOrgWideEmailAddressId(orgWideId);
		singleEmail.setToAddresses(toAddresses);
		singleEmail.setSaveAsActivity(false);
		singleEmail.setFileAttachments(emailFileAttachments);
		singleEmail.setTargetObjectId(dummyContact.Id);
		singleEmail.setWhatId(invoices.get(0).Id);

		List<Messaging.SingleEmailMessage> singleEmails = new List<Messaging.SingleEmailMessage>();
		singleEmails.add(singleEmail);

		EmailUtility.getInstance().fakeSendEmails(singleEmails);

		System.assertEquals(toAddresses, singleEmail.getToAddresses());
		System.assertEquals(emailFileAttachments, singleEmail.getFileAttachments());
		System.assertEquals(orgWideId, singleEmail.getOrgWideEmailAddressId());
		System.assertEquals(emailTemplate.Id, singleEmail.getTemplateId());
		System.assertEquals(invoices.get(0).Id, singleEmail.getWhatId());
		System.assertEquals(dummyContact.Id, singleEmail.getTargetObjectId());
		System.assert(!singleEmail.getSubject().contains('{!'), 'Email Subject all field tags replaced by field value');
		System.assert(!singleEmail.getHTMLBody().contains('{!'), 'Email HTML Body all field tags replaced by field value');
	}

	@isTest
	static void getSingleEmailFromTempEmailTest(){
		Id orgWideId = OrgWideEmailAddressSelector.getInstance().getByAddress(EmailUtility.getInstance().emailForOrgWide).get(0).Id;

		EmailTemplate emailTemplate =  [
			SELECT Id, Body, Subject, DeveloperName, HtmlValue, TemplateType
			FROM EmailTemplate
			WHERE DeveloperName = 'SendInvoiceToCustomer'
			LIMIT 1
		];

		List<String> toAddresses = new List<String>{'toEmail@toEmail.com'};
		List<Messaging.EmailFileAttachment> emailFileAttachments = new List<Messaging.EmailFileAttachment>();

		Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
		attachment.filename = 'testAttachment.pdf';
		attachment.body = Blob.valueOf('content file');
		emailFileAttachments.add(attachment);

		Date dueDate = Date.newInstance(2024, 10, 25);
		Date invoiceDate = Date.newInstance(2024, 10, 20);
		List<Opportunity> opportunities = [SELECT Id, Name, Project__r.ProjectCode__c, AccountId, ContactPerson__c, ContactPerson__r.Email FROM Opportunity];
		List<Invoice__c> invoices = new List<Invoice__c>();
		for (Opportunity opportunity : opportunities) {
			Invoice__c invoice = DataMaker.getInstance().createInvoice(opportunity.Id, dueDate, invoiceDate, false, 'Adrress');
			invoices.add(invoice);
		}
		insert invoices;

		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account dummyAccount = DataMaker.getInstance().createAccount(recordTypeId, 'Dummy Accouny');
		insert dummyAccount;
		Contact dummyContact = DataMaker.getInstance().createContact(dummyAccount.Id, 'Dummy', 'Contact', 'dummyContact@dummy.com', '0111111111');
		dummyContact.IsDummy__c = true;
		insert dummyContact;

		Messaging.SingleEmailMessage tempEmail = new Messaging.SingleEmailMessage();
		tempEmail.setTemplateId(emailTemplate.Id);
		tempEmail.setOrgWideEmailAddressId(orgWideId);
		tempEmail.setToAddresses(toAddresses);
		tempEmail.setSaveAsActivity(false);
		tempEmail.setFileAttachments(emailFileAttachments);
		tempEmail.setTargetObjectId(dummyContact.Id);
		tempEmail.setWhatId(invoices.get(0).Id);

		List<Messaging.SingleEmailMessage> tempEmails = new List<Messaging.SingleEmailMessage>();
		tempEmails.add(tempEmail);

		Savepoint savePoint = Database.setSavepoint();
		Messaging.sendEmail(tempEmails);
		Database.rollback(savePoint);

		Messaging.SingleEmailMessage result = EmailUtility.getInstance().getSingleEmailFromTempEmail(tempEmail,null);

		System.assertEquals(tempEmail.getToAddresses(), result.getToAddresses());
		// System.assertEquals(tempEmail.getHTMLBody(), result.getHTMLBody());
		System.assertEquals(tempEmail.getSubject(), result.getSubject());
		System.assertEquals(tempEmail.getOrgWideEmailAddressId(), result.getOrgWideEmailAddressId());
		System.assertEquals(tempEmail.getFileAttachments(), result.getFileAttachments());
	}
}