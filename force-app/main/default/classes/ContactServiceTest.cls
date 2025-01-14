@isTest
public with sharing class ContactServiceTest {
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
		Contact contact2 = dataMaker.createContact(account.Id, 'Tim', 'Duncan', 'td@gmail.com.invalid', '0111111112');
		contact2.IsPrimaryContact__c = false;
		List<Contact> contacts = new List<Contact>{contact1,contact2};
		insert contacts;
	}

	@isTest
	static void unsetPrimaryContactFromOthersTest(){
		Test.startTest();
		ContactService service = ContactService.getInstance();
		List<Contact> contacts = [SELECT Id, IsPrimaryContact__c,AccountId FROM Contact];
		List<Contact> filteredContacts = new List<Contact>();
		for (Contact contact : contacts){
			if (contact.IsPrimaryContact__c == false){
				contact.IsPrimaryContact__c = true;
				filteredContacts.add(contact);
			}
		}
		List<Contact> updatedContacts = service.unsetPrimaryContactFromOthers(filteredContacts);
		for (Contact updatedContact : updatedContacts){
			if (updatedContact.FirstName == 'Tony'){
				System.assertEquals(false, updatedContact.IsPrimaryContact__c);
			}
		}
		Test.stopTest();
	}

}