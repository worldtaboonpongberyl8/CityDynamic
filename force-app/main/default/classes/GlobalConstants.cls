/**
 * Phase2
 * Details:
 * - Init GlobalConstants class
 */
public class GlobalConstants {
    // ----- Opportunity Section -----
	// Stage Name
	public static final String OPP_STAGENAME_QUOTATION = 'Quotation';
	public static final String OPP_STAGENAME_RESERVATION = 'Reservation';
	public static final String OPP_STAGENAME_CONTRACT = 'Contract';
	public static final String OPP_STAGENAME_TRANSFERRED = 'Transferred';
	public static final String OPP_STAGENAME_CLOSED_LOST = 'Closed Lost';
	public static final String OPP_STAGENAME_CLOSED_WON = 'Closed Won';
	public static final String OPP_STAGENAME_SIGNEDNOVATION = 'Signed Novation';

	// Lost Reason
	public static final String OPP_LOST_REASON_NOVATION = 'Novation Case';
	public static final String OPP_LOST_REASON_UPGRADE = 'Upgrade Unit';
	public static final String OPP_LOST_REASON_DOWNGRADE = 'Downgrade Unit';
	public static final String OPP_LOST_REASON_MOVEPAYMENT = 'Cancellation - Move Payment';
	public static final String OPP_LOST_REASON_PURCHASEOTHERNAME = 'Purchase under other name';
	public static final String OPP_LOST_REASON_CANCELREFUND = 'Cancellation - Refunds';
	public static final String OPP_LOST_REASON_CANCELFORFEIT = 'Cancellation - Forfeit';
	public static final String OPP_LOST_REASON_TERMINATIONREFUND = 'Termination - Refunds';
	public static final String OPP_LOST_REASON_TERMINATIONFORFEIT = 'Termination - Forfeit';

	// Termination Type
	public static final String OPP_TERMINATION_TYPE_CANCELLATION = 'Cancellation';
	public static final String OPP_TERMINATION_TYPE_TERMINATION = 'Termination';

	// Termination Sub Type
	public static final String OPP_TERMINATION_SUBTYPE_REFUND = 'Refund';
	public static final String OPP_TERMINATION_SUBTYPE_FORFEIT = 'Forfeit';

	// Quota
	public static final String OPP_QUOTA_THAI = 'Thai';
	public static final String OPP_QUOTA_FOREIGN = 'Foreign';
	// ----- End Opportunity Section -----

	// ----- Opportunity Payment Section -----
	// Term
	public static final String OPP_PAYMENT_TERM_RESERVATION = 'Reservation';
	public static final String OPP_PAYMENT_TERM_CONTRACT = 'Contract';
	public static final String OPP_PAYMENT_TERM_SPLITTED_CONTRACT_1 = 'Contract 1';
	public static final String OPP_PAYMENT_TERM_SPLITTED_CONTRACT_2 = 'Contract 2';
	public static final String OPP_PAYMENT_TERM_SPLITTED_CONTRACT_3 = 'Contract 3';
	public static final String OPP_PAYMENT_TERM_NOVATION = 'Novation';

	// Status
	public static final String OPP_PAYMENT_STATUS_FULLYPAID = 'Fully Paid';
	public static final String OPP_PAYMENT_STATUS_PARTIALLYPAID = 'Partially Paid';
	public static final String OPP_PAYMENT_STATUS_OVERDUE = 'Overdue';
	// ----- End Opportunity Payment Section -----

	// ----- Start Invoice Section -----
	// Cancel Reason
	public static final String INVOICE_LOST_REASON_NOVATION = 'Novation Case';
	public static final String INVOICE_LOST_REASON_UPGRADE = 'Upgrade';
	public static final String INVOICE_LOST_REASON_DOWNGRADE = 'Downgrade';
	public static final String INVOICE_LOST_REASON_MOVEPAYMENT = 'Cancellation - Move Payment';
	public static final String INVOICE_LOST_REASON_CANCELREFUND = 'Cancellation - Refund';
	public static final String INVOICE_LOST_REASON_CANCELFORFEIT = 'Cancellation - Forfeit';
	public static final String INVOICE_LOST_REASON_TERMINATIONREFUND = 'Termination - Refund';
	public static final String INVOICE_LOST_REASON_TERMINATIONFORFEIT = 'Termination - Forfeit';
	public static final String INVOICE_LOST_REASON_CLOSEDLOST = 'Closed Lost';
	// ----- End Invoice Section -----

