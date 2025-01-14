@isTest
public with sharing class AccountTriggerHandlerTest {

	@isTest
	static void updateAccountTest(){
		DataMaker dataMaker = DataMaker.getInstance();
        // Creat Account
        Id recordTypeId = Schema.getGlobalDescribe()
            .get('Account')
            .getDescribe()
            .getRecordTypeInfosByName()
            .get('Co-Owner - Corporate')
            .getRecordTypeId();
        Account account = dataMaker.createAccount(recordTypeId, 'Test Account');
		account.Active__c = true;
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
		Test.startTest();
		Account targetAccount = [SELECT Id,Phone,Active__c FROM Account WHERE Id =: account.Id];
		targetAccount.Active__c = false;
		update targetAccount;
		Test.stopTest();
		Account updatedAccount = [SELECT Id,Active__c FROM Account WHERE Id =: targetAccount.Id];
		Contact updatedContact1 = [SELECT Id,Active__c FROM Contact WHERE Id =: contact1.Id];
		Contact updatedContact2 = [SELECT Id,Active__c FROM Contact WHERE Id =: contact2.Id];
		System.assertEquals(false, updatedAccount.Active__c);
		System.assertEquals(false, updatedContact1.Active__c);
		System.assertEquals(false, updatedContact2.Active__c);
	}

	@isTest
    static void setBypassTest() {
        Test.startTest();
        AccountTriggerHandler handler = AccountTriggerHandler.getInstance();
        handler.setBypass();
        System.assertEquals(false, handler.isActive);
        System.assertEquals(false, handler.isTriggerActivated());
        Test.stopTest();
    }

    @isTest
    static void clearBypassTest() {
        Test.startTest();
        AccountTriggerHandler handler = AccountTriggerHandler.getInstance();
        handler.clearBypass();
        System.assertEquals(true, handler.isActive);
        System.assertEquals(true, handler.isTriggerActivated());
        Test.stopTest();
    }
}