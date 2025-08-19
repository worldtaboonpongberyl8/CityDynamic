import { LightningElement,api,wire } from 'lwc';
import getOpportunityDetails from "@salesforce/apex/OpportunityMoverController.getOpportunityDetails";
import { publish, MessageContext } from "lightning/messageService";
import sourceOppToTargetOpp from "@salesforce/messageChannel/sourceOppToTargetOpp__c";

export default class SourceOpportunityToBeMoved extends LightningElement {

	_accountId;
	@api
	set accountId(value){
		this._accountId = value;
		// this.clearData();
	}
	get accountId(){
		return this._accountId;
	}

	_selectedAction
	@api
	set selectedAction(value){
		this._selectedAction = value;
	}
	get selectedAction(){
		return this._selectedAction;
	}

	@api
	getSelectedSourceOpportunityData() {
		return {
			currentOpportunityId: this.currentOpportunityId,
			operationFee: this.operationFee,
			// selectedPromotionIds: [
			// 	...(this.currentOppDetails?.opportunityPromotions || [])
			// 		.filter(p => p.isChecked)
			// 		.map(p => p.id),
			// 	...(this.currentOppDetails?.clientOffers || [])
			// 		.filter(p => p.isChecked)
			// 		.map(p => p.id)
			// ],
			netPaidAmount : this.netPaidAmount,
			moveReason : this.moveReason
		};
	}

	@api
	setErrorOppPickers(msg) {
		const oppPicker = this.template.querySelector('[data-id="currentOppPicker"]');
		if (oppPicker) {
			oppPicker.setCustomValidity(msg);
			oppPicker.reportValidity();
		}
	}

	@api
	clearErrorOppPickers() {
		const oppPicker = this.template.querySelector('[data-id="currentOppPicker"]');
		if (oppPicker) {
			oppPicker.setCustomValidity('');
			oppPicker.reportValidity();
		}
	}

	currentOpportunityId;
	currentOppDetails;
	isLoading;
	isShowOperationFee = true;
	operationFee = 0;
	netPaidAmount = 0;
	detailWrapperClass = 'fade-in fade-wrapper'
	hasLoadedOnce = false;
	moveReason;

	opportunityMatchingInfo = {
		primaryField: { fieldPath: 'Name', mode: 'startsWith' },
		additionalFields: [{ fieldPath: 'Unit__r.Name' }],
	};

	get opportunityFilter(){
		return {
			criteria: [
				// 1: AccountId = selected account
				{
					fieldPath: 'AccountId',
					operator: 'eq',
					value: this.accountId
				},
				// 2: StageName = Reservation
				{
					fieldPath: 'StageName',
					operator: 'eq',
					value: 'Reservation'
				},
				// 3: StageName = Contract
				{
					fieldPath: 'StageName',
					operator: 'eq',
					value: 'Contract'
				},
				// 4: IsCompletedContract__c = true (used with 3 or 5)
				{
					fieldPath: 'IsCompletedContract__c',
					operator: 'eq',
					value: true
				},
				// 5: StageName = Signed Novation
				{
					fieldPath: 'StageName',
					operator: 'eq',
					value: 'Signed Novation'
				},
				// 6: StageName = Closed Lost
				{
					fieldPath: 'StageName',
					operator: 'eq',
					value: 'Closed Lost'
				},
				// 7: LossReason__c = Purchase under other name
				{
					fieldPath: 'LossReason__c',
					operator: 'eq',
					value: 'Purchase under other name'
				}
			],
			filterLogic: '1 AND (2 OR (3 AND 4) OR (5 AND 4) OR (6 AND 7))'
		};
	}

	get reasonLabel(){
		switch (this.selectedAction) {
			case 'upgrade':
				return 'Upgrade Reason';
			case 'downgrade':
				return 'Downgrade Reason';
			case 'move_payment':
				return 'Move Payment Reason';
			default:
				return '';
		}
	}

	get hasOpportunityPromotion(){
		return this.currentOppDetails?.opportunityPromotions?.length > 0;
	}

	get hasClientOffer(){
		return this.currentOppDetails?.clientOffers?.length > 0;
	}

	get hasReceivedPromotion(){
		return this.currentOppDetails?.receivedPromotions?.length > 0;
	}

	get isMovePayment() {
		return this.selectedAction === 'move_payment';
	}

	@wire(MessageContext)
    messageContext;

	renderedCallback() {
        this.injectStyle();
    }

	async handleCurrentOppChange(event) {
		// this.highlightValidationErrors('');
		this.currentOpportunityId = event.detail.recordId;
		// Start fade-out animation
		if (this.hasLoadedOnce){
			this.detailWrapperClass = 'fade-out fade-wrapper';
		}
		this.currentOppDetails = {};
		if (this.currentOpportunityId) {
			await this.loadOpportunityDetails(this.currentOpportunityId);
		}
	}

