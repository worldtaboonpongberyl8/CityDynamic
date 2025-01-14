@isTest
private class AttachmentSelectorTest {
    @TestSetup
    static void makeData(){
        DataMaker dataMaker = DataMaker.getInstance();
        ZipFile__c testZipFile = dataMaker.createZipFile('Test ZipFile', ZipUtility.getInstance().MASTER_DATA_RECORDTYPE);
        insert testZipFile;
        Attachment testAttachment = dataMaker.createAttachment('Test Attachment',Blob.valueOf('Test Data'), testZipFile.Id);
        insert testAttachment;
    }
    @isTest
    static void getByParentIdSetTest() {
        Test.startTest();
        ZipFile__c testZipFile = [SELECT Id FROM ZipFile__c LIMIT 1];
        List<Attachment> results = AttachmentSelector.getInstance().getByParentIdSet(new Set<Id>{testZipFile.Id});
        System.assertEquals(testZipFile.Id, results[0].ParentId);
        Test.stopTest();
    }
    @isTest
    static void getByParentIdAndNameSetTest() {
        Test.startTest();
        ZipFile__c testZipFile = [SELECT Id FROM ZipFile__c LIMIT 1];
        Attachment testAttachment = [SELECT Id , Name FROM Attachment LIMIT 1];
        List<Attachment> results = AttachmentSelector.getInstance().getByParentIdAndNameSet(testZipFile.Id, new Set<String>{testAttachment.Name});
        System.assertEquals(testZipFile.Id, results[0].ParentId);
        Test.stopTest();
    }
    @isTest
    static void getByParentIdAndNameTest() {
        Test.startTest();
        ZipFile__c testZipFile = [SELECT Id FROM ZipFile__c LIMIT 1];
        Attachment testAttachment = [SELECT Id , Name FROM Attachment LIMIT 1];
        List<Attachment> results = AttachmentSelector.getInstance().getByParentIdAndName(testZipFile.Id, testAttachment.Name);
        System.assertEquals(testZipFile.Id, results[0].ParentId);
        Test.stopTest();
    }
}