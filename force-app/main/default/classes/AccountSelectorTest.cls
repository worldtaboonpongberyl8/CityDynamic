@isTest
public with sharing class AccountSelectorTest {
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
		Contact contact2 = dataMaker.createContact(account.Id, 'Tim', 'Duncan', 'td@gmail.com.invalid', '0111111112');
		List<Contact> contacts = new List<Contact>{contact1,contact2};
		insert contacts;
	}

	@isTest
	static void getAccountWithContactsMapByIdTest(){
		Test.startTest();
		AccountSelector accountSelector = new AccountSelector();
		Account account = [SELECT Id FROM Account LIMIT 1];
		Map<Id, Account> accountWithContactsMapById = accountSelector.getAccountWithContactsMapById(new Set<Id>{account.Id});
		System.assertEquals(account.Id, accountWithContactsMapById.get(account.Id).Id);
		Account targetAccount = accountWithContactsMapById.get(account.Id);
		List<Contact> targetContacts = targetAccount.Contacts;
		List<Contact> contacts = [SELECT Id FROM Contact];
		for (Integer i = 0; i < contacts.size() ; i++){
			System.assertEquals(contacts[i].Id, targetContacts[i].Id);
		}
		Test.stopTest();
	}

	@isTest
	static void getLastCreatedAccountWithContactsMapByIdTest(){
		Test.startTest();
		AccountSelector accountSelector = new AccountSelector();
		Account account = [SELECT Id FROM Account LIMIT 1];
		Map<Id, Account> accountWithContactsMapById = accountSelector.getLastCreatedAccountWithContactsMapById();
		System.assertNotEquals(null, accountWithContactsMapById);
		Test.stopTest();
	}
}