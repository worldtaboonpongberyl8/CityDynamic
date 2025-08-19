public with sharing class PojjamanDataModel {

    public class FNGLDocRequest extends b8int_BaseRequestDataModel {
		public String CustomerCode;
		public String PreviousCustomerCode;
		public String ProjectCode;
		public String SFDocId;
		public Date DocDate;
		public String DocType;
		public String InvoiceCode;
		public String ReceiptCode;
		public Integer Indicator;
		public String GroupKey;
		public Date GLDate;
		public String Remark;
		public List<String> CoBuyerCustomerCode;
		public List<FNGLDocLineRequest> DocLine;
		public List<FNGLPaymentMethodRequest> PaymentMethod;
	}

	public class FNGLDocLineRequest {
		public Integer LineNumber;
		public String UnitCode;
		public String Type;
		public Decimal Amount;
		public Boolean IsDebit;
		public String SFDocLineId;
		public String Status;
		public Date DueDate;
		public String RefInvoiceId;
	}

	public class FNGLPaymentMethodRequest {
		public String SFPaymentMethodId;
		public String Method;
		public String CreditCardNo;
		public String ChequeNo;
		public String ChequeBranch;
		public String BankBranch;
		public String BankName;
		public String BankAccountNo;
		public String RVBankAccountNo;
		public Date PaymentDate;
		public Decimal Amount;
	}

	public class ResponseDataModel extends b8int_BaseResponseDataModel {
		public Boolean isSuccess;
        public String description;
		public List<FNGLDocResponse> responses;

        public override Boolean isValid() {
            return isSuccess;
        }

        public override String getErrorDescription() {
            return this.description;
        }
	}

	public class FNGLDocResponse {
		public String SFDocId;
		public Integer ResponseId;
		public String ResponseCode;
		public String Message;
		public Datetime Timestamp;
		public List<FNGLDocLineItemResponse> DocLine;
		public List<FNGLPaymentMethodResponse> PaymentMethod;
	}

	public class FNGLDocLineItemResponse {
		public String SFDocLineId;
		public Integer ResponseId;
		public String ResponseCode;
		public String Message;
		public Datetime Timestamp;
	}

	public class FNGLPaymentMethodResponse{
		public String SFPaymentMethodId;
		public Integer ResponseId;
		public String ResponseCode;
		public String Message;
		public Datetime Timestamp;
	}
}