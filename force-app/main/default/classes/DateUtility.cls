public with sharing class DateUtility {
	
	public static DateUtility instance;

	public static DateUtility getInstance() {
		if (instance == null) {
			instance = new DateUtility();
		}
		return instance;
	}

	public String toDateString(String formatting, Date targetDate) {
		if(targetDate == null){
            return null;
        }
		DateTime dt = DateTime.newInstance(targetDate.year(), targetDate.month(), targetDate.day());
		return formatting == null ? String.ValueOf(targetDate) : dt.format(formatting);
	}

	public String toDateString(String formatting, String targetDate) {
		if(String.isBlank(targetDate)){
            return '';
        }
		DateTime dt = DateTime.valueOfGMT(targetDate);
		return formatting == null ? targetDate : dt.format(formatting);
	}

	public String toDateTHString(String formatting, Date targetDate) {
		if(targetDate == null){
            return null;
        }
		DateTime dt = DateTime.newInstance(targetDate.year(), targetDate.month(), targetDate.day());
		return formatting == null ? String.ValueOf(targetDate) : getTHFormatDate(formatting, dt);
	}

	public String toDateTHString(String formatting, String targetDate) {
		if(String.isBlank(targetDate)){
            return '';
        }
		DateTime dt = DateTime.valueOfGMT(targetDate);

		return formatting == null ? targetDate : getTHFormatDate(formatting, dt);
	}
    
	public String toDateTimeString(String formatting, DateTime dt) {
		if(dt == null) {
            return null;
        }
		return formatting == null ? String.ValueOf(dt) : dt.format(formatting);
	}

	private String getTHFormatDate(String formatting, DateTime dt) {
		String dateWithFormat = getDateFormatTH(formatting, dt);
		
		Map<String, String> dateNameMapWithTHValue = getDateNameMapWithTHValue();
		
		for(String formatKey : dateNameMapWithTHValue.keySet()){
			String value = dateNameMapWithTHValue.get(formatKey);
			dateWithFormat = dateWithFormat.replace(formatKey, (value == null ? '' : value));
		}

		return dateWithFormat;
	}

	private String getDateFormatTH(String formatting, DateTime dt){
		List<String> dayOfWeekFormats = new List<String>();
		List<String> monthFormats = new List<String>();

		for (String character : formatting.split('')) {
			if(character == 'E'){
				dayOfWeekFormats.add(character);
			}
			else if(character == 'M'){
				monthFormats.add(character);
			}
		}

		Datetime dtTH = dt.addYears(543);
		String dateWithFormat = dtTH.format(formatting);

		if(!dayOfWeekFormats.isEmpty()){
			String originalDayOfWeek = dt.format(String.join(dayOfWeekFormats, ''));
			String dayOfWeekTH = dtTH.format(String.join(dayOfWeekFormats, ''));
			dateWithFormat = dateWithFormat.replace(dayOfWeekTH, originalDayOfWeek);
		}
		dateWithFormat = dateWithFormat.toLowerCase();

		if(monthFormats.size() > 3){
			dateWithFormat = dateWithFormat.replace('may', 'mayy');
		}
		
		return dateWithFormat;
	}

	private Map<String, String> getDateNameMapWithTHValue(){
		return new Map<String, String> {
			'monday' => 'จันทร์',
			'tuesday' => 'อังคาร',
			'wednesday' => 'พุธ',
			'thursday' => 'พฤหัสบดี',
			'friday' => 'ศุกร์',
			'saturday' => 'เสาร์',
			'sunday' => 'อาทิตย์',
			'january' => 'มกราคม',
			'february' => 'กุมภาพันธ์',
			'march' => 'มีนาคม',
			'april' => 'เมษายน',
			'mayy' => 'พฤษภาคม',
			'june' => 'มิถุนายน',
			'july' => 'กรกฎาคม',
			'august' => 'สิงหาคม',
			'september' => 'กันยายน',
			'october' => 'ตุลาคม',
			'november' => 'พฤศจิกายน',
			'december' => 'ธันวาคม',
			'mon' => 'จ',
			'tue' => 'อ',
			'wed' => 'พ',
			'thu' => 'พฤ',
			'fri' => 'ศ',
			'sat' => 'ส',
			'sun' => 'อา',
			'jan' => 'ม.ค.',
			'feb' => 'ก.พ.',
			'mar' => 'มี.ค.',
			'apr' => 'เม.ย.',
			'may' => 'พ.ค.',
			'jun' => 'มิ.ย.',
			'jul' => 'ก.ค.',
			'aug' => 'ส.ค.',
			'sep' => 'ก.ย.',
			'oct' => 'ต.ค.',
			'nov' => 'พ.ย.',
			'dec' => 'ธ.ค.'
		};
	}
}