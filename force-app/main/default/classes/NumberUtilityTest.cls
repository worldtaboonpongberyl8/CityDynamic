@isTest
public with sharing class NumberUtilityTest {
    @isTest
    private static void testGetOrdinalNumber(){
        NumberUtility numberUtil = NumberUtility.getInstance();
        System.assertEquals('', numberUtil.getOrdinalNumber(null));
        System.assertEquals('st', numberUtil.getOrdinalNumber('1'));
        System.assertEquals('nd', numberUtil.getOrdinalNumber('2'));
        System.assertEquals('rd', numberUtil.getOrdinalNumber('3'));
        System.assertEquals('th', numberUtil.getOrdinalNumber('4'));
        System.assertEquals('th', numberUtil.getOrdinalNumber('11'));
        System.assertEquals('th', numberUtil.getOrdinalNumber('12'));
        System.assertEquals('th', numberUtil.getOrdinalNumber('13'));
        System.assertEquals('th', numberUtil.getOrdinalNumber('14'));
    }

    @isTest
    private static void testGetOrdinalName(){
        NumberUtility numberUtil = NumberUtility.getInstance();
        System.assertEquals('', numberUtil.getOrdinalName(null));
        System.assertEquals('', numberUtil.getOrdinalName(0));
        System.assertEquals('FIRST', numberUtil.getOrdinalName(1));
        System.assertEquals('SECOND', numberUtil.getOrdinalName(2));
        System.assertEquals('THIRD', numberUtil.getOrdinalName(3));
        System.assertEquals('FOURTH', numberUtil.getOrdinalName(4));
        System.assertEquals('FIFTH', numberUtil.getOrdinalName(5));
        System.assertEquals('SIXTH', numberUtil.getOrdinalName(6));
        System.assertEquals('SEVENTH', numberUtil.getOrdinalName(7));
        System.assertEquals('EIGHTH', numberUtil.getOrdinalName(8));
        System.assertEquals('NINTH', numberUtil.getOrdinalName(9));
        System.assertEquals('TENTH', numberUtil.getOrdinalName(10));
        System.assertEquals('ELEVENTH', numberUtil.getOrdinalName(11));
        System.assertEquals('TWELFTH', numberUtil.getOrdinalName(12));
        System.assertEquals('THIRTEENTH', numberUtil.getOrdinalName(13));
        System.assertEquals('TWENTIETH', numberUtil.getOrdinalName(20));
        System.assertEquals('TWENTY FIRST', numberUtil.getOrdinalName(21));
        System.assertEquals('TWENTY SECOND', numberUtil.getOrdinalName(22));
        System.assertEquals('TWENTY THIRD', numberUtil.getOrdinalName(23));
        System.assertEquals('TWENTY FOURTH', numberUtil.getOrdinalName(24));
        System.assertEquals('THIRTIETH', numberUtil.getOrdinalName(30));
        System.assertEquals('ONE HUNDREDTH', numberUtil.getOrdinalName(100));
        System.assertEquals('ONE THOUSANDTH', numberUtil.getOrdinalName(1000));
        System.assertEquals('ONE HUNDRED ELEVENTH', numberUtil.getOrdinalName(111));
    }
}