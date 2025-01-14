@isTest
public with sharing class RoundRobinAssignmentSelectorTest {
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
			)
		};
		insert userList;
		// insert Round Robin Assignment
		List<RoundRobinAssignment__c> rrAssignments = new List<RoundRobinAssignment__c>{
			dataMaker.createRRAssignment('Chinese', userList[0].Id , 'Lead'),
			dataMaker.createRRAssignment('NonChinese', userList[1].Id , 'Lead')
		};
		insert rrAssignments;
	}

	@isTest
	static void getLeadRoundRobinAssignmentMapByQueueNameTest() {
		Test.startTest();
		RoundRobinAssignmentSelector rrAssignmentSelector = RoundRobinAssignmentSelector.getInstance();
		Map<String, RoundRobinAssignment__c> rrAssignmentMapByQueueName = rrAssignmentSelector.getLeadRoundRobinAssignmentMapByQueueName(
			new Set<String>{ 'Chinese' , 'NonChinese' }
		);
		System.assertEquals(2, rrAssignmentMapByQueueName.keyset().size());
		Test.stopTest();
	}
}