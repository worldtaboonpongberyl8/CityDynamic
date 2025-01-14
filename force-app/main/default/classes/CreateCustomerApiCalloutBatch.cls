public class CreateCustomerApiCalloutBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    public CreateCustomerApiCalloutBatch() {
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
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
					Nationality__c,
                    CountryEN__c,
                    CountryTH__c,
                    CustomerStatus__c,
                    Interest__c,
                    Active__c,
                    ResponseCode__c,
                    ResponseMessage__c,
                    LastIntegrationDateTime__c,
                    LastModifiedDate,
					LastContactIntegrationStatus__c,
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
                            LastModifiedDate,
							LastCreatedStatusInPojjaman__c
                        FROM Contacts
                    )
                FROM Account
                WHERE
                    (RecordType.DeveloperName = 'Co_Owner_Corporate'
                    OR RecordType.DeveloperName = 'Co_Owner_Individual')
                    AND (ResponseCode__c != 'SC'
                    OR LastModifiedDate = TODAY
					OR LastContactIntegrationStatus__c = 'Fail')
					AND Name != 'Dummy for send Email'
				ORDER BY CreatedDate ASC
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        CreateCustomerApiCallout callout = new CreateCustomerApiCallout(scope);
        callout.execute();
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch processing finished.');
        // execute next batch
		CreateInvoiceApiCalloutBatch createInvoiceApiCalloutBatch = new CreateInvoiceApiCalloutBatch();
        Database.executeBatch(createInvoiceApiCalloutBatch, 25);
    }
}