import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class PaymentReceiptGenerator extends LightningElement {
    currentRecordId;
	pdfPageName = 'PaymentReceiptForm';
	purpose = 'Document';
	templateMappingType = 'Payment Receipt';
	fieldApiSaveToExisting = null;
	isGeneratePaymentReceipt = false

	@wire(CurrentPageReference)
	getStateParameters(currentPageReference) {
		if (currentPageReference) {
			//it gets executed before the connected callback and avilable to use
			this.currentRecordId = currentPageReference.state.recordId;
			this.isGeneratePaymentReceipt = true;
		}
	}
}