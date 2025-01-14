import { LightningElement, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import createPDFFile from '@salesforce/apex/PDFGeneratorController.createPDFFile';

export default class PdfGenerator extends LightningElement {
    currentPageRef;
    @api currentRecordId;
	@api pdfPageName;
	@api purpose;
	@api templateMappingType;
	@api fieldApiSaveToExisting;

	spinner = true;
	progress = 0;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            //it gets executed before the connected callback and avilable to use
            this.currentPageRef = currentPageReference;

            this.generatefile();
        }
    }

	generatefile(){
		const param = {
			recordId: this.currentRecordId,
			pdfPageName: this.pdfPageName,
			purpose: this.purpose,
			templateMappingType: this.templateMappingType,
			fieldAPISaveToExisting: this.fieldApiSaveToExisting
		};

		createPDFFile(param).then(result => {
			this.showSuccessToast('Starting create a document...');
			this.spinner = false;
			this.toggleProgress();

		}).catch(error => {
			console.error('createPDFFile error: ', error);
			this.handlerError(error);
		});
	}

	toggleProgress(){
		this._interval = setInterval(() => {
			if(this.progress + 7 >= 100){
				this.progress = 100;
				clearInterval(this._interval);

				window.location.href = '/' + this.currentRecordId
			}
			else{
				this.progress = this.progress + 7;
			}
		}, 200);
    }

    showErrorToast(message) {
        this.showSpinner = false;

        const event = new ShowToastEvent({
            title: "Failed !",
            variant: "error",
            message: message,
            mode: "sticky"
        });
        this.dispatchEvent(event);
        this.dispatchEvent(new CloseActionScreenEvent({ bubbles: true, composed: true }));
    }

    showSuccessToast(message) {
        this.showSpinner = false;

        const event = new ShowToastEvent({
            title: "Success !",
            variant: "success",
            message: message
        });
        this.dispatchEvent(event);
    }

    handlerError (error) {
        if (error && error.body && error.body.message) {
            this.showErrorToast(error.body.message);
        } else {
            this.showErrorToast('Unknown error');
        }
    }
}