@isTest
private class ZipFileSelectorTest {
    @TestSetup
    static void makeData(){
        DataMaker dataMaker = DataMaker.getInstance();
        ZipFile__c testZipFile = dataMaker.createZipFile('Test ZipFile', ZipUtility.getInstance().MASTER_DATA_RECORDTYPE);
        insert testZipFile;
    }
    @isTest
    static void getByNameAndRecordTypeTest() {
        ZipFile__c testZipFile = [SELECT Id , Name ,RecordTypeId FROM ZipFile__c LIMIT 1];
        List<ZipFile__c> results = ZipFileSelector.getInstance().getByNameAndRecordType(new Set<String>{testZipFile.Name},testZipFile.RecordTypeId);
        System.assertEquals(testZipFile.Id, results[0].Id);
    }
    @isTest
    static void getByIdSetAndRecTypeTest() {
        ZipFile__c testZipFile = [SELECT Id , Name ,RecordTypeId FROM ZipFile__c LIMIT 1];
        List<ZipFile__c> results = ZipFileSelector.getInstance().getByIdSetAndRecType(new Set<String>{testZipFile.Id},testZipFile.RecordTypeId);
        System.assertEquals(testZipFile.Id, results[0].Id);
    }
    @isTest
    static void getByIdTest() {
        ZipFile__c testZipFile = [SELECT Id , Name ,RecordTypeId FROM ZipFile__c LIMIT 1];
        ZipFile__c result = ZipFileSelector.getInstance().getById(testZipFile.Id);
        System.assertEquals(testZipFile.Id, result.Id);
    }
    @isTest
    static void getByIdSetTest() {
        ZipFile__c testZipFile = [SELECT Id , Name ,RecordTypeId FROM ZipFile__c LIMIT 1];
        List<ZipFile__c> results = ZipFileSelector.getInstance().getByIdSet(new Set<Id>{testZipFile.Id});
        System.assertEquals(testZipFile.Id, results[0].Id);
    }
}