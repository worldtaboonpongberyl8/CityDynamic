public with sharing class UnitReleasingController {
	@AuraEnabled
	public static Map<String,List<SObject>> completeUnitReleasing(Id unitId){
		Savepoint sp = Database.setSavepoint();
		try {
			Map<String,List<SObject>> resultMap = new Map<String,List<SObject>>();
			Product2Service productService = Product2Service.getInstance();
			Product2Selector productSelector = Product2Selector.getInstance();
			Map<Id, Product2> product2ById = productSelector.getProduct2ById(new Set<Id>{unitId});
			Product2 targetUnit = product2ById.get(unitId);
			List<Product2> releasedUnit = productService.changeUnitStatusToAvailable(new List<Product2>{targetUnit});
			for (Product2 unit : releasedUnit){
				unit.IsChangeFromBlock__c = true;
			}
			update releasedUnit;
			resultMap.put('releasedUnit' , releasedUnit);
			return resultMap;
		} catch (Exception e){
			Database.rollback(sp);
            System.debug('ERROR: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
		}
	}

	public class InputWrapper {
        @InvocableVariable(required=true) public Id opportunityId;
    }

	public class OutputWrapper {
        @InvocableVariable public Decimal tqUnitPrice;
        @InvocableVariable public Decimal fqUnitPrice;
		@InvocableVariable public Decimal unitPrice;
    }

	@InvocableMethod(label='Get Unit Price from Active PricebookEntry')
    public static List<OutputWrapper> getUnitPricesFromPricebookEntry(List<InputWrapper> inputList) {
		OpportunitySelector oppSelector = OpportunitySelector.getInstance();
		PricebookEntrySelector pricebookEntrySelector = PricebookEntrySelector.getInstance();
        List<OutputWrapper> results = new List<OutputWrapper>();
        if (inputList.isEmpty()) return results;
        Set<Id> opportunityIds = new Set<Id>();
        for (InputWrapper input : inputList) {
            if (input.opportunityId != null) {
                opportunityIds.add(input.opportunityId);
            }
        }
        // Step 1: Get Product2 Ids from Opportunity
        Set<Id> productIds = new Set<Id>();
		Map<Id, Opportunity> opportunityMapById = oppSelector.getOpportunityMapById(opportunityIds);
		for (Id opportunityId : opportunityIds){
			Opportunity targetOpportunity = opportunityMapById.get(opportunityId);
			productIds.add(targetOpportunity.Unit__c);
		}

        // Step 2: Get PricebookEntries where IsActive = true for those Product2
        Map<Id, PricebookEntry> pricebookEntriesMapByProductId = pricebookEntrySelector.getPricebookEntiesByProductId(productIds);
        // Step 3: Construct result
        for (InputWrapper input : inputList) {
			Opportunity targetOpportunity = opportunityMapById.get(input.opportunityId);
            PricebookEntry pbe = pricebookEntriesMapByProductId.get(targetOpportunity.Unit__c);
            if (targetOpportunity != null && pbe != null) {
                OutputWrapper output = new OutputWrapper();
                output.tqUnitPrice = pbe.TQUnitPrice__c;
                output.fqUnitPrice = pbe.FQUnitPrice__c;
				output.unitPrice = pbe.UnitPrice;
                results.add(output);
            }
        }
        return results;
    }

}