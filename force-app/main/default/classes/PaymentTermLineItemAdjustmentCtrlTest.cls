@isTest
public with sharing class PaymentTermLineItemAdjustmentCtrlTest {
	@isTest
	static void getPaymentTermMasterWithLineItemTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		PaymentTermSelector selector = PaymentTermSelector.getInstance();
		Project__c project = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert project;
		PaymentTermMaster__c paymentTermMaster = dataMaker.craetePaymentTermMaster(project.Id,'TQ Series 5-10-85', 'Series', 'Thai', 25);
		insert paymentTermMaster;
		PaymentTermMaster__c paymentTermMasterResult = PaymentTermLineItemAdjustmentController.getPaymentTermMasterWithLineItem(paymentTermMaster.Id);
		System.assertEquals(paymentTermMaster.Id, paymentTermMasterResult.Id);
		Test.stopTest();
	}

	@isTest
	static void upsertPaymentTermLineItemTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c project = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert project;
		PaymentTermMaster__c paymentTermMaster = dataMaker.craetePaymentTermMaster(project.Id,'TQ Series 5-10-85', 'Series', 'Thai', 25);
		insert paymentTermMaster;
		List<PaymentTermService.PaymentTermLineItemWrapper> paymentTermWrappers = new List<PaymentTermService.PaymentTermLineItemWrapper>();
		PaymentTermService.PaymentTermLineItemWrapper wrapper1 = new PaymentTermService.PaymentTermLineItemWrapper();
		wrapper1.id = null;
		wrapper1.order = 1;
		wrapper1.amount = 100.00;
		wrapper1.percent = null;
		wrapper1.term = 'Contract';
		wrapper1.paymentTermMasterId = paymentTermMaster.Id;
		PaymentTermService.PaymentTermLineItemWrapper wrapper2 = new PaymentTermService.PaymentTermLineItemWrapper();
		wrapper2.id = null;
		wrapper2.order = 2;
		wrapper2.amount = null;
		wrapper2.percent = null;
		wrapper2.term = 'Transfer';
		wrapper2.paymentTermMasterId = paymentTermMaster.Id;
		paymentTermWrappers.add(wrapper1);
		paymentTermWrappers.add(wrapper2);
		String paymentTermLineItemJSON = JSON.serialize(paymentTermWrappers);
		List<PaymentTerm__c> upsertedPaymentTerms = PaymentTermLineItemAdjustmentController.upsertPaymentTermLineItem(paymentTermLineItemJSON);
		System.assertEquals(paymentTermWrappers.size(), upsertedPaymentTerms.size());
		for (Integer i = 0 ; i < upsertedPaymentTerms.size(); i++){
			System.assertEquals(upsertedPaymentTerms[i].Order__c, paymentTermWrappers[i].order);
			System.assertEquals(upsertedPaymentTerms[i].Amount__c, paymentTermWrappers[i].amount);
			System.assertEquals(upsertedPaymentTerms[i].Percent__c, paymentTermWrappers[i].percent);
			System.assertEquals(upsertedPaymentTerms[i].Term__c, paymentTermWrappers[i].term);
			System.assertEquals(upsertedPaymentTerms[i].PaymentTermMaster__c, paymentTermMaster.Id);
		}
		List<PaymentTerm__c> paymentTerms = [SELECT Id FROM PaymentTerm__c WHERE PaymentTermMaster__c =: paymentTermMaster.Id];
		System.assertEquals(upsertedPaymentTerms.size(), paymentTerms.size());
		Test.stopTest();
	}
}