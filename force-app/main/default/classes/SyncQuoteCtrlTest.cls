@isTest
private class SyncQuoteCtrlTest {
    @TestSetup
    static void makeData(){
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
        testProduct.ReservationPrice__c = 10000;
        insert testProduct;
        // Create Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry testPricebookEntry1 = dataMaker.createPricebookEntries(testProduct.Id, 150000, 200000,10000000);
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
        Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
        insert account;
        PaymentTermMaster__c paymentTermMasterNew = dataMaker.craetePaymentTermMaster(testProject.Id,'TQ Series 5-10-85', 'Series', 'Thai', 25);
        insert paymentTermMasterNew;
        List<PaymentTerm__c> paymentTermWrappers = new List<PaymentTerm__c>();
        PaymentTerm__c paymentTarm1 = dataMaker.createPaymentTermLineItem(
            paymentTermMasterNew.Id,
            1,
            null,
            10,
            'Contract'
        );
        PaymentTerm__c paymentTarm2 = dataMaker.createPaymentTermLineItem(
            paymentTermMasterNew.Id,
            2,
            null,
            20,
            'Installment 1'
        );
        PaymentTerm__c paymentTarm3 = dataMaker.createPaymentTermLineItem(
            paymentTermMasterNew.Id,
            3,
            null,
            null,
            'Transfer'
        );
        paymentTermWrappers.add(paymentTarm1);
        paymentTermWrappers.add(paymentTarm2);
        paymentTermWrappers.add(paymentTarm3);
        insert paymentTermWrappers;
        // Create Opportunity
        List<Opportunity> opportunities = new List<Opportunity>{
            dataMaker.createOpportunity(
                account.Id,
                'Omitted',
                'Test Opp',
                Date.today(),
                'Open',
                testProduct.Id,
                'Thai',
                paymentTermMasterNew.Id,
                testProject.Id
            )
        };
        insert opportunities;
        Quote__c testQuote = dataMaker.createQuote(
            opportunities[0].Id
        );  
        insert testQuote;
    }
    @isTest 
    static void syncQuoteFromOpportunityTest(){
        Quote__c quote = [SELECT Id,Opportunity__c , IsSyncing__c FROM Quote__c LIMIT 1];
        Quote__c result = SyncQuoteCtrl.syncQuoteFromOpportunity(quote.Id);
        Opportunity opp = [SELECT Id , SyncedQuoteId__c FROM Opportunity WHERE  Id=: result.Opportunity__c];
        System.assertEquals(true, result.IsSyncing__c);
        System.assertEquals(opp.SyncedQuoteId__c, result.Id);
        
    }
}