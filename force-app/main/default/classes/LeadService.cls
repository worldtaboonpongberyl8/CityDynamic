public with sharing class LeadService {
	public static LeadService instance;

	public LeadService() {
	}

	public static LeadService getInstance() {
		if (instance == null) {
			instance = new LeadService();
		}
		return instance;
	}

	public List<Lead> assignLeadCountryFromCountryCode(List<Lead> leads) {
		for (Lead lead : leads) {
			lead.LeadCountry__c = lead.CountryCode__c == 'Thailand'
				? 'Thailand'
				: lead.CountryCode__c == 'China' ? 'China' : 'Foreign';
		}
		return leads;
	}

	// assign lead to queue
	public List<Lead> assignLeadToQueue(List<Lead> leads) {
		GroupSelector groupSelector = GroupSelector.getInstance();
		Map<String, Group> queueMapByDevName = groupSelector.getQueueMapByDevName(
			new Set<String>{ 'Sales_Chinese_Group', 'Sales_Group', 'Salesforeign' }
		);
		List<Lead> leadsAfterAssigned = new List<Lead>();
		for (Lead lead : leads) {
			if (lead.LeadOrigin__c == 'Upload' || lead.LeadOrigin__c == 'Web-to-Lead') {
				if (lead.LeadCountry__c == 'China') {
					Group chineseQueue = queueMapByDevName.get('Sales_Chinese_Group');
					lead.OwnerId = chineseQueue.Id;
				} else if (lead.LeadCountry__c == 'Thailand') {
					Group thaiQueue = queueMapByDevName.get('Sales_Group');
					lead.OwnerId = thaiQueue.Id;
				} else {
					Group foreignQueue = queueMapByDevName.get('Salesforeign');
					lead.OwnerId = foreignQueue.Id;
				}
			}
		}
		return leads;
	}
	// assign lead to user by Round Robin
	public List<Lead> assignLeadInQueueByRoundRobin(List<Lead> leads) {
		List<Lead> updatedLeads = new List<Lead>();
		List<Lead> leadsOwnedByQueue = this.filterLeadOwnedByQueue(leads);
		leadsOwnedByQueue = this.filterLeadNeededAutoAssignment(leadsOwnedByQueue);
		List<RoundRobinAssignment__c> updatedRRAssignment = new List<RoundRobinAssignment__c>();
		GroupSelector groupSelector = GroupSelector.getInstance();
		RoundRobinAssignmentSelector rrAssignmentSelector = RoundRobinAssignmentSelector.getInstance();
		Set<Id> queueIds = new Set<Id>();
		for (Lead lead : leadsOwnedByQueue) {
			queueIds.add(lead.OwnerId);
		}
		Map<Id, Group> queueMapById = groupSelector.getQueueMapById(queueIds);
		Set<String> queueNames = new Set<String>();
		for (Group eachGroup : queueMapById.values()) {
			queueNames.add(eachGroup.DeveloperName);
		}
		System.debug('queueNames: ' + queueNames);
		Map<Id, List<Lead>> leadsMapByQueueId = new Map<Id, List<Lead>>();
		for (Lead lead : leadsOwnedByQueue) {
			if (!leadsMapByQueueId.containsKey(lead.OwnerId)) {
				leadsMapByQueueId.put(lead.OwnerId, new List<Lead>());
			}
			leadsMapByQueueId.get(lead.OwnerId).add(lead);
		}
		Map<Id, List<GroupMember>> queueMembersMapByQueueId = groupSelector.getQueueMembersMapByQueueId(queueIds);
		Map<String, RoundRobinAssignment__c> rrAssignmentMapByQueueName = rrAssignmentSelector.getLeadRoundRobinAssignmentMapByQueueName(
			queueNames
		);

		// Round Robin Logic
		for (Id queueId : queueIds) {
			List<Lead> leadsOwnedByThisQueue = leadsMapByQueueId.get(queueId);
			if (!leadsOwnedByThisQueue.isEmpty() && queueMembersMapByQueueId.containsKey(queueId)) {
				Group targetQueue = queueMapById.get(queueId);
				List<GroupMember> queueMembers = queueMembersMapByQueueId.get(queueId);
				System.debug('member size: ' + queueMembers.size());
				RoundRobinAssignment__c targetRRAssignment = rrAssignmentMapByQueueName.get(targetQueue.DeveloperName);
				if (targetRRAssignment == null) {
					targetRRAssignment = new RoundRobinAssignment__c(
						QueueName__c = targetQueue.DeveloperName,
						TargetObject__c = 'Lead'
					);
				}
				Integer startIndex = 0;
				// Find starting index in each queue
				if (targetRRAssignment.LastAssignedUser__c != null) {
					for (Integer i = 0; i < queueMembers.size(); i++) {
						if (queueMembers[i].UserOrGroupId == targetRRAssignment.LastAssignedUser__c) {
							startIndex = Math.mod((i + 1), queueMembers.size()); // Move to the next user
							break;
						}
					}
				}
				// Start round-robin assignment
				for (Integer i = 0; i < leadsOwnedByThisQueue.size(); i++) {
					Integer currentIndex = Math.mod(startIndex, queueMembers.size());
					Lead assignedLead = leadsOwnedByThisQueue[i];
					assignedLead.OwnerId = queueMembers[currentIndex].UserOrGroupId;
					System.debug('queueMember: ' + queueMembers[currentIndex]);
					System.debug('assignedLead: ' + assignedLead);
					startIndex++;
					updatedLeads.add(assignedLead);
				}
				// Update the last assigned user
				targetRRAssignment.LastAssignedUser__c = queueMembers[Math.mod((startIndex - 1), queueMembers.size())]
					.UserOrGroupId;
				updatedRRAssignment.add(targetRRAssignment);
			}
		}
		if (!updatedRRAssignment.isEmpty()) {
			upsert updatedRRAssignment;
		}
		return updatedLeads;
	}

	public List<Lead> stampProjectFromProjectCode(List<Lead> leads) {
		ProjectSelector selector = ProjectSelector.getInstance();
		Set<String> prjectCodes = new Set<String>();
		for (Lead lead : leads) {
			prjectCodes.add(lead.ProjectInterest__c);
		}
		Map<String, Project__c> projectMapByProjectCode = selector.getProjectMapByProjectCode(prjectCodes);
		for (Lead lead : leads) {
			Project__c targetProject = projectMapByProjectCode.get(lead.ProjectInterest__c);
			lead.ProjectsInterest__c = targetProject == null ? null : targetProject.Id;
		}
		return leads;
	}

	// filter lead owned by queue
	public List<Lead> filterLeadOwnedByQueue(List<Lead> leads) {
		List<Lead> filteredLeads = new List<Lead>();
		for (Lead lead : leads) {
			if (!lead.OwnerId.toString().startsWith('005')) {
				filteredLeads.add(lead);
			}
		}
		return filteredLeads;
	}

	// filter leads which need to be assigned automatically
	public List<Lead> filterLeadNeededAutoAssignment(List<Lead> leads) {
		List<Lead> filteredLeads = new List<Lead>();
		for (Lead lead : leads) {
			if (lead.IsAutoAssingment__c || lead.LeadOrigin__c == 'Web-to-Lead') {
				filteredLeads.add(lead);
			}
		}
		return filteredLeads;
	}

	// assign lead to queue future
	@Future
	public static void assignLeadToQueueFuture(Set<Id> leadIds) {
		LeadSelector leadSelector = LeadSelector.getInstance();
		GroupSelector groupSelector = GroupSelector.getInstance();
		Map<String, Group> queueMapByDevName = groupSelector.getQueueMapByDevName(
			new Set<String>{ 'Sales_Chinese_Group', 'Sales_Group', 'Salesforeign' }
		);
		Map<Id, Lead> leadsToAssignedMapById = leadSelector.getLeadMapById(leadIds);
		List<Lead> leads = leadsToAssignedMapById.values();
		for (Lead lead : leads) {
			if (lead.LeadOrigin__c == 'Upload' || lead.LeadOrigin__c == 'Web-to-Lead') {
				if (lead.LeadCountry__c == 'China') {
					Group chineseQueue = queueMapByDevName.get('Sales_Chinese_Group');
					lead.OwnerId = chineseQueue.Id;
				} else if (lead.LeadCountry__c == 'Thailand') {
					Group thaiQueue = queueMapByDevName.get('Sales_Group');
					lead.OwnerId = thaiQueue.Id;
				} else {
					Group foreignQueue = queueMapByDevName.get('Salesforeign');
					lead.OwnerId = foreignQueue.Id;
				}
			}
		}
		LeadService.getInstance().assignLeadInQueueByRoundRobin(leads);
		update leads;
	}

	/**
	 * Phase: 1
	 * UAT Issue: DF-UAT-004
	*/
	public List<Lead> assignLeadCountryWithCodeFromCountryCode(List<Lead> leads) {
		for (Lead lead : leads) {
			lead.CountryWithCode__c = lead.CountryCode__c ;
		}
		return leads;
	}
}