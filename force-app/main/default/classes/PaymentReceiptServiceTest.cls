@isTest
public with sharing class PaymentReceiptServiceTest {
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
		List<Product2> products = new List<Product2>{testProduct,testProduct2,testProduct3};
		insert products;
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
		PricebookEntry testPricebookEntry2 = dataMaker.createPricebookEntries(
			testProduct2.Id,
			15000000,
			20000000,
			10000000
		);
		testPricebookEntry2.Pricebook2Id = pricebookId;
		testPricebookEntry2.UseStandardPrice = false;
		PricebookEntry testPricebookEntry3 = dataMaker.createPricebookEntries(
			testProduct3.Id,
			15000000,
			20000000,
			10000000
		);
		testPricebookEntry3.Pricebook2Id = pricebookId;
		testPricebookEntry3.UseStandardPrice = false;
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{testPricebookEntry1,testPricebookEntry2,testPricebookEntry3};
		insert pricebookEntries;
		// Creat Account
		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
		account.Email__c = 'test@gmail.com.invalid';
		Account account2 = dataMaker.createAccount(recordTypeId, 'Test Account 2');
		Account account3 = dataMaker.createAccount(recordTypeId, 'Test Account 3');
		Account dummyAccount = dataMaker.createAccount(recordTypeId, 'Dummy Accouny');
		dummyAccount.AccountCode__c = '5555';
		List<Account> accounts = new List<Account>{account,account2,account3,dummyAccount};
		insert accounts;
		// Create Dummy Contact
		Contact dummyContact = dataMaker.createContact(dummyAccount.Id, 'Dummy', 'Contact', 'dummyContact@dummy.com', '0111111111');
		dummyContact.IsDummy__c = true;
		List<Contact> contacts = new List<Contact>{dummyContact};
		insert contacts;
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
		Opportunity opportunity2 = dataMaker.createOpportunity(
			account2.Id,
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
			account3.Id,
			'Omitted',
			'Test Opp with Unit 3',
			Date.today(),
			'Open', //Transfer
			testProduct3.Id,
			'Foreign',
			null,
			testProject.Id
		);
		List<Opportunity> opportunities = new List<Opportunity>{opportunity,opportunity2,opportunity3};
		insert opportunities;
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
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice };
		insert invoices;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(
			invoice.Id,
			reservationOppPayment.Id,
			50000,
			Date.newInstance(2024, 12, 1),
			''
		);
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1 };
		insert invoiceLineItems;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opportunity.Id, Date.newInstance(2024, 10, 10));
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{ receipt };
		insert receipts;
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItem = dataMaker.createReceiptLineItem(
			receipt.Id,
			reservationOppPayment.Id,
			invoiceLineItem1.Id,
			50000,
			'Fully Paid'
		);
		PaymentReceiptLineItem__c receiptItem2 = dataMaker.createReceiptLineItem(
			receipt.Id,
			contractOppPayment.Id,
			invoiceLineItem1.Id,
			50000,
			'Partially Paid'
		);
		PaymentReceiptLineItem__c receiptItem3 = dataMaker.createReceiptLineItem(
			receipt.Id,
			contractOppPayment.Id,
			invoiceLineItem1.Id,
			30000,
			'Partially Paid'
		);
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{ receiptItem,receiptItem2,receiptItem3 };
		insert receiptItems;
		// Create Name Formatting
		NameFormattingMasterData__c format = dataMaker.createNameFormattingMasterData(
			'PaymentReceipt__c', 'Format', 'Object', 'RV-{Opportunity__r.Project__r.ProjectCode__c}{CreatedDate:FORMATDATETIME:yyMM}{RUNNINGNUMBER:000}', 1, null
		);
		insert format;
	}

	@isTest
	static void generatePaymentReceiptRelatedToOpportunityTest() {
		Test.startTest();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		PaymentReceipt__c paymentReceipt = service.generatePaymentReceiptRelatedToOpportunity(opportunity.Id);
		System.assertEquals(opportunity.Id, paymentReceipt.Opportunity__c);
		Test.stopTest();
	}

	@isTest
	static void generateRunningNoTest() {
		Test.startTest();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		PaymentReceipt__c paymentReceipt = [SELECT Id, ReceiptNo__c FROM PaymentReceipt__c LIMIT 1];
		PaymentReceipt__c resultPaymentReceipt = service.generateRunningNo(paymentReceipt);
		// System.assertEquals('RV-AA012410001', resultPaymentReceipt.ReceiptNo__c);
		Test.stopTest();
	}

	@isTest
	static void generatePaymentReceiptLineItemFromTotalReceivedAmount() {
		Test.startTest();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		List<OpportunityPayment__c> oppPayments = [
			SELECT
				Id,
				Remaining__c,
				Amount__c,
				(SELECT Id, Invoice__c, Status__c, PaymentReceiptLineItem__c FROM InvoiceLineItems__r)
			FROM OpportunityPayment__c
			ORDER BY Order__c
		];
		OpportunityPayment__c reservationOppPayments = [
			SELECT Id, Remaining__c, Amount__c
			FROM OpportunityPayment__c
			WHERE Term__c = 'Reservation'
			LIMIT 1
		];
		OpportunityPayment__c contractOppPayments = [
			SELECT Id, Remaining__c, Amount__c
			FROM OpportunityPayment__c
			WHERE Term__c = 'Contract'
			LIMIT 1
		];
		InvoiceLineItem__c reservationInvoiceLine = [
			SELECT Id
			FROM InvoiceLineItem__c
			WHERE OpportunityPayment__c = :reservationOppPayments.Id
			LIMIT 1
		];
		List<PaymentReceiptLineItem__c> resultPaymentReceiptItems1 = service.generatePaymentReceiptLineItemFromTotalReceivedAmount(
			50000,
			oppPayments,
			null,
			null
		);
		System.assertEquals(1, resultPaymentReceiptItems1.size());
		System.assertEquals(50000, resultPaymentReceiptItems1[0].ReceivedAmount__c);
		System.assertEquals('Fully Paid', resultPaymentReceiptItems1[0].Status__c);
		System.assertEquals(reservationOppPayments.Id, resultPaymentReceiptItems1[0].OpportunityPayment__c);
		System.assertEquals(reservationInvoiceLine.Id, resultPaymentReceiptItems1[0].InvoiceLineItem__c);
		List<PaymentReceiptLineItem__c> resultPaymentReceiptItems2 = service.generatePaymentReceiptLineItemFromTotalReceivedAmount(
			70000,
			oppPayments,
			null,
			null
		);
		System.assertEquals(2, resultPaymentReceiptItems2.size());
		System.assertEquals(50000, resultPaymentReceiptItems2[0].ReceivedAmount__c);
		System.assertEquals('Fully Paid', resultPaymentReceiptItems2[0].Status__c);
		System.assertEquals(reservationOppPayments.Id, resultPaymentReceiptItems2[0].OpportunityPayment__c);
		System.assertEquals(reservationInvoiceLine.Id, resultPaymentReceiptItems2[0].InvoiceLineItem__c);
		System.assertEquals(20000, resultPaymentReceiptItems2[1].ReceivedAmount__c);
		System.assertEquals('Partially Paid', resultPaymentReceiptItems2[1].Status__c);
		System.assertEquals(contractOppPayments.Id, resultPaymentReceiptItems2[1].OpportunityPayment__c);
		System.assertEquals(null, resultPaymentReceiptItems2[1].InvoiceLineItem__c);
		Test.stopTest();
	}
	@isTest
	static void aggregatePaymentReceiptLineItems(){
		Test.startTest();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		PaymentReceipt__c paymentReceipt = [SELECT Id, ReceiptNo__c FROM PaymentReceipt__c LIMIT 1];
		List<PaymentReceiptLineItem__c> paymentReceiptItems = [
			SELECT Id,
				InvoiceLineItem__c,
				InvoiceLineItem__r.Invoice__c,
				ReceivedAmount__c,
				RemainingAmount__c,
				Status__c,
				PreviousRemaining__c,
				OpportunityPayment__c,
				OpportunityPayment__r.Term__c,
				OpportunityPayment__r.DueDate__c,
				OpportunityPayment__r.Remaining__c,
				OpportunityPayment__r.ReceivedAmount__c,
				OpportunityPayment__r.PaymentStatus__c,
				TransactionDateTime__c,
				PaymentReceipt__r.TotalReceiveAmount__c
			FROM PaymentReceiptLineItem__c
			WHERE PaymentReceipt__c =: paymentReceipt.Id
		];
		List<PaymentReceiptLineItem__c> resultPaymentReceiptItems = service.aggregatePaymentReceiptLineItems(paymentReceiptItems);
		System.assertEquals(2, resultPaymentReceiptItems.size());

		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - add test method for getCancelPaymentReceiptByOppIdSet
	 */
	@isTest
	static void getCancelPaymentReceiptByOppIdSetTest(){
		Test.startTest();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		opportunity.StageName = 'Closed Lost';
		opportunity.LossReason__c = 'Downgrade Unit';
		update opportunity;
		Set<Id> oppIds = new Set<Id>{opportunity.Id};
		List<PaymentReceipt__c> receiptForCancels = service.getCancelPaymentReceiptByOppIdSet(oppIds);
		for (PaymentReceipt__c receiptForCancel : receiptForCancels){
			System.assertEquals(GlobalConstants.RECEIPT_LOST_REASON_DOWNGRADE, receiptForCancel.CancelReason__c);
		}
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - add test method for generateNovationPaymentReceiptRelatedToOpportunity
	 */
	@isTest
	static void generateNovationPaymentReceiptRelatedToOpportunityTest(){
		Test.startTest();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		Opportunity opportunity = [SELECT Id,Account.AddressEN__c FROM Opportunity LIMIT 1];
		PaymentReceipt__c targetReceipt = service.generateNovationPaymentReceiptRelatedToOpportunity(opportunity.Id);
		System.assertEquals(opportunity.Id, targetReceipt.Opportunity__c);
		System.assertEquals(opportunity.Account.AddressEN__c, targetReceipt.AccountAddress__c);
		System.assertEquals(GlobalConstants.RECEIPT_TYPE_NOVATION, targetReceipt.ReceiptType__c);
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - add test method for generateNovationPaymentReceiptLineItem
	 */
	@isTest
	static void generateNovationPaymentReceiptLineItemTest(){
		Test.startTest();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		List<PaymentReceiptLineItem__c> receiptLineItems = service.generateNovationPaymentReceiptLineItem(1000,null,null);
		for(PaymentReceiptLineItem__c receiptLineItem : receiptLineItems){
			System.assertEquals(1, receiptLineItem.LineNumber__c);
			System.assertEquals(1000, receiptLineItem.ReceivedAmount__c);
			System.assertEquals(0, receiptLineItem.PreviousRemaining__c);
			System.assertEquals(null, receiptLineItem.PaymentReceipt__c);
			System.assertEquals('Fully Paid', receiptLineItem.Status__c);
			System.assertEquals(null, receiptLineItem.PaymentMethod__c);
			System.assertEquals(0, receiptLineItem.RemainingAmount__c);
		}
		Test.stopTest();
	}

	/**
	 * Phase2
	 * Details:
	 * - add test method for lookupPaymentReceiptToOpportunityAccountChangeLog
	 */
	@isTest
	static void lookupPaymentReceiptToOpportunityAccountChangeLogTest(){
		Test.startTest();
		PaymentReceiptService service = PaymentReceiptService.getInstance();
		// CASE 1: initial relate PaymentReceipt
		DataMaker dataMaker = DataMaker.getInstance();
		List<Opportunity> opportunities = [SELECT Id,AccountId FROM Opportunity];
		List<PaymentReceipt__c> originalReceipts = [SELECT Id FROM PaymentReceipt__c];
		Opportunity targetOpportunity1 = opportunities[0];
		Opportunity targetOpportunity2 = opportunities[1];
		Opportunity targetOpportunity3 = opportunities[2];
		OpportunityAccountChangeLog__c oppAccChangeLog = dataMaker.createOpportunityAccountChangeLog(targetOpportunity1.Id,targetOpportunity2.Id,targetOpportunity1.AccountId,targetOpportunity2.AccountId);
		insert oppAccChangeLog;
		List<PaymentReceipt__c> receipts = service.lookupPaymentReceiptToOpportunityAccountChangeLog(new Set<Id>{oppAccChangeLog.Id});
		update receipts;
		System.assertEquals(originalReceipts.size(), receipts.size());
		for (PaymentReceipt__c receipt : receipts){
			System.assertEquals(oppAccChangeLog.Id, receipt.OpportunityAccountChangeLog__c);
		}
		// CASE 2: change again
		OpportunityAccountChangeLog__c oppAccChangeLog2 = dataMaker.createOpportunityAccountChangeLog(targetOpportunity2.Id,targetOpportunity3.Id,targetOpportunity2.AccountId,targetOpportunity3.AccountId);
		insert oppAccChangeLog2;
		List<PaymentReceipt__c> receipts2 = service.lookupPaymentReceiptToOpportunityAccountChangeLog(new Set<Id>{oppAccChangeLog2.Id});
		System.assertEquals(originalReceipts.size(), receipts2.size());
		for (PaymentReceipt__c receipt : receipts2){
			System.assertEquals(oppAccChangeLog2.Id, receipt.OpportunityAccountChangeLog__c);
		}
		Test.stopTest();
	}

	@istest
	static void createPaymentReceiptWithLineItemTest(){
		Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE Quota__c = 'Thai'
            LIMIT 1
        ];

        Test.startTest();
        PaymentReceiptService service = PaymentReceiptService.getInstance();
        service.createPaymentReceiptWithLineItem(
            opp.Id,
            100000,
            GlobalConstants.RECEIPT_TYPE_PAYMENTGATEWAY,
            'Credit Card'
        );
        Test.stopTest();

        // ✅ Assertions

        List<PaymentReceipt__c> receipts = [
            SELECT Id, ReceiptType__c, Opportunity__c
            FROM PaymentReceipt__c
            WHERE Opportunity__c = :opp.Id
			AND ReceiptType__c = :GlobalConstants.RECEIPT_TYPE_PAYMENTGATEWAY
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, receipts.size(), 'Should create 1 PaymentReceipt');
        System.assertEquals(GlobalConstants.RECEIPT_TYPE_PAYMENTGATEWAY, receipts[0].ReceiptType__c, 'ReceiptType__c should match');

        List<PaymentMethod__c> paymentMethods = [
            SELECT Id, PaymentType__c, CreditCardNo__c, BankName__c
            FROM PaymentMethod__c
            WHERE PaymentReceipt__c = :receipts[0].Id
        ];
        System.assertEquals(1, paymentMethods.size(), 'Should create 1 PaymentMethod');
        System.assertEquals('Credit Card', paymentMethods[0].PaymentType__c, 'PaymentType__c should match');
        System.assertNotEquals(null, paymentMethods[0].CreditCardNo__c, 'CreditCardNo__c should be filled');
        System.assertEquals('BBL', paymentMethods[0].BankName__c, 'BankName__c should be BBL');

        List<PaymentReceiptLineItem__c> lineItems = [
            SELECT Id, PaymentReceipt__c, PaymentMethod__c
            FROM PaymentReceiptLineItem__c
            WHERE PaymentReceipt__c = :receipts[0].Id
        ];
        System.assert(!lineItems.isEmpty(), 'Should create at least 1 PaymentReceiptLineItem');
        System.assertEquals(paymentMethods[0].Id, lineItems[0].PaymentMethod__c, 'LineItem should link to PaymentMethod');
	}

	@isTest
	static void createPaymentReceiptWithLineItemFromPaymentGatewayTest(){
		Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE Quota__c = 'Thai'
            LIMIT 1
        ];
		Test.startTest();
			PaymentReceiptService service = PaymentReceiptService.getInstance();
			PaymentReceipt__c result = service.createPaymentReceiptWithLineItemFromPaymentGateway(
				opp.Id,
				100000,
				'4111',
				'1234',
				'VISA',
				'CD-1234567890-0001'
			);
        Test.stopTest();
		// Assert
        System.assertNotEquals(null, result);
        // Verify PaymentMethod
        List<PaymentMethod__c> paymentMethods = [
            SELECT Id, CreditCardNo__c, ProviderName__c, Reference1__c, PaymentReceipt__c
            FROM PaymentMethod__c
            WHERE PaymentReceipt__c = :result.Id
        ];
        System.assertEquals(1, paymentMethods.size());
        System.assertEquals('Visa', paymentMethods[0].ProviderName__c);
        System.assertEquals('CD-1234567890-0001', paymentMethods[0].Reference1__c);
        System.assert(paymentMethods[0].CreditCardNo__c.startsWith('4111'));
        System.assert(paymentMethods[0].CreditCardNo__c.endsWith('1234'));

        // Verify Line Items
        List<PaymentReceiptLineItem__c> lineItems = [
            SELECT Id, PaymentReceipt__c, ReceivedAmount__c
            FROM PaymentReceiptLineItem__c
            WHERE PaymentReceipt__c = :result.Id
        ];
        System.assert(lineItems.size() > 0);

        // Verify ReceiptType
        System.assertEquals(GlobalConstants.RECEIPT_TYPE_PAYMENTGATEWAY, result.ReceiptType__c);
	}

	@isTest
    static void sendEmailWithAttachmentTest() {
        // Arrange
        Opportunity testOpp = [
            SELECT Id
            FROM Opportunity
            WHERE Quota__c = 'Thai'
            LIMIT 1
        ];
        PaymentReceipt__c receipt = [SELECT
											Id,
											Opportunity__c,
											Opportunity__r.Account.Email__c,
											Opportunity__r.ContactPerson__r.Email,
											ReceiptNo__c,
											Opportunity__r.Project__r.ProjectCode__c,
											Opportunity__r.Owner.Email,
											Opportunity__r.CRMinCharge__r.Email
										FROM PaymentReceipt__c
										WHERE Opportunity__c = :testOpp.Id LIMIT 1];

		Map<Id, ContentVersion> contentVersionMapByRecordId = new Map<Id, ContentVersion>();
		contentVersionMapByRecordId.put(
			receipt.Id,
			DataMaker.getInstance().createContentVersion(receipt.ReceiptNo__c, (receipt.ReceiptNo__c + '.pdf'))
		);
		System.debug('--w-- contentVersionMapByRecordId: ' + contentVersionMapByRecordId);
		INSERT contentVersionMapByRecordId.values();

		Set<Id> contentVerIdSet = new Set<Id>();
		Map<Id, Id> recordIdMapByContentVerId = new Map<Id, Id>();
		for (Id recordId : contentVersionMapByRecordId.keySet()) {
			recordIdMapByContentVerId.put(contentVersionMapByRecordId.get(recordId).Id, recordId);
			contentVerIdSet.add(contentVersionMapByRecordId.get(recordId).Id);
		}

		List<ContentVersion> contentVersions = [
				SELECT Id, ContentDocumentId, Title, VersionData
				FROM ContentVersion
				WHERE Id IN: contentVerIdSet
					AND IsLatest = true
		];
		System.debug('--w-- contentVersions: ' + contentVersions);

		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		for (ContentVersion contentVersion : contentVersions) {
			contentDocumentLinks.add(
				new ContentDocumentLink(
					LinkedEntityId = recordIdMapByContentVerId.get(contentVersion.Id),
					ContentDocumentId = contentVersion.ContentDocumentId
				)
			);
		}
		insert contentDocumentLinks;

        // Act
        Test.startTest();
        PaymentReceiptService service = PaymentReceiptService.getInstance();
        Messaging.SendEmailResult[] results = service.sendEmailWithAttachment(new List<PaymentReceipt__c>{ receipt });
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, results, 'sendEmailWithAttachment should return results');
        System.assertEquals(true, results[0].isSuccess(), 'Email should be sent successfully');

    }
}