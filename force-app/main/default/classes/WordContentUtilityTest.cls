@isTest
public with sharing class WordContentUtilityTest {

	@isTest
	public static void test_startGenerateDocxContract(){
		String sampleContractZipFileName = 'Sample Contract.docx';

		NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
			ObjectName__c = 'Contract',
			RunningFormat__c = '{ContractNumber}_{Account.Name}',
			RunningPurpose__c = 'Document',
			Type__c = 'Format',
			CurrentRunningNumber__c = 1
		);
		insert new List<NameFormattingMasterData__c>{runningNumberFormatDocument};

        Account account = new Account(
            Name = 'United Oil & Gas Corp.',
			Phone = '0111111111'
        );
        insert account;

		ContractTriggerHandler.getInstance().setBypass();
		Contract contract = new Contract(
            AccountId = account.Id
        );
		insert contract;
		ContractTriggerHandler.getInstance().clearBypass();

		Order order = new Order(
            AccountId = account.Id,
            ContractId = contract.Id,
            EffectiveDate = Date.newInstance(2024, 08, 01),
            EndDate = Date.newInstance(2025, 07, 31),
            Status = 'Draft'
        );
		insert order;

		StaticResource staticResource = [
			SELECT Id, ContentType, BodyLength, Body, Description
			FROM StaticResource
			WHERE Name = 'SampleContractWordWithWCMXML'
		];

		ZipFile__c sampleContractZipFile = new ZipFile__c(
			Name = sampleContractZipFileName,
			RecordTypeId = ZipUtility.getInstance().MASTER_DATA_RECORDTYPE
		);
		insert new List<ZipFile__c> {sampleContractZipFile};

        String attachmentXml = staticResource.Body.toString().replace('a0YBK000000QqkX2AS', sampleContractZipFile.Id);

		Attachment attachSampleContractMaster = new Attachment();
		attachSampleContractMaster.Name = 'word/document.xml';
		attachSampleContractMaster.Body = Blob.valueOf(attachmentXml);
		attachSampleContractMaster.ParentId = sampleContractZipFile.Id;
		attachSampleContractMaster.ContentType = 'application/msword';
		attachSampleContractMaster.IsPrivate = false;
		attachSampleContractMaster.Description = 'Test';

		insert new List<Attachment>{ attachSampleContractMaster };

        List<WordContentMaster__c> wordContrantMasters = new List<WordContentMaster__c>{
            new WordContentMaster__c(
                ZipFileMasterId__c = sampleContractZipFile.Id,
                KeyToReplace__c = null,
                ObjectToQuery__c = 'Main',
                FieldToQuery__c = 'ContractNumber',
                ConditionToQuery__c = null,
                LookupFieldToQuery__c = null,
                WordContentExternalKey__c = (sampleContractZipFile.Id + '_1_1'),
                FormatType__c = 'FIELD',
                DocumentPathName__c = 'word/document.xml'
            ),
            new WordContentMaster__c(
                ZipFileMasterId__c = sampleContractZipFile.Id,
                KeyToReplace__c = null,
                ObjectToQuery__c = 'Main',
                FieldToQuery__c = 'Account.Name',
                ConditionToQuery__c = null,
                LookupFieldToQuery__c = null,
                WordContentExternalKey__c = (sampleContractZipFile.Id + '_2_2'),
                FormatType__c = 'FIELD',
                DocumentPathName__c = 'word/document.xml'
            ),
            new WordContentMaster__c(
                ZipFileMasterId__c = sampleContractZipFile.Id,
                KeyToReplace__c = null,
                ObjectToQuery__c = 'Order',
                FieldToQuery__c = 'EffectiveDate,EndDate',
                ConditionToQuery__c = 'EffectiveDate != NULL ORDER BY ContractId',
                LookupFieldToQuery__c = 'ContractId',
                WordContentExternalKey__c = (sampleContractZipFile.Id + '_5_7'),
                FormatType__c = 'LOOPRELATEDOBJECT',
                DocumentPathName__c = 'word/document.xml'
            ),
            new WordContentMaster__c(
                ZipFileMasterId__c = sampleContractZipFile.Id,
                KeyToReplace__c = 'ContractTerm <= 12',
                ObjectToQuery__c = 'Main',
                FieldToQuery__c = 'ContractTerm',
                ConditionToQuery__c = null,
                LookupFieldToQuery__c = null,
                WordContentExternalKey__c = (sampleContractZipFile.Id + '_10_17'),
                FormatType__c = 'IFF',
                DocumentPathName__c = 'word/document.xml'
            ),
            new WordContentMaster__c(
                ZipFileMasterId__c = sampleContractZipFile.Id,
                KeyToReplace__c = 'Account.jpg',
                ObjectToQuery__c = 'Main',
                FieldToQuery__c = 'AccountId',
                ConditionToQuery__c = null,
                LookupFieldToQuery__c = null,
                WordContentExternalKey__c = (sampleContractZipFile.Id + '_26_28'),
                FormatType__c = 'IMAGEOBJECT',
				SourceObject__c = 'Account',
				SourceField__c = 'AccountId',
                DocumentPathName__c = 'word/document.xml'
            ),
            new WordContentMaster__c(
                ZipFileMasterId__c = sampleContractZipFile.Id,
                KeyToReplace__c = 'Layout_[FIELDS:Contract.ContractNumber/].jpg',
                ObjectToQuery__c = 'Order',
                FieldToQuery__c = 'Id, Contract.ContractNumber',
                ConditionToQuery__c = null,
                LookupFieldToQuery__c = 'ContractId',
                WordContentExternalKey__c = (sampleContractZipFile.Id + '_30_32'),
                FormatType__c = 'IMAGELOOPRELATEDOBJECT',
				SourceObject__c = 'Order',
				SourceField__c = 'Id',
                DocumentPathName__c = 'word/document.xml'
            )
        };
        insert wordContrantMasters;

		List<DocumentTemplateMapping__mdt> docTemplateMdts = [
			SELECT Id, DocumentTemplateName__c, IsActive__c, Language__c, ObjectName__c, TemplateMappingType__c
			FROM DocumentTemplateMapping__mdt
			WHERE DocumentTemplateName__c =: sampleContractZipFileName
				AND IsActive__c = true
		];
		Map<String, DocumentTemplateMapping__mdt> docTemplateMdtMapByDocTemplateName = new Map<String, DocumentTemplateMapping__mdt>();
		for(DocumentTemplateMapping__mdt docTemplateMdt : docTemplateMdts) {
			docTemplateMdtMapByDocTemplateName.put(docTemplateMdt.DocumentTemplateName__c, docTemplateMdt);
		}

		ZipFile__c sampleContractMergeZipFile = new ZipFile__c(
			Name = sampleContractZipFileName,
			RecordTypeId = ZipUtility.getInstance().MERGE_DATA_RECORDTYPE
		);
		insert sampleContractMergeZipFile;

		Attachment attachSampleContractMerge = new Attachment();
		attachSampleContractMerge.Name = 'word/document.xml';
		attachSampleContractMerge.Body = attachSampleContractMaster.Body;
		attachSampleContractMerge.ParentId = sampleContractMergeZipFile.Id;
		attachSampleContractMerge.ContentType = 'application/msword';
		attachSampleContractMerge.IsPrivate = false;
		attachSampleContractMerge.Description = 'Test';
		insert attachSampleContractMerge;

		DocumentDetailWrapper documentDetailWrapper = new DocumentDetailWrapper();
		documentDetailWrapper.RecordId = contract.Id;
		documentDetailWrapper.ObjectAPIName = 'Contract';
		documentDetailWrapper.RunningNumber = '00000100 United Oil & Gas Corp.';
		// documentDetailWrapper.MapDocumentTemplate = docTemplateMdtMapByDocTemplateName;
		documentDetailWrapper.DocumentTemplateMappingMDT = docTemplateMdtMapByDocTemplateName.get(sampleContractZipFileName);
		documentDetailWrapper.DocumentName = sampleContractZipFileName;
		documentDetailWrapper.DocumentId = sampleContractMergeZipFile.Id;
		// documentDetailWrapper.TableRowToRemoves = new List<Integer>{2,4};

		Map<String, String> results = WordContentUtility.getInstance().generateDocx(
			JSON.serialize(documentDetailWrapper)
		);

		System.assertEquals(1, results.keySet().size());
		for (String key : results.keySet()) {
			System.assertEquals(sampleContractMergeZipFile.Id, key);
		}
		System.assertEquals('00000100 United Oil & Gas Corp.', results.get(sampleContractMergeZipFile.Id));
	}

	// @isTest
	// static void getRelationRIdMapByImageNameTest(){
    //     Attachment relsAttachment = new Attachment();
    //     relsAttachment.Name = 'document.xml.rels';
    //     relsAttachment.Body = Blob.valueOf(
    //         '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    //         '<Relationships>' +
    //         '<Relationship Id="rId7" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/ROImage_SD_6_0610.jpg" />' +
    //         '<Relationship Id="rId8" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/ROImage_SD_6_0611.jpg" />' +
    //         '</Relationships>'
    //     );
    //     MyClass instance = new MyClass();
    //     Map<String, String> result = instance.getRelationRIdMapByImageName(relsAttachment);

    //     // Step 3: Perform assertions to verify the behavior
    //     System.assertEquals(2, result.size(), 'There should be 2 relationships parsed.');
    //     System.assertEquals('rId7', result.get('ROImage_SD_6_0610.jpg'), 'The first image name should map to rId7.');
    //     System.assertEquals('rId8', result.get('ROImage_SD_6_0611.jpg'), 'The second image name should map to rId8.');
	// }

}