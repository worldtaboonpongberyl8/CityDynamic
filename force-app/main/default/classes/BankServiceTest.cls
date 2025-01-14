@isTest
public with sharing class BankServiceTest {
	@isTest
	static void getBankNameLabelMapByValueTest(){
		Map<String, String> bankNameLabelMapByValue = BankService.getInstance().getBankNameLabelMapByValue();
		System.assert(!bankNameLabelMapByValue.keySet().isEmpty());
		System.assertEquals('Bangkok Bank', bankNameLabelMapByValue.get('BBL'));
	}
}