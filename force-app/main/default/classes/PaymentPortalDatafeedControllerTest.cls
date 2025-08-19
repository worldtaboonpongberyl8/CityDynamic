@isTest
public with sharing class PaymentPortalDatafeedControllerTest {
    @TestSetup
	static void makeData(){
		DataMaker dataMaker = DataMaker.getInstance();
		// Create Project
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		testProject.CompanyName__c ='Test Company Name';
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
			'UN01',
			testProject.Id,
			testFloor.Id,
			'Transferred',
			unitType.Id
		);
		testProduct.ReservationPrice__c = 100000;
		testProduct.TransferredDate__c = Date.today();
		List<Product2> products = new List<Product2>{testProduct};
		insert products;
		// Create PaymentTermMaster__c
		PaymentTermMaster__c paymentTermMaster = dataMaker.craetePaymentTermMaster(
			testProject.Id,
			'FQ Series 5-10-85',
			'Series',
			'Foreign',
			25
		);
		insert paymentTermMaster;
		PaymentTerm__c contractLineItem = dataMaker.createPaymentTermLineItem(paymentTermMaster.Id,1,1000000,null,'Contract');
		PaymentTerm__c installment1LineItem = dataMaker.createPaymentTermLineItem(paymentTermMaster.Id,2,100000,null,'Installment 1');
		PaymentTerm__c installment2LineItem = dataMaker.createPaymentTermLineItem(paymentTermMaster.Id,3,100000,null,'Installment 2');
		PaymentTerm__c installment3LineItem = dataMaker.createPaymentTermLineItem(paymentTermMaster.Id,1,100000,null,'Installment 3');
		List<PaymentTerm__c> paymentTermLineItems = new List<PaymentTerm__c>{contractLineItem,installment1LineItem,installment2LineItem,installment3LineItem};
		insert paymentTermLineItems;
		// Create Pricebook Entry
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 15000000, 15000000,15000000);
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
		Account targetAccount = dataMaker.createAccount(recordTypeId, 'Test Account');
		targetAccount.Email__c = 'test@gmail.com.invalid';
		targetAccount.AccountCode__c = '1111';
		Account targetAccount2 = dataMaker.createAccount(recordTypeId, 'Test Account 2');
		targetAccount2.AccountCode__c = '2222';
		Account targetAccount3 = dataMaker.createAccount(recordTypeId, 'Test Account 3');
		targetAccount3.AccountCode__c = '3333';
		Account targetAccount4 = dataMaker.createAccount(recordTypeId, 'Test Account 4');
		targetAccount4.AccountCode__c = '4444';
		Account dummyAccount = dataMaker.createAccount(recordTypeId, 'Dummy Accouny');
		dummyAccount.AccountCode__c = '5555';
		List<Account> accounts = new List<Account>{targetAccount,targetAccount2,targetAccount3,targetAccount4,dummyAccount};
		insert accounts;
		// Create Dummy Contact
		Contact dummyContact = dataMaker.createContact(dummyAccount.Id, 'Dummy', 'Contact', 'dummyContact@dummy.com', '0111111111');
		dummyContact.IsDummy__c = true;
		List<Contact> contacts = new List<Contact>{dummyContact};
		insert contacts;
		// Create Opportunity
		Opportunity opp1 = dataMaker.createOpportunity(
			targetAccount.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct.Id,
			'Foreign',
			paymentTermMaster.Id,
			testProject.Id
		);
		List<Opportunity> opportunities = new List<Opportunity>{ opp1 };
		insert opportunities;
		// Create Name Formatting
		NameFormattingMasterData__c receiptFormatObject = dataMaker.createNameFormattingMasterData(
			'PaymentReceipt__c', 'Format', 'Object', 'RV-{Opportunity__r.Project__r.ProjectAbbreviated__c}{CreatedDate:FORMATDATETIME:yyMM}{RUNNINGNUMBER:000}', 1, null
		);
		NameFormattingMasterData__c receiptFormatDocument = dataMaker.createNameFormattingMasterData(
			'PaymentReceipt__c', 'Format', 'Document', '{ReceiptNo__c}', 1, 'Payment Receipt'
		);
		List<NameFormattingMasterData__c> nameFormattings = new List<NameFormattingMasterData__c>{receiptFormatObject,receiptFormatDocument};
		insert nameFormattings;
	}

	@isTest
    static void testProceedDatafeedResponse_SuccessCase() {

		Opportunity targetOpp = [SELECT Id FROM Opportunity LIMIT 1];
		OpportunityPayment__c oppPayment = [SELECT Id FROM OpportunityPayment__c WHERE Opportunity__c =: targetOpp.Id AND Term__c = 'Reservation'] ;
        PaymentGatewayReference__c ref = new PaymentGatewayReference__c(
            OpportunityPayment__c = oppPayment.Id,
            OrderReference__c = 'CD-1234567890-0001'
        );
        insert ref;

        Test.startTest();
			Test.setCurrentPageReference(new PageReference('/apex/dummy'));
			ApexPages.currentPage().getParameters().put('Ref', ref.OrderReference__c);
			ApexPages.currentPage().getParameters().put('successcode', '0');
			ApexPages.currentPage().getParameters().put('Amt', '100000');
			ApexPages.currentPage().getParameters().put('eci', '07');
			ApexPages.currentPage().getParameters().put('cc0104', '4111');
			ApexPages.currentPage().getParameters().put('cc1316', '1234');
			ApexPages.currentPage().getParameters().put('CreditCard', '4111111111111234');
			ApexPages.currentPage().getParameters().put('PayMethod', 'VISA');

			PaymentPortalDatafeedController controller = new PaymentPortalDatafeedController();
			controller.proceedDatafeedResponse();
        Test.stopTest();

        // Assert
        List<PaymentGatewayReference__c> updatedRefs = [
            SELECT
				Id,
				DatafeedStatus__c,
				OpportunityPayment__c,
				OpportunityPayment__r.Opportunity__c,
				OrderReference__c,
				ReceivedAmount__c,
				RejectedReason__c,
				SFErrorMessage__c,
				SFStatus__c
			FROM PaymentGatewayReference__c WHERE Id = :ref.Id
        ];
        System.assertEquals(GlobalConstants.PGF_STATUS_ACCEPTED, updatedRefs[0].DatafeedStatus__c);

        List<PaymentReceipt__c> receipts = [
            SELECT Id, ReceiptType__c FROM PaymentReceipt__c WHERE Opportunity__c = :targetOpp.Id
        ];
        System.assertEquals(1, receipts.size());
        System.assertEquals(GlobalConstants.RECEIPT_TYPE_PAYMENTGATEWAY, receipts[0].ReceiptType__c);

		// 🔍 Find the ContentDocumentLink tied to the PaymentReceipt
		List<ContentDocumentLink> links = [
			SELECT ContentDocumentId, LinkedEntityId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :receipts[0].Id
		];
		// System.assertEquals(1, links.size());

		// 🔍 Optionally confirm that a file (ContentDocument) exists with correct title or type
		List<ContentDocument> documents = [
			SELECT Id, Title, FileExtension, ContentSize
			FROM ContentDocument
			WHERE Id =: links[0].ContentDocumentId
		];
		// System.assertEquals(1, Limits.getEmailInvocations());
    }

}