@isTest
public with sharing class LeadTriggerHandlerTest {
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
        Group chineseQueue = dataMaker.createQueue('Sales_Chinese_Group');
        insert chineseQueue;
        Group nonChineseQueue = dataMaker.createQueue('Sales_Group');
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
    static void insertLeadTest() {
        Test.startTest();
        DataMaker dataMaker = DataMaker.getInstance();
        LeadService leadService = LeadService.getInstance();
        // ------------------ Assign Lead To Queue Chinese ------------------
        Group chineseQueue = [SELECT Id FROM Group WHERE Name = 'Sales_Chinese_Group' LIMIT 1];
        List<Lead> leadList = new List<Lead>{
            dataMaker.createLead('Tony', 'Parker', 'SAS', UserInfo.getUserId(),'China'),
            dataMaker.createLead('Tim', 'Duncan', 'SAS', UserInfo.getUserId(),'China'),
            dataMaker.createLeadAsUpload('Patty', 'Mills', 'SAS', UserInfo.getUserId(),'China'),
            dataMaker.createLeadAsUpload('Keldon', 'Johnson', 'SAS', UserInfo.getUserId(),'China'),
            dataMaker.createLeadAsUpload('Devin', 'Vassel', 'SAS', UserInfo.getUserId(),'China')
        };
        insert leadList;
        List<Lead> leadsOwnedByQueue = [
            SELECT Id, OwnerId,ProjectsInterest__c
            FROM Lead
            WHERE OwnerId IN (SELECT Id FROM Group WHERE Id = :chineseQueue.Id)
        ];
        List<Lead> updatedLead = leadService.assignLeadInQueueByRoundRobin(leadsOwnedByQueue);
        List<GroupMember> groupMembers = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :chineseQueue.Id];
        Integer startIndex = 0;
        for (Lead lead : updatedLead) {
            Integer currentIndex = Math.mod(startIndex, groupMembers.size());
            System.assertEquals(groupMembers[currentIndex].UserOrGroupId, lead.OwnerId);
			System.assertEquals(null, lead.ProjectsInterest__c);
            startIndex++;
        }
        // ------------------ Assign New Leads To Queue Chinese Again------------------
        List<Lead> leadList2 = new List<Lead>{
            dataMaker.createLead('Manu', 'Ginobilli', 'SAS', UserInfo.getUserId(),'China'),
            dataMaker.createLeadAsUpload('Boris', 'Diaw', 'SAS', UserInfo.getUserId(),'China')
        };
        insert leadList2;
        List<Lead> leadsOwnedByQueue2 = [
            SELECT Id, OwnerId
            FROM Lead
            WHERE OwnerId IN (SELECT Id FROM Group WHERE Id = :chineseQueue.Id)
        ];
        
        // ------------------ Assign Lead To Queue Non Chinese ------------------
        Group nonChineseQueue = [SELECT Id FROM Group WHERE Name = 'Sales_Group' LIMIT 1];
        List<Lead> leadListNonChinese = new List<Lead>{
            dataMaker.createLead('Russell', 'Westbrook', 'OKC', UserInfo.getUserId(),'Thailand'),
            dataMaker.createLead('Kevin', 'Durant', 'OKC', UserInfo.getUserId(),'Thailand'),
            dataMaker.createLeadAsUpload('Serge', 'Ibaka', 'OKC', UserInfo.getUserId(),'Thailand'),
            dataMaker.createLeadAsUpload('James', 'Harden', 'OKC', UserInfo.getUserId(),'Thailand'),
            dataMaker.createLeadAsUpload('Steven', 'Adam', 'OKC', UserInfo.getUserId(),'Thailand')
        };
        insert leadListNonChinese;
        List<Lead> leadsOwnedByQueueNonChinese = [
            SELECT Id, OwnerId,ProjectsInterest__c
            FROM Lead
            WHERE OwnerId IN (SELECT Id FROM Group WHERE Id = :nonChineseQueue.Id)
        ];
        List<Lead> updatedLeadNonChinese = leadService.assignLeadInQueueByRoundRobin(leadsOwnedByQueueNonChinese);
        List<GroupMember> groupMembersNonChinese = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :nonChineseQueue.Id];
        Integer startIndexNonChinese = 0;
        for (Lead lead : updatedLeadNonChinese) {
            Integer currentIndex = Math.mod(startIndexNonChinese, groupMembersNonChinese.size());
            System.assertEquals(groupMembersNonChinese[currentIndex].UserOrGroupId, lead.OwnerId);
			System.assertEquals(null, lead.ProjectsInterest__c);
            startIndexNonChinese++;
        }
        // ------------------ Assign New Lead To Queue Non Chinese Again ------------------
        Group nonChineseQueue2 = [SELECT Id FROM Group WHERE Name = 'Sales_Group' LIMIT 1];
        User user = [SELECT Id FROM User WHERE Username = 'NonChineseSales@gmail.com.invalid' LIMIT 1];
        List<Lead> leadListNonChinese2 = new List<Lead>{
            dataMaker.createLead('Chet', 'Holmgren', 'OKC', UserInfo.getUserId(),'Thailand'),
            dataMaker.createLead('Lugent', 'Dortz', 'OKC', UserInfo.getUserId(),'Thailand'),
            dataMaker.createLeadAsUpload('Jaylen', 'William', 'OKC', UserInfo.getUserId(),'Thailand')
        };
        insert leadListNonChinese2;
        List<Lead> leadsOwnedByQueueNonChinese2 = [
            SELECT Id, OwnerId, ProjectsInterest__c
            FROM Lead
            WHERE OwnerId IN (SELECT Id FROM Group WHERE Id = :nonChineseQueue2.Id)
        ];
        
        // ------------------
		Test.stopTest();
        List<RoundRobinAssignment__c> rrAssignments = [
            SELECT QueueName__c, LastAssignedUser__c, TargetObject__c
            FROM RoundRobinAssignment__c
        ];
        System.assertEquals(2, rrAssignments.size());
		List<Lead> updatedLead2 = leadService.assignLeadInQueueByRoundRobin(leadsOwnedByQueue2);
        Integer startIndex2 = 0;
        RoundRobinAssignment__c rrAssignment = [
            SELECT QueueName__c, LastAssignedUser__c, TargetObject__c
            FROM RoundRobinAssignment__c
            WHERE QueueName__c = 'Sales_Chinese_Group'
            LIMIT 1
        ];
        for (Integer i = 0; i < groupMembers.size(); i++) {
            if (groupMembers[i].UserOrGroupId == rrAssignment.LastAssignedUser__c) {
                startIndex2 = Math.mod((i + 1), groupMembers.size()); // Move to the next user
                break;
            }
        }
        for (Lead lead : updatedLead2) {
            Integer currentIndex = Math.mod(startIndex2 , groupMembers.size());
            System.assertEquals(groupMembers[currentIndex].UserOrGroupId, lead.OwnerId);
			System.assertEquals(null, lead.ProjectsInterest__c);
            startIndex2 ++;
        }
		List<Lead> updatedLeadNonChinese2 = leadService.assignLeadInQueueByRoundRobin(leadsOwnedByQueueNonChinese2);
        Integer startIndexNonChinese2 = 0;
        RoundRobinAssignment__c rrAssignment2 = [
            SELECT QueueName__c, LastAssignedUser__c, TargetObject__c
            FROM RoundRobinAssignment__c
            WHERE QueueName__c = 'Sales_Group'
            LIMIT 1
        ];
        for (Integer i = 0; i < groupMembersNonChinese.size(); i++) {
            if (groupMembersNonChinese[i].UserOrGroupId == rrAssignment2.LastAssignedUser__c) {
                startIndexNonChinese2 = Math.mod((i + 1), groupMembersNonChinese.size()); // Move to the next user
                break;
            }
        }
        for (Lead lead : updatedLeadNonChinese2) {
            Integer currentIndex = Math.mod(startIndexNonChinese2 , groupMembersNonChinese.size());
            System.assertEquals(groupMembersNonChinese[currentIndex].UserOrGroupId, lead.OwnerId);
			System.assertEquals(null, lead.ProjectsInterest__c);
            startIndexNonChinese2 ++;
        }
    }

    @isTest 
    static void setBypassTest(){
        Test.startTest();
        LeadTriggerHandler handler = LeadTriggerHandler.getInstance();
        handler.setBypass();
        System.assertEquals(false, handler.isActive);
        System.assertEquals(false, handler.isTriggerActivated());
        Test.stopTest();
    }

    @isTest 
    static void clearBypassTest(){
        Test.startTest();
        LeadTriggerHandler handler = LeadTriggerHandler.getInstance();
        handler.clearBypass();
        System.assertEquals(true, handler.isActive);
        System.assertEquals(true, handler.isTriggerActivated());
        Test.stopTest();
    }
}