public with sharing class CurrencyUtility {
    public static CurrencyUtility instance;
    public static CurrencyUtility getInstance() {
        if (instance == null) {
            instance = new CurrencyUtility();
        }
        return instance;
    }
    private final Integer ROUNDED_PRECISION  = 2;

    private final String[] SCALE_TH = new String[]{ '', 'สิบ', 'ร้อย', 'พัน', 'หมื่น', 'แสน', 'ล้าน' }; // เรียงหลัก เริ่มจากหน่วย
    private final String[] DIGIT_TH = new String[]{ 'ศูนย์', 'หนึ่ง', 'สอง', 'สาม', 'สี่', 'ห้า', 'หก', 'เจ็ด', 'แปด', 'เก้า' };
    private final String[] OTHERS_TH = new String[]{ 'ลบ', 'บาท', 'ถ้วน', 'สตางค์', 'ยี่', 'เอ็ด', 'จุด'};

    private final String[] UNIT_EN = new String[] {
        'Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 
        'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    };
	private final String[] TEN_EN = new String[] {'', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'};
    private final String[] DIGIT_EN = new String[]{ 'Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine' };
    private final String[] OTHERS_EN = new String[]{ 'Minus', 'Baht', 'Only', 'Satang', 'And'};

    private String valueText;
    
    public String getText(Double amount, String language) {
        return getWording(Decimal.valueOf(amount), language);
    }
    
    public String getText(Decimal amount, String language) {
        return getWording(amount, language);
    }
    
    public String getText(Integer amount, String language) {
        return getWording(Decimal.valueOf(amount), language);
    }

    public String getText(long amount, String language) {
        return getWording(Decimal.valueOf(amount), language);
    }

    public String getText(String amount, String language) {
        return getWording(Decimal.valueOf(amount), language);
    }

    private String getWording(Decimal amount, String language) {
        switch on language {
            when 'TH' {
                return getCurrencyWording(amount, language);
            }
            when else {
                return getCurrencyWording(amount, language);
            }
        }
    }

    private String [] getDigitAndDecimal(Decimal decimalNumber){
        String decimalNumberStr = String.valueOf(decimalNumber);
        String[] digitAndDecimal = decimalNumberStr.split('\\.');
        if(digitAndDecimal[1] == null){
            digitAndDecimal[1] = '';
        }

        return digitAndDecimal;
    }

    private String getCurrencyWording(Decimal amount, String language) {
        String numberText = '';
        Decimal absolute = amount.abs();
        integer precision = absolute.precision();
        integer scale = absolute.scale();
        Decimal rounded = absolute.setScale(ROUNDED_PRECISION, RoundingMode.HALF_UP);
        String[] digitAndDecimal = getDigitAndDecimal(rounded);
        String digitTxt = digitAndDecimal[0];
        String decimalTxt = digitAndDecimal[1];

        switch on language {
            when 'TH' {
                if (amount < 0) {
                    // ลบ
                    numberText += OTHERS_TH[0];
                }
                // get wording หน้าทศนิยม
                numberText += getNumberTextTH(amount, Long.valueOf(digitTxt)) + OTHERS_TH[1];
                if(decimalTxt == '00'){
                    // ถ้วน
                    numberText += OTHERS_TH[2];
                }
                else{
                    // get wording หลังทศนิยม
                    // สตางค์
                    numberText += getNumberTextTH(amount, Long.valueOf(decimalTxt)) + OTHERS_TH[3];
                }
            }
            when else {
                if (amount < 0) {
                    // Minus
                    numberText += OTHERS_EN[0];
                }
                // get wording หน้าทศนิยม
                numberText += getNumberTextEN(Long.valueOf(digitTxt));
                if(decimalTxt == '00'){
                    // Only
                    numberText += ' ' + OTHERS_EN[2];
                }
                else{
                    // get wording หลังทศนิยม
                    // And ... Satang
                    numberText += ' ' + OTHERS_EN[4] + ' ' + getNumberTextEN(Long.valueOf(decimalTxt)) + ' ' + OTHERS_EN[3];
                }
                // Baht
                numberText = OTHERS_EN[1] + ' ' + numberText;
            }
        }

        return numberText;
    }

    private String getNumberTextTH(Decimal amount, Long numToConvert) {
        String numberText = '';
        String[] digitChars = String.valueOf(numToConvert).split('');
        Integer digitIndex = 0;
        Integer loopAmount = ((Decimal.valueOf(digitChars.size()) / Decimal.valueOf(SCALE_TH.size())).round(System.RoundingMode.UP)).intValue();

        if(amount == 0){
            return DIGIT_TH[0];
        }

        for (Integer loopIndex = 1; loopIndex <= loopAmount; loopIndex++) {
            Integer previousDigit = 0;
            Integer digitLoopIndex = digitChars.size() - 1;
            
            if(loopAmount > 1){
                if(loopIndex == 1){
                    digitLoopIndex = digitChars.size() - (SCALE_TH.size() * (loopAmount - 1));
                }
                else{
                    digitLoopIndex = SCALE_TH.size() - 2;
                }
            }

            for (Integer index = digitLoopIndex; index >= 0; index--) {
                Integer digit = Integer.valueOf(digitChars[digitIndex]);
                String digitText = DIGIT_TH[digit];
                Integer scaleIndex = index;

                if(digit != 0){
                    if(index == 1){
                        if(digit == 2){
                            // ยี่
                            numberText += OTHERS_TH[4];
                        }
                        else if(digit != 1){
                            numberText += DIGIT_TH[digit];
                        }
                    }
                    else if(index == 0 && digit == 1 && previousDigit > 0){
                        // เอ็ด
                        numberText += OTHERS_TH[5];
                    }
                    else{
                        numberText += DIGIT_TH[digit];
                    }
    
                    numberText += SCALE_TH[scaleIndex];
                }
    
                previousDigit = digit;
                digitIndex++;
            }
            if(loopAmount > 1 && loopIndex != loopAmount){
                numberText += SCALE_TH[SCALE_TH.size() - 1];
            }
        }
        return numberText;
    }
    
    private String getNumberTextEN(long i) {
		if ( i < 20)  return UNIT_EN[integer.valueOf(i)];
		if ( i < 100) return TEN_EN[integer.valueOf(i) / 10] + ((math.mod(i , 10) > 0) ? ' ' + getNumberTextEN(math.mod(i , 10)) : '');
		if ( i < 1000) return UNIT_EN[integer.valueOf(i) / 100] + ' Hundred' + ((math.mod(i , 100) > 0) ? ' ' + getNumberTextEN(math.mod(i , 100)) : '');
		if ( i < 100000) return getNumberTextEN(i / 1000) + ' Thousand' + ((math.mod(i , 1000) > 0) ? ' ' + getNumberTextEN(math.mod(i , 1000)) : '') ;
		if ( i < 1000000) return getNumberTextEN(i / 1000) + ' Thousand' + ((math.mod(i , 1000) > 0) ? ' ' + getNumberTextEN(math.mod(i , 1000)) : '') ;
		if ( i < 100000000) return getNumberTextEN(integer.valueOf(i) / 1000000) + ' Million' + ((math.mod(i , 1000000) > 0) ? ' ' + getNumberTextEN(math.mod(i , 1000000)) : '') ;
		if ( i < integer.valueOf('1000000000')) return getNumberTextEN(i / 1000000) + ' Million' + ((math.mod(i , 1000000) > 0) ? ' ' + getNumberTextEN(math.mod(i , 1000000)) : '') ;
		if ( i < Long.valueOf('10000000000')) return getNumberTextEN(i / 1000000000) + ' Billion' + ((math.mod(i , integer.valueOf('1000000000')) > 0) ? ' ' + getNumberTextEN(math.mod(i , integer.valueOf('1000000000'))) : '') ;
		if ( i < Long.valueOf('100000000000')) return getNumberTextEN(i / integer.valueOf('1000000000')) + ' Billion' + ((math.mod(i , integer.valueOf('1000000000')) > 0) ? ' ' + getNumberTextEN(math.mod(i , integer.valueOf('1000000000'))) : '') ;

		return getNumberTextEN(i / Long.valueOf('100000000000')) + ' Billion' + ((math.mod(i , Long.valueOf('100000000000')) > 0) ? ' ' + getNumberTextEN(math.mod(i , Long.valueOf('100000000000'))) : '') ;
    }
}