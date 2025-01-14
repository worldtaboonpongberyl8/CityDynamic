@isTest
private class EmailTemplateSelectorTest {
    @TestSetup
    static void makeData(){
        DataMaker dataMaker = DataMaker.getInstance();
        EmailTemplate testEmailTemplate = dataMaker.createEmailTemplate('Test Email Template','DevelopmentEmailTemplate','text','Test Email Template');
        insert testEmailTemplate;
    }
    @IsTest
    static void getByDeveloperNameTest() {
        Test.startTest();
        EmailTemplate testEmailTemplate = [SELECT Id , Name,DeveloperName FROM EmailTemplate LIMIT 1];
        List<EmailTemplate> results = EmailTemplateSelector.getInstance().getByDeveloperName(new Set<String>{testEmailTemplate.DeveloperName});
        System.assertEquals(testEmailTemplate.DeveloperName, results[0].DeveloperName);
        Test.stopTest();
    }
}