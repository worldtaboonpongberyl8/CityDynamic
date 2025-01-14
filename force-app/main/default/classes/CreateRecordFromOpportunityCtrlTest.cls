@isTest
public with sharing class CreateRecordFromOpportunityCtrlTest {
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
        insert testProduct;
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
        // Create Opportunity
        List<Opportunity> opportunities = new List<Opportunity>{
            dataMaker.createOpportunity(
                account.Id,
                'Omitted',
                'Test Opp',
                Date.today(),
                'Open',
                testProduct.Id,
                'Foreign',
                null,
                testProject.Id
            )
        };
        insert opportunities;
    }

    @isTest 
    static void createQuoteFromOpportunityTest(){
        Test.startTest();
        Opportunity targetOpp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Quote__c> targetQuotes = new List<Quote__c>{CreateRecordFromOpportunityController.createQuoteFromOpportunity(targetOpp.Id)};
        List<Quote__c> resultQuotes = [SELECT Id , Opportunity__c FROM Quote__c ];
        System.assertEquals(1, targetQuotes.size());
        Quote__c resultQuote = resultQuotes[0];
        System.assertEquals(targetOpp.Id, resultQuote.Opportunity__c);
        Test.stopTest();
    }

    @isTest 
    static void createContractFromOpportunityTest(){
        Test.startTest();
        Opportunity targetOpp = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
        List<Contract> targetContracts = new List<Contract>{ CreateRecordFromOpportunityController.createContractFromOpportunity(targetOpp.Id) };
        List<Contract> resultContracts = [SELECT Id , Opportunity__c, AccountId FROM Contract ];
        System.assertEquals(1, targetContracts.size());
        Contract resultContract = resultContracts[0];
        System.assertEquals(targetOpp.Id, resultContract.Opportunity__c);
        System.assertEquals(targetOpp.AccountId, resultContract.AccountId);
        Test.stopTest();
    }
}