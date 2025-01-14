public with sharing class OrgWideEmailAddressSelector {
	public static OrgWideEmailAddressSelector instance;

	public static OrgWideEmailAddressSelector getInstance() {
		if (instance == null) {
			instance = new OrgWideEmailAddressSelector();
		}
		return instance;
	}

	public List<OrgWideEmailAddress> getByAddress(String email){
		return [
			SELECT Id, Address
			FROM OrgWideEmailAddress 
			WHERE Address =: email
		];
	}
}