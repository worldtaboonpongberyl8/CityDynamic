import { LightningElement, api,wire } from 'lwc';
import completeAction from '@salesforce/apex/OpportunityMoverController.completeAction';
import insertTask from '@salesforce/apex/OpportunityMoverController.insertTask';
import ConfirmModal from "c/confirmModal";
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import hasOutstandingPayments from '@salesforce/apex/OpportunityMoverController.hasOutstandingPayments';
import { NavigationMixin } from 'lightning/navigation';

export default class OpportuntiyMover extends NavigationMixin(LightningElement)  {
    selectedAction = '';
    accountId = null;
	showCard = false;
	showChildren = false;
	validationErrors = [];
	hasValidationErrors = false;
	isLoading = false;

	get accountIdWrapper() {
		return this.accountId;
	}

	set accountIdWrapper(val) {
		if (val) {
			this.accountId = val;
			this.showChildren = true;
		} else {
			const section = this.template.querySelector('.fade-wrapper');
			if (section) {
				section.classList.remove('fade-in');
				section.classList.add('fade-out');

				setTimeout(() => {
					this.showChildren = false;
					this.accountId = null;
				}, 400); // same as animation duration
			} else {
				this.showChildren = false;
				this.accountId = null;
			}
		}
	}

    get actionOptions() {
        return [
            { label: 'Upgrade', value: 'upgrade' },
            { label: 'Downgrade', value: 'downgrade' },
            { label: 'Move Payment', value: 'move_payment' }
        ];
    }

    get disableNewOpp() {
        return !this.currentOpportunityId;
    }

	get sectionName(){
		switch (this.selectedAction) {
			case 'upgrade':
				return 'Upgrade Opportunity';
			case 'downgrade':
				return 'Downgrade Opportunity';
			case 'move_payment':
				return 'Move Payment';
			default:
				return '';
		}
	}

	get isActionSelected() {
		return !!this.selectedAction;
	}

	get actionButtonLabel() {
		switch (this.selectedAction) {
			case 'upgrade':
				return 'Upgrade Completed';
			case 'downgrade':
				return 'Downgrade Completed';
			case 'move_payment':
				return 'Move Payment Completed';
			default:
				return 'Submit';
		}
	}

	get confirmMessage() {
		switch (this.selectedAction) {
			case 'upgrade':
				return 'Are you sure you want to complete the upgrade?';
			case 'downgrade':
				return 'Are you sure you want to complete the downgrade?';
			case 'move_payment':
				return 'Are you sure you want to complete to move payment?';
			default:
				return '';
		}
	}

	get paymentTypeLabel() {
		switch (this.selectedAction) {
			case 'upgrade':
				return 'Upgrade';
			case 'downgrade':
				return 'Downgrade';
			case 'move_payment':
				return 'Move Payment';
			default:
				return '';
		}
	}

	get accountDisplayInfo(){
		return {
			primaryField: 'Name',
			additionalFields: ['IDInfo__c'],
		}
	}

	renderedCallback() {
        this.injectStyle();
    }

	handleActionChange(event) {
		const newAction = event.detail.value;

		// Step 1: fade-out card before hiding
		const cardEl = this.template.querySelector('.outter-fade-wrapper');
		if (cardEl) {
			cardEl.classList.remove('fade-in');
			cardEl.classList.add('fade-out');

			setTimeout(() => {
				// Step 2: Clear values and hide card
				this.showCard = false;
				this.accountId = null;
				this.showChildren = false;
				this.selectedAction = newAction;

				// Step 3: Show card again with fade-in
				setTimeout(() => {
					this.showCard = true;
				}, 10); // Slight delay to allow DOM reset

			}, 400); // Wait for fade-out to finish
		} else {
			// Fallback if no fade-wrapper found
			this.showCard = false;
			this.accountId = null;
			this.showChildren = false;
			this.selectedAction = newAction;
			this.showCard = true;
		}
	}

    handleAccountChange(event) {
        this.accountIdWrapper  = event.detail.recordId;
    }

