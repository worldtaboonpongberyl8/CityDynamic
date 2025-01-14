@isTest
public with sharing class UserSelectorTest {
	@TestSetup
    static void makeData() {
        DataMaker dataMaker = DataMaker.getInstance();
        // insert User
        List<User> userList = new List<User>{
            dataMaker.createUser(
                'ChineseSales1',
                'Chinese1',
                'ChineseSales1@gmail.com.invalid',
                'Senior Sales Executive'
            ),
            dataMaker.createUser(
                'ChineseSales2',
                'Chinese2',
                'ChineseSales2@gmail.com.invalid',
                'Senior Sales Executive'
            ),
            dataMaker.createUser(
                'NonChineseSales',
                'NonChinese',
                'NonChineseSales@gmail.com.invalid',
                'Senior Sales Executive'
            ),
            dataMaker.createUser(
                'NonChineseSales2',
                'NonChinese2',
                'NonChineseSales2@gmail.com.invalid',
                'Senior Sales Executive'
            )
        };
        insert userList;
    }

	@isTest
	static void getUserByIdTest(){
		Test.startTest();
		User selectedUser = [SELECT Id FROM User WHERE LastName = 'Chinese1' LIMIT 1];
		UserSelector selector = UserSelector.getInstance();
		User targetUser = selector.getUserById(selectedUser.Id);
		System.assertEquals(selectedUser.Id, targetUser.Id);
		Test.stopTest();
	}

	@isTest
	static void getUserMapByIdTest(){
		Test.startTest();
		User selectedUser = [SELECT Id FROM User WHERE LastName = 'Chinese1' LIMIT 1];
		UserSelector selector = UserSelector.getInstance();
		Map<Id,User> targetUserMapById = selector.getUserMapById(new Set<Id>{selectedUser.Id});
		System.assertEquals(selectedUser.Id, targetUserMapById.get(selectedUser.Id).Id);
		Test.stopTest();
	}
}