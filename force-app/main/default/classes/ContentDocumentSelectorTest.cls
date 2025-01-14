@isTest
public class ContentDocumentSelectorTest {
    @isTest
    static void getContentDocumentByIdTest() {
        Test.startTest();
        DataMaker dataMaker = DataMaker.getInstance();
        ContentVersion testContentVersion = dataMaker.createContentVersion('File Name','sample.jpg');
        insert testContentVersion;
        ContentVersion contentVersion = [SELECT Id,Title, ContentDocumentId FROM ContentVersion WHERE Id =: testContentVersion.Id];
        Set<Id> contentDocIds = new Set<Id>();
        contentDocIds.add(contentVersion.ContentDocumentId);
 
        ContentDocumentSelector contentDocSelector = ContentDocumentSelector.getInstance();
        Map<Id,ContentDocument> contentDocMap = contentDocSelector.getContentDocumentById(contentDocIds);
        ContentDocument contentDoc = contentDocMap.get(contentVersion.ContentDocumentId);
        System.assertEquals(contentDoc.Title , TestContentVersion.Title);
        Test.stopTest();

    }
}