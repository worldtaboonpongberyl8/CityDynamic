@isTest
public class b8int_BaseResponseDataModel_Test {
    
    @isTest static void test() {
        b8int_BaseResponseDataModel responseData = new b8int_BaseResponseDataModel();
        responseData.isValid();
        responseData.getErrorDescription();
    }
}