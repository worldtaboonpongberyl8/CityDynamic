public with sharing class Product2Service {
	public Product2Service() {

	}
	public static Product2Service instance;

	public static Product2Service getInstance() {
		if (instance == null) {
			instance = new Product2Service();
		}
		return instance;
	}

	/**
	 * Phase2
	 * Details:
	 * - modify logic to update unit status to 'Blocked'
	 */
	public List<Product2> changeUnitStageToBookOrSoldByOpportunityStage(List<Opportunity> opportunities){
		Product2Selector productSelector = Product2Selector.getInstance();
		List<Product2> productToUpdateList = new List<Product2>();
		Set<Id> productIds = new Set<Id>();
		for(Opportunity opp : opportunities){
			productIds.add(opp.Unit__c);
		}
		Map<Id,Product2> productMap = productSelector.getProduct2ById(productIds);
		for(Opportunity opp : opportunities){
			Product2 product = productMap.get(opp.Unit__c);
			if(opp.StageName == 'Reservation'){
				product.Status__c = GlobalConstants.UNIT_STATUS_RESERVED;
				productToUpdateList.add(product);
			} else if (opp.StageName == 'Contract') {
				product.Status__c = GlobalConstants.UNIT_STATUS_SOLD;
				productToUpdateList.add(product);
			}else if (opp.StageName == 'Transferred'){
				product.Status__c = 'Transferred';
				product.TransferredDate__c = Date.today();
				productToUpdateList.add(product);
			}
			// Phase2 : add logic to update unit status to 'Blocked'
			else if (opp.StageName == GlobalConstants.OPP_STAGENAME_CLOSED_LOST &&
				(opp.LossReason__c == GlobalConstants.OPP_LOST_REASON_UPGRADE  ||
				opp.LossReason__c == GlobalConstants.OPP_LOST_REASON_DOWNGRADE ||
				opp.LossReason__c == GlobalConstants.OPP_LOST_REASON_MOVEPAYMENT ||
				opp.LossReason__c == GlobalConstants.OPP_LOST_REASON_CANCELFORFEIT ||
				opp.LossReason__c == GlobalConstants.OPP_LOST_REASON_TERMINATIONFORFEIT ||
				opp.LossReason__c == GlobalConstants.OPP_LOST_REASON_CANCELREFUND ||
				opp.LossReason__c == GlobalConstants.OPP_LOST_REASON_TERMINATIONREFUND)
			){
				product.Status__c = GlobalConstants.UNIT_STATUS_BLOCK;
				productToUpdateList.add(product);
			}
			System.debug('target product: ' +  ' ' + product.ProductCode + ' ' + product.Status__c );
		}
		return productToUpdateList;
	}

	public List<Product2> changeUnitStatusToAvailableByClosedLostOpportunity(List<Opportunity> opportunities){
		Set<Id> productIds = new Set<Id>();
		Product2Selector selector = Product2Selector.getInstance();
		for (Opportunity opportunity : opportunities ){
			productIds.add(opportunity.Unit__c);
		}
		Map<Id,Product2> productMapById = selector.getProduct2ById(productIds);
		List<Product2> products = new List<Product2>();
		for (Product2 product : productMapById.values()){
			product.Status__c = 'Available';
			product.TransferredDate__c = null;
			products.add(product);
		}
		if(!products.isEmpty()){
			update products;
		}
		return products;
	}

	/**
	 * Phase 2
	 * Details:
	 * 	- add method to change unit status to available
	 */
	public List<Product2> changeUnitStatusToAvailable(List<Product2> products){
		for (Product2 product : products){
			product.Status__c = 'Available';
			product.TransferredDate__c = null;
		}
		return products;
	}

}