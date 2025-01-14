@isTest
public with sharing class ZipUtilityTest {
    @isTest
    static void createMergeFileWithAttachmentAndImageTest() {
		StaticResource staticResource = [
			SELECT Id, ContentType, BodyLength, Body, Description
			FROM StaticResource
			WHERE Name = 'SampleContractWordRelsXML'
		];
		// Create Zip File
        ZipFile__c sampleContractZipFile = new ZipFile__c(
            Name = 'Sample Contract.docx',
            RecordTypeId = ZipUtility.getInstance().MERGE_DATA_RECORDTYPE
        );
		List<ZipFile__c> zipFileMasters = new List<ZipFile__c>{sampleContractZipFile};
		insert zipFileMasters;
		// Create Attachment
        String attachmentXml = staticResource.Body.toString().replace('a02dM000004mhJhQAI', sampleContractZipFile.Id);
        Attachment attachSampleContractMaster = new Attachment();
        attachSampleContractMaster.Name = 'word/_rels/document.xml.rels';
        attachSampleContractMaster.Body = Blob.valueOf(attachmentXml);
        attachSampleContractMaster.ParentId = sampleContractZipFile.Id;
        attachSampleContractMaster.ContentType = 'application/msword';
        attachSampleContractMaster.IsPrivate = false;
        attachSampleContractMaster.Description = 'Test';
        insert new List<Attachment>{ attachSampleContractMaster };
		// Create ContentVersion
		Map<Id, List<ContentVersion>> contentVersionsMapByZipMasterId = new Map<Id, List<ContentVersion>>();
        Set<Id> zipMasterIdHasReplaceImgSet = new Set<Id>();
		for (ZipFile__c zipFileMaster : zipFileMasters) {
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            for (Integer i = 0; i < 2; i++) {
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = 'Image' + i;
                contentVersion.VersionData = Blob.valueOf('Image Data');
				contentVersion.PathOnClient = 'Image' + i + '.jpg';
                contentVersions.add(contentVersion);
            }
            insert contentVersions;
            contentVersionsMapByZipMasterId.put(zipFileMaster.Id, contentVersions);
            zipMasterIdHasReplaceImgSet.add(zipFileMaster.Id);
        }
		Test.startTest();
        Map<String, List<Attachment>> result = ZipUtility.getInstance().createMergeFileWithAttachmentAndImage(
            zipFileMasters, 
            ZipUtility.getInstance().MERGE_DATA_RECORDTYPE, 
            contentVersionsMapByZipMasterId, 
            zipMasterIdHasReplaceImgSet
        );
        Test.stopTest();
        List<Attachment> imageAttachments = [SELECT Id, Name, ParentId FROM Attachment WHERE Name LIKE 'word/media/%'];
        System.assertNotEquals(0, imageAttachments.size());
        List<Attachment> relsXMLAttachment = [SELECT Id FROM Attachment WHERE Name LIKE 'word/_rels/document.xml.rels'];
        System.assertNotEquals(0, relsXMLAttachment.size());
    }

	@isTest 
	static void createMergeFileWithAttachmentAndImageTestReceivedMapOfMap(){
		StaticResource staticResource = [
			SELECT Id, ContentType, BodyLength, Body, Description
			FROM StaticResource
			WHERE Name = 'SampleContractWordRelsXML'
		];
		// Create Zip File
        ZipFile__c sampleContractZipFile = new ZipFile__c(
            Name = 'Sample Contract.docx',
            RecordTypeId = ZipUtility.getInstance().MERGE_DATA_RECORDTYPE
        );
		List<ZipFile__c> zipFileMasters = new List<ZipFile__c>{sampleContractZipFile};
		insert zipFileMasters;
		// Create Attachment
        String attachmentXml = staticResource.Body.toString().replace('a02dM000004mhJhQAI', sampleContractZipFile.Id);
        Attachment attachSampleContractMaster = new Attachment();
        attachSampleContractMaster.Name = 'word/_rels/document.xml.rels';
        attachSampleContractMaster.Body = Blob.valueOf(attachmentXml);
        attachSampleContractMaster.ParentId = sampleContractZipFile.Id;
        attachSampleContractMaster.ContentType = 'application/msword';
        attachSampleContractMaster.IsPrivate = false;
        attachSampleContractMaster.Description = 'Test';
        insert new List<Attachment>{ attachSampleContractMaster };
		// Create ContentVersion
		Map<Id, Map<String, List<ContentVersion>>> contentVersMapByDocPathNameMapByZipMasterId = new Map<Id, Map<String, List<ContentVersion>>>();
        Set<Id> zipMasterIdHasReplaceImgSet = new Set<Id>();
		for (ZipFile__c zipFileMaster : zipFileMasters) {
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            for (Integer i = 0; i < 2; i++) {
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = 'Image' + i;
                contentVersion.VersionData = Blob.valueOf('Image Data');
				contentVersion.PathOnClient = 'Image' + i + '.jpg';
                contentVersions.add(contentVersion);
            }
            insert contentVersions;
            Map<String, List<ContentVersion>> contentVersMapByDocPathName = new Map<String, List<ContentVersion>>();
            contentVersMapByDocPathName.put('word/document.xml', contentVersions);
            contentVersMapByDocPathNameMapByZipMasterId.put(zipFileMaster.Id, contentVersMapByDocPathName);
            zipMasterIdHasReplaceImgSet.add(zipFileMaster.Id);
        }
		
		Test.startTest();
		Map<String, List<Attachment>> result = ZipUtility.getInstance().createMergeFileWithAttachmentAndImage(
            zipFileMasters,
            ZipUtility.getInstance().MERGE_DATA_RECORDTYPE,
            contentVersMapByDocPathNameMapByZipMasterId,
            zipMasterIdHasReplaceImgSet
        );
		Test.stopTest();

		System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        System.assertEquals('word/_rels/document.xml.rels', result.get(result.keySet().iterator().next())[0].Name);
	}

	@isTest 
	static void deleteZipRecordTest(){
        List<ZipFile__c> zipFiles = new List<ZipFile__c>();
        for (Integer i = 0; i < 3; i++) {
            ZipFile__c zipFile = new ZipFile__c(
                Name = 'Test Zip File ' + i,
                RecordTypeId = ZipUtility.getInstance().MERGE_DATA_RECORDTYPE
            );
            zipFiles.add(zipFile);
        }
        insert zipFiles;
        System.assertEquals(3, [SELECT COUNT() FROM ZipFile__c WHERE Id IN :zipFiles], '3 ZipFile__c records should have been inserted.');
        Set<Id> zipFileIdSet = new Set<Id>();
        for (ZipFile__c zipFile : zipFiles) {
            zipFileIdSet.add(zipFile.Id);
        }
        ZipUtility.getInstance().deleteZipRecord(zipFileIdSet);
        System.assertEquals(0, [SELECT COUNT() FROM ZipFile__c WHERE Id IN :zipFileIdSet], 'The ZipFile__c records should have been deleted.');
	}
}