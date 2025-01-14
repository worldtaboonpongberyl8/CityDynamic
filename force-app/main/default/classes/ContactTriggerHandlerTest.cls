@isTest
public with sharing class ContactTriggerHandlerTest {
    @TestSetup
    static void makeData(){
        DataMaker dataMaker = DataMaker.getInstance();
        // Creat Account
        Id recordTypeId = Schema.getGlobalDescribe()
            .get('Account')
            .getDescribe()
            .getRecordTypeInfosByName()
            .get('Co-Owner - Corporate')
            .getRecordTypeId();
        Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
        insert account;
        // Create Contact
        Contact contact1 = dataMaker.createContact(account.Id, 'Tony', 'Parker', 'tp@gmail.com.invalid', '0111111111');
        contact1.IsPrimaryContact__c = true;
		contact1.Active__c = true;
        Contact contact2 = dataMaker.createContact(account.Id, 'Tim', 'Duncan', 'td@gmail.com.invalid', '0111111112');
        contact2.IsPrimaryContact__c = false;
		contact2.Active__c = true;
        List<Contact> contacts = new List<Contact>{contact1,contact2};
        insert contacts;
    }

    @isTest
    static void triggerUpdateTest(){
        Test.startTest();
        Contact targetContact = [SELECT Id,AccountId FROM Contact WHERE FirstName = 'Tim' LIMIT 1];
        targetContact.IsPrimaryContact__c = true;
        update targetContact;
        List<Contact> contacts = [SELECT Id,IsPrimaryContact__c,FirstName FROM Contact];
        for (Contact contact : contacts){
            if (contact.FirstName == 'Tony'){
                System.assertEquals(false, contact.IsPrimaryContact__c);
            }
            if (contact.FirstName == 'Tim'){
                System.assertEquals(true, contact.IsPrimaryContact__c);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void setBypassTest() {
        Test.startTest();
        ContactTriggerHandler handler = ContactTriggerHandler.getInstance();
        handler.setBypass();
        System.assertEquals(false, handler.isActive);
        System.assertEquals(false, handler.isTriggerActivated());
        Test.stopTest();
    }

    @isTest
    static void clearBypassTest() {
        Test.startTest();
        ContactTriggerHandler handler = ContactTriggerHandler.getInstance();
        handler.clearBypass();
        System.assertEquals(true, handler.isActive);
        System.assertEquals(true, handler.isTriggerActivated());
        Test.stopTest();
    }
}