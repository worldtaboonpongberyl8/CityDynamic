@isTest
public class GLChangeUnitApiCalloutTest {
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
		Invoice__c invoice2 = dataMaker.createInvoice(opp1.Id, Date.newInstance(2024, 11, 6), Date.newInstance(2024, 11, 1), true, 'Address');
		invoice2.InvoiceNo__c = '2222';
		List<Invoice__c> invoices = new List<Invoice__c>{ invoice , invoice2};
		insert invoices;
		// Create Invoice Line Item
		InvoiceLineItem__c invoiceLineItem1 = dataMaker.createInvoiceLineItem(invoice.Id,contractOppPayment.Id,100000,Date.newInstance(2024, 12, 1),'');
		InvoiceLineItem__c invoiceLineItem2 = dataMaker.createInvoiceLineItem(invoice2.Id,installment1OppPayment.Id,8000,Date.newInstance(2025, 1 , 1),'');
		List<InvoiceLineItem__c> invoiceLineItems = new List<InvoiceLineItem__c>{ invoiceLineItem1,invoiceLineItem2 };
		insert invoiceLineItems;
		// Create Receipt
		PaymentReceipt__c receipt = dataMaker.craeteReceipt(opp1.Id , Date.newInstance(2024, 10, 10));
		receipt.CancelReason__c = GlobalConstants.RECEIPT_LOST_REASON_NOVATION;
		PaymentReceipt__c receipt2 = dataMaker.craeteReceipt(opp1.Id , Date.newInstance(2024, 10, 10));
		receipt2.CancelReason__c = GlobalConstants.RECEIPT_LOST_REASON_NOVATION;
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
		opp1.StageName = GlobalConstants.OPP_STAGENAME_CLOSED_LOST;
		opp1.LossReason__c = GlobalConstants.OPP_LOST_REASON_DOWNGRADE;
		update opp1;
		oppTriggerHandler.clearBypass();
	}

	@isTest
	static void buildRequestDataModelTest(){
		List<Opportunity> opportunities = [
			SELECT
				Id,
				LastGLStatusInPojjaman__c,
				LastIntegrationDateTime__c,
				(
					SELECT Id, LastGLStatusInPojjaman__c
					FROM Invoices__r
					ORDER BY CreatedDate ASC
				),
				(
					SELECT 	Id,
							IsCancel__c,
							CancelReason__c,
							LastGLStatusInPojjaman__c
					FROM PaymentReceipt__r
					ORDER BY CreatedDate ASC
				)
			FROM Opportunity
			WHERE (
					StageName =: GlobalConstants.OPP_STAGENAME_CLOSED_LOST AND
					(LossReason__c =: GlobalConstants.OPP_LOST_REASON_UPGRADE OR
					LossReason__c =: GlobalConstants.OPP_LOST_REASON_DOWNGRADE OR
					LossReason__c =: GlobalConstants.OPP_LOST_REASON_PURCHASEOTHERNAME OR
					LossReason__c =: GlobalConstants.OPP_LOST_REASON_MOVEPAYMENT ) AND
					(LastGLStatusInPojjaman__c = null OR LastGLStatusInPojjaman__c = 'Fail')
				)
			ORDER BY LastModifiedDate ASC
		];
		System.assertEquals(1, opportunities.size());
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		InvoiceSelector invoiceSelector = InvoiceSelector.getInstance();
		Set<Id> receiptIds = new Set<Id>();
		Set<Id> invoiceIds = new Set<Id>();
		for (Opportunity opportunity : opportunities) {
			List<Invoice__c> invoices = opportunity.Invoices__r;
			for (Invoice__c invoice : invoices) {
				invoiceIds.add(invoice.Id);
			}
			List<PaymentReceipt__c> paymentReceipts = opportunity.PaymentReceipt__r;
			for (PaymentReceipt__c paymentReceipt : paymentReceipts) {
				receiptIds.add(paymentReceipt.Id);
			}
		}
		Map<Id, Invoice__c> invoiceWithInvoiceLineItemsMapById = invoiceSelector.getInvoiceWithInvoiceLineItemsMapById(
			invoiceIds
		);
		List<Invoice__c> remainedInvoice = new List<Invoice__c>();
		for(Invoice__c invoice: invoiceWithInvoiceLineItemsMapById.values()){
			InvoiceLineItem__c invoiceLineItem = invoice.InvoiceLineItems__r[0];
			if (invoiceLineItem.OpportunityPayment__r.Remaining__c > 0){
				remainedInvoice.add(invoice);
			}
		}
		Map<Id, PaymentReceipt__c> receiptWithReceiptLineItemsMapById = receiptSelector.getPaymentReceiptWithLineItemMapById(
			receiptIds
		);
		GLChangeUnitApiCallout callout = new GLChangeUnitApiCallout(opportunities);
		Object request = callout.buildRequestDataModel();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(null, request);
		System.assertEquals(remainedInvoice.size() + receiptWithReceiptLineItemsMapById.values().size(), requestModels.size());
		List<PojjamanDataModel.FNGLDocRequest> invoiceRequestModels = new List<PojjamanDataModel.FNGLDocRequest>();
		List<PojjamanDataModel.FNGLDocRequest> receiptRequestModels = new List<PojjamanDataModel.FNGLDocRequest>();
		for(PojjamanDataModel.FNGLDocRequest requestModel : requestModels ){
			if (requestModel.InvoiceCode != null){
				invoiceRequestModels.add(requestModel);
			} else {
				receiptRequestModels.add(requestModel);
			}
		}
		System.assertEquals(remainedInvoice.size(), invoiceRequestModels.size());
		System.assertEquals(receiptWithReceiptLineItemsMapById.values().size(), receiptRequestModels.size());
		// ----- Check Invoice -----
		for (Integer invoiceIdx = 0 ; invoiceIdx < invoiceRequestModels.size(); invoiceIdx ++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = invoiceRequestModels[invoiceIdx];
			Invoice__c invoice = remainedInvoice[invoiceIdx];
			System.assertNotEquals(null, requestDataModel.CustomerCode);
			System.assertEquals(invoice.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(invoice.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(invoice.Id, requestDataModel.SFDocId);
			System.assertEquals(invoice.CreatedDate.date(), requestDataModel.DocDate);
			System.assertEquals('GL', requestDataModel.DocType);
			System.assertEquals(null, requestDataModel.ReceiptCode);
			System.assertEquals(invoice.InvoiceNo__c, requestDataModel.InvoiceCode);
			System.assertEquals(2, requestDataModel.Indicator);
			System.assertEquals(invoice.GLKey__c, requestDataModel.GroupKey);
			System.assertEquals(invoice.GLDate__c, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(null, requestDataModel.CoBuyerCustomerCode);
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = requestDataModel.DocLine;
			List<InvoiceLineItem__c> invoiceLineItems = invoice.InvoiceLineItems__r;
			System.assertEquals(invoiceLineItems.size(), docLines.size());
			for (Integer invoiceLineIdx = 0; invoiceLineIdx < docLines.size() ; invoiceLineIdx++){
				PojjamanDataModel.FNGLDocLineRequest docLine = docLines[invoiceLineIdx];
				InvoiceLineItem__c invoiceLineItem = invoiceLineItems[invoiceLineIdx];
				System.assertEquals(Integer.valueOf(invoiceLineItem.LineNumber__c), docLine.LineNumber);
				System.assertEquals(invoiceLineItem.Invoice__r.Opportunity__r.Unit__r.ProductCode , docLine.UnitCode);
				System.assertEquals(invoiceLineItem.Term__c , docLine.Type);
				System.assertEquals(invoiceLineItem.Amount__c , docLine.Amount);
				System.assertEquals(null , docLine.IsDebit);
				System.assertEquals(invoiceLineItem.Id , docLine.SFDocLineId);
				System.assertEquals(invoiceLineItem.Status__c , docLine.Status);
				System.assertEquals(invoiceLineItem.DueDate__c , docLine.DueDate);
				System.assertEquals(null, docLine.RefInvoiceId);
			}
			System.assertEquals(null, requestDataModel.PaymentMethod);
		}
		// ----- Check Receipt -----
		for (Integer receiptIdx = 0 ; receiptIdx < receiptRequestModels.size(); receiptIdx ++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = receiptRequestModels[receiptIdx];
			PaymentReceipt__c receipt = receiptWithReceiptLineItemsMapById.values()[receiptIdx];
			System.assertNotEquals(null, requestDataModel.CustomerCode);
			System.assertEquals(receipt.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(receipt.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(receipt.Id, requestDataModel.SFDocId);
			System.assertEquals(receipt.CreatedDate.date(), requestDataModel.DocDate);
			System.assertEquals('GL', requestDataModel.DocType);
			System.assertEquals(receipt.ReceiptNo__c, requestDataModel.ReceiptCode);
			System.assertEquals(null, requestDataModel.InvoiceCode);
			System.assertEquals(4, requestDataModel.Indicator);
			System.assertEquals(receipt.GLKey__c, requestDataModel.GroupKey);
			System.assertEquals(receipt.GLDate__c, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(null, requestDataModel.CoBuyerCustomerCode);
			List<PojjamanDataModel.FNGLDocLineRequest> docLines = requestDataModel.DocLine;
			List<PaymentReceiptLineItem__c> receiptItems = receipt.Payment_Transactions__r;
			System.assertEquals(receiptItems.size(), docLines.size());
			for (Integer receiptLineIdx = 0; receiptLineIdx < docLines.size() ; receiptLineIdx++){
				PojjamanDataModel.FNGLDocLineRequest docLine = docLines[receiptLineIdx];
				PaymentReceiptLineItem__c receiptLineItem = receiptItems[receiptLineIdx];
				System.assertEquals(receiptLineIdx + 1, docLine.LineNumber);
				System.assertEquals(receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode , docLine.UnitCode);
				System.assertEquals(receiptLineItem.OpportunityPayment__r.Term__c , docLine.Type);
				System.assertEquals(receiptLineItem.ReceivedAmount__c , docLine.Amount);
				System.assertEquals(true , docLine.IsDebit);
				System.assertEquals(receiptLineItem.Id , docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Status__c , docLine.Status);
				System.assertEquals(null , docLine.DueDate);
				System.assertEquals(receiptLineItem.InvoiceLineItem__r.Invoice__c, docLine.RefInvoiceId);
			}
			System.assertEquals(null, requestDataModel.PaymentMethod);
		}

	}
}