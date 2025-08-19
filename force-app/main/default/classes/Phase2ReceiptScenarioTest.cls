@isTest
public with sharing class Phase2ReceiptScenarioTest {
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
	}

    @isTest
	static void paymentGatewayReceiptPositiveTest(){
		PaymentReceiptService receiptService = PaymentReceiptService.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		PaymentReceipt__c paymentGatewayReceipt = receiptService.generatePaymentReceiptRelatedToOpportunity(opportunity.Id);
		paymentGatewayReceipt.ReceiptType__c = GlobalConstants.RECEIPT_TYPE_PAYMENTGATEWAY;
		insert paymentGatewayReceipt;
		PaymentMethod__c paymentMethod = new PaymentMethod__c(
																	PaymentReceipt__c = paymentGatewayReceipt.Id,
																	PaymentDate__c = Date.today(),
																	ReceivedAmount__c = 100000
															);
		insert paymentMethod;
		List<OpportunityPayment__c> oppPayments = [SELECT Id,Remaining__c FROM OpportunityPayment__c WHERE Opportunity__c = :opportunity.Id];
		List<PaymentReceiptLineItem__c> receiptLineItems = receiptService.generatePaymentReceiptLineItemFromTotalReceivedAmount(100000,oppPayments,paymentGatewayReceipt.Id,paymentMethod.Id);
		insert receiptLineItems;
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
			AND Id =: paymentGatewayReceipt.Id
			ORDER BY CreatedDate ASC
		];
		CreateReceiptApiCallout callout = new CreateReceiptApiCallout(paymentReceipts);
		Test.startTest();
			Object request = callout.buildRequestDataModel();
		Test.stopTest();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(0, requestModels.size());
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
			System.assertEquals('Received via Payment Gateway', requestDataModel.Remark);
			System.assertEquals(null, requestDataModel.CoBuyerCustomerCode);
			List<PaymentReceiptLineItem__c> targetReceiptLineItems = receipt.Payment_Transactions__r;
			List<PojjamanDataModel.FNGLDocLineRequest> requestLineModels = requestDataModel.DocLine;
			System.assertEquals(targetReceiptLineItems.size(), requestLineModels.size());
			for (Integer j = 0; j < receiptLineItems.size(); j++){
				PojjamanDataModel.FNGLDocLineRequest docLine = requestLineModels[j];
				PaymentReceiptLineItem__c receiptLineItem = targetReceiptLineItems[j];
				System.assertEquals(1, docLine.LineNumber);
				System.assertEquals(receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode, docLine.UnitCode);
				System.assertEquals(receiptLineItem.OpportunityPayment__r.Term__c, docLine.Type);
				System.assertEquals(receiptLineItem.ReceivedAmount__c, docLine.Amount);
				System.assertEquals(null, docLine.IsDebit);
				System.assertEquals(receiptLineItem.Id, docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Status__c, docLine.Status);
				System.assertEquals(null, docLine.DueDate);
				System.assertEquals(null, docLine.RefInvoiceId);
			}
		}

	}

	@isTest
	static void recurringReceiptPositiveTest(){
		PaymentReceiptService receiptService = PaymentReceiptService.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		PaymentReceipt__c paymentGatewayReceipt = receiptService.generatePaymentReceiptRelatedToOpportunity(opportunity.Id);
		paymentGatewayReceipt.ReceiptType__c = GlobalConstants.RECEIPT_TYPE_RECURRING;
		insert paymentGatewayReceipt;
		PaymentMethod__c paymentMethod = new PaymentMethod__c(
																	PaymentReceipt__c = paymentGatewayReceipt.Id,
																	PaymentDate__c = Date.today(),
																	ReceivedAmount__c = 100000
															);
		insert paymentMethod;
		List<OpportunityPayment__c> oppPayments = [SELECT Id,Remaining__c FROM OpportunityPayment__c WHERE Opportunity__c = :opportunity.Id];
		List<PaymentReceiptLineItem__c> receiptLineItems = receiptService.generatePaymentReceiptLineItemFromTotalReceivedAmount(100000,oppPayments,paymentGatewayReceipt.Id,paymentMethod.Id);
		insert receiptLineItems;
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
			AND Id =: paymentGatewayReceipt.Id
			ORDER BY CreatedDate ASC
		];
		CreateReceiptApiCallout callout = new CreateReceiptApiCallout(paymentReceipts);
		Test.startTest();
			Object request = callout.buildRequestDataModel();
		Test.stopTest();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(0, requestModels.size());
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
			System.assertEquals('Received via Recurring Credit Card Transaction', requestDataModel.Remark);
			System.assertEquals(null, requestDataModel.CoBuyerCustomerCode);
			List<PaymentReceiptLineItem__c> targetReceiptLineItems = receipt.Payment_Transactions__r;
			List<PojjamanDataModel.FNGLDocLineRequest> requestLineModels = requestDataModel.DocLine;
			for (Integer j = 0; j < receiptLineItems.size(); j++){
				PojjamanDataModel.FNGLDocLineRequest docLine = requestLineModels[j];
				PaymentReceiptLineItem__c receiptLineItem = targetReceiptLineItems[j];
				System.assertEquals(1, docLine.LineNumber);
				System.assertEquals(receiptLineItem.PaymentReceipt__r.Opportunity__r.Unit__r.ProductCode, docLine.UnitCode);
				System.assertEquals(receiptLineItem.OpportunityPayment__r.Term__c, docLine.Type);
				System.assertEquals(receiptLineItem.ReceivedAmount__c, docLine.Amount);
				System.assertEquals(null, docLine.IsDebit);
				System.assertEquals(receiptLineItem.Id, docLine.SFDocLineId);
				System.assertEquals(receiptLineItem.Status__c, docLine.Status);
				System.assertEquals(null, docLine.DueDate);
				System.assertEquals(null, docLine.RefInvoiceId);
			}
		}

	}

	@isTest
	static void invoiceWithCoBuyerTest(){
		DataMaker dataMaker = DataMaker.getInstance();
		InvoiceService invoiceService = invoiceService.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		Id recordTypeId = Schema.getGlobalDescribe()
		.get('Account')
		.getDescribe()
		.getRecordTypeInfosByName()
		.get('Co-Owner - Corporate')
		.getRecordTypeId();
		Account accountToBeCoBuyer = dataMaker.createAccount(recordTypeId, 'Cobuyer Account 1');
		accountToBeCoBuyer.AccountCode__c = '0001';
		Account accountToBeCoBuyer2 = dataMaker.createAccount(recordTypeId, 'Cobuyer Account 2');
		accountToBeCoBuyer2.AccountCode__c = '0002';
		List<Account> accountsToBeCoBuyer = new List<Account>{accountToBeCoBuyer, accountToBeCoBuyer2};
		insert accountsToBeCoBuyer;
		CoBuyer__c targetCoBuyer = dataMaker.createCoBuyer(opportunity.Id,accountToBeCoBuyer.Id , '1');
		CoBuyer__c targetCoBuyer2 = dataMaker.createCoBuyer(opportunity.Id,accountToBeCoBuyer2.Id , '2');
		List<CoBuyer__c> coBuyers = new List<CoBuyer__c>{targetCoBuyer,targetCoBuyer2};
		insert coBuyers;
		Date invoiceDate = Date.today();
		invoiceService.createInvoiceAndLineItem(opportunity.Id, invoiceDate, invoiceDate.addDays(15), 'Contract');
		List<Invoice__c> invoices = [
			SELECT
				Id,
				Opportunity__r.Account.AccountCode__c,
				Opportunity__r.Project__r.ProjectCode__c,
				CreatedDate,
				InvoiceNo__c,
				GLKey__c,
				ResponseCode__c,
				ResponseMessage__c,
				LastIntegrationDateTime__c,
				LastCreatedStatusInPojjaman__c,
				LastGLStatusInPojjaman__c,
				CoBuyerAccountCode__c,
				(
					SELECT
						Id,
						Invoice__r.Opportunity__r.Unit__r.ProductCode,
						OpportunityPayment__r.Remaining__c,
						Term__c,
						Amount__c,
						Status__c,
						DueDate__c,
						ResponseCode__c,
						ResponseMessage__c,
						LastIntegrationDateTime__c
					FROM InvoiceLineItems__r
				)
			FROM Invoice__c
		];
		System.assertEquals(1, invoices.size());
		CreateInvoiceApiCallout callout = new CreateInvoiceApiCallout(invoices);
		Test.startTest();
			Object request = callout.buildRequestDataModel();
		Test.stopTest();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(0, requestModels.size());
		System.assertNotEquals(null, request);
		System.assertEquals(invoices.size(), requestModels.size());
		for (Integer i = 0; i < invoices.size(); i++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = requestModels[i];
			Invoice__c invoice = invoices[i];
			System.assertEquals(invoice.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(invoice.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(invoice.Id, requestDataModel.SFDocId);
			System.assertEquals(invoice.CreatedDate.date(), requestDataModel.DocDate);
			System.assertEquals('IV', requestDataModel.DocType);
			System.assertEquals(invoice.InvoiceNo__c, requestDataModel.InvoiceCode);
			System.assertEquals(null, requestDataModel.ReceiptCode);
			System.assertEquals(0, requestDataModel.Indicator);
			System.assertEquals(null, requestDataModel.GroupKey);
			System.assertEquals(null, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(new List<String>{'0001','0002'}, requestDataModel.CoBuyerCustomerCode);
			List<InvoiceLineItem__c> targetInvoiceLineItems = invoice.InvoiceLineItems__r;
			List<PojjamanDataModel.FNGLDocLineRequest> requestLineModels = requestDataModel.DocLine;
			for (Integer j = 0; j < targetInvoiceLineItems.size(); j++){
				PojjamanDataModel.FNGLDocLineRequest docLine = requestLineModels[j];
				InvoiceLineItem__c invoiceLineItem = targetInvoiceLineItems[j];
				System.assertEquals(1, docLine.LineNumber);
				System.assertEquals(invoiceLineItem.Invoice__r.Opportunity__r.Unit__r.ProductCode, docLine.UnitCode);
				System.assertEquals(invoiceLineItem.Term__c, docLine.Type);
				System.assertEquals(invoiceLineItem.Amount__c, docLine.Amount);
				System.assertEquals(null, docLine.IsDebit);
				System.assertEquals(invoiceLineItem.Id, docLine.SFDocLineId);
				System.assertEquals(invoiceLineItem.Status__c, docLine.Status);
				System.assertEquals(invoiceLineItem.DueDate__c, docLine.DueDate);
				System.assertEquals(null, docLine.RefInvoiceId);
			}
		}
	}

	@isTest
	static void invoiceWithCoBuyerNegativeTest(){
		DataMaker dataMaker = DataMaker.getInstance();
		InvoiceService invoiceService = invoiceService.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		Id recordTypeId = Schema.getGlobalDescribe()
		.get('Account')
		.getDescribe()
		.getRecordTypeInfosByName()
		.get('Co-Owner - Corporate')
		.getRecordTypeId();
		Account accountToBeCoBuyer = dataMaker.createAccount(recordTypeId, 'Cobuyer Account 1');
		accountToBeCoBuyer.AccountCode__c = '0001';
		Account accountToBeCoBuyer2 = dataMaker.createAccount(recordTypeId, 'Cobuyer Account 2');
		accountToBeCoBuyer2.AccountCode__c = null;
		List<Account> accountsToBeCoBuyer = new List<Account>{accountToBeCoBuyer, accountToBeCoBuyer2};
		insert accountsToBeCoBuyer;
		CoBuyer__c targetCoBuyer = dataMaker.createCoBuyer(opportunity.Id,accountToBeCoBuyer.Id , '1');
		CoBuyer__c targetCoBuyer2 = dataMaker.createCoBuyer(opportunity.Id,accountToBeCoBuyer2.Id , '2');
		List<CoBuyer__c> coBuyers = new List<CoBuyer__c>{targetCoBuyer,targetCoBuyer2};
		insert coBuyers;
		Date invoiceDate = Date.today();
		invoiceService.createInvoiceAndLineItem(opportunity.Id, invoiceDate, invoiceDate.addDays(15), 'Contract');
		List<Invoice__c> invoices = [
			SELECT
				Id,
				Opportunity__r.Account.AccountCode__c,
				Opportunity__r.Project__r.ProjectCode__c,
				CreatedDate,
				InvoiceNo__c,
				GLKey__c,
				ResponseCode__c,
				ResponseMessage__c,
				LastIntegrationDateTime__c,
				LastCreatedStatusInPojjaman__c,
				LastGLStatusInPojjaman__c,
				CoBuyerAccountCode__c,
				(
					SELECT
						Id,
						Invoice__r.Opportunity__r.Unit__r.ProductCode,
						OpportunityPayment__r.Remaining__c,
						Term__c,
						Amount__c,
						Status__c,
						DueDate__c,
						ResponseCode__c,
						ResponseMessage__c,
						LastIntegrationDateTime__c
					FROM InvoiceLineItems__r
				)
			FROM Invoice__c
		];
		System.assertEquals(1, invoices.size());
		CreateInvoiceApiCallout callout = new CreateInvoiceApiCallout(invoices);
		Test.startTest();
			Object request = callout.buildRequestDataModel();
		Test.stopTest();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(0, requestModels.size());
		System.assertNotEquals(null, request);
		System.assertEquals(invoices.size(), requestModels.size());
		for (Integer i = 0; i < invoices.size(); i++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = requestModels[i];
			Invoice__c invoice = invoices[i];
			System.assertEquals(invoice.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(invoice.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(invoice.Id, requestDataModel.SFDocId);
			System.assertEquals(invoice.CreatedDate.date(), requestDataModel.DocDate);
			System.assertEquals('IV', requestDataModel.DocType);
			System.assertEquals(invoice.InvoiceNo__c, requestDataModel.InvoiceCode);
			System.assertEquals(null, requestDataModel.ReceiptCode);
			System.assertEquals(0, requestDataModel.Indicator);
			System.assertEquals(null, requestDataModel.GroupKey);
			System.assertEquals(null, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(new List<String>{'0001',''}, requestDataModel.CoBuyerCustomerCode);
			List<InvoiceLineItem__c> targetInvoiceLineItems = invoice.InvoiceLineItems__r;
			List<PojjamanDataModel.FNGLDocLineRequest> requestLineModels = requestDataModel.DocLine;
			for (Integer j = 0; j < targetInvoiceLineItems.size(); j++){
				PojjamanDataModel.FNGLDocLineRequest docLine = requestLineModels[j];
				InvoiceLineItem__c invoiceLineItem = targetInvoiceLineItems[j];
				System.assertEquals(1, docLine.LineNumber);
				System.assertEquals(invoiceLineItem.Invoice__r.Opportunity__r.Unit__r.ProductCode, docLine.UnitCode);
				System.assertEquals(invoiceLineItem.Term__c, docLine.Type);
				System.assertEquals(invoiceLineItem.Amount__c, docLine.Amount);
				System.assertEquals(null, docLine.IsDebit);
				System.assertEquals(invoiceLineItem.Id, docLine.SFDocLineId);
				System.assertEquals(invoiceLineItem.Status__c, docLine.Status);
				System.assertEquals(invoiceLineItem.DueDate__c, docLine.DueDate);
				System.assertEquals(null, docLine.RefInvoiceId);
			}
		}
	}

	@isTest
	static void receiptWithCoBuyerNegativeTest(){
		DataMaker dataMaker = DataMaker.getInstance();
		PaymentReceiptService receiptService = PaymentReceiptService.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		Id recordTypeId = Schema.getGlobalDescribe()
		.get('Account')
		.getDescribe()
		.getRecordTypeInfosByName()
		.get('Co-Owner - Corporate')
		.getRecordTypeId();
		Account accountToBeCoBuyer = dataMaker.createAccount(recordTypeId, 'Cobuyer Account 1');
		accountToBeCoBuyer.AccountCode__c = '0001';
		Account accountToBeCoBuyer2 = dataMaker.createAccount(recordTypeId, 'Cobuyer Account 2');
		accountToBeCoBuyer2.AccountCode__c = null;
		List<Account> accountsToBeCoBuyer = new List<Account>{accountToBeCoBuyer, accountToBeCoBuyer2};
		insert accountsToBeCoBuyer;
		CoBuyer__c targetCoBuyer = dataMaker.createCoBuyer(opportunity.Id,accountToBeCoBuyer.Id , '1');
		CoBuyer__c targetCoBuyer2 = dataMaker.createCoBuyer(opportunity.Id,accountToBeCoBuyer2.Id , '2');
		List<CoBuyer__c> coBuyers = new List<CoBuyer__c>{targetCoBuyer,targetCoBuyer2};
		insert coBuyers;
		Decimal amount = 100000;
		String receiptType = GlobalConstants.RECEIPT_TYPE_DEFAULT;
		String paymentMethodType = 'Credit Card';
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		receiptService.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		List<PaymentReceipt__c> receipts = [
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
			OR LastCancelledStatusInPojjaman__c = 'Fail') AND
			ReceiptType__c !=: GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT AND
			(CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_UPGRADE AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_DOWNGRADE AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_MOVEPAYMENT AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_CANCELREFUND AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONREFUND AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_CANCELFORFEIT AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONFORFEIT)
			ORDER BY CreatedDate ASC
		];
		System.assertEquals(1, receipts.size());
		CreateReceiptApiCallout callout = new CreateReceiptApiCallout(receipts);
		Test.startTest();
			Object request = callout.buildRequestDataModel();
		Test.stopTest();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(0, requestModels.size());
		System.assertNotEquals(null, request);
		System.assertEquals(receipts.size(), requestModels.size());
		for (Integer i = 0; i < receipts.size(); i++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = requestModels[i];
			PaymentReceipt__c receipt = receipts[i];
			System.assertEquals(new List<String>{'0001',''}, requestDataModel.CoBuyerCustomerCode);
		}
	}

	@isTest
	static void invoiceWithCoBuyerNegativeTest2(){
		DataMaker dataMaker = DataMaker.getInstance();
		InvoiceService invoiceService = invoiceService.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		Id recordTypeId = Schema.getGlobalDescribe()
		.get('Account')
		.getDescribe()
		.getRecordTypeInfosByName()
		.get('Co-Owner - Corporate')
		.getRecordTypeId();
		Account accountToBeCoBuyer = dataMaker.createAccount(recordTypeId, 'Cobuyer Account 1');
		accountToBeCoBuyer.AccountCode__c = null;
		Account accountToBeCoBuyer2 = dataMaker.createAccount(recordTypeId, 'Cobuyer Account 2');
		accountToBeCoBuyer2.AccountCode__c = null;
		List<Account> accountsToBeCoBuyer = new List<Account>{accountToBeCoBuyer, accountToBeCoBuyer2};
		insert accountsToBeCoBuyer;
		CoBuyer__c targetCoBuyer = dataMaker.createCoBuyer(opportunity.Id,accountToBeCoBuyer.Id , '1');
		CoBuyer__c targetCoBuyer2 = dataMaker.createCoBuyer(opportunity.Id,accountToBeCoBuyer2.Id , '2');
		List<CoBuyer__c> coBuyers = new List<CoBuyer__c>{targetCoBuyer,targetCoBuyer2};
		insert coBuyers;
		Date invoiceDate = Date.today();
		invoiceService.createInvoiceAndLineItem(opportunity.Id, invoiceDate, invoiceDate.addDays(15), 'Contract');
		List<Invoice__c> invoices = [
			SELECT
				Id,
				Opportunity__r.Account.AccountCode__c,
				Opportunity__r.Project__r.ProjectCode__c,
				CreatedDate,
				InvoiceNo__c,
				GLKey__c,
				ResponseCode__c,
				ResponseMessage__c,
				LastIntegrationDateTime__c,
				LastCreatedStatusInPojjaman__c,
				LastGLStatusInPojjaman__c,
				CoBuyerAccountCode__c,
				(
					SELECT
						Id,
						Invoice__r.Opportunity__r.Unit__r.ProductCode,
						OpportunityPayment__r.Remaining__c,
						Term__c,
						Amount__c,
						Status__c,
						DueDate__c,
						ResponseCode__c,
						ResponseMessage__c,
						LastIntegrationDateTime__c
					FROM InvoiceLineItems__r
				)
			FROM Invoice__c
		];
		System.assertEquals(1, invoices.size());
		CreateInvoiceApiCallout callout = new CreateInvoiceApiCallout(invoices);
		Test.startTest();
			Object request = callout.buildRequestDataModel();
		Test.stopTest();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(0, requestModels.size());
		System.assertNotEquals(null, request);
		System.assertEquals(invoices.size(), requestModels.size());
		for (Integer i = 0; i < invoices.size(); i++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = requestModels[i];
			Invoice__c invoice = invoices[i];
			System.assertEquals(invoice.Opportunity__r.Account.AccountCode__c, requestDataModel.CustomerCode);
			System.assertEquals(null, requestDataModel.PreviousCustomerCode);
			System.assertEquals(invoice.Opportunity__r.Project__r.ProjectCode__c, requestDataModel.ProjectCode);
			System.assertEquals(invoice.Id, requestDataModel.SFDocId);
			System.assertEquals(invoice.CreatedDate.date(), requestDataModel.DocDate);
			System.assertEquals('IV', requestDataModel.DocType);
			System.assertEquals(invoice.InvoiceNo__c, requestDataModel.InvoiceCode);
			System.assertEquals(null, requestDataModel.ReceiptCode);
			System.assertEquals(0, requestDataModel.Indicator);
			System.assertEquals(null, requestDataModel.GroupKey);
			System.assertEquals(null, requestDataModel.GLDate);
			System.assertEquals(null, requestDataModel.Remark);
			System.assertEquals(new List<String>{'',''}, requestDataModel.CoBuyerCustomerCode);
			List<InvoiceLineItem__c> targetInvoiceLineItems = invoice.InvoiceLineItems__r;
			List<PojjamanDataModel.FNGLDocLineRequest> requestLineModels = requestDataModel.DocLine;
			for (Integer j = 0; j < targetInvoiceLineItems.size(); j++){
				PojjamanDataModel.FNGLDocLineRequest docLine = requestLineModels[j];
				InvoiceLineItem__c invoiceLineItem = targetInvoiceLineItems[j];
				System.assertEquals(1, docLine.LineNumber);
				System.assertEquals(invoiceLineItem.Invoice__r.Opportunity__r.Unit__r.ProductCode, docLine.UnitCode);
				System.assertEquals(invoiceLineItem.Term__c, docLine.Type);
				System.assertEquals(invoiceLineItem.Amount__c, docLine.Amount);
				System.assertEquals(null, docLine.IsDebit);
				System.assertEquals(invoiceLineItem.Id, docLine.SFDocLineId);
				System.assertEquals(invoiceLineItem.Status__c, docLine.Status);
				System.assertEquals(invoiceLineItem.DueDate__c, docLine.DueDate);
				System.assertEquals(null, docLine.RefInvoiceId);
			}
		}
	}

	@isTest
	static void receiptWithCoBuyerNegativeTest2(){
		DataMaker dataMaker = DataMaker.getInstance();
		PaymentReceiptService receiptService = PaymentReceiptService.getInstance();
		Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
		Id recordTypeId = Schema.getGlobalDescribe()
		.get('Account')
		.getDescribe()
		.getRecordTypeInfosByName()
		.get('Co-Owner - Corporate')
		.getRecordTypeId();
		Account accountToBeCoBuyer = dataMaker.createAccount(recordTypeId, 'Cobuyer Account 1');
		accountToBeCoBuyer.AccountCode__c = null;
		List<Account> accountsToBeCoBuyer = new List<Account>{accountToBeCoBuyer};
		insert accountsToBeCoBuyer;
		CoBuyer__c targetCoBuyer = dataMaker.createCoBuyer(opportunity.Id,accountToBeCoBuyer.Id , '1');
		List<CoBuyer__c> coBuyers = new List<CoBuyer__c>{targetCoBuyer};
		insert coBuyers;
		Decimal amount = 100000;
		String receiptType = GlobalConstants.RECEIPT_TYPE_DEFAULT;
		String paymentMethodType = 'Credit Card';
		PaymentReceiptSelector receiptSelector = PaymentReceiptSelector.getInstance();
		receiptService.createPaymentReceiptWithLineItem(opportunity.Id, amount, receiptType, paymentMethodType);
		List<PaymentReceipt__c> receipts = [
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
			OR LastCancelledStatusInPojjaman__c = 'Fail') AND
			ReceiptType__c !=: GlobalConstants.RECEIPT_TYPE_REFUND_FORFEIT AND
			(CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_UPGRADE AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_DOWNGRADE AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_MOVEPAYMENT AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_CANCELREFUND AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONREFUND AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_CANCELFORFEIT AND
			CancelReason__c !=: GlobalConstants.RECEIPT_LOST_REASON_TERMINATIONFORFEIT)
			ORDER BY CreatedDate ASC
		];
		System.assertEquals(1, receipts.size());
		CreateReceiptApiCallout callout = new CreateReceiptApiCallout(receipts);
		Test.startTest();
			Object request = callout.buildRequestDataModel();
		Test.stopTest();
		List<PojjamanDataModel.FNGLDocRequest> requestModels = (List<PojjamanDataModel.FNGLDocRequest>) request;
		System.assertNotEquals(0, requestModels.size());
		System.assertNotEquals(null, request);
		System.assertEquals(receipts.size(), requestModels.size());
		for (Integer i = 0; i < receipts.size(); i++){
			PojjamanDataModel.FNGLDocRequest requestDataModel = requestModels[i];
			PaymentReceipt__c receipt = receipts[i];
			System.assertEquals(new List<String>{''}, requestDataModel.CoBuyerCustomerCode);
		}
	}
}