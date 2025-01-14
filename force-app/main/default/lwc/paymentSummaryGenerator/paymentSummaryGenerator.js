import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class PaymentSummaryGenerator extends LightningElement {
    currentRecordId;
	pdfPageName = 'PaymentSummaryForm';
	purpose = 'Document';
	templateMappingType = 'Payment Summary';
	fieldApiSaveToExisting = 'PaymentSummaryDocId__c';
	isGeneratePaymentSummary = false

	@wire(CurrentPageReference)
	getStateParameters(currentPageReference) {
		if (currentPageReference) {
			//it gets executed before the connected callback and avilable to use
			this.currentRecordId = currentPageReference.state.recordId;
			this.isGeneratePaymentSummary = true;
		}
	}
}