	async handleCancel() {
		const isConfirm = await ConfirmModal.open({
			size: "small",
			description: "Confirm Action Modal",
			title: "Cancel",
			message: "Are you sure you want to cancel?"
		});
		if (isConfirm) {
			const cardEl = this.template.querySelector('.outter-fade-wrapper');
			if (cardEl) {
				cardEl.classList.remove('fade-in');
				cardEl.classList.add('fade-out');
				setTimeout(() => {
					this.showCard = false;
					this.accountId = null;
					this.showChildren = false;
					setTimeout(() => {
						this.showCard = true;
					}, 10); // Slight delay to allow DOM reset
				}, 400); // Wait for fade-out to finish
			}
		} else {
			this.dispatchEvent(new CloseActionScreenEvent());
		}
	}

	async handleActionComplete(){
		const errors = await this.validateBeforeSubmit();
		if (errors.length > 0) {
			return;
		}
		const isConfirm = await ConfirmModal.open({
			size: "small",
			description: "Confirm Action Modal",
			title: this.actionButtonLabel,
			message: this.confirmMessage
		});
		if (isConfirm) {
			this.isLoading = true;
			try{
				// 🔽 Get references to child components
				const leftChild = this.template.querySelector('c-source-opportunity-to-be-moved');
				const rightChild = this.template.querySelector('c-target-opportunity-to-move-to');
				debugger
				// 🔽 Extract data from children
				const {
					currentOpportunityId,
					operationFee,
					// selectedPromotionIds,
					netPaidAmount,
					moveReason
				} = leftChild.getSelectedSourceOpportunityData();
				debugger
				const {
					url,
					newOpportunityItems,
					selectedPromotions
				} = rightChild.getTargetOpportunityData();
				debugger
				// 🔽 Prepare and run completeAction calls sequentially
				const results = [];
				let isFirstTime = true;
				for (const item of newOpportunityItems) {
					// let selectedPromotionIds = selectedPromotions.filter(promo => promo.toOpportunityId == item.opportunityId).map(promo => promo.id);
					let selectedPromotionIds = selectedPromotions.map(promo => {
						if (!promo.toOpportunityId){
							return promo.id;
						}
						if(promo.toOpportunityId == item.opportunityId){
							return promo.id;
						}
					})
					debugger
					let receivedAmount;
					if (this.selectedAction === 'move_payment') {
						// Get from item (each one should have amountToMove)
						receivedAmount = item.amountToMove || 0.00;
					} else {
						// Use shared netPaidAmount from left child
						receivedAmount = netPaidAmount;
					}
					debugger
					const paymentMethod = {
						PaymentType__c: this.paymentTypeLabel,
						PaymentDate__c: new Date().toISOString().slice(0, 10), // 'YYYY-MM-DD'
						ReceivedAmount__c: receivedAmount
					};
					debugger
					const payload = {
						currentOpportunityId,
						action: this.selectedAction,
						moveReason,
						operationFee,
						receivedAmount,
						url,
						newOpportunityItemJSON: JSON.stringify(item),
						paymentMethod: paymentMethod, // assume it's set in parent
						selectedPromotionAndClientOfferIds: selectedPromotionIds,
						isFirstTime
					};
					debugger

					const result = await completeAction(payload);
					isFirstTime = false;
					results.push(result);
				}

				// 🔽 Prepare task items from results
				// const taskItems = results.map(result => ({
				// 	subject: `${this.actionButtonLabel}`,
				// 	description: 'Generated after action completion',
				// 	oppId: result.newOpportunity?.Id
				// }));

				const taskItems = results.flatMap(result => [
					{
						subject: `${this.paymentTypeLabel} to ${result.newOpportunity?.Name}`,
						description: 'Generated after action completion',
						oppId: result.currentOpportunity?.Id
					},
					{
						subject: `${this.paymentTypeLabel} from ${result.currentOpportunity?.Name}`,
						description: 'Generated after action completion',
						oppId: result.newOpportunity?.Id
					}
				]);
				debugger

				// 🔽 Insert all tasks
				await insertTask({
					taskItemJSON: JSON.stringify(taskItems)
				});

				this.showToast('Success', `${this.actionButtonLabel} successfully completed.`, 'success');
				this.dispatchEvent(new CloseActionScreenEvent());
				this.isLoading = false;
				if (this.selectedAction == 'move_payment') {
					// Redirect to Opportunity list view
					this[NavigationMixin.Navigate]({
						type: 'standard__objectPage',
						attributes: {
							objectApiName: 'Opportunity',
							actionName: 'list'
						},
						state: {
							filterName: 'Recent'
						}
					});
				} else {
					const firstNewOppId = results?.[0]?.newOpportunity.Id;
					if (firstNewOppId) {
						this[NavigationMixin.Navigate]({
							type: 'standard__recordPage',
							attributes: {
								recordId: firstNewOppId,
								objectApiName: 'Opportunity',
								actionName: 'view'
							}
						});
					}
				}
			} catch(error){
				this.isLoading = false;
				console.error(JSON.stringify(error));
				this.dispatchEvent(new CloseActionScreenEvent());
			}
		} else {
			this.dispatchEvent(new CloseActionScreenEvent());
		}
	}

