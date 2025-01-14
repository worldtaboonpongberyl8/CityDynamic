@isTest
public with sharing class LeadServiceTest {
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
		// insert Group
		Group chineseQueue = dataMaker.createQueue('Chinese');
		insert chineseQueue;
		Group nonChineseQueue = dataMaker.createQueue('NonChinese');
		insert nonChineseQueue;
		// insert Group Member
		List<GroupMember> groupMember = new List<GroupMember>{
			dataMaker.addUserToQueue(userList[0].Id, chineseQueue.Id),
			dataMaker.addUserToQueue(userList[1].Id, chineseQueue.Id),
			dataMaker.addUserToQueue(userList[2].Id, nonChineseQueue.Id),
			dataMaker.addUserToQueue(userList[3].Id, nonChineseQueue.Id)
		};
		insert groupMember;
		// insert Group related with SObject
		List<QueueSObject> queueSObjects = new List<QueueSObject>{
			dataMaker.addQueueToSObject(chineseQueue.Id, 'Lead'),
			dataMaker.addQueueToSObject(nonChineseQueue.Id, 'Lead')
		};
		insert queueSObjects;
	}

	@isTest
	static void assignLeadCountryFromCountryCodeTest(){
		Test.startTest();
		LeadService service = LeadService.getInstance();
		List<Lead> leadsForTest = getLeadsForTest();
		List<Lead> leads = service.assignLeadCountryFromCountryCode(leadsForTest);
		for (Lead lead : leads){
			System.assertEquals('Foreign', lead.LeadCountry__c);
		}
		Test.stopTest();
	}

	@isTest
	static void assignLeadToQueueTest() {
		Test.startTest();
		LeadService service = LeadService.getInstance();
		List<Lead> leadsForTest = getLeadsForTest();
		List<Lead> clonedLeads = new List<Lead>();
		for (Lead lead : leadsForTest) {
			clonedLeads.add(lead.clone(false, true, true, true));
		}
		List<Lead> assignedLeads = service.assignLeadToQueue(leadsForTest);
		for (Integer i = 0; i < leadsForTest.size(); i++) {
			Lead assignedLead = assignedLeads.get(i);
			Lead oldLead = clonedLeads.get(i);
			if (assignedLead.LeadOrigin__c == 'Upload' || assignedLead.LeadOrigin__c == 'Web-to-Lead') {
				System.assertNotEquals(assignedLead.OwnerId, oldLead.OwnerId);
			} else {
				System.assertEquals(assignedLead.OwnerId, oldLead.OwnerId);
			}
		}
		Test.stopTest();
	}

	@isTest
	static void filterLeadOwnedByQueueTest() {
		Test.startTest();
		LeadService service = LeadService.getInstance();
		List<Lead> leadsForTest = getLeadsForTest();
		List<Lead> leadsAssignedToQueue = service.assignLeadToQueue(leadsForTest);
		Integer numberOfLeadOwnedByQueue = 0;
		for (Lead lead : leadsAssignedToQueue) {
			if (lead.OwnerId.toString().startsWith('00G')) {
				numberOfLeadOwnedByQueue++;
			}
		}
		List<Lead> leadsOwnedByQueue = service.filterLeadOwnedByQueue(leadsAssignedToQueue);
		System.assertEquals(numberOfLeadOwnedByQueue, leadsOwnedByQueue.size());
		Test.stopTest();
	}

	@isTest
	static void filterLeadNeededAutoAssignmentTest(){
		Test.startTest();
		LeadService service = LeadService.getInstance();
		List<Lead> leadsForTest = getLeadsForTest();
		List<Lead> leadsAssignedToQueue = service.assignLeadToQueue(leadsForTest);
		Integer numberOfLeadAutoAssigned = 0;
		for (Lead lead : leadsAssignedToQueue) {
			if (lead.IsAutoAssingment__c) {
				numberOfLeadAutoAssigned++;
			}
		}
		List<Lead> leadsAutoAssigned = service.filterLeadNeededAutoAssignment(leadsAssignedToQueue);
		System.assertEquals(numberOfLeadAutoAssigned, leadsAutoAssigned.size());
		Test.stopTest();
	}

	@isTest
	static void assignLeadInQueueByRoundRobinTest() {
		Test.startTest();
		LeadService service = LeadService.getInstance();
		List<Lead> leadsForTest = getLeadsForTest();
		List<Lead> leadsAssignedToQueue = service.assignLeadToQueue(leadsForTest);
		List<Lead> leadsOwnedByQueue = service.filterLeadOwnedByQueue(leadsAssignedToQueue);
		List<Lead> clonedLeadsOwnedByQueue = new List<Lead>();
		for (Lead lead : leadsOwnedByQueue) {
			clonedLeadsOwnedByQueue.add(lead.clone(false, true, true, true));
		}
		List<Lead> leadsAfterRoundRobinAssignment = service.assignLeadInQueueByRoundRobin(leadsOwnedByQueue);
		for (Integer i = 0; i < leadsOwnedByQueue.size(); i++) {
			if (leadsAfterRoundRobinAssignment.size() > i){
				Lead leadAfterRoundRobin = leadsAfterRoundRobinAssignment.get(i);
				Lead oldLead = clonedLeadsOwnedByQueue.get(i);
				System.assert(leadAfterRoundRobin.OwnerId.toString().startsWith('005'));
			}
		}
		List<RoundRobinAssignment__c> rrAssignements = [SELECT Id FROM RoundRobinAssignment__c];
		// System.assertNotEquals(0, rrAssignements.size());
		Test.stopTest();
	}

	@isTest
	static void assignLeadToQueueFuture(){
		Test.startTest();
		LeadTriggerHandler.getInstance().setBypass();
		List<Lead> leadsForTest = getLeadsForTest();
		insert leadsForTest;
		LeadTriggerHandler.getInstance().clearBypass();
		List<Lead> oldLeads = [SELECT Id,OwnerId FROM Lead];
		Set<Id> leadIds = new Set<Id>();
		for (Lead lead : leadsForTest){
			leadIds.add(lead.Id);
		}
		LeadService.assignLeadToQueueFuture(leadIds);
		Test.stopTest();
		List<Lead> leadsAfterRoundRobinAssignment = [SELECT Id,OwnerId,LeadOrigin__c FROM Lead];
		for (Integer i = 0; i < leadsForTest.size(); i++) {
			Lead leadAfterRoundRobin = leadsAfterRoundRobinAssignment.get(i);
			Lead oldLead = oldLeads.get(i);
			if (leadAfterRoundRobin.LeadOrigin__c == 'Upload'){
				System.assert(leadAfterRoundRobin.OwnerId.toString().startsWith('005'));
			}
		}
	}

	@isTest
	static void stampProjectFromProjectCodeTest(){
		Test.startTest();
		LeadService service = LeadService.getInstance();
		List<Lead> leadsForTest = getLeadsForTest();
		service.stampProjectFromProjectCode(leadsForTest);
		for (Lead lead : leadsForTest){
			System.assertEquals(null, lead.ProjectsInterest__c);
		}
		Test.stopTest();
	}

	private static List<Lead> getLeadsForTest() {
		DataMaker dataMaker = DataMaker.getInstance();
		return new List<Lead>{
			dataMaker.createLead('Tony', 'Parker', 'SAS', UserInfo.getUserId(), 'China'),
			dataMaker.createLead('Tim', 'Duncan', 'SAS', UserInfo.getUserId(), 'China'),
			dataMaker.createLeadAsUpload('Patty', 'Mills', 'SAS', UserInfo.getUserId(), 'China'),
			dataMaker.createLeadAsUpload('Keldon', 'Johnson', 'SAS', UserInfo.getUserId(), 'China'),
			dataMaker.createLeadAsUpload('Devin', 'Vassel', 'SAS', UserInfo.getUserId(), 'China'),
			dataMaker.createLead('Chet', 'Holmgren', 'OKC', UserInfo.getUserId(), 'Thailand'),
			dataMaker.createLead('Lugent', 'Dortz', 'OKC', UserInfo.getUserId(), 'Thailand'),
			dataMaker.createLeadAsUpload('Jaylen', 'William', 'OKC', UserInfo.getUserId(), 'Thailand'),
			dataMaker.createLeadAsUpload('Jaylin', 'William', 'OKC', UserInfo.getUserId(), 'Foreign')
		};
	}
}