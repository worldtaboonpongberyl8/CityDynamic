public with sharing class GroupSelector {
    public static GroupSelector instance;

    public GroupSelector() {
    }

    public static GroupSelector getInstance() {
        if (instance == null) {
            instance = new GroupSelector();
        }
        return instance;
    }

    // get Queue map by Id
    public Map<Id, Group> getQueueMapById(Set<Id> queueIds) {
        return new Map<Id, Group>([SELECT Id, DeveloperName FROM Group WHERE Id IN :queueIds]);
    }

    // get Queue map by devname
    public Map<String, Group> getQueueMapByDevName(Set<String> devNames) {
        Map<String, Group> queueMapByDevName = new Map<String, Group>();
        List<Group> groups = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :devNames AND Type = 'Queue'];
        for (Group eachGroup : groups){
            queueMapByDevName.put(eachGroup.DeveloperName , eachGroup);
        }
        return queueMapByDevName;
    }

    // get members of a queue by their Queue IDs
    public Map<Id, List<GroupMember>> getQueueMembersMapByQueueId(Set<Id> queueIds) {
		UserSelector userSelector = UserSelector.getInstance();
        Map<Id, List<GroupMember>> queueMembersMapByQueueId = new Map<Id, List<GroupMember>>();
        List<GroupMember> queueMembers = [
            SELECT GroupId, UserOrGroupId
            FROM GroupMember
            WHERE GroupId IN :queueIds AND UserOrGroupId != null
        ];
		Set<Id> userIds = new Set<Id>();
		for (GroupMember member : queueMembers) {
			if (member.UserOrGroupId.getSobjectType() == Schema.User.SObjectType){
				userIds.add(member.UserOrGroupId);
			}
		}
		Map<Id,User> userMapById = UserSelector.getUserMapById(userIds);
        for (GroupMember member : queueMembers) {
			User targetUser = userMapById.get(member.UserOrGroupId);
            if (!queueMembersMapByQueueId.containsKey(member.GroupId)) {
                queueMembersMapByQueueId.put(member.GroupId, new List<GroupMember>());
            }
			if (targetUser.IsActive){
				queueMembersMapByQueueId.get(member.GroupId).add(member);
			}
        }

        return queueMembersMapByQueueId;
    }
}