@isTest 
public with sharing class PaymentTermSelectorTest {
	@isTest 
	static void getPaymentTermMasterWithLineItemsMapByIdTest(){
		Test.startTest();
		DataMaker dataMaker = DataMaker.getInstance();
		PaymentTermSelector selector = PaymentTermSelector.getInstance();
		Project__c project = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert project;
		PaymentTermMaster__c paymentTermMaster = dataMaker.craetePaymentTermMaster(project.Id,'TQ Series 5-10-85', 'Series', 'Thai', 25);
		insert paymentTermMaster;
		Map<Id,PaymentTermMaster__c> paymentTermMasterMapById = selector.getPaymentTermMasterWithLineItemsMapById(new Set<Id>{paymentTermMaster.Id});
		System.assertEquals(paymentTermMaster.Id, (new List<Id>(paymentTermMasterMapById.keyset())).get(0));
		Test.stopTest();
	}
}