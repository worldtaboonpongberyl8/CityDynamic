public with sharing class AccountTriggerHandler {
    public static AccountTriggerHandler instance;
    public static AccountTriggerHandler getInstance() {
        if (instance == null) {
            instance = new AccountTriggerHandler();
        }
        return instance;
    }

    public Boolean isActive = true;
    public List<Account> newRecords;
    public Map<Id, Account> oldMap;

    public Boolean isTriggerActivated() {
        if (TriggerActivation__mdt.getInstance('AccountTrigger') != null) {
            return this.isActive && TriggerActivation__mdt.getInstance('AccountTrigger').isActive__c;
        }
        return this.isActive;
    }

    public void setParams(List<Account> newRecords, Map<Id, Account> oldMap) {
        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }

    public void setBypass() {
        this.isActive = false;
    }

    public void clearBypass() {
        this.isActive = true;
    }

	public void executeBeforeUpdate() {
		this.preventUpdateWhenInactive();
	}

	public void executeAfterUpdate() {
		this.deactivateAllContacts();
	}

	private void preventUpdateWhenInactive(){
		for (Account account : this.newRecords){
            Account oldAccount = this.oldMap.get(account.Id);
			if(account.LastIntegrationDateTime__c != oldAccount.LastIntegrationDateTime__c){
				continue;
			}
            if (account.Active__c == false && oldAccount.Active__c == false ){
                account.addError('Inactive Account can not be updated');
            }
        }
	}

	private void deactivateAllContacts(){
		ContactService contactService = ContactService.getInstance();
		AccountSelector accountSelector = AccountSelector.getInstance();
		Set<Id> accountIds = new Set<Id>();
		for (Account account : this.newRecords){
            Account oldAccount = this.oldMap.get(account.Id);
            if (account.Active__c != oldAccount.Active__c && account.Active__c == false){
                accountIds.add(account.Id);
            }
        }
		if (!accountIds.isEmpty()){
			Map<Id, Account> accountMapById = accountSelector.getAccountWithContactsMapById(accountIds);
			List<Account> accounts = accountMapById.values();
			List<Contact> deactivatedContacts = new List<Contact>();
			for (Account account : accounts){
				List<Contact> contacts = account.Contacts;
				deactivatedContacts.addAll(contactService.deactivateAllContacts(contacts));
			}
			if (!deactivatedContacts.isEmpty()){
				update deactivatedContacts;
			}
		}
	}
}