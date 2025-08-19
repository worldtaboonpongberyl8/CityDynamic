import { LightningElement, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import ConfirmModal from "c/confirmModal";
import createRecurringTextFileAndDownload from '@salesforce/apex/RecurringTextFileGeneratorController.createRecurringTextFileAndDowdload';

export default class RecurringTextFileGenerator extends LightningElement {
        @api recordId;

        spinner = true;
        progress = 0;

        async connectedCallback() {
            const isConfirm = await ConfirmModal.open({
                size: 'small',
                description: 'Confirm Action Modal',
                title: 'Confirm Action',
                message: 'Are you sure you want to generate a Recurring Text File?'
            });

            if (!isConfirm) {
                this.dispatchEvent(new CloseActionScreenEvent());
                return;
            }
            try {
                const result = await createRecurringTextFileAndDownload({
                    recordId: this.recordId
                });

                if (result && typeof result === 'string') {
                    console.log('File URL:', result);
                    window.open(result, '_blank'); // Opens the file download link
                    this.showToast('Success', 'Recurring file generated successfully!', 'success');
					this.dispatchEvent(new CloseActionScreenEvent());
                } else {
                    this.showToast('Warning', 'File was not created.', 'warning');
					this.dispatchEvent(new CloseActionScreenEvent());
                }

            } catch (error) {
                console.error('createRecurringTextFileAndDownload error:', error);
                this.handlerError(error);
                this.showToast('Error', 'An error occurred while generating the file.', 'error');
				this.dispatchEvent(new CloseActionScreenEvent());
            }
        }


        showToast(title, message, variant) {
            const toastEvent = new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            });
            this.dispatchEvent(toastEvent);
        }

        handlerError (error) {
            if (error && error.body && error.body.message) {
                this.showErrorToast(error.body.message);
            } else {
                this.showErrorToast('Unknown error');
            }
        }
}