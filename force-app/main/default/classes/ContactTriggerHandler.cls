public with sharing class ContactTriggerHandler {

    public static ContactTriggerHandler instance;
    public static ContactTriggerHandler getInstance() {
        if (instance == null) {
            instance = new ContactTriggerHandler();
        }
        return instance;
    }

    public Boolean isActive = true;
    public List<Contact> newRecords;
    public Map<Id, Contact> oldMap;

    public Boolean isTriggerActivated() {
        if (TriggerActivation__mdt.getInstance('ContactTrigger') != null) {
            return this.isActive && TriggerActivation__mdt.getInstance('ContactTrigger').isActive__c;
        }
        return this.isActive;
    }

    public void setParams(List<Contact> newRecords, Map<Id, Contact> oldMap) {
        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }

    public void setBypass() {
        this.isActive = false;
    }

    public void clearBypass() {
        this.isActive = true;
    }

	public void executeAfterInsert(){
		this.forceUpdateAccountAfterContactUpdate();
	}

	public void executeBeforeUpdate() {
		this.preventUpdateWhenInactive();
	}

    public void executeAfterUpdate() {
        this.unsetPrimaryContact();
		this.forceUpdateAccountAfterContactUpdate();
    }

	private void preventUpdateWhenInactive(){
		for (Contact contact : this.newRecords){
            Contact oldContact = this.oldMap.get(contact.Id);
			if(contact.LastIntegrationDateTime__c != oldContact.LastIntegrationDateTime__c){
				continue;
			}
            if (contact.Active__c == false && oldContact.Active__c == false ){
                contact.addError('Inactive Contact can not be updated');
            }
        }
	}

	private void unsetPrimaryContact(){
		ContactService service = ContactService.getInstance();
        List<Contact> filteredContact = new List<Contact>();
        for (Contact contact : this.newRecords){
            Contact oldContact = this.oldMap.get(contact.Id);
            if (contact.IsPrimaryContact__c != oldContact.IsPrimaryContact__c && contact.IsPrimaryContact__c == true){
                filteredContact.add(contact);
            }
        }
        if (!filteredContact.isEmpty()){
            List<Contact> updatedContact = service.unsetPrimaryContactFromOthers(filteredContact);
            if (!updatedContact.isEmpty()){
                update updatedContact;
            }
        }
	}

	private void forceUpdateAccountAfterContactUpdate(){
		AccountSelector accountSelector = AccountSelector.getInstance();
		Set<Id> accountIds = new Set<Id>();
		for (Contact contact : this.newRecords){
			accountIds.add(contact.AccountId);
		}
		Map<Id, Account> accountMapById = accountSelector.getAccountWithContactsMapById(accountIds);
		List<Account> accounts = accountMapById.values();
		if (!accounts.isEmpty()){
			AccountTriggerHandler accountTriggerHandler = AccountTriggerHandler.getInstance();
			accountTriggerHandler.setBypass();
			update accounts;
			accountTriggerHandler.clearBypass();
		}
	}
}