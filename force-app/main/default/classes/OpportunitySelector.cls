public without sharing class OpportunitySelector {
	public static OpportunitySelector instance;
	public static OpportunitySelector getInstance() {
		if (instance == null) {
			instance = new OpportunitySelector();
		}
		return instance;
	}

	/**
	 * Phase2
	 * Details:
	 * - Select more fields
	 * 		- IsPaidNovationFee__c
	 * 		- NovateToOpportunity__c
	 * 		- NewCoOwner__c
	 * 		- TotalPaidAmount__c
	 * 		- TourAnalysis__c
	 */
	public Map<Id, Opportunity> getOpportunityMapById(Set<Id> oppIds) {
		return new Map<Id, Opportunity>(
			[
				SELECT
					Id,
					AreaSqm__c,
					Project__c,
					Project__r.Name,
					Unit__c,
					Unit__r.Name,
					Unit__r.AreaSqm__c,
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
					NetPricePerSqm__c,
					IsPaidNovationFee__c,
					NovateToOpportunity__c,
					NewCoOwner__c,
					TotalPaidAmount__c,
					TourAnalysis__c,
					// ----- Start Refund/Forfeit Section -----
					RefundApprovedDate__c,
					ApprovedBy__c,
					CustomerBankAccount__c,
					ChequeNumber__c,
					ChequeDate__c,
					TotalOperationFee__c,
					NetAgreedRefundAmount__c,
					NetAgreedForfeitAmount__c,
					CancellationTerminationType__c,
					CancellationTerminationSubType__c,
					URLRefund__c,
					URLForfeit__c,
					CoBuyerName__c
					// ----- End Refund/Forfeit Section -----
				FROM Opportunity
				WHERE Id IN :oppIds
			]
		);
	}

	/**
	 * Phase2
	 * Details:
	 * - Select more fields
	 * 		- Account.AccountCode__c
	 */
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
				Quota__c,
				Unit__r.Name,
				Unit__r.AreaSqm__c,
				Unit__r.UnitType__r.Name,
				NovationDate__c,
				Tower__c
			FROM Opportunity
			WHERE Id = :oppId
		];
	}

	/**
	 * Phase2
	 * Details:
	 * - Select more fields
	 * 		- Co_Borrowers__r.Status__c
	 * 		- CoBuyerQuota__c
	 * 		- Customer__r.AccountCode__c
	 */
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
					Account.Nationality__c,
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
					IsPaidNovationFee__c,
					NovateToOpportunity__c,
					NewCoOwner__c,
					Project__r.Name,
					Unit__r.Name,
					ReservationDueDate__c,
					DoNotSendInvoice__c,
					Account.RecordType.DeveloperName,
					NovationDate__c,
					(
						SELECT
							Id,
							Customer__r.AccountCode__c,
							AccountName__c,
							Relationship__c,
							Status__c,
							CoBuyerQuota__c
						FROM Co_Borrowers__r
						ORDER BY Priority__c)
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

	/**
	 * Phase2
	 * Details:
	 * - add new method to select Opportunity with all related record to be cloned in Novation process
	 */
	public Map<Id, Opportunity> getOpportuntiyWithRelatedRecordForNovationMapById(Set<Id> oppIds){
		return new Map<Id, Opportunity>(
			[
				SELECT
					Id,
					Name,
					Project__c,
					Project__r.Name,
					Project__r.ProjectCode__c ,
					Unit__c,
					Unit__r.Name,
					Unit__r.ProductCode,
					Tower__c,
					UnitType__c,
					Floor__c,
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
					Account.AccountCode__c,
					Account.AddressEN__c,
					Account.AddressTH__c,
					Account.RecordType.DeveloperName,
					UnitPricePersqm__c,
					NetPricePerSqm__c,
					ActualContractSigningDate__c,
					TotalPaidAmount__c,
					CoBuyerName__c,
					PurposeofPurchase__c,
					UnitsofInterest__c,
					Budget__c,
					LeadSource,
					SubLeadSource__c,
					LeadChannel__c,
					SoldBy__c,
					SoldBy2__c,
					Ratio__c,
					CRMinCharge__c,
					UnitCode__c,
					// ----- Start Novation/Add or Change Owner Section -----
					IsPaidNovationFee__c,
					NovateToOpportunity__c,
					NovateFromOpportunity__c,
					NewCoOwner__c,
					NewCoOwner__r.Nationality__c,
					NovationDate__c,
					// ----- End Novation/Add or Change Owner Section -----
					// ----- Start Upgrade/Downgrade/Move Payment Section -----
					IsUpgradedOpportunity__c,
					IsDowngradedOpportunity__c,
					UpgradeFrom__c,
					UpgradeTo__c,
					DowngradeFrom__c,
					DowngradeTo__c,
					// ----- End Upgrade/Downgrade/Move Payment Section -----
					(
						SELECT
							Id,
							Name,
							Status__c,
							PromotionMaster__c,
							PromotionMaster__r.Name
						FROM Promotion_Transactions__r
						WHERE IsDelete__c = false
					),
					(
						SELECT
							Id,
							Name,
							Cost__c,
							Description__c,
							OriginalCost__c,
							PromotionType__c,
							PromotionMaster__c,
							Status__c,
							PromotionMaster__r.Name
						FROM Client_Offers__r
					),
					(
						SELECT
							Id,
							AccountName__c,
							AddressEN__c,
							AddressTH__c,
							IsSyncing__c,
							ProjectName__c,
							UnitNo__c,
							PaymentTerm__c,
							ExpirationDate__c,
							UnitPrice__c,
							UnitPricePersqm__c,
							NetPricePerSqm__c,
							TotalPrice__c,
							DiscountPercent__c,
							DiscountAmount__c,
							DiscountPercentOfAmount__c,
							TotalDiscountAmount__c,
							TotalDiscountPercent__c
						FROM Quote__r
						WHERE IsSyncing__c = TRUE
					),
					(
						SELECT Id,
							AccountName__c,
							Customer__r.AccountCode__c,
							Relationship__c,
							Status__c,
							Customer__c
						FROM Co_Borrowers__r
						ORDER BY Priority__c
					),
					(
						SELECT
							Id,
							Amount__c,
							DueDate__c,
							IsMasterData__c,
							Opportunity__c,
							Order__c,
							PaymentStatus__c,
							PaymentTermMaster__c,
							ProjectName__c,
							Quote__c,
							ReceivedAmount__c,
							ReceivedDate__c,
							Remaining__c,
							Term__c,
							Type__c,
							UnitName__c
						FROM Opportunity_Payments__r
						WHERE IsMasterData__c = TRUE
					),
					(
						SELECT
							Id,
							AccountId,
							CancelReason__c,
							Status,
							StartDate,
							IsSignedContract__c,
							StatusCode,
							ContractSignedDate__c,
							Project__c,
							Unit__c,
							DiscountAmount__c,
							DiscountPercent__c,
							DiscountPercentOfAmount__c,
							TotalDiscountAmount__c,
							TotalDiscountPercent__c
						FROM Contracts__r
					)
				FROM Opportunity
				WHERE Id IN :oppIds
			]
		);
	}
	/**
	 * Phase2
	 * Details:
	 * - query Opportunity by oppId and field set
	 */
	public Map<Id, Opportunity> getOpportunityFieldsetByIds(Set<Id> oppIds) {
		Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

		if (oppIds == null || oppIds.isEmpty()) {
			return oppMap;
		}
		List<Schema.FieldSetMember> fields = Schema.SObjectType.Opportunity.fieldSets.getMap().get('Recurring').getFields();
		String query = 'SELECT ';
		for (Integer i = 0; i < fields.size(); i++) {
			query += fields[i].getFieldPath();
			if (i < fields.size() - 1) {
				query += ', ';
			}
		}
		query += ' FROM Opportunity WHERE Id IN :oppIds';
		List<Opportunity> oppList = Database.query(query);
		for (Opportunity opp : oppList) {
			oppMap.put(opp.Id, opp);
		}
		return oppMap;
	}

}