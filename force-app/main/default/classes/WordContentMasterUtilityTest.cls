@isTest
public with sharing class WordContentMasterUtilityTest {
	@isTest
	public static void testGetWordDocumentXMLWithExternalKey() {
		StaticResource staticResource = [
			Select Id, ContentType, BodyLength, Body, Description
			FROM StaticResource
			WHERE Name = 'SampleContractWordXML'
		];

		ZipFile__c zipFile = new ZipFile__c(
			Name = 'Sample Contract.docx',
			RecordTypeId = ZipUtility.getInstance().MASTER_DATA_RECORDTYPE
		);
		insert zipFile;

		Blob ctWithExtKey = WordContentMasterUtility.getInstance().getWordDocumentXMLWithExternalKey(zipFile.Id, staticResource.Body, 'word/document.xml');
		String result = ctWithExtKey.toString();
		System.assert(result.contains('<!-- {CONTENTMASTER:'));
		System.assertEquals(20, result.split('<!-- \\{CONTENTMASTER:').size());

	}
}