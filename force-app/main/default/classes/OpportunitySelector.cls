public with sharing class OpportunitySelector {
	public static OpportunitySelector instance;
	public static OpportunitySelector getInstance() {
		if (instance == null) {
			instance = new OpportunitySelector();
		}
		return instance;
	}

	public Map<Id, Opportunity> getOpportunityMapById(Set<Id> oppIds) {
		return new Map<Id, Opportunity>(
			[
				SELECT
					Id,
					Project__c,
					Project__r.Name,
					Unit__c,
					Unit__r.Name,
					Promotion__c,
					StageName,
					Quota__c,
					AccountId,
					DiscountAmount__c,
					DiscountPercent__c,
					DiscountPercentOfAmount__c,
					TotalDiscountPercent__c,
					UnitPrice__c,
					NetPrice__c,
					PaymentTermMaster__c,
					ContractId,
					TotalDiscountAmount__c,
					ContactPerson__c,
					SyncedQuoteId__c,
					ReservationDueDate__c,
					DoNotSendInvoice__c,
					CloseDate,
					Account.AddressEN__c,
					Account.AddressTH__c,
					Account.RecordType.DeveloperName,
					UnitPricePersqm__c,
					NetPricePerSqm__c
				FROM Opportunity
				WHERE Id IN :oppIds
			]
		);
	}

	public Opportunity getById(Id oppId) {
		return [
			SELECT
				Id,
				Name,
				NetPrice__c,
				UnitPrice__c,
				UnitPricePerSqm__c,
				NetPricePerSqm__c,
				AreaSqm__c,
				CoBuyerName__c,
				Account.Name,
				Account.Phone,
				Account.Email__c,
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
				Unit__r.UnitType__r.Name
			FROM Opportunity
			WHERE Id = :oppId
		];
	}

	public Map<Id, Opportunity> getOpportunityWithCoBuyerMapById(Set<Id> oppIds) {
		return new Map<Id, Opportunity>(
			[
				SELECT
					Id,
					Project__c,
					Unit__c,
					Promotion__c,
					StageName,
					Quota__c,
					AccountId,
					DiscountAmount__c,
					DiscountPercent__c,
					DiscountPercentOfAmount__c,
					TotalDiscountPercent__c,
					UnitPrice__c,
					NetPrice__c,
					PaymentTermMaster__c,
					ContractId,
					TotalDiscountAmount__c,
					CoBuyerName__c,
					IsCoBuyer__c,
					AccountName__c,
					ContactPerson__c,
					SyncedQuoteId__c,
					CloseDate,
					Account.AddressEN__c,
					Account.AddressTH__c,
					UnitPricePersqm__c,
					NetPricePerSqm__c,
					(SELECT Id, AccountName__c, Relationship__c FROM Co_Borrowers__r ORDER BY Priority__c)
				FROM Opportunity
				WHERE Id IN :oppIds
			]
		);
	}

	public Map<Id, Opportunity> getOpportunityWithSyncedQuotedMapById(Set<Id> oppIds) {
		return new Map<Id, Opportunity>(
			[
				SELECT
					Id,
					Project__c,
					Unit__c,
					Promotion__c,
					StageName,
					Quota__c,
					AccountId,
					DiscountAmount__c,
					DiscountPercent__c,
					DiscountPercentOfAmount__c,
					TotalDiscountPercent__c,
					UnitPrice__c,
					NetPrice__c,
					PaymentTermMaster__c,
					ContractId,
					TotalDiscountAmount__c,
					ContactPerson__c,
					SyncedQuoteId__c,
					CloseDate,
					Account.AddressEN__c,
					Account.AddressTH__c,
					UnitPricePersqm__c,
					NetPricePerSqm__c,
					(
						SELECT
							Id,
							AddressEN__c,
							AddressTH__c
						FROM Quote__r
						WHERE IsSyncing__c = TRUE
					)
				FROM Opportunity
				WHERE Id IN :oppIds
			]
		);
	}

	public Map<Id, Opportunity> getOpportunityWithClientOfferMapById(Set<Id> oppIds) {
		return new Map<Id, Opportunity>(
			[
				SELECT
					Id,
					Project__c,
					Unit__c,
					Promotion__c,
					StageName,
					Quota__c,
					AccountId,
					DiscountAmount__c,
					DiscountPercent__c,
					DiscountPercentOfAmount__c,
					TotalDiscountPercent__c,
					UnitPrice__c,
					NetPrice__c,
					PaymentTermMaster__c,
					ContractId,
					TotalDiscountAmount__c,
					ContactPerson__c,
					SyncedQuoteId__c,
					CloseDate,
					Account.AddressEN__c,
					Account.AddressTH__c,
					UnitPricePersqm__c,
					NetPricePerSqm__c,
					(
						SELECT
							Id,
							Cost__c,
							Description__c,
							OriginalCost__c,
							PromotionType__c
						FROM Client_Offers__r
					)
				FROM Opportunity
				WHERE Id IN :oppIds
			]
		);
	}
}