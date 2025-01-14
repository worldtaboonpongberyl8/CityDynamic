@isTest
public with sharing class OpportunityPaymentServiceTest {
	@TestSetup
	static void makeData(){
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		testProject.CompletionDate__c = Date.today().addDays(10);
		insert testProject;
		Floor__c testFloor =dataMaker.createFloor('Test Floor', 'FF01' , testProject.Id);
		insert testFloor;
		UnitType__c unitType = dataMaker.createUnitType('Test Unit Type', testProject.Id);
		insert unitType;
		Product2 testProduct = dataMaker.createUnit('Test Product','PP01',testProject.Id,testFloor.Id,'Available',unitType.Id);
		testProduct.ReservationPrice__c = 10000;
		insert testProduct;
		// Pricebook2 testPricebook = dataMaker.createPricebook('Test Pricebook', testProduct.Id, 150000, 200000);
		// insert testPricebook;
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 150000, 200000,10000000);
		testPricebookEntry1.Pricebook2Id = pricebookId;
		testPricebookEntry1.UseStandardPrice = false;
		insert testPricebookEntry1;
		Id recordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Co-Owner - Corporate').getRecordTypeId();
		Account acc = dataMaker.createAccount(recordTypeId, 'Test Account');
		insert acc;
		PaymentTermMaster__c paymentTermMaster = dataMaker.craetePaymentTermMaster(testProject.Id,'TQ Series 5-10-85', 'Series', 'Thai', 25);
		insert paymentTermMaster;
		Opportunity opp = dataMaker.createOpportunity(acc.Id, 'Omitted', 'Test Opp1', Date.today(), 'Open',testProduct.Id,'Thai',paymentTermMaster.Id,testProject.Id);
		opp.ReservationDueDate__c = Date.today();
		opp.DiscountPercent__c = 10;
		opp.DiscountAmount__c = 0;
		opp.UnitPrice__c = 1000000;
		insert opp;
		PaymentTermMaster__c paymentTermMasterNew = dataMaker.craetePaymentTermMaster(testProject.Id,'TQ Series 9-10-85', 'Series', 'Thai', 25);
		insert paymentTermMasterNew;
		List<PaymentTerm__c> paymentTermWrappers = new List<PaymentTerm__c>();
		PaymentTerm__c paymentTarm1 = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			1,
			null,
			10,
			'Contract'
		);
		PaymentTerm__c paymentTarm2 = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			2,
			null,
			20,
			'Installment 1'
		);
		PaymentTerm__c paymentTarm3 = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			3,
			null,
			null,
			'Transfer'
		);
		paymentTermWrappers.add(paymentTarm1);
		paymentTermWrappers.add(paymentTarm2);
		paymentTermWrappers.add(paymentTarm3);
		insert paymentTermWrappers;

		List<PaymentTerm__c> paymentTermWrapperNews = new List<PaymentTerm__c>{
			dataMaker.createPaymentTermLineItem(paymentTermMasterNew.Id,1,100000.00,null,'Contract'),
			dataMaker.createPaymentTermLineItem(paymentTermMasterNew.Id,2,null,20,'Installment 1'),
			dataMaker.createPaymentTermLineItem(paymentTermMasterNew.Id,3,null,20,'Installment 2'),
			dataMaker.createPaymentTermLineItem(paymentTermMasterNew.Id,4,null,30,'Installment 3'),
			dataMaker.createPaymentTermLineItem(paymentTermMasterNew.Id,5,null,null,'Transfer')
		};
		insert paymentTermWrapperNews;



	}

	@isTest
	static void getOppPaymentsFromJSONStringTest(){
		Test.startTest();
		OpportunityPaymentService service = OpportunityPaymentService.getInstance();
		List<OpportunityPaymentService.OpportunityPaymentWrapper> oppPaymentWrappers = new List<OpportunityPaymentService.OpportunityPaymentWrapper>();
		OpportunityPaymentService.OpportunityPaymentWrapper reservationPaymentWrapper = new OpportunityPaymentService.OpportunityPaymentWrapper();
		reservationPaymentWrapper.amount = 50000;
		reservationPaymentWrapper.dueDate = Date.newInstance(2024, 10, 12);
		reservationPaymentWrapper.order = 1;
		reservationPaymentWrapper.term = 'Reservation';
		reservationPaymentWrapper.isNewRecord = false;
		oppPaymentWrappers.add(reservationPaymentWrapper);
		OpportunityPaymentService.OpportunityPaymentWrapper contractPaymentWrapper = new OpportunityPaymentService.OpportunityPaymentWrapper();
		contractPaymentWrapper.amount = 100000;
		contractPaymentWrapper.dueDate = Date.newInstance(2024, 10, 27);
		contractPaymentWrapper.order = 2;
		contractPaymentWrapper.term = 'Reservation';
		contractPaymentWrapper.isNewRecord = false;
		oppPaymentWrappers.add(contractPaymentWrapper);
		OpportunityPaymentService.OpportunityPaymentWrapper installmentPaymentWrapper = new OpportunityPaymentService.OpportunityPaymentWrapper();
		installmentPaymentWrapper.amount = 200000;
		installmentPaymentWrapper.dueDate = Date.newInstance(2024, 11, 25);
		installmentPaymentWrapper.order = 3;
		installmentPaymentWrapper.term = 'Installment 1';
		installmentPaymentWrapper.isNewRecord = false;
		oppPaymentWrappers.add(installmentPaymentWrapper);
		OpportunityPaymentService.OpportunityPaymentWrapper transferPaymentWrapper = new OpportunityPaymentService.OpportunityPaymentWrapper();
		transferPaymentWrapper.amount = 1000000;
		transferPaymentWrapper.dueDate = Date.newInstance(2026, 11, 25);
		transferPaymentWrapper.order = 4;
		transferPaymentWrapper.term = 'Transfer';
		transferPaymentWrapper.isNewRecord = false;
		oppPaymentWrappers.add(transferPaymentWrapper);
		String oppPaymentsJSON = JSON.serialize(oppPaymentWrappers);
		List<OpportunityPayment__c> oppPayments = service.getOppPaymentsFromJSONString(oppPaymentsJSON);
		System.assertEquals(oppPaymentWrappers.size(), oppPayments.size());
		for (Integer i = 0; i < oppPayments.size(); i++){
			System.assertEquals(oppPaymentWrappers[i].amount, oppPayments[i].Amount__c);
			System.assertEquals(oppPaymentWrappers[i].dueDate, oppPayments[i].DueDate__c);
			System.assertEquals(oppPaymentWrappers[i].order, oppPayments[i].Order__c);
			System.assertEquals(oppPaymentWrappers[i].term, oppPayments[i].Term__c);
		}
		Test.stopTest();
	}
	@isTest
	static void updateOpportunityPaymentByPaymentMasterTest(){
		Test.startTest();
		OpportunityTriggerHandler oppTrigger = OpportunityTriggerHandler.getInstance();
		oppTrigger.setBypass();
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c project = [SELECT Id FROM Project__c WHERE ProjectCode__c = 'AA01'];
		System.debug('Test Project: ' + project);
		PaymentTermMaster__c paymentTarmMaster = [SELECT Id FROM PaymentTermMaster__c WHERE Name =:'TQ Series 5-10-85'];
		PaymentTermMaster__c paymentTarmMasterNew = [SELECT Id FROM PaymentTermMaster__c WHERE Name =:'TQ Series 9-10-85'];
		Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'PP01'];
		Opportunity opp = [SELECT Id , AccountId ,Name ,ForecastCategoryName,CloseDate,Unit__c,Quota__c,StageName,PaymentTermMaster__c,NetPrice__c FROM Opportunity WHERE Unit__c =: product.Id];
		Opportunity oppUpdate = [SELECT Id , AccountId ,Name ,ForecastCategoryName,CloseDate,Unit__c,Quota__c,StageName,PaymentTermMaster__c,NetPrice__c FROM Opportunity WHERE Id =: opp.Id];
		oppUpdate.Project__c = project.Id;
		oppUpdate.ReservationDueDate__c = Date.today();
		oppUpdate.DiscountPercent__c = 10;
		oppUpdate.DiscountAmount__c = 0; // formula field ผิดอยู่คือ ไม่ได้ handle กรณี DiscountAmount__c เป็น Null ถ้าเป็น Null จะส่งผลให้ NetPrice__c เป็น Null ทันที
		oppUpdate.UnitPrice__c = 1000000;
		oppUpdate.PaymentTermMaster__c = paymentTarmMasterNew.Id;
		update oppUpdate;
		List<Opportunity> oppList = [SELECT Id , UnitPrice__c , NetPrice__c,Unit__c,ReservationDueDate__c,PaymentTermMaster__c,Project__c,TotalDiscountPercent__c,DiscountPercent__c,DiscountPercentOfAmount__c FROM Opportunity WHERE Id =: oppUpdate.Id];
		System.debug('Opp List: '+oppList);
		OpportunityPaymentService serviceOppPayment = OpportunityPaymentService.getInstance();
		List<OpportunityPayment__c> oppPaymentTerms = serviceOppPayment.updateOpportunityPaymentByPaymentMaster(oppList);
		List<OpportunityPayment__c> oppPaymentOldTerms = [SELECT Id FROM OpportunityPayment__c WHERE PaymentTermMaster__c = :paymentTarmMaster.Id];
		System.assertEquals(0, oppPaymentOldTerms.size());
		System.assertEquals(paymentTarmMasterNew.Id , oppPaymentTerms[0].PaymentTermMaster__c);
		System.assertEquals(6, oppPaymentTerms.size());
		for(OpportunityPayment__c oppPayment : oppPaymentTerms){
			System.assertEquals(oppPayment.Order__c, Integer.valueOf(oppPayment.Name));
		}
		Test.stopTest();
	}
	@isTest
	static void adjustRelatedOpportunityPaymentAfterApplyDiscountTest(){
		Test.startTest();
		OpportunityTriggerHandler oppTrigger = OpportunityTriggerHandler.getInstance();
		oppTrigger.setBypass();
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c project = [SELECT Id FROM Project__c WHERE ProjectCode__c = 'AA01'];
		PaymentTermMaster__c paymentTermMaster = [SELECT Id FROM PaymentTermMaster__c WHERE Name = 'TQ Series 5-10-85'];
		Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'PP01'];
		Opportunity opp = [SELECT Id FROM Opportunity WHERE Unit__c =: product.Id];
		List<Opportunity> oppList = [SELECT Id , UnitPrice__c , NetPrice__c,Unit__c,ReservationDueDate__c,PaymentTermMaster__c,Project__c FROM Opportunity WHERE Id =: opp.Id];
		OpportunityPaymentService serviceOppPayment = OpportunityPaymentService.getInstance();
		Opportunity resultCreate = [SELECT Id , AccountId ,Name ,ForecastCategoryName,CloseDate,Unit__c,Quota__c,StageName,PaymentTermMaster__c,DiscountPercent__c FROM Opportunity WHERE Id =: opp.Id];
		System.assertEquals(10, resultCreate.DiscountPercent__c);
		List<OpportunityPayment__c> resultOppPayment = serviceOppPayment.adjustRelatedOpportunityPaymentAfterApplyDiscount(oppList);
		for(OpportunityPayment__c oppPayment : resultOppPayment){
			System.debug(oppPayment);
			if(oppPayment.Term__c.contains('Reservation')){
				System.assertEquals(10000, oppPayment.Amount__c);
			}
			else if(oppPayment.Term__c == 'Contract'){
				System.assertEquals(13500, oppPayment.Amount__c);
			}else if(oppPayment.Term__c.contains('Installment')){
				System.assertEquals(27000, oppPayment.Amount__c);
			}else if(oppPayment.Term__c.contains('Transfer')){
				System.assertEquals(60500, oppPayment.Amount__c);
			}
		}
		Test.stopTest();
	}
	@isTest
	static void createOpportunityPaymentByPaymentMasterTest(){
		Test.startTest();
		Product2 product = [SELECT Id,Name FROM Product2 WHERE ProductCode = 'PP01'];
		Opportunity opp = [SELECT Id FROM Opportunity WHERE Unit__c =: product.Id];
		List<Opportunity> results = [SELECT Id , UnitPrice__c , NetPrice__c,Unit__c,ReservationDueDate__c,PaymentTermMaster__c,Project__c FROM Opportunity WHERE Id =: opp.Id];
		System.debug('Result: ' + results);
		OpportunityPaymentService serviceOppPayment = OpportunityPaymentService.getInstance();
		List<OpportunityPayment__c> oppPayments = serviceOppPayment.createOpportunityPayments(results);
		System.assertEquals(4, oppPayments.size());
		for(OpportunityPayment__c oppPayment : oppPayments){
			System.assertEquals(oppPayment.Order__c, Integer.valueOf(oppPayment.Name));
			System.assertEquals('Test Project', oppPayment.ProjectName__c);
			System.assertEquals('Test Product', oppPayment.UnitName__c);
		}
		Test.stopTest();
	}

	@isTest
	static void getClonedOpportunityPaymentByQuoteTest(){
		Test.startTest();
		Project__c targetProject = [SELECT Id FROM Project__c WHERE ProjectCode__c = 'AA01' LIMIT 1];
		Opportunity opp1 = [SELECT Id , TotalInstallmentAmount__c,TotalInstallmentPercent__c,PaymentTermMaster__c FROM Opportunity WHERE Project__c =: targetProject.Id];
		List<OpportunityPayment__c> oppPayments = [SELECT Id,Amount__c FROM OpportunityPayment__c WHERE Opportunity__c =: opp1.Id];
		List<Quote__c> quotes = new List<Quote__c>{
			new Quote__c(Opportunity__c = opp1.Id)
		};
		OpportunityPaymentService service = OpportunityPaymentService.getInstance();
		List<OpportunityPayment__c> resultOppPayments = service.getClonedOpportunityPaymentByQuote(quotes);
		for (Integer i = 0 ; i < resultOppPayments.size(); i++) {
			System.assertEquals(oppPayments[i].Amount__c, resultOppPayments[i].Amount__c);
			System.assertEquals(opp1.Id, resultOppPayments[i].Opportunity__c);
		}
		Test.stopTest();
	}

	@isTest
	static void stampFieldFromReceiptLineItemTest(){
		Test.startTest();
		PaymentReceiptService paymentReceiptService = PaymentReceiptService.getInstance();
		OpportunityPaymentService oppPaymentService = OpportunityPaymentService.getInstance();
		List<OpportunityPayment__c> oppPayments = [SELECT Id,Remaining__c,Amount__c,Term__c,Order__c FROM OpportunityPayment__c ORDER BY Order__c];
		List<PaymentReceiptLineItem__c> resultPaymentReceiptItems1 = paymentReceiptService.generatePaymentReceiptLineItemFromTotalReceivedAmount(50000,oppPayments,null,null);
		List<OpportunityPayment__c> resultOppPayments1 = oppPaymentService.stampFieldFromReceiptLineItem(resultPaymentReceiptItems1);
		System.assertEquals(1, resultOppPayments1.size());
		System.assertEquals(10000, resultOppPayments1[0].ReceivedAmount__c);
		Test.stopTest();
	}

	@isTest
	static void cancelRecievedAmountFromReceiptLineItemTest(){
		Test.startTest();
		PaymentReceiptService paymentReceiptService = PaymentReceiptService.getInstance();
		OpportunityPaymentService oppPaymentService = OpportunityPaymentService.getInstance();
		List<OpportunityPayment__c> oppPayments = [SELECT Id,Remaining__c,Amount__c,Term__c,Order__c FROM OpportunityPayment__c ORDER BY Order__c];
		List<PaymentReceiptLineItem__c> resultPaymentReceiptItems1 = paymentReceiptService.generatePaymentReceiptLineItemFromTotalReceivedAmount(50000,oppPayments,null,null);
		List<OpportunityPayment__c> resultOppPayments1 = oppPaymentService.stampFieldFromReceiptLineItem(resultPaymentReceiptItems1);
		update resultOppPayments1;
		List<OpportunityPayment__c> resultOppPaymentsCancel = oppPaymentService.cancelRecievedAmountFromReceiptLineItem(resultPaymentReceiptItems1);
		System.assertEquals(1, resultOppPaymentsCancel.size());
		System.assertEquals(0, resultOppPaymentsCancel[0].ReceivedAmount__c);
		Test.stopTest();
	}
}