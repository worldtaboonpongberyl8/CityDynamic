@isTest
public with sharing class ZipFileControllerTest {

    @isTest
    public static void testReceiveZipFile() {
        ZipFile__c zipFile = new ZipFile__c(
            Name = 'Test General Template.docx',
            RecordTypeId = ZipUtility.getInstance().MERGE_DATA_RECORDTYPE
        );
        insert zipFile;

        PageReference pageRef = Page.ZipFile;
        Test.setCurrentPage(pageRef);


        pageRef.getParameters().put('recordId', zipFile.Id);
        pageRef.getParameters().put('remainingList', '');
        pageRef.getParameters().put('remainingDocNameList', '');

        ApexPages.StandardController sc = new ApexPages.StandardController(zipFile);
        ZipFileController zipController = new ZipFileController(sc);
        PageReference result = zipController.receiveZipFile();

        System.assertNotEquals(null, result); 
    }
}