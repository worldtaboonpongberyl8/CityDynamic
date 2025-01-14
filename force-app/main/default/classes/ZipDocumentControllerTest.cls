@isTest
public with sharing class ZipDocumentControllerTest {
    @isTest
    public static void testReceiveZipFile() {
        ZipFile__c zipFile = new ZipFile__c(
            Name = 'Test[COMMA]General[AMPERSAND]Template.docx',
            RecordTypeId = ZipUtility.getInstance().MERGE_DATA_RECORDTYPE
        );
        insert zipFile;

        PageReference pageRef = Page.ZipDocument;
        Test.setCurrentPage(pageRef);
        
        pageRef.getParameters().put('recordId', zipFile.Id);
        pageRef.getParameters().put('remainingList', '');
        pageRef.getParameters().put('remainingDocNameList', 'Test[COMMA]General[AMPERSAND]Template.docx');
		pageRef.getParameters().put('remainingFieldAPISaveToExistingList', '');

        ApexPages.StandardController sc = new ApexPages.StandardController(zipFile);
        ZipDocumentController zipController = new ZipDocumentController(sc);
        zipController.receiveZipFile();

        ContentVersion result = [SELECT Id, Title FROM ContentVersion LIMIT 1];
        System.assertEquals('Test,General&Template.docx', result.Title);
    }

    @isTest
    public static void testRedirectToLightningPage() {
        ZipFile__c zipFile = new ZipFile__c(
            Name = 'Test General Template.docx',
            RecordTypeId = ZipUtility.getInstance().MERGE_DATA_RECORDTYPE
        );
        insert zipFile;
        
        PageReference pageRef = Page.ZipDocument;
        Test.setCurrentPage(pageRef);

        pageRef.getParameters().put('recordId', zipFile.Id);
        pageRef.getParameters().put('remainingList', '');
        pageRef.getParameters().put('remainingDocNameList', 'Test General Template.docx');
        pageRef.getParameters().put('remainingFieldAPISaveToExistingList', '');

        ApexPages.StandardController sc = new ApexPages.StandardController(zipFile);
        ZipDocumentController zipController = new ZipDocumentController(sc);
        PageReference result = zipController.redirectToLightningPage();

        System.assertEquals(('/' + zipFile.Id), result.getUrl()); 
    }
}