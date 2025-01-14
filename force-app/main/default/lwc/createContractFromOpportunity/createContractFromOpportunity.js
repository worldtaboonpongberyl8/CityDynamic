import { LightningElement, api, wire } from "lwc";
import createContractFromOpportunity from "@salesforce/apex/CreateRecordFromOpportunityController.createContractFromOpportunity";
import ConfirmModal from "c/confirmModal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CreateContractFromOpportunity extends NavigationMixin(LightningElement) {
    @api recordId;

    // ----- Start Init -----
    async connectedCallback(){    
        const isConfirm = await ConfirmModal.open({
            size: "small",
            description: "Confirm Action Modal",
            title: "Confirm Action",
            message: "Are you sure you want to create Contract?"
        });
        if (isConfirm) {
            try{
                const contractRecord = await createContractFromOpportunity({oppId : this.recordId});
                this.showToast('Success', 'Contract created successfully!', 'success');
                this.navigateToRecordPage(contractRecord.Id)
            } catch(error) {
                this.showToast('Error', 'Contract not created. Please contact Admin', 'error');
                console.error('ERROR: ' + error)
            }
        } else {
            this.dispatchEvent(new CloseActionScreenEvent());
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