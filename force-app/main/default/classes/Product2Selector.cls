public with sharing class Product2Selector {
	public Product2Selector() {
	}
	public static Product2Selector instance;

	public static Product2Selector getInstance() {
		if (instance == null) {
			instance = new Product2Selector();
		}
		return instance;
	}
	public Map<Id, Product2> getProduct2ById(Set<Id> product2Ids) {
		return new Map<Id, Product2>(
			[SELECT Id, Name, ReservationPrice__c, Project__c, Status__c FROM Product2 WHERE Id IN :product2Ids]
		);
	}
}