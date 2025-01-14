@isTest
public with sharing class GroupSelectorTest {
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
    }

    @isTest
    static void getQueueMapByIdTest() {
        Test.startTest();
        GroupSelector groupSelector = GroupSelector.getInstance();
        List<Group> groups = [SELECT Id FROM Group WHERE Type = 'Queue'];
        Set<Id> groupIds = new Set<Id>();
        for (Group eachGroup : groups){
            groupIds.add(eachGroup.Id);
        }
        Map<Id, Group> queueMapById = groupSelector.getQueueMapById(groupIds);
        // System.assertEquals(groups.size(), queueMapById.keyset().size());
        Test.stopTest();
    }

    @isTest
    static void getQueueMapByDevNameTest(){
        Test.startTest();
        GroupSelector groupSelector = GroupSelector.getInstance();
        List<Group> groups = [SELECT Id,DeveloperName FROM Group WHERE Type = 'Queue'];
        Set<String> groupDevNames = new Set<String>();
        for (Group eachGroup : groups){
            groupDevNames.add(eachGroup.DeveloperName);
        }
        Map<String, Group> queueMapByDevName = groupSelector.getQueueMapByDevName(groupDevNames);
        // System.assertEquals(groups.size(), queueMapByDevName.keyset().size());
        Test.stopTest();
    }

    @isTest
    static void getQueueMembersMapByQueueIdTest() {
        Test.startTest();
        GroupSelector groupSelector = GroupSelector.getInstance();
        List<Group> groups = [SELECT Id FROM Group WHERE Type = 'Queue'];
        Set<Id> groupIds = new Set<Id>();
        for (Group eachGroup : groups){
            groupIds.add(eachGroup.Id);
        }
        Map<Id, List<GroupMember>> queueMembersMapByQueueId = groupSelector.getQueueMembersMapByQueueId(groupIds);
        // System.assertEquals(groups.size(), queueMembersMapByQueueId.keyset().size());
        Test.stopTest();
    }
}