import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getLanguagesByMappingType from '@salesforce/apex/DocumentGeneratorController.getLanguages';

export default class ContractGenrator extends LightningElement {
    currentRecordId;
    templateMappingType = 'Contract';
    isGenerateContract = false;
    languages = [];
    language = 'TH';
	@track spinner = true;
    
    renderedCallback() {
        const STYLE = document.createElement("style");
        STYLE.innerText = `.uiModal--medium .modal-container, .uiModal--horizontalForm .modal-container {
            width: 40% !important;
        }`;

        this.template.querySelector('lightning-quick-action-panel').appendChild(STYLE);
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {

            console.log('1111111111111 currentPageRef: ', currentPageReference);

            //it gets executed before the connected callback and avilable to use
            this.currentRecordId = currentPageReference.state.recordId;
        }
    }

    connectedCallback() {
        // this.callApexMethod();
    }

    // callApexMethod() {
    //     const param = {
    //         recordId: this.templateMappingType
    //     };

    //     getLanguages(param)
    //         .then(result => {
    //             this.languages = result;
    //         })
    //         .catch(error => {
    //             console.error('Error calling Apex method: ', error);
    //         });
    // }

    @wire(getLanguagesByMappingType, { templateMappingType: '$templateMappingType' })
    wireLanguages({ data, error }) {
        if (data) {
          this.languages = data
          this.language = data[0].value;

          if (error) {
              console.error('wireLanguages:', error);
              this.handlerError(error);
          }
        }
        this.spinner = false;
    }

    onGenerate(event) {
        this.isGenerateContract = true;
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

	handlerError(error) {
		if (error && error.body && error.body.message) {
			this.showErrorToast(error.body.message);
		} else {
			this.showErrorToast('Unknown error');
		}
	}
}