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
				product.Status__c = 'Reserved';
				productToUpdateList.add(product);
			} else if (opp.StageName == 'Contract') {
				product.Status__c = 'Sold';
				productToUpdateList.add(product);
			}else if (opp.StageName == 'Transferred'){
				product.Status__c = 'Transferred';
				product.TransferredDate__c = Date.today();
				productToUpdateList.add(product);
			}
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

}