	// ----- Start Payment Receipt Section -----
	// Cancel Reason
	public static final String RECEIPT_LOST_REASON_CRM = 'Cancel by CRM';
	public static final String RECEIPT_LOST_REASON_NOVATION = 'Novation Case';
	public static final String RECEIPT_LOST_REASON_UPGRADE = 'Upgrade';
	public static final String RECEIPT_LOST_REASON_DOWNGRADE = 'Downgrade';
	public static final String RECEIPT_LOST_REASON_MOVEPAYMENT = 'Cancellation - Move Payment';
	public static final String RECEIPT_LOST_REASON_CANCELREFUND = 'Cancellation - Refund';
	public static final String RECEIPT_LOST_REASON_CANCELFORFEIT = 'Cancellation - Forfeit';
	public static final String RECEIPT_LOST_REASON_TERMINATIONREFUND= 'Termination - Refund';
	public static final String RECEIPT_LOST_REASON_TERMINATIONFORFEIT = 'Termination - Forfeit';
	public static final String RECEIPT_LOST_REASON_CLOSEDLOST = 'Closed Lost';

	// Payment Receipt Type
	public static final String RECEIPT_TYPE_DEFAULT = 'Default';
	public static final String RECEIPT_TYPE_NOVATION = 'Novation';
	public static final String RECEIPT_TYPE_MOVEPAYMENT = 'Move Payment';
	public static final String RECEIPT_TYPE_REFUND_FORFEIT = 'Refund/Forfeit';
	public static final String RECEIPT_TYPE_RECURRING = 'Recurring';
	public static final String RECEIPT_TYPE_PAYMENTGATEWAY = 'Payment Gateway';
	public static final String RECEIPT_TYPE_MOVEPAYMENTNOOPERATION = 'Move Payment Without Operation Fee';

	// Payment Receipt Line Item Type
	public static final String RECEIPTLINE_TYPE_DEFAULT = 'Default';
	public static final String RECEIPTLINE_TYPE_OPERATION = 'Operation';
	public static final String RECEIPTLINE_TYPE_REFUND = 'Refund';
	public static final String RECEIPTLINE_TYPE_FORFEIT = 'Forfeit';


	// Payment Receipt Remark
	public static final String RECEIPT_REMARK_RECURRING = 'Received via Recurring Credit Card Transaction';
	public static final String RECEIPT_REMARK_PAYMENTGATEWAY = 'Received via Payment Gateway';
	// ----- End Payment Receipt Section -----

	// ----- Start Global Map Section -----
	public static final Map<String,String> INVOICE_RECEIPT_LOST_REASON_MAP_BY_OPP_LOST_REASON = new Map<String,String>{
		OPP_LOST_REASON_NOVATION => INVOICE_LOST_REASON_NOVATION,
		OPP_LOST_REASON_UPGRADE => INVOICE_LOST_REASON_UPGRADE,
		OPP_LOST_REASON_DOWNGRADE => INVOICE_LOST_REASON_DOWNGRADE,
		OPP_LOST_REASON_MOVEPAYMENT => INVOICE_LOST_REASON_MOVEPAYMENT,
		OPP_LOST_REASON_PURCHASEOTHERNAME => INVOICE_LOST_REASON_MOVEPAYMENT,
		OPP_LOST_REASON_CANCELREFUND => INVOICE_LOST_REASON_CANCELREFUND,
		OPP_LOST_REASON_TERMINATIONREFUND => INVOICE_LOST_REASON_TERMINATIONREFUND,
		OPP_LOST_REASON_CANCELFORFEIT => INVOICE_LOST_REASON_CANCELFORFEIT ,
		OPP_LOST_REASON_TERMINATIONFORFEIT => INVOICE_LOST_REASON_TERMINATIONFORFEIT
	};
	// ---- End Global Map Section -----

	// ----- Start Co Buyer Section -----
	// Status
	public static final String COBUYER_STATUS_ACTIVE = 'Active';
	public static final String COBUYER_STATUS_INACTIVE = 'Inactive';

	// Quota
	public static final String COBUYER_QUOTA_TQ = 'Thai';
	public static final String COBUYER_QUOTA_FQ = 'Foreign';
	// ----- End Co Buyer Section -----

	// ----- Start Unit Section -----
	// Status
	public static final String UNIT_STATUS_AVAILABLE = 'Available';
	public static final String UNIT_STATUS_BLOCK = 'Block';
	public static final String UNIT_STATUS_SOLD = 'Sold';
	public static final String UNIT_STATUS_RESERVED = 'Reserved';
	public static final String UNIT_STATUS_NOTFORSALES = 'Not for Sales';
	// ----- End Unit Section -----

	// ----- Start Payment Gateway Reference Section -----
	// Status
	public static final String PGF_STATUS_PENDING = 'Pending';
	public static final String PGF_STATUS_ACCEPTED = 'Accepted';
	public static final String PGF_STATUS_REJECTED = 'Rejected';
	public static final String PGF_STATUS_SUCCESS = 'Success';
	public static final String PGF_STATUS_FAIL = 'Fail';
	// ----- End Payment Gateway Reference Section -----

}