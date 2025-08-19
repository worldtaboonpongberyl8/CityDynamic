/**
 * Phase2
 * Details:
 * - Add new class to be service of Project__c
 */
public class ProjectService {

    public static ProjectService instance;

	public static ProjectService getInstance() {
		if (instance == null) {
			instance = new ProjectService();
		}
		return instance;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add new method to calculate Total FQ booked and sold
	 */
	public Map<Id,Decimal> calculateAreaBookedOrSoldAsFQQuota(Set<Id> projectIds){
		Map<Id,Decimal> areaOfBookedOrSoldFQQuotaMapByProjectId = new Map<Id,Decimal>();
		ProjectSelector projectSelector = ProjectSelector.getInstance();
		Map<Id, Project__c> projectWithForeignOppMapById = projectSelector.getProjectWithForeignOppMapById(projectIds);
		for (Id projectId : projectWithForeignOppMapById.keySet()){
			Decimal totalForeignBookAndSoldArea = 0;
			Project__c targetProject = projectWithForeignOppMapById.get(projectId);
			List<Opportunity> foreignOpportunities = targetProject.Opportunities__r;
			for (Opportunity foreignOpportunity : foreignOpportunities){
				totalForeignBookAndSoldArea =  foreignOpportunity.Unit__r.AreaSqm__c == null ? totalForeignBookAndSoldArea : totalForeignBookAndSoldArea + foreignOpportunity.Unit__r.AreaSqm__c;
			}
			areaOfBookedOrSoldFQQuotaMapByProjectId.put(projectId, totalForeignBookAndSoldArea);
		}
		return areaOfBookedOrSoldFQQuotaMapByProjectId;
	}
}