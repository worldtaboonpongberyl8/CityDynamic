public with sharing class CreateCustomerApiCallout extends b8int_BaseHttpCallout {

	private List<Account> accounts = new List<Account>();

    public CreateCustomerApiCallout(List<Account> accounts) {
        super('Customer');
		this.accounts = accounts;
        this.setCalloutType(b8int_BaseHttpCallout.HttpCalloutType.REALTIME);
        this.setIsRequireRetry(false);
        this.setMethod(b8int_BaseHttpRequest.HttpMethod.POST);
        this.setClient(new CreateCustomerApiClient());
        this.setContentType(b8int_BaseHttpRequest.ContentType.JSON);
        this.setEndpoint('api/CityDynamic/CreateCustomer');
        this.setRequestDataModelClass(RequestDataModel.class);
        this.setResponseDataModelClass(ResponseDataModel.class);
    }

	public override Object buildRequestDataModel() {
		Date todayDate = Date.today();
        List<RequestDataModel> requestDataModels = new List<RequestDataModel>();
		for (Account account : accounts){
			RequestDataModel requestDataModel = new RequestDataModel();
			requestDataModel.SFCustomerId = account.Id;
			requestDataModel.CustomerCode = account.AccountCode__c;
			requestDataModel.CustomerNameEN = account.Name;
			requestDataModel.CustomerNameTH = account.AccountNameTH__c;
			requestDataModel.CustomerType = account.RecordType.DeveloperName == 'Co_Owner_Corporate' ? 'Corporate' : 'Individual' ;
			requestDataModel.AddressEN = account.AddressEN__c;
			requestDataModel.AddressTH = account.AddressTH__c;
			requestDataModel.MailingAddressEN = account.MailingAddressEN__c;
			requestDataModel.MailingAddressTH = account.MailingAddressTH__c;
			requestDataModel.MobilePhone = account.Phone;
			if (account.Fax != null) {
				if (account.FaxExt__c != null){
					requestDataModel.Fax = account.Fax + '-' + account.FaxExt__c;
				}else{
					requestDataModel.Fax = account.Fax;
				}
			} else {
				requestDataModel.Fax = null;
			}
			requestDataModel.Email = account.Email__c;
			requestDataModel.TaxId = requestDataModel.CustomerType == 'Corporate' ? account.TaxID__c : account.Nationality__c == 'Thai' ? account.IDCardNumber__c : account.PassportNo__c ;
			requestDataModel.IDType = requestDataModel.CustomerType == 'Corporate' ? 3 : account.Nationality__c == 'Thai' ? 1 : 2 ;
			requestDataModel.CustomerIndicator = account.AccountCode__c == null ? 0 : 1;
			requestDataModel.IsActiveCustomer = account.Active__c ? 1 : 0;
			List<Contact> contacts = account.Contacts;
			List<ContactRequest> contactRequests = new List<ContactRequest>();
			if (contacts != null){
				for (Contact contact : contacts){
					// if (account.Active__c && !contact.Active__c){
					// 	continue;
					// }
					if (contact.LastModifiedDate.date() == todayDate || contact.ResponseCode__c != 'SCC'){
						ContactRequest contactRequest = new ContactRequest();
						contactRequest.SFContactId = contact.Id;
						contactRequest.Name = contact.FirstName != null ? contact.FirstName + ' ' + contact.LastName : contact.LastName;
						contactRequest.Email = contact.Email;
						contactRequest.MobilePhone = contact.MobilePhone;
						contactRequest.Position = contact.Position__c;
						contactRequest.IsPrimaryContact = contact.IsPrimaryContact__c;
						contactRequest.ContactIndicator = contact.LastCreatedStatusInPojjaman__c == null || contact.LastCreatedStatusInPojjaman__c == 'Fail'  ? 0 : 1;
						contactRequest.IsActiveContact = contact.Active__c ? 1 : 0;
						contactRequests.add(contactRequest);
					}
				}
			}
			requestDataModel.Contacts = contactRequests;
			requestDataModels.add(requestDataModel);
		}
        return requestDataModels;
    }

	public override Boolean processFailedResponse() {
		// stamp server error
		b8int_BaseHttpRequest request = this.getRequestModel();
		b8int_BaseHttpResponse response = this.getResponseModel();
		System.debug('** test ** response: ' + this.getResponseModel());
		List<RequestDataModel> targetRequests = (List<RequestDataModel>)request.getRequestBody();
		String errorDescription = response.getDescription();
		System.debug('** test ** errorDescription:' + errorDescription);
		List<Account> updatedAccounts = new List<Account>();
		List<Contact> updatedContacts = new List<Contact>();
		for (RequestDataModel eachRequest : targetRequests){
			System.debug('** test ** eachRequest:' + eachRequest);
			Account updatedAccount = new Account(
				Id = eachRequest.SFCustomerId,
				ResponseCode__c = 'ERR',
				ResponseMessage__c = errorDescription,
				LastIntegrationDateTime__c = System.now(),
				LastContactIntegrationStatus__c = 'Fail'
			);
			updatedAccounts.add(updatedAccount);
			List<ContactRequest> contactRequests = eachRequest.Contacts;
			if (contactRequests != null){
				for (ContactRequest contactRequest : contactRequests){
					Contact updatedContact = new Contact(
						Id = contactRequest.SFContactId,
						ResponseCode__c = 'ERR',
						ResponseMessage__c = errorDescription,
						LastIntegrationDateTime__c = System.now()
					);
					updatedContacts.add(updatedContact);
				}
			}
		}
		if (!updatedAccounts.isEmpty()){
			update updatedAccounts;
		}
		if (!updatedContacts.isEmpty()){
			update updatedContacts;
		}
        return true;
    }

    public override Boolean processSuccessResponse() {
		AccountSelector accountSelector = AccountSelector.getInstance();
		b8int_BaseHttpResponse response = this.getResponseModel();
		ResponseDataModel targetResponse = (ResponseDataModel)response.getResponseDataModel();
		System.debug('** test **: ' + targetResponse);
		Set<Id> accountIds = new Set<Id>();
		List<AccountResponse> accountResponses = targetResponse.responses;
		for (AccountResponse accountResponse : accountResponses){
			accountIds.add(accountResponse.SFCustomerId);
		}
		Map<Id, Account> accountWithContactsMapById = accountSelector.getAccountWithContactsMapById(accountIds);
		List<Account> updatedAccounts = new List<Account>();
		List<Contact> updatedContacts = new List<Contact>();
		for (AccountResponse accountResponse : accountResponses){
			Account targetAccount = accountWithContactsMapById.get(accountResponse.SFCustomerId);
			Boolean allContactSuccess = true;
			Account updatedAccount = new Account(
				Id = accountResponse.SFCustomerId,
				ResponseCode__c = accountResponse.ResponseCode,
				ResponseMessage__c = accountResponse.Message,
				LastIntegrationDateTime__c = accountResponse.Timestamp
			);
			if (accountResponse.ResponseCode == 'SC'){
				updatedAccount.AccountCode__c = accountResponse.CustomerCode;
			}
			List<Contact> contacts = targetAccount.Contacts;
			Map<Id,Contact> contactMapById = new Map<Id,Contact>();
			if (contacts != null){
				for (Contact contact : contacts){
					contactMapById.put(contact.Id , contact);
				}
			}
			List<ContactResponse> contactResponses = accountResponse.Contacts;
			for (ContactResponse contactResponse : contactResponses){
				Contact targetContact = contactMapById.get(contactResponse.SFContactId);
				targetContact.ResponseCode__c = contactResponse.ResponseCode;
				targetContact.ResponseMessage__c = contactResponse.Message;
				targetContact.LastIntegrationDateTime__c = contactResponse.Timestamp;
				if (targetContact.LastCreatedStatusInPojjaman__c == null){
					targetContact.LastCreatedStatusInPojjaman__c = contactResponse.ResponseCode == 'SCC' ? 'Success' : 'Fail';
				}
				updatedContacts.add(targetContact);
				if (contactResponse.ResponseCode != 'SCC'){
					if (contactResponse.ResponseCode != 'SC') {
						allContactSuccess = false;
					}
				}
			}
			if (!allContactSuccess){
				updatedAccount.LastContactIntegrationStatus__c = 'Fail';
			} else {
				updatedAccount.LastContactIntegrationStatus__c = 'Success';
			}
			updatedAccounts.add(updatedAccount);
		}
		if (!updatedAccounts.isEmpty()){
			update updatedAccounts;
		}
		if (!updatedContacts.isEmpty()){
			update updatedContacts;
		}
        return true;
    }

    public class RequestDataModel extends b8int_BaseRequestDataModel {
		public String SFCustomerId;
		public String CustomerCode;
		public String CustomerNameEN;
		public String CustomerNameTH;
		public String CustomerType;
		public String AddressEN;
		public String AddressTH;
		public String MailingAddressEN;
		public String MailingAddressTH;
		public String MobilePhone;
		public String Fax;
		public String Email;
		public String TaxID;
		public Integer IDType;
		public Integer CustomerIndicator;
		public Integer IsActiveCustomer;
		public List<ContactRequest> Contacts;
    }

	public class ContactRequest{
		public String SFContactId;
		public String Name;
		public String Email;
		public String MobilePhone;
		public String Position;
		public Boolean IsPrimaryContact;
		public Integer ContactIndicator;
		public Integer IsActiveContact;
	}

    public class ResponseDataModel extends b8int_BaseResponseDataModel {
        public Boolean isSuccess;
        public String description;
		public List<AccountResponse> responses;

        public override Boolean isValid() {
            return isSuccess;
        }

        public override String getErrorDescription() {
            return this.description;
        }

    }

	public class AccountResponse{
		public String SFCustomerId;
		public String CustomerCode;
		public Integer ResponseId;
		public String ResponseCode;
		public String Message;
		public Datetime Timestamp;
		public List<ContactResponse> Contacts;
	}

	public class ContactResponse{
		public String SFContactId;
		public Integer ResponseId;
		public String ResponseCode;
		public String Message;
		public Datetime Timestamp;
	}
}