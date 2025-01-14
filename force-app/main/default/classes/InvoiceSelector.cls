public with sharing class InvoiceSelector {
	public static InvoiceSelector instance;
	public static InvoiceSelector getInstance() {
		if (instance == null) {
			instance = new InvoiceSelector();
		}
		return instance;
	}

	public List<Invoice__c> getForSendEmail(Date dueDate) {
		return [
			SELECT Id, Opportunity__c, InvoiceDate__c, DueDate__c, DoNotSendInvoice__c, Opportunity__r.ContactPerson__r.Email,
				Opportunity__r.Account.Email__c
			FROM Invoice__c
			WHERE DueDate__c =: dueDate
				AND DoNotSendInvoice__c = false
		];
	}

	public List<Invoice__c> getByOppIdSet(Set<Id> oppIdSet) {
		return [
			SELECT Id, Opportunity__c
			FROM Invoice__c
			WHERE Opportunity__c IN: oppIdSet
		];
	}

	public Invoice__c getById(Id invoiceId) {
		return [
			SELECT Id, Opportunity__c, InvoiceNo__c, AccountAddress__c, IsCancel__c, InvoiceDate__c, DueDate__c,
				Opportunity__r.Name, Opportunity__r.NetPrice__c, Opportunity__r.UnitPrice__c, Opportunity__r.UnitPricePerSqm__c,
				Opportunity__r.NetPricePerSqm__c, Opportunity__r.AreaSqm__c, Opportunity__r.CoBuyerName__c,
				Opportunity__r.Account.Name, Opportunity__r.Account.Phone, Opportunity__r.Account.Email__c,
				Opportunity__r.Account.AddressEN__c, Opportunity__r.Account.AddressTH__c, Opportunity__r.Account.TaxID__c,
				Opportunity__r.ContactPerson__c, Opportunity__r.ContactPerson__r.MobilePhone, Opportunity__r.ContactPerson__r.Email,
				Opportunity__r.Unit__r.Name, Opportunity__r.Unit__r.AreaSqm__c,
				Opportunity__r.Unit__r.UnitType__r.Name,
				Opportunity__r.Project__r.Name, Opportunity__r.Project__r.ProjectLogo__c, Opportunity__r.Project__r.CompanyName__c,
				Opportunity__r.Project__r.CompanyAddress__c, Opportunity__r.Project__r.CompanyPhone__c,
				Opportunity__r.Project__r.CompanyTaxID__c,
				Opportunity__r.Project__r.CompanyAccountNameForInvoice__c, Opportunity__r.Project__r.CompanyAccountNameForInvoice__r.Name,
				Opportunity__r.Project__r.BankAccountNumberForInvoice__c, Opportunity__r.Project__r.CompanyBankNameForInvoice__c,
				Opportunity__r.Project__r.BankBranchForInvoice__c, Opportunity__r.Project__r.BankAddressForInvoice__c,
				Opportunity__r.Project__r.SWIFTCodeForInvoice__c
			FROM Invoice__c
			WHERE Id =: invoiceId
		];
	}

	public Map<Id,Invoice__c> getInvoiceWithInvoiceLineItemsMapById(Set<Id> invoiceIds){
		return new Map<Id,Invoice__c>([
			SELECT
				Id,
				Opportunity__r.Account.AccountCode__c,
				Opportunity__r.Project__r.ProjectCode__c,
				CreatedDate,
				InvoiceNo__c,
				GLKey__c,
				GLDate__c,
				ResponseCode__c,
				ResponseMessage__c,
				LastIntegrationDateTime__c,
				LastCreatedStatusInPojjaman__c,
				LastGLStatusInPojjaman__c,
				(
					SELECT
						Id,
						Invoice__r.Opportunity__r.Unit__r.ProductCode,
						OpportunityPayment__r.Remaining__c,
						Term__c,
						Amount__c,
						Status__c,
						DueDate__c,
						ResponseCode__c,
						ResponseMessage__c,
						LastIntegrationDateTime__c,
						LineNumber__c
					FROM InvoiceLineItems__r
				)
			FROM Invoice__c
			WHERE Id IN: invoiceIds
		]);
	}

	public Map<String, Invoice__c> getInvoiceMapByTerm(Id oppId) {
		Map<String, Invoice__c> invoiceMapByTerm = new Map<String, Invoice__c>();
        List<Invoice__c> invoices = [
            SELECT
                Id,
                Opportunity__r.Account.AccountCode__c,
                Opportunity__r.Project__r.ProjectCode__c,
                CreatedDate,
                InvoiceNo__c,
                GLKey__c,
                ResponseCode__c,
                ResponseMessage__c,
                LastIntegrationDateTime__c,
                LastCreatedStatusInPojjaman__c,
                LastGLStatusInPojjaman__c,
                (
                    SELECT
                        Id,
                        Invoice__r.Opportunity__r.Unit__r.ProductCode,
                        OpportunityPayment__r.Remaining__c,
                        Term__c,
                        Amount__c,
                        Status__c,
                        DueDate__c,
                        ResponseCode__c,
                        ResponseMessage__c,
                        LastIntegrationDateTime__c
                    FROM InvoiceLineItems__r
                )
            FROM Invoice__c
			WHERE Opportunity__c =: oppId
        ];
		for (Invoice__c invoice : invoices){
			InvoiceLineItem__c invoiceLineItem = invoice.InvoiceLineItems__r[0];
			invoiceMapByTerm.put(invoiceLineItem.Term__c , invoice);
		}
		return invoiceMapByTerm;
    }
}