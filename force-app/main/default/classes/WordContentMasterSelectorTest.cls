@isTest
private class WordContentMasterSelectorTest {
    @TestSetup
    static void makeData(){
        DataMaker dataMaker = DataMaker.getInstance();
        ZipFile__c testZipFile = dataMaker.createZipFile('Test ZipFile', ZipUtility.getInstance().MASTER_DATA_RECORDTYPE);
        insert testZipFile;
        WordContentMaster__c testWordContentMaster = dataMaker.createWordContentMester(testZipFile.Id);
        testWordContentMaster.FormatType__c = 'IMAGELOOPRELATEDOBJECT';
        insert testWordContentMaster;
    }
    @isTest
    static void getByZipIdTest() {
        WordContentMaster__c testWordContentMaster = [SELECT Id,ZipFileMasterId__c FROM WordContentMaster__c LIMIT 1];
        List<WordContentMaster__c> results = WordContentMasterSelector.getInstance().getByZipId(testWordContentMaster.ZipFileMasterId__c);
        System.assertEquals(testWordContentMaster.ZipFileMasterId__c, results[0].ZipFileMasterId__c);
    }
    @isTest
    static void getByZipIdSetAndFormatTypeSetTest() {
        WordContentMaster__c testWordContentMaster = [SELECT Id,ZipFileMasterId__c FROM WordContentMaster__c LIMIT 1];
        List<WordContentMaster__c> results = WordContentMasterSelector.getInstance().getByZipIdSetAndFormatTypeSet(new Set<Id>{testWordContentMaster.ZipFileMasterId__c},new Set<String>{'IMAGELOOPRELATEDOBJECT'});
        System.assertEquals(testWordContentMaster.ZipFileMasterId__c, results[0].ZipFileMasterId__c);
    }
    
}