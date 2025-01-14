@isTest
public with sharing class UnzipDocumentControllerTest {
	@isTest
	static void unzippedTest() {
		Test.startTest();
		ZipFile__c zipFile = new ZipFile__c(
			Name = 'Test General Template.docx',
			RecordTypeId = ZipUtility.getInstance().MERGE_DATA_RECORDTYPE
		);
		insert zipFile;

		PageReference pageRef = Page.UnzipDocument;
		Test.setCurrentPage(pageRef);
		UnzipDocumentController unzipController = new UnzipDocumentController();
		unzipController.unzippedState = 'Test';
		PageReference result = unzipController.unzipped();
		System.assertEquals('/Test', result.getUrl());
		Test.stopTest();
	}

	@isTest
	static void receiveZipFileEntryTest() {
		Test.startTest();
		String result = UnzipDocumentController.receiveZipFileEntry(
			'Test General Template.docx',
			'word/document.xml',
			EncodingUtil.base64Encode(Blob.valueOf('Test file content')),
			''
		);
		Test.stopTest();
		ZipFile__c zip = [SELECT Id FROM ZipFile__c LIMIT 1];
		System.assertEquals(zip.Id, result);
	}
}