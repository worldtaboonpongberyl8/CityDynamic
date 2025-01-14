@isTest
public with sharing class WordContentControllerTest {
    @isTest
    public static void validateRecordIdtoGetDocumentTemplateTest() {
        DataMaker dataMaker = DataMaker.getInstance();

        String sampleContractZipFileName = 'Sample Contract.docx';

        NameFormattingMasterData__c runningNumberFormatDocument = new NameFormattingMasterData__c(
            ObjectName__c = 'Contract',
            RunningFormat__c = '{ContractNumber}_{Account.Name}',
            RunningPurpose__c = 'Document',
            Type__c = 'Format',
            CurrentRunningNumber__c = 1,
            DocumentTemplateMappingType__c = 'Contract'
        );
        insert new List<NameFormattingMasterData__c>{ runningNumberFormatDocument };

        Account account = new Account(Name = 'United Oil & Gas Corp.' , Phone = '0111111111');
        insert account;

        ContractTriggerHandler.getInstance().setBypass();
        Contract contract = new Contract(AccountId = account.Id);
        insert contract;
        ContractTriggerHandler.getInstance().clearBypass();

        Order order = new Order(
            AccountId = account.Id,
            ContractId = contract.Id,
            EffectiveDate = Date.newInstance(2024, 8, 1),
            EndDate = Date.newInstance(2025, 7, 31),
            Status = 'Draft'
        );
        insert order;
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Image';
        contentVersion.VersionData = Blob.valueOf('Image Data');
        contentVersion.PathOnClient = 'Image.jpg';
        insert contentVersion;
        ContentDocument contentDocument = [
            SELECT Id, Title
            FROM ContentDocument
            WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id)
            LIMIT 1
        ];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = contract.Id,
            ContentDocumentId = contentDocument.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert contentDocumentLink;

        StaticResource staticResource = [
            SELECT Id, ContentType, BodyLength, Body, Description
            FROM StaticResource
            WHERE Name = 'SampleContractWordRelsXML'
        ];

        ZipFile__c sampleContractZipFile = new ZipFile__c(
            Name = sampleContractZipFileName,
            RecordTypeId = ZipUtility.getInstance().MASTER_DATA_RECORDTYPE
        );
        insert new List<ZipFile__c>{ sampleContractZipFile };
        // WordContentMaster__c testWordContentMaster = dataMaker.createWordContentMester(sampleContractZipFile.Id);
        // testWordContentMaster.FormatType__c = 'IMAGELOOPRELATEDOBJECT';
        // testWordContentMaster.ObjectToQuery__c = 'Contract';
        // testWordContentMaster.FieldToQuery__c = 'FirstName,LastName';
        // testWordContentMaster.ConditionToQuery__c = '';
        // testWordContentMaster.LookupFieldToQuery__c = '';
        WordContentMaster__c testWordContentMaster = new WordContentMaster__c(
            ZipFileMasterId__c = sampleContractZipFile.Id,
            KeyToReplace__c = 'Image.jpg',
            ObjectToQuery__c = 'Main',
            FieldToQuery__c = 'Id,ContractNumber',
			SourceField__c = 'Id',
            ConditionToQuery__c = null,
            LookupFieldToQuery__c = null,
            WordContentExternalKey__c = (sampleContractZipFile.Id + '_1_1'),
            FormatType__c = 'IMAGEOBJECT',
            DocumentPathName__c = 'word/document.xml'
        );
        insert testWordContentMaster;

        String attachmentXml = staticResource.Body.toString().replace('a02dM000004mhJhQAI', sampleContractZipFile.Id);

        Attachment attachSampleContractMaster = new Attachment();
        attachSampleContractMaster.Name = 'word/_rels/document.xml.rels';
        attachSampleContractMaster.Body = Blob.valueOf(attachmentXml);
        attachSampleContractMaster.ParentId = sampleContractZipFile.Id;
        attachSampleContractMaster.ContentType = 'application/msword';
        attachSampleContractMaster.IsPrivate = false;
        attachSampleContractMaster.Description = 'Test';

        insert new List<Attachment>{ attachSampleContractMaster };

        List<DocumentDetailWrapper> results = WordContentController.validateRecordIdtoGetDocumentTemplate(
            contract.Id,
            'TH',
            'Contract',
            ''
        );
        System.assertEquals(1, results.size());

        DocumentDetailWrapper result = results.get(0);

        List<DocumentTemplateMapping__mdt> docTemplateMdts = [
            SELECT Id, DocumentTemplateName__c, IsActive__c, Language__c, ObjectName__c, TemplateMappingType__c
            FROM DocumentTemplateMapping__mdt
            WHERE DocumentTemplateName__c = :sampleContractZipFileName AND IsActive__c = TRUE
        ];
        Map<String, DocumentTemplateMapping__mdt> docTemplateMdtMapByDocTemplateName = new Map<String, DocumentTemplateMapping__mdt>();
        for (DocumentTemplateMapping__mdt docTemplateMdt : docTemplateMdts) {
            docTemplateMdtMapByDocTemplateName.put(docTemplateMdt.DocumentTemplateName__c, docTemplateMdt);
        }

        Zipfile__c zipFileMerge = [
            SELECT Id, Name, RecordTypeId
            FROM ZipFile__c
            WHERE Name = :sampleContractZipFileName AND RecordTypeId = :ZipUtility.getInstance().MERGE_DATA_RECORDTYPE
            LIMIT 1
        ];

        System.assertEquals(contract.Id, result.RecordId);
        System.assertEquals('Contract', result.ObjectAPIName);
        System.assertEquals(zipFileMerge.Id, result.DocumentId);
        System.assertEquals(sampleContractZipFileName, result.DocumentName);
        System.assertEquals('', result.ErrorMessage);
        System.assertNotEquals(null, result.DocumentTemplateMappingMDT);
        System.assertEquals('', result.ParamInput);
        // System.assertEquals('SPA-00100011_United Oil [AMPERSAND] Gas Corp.', result.RunningNumber);
        // System.assertEquals(new List<Integer>{1,3,5}, result.TableRowToRemoves);
    }
}