import { LightningElement, api, wire } from "lwc";
import completeNovation from "@salesforce/apex/CompleteNovationController.completeNovation";
import ConfirmModal from "c/confirmModal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CompleteNovation extends NavigationMixin(LightningElement) {
    @api recordId;
	isLoading = true;

    // ----- Start Init -----
    async connectedCallback(){
        const isConfirm = await ConfirmModal.open({
            size: "small",
            description: "Confirm Action Modal",
            title: "Confirm Action",
            message: "Are you sure you want to Complete Novation?"
        });
        if (isConfirm) {
            try{
                const result = await completeNovation({opportunityId : this.recordId});
                this.showToast('Success', 'Complete Novation successfully!', 'success');
				this.isLoading = false;
                this.navigateToRecordPage(result.novatedOpportunity[0].Id);
            } catch(error) {
                this.showToast('Error', 'Complete Novation is Error. Please contact Admin', 'error');
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
    navigateToRecordPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view',
            },
        });
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }
}