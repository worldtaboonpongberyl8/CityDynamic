public with sharing class ContactSelector {
    public static ContactSelector instance;
    public static ContactSelector getInstance() {
        if (instance == null) {
            instance = new ContactSelector();
        }
        return instance;
    }

    public Contact getDummy() {
        return [
			SELECT Id
			FROM Contact
			WHERE IsDummy__c = true
			LIMIT 1
		];
	}
}