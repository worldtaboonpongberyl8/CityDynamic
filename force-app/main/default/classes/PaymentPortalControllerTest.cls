@isTest
public class PaymentPortalControllerTest {
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
        opp.PaymentPortalToken__c = '12345678';
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
        paymentTarm1.IsAllowedPaymentByGateway__c = true;
		PaymentTerm__c paymentTarm2 = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			2,
			null,
			20,
			'Installment 1'
		);
        paymentTarm2.IsAllowedPaymentByGateway__c = true;
		PaymentTerm__c paymentTarm3 = dataMaker.createPaymentTermLineItem(
			paymentTermMaster.Id,
			3,
			null,
			null,
			'Transfer'
		);
        paymentTarm3.IsAllowedPaymentByGateway__c = true;
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
    static void PaymentPortalControllerTest(){
        Opportunity opp = [SELECT id
		,PaymentPortalToken__c
		FROM Opportunity LIMIT 1];
        Test.startTest();
        Test.setCurrentPage(Page.PaymentPortal); // replace with actual VF page name
        ApexPages.currentPage().getParameters().put('oppId', opp.Id);
        ApexPages.currentPage().getParameters().put('token', opp.PaymentPortalToken__c);

        PaymentPortalController controller = new PaymentPortalController();
        PaymentPortalController.PaymentPortalWrapper wrapper = controller.getPaymentPortal();

        System.debug('PaymentPortalWrapper: '+wrapper);
        System.assertNotEquals(null, wrapper);
        System.assertEquals(true, wrapper.isToken);
        System.assertNotEquals(null, wrapper.paymentPortalHeader);
        System.assert(wrapper.paymentPortalTable.size() > 0);
        Test.stopTest();
    }
}