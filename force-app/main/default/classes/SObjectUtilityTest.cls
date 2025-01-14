@isTest
private class SObjectUtilityTest {
	@TestSetup
	static void makeData(){

		Id recordTypeId = Schema.getGlobalDescribe()
			.get('Account')
			.getDescribe()
			.getRecordTypeInfosByName()
			.get('Co-Owner - Corporate')
			.getRecordTypeId();
		Account account = DataMaker.getInstance().createAccount(recordTypeId, 'Test Account');
		insert account;
		Contact contact1 = DataMaker.getInstance().createContact(account.Id, 'Tony', 'Parker', 'tp@gmail.com.invalid', '0111111111');
		contact1.IsPrimaryContact__c = true;
		Contact contact2 = DataMaker.getInstance().createContact(account.Id, 'Tim', 'Duncan', 'td@gmail.com.invalid', '0111111112');
		contact2.IsPrimaryContact__c = false;
		List<Contact> contacts = new List<Contact>{contact1,contact2};
		insert contacts;
	}
	@isTest
	static void querySObjectTest() {
			Account testAccount = [SELECT Id , Name FROM Account LIMIT 1];
			String fieldTxt = 'Id, Name';
			String objectApiName = 'Account';
			String condition = ''; // No condition

			SObject result = SObjectUtility.getInstance().querySObject(fieldTxt, objectApiName, condition);
			System.assertNotEquals(null, result, 'The result should not be null');
			System.assertEquals(testAccount.Id, result.get('Id'), 'The queried account ID should match the inserted test account ID');
			System.assertEquals('Test Account', result.get('Name'), 'The queried account name should match the inserted test account name');

	}
	@isTest
	static void querySObjectsTest() {
			Account testAccount = [SELECT Id , Name FROM Account LIMIT 1];
			String fieldTxt = 'Id, Name';
			String objectApiName = 'Account';
			String condition = ''; // No condition

			List<SObject> results = SObjectUtility.getInstance().querySObjects(fieldTxt, objectApiName, condition);
			System.assertNotEquals(null, results, 'The result should not be null');
			System.assertEquals(testAccount.Id, results[0].get('Id'), 'The queried account ID should match the inserted test account ID');
			System.assertEquals('Test Account', results[0].get('Name'), 'The queried account name should match the inserted test account name');

	}
	@isTest
	static void queryRelatedSObjectsTest(){
		Account testAccount = [SELECT Id , Name FROM Account LIMIT 1];
		List<Contact> testContacts = [SELECT Id FROM Contact WHERE AccountId =:testAccount.Id];
		String fieldTxt = 'Id, FirstName, LastName, AccountId';
        String objectApiName = 'Contact';
        String condition = ''; // No condition
        
        List<SObject> results = SObjectUtility.getInstance().queryRelatedSObjects(fieldTxt, objectApiName, condition);
        System.assertNotEquals(null, results, 'The results should not be null');
        System.assertEquals(2, results.size(), 'There should be two contact records returned');
	}
	@isTest
	static void getRecordFieldValueTest(){
		Account testAccount = [SELECT Id , Name FROM Account LIMIT 1];
		List<Contact> testContacts = [SELECT Id,FirstName FROM Contact WHERE AccountId =:testAccount.Id];
		String field = 'FirstName';
        String result = SObjectUtility.getInstance().getRecordFieldValue(testContacts[0], field);
        System.assertEquals('Tony', result, 'The FirstName field should return "Tony"');

        // Step 3: Test related field retrieval (e.g., Account.Name from Contact)
        field = 'Account.Name';
        Contact testContact = [SELECT Id, FirstName, LastName, Account.Name FROM Contact WHERE Id = :testContacts[0].Id];
        result = SObjectUtility.getInstance().getRecordFieldValue(testContact, field);
        System.assertEquals('Test Account', result, 'The related Account.Name field should return "Test Account"');

	}
}