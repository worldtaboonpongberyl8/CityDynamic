/**
 * Phase2
 * Details:
 * - Add new class to be test class of CompleteNovationController
 */
@isTest
public class CompleteNovationControllerTest {
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
		Account account2 = dataMaker.createAccount(recordTypeId, 'Test Account 2');
		Account account3 = dataMaker.createAccount(recordTypeId, 'Test Account 3');
		List<Account> accounts = new List<Account>{account,account2,account3};
		insert accounts;
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
		List<Opportunity> opportunities = new List<Opportunity>{opportunity};
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


	/**
	 * Phase2
	 * Details:
	 * - Add test class to test method completeNovation
	 */
	@isTest
	static void completeNovationTest(){

		DataMaker dataMaker = DataMaker.getInstance();
		List<Opportunity> opportunities = [SELECT Id FROM Opportunity];
		Opportunity targetOpportunity1 = opportunities[0];
		Quote__c quote = dataMaker.createQuote(targetOpportunity1.Id);
		quote.IsSyncing__c = true;
		insert quote;
		List<Account> accounts = [SELECT Id FROM Account ];
		Account account1 = accounts[0];
		Account account2 = accounts[1];
		Account account3 = accounts[2];
		targetOpportunity1.NewCoOwner__c = account2.Id;
		targetOpportunity1.SyncedQuoteId__c = quote.Id;
		update targetOpportunity1;
		// ----- Start Novation for the First Time -----
		Test.startTest();
			Map<String,List<SObject>> resultMap = CompleteNovationController.completeNovation(targetOpportunity1.Id);
		Test.stopTest();
		// ----- Get New Novated Opportunity -----
		Opportunity novatedOpportunity =
			[
				SELECT
					Id,
					Project__c,
					Project__r.Name,
					Unit__c,
					Unit__r.Name,
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
					ReservationDueDate__c,
					DoNotSendInvoice__c,
					CloseDate,
					Account.AddressEN__c,
					Account.AddressTH__c,
					Account.RecordType.DeveloperName,
					UnitPricePersqm__c,
					NetPricePerSqm__c,
					IsPaidNovationFee__c,
					NovateToOpportunity__c,
					NovateFromOpportunity__c,
					NewCoOwner__c,
					(
						SELECT
							Id,
							PromotionMaster__c
						FROM Promotion_Transactions__r
					),
					(
						SELECT
							Id,
							Cost__c,
							Description__c,
							OriginalCost__c,
							PromotionType__c
						FROM Client_Offers__r
					),
					(
						SELECT
							Id,
							AddressEN__c,
							AddressTH__c
						FROM Quote__r
						WHERE IsSyncing__c = TRUE
					),
					(
						SELECT Id,
							AccountName__c,
							Relationship__c
						FROM Co_Borrowers__r
						ORDER BY Priority__c
					),
					(
						SELECT
							Id,
							Amount__c,
							DueDate__c,
							IsMasterData__c,
							Opportunity__c,
							Order__c,
							PaymentStatus__c,
							PaymentTermMaster__c,
							ProjectName__c,
							Quote__c,
							ReceivedAmount__c,
							ReceivedDate__c,
							Remaining__c,
							Term__c,
							Type__c,
							UnitName__c
						FROM Opportunity_Payments__r
					),
					(
						SELECT
							Id
						FROM PaymentReceipt__r
					)
				FROM Opportunity
				WHERE NovateFromOpportunity__c =: targetOpportunity1.Id
				LIMIT 1
			];
		// ----- Get Old Opportunity after Novation -----
		Opportunity afterNovatedOpportunity = [
			SELECT
				NovateToOpportunity__c,
				IsNovationCompleted__c,
				(
				SELECT
					Id
				FROM PaymentReceipt__r
				)
			FROM Opportunity
			WHERE Id =: targetOpportunity1.Id LIMIT 1];
		// ----- Check Data Completeness -----
		System.assertEquals(true, afterNovatedOpportunity.IsNovationCompleted__c);
		System.assertEquals(novatedOpportunity.Id, afterNovatedOpportunity.NovateToOpportunity__c);
		List<PromotionOpportunity__c> actualPromotionOpportunities = novatedOpportunity.Promotion_Transactions__r;
		List<PromotionOpportunity__c> expectedPromotionOpportunities = resultMap.get('clonedOpportunityPromotions');
		System.assertEquals(expectedPromotionOpportunities.size(), actualPromotionOpportunities.size());
		List<ClientOffer__c> actualClientOffers = novatedOpportunity.Client_Offers__r;
		List<ClientOffer__c> expectedClientOffers = resultMap.get('clonedClientOffers');
		System.assertEquals(expectedClientOffers.size(), actualClientOffers.size());
		// ----- Get OpportunityAccountChangeLog__c Record -----
		List<OpportunityAccountChangeLog__c> oppAccountChangeLogs =
			[SELECT
				Id,
				PreviousAccount__c,
				PreviousAccount__r.AccountCode__c,
				CurrentAccount__c,
				PreviousOpportunity__c,
				CurrentOpportunity__c,
				CurrentOpportunity__r.Project__r.ProjectCode__c,
				CurrentOpportunity__r.Unit__r.ProductCode,
				ChangedDatetime__c,
				LastGLStatusInPojjaman__c,
				LastIntegrationDateTime__c,
				ResponseMessage__c,
				(
					SELECT
						Id
					FROM PaymentReceipts__r
				)
			FROM OpportunityAccountChangeLog__c
			WHERE PreviousOpportunity__c =: afterNovatedOpportunity.Id];
		System.assertEquals(1, oppAccountChangeLogs.size());
		OpportunityAccountChangeLog__c oppAccountChangeLog = oppAccountChangeLogs[0];
		// ----- Check Receipt Lookup to OpportunityAccountChangeLog__c record -----
		List<PaymentReceipt__c> oldReceipts = afterNovatedOpportunity.PaymentReceipt__r;
		List<PaymentReceipt__c> receiptsLookedUpToOppAccountChangeLog = oppAccountChangeLog.PaymentReceipts__r;
		System.assertEquals(oldReceipts.size(), receiptsLookedUpToOppAccountChangeLog.size());
		// ----- Novate Again -----
		// Create Opp Payments
		OpportunityPayment__c installmentOppPayment = dataMaker.createOpportunityPayment(
			novatedOpportunity.Id,
			'Installment 1',
			50000,
			Date.newInstance(2024, 10, 15),
			3
		);
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			installmentOppPayment
		};
		insert oppPayments;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(novatedOpportunity.Id, Date.newInstance(2024, 10, 10));
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{ receipt };
		insert receipts;
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItem = dataMaker.createReceiptLineItem(
			receipt.Id,
			installmentOppPayment.Id,
			null,
			50000,
			'Fully Paid'
		);
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{ receiptItem };
		insert receiptItems;
		novatedOpportunity.NewCoOwner__c = account3.Id;
		update novatedOpportunity;
	}
}