public with sharing class NumberUtility {
	public static NumberUtility instance;

	public static NumberUtility getInstance() {
		if (instance == null) {
			instance = new NumberUtility();
		}
		return instance;
	}

	public String setDecToFormatCommaTwoDigits(String numberInput) {
		if(String.isBlank(numberInput)){
			return '';
		}

		return setDecToFormatCommaTwoDigits(decimal.valueOf(numberInput));
	}

	public String setDecToFormatCommaTwoDigits(Decimal numberInput) {
		if(numberInput == null){
			return '0.00';
		}

		String minusTxt = '';
		if(numberInput < 0){
			numberInput = numberInput * (-1);
			minusTxt = '-';
		}
		numberInput = numberInput.doubleValue() * 1.00;
		Long numberLong = (Long)numberInput.longValue();
		Decimal numberDigit = numberInput - numberLong;
		return minusTxt + numberLong.format() + String.valueOf(Decimal.valueOf(numberDigit.doubleValue()).setScale(2)).substring(1, 4);
	}

	public Decimal getConvertNumberNotNull(Decimal numberInput){
		if(numberInput == null){
			return 0.00;
		}
		return numberInput;
	}

	public String getOrdinalNumber(String noTxt){
		if(String.isEmpty(noTxt) || !noTxt.isNumeric()){
			return '';
		}

		String lastNoTxt = '';

		if(noTxt.length() == 1){
			lastNoTxt = noTxt;
		}
		else{
			// ปกติถ้าลงท้ายด้วยจะใช้ 1(st), 2(nd), 3(nd)
			// แต่ถ้าลงท้ายด้วย 11, 12, 13 จะใช้ th เช่น 111(th)
			Integer noTwoEndWord = Integer.valueOf(noTxt.right(2));
			// เลยต้องตัด 2 ตัวท้ายส่งไป
			if(noTwoEndWord >= 11 && noTwoEndWord <= 13){
				lastNoTxt = noTxt.right(2);
			}
			else{
				lastNoTxt = noTxt.right(1);
			}
		}
		return getOrdinalText(noTxt);
	}

	private String getOrdinalText(String lastNoTxt){
		// ปกติถ้าลงท้ายด้วยจะใช้ 1(st), 2(nd), 3(nd)
		// แต่ถ้าลงท้ายด้วย 11, 12, 13 จะใช้ th เช่น 111(th)

		switch on lastNoTxt {
			when '1' {
				return 'st';
			}
			when '2' {
				return 'nd';
			}
			when '3' {
				return 'rd';
			}
			when else {
				return 'th';
			}
		}
	}

	public String getOrdinalName(Integer no){
		List<String> ordinalNormalWordings = new List<String>{
			'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'FIFTH', 'SIXTH', 'SEVENTH', 'EIGHTH', 'NINTH'
		};
		List<String> ordinalTenWordings = new List<String>{
			'TENTH', 'TWEN', 'THIR', 'FOR', 'FIF', 'SIX', 'SEVEN', 'EIGH', 'NINE'
		};
		List<String> cardinalNormalWordings = new List<String>{
			'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGH', 'NINE'
		};
		List<String> cardinalEndNormalWordings = new List<String>{
			'', 'TY', 'HUNDRED', 'THOUSAND'
		};

		if(no == null || no == 0){
			return '';
		}

		String noTxt = String.valueOf(no);
		Integer noLength = noTxt.length();
		String previousNoTxt = noTxt.left(1);

		switch on noLength {
			when 1 {
				return ordinalNormalWordings.get(no - 1);
			}
			when 2 {
				return getOrdinalNameTwoDigit(noTxt, ordinalNormalWordings, ordinalTenWordings);
			}
			when else {
				if(noTxt.right(1) == '0'){
					return cardinalNormalWordings.get( (Integer.valueOf(previousNoTxt) - 1) ) + ' ' +
					cardinalEndNormalWordings.get( (Integer.valueOf(noLength) - 1) ) + 'TH';
				}
				else{
					return cardinalNormalWordings.get( (Integer.valueOf(previousNoTxt) - 1) ) + ' ' +
					cardinalEndNormalWordings.get( (Integer.valueOf(noLength) - 1) ) + ' ' +
					getOrdinalNameTwoDigit(noTxt.right(2), ordinalNormalWordings, ordinalTenWordings);
				}
			}
		}
	}

	private String getOrdinalNameTwoDigit(String noTxt, List<String> ordinalNormalWordings, List<String> ordinalTenWordings){
		String previousNoTxt = noTxt.left(1);
		String lastNoTxt = noTxt.right(1);

		if(lastNoTxt == '0'){
			if(previousNoTxt == '1'){
				return ordinalTenWordings.get( (Integer.valueOf(previousNoTxt) - 1) );
			}
			else{
				return ordinalTenWordings.get( (Integer.valueOf(previousNoTxt) - 1) ) + 'TIETH';
			}
		}
		else{
			if(previousNoTxt == '1'){
				if(noTxt == '11'){
					return 'ELEVENTH';
				}
				else if(noTxt == '12'){
					return 'TWELFTH';
				}
				else{
					return ordinalTenWordings.get( (Integer.valueOf(lastNoTxt) - 1) ) + 'TEENTH';
				}
			}
			else{
				return ordinalTenWordings.get( (Integer.valueOf(previousNoTxt) - 1) ) + 'TY ' + 
				ordinalNormalWordings.get( (Integer.valueOf(lastNoTxt) - 1) );
			}
		}
	}
}