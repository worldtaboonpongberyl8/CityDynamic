import { LightningElement, api, wire } from "lwc";
import syncQuoteFromOpportunity from "@salesforce/apex/SyncQuoteCtrl.syncQuoteFromOpportunity";
import ConfirmModal from "c/confirmModal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class SyncQuote extends NavigationMixin(LightningElement) {
    @api recordId;

    // ----- Start Init -----
    async connectedCallback(){    
        const isConfirm = await ConfirmModal.open({
            size: "small",
            description: "Confirm Action Modal",
            title: "Confirm Action",
            message: "Are you sure you want to Sync Quote?"
        });
        if (isConfirm) {
            try{
                const quoteRecord = await syncQuoteFromOpportunity({quoteId : this.recordId});
                this.showToast('Success', 'Sync Quote successfully!', 'success');
                this.navigateToRecordPage(quoteRecord.Opportunity__c);
            } catch(error) {
                this.showToast('Error', 'Sync Quote is Error. Please contact Admin', 'error');
                console.error('ERROR: ' + JSON.stringify(error))
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