@isTest
public with sharing class CurrencyUtilityTest {
	@isTest static void testGetTextTH() {
		Map<Decimal, String> testCaseMap = new Map<Decimal, String>{
			0 => 'ศูนย์บาทถ้วน',
			34.87 => 'สามสิบสี่บาทแปดสิบเจ็ดสตางค์',
			1500000 => 'หนึ่งล้านห้าแสนบาทถ้วน',
			1500001 => 'หนึ่งล้านห้าแสนหนึ่งบาทถ้วน',
			1500010 => 'หนึ่งล้านห้าแสนสิบบาทถ้วน',
			1500021 => 'หนึ่งล้านห้าแสนยี่สิบเอ็ดบาทถ้วน',
			1500000.08 => 'หนึ่งล้านห้าแสนบาทแปดสตางค์',
			1500000.21 => 'หนึ่งล้านห้าแสนบาทยี่สิบเอ็ดสตางค์',
			98721654231.00 => 'เก้าหมื่นแปดพันเจ็ดร้อยยี่สิบเอ็ดล้านหกแสนห้าหมื่นสี่พันสองร้อยสามสิบเอ็ดบาทถ้วน' // 98,721,654,231
		};

		for (Decimal input : testCaseMap.keySet()) {
			String expectedResult = testCaseMap.get(input);
			string actualResult = CurrencyUtility.getInstance().getText(input, 'TH');
			System.assertEquals(expectedResult, actualResult);
		}
	}
	@isTest static void testGetTextEN() {
		Map<Decimal, String> testCaseMap = new Map<Decimal, String>{
			0 => 'Baht Zero Only',
			14.15 => 'Baht Fourteen And Fifteen Satang',
			34.87 => 'Baht Thirty Four And Eighty Seven Satang',
			30.11 => 'Baht Thirty And Eleven Satang',
			10.12 => 'Baht Ten And Twelve Satang',
			20.13 => 'Baht Twenty And Thirteen Satang',
			1500000 => 'Baht One Million Five Hundred Thousand Only',
			1500001 => 'Baht One Million Five Hundred Thousand One Only',
			1500010.08 => 'Baht One Million Five Hundred Thousand Ten And Eight Satang',
			1000000 => 'Baht One Million Only',
			10000000 => 'Baht Ten Million Only',
			100000000 => 'Baht One Hundred Million Only',
			1000000000 => 'Baht One Billion Only',
			10000000000.00 => 'Baht Ten Billion Only',
			// 98721654231.00 => 'เก้าหมื่นแปดพันเจ็ดร้อยยี่สิบเอ็ดล้านหกแสนห้าหมื่นสี่พันสองร้อยสามสิบเอ็ดบาทถ้วน' // 98,721,654,231
			98721654231.00 => 'Baht Ninety Eight Billion Seven Hundred Twenty One Million Six Hundred Fifty Four Thousand Two Hundred Thirty One Only' // 98,721,654,231
		};

		for (Decimal input : testCaseMap.keySet()) {
			String expectedResult = testCaseMap.get(input);
			string actualResult = CurrencyUtility.getInstance().getText(input, 'EN');
			System.assertEquals(expectedResult, actualResult);
		}
	}

	@isTest
	static void testGetTextDouble() {
		string actualResult = CurrencyUtility.getInstance().getText(((Double) 1500010.08), 'EN');
		System.assertEquals(actualResult, 'Baht One Million Five Hundred Thousand Ten And Eight Satang');
	}

	@isTest
	static void testGetTextInteger() {
		string actualResult = CurrencyUtility.getInstance().getText(((Integer) 1000000), 'EN');
		System.assertEquals(actualResult, 'Baht One Million Only');
	}

	@isTest
	static void testGetTextLong() {
		string actualResult = CurrencyUtility.getInstance().getText(((long) 98721654231.00), 'EN');
		System.assertEquals(actualResult, 'Baht Ninety Eight Billion Seven Hundred Twenty One Million Six Hundred Fifty Four Thousand Two Hundred Thirty One Only');
	}

	@isTest
	static void testGetTextString() {
		string actualResult = CurrencyUtility.getInstance().getText(('98721654231.00'), 'EN');
		System.assertEquals(actualResult, 'Baht Ninety Eight Billion Seven Hundred Twenty One Million Six Hundred Fifty Four Thousand Two Hundred Thirty One Only');
	}
}