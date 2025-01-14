@isTest
public with sharing class LeadSelectorTest {
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
            dataMaker.addQueueToSObject(chineseQueue.Id , 'Lead'),
            dataMaker.addQueueToSObject(nonChineseQueue.Id , 'Lead')
        };
        insert queueSObjects;
    }

    @isTest 
    static void getLeadsOwnedByQueuesTest(){
        Test.startTest();
        DataMaker dataMaker = DataMaker.getInstance();
        Group chineseQueue = [SELECT Id FROM Group WHERE Name = 'Chinese' LIMIT 1];
        List<Lead> leadList = new List<Lead>{
            dataMaker.createLead('Tony', 'Parker', 'SAS', chineseQueue.Id,'China'),
            dataMaker.createLead('Tim', 'Duncan', 'SAS', chineseQueue.Id,'China'),
            dataMaker.createLead('Patty', 'Mills', 'SAS', chineseQueue.Id,'China'),
            dataMaker.createLead('Keldon', 'Johnson', 'SAS', chineseQueue.Id,'China'),
            dataMaker.createLead('Devin', 'Vassel', 'SAS', chineseQueue.Id,'China')
        };
        insert leadList;
        LeadSelector leadSelector = LeadSelector.getInstance();
        List<Lead> leadsOwnedByQueue = leadSelector.getLeadsOwnedByQueues();
        System.assertEquals(leadList.size(), leadsOwnedByQueue.size());
        Test.stopTest();
    }

    @isTest 
    static void getLeadsMapByQueueIdTest(){
        Test.startTest();
        DataMaker dataMaker = DataMaker.getInstance();
        Group chineseQueue = [SELECT Id FROM Group WHERE Name = 'Chinese' LIMIT 1];
        List<Lead> leadList = new List<Lead>{
            dataMaker.createLead('Tony', 'Parker', 'SAS', chineseQueue.Id,'China'),
            dataMaker.createLead('Tim', 'Duncan', 'SAS', chineseQueue.Id,'China'),
            dataMaker.createLead('Patty', 'Mills', 'SAS', chineseQueue.Id,'China'),
            dataMaker.createLead('Keldon', 'Johnson', 'SAS', chineseQueue.Id,'China'),
            dataMaker.createLead('Devin', 'Vassel', 'SAS', chineseQueue.Id,'China')
        };
        insert leadList;
        LeadSelector leadSelector = LeadSelector.getInstance();
        Map<Id, List<Lead>> leadsMapByQueue = leadSelector.getLeadsMapByQueueId(new Set<Id>{chineseQueue.Id});
        System.assertEquals(leadList.size(), leadsMapByQueue.get(chineseQueue.Id).size());
        Group nonChineseQueue = [SELECT Id FROM Group WHERE Name = 'NonChinese' LIMIT 1];
        List<Lead> leadListNonChinese = new List<Lead>{
            dataMaker.createLead('Russell', 'Westbrook', 'OKC', nonChineseQueue.Id,'Thailand'),
            dataMaker.createLead('Kevin', 'Durant', 'OKC', nonChineseQueue.Id,'Thailand'),
            dataMaker.createLead('Serge', 'Ibaka', 'OKC', nonChineseQueue.Id,'Thailand'),
            dataMaker.createLead('James', 'Harden', 'OKC', nonChineseQueue.Id,'Thailand'),
            dataMaker.createLead('Steven', 'Adam', 'OKC', nonChineseQueue.Id,'Thailand')
        };
        insert leadListNonChinese;
        Map<Id, List<Lead>> leadsMapByQueueNonChinese = leadSelector.getLeadsMapByQueueId(new Set<Id>{nonChineseQueue.Id});
        System.assertEquals(leadList.size(), leadsMapByQueueNonChinese.get(nonChineseQueue.Id).size());
        Test.stopTest();
    }

	@isTest 
    static void getLeadMapByIdTest(){
        Test.startTest();
        DataMaker dataMaker = DataMaker.getInstance();
        Group chineseQueue = [SELECT Id FROM Group WHERE Name = 'Chinese' LIMIT 1];
        List<Lead> leadList = new List<Lead>{
            dataMaker.createLead('Tony', 'Parker', 'SAS', chineseQueue.Id,'China'),
            dataMaker.createLead('Tim', 'Duncan', 'SAS', chineseQueue.Id,'China'),
            dataMaker.createLead('Patty', 'Mills', 'SAS', chineseQueue.Id,'China'),
            dataMaker.createLead('Keldon', 'Johnson', 'SAS', chineseQueue.Id,'China'),
            dataMaker.createLead('Devin', 'Vassel', 'SAS', chineseQueue.Id,'China')
        };
        insert leadList;
		Set<Id> leadIds = new Set<Id>();
		for (Lead lead : [SELECT Id FROM Lead]){
			leadIds.add(lead.Id);
		}
        LeadSelector leadSelector = LeadSelector.getInstance();
        Map<Id, Lead> leadMapById = leadSelector.getLeadMapById(leadIds);
        System.assertEquals(leadList.size(), leadMapById.values().size());
        Test.stopTest();
    }
}