	async validateBeforeSubmit() {
		const errors = [];
		let isValid = true;
		const sourceCmp = this.template.querySelector('c-source-opportunity-to-be-moved');
		const sourceData = sourceCmp?.getSelectedSourceOpportunityData?.();
		console.log('sourceData: ' + sourceData)
		// 1. Validate Current Opportunity is selected
		// const currentOppPicker = sourceCmp?.template.querySelector('[data-id="currentOppPicker"]');
		if (!sourceData?.currentOpportunityId) {
			const msg = 'Please select a Opportunity (From).';
			// sourceCmp.setErrorOppPickers(msg);
			errors.push(msg);
			isValid = false;
		} else {
			// sourceCmp.clearErrorOppPickers();
		}

		// 2. Validate at least 1 New Opportunity is selected
		const targetCmp = this.template.querySelector('c-target-opportunity-to-move-to');
		const targetData = targetCmp?.getTargetOpportunityData?.();
		console.log('targetData: ' + targetData)
		const newOpps = targetData?.newOpportunityItems || [];
		const newOppsPromotions = targetData?.selectedPromotions || [];
		// debugger
		if (newOpps.length === 0 || newOpps.some(o => !o.opportunityId)) {
			const msg = 'Please select at least one Opportunity (To).';
			// targetCmp.setErrorOppPickers(msg);
			errors.push(msg);
			isValid = false;
		} else {
			// targetCmp.clearErrorOppPickers();
		}

		// 3. Validate no duplicates (Current vs New + New vs New)
		const allOppIds = [
			sourceData?.currentOpportunityId,
			...newOpps.map(o => o.opportunityId)
		].filter(Boolean);
		// debugger
		const hasDuplicate = new Set(allOppIds).size !== allOppIds.length;
		if (hasDuplicate) {
			const msg = 'Duplicate Opportunities are not allowed.';
			errors.push(msg);
			// sourceCmp.setErrorOppPickers(msg);
			// targetCmp.setErrorOppPickers(msg);
			isValid = false;
		} else {
			// sourceCmp.clearErrorOppPickers(msg);
			// targetCmp.clearErrorOppPickers(msg);
		}

		// 4. Validate amountToMove for all items (if applicable)
		const isMovePayment = this.selectedAction === 'move_payment';
		if (isMovePayment) {
			// debugger
			// const amountInputs = targetCmp?.template.querySelectorAll('[data-id="moveAmountInput"]');
			newOpps.forEach((o, idx) => {
				if (!o.amountToMove || isNaN(o.amountToMove) || Number(o.amountToMove) <= 0) {
					const msg = 'Enter a valid Move Payment Amount greater than 0.';
					// if (amountInputs?.[idx]) {
					// 	amountInputs[idx].setCustomValidity(msg);
					// 	amountInputs[idx].reportValidity();
					// }
					errors.push(`Opportunity #${idx + 1}: ${msg}`);
					// targetCmp.setErrorOppPickerByIndex(msg,idx);
					isValid = false;
				} else {
					// targetCmp.clearErrorOppPickerByIndex(msg,idx);
				}
			});

			const totalToMove = newOpps.reduce((sum, o) => sum + Number(o.amountToMove || 0), 0);
			// debugger
			if (totalToMove !== sourceData?.netPaidAmount) {
				const msg = `The total Move Payment Amount (${totalToMove}) must equal the Net Paid Amount (${sourceData?.netPaidAmount}).`;
				errors.push(msg);
				isValid = false;
			}
		}

		// 5. Validate URL is not empty
		// const urlInput = targetCmp?.template.querySelector('[data-id="urlInput"]');
		if (!targetData?.url?.trim()) {
			const msg = 'URL is required.';
			// debugger
			errors.push(msg);
			isValid = false;
		} else {
			const urlRegex = /^(https?:\/\/)?(www\.)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(\/[^\s]*)?$/;
			if (!urlRegex.test(targetData.url.trim())) {
				const msg = 'Enter a valid URL like www.example.com';
				errors.push(msg);
				isValid = false;
			}
		}

		// 6. Validate outstanding payments (only for upgrade)
		const allSourceOppIds = [sourceData?.currentOpportunityId].filter(Boolean);
		if (this.selectedAction === 'upgrade' && allSourceOppIds.length > 0) {
			console.log('allSourceOppIds: ' + allSourceOppIds)
			try {
				const hasUnpaid = await hasOutstandingPayments({ opportunityIds: allSourceOppIds });
				if (hasUnpaid) {
					const msg = 'Opportunity (From) have unpaid payments due today or earlier.';
					errors.push(msg);
					isValid = false;
				}
			} catch (e) {
				const msg = 'Unable to validate outstanding payments.';
				console.error(e);
				errors.push(msg);
				isValid = false;
			}
		}

		// 7. Validate selected Opportunity to move promotion to
		if (isMovePayment) {
			const hasNullToOpportunity = newOppsPromotions.some(
				promo => !promo.toOpportunityId
			);
			if (hasNullToOpportunity){
				const msg = 'Please select a Opportunity (To) for each Promotion.';
				errors.push(msg);
				isValid = false;
			}
		}

		this.validationErrors = errors;
		this.hasValidationErrors = errors.length > 0;
		return isValid ? [] : errors;
	}


