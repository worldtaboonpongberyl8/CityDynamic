public with sharing class ContactService {

    public static ContactService instance;
    public static ContactService getInstance(){
        if (instance == null){
            instance = new ContactService();
        }
        return instance;
    }

    public List<Contact> unsetPrimaryContactFromOthers(List<Contact> primaryContacts){
        AccountSelector accountSelector = AccountSelector.getInstance();
        Set<Id> accountIds = new Set<Id>();
        List<Contact> updatedContact = new List<Contact>();
        for (Contact primaryContact : primaryContacts){
            accountIds.add(primaryContact.AccountId);
        }
        Map<Id, Account> accountWithContactsMapById = accountSelector.getAccountWithContactsMapById(accountIds);
        for (Contact primaryContact : primaryContacts){
            Account targetAccount = accountWithContactsMapById.get(primaryContact.AccountId);
            List<Contact> targetContacts = targetAccount.Contacts == null ? new List<Contact>() : targetAccount.Contacts;
            for (Contact targetContact : targetContacts){
                if (targetContact.Id != primaryContact.Id && targetContact.IsPrimaryContact__c == true){
                    targetContact.IsPrimaryContact__c = false;
                    updatedContact.add(targetContact);
                }
            }
        }
        return updatedContact;
    }

	public List<Contact> deactivateAllContacts(List<Contact> contacts){
		for (Contact contact : contacts){
			if (contact.Active__c == true){
				contact.Active__c = false;
			}
		}
		return contacts;
	}
}