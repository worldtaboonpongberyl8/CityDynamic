public without sharing class ProjectSelector {
	public ProjectSelector() {
	}
	public static ProjectSelector instance;
	public static ProjectSelector getInstance() {
		if (instance == null) {
			instance = new ProjectSelector();
		}
		return instance;
	}
	/**
	 * Phase2
	 * Details:
	 * - Select more fields
	 * 		- NovationFee__c
	 */
	public Map<Id, Project__c> getProjectById(Set<Id> projectIds) {
		Map<Id, Project__c> projectMap = new Map<Id, Project__c>();
		List<Project__c> projectRecords = [
			SELECT Id, Name, CompletionDate__c, ProjectLogo__c,NovationFee__c,Tower__c,ProjectLogoPublicURL__c
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

	/**
	 * Phase2
	 * Details:
	 * - Add method to query Project__c with related Unit__c
	 */
	public Map<Id, Project__c> getProjectWithForeignOppMapById(Set<Id> projectIds){
		return new Map<Id, Project__c>(
			[
				SELECT
					Id,
					Name,
					CompletionDate__c,
					ProjectLogo__c,
					ProjectCode__c,
					NovationFee__c,
					ForeignQuotaArea__c,
					(
						SELECT
							Id,
							Unit__r.AreaSqm__c,
							Unit__r.Status__c
						FROM Opportunities__r
						WHERE Quota__c = 'Foreign'
						AND
						(
							StageName !=: GlobalConstants.OPP_STAGENAME_CLOSED_LOST
						)
					)
				FROM Project__c
				WHERE Id IN :projectIds
			]
		);
	}
	/**
	 * Phase2
	 * Details:
	 * - Add method to query Project__c and Opportunity with related Unit__c
	 */
	public Map<Id, Project__c> getProjectWithOppMapById(Set<Id> projectIds){
		return new Map<Id, Project__c>(
			[
				SELECT
					Id,
					Name,
					CompletionDate__c,
					ProjectLogo__c,
					ProjectCode__c,
					NovationFee__c,
					ForeignQuotaArea__c,
					(
						SELECT
							Id,
							Name,
							NetPrice__c,
							UnitPrice__c,
							UnitPricePerSqm__c,
							NetPricePerSqm__c,
							AreaSqm__c,
							CoBuyerName__c,
							PaymentPortalToken__c,
							Account.Name,
							Account.Phone,
							Account.Email__c,
							Account.AccountCode__c,
							Account.AddressEN__c,
							Account.AddressTH__c,
							Account.TaxID__c,
							ContactPerson__c,
							ContactPerson__r.MobilePhone,
							ContactPerson__r.Email,
							Project__r.Name,
							Project__r.ProjectLogo__c,
							Project__r.CompanyName__c,
							Project__r.CompanyAddress__c,
							Project__r.CompanyPhone__c,
							Project__r.CompanyTaxID__c,
							Unit__r.Name,
							Unit__r.AreaSqm__c,
							Unit__r.UnitType__r.Name,
							NovationDate__c
						FROM Opportunities__r
					)
				FROM Project__c
				WHERE Id IN :projectIds
			]
		);
	}
}