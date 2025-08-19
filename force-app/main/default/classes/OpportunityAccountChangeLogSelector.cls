/**
 * Phase2
 * Details:
 * - Add new class to be selector of OpportunityAccountChangeLog__c
 */
public class OpportunityAccountChangeLogSelector {

    public static OpportunityAccountChangeLogSelector instance;
	public static OpportunityAccountChangeLogSelector getInstance() {
		if (instance == null) {
			instance = new OpportunityAccountChangeLogSelector();
		}
		return instance;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add new method to select OpportunityAccountChangeLog__c with related PaymentReceipt__c
	 */
	public Map<Id,OpportunityAccountChangeLog__c> getOpportunityAccountChangeLogWithSnapshotReceipts(Set<Id> opportunityAccountChangeLogIds){
		return new Map<Id,OpportunityAccountChangeLog__c>(
			[
				SELECT
					Id,
					PreviousAccount__c,
					PreviousAccount__r.AccountCode__c,
					CurrentAccount__c,
					PreviousOpportunity__c,
					CurrentOpportunity__c,
					CurrentOpportunity__r.Project__r.ProjectCode__c,
					CurrentOpportunity__r.Unit__r.ProductCode,
					ChangedDatetime__c,
					LastGLStatusInPojjaman__c,
					LastIntegrationDateTime__c,
					ResponseMessage__c,
					(
						SELECT
							Id,ReceiptType__c
						FROM PaymentReceipts__r
					)
				FROM OpportunityAccountChangeLog__c
				WHERE Id IN: opportunityAccountChangeLogIds
			]
		);
	}

	/**
	 * Phase2
	 * Details:
	 * - Add new method to select latest OpportunityAccountChangeLog__c which opportunity changed
	 */
	public Map<Id,OpportunityAccountChangeLog__c> getOpportunityAccountChangeLogFromPreviousOpportuntiyIdMapByPreviousAccountId(Set<Id> previousAccountIds){
		Map<Id,OpportunityAccountChangeLog__c> opportunityAccountChangeLogFromPreviousOpportuntiyIdMapByPreviousAccountId = new Map<Id,OpportunityAccountChangeLog__c>();
		List<OpportunityAccountChangeLog__c> oppAccChangeLogs =	[
																	SELECT
																		Id,
																		PreviousAccount__c,
																		PreviousAccount__r.AccountCode__c,
																		CurrentAccount__c,
																		PreviousOpportunity__c,
																		CurrentOpportunity__c,
																		CurrentOpportunity__r.Project__r.ProjectCode__c,
																		CurrentOpportunity__r.Unit__r.ProductCode,
																		ChangedDatetime__c,
																		(
																			SELECT
																				Id,ReceiptType__c
																			FROM PaymentReceipts__r
																		)
																	FROM OpportunityAccountChangeLog__c
																	WHERE CurrentAccount__c IN: previousAccountIds
																];
		for (OpportunityAccountChangeLog__c oppAccChangeLog : oppAccChangeLogs){
			opportunityAccountChangeLogFromPreviousOpportuntiyIdMapByPreviousAccountId.put(oppAccChangeLog.CurrentAccount__c , oppAccChangeLog);
		}
		return opportunityAccountChangeLogFromPreviousOpportuntiyIdMapByPreviousAccountId;
	}
}