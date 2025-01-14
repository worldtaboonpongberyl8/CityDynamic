@isTest
public with sharing class OrgWideEmailAddressSelectorTest {
    @isTest 
	static void getByAddressTest(){
		Test.startTest();
		OrgWideEmailAddressSelector selector = OrgWideEmailAddressSelector.getInstance();
		List<OrgWideEmailAddress> result = selector.getByAddress(null);
		Test.stopTest();
	}
}