public with sharing class QuoteService {
	public static QuoteService instance;
	public static QuoteService getInstance(){
		if (instance == null){
			instance = new QuoteService();
		}
		return instance;
	}

	/**
	 * Phase: 1
	 * UAT Issue: DF-UAT-025
	*/
	public List<Quote__c> generateQuotesFromOpportunities(List<Opportunity> opportunities){
		AccountSelector accountSelector = AccountSelector.getInstance();
		List<Quote__c> targetQuotes = new List<Quote__c>();
		Set<Id> accountIds = new Set<Id>();
		for (Opportunity opportunity : opportunities){
			accountIds.add(opportunity.AccountId);
		}
		Map<Id, Account> accountWithContactsMapById = accountSelector.getAccountWithContactsMapById(accountIds);
		for (Opportunity opportunity : opportunities){
			Account targetAccount = accountWithContactsMapById.get(opportunity.AccountId);
			Quote__c targetQuote = new Quote__c();
			targetQuote.Opportunity__c = opportunity.Id;
			targetQuote.Status__c = 'Open';
			targetQuote.DiscountPercent__c = opportunity.DiscountPercent__c;
			targetQuote.PaymentTerm__c = opportunity.PaymentTermMaster__c;
			targetQuote.DiscountAmount__c = opportunity.DiscountAmount__c;
			targetQuote.DiscountPercentOfAmount__c = opportunity.DiscountPercentOfAmount__c;
			targetQuote.TotalDiscountPercent__c = opportunity.TotalDiscountPercent__c;
			targetQuote.TotalPrice__c = opportunity.NetPrice__c;
			targetQuote.UnitPrice__c = opportunity.UnitPrice__c;
			targetQuote.TotalDiscountAmount__c = opportunity.TotalDiscountAmount__c;
			targetQuote.AccountName__c = opportunity.AccountId;
			targetQuote.ProjectName__c = opportunity.Project__c;
			targetQuote.UnitNo__c = opportunity.Unit__c;
			targetQuote.ExpirationDate__c = opportunity.CloseDate;
			targetQuote.AddressEN__c = opportunity.Account.AddressEN__c;
			targetQuote.AddressTH__c = opportunity.Account.AddressTH__c;
			targetQuote.UnitPricePersqm__c = opportunity.UnitPricePersqm__c;
			targetQuote.NetPricePerSqm__c = opportunity.NetPricePerSqm__c;
			if (targetAccount != null){
				targetQuote.Fax__c = targetAccount.Fax;
				if (targetAccount.RecordType.DeveloperName == 'Co_Owner_Corporate' || targetAccount.RecordType.DeveloperName == 'Prospect_Corporate'){
					List<Contact> contacts = targetAccount.Contacts == null ? new List<Contact>() : targetAccount.Contacts;
					Contact targetContact = contacts.size() > 0 ? contacts[0] : null;
					for (Contact contact : contacts){
						if (contact.IsPrimaryContact__c){
							targetContact = contact;
						}
					}
					if (targetContact != null){
						targetQuote.ContactName__c = targetContact.FirstName + ' ' + targetContact.LastName;
						targetQuote.Phone__c = targetContact.Phone;
						targetQuote.Email__c = targetContact.Email;
					}
				} else {
					targetQuote.ContactName__c = targetAccount.Name;
					targetQuote.Phone__c = targetAccount.Phone;
					targetQuote.Email__c = targetAccount.Email__c;
				}
			}
			targetQuotes.add(targetQuote);
		}
		return targetQuotes;
	}
	public Map<String, SObject> getMapForSyncQuoteToOpp(List<Quote__c> quotes){
		OpportunitySelector oppSelector = OpportunitySelector.getInstance();
		Map<String, SObject> syncQuoteToOppMap = new Map<String, SObject>();
		List<Quote__c> quoteList = new List<Quote__c>();
		Set<Id> quoteIds = new Set<Id>();
		Set<Id> oppIds = new Set<Id>();
		for (Quote__c quote : quotes){
			oppIds.add(quote.Opportunity__c);
		}
		Map<Id, Opportunity> opportunityMapById = oppSelector.getOpportunityMapById(oppIds);
		for(Quote__c quote : quotes){
			quote.IsSyncing__c = true;
			Opportunity opportunity = opportunityMapById.get(quote.Opportunity__c);
			if(opportunity != null){
				opportunity.SyncedQuoteId__c = quote.Id;
				syncQuoteToOppMap.put('Opportunity', opportunity);
			}
			syncQuoteToOppMap.put('Quote__c', quote);
		}
		return syncQuoteToOppMap;
	}

	public List<Quote__c> unsetSyncedQuoteFromOthers(List<Quote__c> quotes){
		OpportunitySelector oppSelector = OpportunitySelector.getInstance();
		List<Quote__c> unsyncedQuote = new List<Quote__c>();
		Set<Id> oppIds = new Set<Id>();
		for(Quote__c quote: quotes){
			oppIds.add(quote.Opportunity__c);
		}
		Map<Id, Opportunity> opportunityWithSyncedQuoteMapById = oppSelector.getOpportunityWithSyncedQuotedMapById(oppIds);
		for(Quote__c quote: quotes){
			Opportunity targetOpportunity = opportunityWithSyncedQuoteMapById.get(quote.Opportunity__c);
			List<Quote__c> allSyncedQuotes = targetOpportunity.Quote__r == null ? new List<Quote__c>() : targetOpportunity.Quote__r;
			for (Quote__c syncedQuote : allSyncedQuotes){
				if (syncedQuote.Id != quote.Id){
					syncedQuote.IsSyncing__c = false;
					unsyncedQuote.add(syncedQuote);
				}
			}
		}
		return unsyncedQuote;
	}

	public List<Opportunity> stampDiscountFromSyncedQuoteToOpportunity(List<Quote__c> quotes){
		OpportunitySelector oppSelector = OpportunitySelector.getInstance();
		List<Opportunity> updatedOpportunities = new List<Opportunity>();
		Set<Id> oppIds = new Set<Id>();
		for (Quote__c quote : quotes){
			oppIds.add(quote.Opportunity__c);
		}

		System.debug('oppIds' + oppIds);
		Map<Id, Opportunity> opportunityMapById = oppSelector.getOpportunityMapById(oppIds);
		for (Quote__c quote : quotes){
			Opportunity opportunity = opportunityMapById.get(quote.Opportunity__c);
			if (opportunity != null){
				opportunity.DiscountPercent__c = quote.DiscountPercent__c;
				opportunity.DiscountAmount__c = quote.DiscountAmount__c;
				updatedOpportunities.add(opportunity);
			}
		}
		return updatedOpportunities;
	}


}