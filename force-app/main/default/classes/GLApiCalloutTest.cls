@isTest
public class GLApiCalloutTest {
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
			'Available',
			unitType.Id
		);
		testProduct.ReservationPrice__c = 10000;
		// testProduct.TransferredDate__c = Date.today();
		Product2 testProduct2 = dataMaker.createUnit(
			'Test Product 2',
			'UN02',
			testProject.Id,
			testFloor.Id,
			'Available',
			unitType.Id
		);
		testProduct2.ReservationPrice__c = 10000;
		// testProduct2.TransferredDate__c = Date.today();
		List<Product2> products = new List<Product2>{testProduct,testProduct2};
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
		// Create Pricebook Entry
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 15000000, 20000000,10000000);
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
		targetAccount.AccountCode__c = '1111';
		Account targetAccount2 = dataMaker.createAccount(recordTypeId, 'Test Account 2');
		targetAccount2.AccountCode__c = '2222';
		Account targetAccount3 = dataMaker.createAccount(recordTypeId, 'Test Account 3');
		targetAccount3.AccountCode__c = '3333';
		Account targetAccount4 = dataMaker.createAccount(recordTypeId, 'Test Account 4');
		targetAccount4.AccountCode__c = '4444';
		List<Account> accounts = new List<Account>{targetAccount,targetAccount2,targetAccount3,targetAccount4};
		insert accounts;
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
		// opp1.TotalOperationFee__c = 5000;
		// opp1.NetAgreedForfeitAmount__c = 10000;
		Opportunity opp2 = dataMaker.createOpportunity(
			targetAccount2.Id,
			'Omitted',
			'Test Opp',
			Date.today(),
			'Open',
			testProduct2.Id,
			'Foreign',
			paymentTermMaster.Id,
			testProject.Id
		);
		// opp2.TotalOperationFee__c = 2000;
		// opp2.NetAgreedForfeitAmount__c = 4000;
		List<Opportunity> opportunities = new List<Opportunity>{ opp1 , opp2 };
		insert opportunities;
		oppTriggerHandler.clearBypass();
		// Create Opp Payments
		OpportunityPayment__c reservationOppPayment = dataMaker.createOpportunityPayment(
			opp1.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		reservationOppPayment.ReceivedAmount__c = 45000;
		OpportunityPayment__c reservationOppPayment2 = dataMaker.createOpportunityPayment(
			opp2.Id,
			'Reservation',
			50000,
			Date.newInstance(2024, 10, 15),
			1
		);
		reservationOppPayment2.ReceivedAmount__c = 45000;
		List<OpportunityPayment__c> oppPayments = new List<OpportunityPayment__c>{
			reservationOppPayment,reservationOppPayment2
		};
		insert oppPayments;
		Opportunity updatedOpp1 = [SELECT Id FROM Opportunity WHERE Id =: opp1.Id];
		updatedOpp1.TotalOperationFee__c = 5000;
		updatedOpp1.NetAgreedForfeitAmount__c = 2000;
		Opportunity updatedOpp2 = [SELECT Id FROM Opportunity WHERE Id =: opp2.Id];
		updatedOpp2.TotalOperationFee__c = 5000;
		updatedOpp2.NetAgreedForfeitAmount__c = 1000;
		List<Opportunity> updatedOpps = new List<Opportunity>{updatedOpp1,updatedOpp2};
		update updatedOpps;
		// Create Invoice
		Invoice__c invoice = dataMaker.createInvoice(opp1.Id, Date.newInstance(2024, 10, 6), Date.newInstance(2024, 10, 1), true, 'Address');
		Invoice__c invoice2 = dataMaker.createInvoice(opp2.Id, Date.newInstance(2024, 11, 6), Date.newInstance(2024, 11, 1), true, 'Address');
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice , invoice2};
		insert invoices;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(invoice.Id,reservationOppPayment.Id,100000,Date.newInstance(2024, 12, 1),'');
		InvoiceLineItem__c invoiceLineItem2 = dataMaker.createInvoiceLineItem(invoice2.Id,reservationOppPayment2.Id,8000,Date.newInstance(2025, 1 , 1),'');
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1,invoiceLineItem2 };
		insert invoiceLineItems;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opp1.Id , Date.newInstance(2024, 10, 10));
		receipt.CustomGLKey__c = 'TestKey1';
		receipt.CustomGLDate__c = Date.today();
		PaymentReceipt__c receipt2 = dataMaker.craeteReceipt(opp2.Id , Date.newInstance(2024, 10, 10));
		receipt2.CustomGLKey__c = 'TestKey2';
		receipt2.CustomGLDate__c = Date.today();
		PaymentReceipt__c refundReceipt = dataMaker.craeteReceipt(opp1.Id , Date.newInstance(2024, 10, 10));
		refundReceipt.ReceiptType__c = GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT;
		PaymentReceipt__c forfeitReceipt = dataMaker.craeteReceipt(opp1.Id , Date.newInstance(2024, 10, 10));
		forfeitReceipt.ReceiptType__c = GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT;
		PaymentReceipt__c operationReceipt = dataMaker.craeteReceipt(opp1.Id , Date.newInstance(2024, 10, 10));
		operationReceipt.ReceiptType__c = GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT;
		PaymentReceipt__c refundReceipt2 = dataMaker.craeteReceipt(opp2.Id , Date.newInstance(2024, 10, 10));
		refundReceipt2.ReceiptType__c = GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT;
		PaymentReceipt__c forfeitReceipt2 = dataMaker.craeteReceipt(opp2.Id , Date.newInstance(2024, 10, 10));
		forfeitReceipt2.ReceiptType__c = GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT;
		PaymentReceipt__c operationReceipt2 = dataMaker.craeteReceipt(opp2.Id , Date.newInstance(2024, 10, 10));
		operationReceipt2.ReceiptType__c = GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT;
		List<PaymentReceipt__c> receipts = new List<PaymentReceipt__c>{receipt,receipt2,refundReceipt,forfeitReceipt,operationReceipt,refundReceipt2,forfeitReceipt2,operationReceipt2};
		insert receipts;
		// Create Receipt Line Item
		PaymentReceiptLineItem__c receiptItemReservation = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment.Id,null,50000,'Fully Paid');
		PaymentReceiptLineItem__c receiptItemReservation2 = dataMaker.createReceiptLineItem(receipt.Id,reservationOppPayment2.Id,null,50000,'Fully Paid');
		PaymentReceiptLineItem__c refundReceiptItem = dataMaker.createReceiptLineItem(refundReceipt.Id,null,null,10000,'Fully Paid');
		PaymentReceiptLineItem__c forfeitReceiptItem = dataMaker.createReceiptLineItem(forfeitReceipt.Id,null,null,20000,'Fully Paid');
		PaymentReceiptLineItem__c operationReceiptItem = dataMaker.createReceiptLineItem(operationReceipt.Id,null,null,30000,'Fully Paid');
		PaymentReceiptLineItem__c refundReceiptItem2 = dataMaker.createReceiptLineItem(refundReceipt2.Id,null,null,40000,'Fully Paid');
		PaymentReceiptLineItem__c forfeitReceiptItem2 = dataMaker.createReceiptLineItem(forfeitReceipt2.Id,null,null,50000,'Fully Paid');
		PaymentReceiptLineItem__c operationReceiptItem2 = dataMaker.createReceiptLineItem(operationReceipt2.Id,null,null,60000,'Fully Paid');
		List<PaymentReceiptLineItem__c> receiptItems = new List<PaymentReceiptLineItem__c>{ receiptItemReservation , receiptItemReservation2,refundReceiptItem,forfeitReceiptItem,operationReceiptItem,refundReceiptItem2,forfeitReceiptItem2,operationReceiptItem2};
		insert receiptItems;
		// Create Payment Method
		PaymentMethod__c receiptMethod = dataMaker.createPaymentMethod(receipt.Id,'KBANK',Decimal.valueOf(1000000),'Cash','Reservation',Date.today());
		PaymentMethod__c receiptMethod2 = dataMaker.createPaymentMethod(receipt2.Id,'KBANK',Decimal.valueOf(1000000),'Cash','Reservation',Date.today());
		List<PaymentMethod__c> receiptMethods = new List<PaymentMethod__c>{receiptMethod,receiptMethod2};
		insert receiptMethods;
	}

	@isTest
	static void buildRequestDataModelTest(){
		List<Opportunity> closedOpportunities = [SELECT Id FROM Opportunity];
		for (Opportunity opp : closedOpportunities){
			opp.StageName = GlobalConstants.OPP_STAGENAME_CLOSED_LOST;
			opp.LossReason__c = GlobalConstants.OPP_LOST_REASON_CANCELREFUND;
		}
		update closedOpportunities;
		List<Opportunity> opportunities = [
			SELECT
				Id,
				LastGLStatusInPojjaman__c,
				TotalOperationFee__c,
				NetAgreedRefundAmount__c,
				NetAgreedForfeitAmount__c,
				(
					SELECT Id, LastGLStatusInPojjaman__c
					FROM Invoices__r
					ORDER BY CreatedDate ASC
				),
				(
					SELECT Id,
					IsCancel__c,
					CancelReason__c, LastGLStatusInPojjaman__c
					FROM PaymentReceipt__r
					WHERE
					CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_CANCELREFUND OR
					CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_CANCELFORFEIT OR
					CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONREFUND OR
					CancelReason__c =: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONFORFEIT
					ORDER BY CreatedDate ASC
				)
			FROM Opportunity
			WHERE StageName =: GlobalConstants.OPP_STAGENAME_CLOSED_LOST AND (LastGLStatusInPojjaman__c = 'Fail' OR LastGLStatusInPojjaman__c = null)
			ORDER BY LastModifiedDate ASC
		];
		List<PaymentReceipt__c> operationReceipts = [SELECT Id FROM PaymentReceipt__c WHERE ReceiptType__c =: GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT];
		GLApiCallout callout = new GLApiCallout(opportunities);
		Object request = callout.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		Set<Id> receiptIds = new Set<Id>();
		Set<Id> invoiceIds = new Set<Id>();
		Set<Id> oppIds = new Set<Id>();
		for (Opportunity opportunity : opportunities) {
			oppIds.add(opportunity.Id);
			List<PaymentReceipt__c> paymentReceipts = opportunity.PaymentReceipt__r;
			for (PaymentReceipt__c paymentReceipt : paymentReceipts) {
				if (
					paymentReceipt.IsCancel__c &&
					(paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_CANCELREFUND ||
					paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_CANCELFORFEIT ||
					paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONREFUND ||
					paymentReceipt.CancelReason__c == GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONFORFEIT) &&
					(paymentReceipt.LastGLStatusInPojjaman__c == null ||
					paymentReceipt.LastGLStatusInPojjaman__c == 'Fail')
				) {
					receiptIds.add(paymentReceipt.Id);
				}
			}
			List<Invoice__c> invoices = opportunity.Invoices__r;
			for (Invoice__c invoice : invoices) {
				if (invoice.LastGLStatusInPojjaman__c == null || invoice.LastGLStatusInPojjaman__c == 'Fail') {
					invoiceIds.add(invoice.Id);
				}
			}
		}
		Map<Id, Invoice__c> invoiceWithInvoiceLineItemsMapById = invoiceSelector.getInvoiceWithInvoiceLineItemsMapById(
			invoiceIds
		);
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			receiptIds
		);
		System.debug('SIZE invoiceWithInvoiceLineItemsMapByIdSize: ' + invoiceWithInvoiceLineItemsMapById.values().size());
		System.debug('SIZE receiptWithReceiptLineItemsMapById: ' + receiptWithReceiptLineItemsMapById.values().size());
		System.debug('SIZE receiptWithReceiptLioperationReceiptsneItemsMapById: ' + operationReceipts.size());
		for (PojjamanDataModel.FNGLDocRequest requestModel : requestModels) {
			System.debug('REQUEST: ' + requestModel.SFDocId);
		}
		System.assertEquals(10 , requestModels.size());
	}
}