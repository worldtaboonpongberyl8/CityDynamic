public with sharing class ProjectSelector {
	public ProjectSelector() {
	}
	public static ProjectSelector instance;
	public static ProjectSelector getInstance() {
		if (instance == null) {
			instance = new ProjectSelector();
		}
		return instance;
	}
	public Map<Id, Project__c> getProjectById(Set<Id> projectIds) {
		Map<Id, Project__c> projectMap = new Map<Id, Project__c>();
		List<Project__c> projectRecords = [
			SELECT Id, Name, CompletionDate__c, ProjectLogo__c
			FROM Project__c
			WHERE Id IN :projectIds
		];
		for (Project__c project : projectRecords) {
			projectMap.put(project.Id, project);
		}
		return projectMap;
	}

	public Map<String, Project__c> getProjectMapByProjectCode(Set<String> projectCodes) {
		Map<String, Project__c> projectMapByProjectCode = new Map<String, Project__c>();
		List<Project__c> projects = [
			SELECT Id, Name, CompletionDate__c, ProjectLogo__c, ProjectCode__c
			FROM Project__c
			WHERE ProjectCode__c IN :projectCodes
		];
		for (Project__c project : projects) {
			projectMapByProjectCode.put(project.ProjectCode__c, project);
		}
		return projectMapByProjectCode;
	}

	public Map<Id, Project__c> getProjectWithActiveCompanyBankMapById(Set<Id> projectsId) {
		return new Map<Id, Project__c>(
			[
				SELECT
					Id,
					Name,
					CompletionDate__c,
					ProjectLogo__c,
					ProjectCode__c,
					(
						SELECT
							Id,
							BankAccountNumber__c,
							BankName__c,
							BankBranch__c,
							BankAddress__c,
							SWIFTCode__c,
							Project__c,
							DisplayName__c,
							IsActive__c,
							IsDefault__c,
							IsUsedInPaymentGateway__c
						FROM Bank__r
						WHERE IsActive__c = TRUE
					)
				FROM Project__c
				WHERE Id IN :projectsId
			]
		);
	}
}