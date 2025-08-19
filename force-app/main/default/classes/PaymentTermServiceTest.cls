@isTest
public with sharing class PaymentTermServiceTest {
    @isTest
    static void getPaymentTermLineItemFromJSONStringTest() {
        Test.startTest();
        PaymentTermService service = PaymentTermService.getInstance();
        List<PaymentTermService.PaymentTermLineItemWrapper> paymentTermWrappers = new List<PaymentTermService.PaymentTermLineItemWrapper>();
        PaymentTermService.PaymentTermLineItemWrapper wrapper1 = new PaymentTermService.PaymentTermLineItemWrapper();
        wrapper1.id = null;
        wrapper1.order = 1;
        wrapper1.amount = 100.00;
        wrapper1.percent = null;
        wrapper1.term = 'Contract';
        wrapper1.isAllowedPayment = false;
        wrapper1.paymentTermMasterId = null;
        PaymentTermService.PaymentTermLineItemWrapper wrapper2 = new PaymentTermService.PaymentTermLineItemWrapper();
        wrapper2.id = null;
        wrapper2.order = 2;
        wrapper2.amount = null;
        wrapper2.percent = null;
        wrapper2.term = 'Transfer';
        wrapper2.isAllowedPayment = false;
        wrapper2.paymentTermMasterId = null;
        paymentTermWrappers.add(wrapper1);
        paymentTermWrappers.add(wrapper2);
        String paymentTermLineItemJSON = JSON.serialize(paymentTermWrappers);
        List<PaymentTerm__c> result = service.getPaymentTermLineItemFromJSONString(paymentTermLineItemJSON);
        PaymentTerm__c paymentTerm1 = result[0];
        PaymentTerm__c paymentTerm2 = result[1];
        System.assertEquals(2, result.size());
        System.assertEquals(wrapper1.order, paymentTerm1.Order__c);
        System.assertEquals(wrapper1.term, paymentTerm1.Term__c);
        System.assertEquals(wrapper2.order, paymentTerm2.Order__c);
        System.assertEquals(wrapper2.term, paymentTerm2.Term__c);
        Test.stopTest();
    }
}