/**
 * Phase2
 * Details:
 * - Add new class to be service of UpgradeDowngradeMovePayment__c
 */
public class UpgradeDowngradeMovePaymentService {

    public static UpgradeDowngradeMovePaymentService instance;

	public static UpgradeDowngradeMovePaymentService getInstance() {
		if (instance == null) {
			instance = new UpgradeDowngradeMovePaymentService();
		}
		return instance;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add new method to generate UpgradeDowngradeMovePayment__c record with the detail
	 */
	public UpgradeDowngradeMovePayment__c generateUpgradeDowngradeMovePayment(String action, Opportunity oldOpportunity, Opportunity newOpportunity, String url, Decimal operationFee, String moveReason){
		UpgradeDowngradeMovePayment__c upgradeDowngradeMovePayment = new UpgradeDowngradeMovePayment__c();
		upgradeDowngradeMovePayment.AccountName__c = oldOpportunity.AccountId;
		upgradeDowngradeMovePayment.OpportunityFrom__c = oldOpportunity.Id;
		upgradeDowngradeMovePayment.OpportunityTo__c = newOpportunity.Id;
		upgradeDowngradeMovePayment.OperationFee__c = operationFee;
		upgradeDowngradeMovePayment.ChangeReason__c = moveReason;
		switch on action {
			when 'upgrade' {
				upgradeDowngradeMovePayment.URLUpgrade__c = url;
				upgradeDowngradeMovePayment.IsUpgradeCompleted__c = true;
			}
			when 'downgrade' {
				upgradeDowngradeMovePayment.URLDowngrade__c = url;
				upgradeDowngradeMovePayment.IsDowngradeCompleted__c = true;
			}
			when 'move_payment' {
				upgradeDowngradeMovePayment.URLMovePayment__c = url;
				upgradeDowngradeMovePayment.IsMovePaymentCompleted__c = true;
			}
			when else {

			}
		}
		return upgradeDowngradeMovePayment;
	}
}