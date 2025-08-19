import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import getLanguagesByMappingType from '@salesforce/apex/DocumentGeneratorController.getLanguages';
import { getRecord } from 'lightning/uiRecordApi';
import getAreaDetails from "@salesforce/apex/ProceedPaymentController.getAreaDetails";

const FIELDS = ['Opportunity.CoBuyerName__c','Opportunity.NewCoOwner__r.Name','Opportunity.Quota__c','Opportunity.NewCoOwner__r.Nationality__c','Opportunity.Project__r.ForeignQuotaArea__c','Opportunity.Unit__r.AreaSqm__c'];

export default class SpaGenerator extends LightningElement {
	@api recordId;
	templateMappingType = 'Novation Agreement';
	isGenerated = false;
	languages = [];
	language = 'TH/EN';
	spinner = true;
	currentAccountName;
	newAccountName;
	currentQuota;
	newQuota;
	isQuotaUnchanged;
	isQuotaChangedToFQ;
	isQuotaChangedToTQ
	totalFQArea;
	areaUsedAsFQ;
	currentArea;
	remainingFQArea;
	remainingFQAreaPercent;

	renderedCallback() {
		const STYLE = document.createElement("style");
		STYLE.innerText = `.uiModal--medium .modal-container, .uiModal--horizontalForm .modal-container {
			width: 40% !important;
		}`;

		this.template.querySelector('lightning-quick-action-panel').appendChild(STYLE);
	}

	@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
	wiredRecord({ error, data }) {
		if (data) {
			console.log('Opp Data: ' + JSON.stringify(data))
			this.currentAccountName = data.fields.CoBuyerName__c.value;
			this.newAccountName = data.fields.NewCoOwner__r.value.fields.Name.value;
			this.currentQuota = data.fields.Quota__c.value == 'Thai' ? 'Thai' : 'Foreign';
			this.newQuota = data.fields.NewCoOwner__r.value.fields.Nationality__c.value == 'Thai' ? 'Thai' : 'Foreign';
			this.isQuotaUnchanged = this.currentQuota == this.newQuota
			this.isQuotaChangedToFQ = this.currentQuota != this.newQuota && this.newQuota == 'Foreign';
			this.isQuotaChangedToTQ = this.currentQuota != this.newQuota && this.newQuota == 'Thai';
			this.totalFQArea = data.fields.Project__r.value.fields.ForeignQuotaArea__c.value;
			this.currentArea = data.fields.Unit__r.value.fields.AreaSqm__c.value;
			getAreaDetails({opportunityId: this.recordId})
				.then(result => {
					this.areaUsedAsFQ = result.areaBookedOrSoldAsFQQuota || 0.00;
					console.log('totalFQArea: ' + this.totalFQArea)
					console.log('areaUsedAsFQ: ' + this.areaUsedAsFQ)
					console.log('currentArea: ' + this.currentArea)
					if (this.isQuotaChangedToFQ){
						this.remainingFQArea = this.totalFQArea - this.areaUsedAsFQ - this.currentArea;
					} else if (this.isQuotaChangedToTQ){
						this.remainingFQArea = this.totalFQArea - this.areaUsedAsFQ + this.currentArea;
					}
					this.remainingFQAreaPercent = parseFloat(((this.remainingFQArea * 100) / this.totalFQArea).toFixed(2))
				}).catch(error => {
					console.error(error)
				})
		} else if (error) {
			console.error('Error fetching record:', error);
		}
	}


	@wire(getLanguagesByMappingType, { templateMappingType: '$templateMappingType' })
	wireLanguages({ data, error }) {
		if (data) {
			console.log(JSON.stringify(data))
			this.languages = data
			this.language = data[0].value;
			this.spinner = false;
		}
		if (error) {
			console.error('wireLanguages:', error);
			this.handlerError(error);
		}

	}

	onGenerate(event) {
		this.isGenerated = true;
	}

	handleCancel(event){
		this.dispatchEvent(new CloseActionScreenEvent({ bubbles: true, composed: true }));
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