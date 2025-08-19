@isTest
public class CreateReceiptApiCalloutTest {
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
		testProduct.ReservationPrice__c = 10000;
		testProduct.TransferredDate__c = Date.today();
		Product2 testProduct2 = dataMaker.createUnit(
			'Test Product 2',
			'UN01',
			testProject.Id,
			testFloor.Id,
			'Transferred',
			unitType.Id
		);
		testProduct2.ReservationPrice__c = 10000;
		testProduct2.TransferredDate__c = Date.today();
		Product2 testProduct3 = dataMaker.createUnit(
			'Test Product 3',
			'UN01',
			testProject.Id,
			testFloor.Id,
			'Transferred',
			unitType.Id
		);
		testProduct3.ReservationPrice__c = 10000;
		testProduct3.TransferredDate__c = Date.today();
		List<Product2> products = new List<Product2>{testProduct,testProduct2,testProduct3};
		insert products;
		// Create Pricebook Entry
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 15000000, 20000000,10000000);
		testPricebookEntry1.Pricebook2Id = pricebookId;
		testPricebookEntry1.UseStandardPrice = false;
		PricebookEntry testPricebookEntry2 = dataMaker.createPricebookEntries(testProduct2.Id, 15000000, 20000000,10000000);
		testPricebookEntry2.Pricebook2Id = pricebookId;
		testPricebookEntry2.UseStandardPrice = false;
		PricebookEntry testPricebookEntry3 = dataMaker.createPricebookEntries(testProduct3.Id, 15000000, 20000000,10000000);
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
		Account targetAccount = dataMaker.createAccount(recordTypeId, 'Test Account');
		targetAccount.AccountCode__c = '1234';
		insert targetAccount;
		// Create Payment Term Master
		PaymentTermMaster__c paymentTermMaster = dataMaker.craetePaymentTermMaster(
			testProject.Id,
			'FQ Series 5-10-85',
			'Series',
			'Foreign',
			25
		);
		insert paymentTermMaster;
		// Create Opportunity
		OpportunityTriggerHandler oppTriggerHandler = OpportunityTriggerHandler.getInstance();
		oppTriggerHandler.setBypass();
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
		opp1.Quota__c = 'Foreign';
		insert opp1;
		// opp1.ReservationDueDate__c = Date.newInstance(2024, 10, 12);
		// opp1.StageName = 'Reservation';
		// update opp1;

		// Create Opp Payments
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opp1.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		reservationOppPayment.ReceivedAmount__c = 50000;
		OpportunityPayment__c contractOppPayment = dataMaker.createOpportunityPayment(
			opp1.Id,
			'Contract',
			100000,
			Date.newInstance(2024, 10, 15),
			2
		);
		contractOppPayment.ReceivedAmount__c = 100000;
		OpportunityPayment__c installment1OppPayment = dataMaker.createOpportunityPayment(
			opp1.Id,
			'Installment 1',
			8000,
			Date.newInstance(2024, 10, 15),
			3
		);
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment,contractOppPayment,installment1OppPayment
		};
		insert oppPayments;
		// Create Invoice
		Invoice__c invoice = dataMaker.createInvoice(opp1.Id, Date.newInstance(2024, 10, 6), Date.newInstance(2024, 10, 1), true, 'Address');
		invoice.InvoiceNo__c = '1111';
		invoice.CoBuyerAccountCode__c = '1111,2222';
		Invoice__c invoice2 = dataMaker.createInvoice(opp1.Id, Date.newInstance(2024, 11, 6), Date.newInstance(2024, 11, 1), true, 'Address');
		invoice2.InvoiceNo__c = '2222';
		invoice2.CoBuyerAccountCode__c = '3333,4444';
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice , invoice2};
		insert invoices;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(invoice.Id,contractOppPayment.Id,100000,Date.newInstance(2024, 12, 1),'');
		InvoiceLineItem__c invoiceLineItem2 = dataMaker.createInvoiceLineItem(invoice2.Id,installment1OppPayment.Id,8000,Date.newInstance(2025, 1 , 1),'');
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1,invoiceLineItem2 };
		insert invoiceLineItems;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opp1.Id , Date.newInstance(2024, 10, 10));
		receipt.ReceiptNo__c = '1111';
		receipt.CoBuyerAccountCode__c = '1111,2222';
		// receipt.CancelReason__c = GlobalConstants.RECEIPT_LOST_REASON_NOVATION;
		PaymentReceipt__c receipt2 = dataMaker.craeteReceipt(opp1.Id , Date.newInstance(2024, 10, 10));
		receipt2.ReceiptNo__c = '2222';
		receipt2.CoBuyerAccountCode__c = '1111,2222';
		// receipt2.CancelReason__c = GlobalConstants.RECEIPT_LOST_REASON_NOVATION;
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt,receipt2};
		insert receipts;
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,null,50000,'Fully Paid');
		PaymentReceiptLineItem__c receiptItemContract = dataMaker.createReceiptLineItem(receipt2.Id,contractOppPayment.Id,invoiceLineItem1.Id,100000,'Fully Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{ receiptItemReservation,receiptItemContract };
		insert receiptItems;
		// Create Payment method
		PaymentMethod__c receiptMethod = dataMaker.createPaymentMethod(receipt.Id,'KBANK',Decimal.valueOf(50000),'Cash','Reservation',Date.today());
		PaymentMethod__c receiptMethod2 = dataMaker.createPaymentMethod(receipt2.Id,'KBANK',Decimal.valueOf(100000),'Cash','Reservation',Date.today());
		List<PaymentMethod__c> receiptMethods = new List<PaymentMethod__c>{receiptMethod,receiptMethod2};
		insert receiptMethods;
		// update opp stage to Closed Lost
		// opp1.StageName = GlobalConstants.OPP_STAGENAME_CLOSED_LOST;
		// opp1.LossReason__c = GlobalConstants.OPP_LOST_REASON_DOWNGRADE;
		// update opp1;
		oppTriggerHandler.clearBypass();
	}

	@isTest
	static void buildRequestDataModelCreateTest(){
		List<PaymentReceipt__c> paymentReceipts = [
			SELECT
				Id,
				AccountAddress__c,
				CreatedDate,
				DueDate__c,
				IsCancel__c,
				CancelReason__c,
				LastIntegrationDateTime__c,
				LastCreatedStatusInPojjaman__c,
				LastCancelledStatusInPojjaman__c,
				Opportunity__c,
				ReceiptNo__c,
				ResponseCode__c,
				ResponseMessage__c,
				TotalReceiveAmount__c,
				GLKey__c,
				GLDate__c,
				Opportunity__r.Account.AccountCode__c,
				Opportunity__r.Project__r.ProjectCode__c,
				CoBuyerAccountCode__c,
				ReceiptType__c,
				(
					SELECT
						Id,
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
						OpportunityPayment__r.Order__c,
						TransactionDateTime__c,
						PaymentReceipt__r.TotalReceiveAmount__c,
						PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode,
						ResponseCode__c,
						ResponseMessage__c,
						LastIntegrationDateTime__c,
						ReceiptLineItemType__c
					FROM Payment_Transactions__r
					ORDER BY OpportunityPayment__r.Order__c, Name
				),
				(
					SELECT
						Id,
						PaymentType__c,
						CreditCardNo__c,
						DebitCardNo__c,
						ChequeNo__c,
						BankBranch__c,
						BankName__c,
						BankAccountNo__c,
						CompanyBank__r.BankAccountNumber__c,
						PaymentDate__c,
						ReceivedAmount__c,
						InternationalBankName__c,
						ResponseCode__c,
						ResponseMessage__c,
						LastIntegrationDateTime__c
					FROM PaymentMethods__r
				)
			FROM PaymentReceipt__c
			WHERE (LastModifiedDate = TODAY
			OR LastCreatedStatusInPojjaman__c = null
			OR LastCreatedStatusInPojjaman__c = 'Fail'
			OR LastCancelledStatusInPojjaman__c = 'Fail')
			ORDER BY CreatedDate ASC
		];
		CreateReceiptApiCallout callout = new CreateReceiptApiCallout(paymentReceipts);
		Object request = callout.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(null, request);
		System.assertEquals(paymentReceipts.size(), requestModels.size());
		for (Integer i = 0; i < paymentReceipts.size(); i++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = requestModels[i];
			PaymentReceipt__c receipt = paymentReceipts[i];
			System.assertEquals(receipt.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(receipt.Id, requestDataModel.SFDocId);
			System.assertEquals(receipt.CreatedDate.date(), requestDataModel.DocDate);
			System.assertEquals('RP', requestDataModel.DocType);
			System.assertEquals(receipt.ReceiptNo__c, requestDataModel.ReceiptCode);
			System.assertEquals(null, requestDataModel.InvoiceCode);
			System.assertEquals(0, requestDataModel.Indicator);
			System.assertEquals(null, requestDataModel.GroupKey);
			System.assertEquals(null, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(receipt.CoBuyerAccountCode__c.split(','), requestDataModel.CoBuyerCustomerCode);
		}
	}

	@isTest
	static void buildRequestDataModelCancelTest(){
		List<PaymentReceipt__c> updatedPaymentReceipts = [
			SELECT
				Id
			FROM PaymentReceipt__c
			ORDER BY CreatedDate DESC
		];
		for (PaymentReceipt__c receipt : updatedPaymentReceipts){
			receipt.CancelReason__c = GlobalConstants.RECEIPT_LOST_REASON_CRM;
			receipt.CancelReasonforCRM__c = 'Test';
			update receipt;
		}
		// OpportunityTriggerHandler.getInstance().setBypass();
		// update updatedPaymentReceipts;
		// OpportunityTriggerHandler.getInstance().clearBypass();
		List<PaymentReceipt__c> paymentReceipts = [
			SELECT
				Id,
				AccountAddress__c,
				CreatedDate,
				DueDate__c,
				IsCancel__c,
				CancelReason__c,
				LastIntegrationDateTime__c,
				LastCreatedStatusInPojjaman__c,
				LastCancelledStatusInPojjaman__c,
				Opportunity__c,
				ReceiptNo__c,
				ResponseCode__c,
				ResponseMessage__c,
				TotalReceiveAmount__c,
				GLKey__c,
				GLDate__c,
				Opportunity__r.Account.AccountCode__c,
				Opportunity__r.Project__r.ProjectCode__c,
				CoBuyerAccountCode__c,
				ReceiptType__c,
				(
					SELECT
						Id,
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
						OpportunityPayment__r.Order__c,
						TransactionDateTime__c,
						PaymentReceipt__r.TotalReceiveAmount__c,
						PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode,
						ResponseCode__c,
						ResponseMessage__c,
						LastIntegrationDateTime__c,
						ReceiptLineItemType__c
					FROM Payment_Transactions__r
					ORDER BY OpportunityPayment__r.Order__c, Name
				),
				(
					SELECT
						Id,
						PaymentType__c,
						CreditCardNo__c,
						DebitCardNo__c,
						ChequeNo__c,
						BankBranch__c,
						BankName__c,
						BankAccountNo__c,
						CompanyBank__r.BankAccountNumber__c,
						PaymentDate__c,
						ReceivedAmount__c,
						InternationalBankName__c,
						ResponseCode__c,
						ResponseMessage__c,
						LastIntegrationDateTime__c
					FROM PaymentMethods__r
				)
			FROM PaymentReceipt__c
			WHERE (LastModifiedDate = TODAY
			OR LastCreatedStatusInPojjaman__c = null
			OR LastCreatedStatusInPojjaman__c = 'Fail'
			OR LastCancelledStatusInPojjaman__c = 'Fail')
			ORDER BY CreatedDate ASC
		];
		CreateReceiptApiCallout callout = new CreateReceiptApiCallout(paymentReceipts);
		Object request = callout.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(null, request);
		System.assertEquals(paymentReceipts.size() * 2, requestModels.size());
		// for (Integer i = 0; i < requestModels.size(); i++){
		// 	PojjamanDataModel.FNGLDocRequest requestDataModel = requestModels[i];
		// 	PaymentReceipt__c receipt = paymentReceipts[i];
		// 	System.assertEquals(receipt.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
		// 	System.assertEquals(null, requestDataModel.PreviousCustomerCode);
		// 	System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
		// 	System.assertEquals(receipt.Id, requestDataModel.SFDocId);
		// 	System.assertEquals(receipt.CreatedDate.date(), requestDataModel.DocDate);
		// 	System.assertEquals('RP', requestDataModel.DocType);
		// 	System.assertEquals(receipt.ReceiptNo__c, requestDataModel.ReceiptCode);
		// 	System.assertEquals(null, requestDataModel.InvoiceCode);
		// 	System.assertEquals(0, requestDataModel.Indicator);
		// 	System.assertEquals(null, requestDataModel.GroupKey);
		// 	System.assertEquals(null, requestDataModel.GLDate);
		// 	System.assertEquals(null, requestDataModel.Remark);
		// 	System.assertEquals(receipt.CoBuyerAccountCode__c.split(','), requestDataModel.CoBuyerCustomerCode);
		// }
	}
}