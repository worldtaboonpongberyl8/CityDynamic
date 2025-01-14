import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getLanguagesByMappingType from '@salesforce/apex/DocumentGeneratorController.getLanguages';

export default class SpaGenerator extends LightningElement {
    currentRecordId;
	templateMappingType = 'SPA';
	isGenerateSPA = false;
	languages = [];
	@track language = 'TH/EN';
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
			//it gets executed before the connected callback and avilable to use
			this.currentRecordId = currentPageReference.state.recordId;
		}
	}

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
		setTimeout(() => {
			this.onGenerate();
		}, 300);
	}

	onGenerate(event) {
		this.isGenerateSPA = true;
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