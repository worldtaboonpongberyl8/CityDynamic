public with sharing class AccountSelector {
	public static AccountSelector instance;
	public static AccountSelector getInstance() {
		if (instance == null) {
			instance = new AccountSelector();
		}
		return instance;
	}

	public Map<Id, Account> getAccountWithContactsMapById(Set<Id> accountIds) {
		return new Map<Id, Account>(
			[
				SELECT
					Id,
					Name,
					Phone,
					AccountCode__c,
					AccountNameTH__c,
					AccountSource,
					Active__c,
					AddressEN__c,
					AddressTH__c,
					CountryEN__c,
					CountryTH__c,
					CustomerStatus__c,
					Email__c,
					Fax,
					FaxExt__c,
					IDCardNumber__c,
					Interest__c,
					LastIntegrationDateTime__c,
					LineID__c,
					RecordType.DeveloperName,
					ResponseCode__c,
					ResponseMessage__c,
					(
						SELECT
							Id,
							IsPrimaryContact__c,
							Active__c,
							Email,
							FirstName,
							LastName,
							Phone,
							LastCreatedStatusInPojjaman__c,
							ResponseCode__c,
							ResponseMessage__c,
							LastIntegrationDateTime__c
						FROM Contacts
						ORDER BY CreatedDate ASC
					)
				FROM Account
				WHERE Id IN :accountIds
			]
		);
	}

	public Map<Id, Account> getLastCreatedAccountWithContactsMapById() {
		return new Map<Id, Account>(
			[
				SELECT
					Id,
					AccountCode__c,
					Name,
					AccountNameTH__c,
					AddressEN__c,
					AddressTH__c,
					RecordType.DeveloperName,
					MailingAddressEN__c,
					MailingAddressTH__c,
					Phone,
					Fax,
					FaxExt__c,
					Email__c,
					TaxID__c,
					IDCardNumber__c,
					PassportNo__c,
					CountryEN__c,
					CountryTH__c,
					CustomerStatus__c,
					Interest__c,
					Active__c,
					ResponseCode__c,
					ResponseMessage__c,
					LastIntegrationDateTime__c,
					LastModifiedDate,
					(
						SELECT
							Id,
							FirstName,
							LastName,
							Email,
							MobilePhone,
							Position__c,
							IsPrimaryContact__c,
							Active__c,
							ResponseCode__c,
							ResponseMessage__c,
							LastIntegrationDateTime__c,
							LastCreatedStatusInPojjaman__c,
							LastModifiedDate
						FROM Contacts
					)
				FROM Account
				WHERE
					(LastModifiedDate = YESTERDAY
					AND (RecordType.DeveloperName = 'Co_Owner_Corporate'
					OR RecordType.DeveloperName = 'Co_Owner_Individual'))
					OR ResponseCode__c != 'SC'
				LIMIT 50000
			]
		);
	}
}