@isTest
public with sharing class DateUtilityTest {
	@isTest
	static void toDateTHStringInputDateTest(){
		Map<String, Map<Date, String>> testCaseMap = new Map<String, Map<Date, String>>{
			'EEEE d MMMM yyyy' => new Map<Date, String>{
				Date.newInstance(2024, 7, 1) => 'จันทร์ 1 กรกฎาคม 2567',
				Date.newInstance(2024, 7, 2) => 'อังคาร 2 กรกฎาคม 2567',
				Date.newInstance(2024, 7, 3) => 'พุธ 3 กรกฎาคม 2567',
				Date.newInstance(2024, 7, 4) => 'พฤหัสบดี 4 กรกฎาคม 2567',
				Date.newInstance(2024, 7, 5) => 'ศุกร์ 5 กรกฎาคม 2567',
				Date.newInstance(2024, 7, 6) => 'เสาร์ 6 กรกฎาคม 2567',
				Date.newInstance(2024, 7, 7) => 'อาทิตย์ 7 กรกฎาคม 2567'
			},
			'EE d MMM yy' => new Map<Date, String>{
				Date.newInstance(2024, 7, 1) => 'จ 1 ก.ค. 67',
				Date.newInstance(2024, 7, 2) => 'อ 2 ก.ค. 67',
				Date.newInstance(2024, 7, 3) => 'พ 3 ก.ค. 67',
				Date.newInstance(2024, 7, 4) => 'พฤ 4 ก.ค. 67',
				Date.newInstance(2024, 7, 5) => 'ศ 5 ก.ค. 67',
				Date.newInstance(2024, 7, 6) => 'ส 6 ก.ค. 67',
				Date.newInstance(2024, 7, 7) => 'อา 7 ก.ค. 67'
			},
			'EE. d MMM yy' => new Map<Date, String>{
				Date.newInstance(2024, 7, 1) => 'จ. 1 ก.ค. 67',
				Date.newInstance(2024, 7, 2) => 'อ. 2 ก.ค. 67',
				Date.newInstance(2024, 7, 3) => 'พ. 3 ก.ค. 67',
				Date.newInstance(2024, 7, 4) => 'พฤ. 4 ก.ค. 67',
				Date.newInstance(2024, 7, 5) => 'ศ. 5 ก.ค. 67',
				Date.newInstance(2024, 7, 6) => 'ส. 6 ก.ค. 67',
				Date.newInstance(2024, 7, 7) => 'อา. 7 ก.ค. 67'
			},
			'd MMMM yyyy' => new Map<Date, String>{
				Date.newInstance(2024, 1, 1) => '1 มกราคม 2567',
				Date.newInstance(2024, 2, 2) => '2 กุมภาพันธ์ 2567',
				Date.newInstance(2024, 3, 3) => '3 มีนาคม 2567',
				Date.newInstance(2024, 4, 4) => '4 เมษายน 2567',
				Date.newInstance(2024, 5, 5) => '5 พฤษภาคม 2567',
				Date.newInstance(2024, 6, 6) => '6 มิถุนายน 2567',
				Date.newInstance(2024, 7, 7) => '7 กรกฎาคม 2567',
				Date.newInstance(2024, 8, 8) => '8 สิงหาคม 2567',
				Date.newInstance(2024, 9, 9) => '9 กันยายน 2567',
				Date.newInstance(2024, 10, 10) => '10 ตุลาคม 2567',
				Date.newInstance(2024, 11, 11) => '11 พฤศจิกายน 2567',
				Date.newInstance(2024, 12, 12) => '12 ธันวาคม 2567'
			},
			'd MMM yyyy' => new Map<Date, String>{
				Date.newInstance(2024, 1, 1) => '1 ม.ค. 2567',
				Date.newInstance(2024, 2, 2) => '2 ก.พ. 2567',
				Date.newInstance(2024, 3, 3) => '3 มี.ค. 2567',
				Date.newInstance(2024, 4, 4) => '4 เม.ย. 2567',
				Date.newInstance(2024, 5, 5) => '5 พ.ค. 2567',
				Date.newInstance(2024, 6, 6) => '6 มิ.ย. 2567',
				Date.newInstance(2024, 7, 7) => '7 ก.ค. 2567',
				Date.newInstance(2024, 8, 8) => '8 ส.ค. 2567',
				Date.newInstance(2024, 9, 9) => '9 ก.ย. 2567',
				Date.newInstance(2024, 10, 10) => '10 ต.ค. 2567',
				Date.newInstance(2024, 11, 11) => '11 พ.ย. 2567',
				Date.newInstance(2024, 12, 12) => '12 ธ.ค. 2567'
			}
		};

		for (String formatting : testCaseMap.keySet()) {
			for (Date targetDate : testCaseMap.get(formatting).keySet()) {
				String expectedResult = testCaseMap.get(formatting).get(targetDate);
				string actualResult = DateUtility.getInstance().toDateTHString(formatting, targetDate);
				System.assertEquals(expectedResult, actualResult);
			}
		}
	}

	@isTest
	static void toDateTHStringInputStringTest(){
		Map<String, Map<String, String>> testCaseMap = new Map<String, Map<String, String>>{
			'EEEE d MMMM yyyy' => new Map<String, String>{
				'2024-07-01 00:00:00' => 'จันทร์ 1 กรกฎาคม 2567',
				'2024-07-02 00:00:00' => 'อังคาร 2 กรกฎาคม 2567',
				'2024-07-03 00:00:00' => 'พุธ 3 กรกฎาคม 2567',
				'2024-07-04 00:00:00' => 'พฤหัสบดี 4 กรกฎาคม 2567',
				'2024-07-05 00:00:00' => 'ศุกร์ 5 กรกฎาคม 2567',
				'2024-07-06 00:00:00' => 'เสาร์ 6 กรกฎาคม 2567',
				'2024-07-07 00:00:00' => 'อาทิตย์ 7 กรกฎาคม 2567'
			}
		};

		for (String formatting : testCaseMap.keySet()) {
			for (String targetDate : testCaseMap.get(formatting).keySet()) {
				String expectedResult = testCaseMap.get(formatting).get(targetDate);
				string actualResult = DateUtility.getInstance().toDateTHString(formatting, targetDate);
				System.assertEquals(expectedResult, actualResult);
			}
		}
	}

	@isTest
	static void toDateStringTest() {
		String formatting = 'yyyy-MM-dd';
		Date targetDate = Date.newInstance(2024, 10, 10);
		String result = DateUtility.getInstance().toDateString(formatting, targetDate);
		System.assertEquals('2024-10-10', result, 'The result should match the expected formatted date.');
	}

	@isTest
	static void toDateStringByStringDateTest() {
		String formatting = 'yyyy-MM-dd';
		String targetDate = '2024-10-10 00:00:00'; // Example date in GMT format
		String result = DateUtility.getInstance().toDateString(formatting, targetDate);
		System.assertEquals('2024-10-10', result, 'The result should match the expected formatted date.');
	}

	@isTest
	static void toDateTimeStringTest() {
		String formatting = 'yyyy-MM-dd HH:mm:ss';
		DateTime dt = DateTime.newInstance(2024, 10, 10, 12, 30, 45); // Example DateTime
		String result = DateUtility.getInstance().toDateTimeString(formatting, dt);
		System.assertEquals('2024-10-10 12:30:45', result, 'The result should match the expected formatted DateTime.');
	}

	@isTest
	static void toDateNegativeTest() {
		DateUtility dateUtilility = DateUtility.getInstance();
		Date targetDate;
		DateTime targetDateTime;

		System.assertEquals(null, dateUtilility.toDateString('', targetDate));
		System.assertEquals('', dateUtilility.toDateString('', ''));
		System.assertEquals(null, dateUtilility.toDateTHString('', targetDate));
		System.assertEquals('', dateUtilility.toDateTHString('', ''));
		System.assertEquals(null, dateUtilility.toDateTimeString('', targetDateTime));
	}
}