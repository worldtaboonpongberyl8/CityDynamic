import { LightningElement, wire, api } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { getRecord } from 'lightning/uiRecordApi';
import completeRefundForfeit from "@salesforce/apex/CompleteRefundForfeitController.completeRefundForfeit";
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

const FIELDS = ['Opportunity.TotalPaidAmount__c',
				'Opportunity.TotalOperationFee__c',
				'Opportunity.NetAgreedForfeitAmount__c',
				'Opportunity.NetAgreedRefundAmount__c',
				'Opportunity.CancellationTerminationType__c',
				'Opportunity.CancellationTerminationSubType__c',
				'Opportunity.URLRefund__c',
				'Opportunity.URLForfeit__c'
			];

export default class CompleteRefundForfeit extends LightningElement {

	@api recordId;
	totalPaidAmount;
	totalOperationFee;
	netAgreedForfeitAmount;
	netAgreedRefundAmount;
	terminationType;
	terminationSybType;
	urlRefund;
	urlForfeit;
	warningMessage;
	isLoading;

	get isDetailComplete(){
		return this.warningMessage == null;
	}

	get headerLabel(){
		if (this.urlRefund){
			return 'Refund Completed'
		} else {
			return 'Forfeit Completed';
		}
	}

	@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
	wiredRecord({ error, data }) {
		if (data) {
			this.totalPaidAmount = data.fields.TotalPaidAmount__c.value;
			this.totalOperationFee = data.fields.TotalOperationFee__c.value;
			this.netAgreedForfeitAmount = data.fields.NetAgreedForfeitAmount__c.value;
			this.netAgreedRefundAmount = data.fields.NetAgreedRefundAmount__c.value;
			this.terminationType = data.fields.CancellationTerminationType__c.value;
			this.terminationSybType = data.fields.CancellationTerminationSubType__c.value;
			this.urlRefund = data.fields.URLRefund__c.value;
			this.urlForfeit = data.fields.URLForfeit__c.value;
			if (!this.terminationType || !this.terminationSybType){
				this.warningMessage = 'Please select Termination Type and Termination Sub Type';
			}
			// if (!this.netAgreedForfeitAmount){
			// 	this.warningMessage = 'Please enter Net Agreed Forfeit Amount';
			// }
		} else if (error) {
			console.error('Error fetching record:', error);
		}
	}

	renderedCallback() {
		const STYLE = document.createElement("style");
		STYLE.innerText = `.uiModal--medium .modal-container, .uiModal--horizontalForm .modal-container {
			width: 40% !important;
		}`;
		this.template.querySelector('lightning-quick-action-panel').appendChild(STYLE);
	}

	handleCancel(){
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	async handleConfirm(){
		this.isLoading = true;
		try{
			const result = await completeRefundForfeit({opportunityId: this.recordId});
			getRecordNotifyChange([{ recordId: this.recordId }]);
			this.isLoading = false;
			this.dispatchEvent(new CloseActionScreenEvent());
		} catch (error) {
			console.error('ERROR: ' + JSON.stringify(error));
			this.isLoading = false;
			this.dispatchEvent(new CloseActionScreenEvent());
		}

	}
}