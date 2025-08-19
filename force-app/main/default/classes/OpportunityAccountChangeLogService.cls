/**
 * Phase2
 * Details:
 * - Add new class to be service of OpportunityAccountChangeLog__c
 */
public class OpportunityAccountChangeLogService {

    public static OpportunityAccountChangeLogService instance;

	public static OpportunityAccountChangeLogService getInstance() {
		if (instance == null) {
			instance = new OpportunityAccountChangeLogService();
		}
		return instance;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add new method to create OpportunityAccountChangeLog__c
	 */
	public OpportunityAccountChangeLog__c craeteOpportunityAccountChangeLogFromPreviousAndCurrentOpportunity(Opportunity previousOpportunity, Opportunity currentOpportunity){
		OpportunityAccountChangeLog__c opportunityAccountChangeLogs = new OpportunityAccountChangeLog__c();
		opportunityAccountChangeLogs.PreviousOpportunity__c = previousOpportunity.Id;
		opportunityAccountChangeLogs.PreviousAccount__c = previousOpportunity.AccountId;
		opportunityAccountChangeLogs.CurrentOpportunity__c = currentOpportunity.Id;
		opportunityAccountChangeLogs.CurrentAccount__c = currentOpportunity.AccountId;
		opportunityAccountChangeLogs.ChangedDatetime__c = Datetime.now();
		return opportunityAccountChangeLogs;
	}

}