	injectStyle() {
		const style = document.createElement("style");
		style.innerText = `
			/* Style for lightning-record-picker input */
			.custom-picker lightning-record-picker .slds-combobox__input {
				border: none !important;
				border-bottom: 1px solid #d8dde6 !important;
				border-radius: 0 !important;
				background: transparent !important;
				box-shadow: none !important;
			}
			.custom-combobox lightning-combobox .slds-combobox__input {
				border: none !important;
				border-bottom: 1px solid #d8dde6 !important;
				border-radius: 0 !important;
				background: transparent !important;
				box-shadow: none !important;
				text-align: left !important; /* Keep default alignment */
			}

			/* Allow the dropdown to expand beyond the combobox width */
			.custom-combobox-wrapper .slds-dropdown {
				min-width: 350px !important; /* or whatever wider value you prefer */
				width: auto !important;
				left: auto !important;
				right: 0 !important;
				z-index: 999 !important
			}

			/* Optional: allow it to overflow its parent wrapper */
			.custom-combobox-wrapper {
				overflow: visible !important;
				position: relative;
			}

			/* Optional: adjust dropdown to not clip */
			.slds-dropdown {
				max-width: none !important;
			}

			.remove-icon-button lightning-primitive-icon svg {
				fill: #e60000 !important; /* Red color */
			}

			/* Optional hover effect */
			.remove-icon-button:hover lightning-primitive-icon svg {
				fill: #b50000 !important; /* Darker red on hover */
			}
		`;
		document.body.appendChild(style);
	}

	showToast(title, message, variant = 'info') {
		this.dispatchEvent(
			new ShowToastEvent({
				title: title,
				message: message,
				variant: variant,
				mode: 'dismissable'
			})
		);
	}


}