	async loadOpportunityDetails(oppId) {
		// this.isLoading = true;
		try{
			let result = await getOpportunityDetails({
				opportunityId: oppId,
			})
			const details = {
				projectName: result.projectName,
				unitName: result.unitName,
				unitCode: result.unitCode,
				netPrice: result.netPrice || 0.00,
				totalPaidAmount: result.totalPaidAmount || 0.00,
				opportunityPromotions: result.opportunityPromotions || [],
				clientOffers: result.clientOffers || [],
				receivedPromotions: result.receivedPromotions || [],
				stageName : result.stageName
			};
			this.currentOppDetails = details;
			this.netPaidAmount = details.totalPaidAmount
			console.log('opportunityPromotions: ' + JSON.stringify(details.opportunityPromotions))
			console.log('clientOffers: ' + JSON.stringify(details.clientOffers))
			this.isShowOperationFee = details.stageName === 'Closed Lost' ? false : true;
			this.operationFee = 0;
			this.hasLoadedOnce = true;
			this.detailWrapperClass = 'fade-in fade-wrapper';
			// this.isLoading = false
			publish(this.messageContext, sourceOppToTargetOpp, {
				method: 'setSelectedSourceOpportunity',
				payload: {
					oppId : oppId,
					unitCodes : details.unitCode,
					stageName : details.stageName
				}
			});
		} catch (error) {
			// this.isLoading = false
			this.hasLoadedOnce = true;
			this.detailWrapperClass = 'fade-in fade-wrapper';
			console.error('Error loading Opportunity details:', JSON.stringify(error));
		}
	}

	handleSelectOpportunityPromotion(event){
		const recordId = event.target.dataset.id;
		const isChecked = event.target.checked;
		let selectedItem = this.currentOppDetails.opportunityPromotions.find(oppPromotion => oppPromotion.id === recordId);
		console.log('selectedItem: ' + selectedItem);
		if (selectedItem) {
			publish(this.messageContext, sourceOppToTargetOpp, {
				method: 'setSelectedPromotion',
				payload: {...selectedItem , isChecked}
			});
		}
	}

	handleSelectClientOffer(event){
		const recordId = event.target.dataset.id;
		const isChecked = event.target.checked;
		let selectedItem = this.currentOppDetails.clientOffers.find(clientOffer => clientOffer.id === recordId);
		console.log('selectedItem: ' + selectedItem);
		if (selectedItem) {
			publish(this.messageContext, sourceOppToTargetOpp, {
				method: 'setSelectedPromotion',
				payload: {...selectedItem , isChecked}
			});
		}
	}

	handleOperationFeeChange(event) {
		const rawValue = event.target.value;
		let fee = 0.00;
		if (rawValue && !isNaN(rawValue)) {
			fee = Math.round(parseFloat(rawValue) * 100) / 100;
		}
		this.operationFee = fee;
		const totalPaid = this.currentOppDetails?.totalPaidAmount || 0.00;
		this.netPaidAmount = totalPaid - this.operationFee;
	}

	handleMoveReasonChange(event){
		this.moveReason = event.target.value;
	}

	injectStyle() {
		const style = document.createElement("style");
		style.innerText = `
			/* Right-align number input inside lightning-input */
			.custom-input-wrapper .number-input input {
				text-align: right !important;
				border: none !important;
				border-bottom: 1px solid #d8dde6 !important;
				border-radius: 0 !important;
				background: transparent !important;
				box-shadow: none !important;
			}

			/* Hide date formatting helper text */
			.date-format-hide .slds-form-element__help {
				display: none !important;
			}

			/* Force-show something hidden by SLDS (if needed) */
			.date-format-hide .slds-show {
				display: block !important;
			}

			/* Custom style for disabled input */
			.slds-input[disabled],
			.slds-input.slds-is-disabled {
				color: #a49e9e !important;
				border-color: #a49e9e !important;
			}

			/* Modernized URL input (matches number style but left aligned) */
			.url-input input {
				border: none !important;
				border-bottom: 1px solid #d8dde6 !important;
				border-radius: 0 !important;
				background: transparent !important;
				box-shadow: none !important;
			}

			/* Modernized Text input (matches number style but left aligned) */
			.text-input input {
				border: none !important;
				border-bottom: 1px solid #d8dde6 !important;
				border-radius: 0 !important;
				background: transparent !important;
				box-shadow: none !important;
				min-width : 50vh !important
			}
		`;
		document.body.appendChild(style);
	}

	// clearData(){
	// 	this.currentOpportunityId = null;
	// 	this.currentOppDetails = null;
	// 	const oppPicker = this.template.querySelector('[data-id="currentOppPicker"]');
	// 	oppPicker.clearData();
	// }
}