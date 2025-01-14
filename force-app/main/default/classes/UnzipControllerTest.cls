@isTest
private class UnzipControllerTest {

    @isTest
	static void receiveZipFileEntryTest() {
		Test.startTest();
		String result = UnzipController.receiveZipFileEntry(
			'Test General Template.docx',
			'word/document.xml',
			EncodingUtil.base64Encode(Blob.valueOf('Test file content')),
			''
		);
		Test.stopTest();
		ZipFile__c zip = [SELECT Id FROM ZipFile__c LIMIT 1];
		System.assertEquals(zip.Id, result);
	}
    @isTest
    static void unzipControllerTest(){
        Test.startTest();
		UnzipController controller = new UnzipController();
		Test.stopTest();
        System.assertEquals('SampleContractWord', controller.fileWrapper.name);
    }
}