import { LightningElement, api, wire } from "lwc";
import completeUnitReleasing from "@salesforce/apex/UnitReleasingController.completeUnitReleasing";
import ConfirmModal from "c/confirmModal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from 'lightning/actions';
import { updateRecord } from 'lightning/uiRecordApi';

export default class UnitReleasing extends LightningElement {
	@api recordId;
	isLoading = true;

	// ----- Start Init -----
	async connectedCallback(){
		const isConfirm = await ConfirmModal.open({
			size: "small",
			description: "Confirm Action Modal",
			title: "Confirm Action",
			message: "Are you sure you want to releas unit?"
		});
		if (isConfirm) {
			try{
				const result = await completeUnitReleasing({unitId : this.recordId});
				this.showToast('Success', 'Release unit successfully!', 'success');
				this.isLoading = false;
				updateRecord({ fields: { Id: this.recordId }})
				this.dispatchEvent(new CloseActionScreenEvent());
			} catch(error) {
				this.showToast('Error', 'Unit releasing is Error. Please contact Admin', 'error');
				this.isLoading = false;
				console.error('ERROR: ' + JSON.stringify(error))
			}
		} else {
			this.dispatchEvent(new CloseActionScreenEvent());
			this.isLoading = false;
		}
	}
	// ----- End Init -----

	// ----- Start Service -----
	showToast(title, message, variant) {
		const toastEvent = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});
		this.dispatchEvent(toastEvent);
	}
}