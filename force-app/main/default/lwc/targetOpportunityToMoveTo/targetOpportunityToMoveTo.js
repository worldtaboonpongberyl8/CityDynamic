import { LightningElement,api,wire } from 'lwc';
import getOpportunityDetails from "@salesforce/apex/OpportunityMoverController.getOpportunityDetails";
import { subscribe, MessageContext } from "lightning/messageService";
import sourceOppToTargetOpp from "@salesforce/messageChannel/sourceOppToTargetOpp__c";

export default class TargetOpportunityToMoveTo extends LightningElement {

	_selectedSourceUnitCode;
	set selectedSourceUnitCode(value){
		this._selectedSourceUnitCode = value;
	}
	get selectedSourceUnitCode(){
		return this._selectedSourceUnitCode;
	}

	_selectedSourceOpportunityId;
	set selectedSourceOpportunityId(value){
		this._selectedSourceOpportunityId = value;
	}
	get selectedSourceOpportunityId(){
		return this._selectedSourceOpportunityId;
	}

	_selectedSourceOpportunityStageName
	set selectedSourceOpportunityStageName(value){
		this._selectedSourceOpportunityStageName = value;
	}
	get selectedSourceOpportunityStageName(){
		return this._selectedSourceOpportunityStageName;
	}

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
	getTargetOpportunityData() {
		return {
			url: this.urlDoc,
			newOpportunityItems: this.newOpportunities
				.filter(item => item.newOpportunityId && item.newOppDetails)
				.map(item => ({
					opportunityId: item.newOpportunityId,
					amountToMove: item.amountToMove || 0 // you may want to ensure this is set earlier
				})),
			selectedPromotions: this.selectedPromotions
		};
	}

	@api
	highlightValidationErrors() {
		this.newOpportunities.forEach((item, index) => {
			// Opportunity Picker
			const oppPicker = this.template.querySelector(`lightning-record-picker[data-index="${index}"]`);
			if (oppPicker && !item.newOpportunityId) {
				oppPicker.reportValidity();
			}

			// Amount to Move (for move_payment)
			if (this.selectedAction === 'move_payment') {
				const amountInput = this.template.querySelector(`lightning-input[data-id="amountToMove-${index}"]`);
				if (amountInput && (!item.amountToMove || Number(item.amountToMove) <= 0)) {
					amountInput.reportValidity();
				}
			}
		});

		// URL input
		const urlInput = this.template.querySelector('.url-input');
		if (urlInput && (!this.urlDoc || !this.urlDoc.trim())) {
			urlInput.reportValidity();
		}
	}

	// @api
	// highlightValidationErrorsOppPicker(msg) {
	// 	const oppPicker = this.template.querySelectorAll('[data-id="currentOppPicker"]');
	// 	if (oppPicker) {

	// 	}
	// }

	isLoading;
	urlDoc;

	newOpportunities = [
		{
			key : 1,
			newOpportunityId : null,
			newOppDetails : {
				hasOpportunityPromotion: false,
				hasClientOffer: false
			},
			isShowDetail : false,
			detailWrapperClass: '',
			hasLoadedOnce: false,
			amountToMove: 0.00
		}
	]

	opportunityMatchingInfo = {
		primaryField: { fieldPath: 'Name', mode: 'startsWith' },
		additionalFields: [{ fieldPath: 'Unit__r.Name' }],
	};

	get opportunityFilter(){
		if (this.selectedAction == 'move_payment'){
			if (this.selectedSourceOpportunityStageName == 'Closed Lost'){
				return {
					criteria: [
						// (1) Filter by selected Account
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
						// 6 Filter by selected Source Unit Code
						{
							fieldPath: 'UnitCode__c',
							operator: 'eq',
							value: this.selectedSourceUnitCode || ''
						},
						//7 Filter by selected Source Opp
						{
							fieldPath: 'Id',
							operator: 'eq',
							value: this.selectedSourceOpportunityId || ''
						},
						// 8: StageName = Negotiation
						{
							fieldPath: 'StageName',
							operator: 'eq',
							value: 'Negotiation'
						},
						// (9) IsQuoteSynced__c must be TRUE
						{
							fieldPath: 'IsQuoteSynced__c',
							operator: 'eq',
							value: true
						},
					],
					// Combine all
					filterLogic: '(2 OR (3 AND 4) OR 5 OR (8 AND 9)) AND (6) AND NOT(7)'
				};
			} else {
				return {
					criteria: [
						// (1) Filter by selected Account
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
						// 6 Filter by selected Source Unit Code
						{
							fieldPath: 'UnitCode__c',
							operator: 'eq',
							value: this.selectedSourceUnitCode || ''
						},
						//7 Filter by selected Source Opp
						{
							fieldPath: 'Id',
							operator: 'eq',
							value: this.selectedSourceOpportunityId || ''
						}
					],
					// Combine all
					filterLogic: '1 AND NOT(7) AND (2 OR (3 AND 4) OR 5) '
				};
			}

		} else {
			return {
				criteria: [
					// (1) Filter by selected Account
					{
						fieldPath: 'AccountId',
						operator: 'eq',
						value: this.accountId
					},
					// (2) Only include Opportunities with StageName = 'Negotiation'
					{
						fieldPath: 'StageName',
						operator: 'eq',
						value: 'Negotiation'
					},
					// (3) IsQuoteSynced__c must be TRUE
					{
						fieldPath: 'IsQuoteSynced__c',
						operator: 'eq',
						value: true
					},
					// (4) Filter by selected Source Unit Code
					{
						fieldPath: 'UnitCode__c',
						operator: 'eq',
						value: this.selectedSourceUnitCode || ''
					},
					// (5) Filter by selected Source Opp
					{
						fieldPath: 'Id',
						operator: 'eq',
						value: this.selectedSourceOpportunityId || ''
					}
				],
				// Combine all with AND
				filterLogic: '1 AND 2 AND 3 AND NOT(5)'
			};
		}

	}

	get isShowAddButton(){
		if (this.selectedAction == 'move_payment'){
			return true;
		}
		return false;
	}

	get isMovePayment() {
		return this.selectedAction === 'move_payment';
	}

	get availableNewOpportunityOptions() {
		return this.newOpportunities
			.filter(item => item.newOpportunityId && item.newOppDetails)
			.map(item => {
				return {
					label: item.newOppDetails.name,
					value: item.newOpportunityId
				};
			});
	}

	get urlLabel(){
		switch (this.selectedAction) {
			case 'upgrade':
				return 'URL Upgrade Unit';
			case 'downgrade':
				return 'URL Downgrade Unit';
			case 'move_payment':
				return 'URL Move Payment';
			default:
				return '';
		}
	}

	get isRemovable() {
		return this.newOpportunities.length > 1;
	}



	selectedPromotions = []
	get hasSelectedPromotions() {
		return this.selectedPromotions.length > 0;
	}

	@wire(MessageContext)
    messageContext;

	connectedCallback() {
        this.subscribeToMessageChannel();
		console.log('filter: ' + JSON.stringify(this.opportunityFilter))
    }

	async handleNewOppChange(event) {
		const index = parseInt(event.target.dataset.index);
		const selectedId = event.detail.recordId;
		const item = this.newOpportunities[index]
		item.newOpportunityId = selectedId;
		// If cleared
		if (!selectedId) {
			item.detailWrapperClass = 'fade-out fade-wrapper';
			this.newOpportunities = [...this.newOpportunities];

			setTimeout(() => {
				item.isShowDetail = false;
				item.newOppDetails = {
					hasOpportunityPromotion: false,
					hasClientOffer: false
				};
				item.hasLoadedOnce = false;
				this.newOpportunities = [...this.newOpportunities];
			}, 400);
			return;
		}
		// If already shown once → fade-out before loading new data
		if (item.hasLoadedOnce) {
			item.detailWrapperClass = 'fade-out fade-wrapper';
			item.newOppDetails = {
				hasOpportunityPromotion: false,
				hasClientOffer: false
			};
			this.newOpportunities = [...this.newOpportunities];
			setTimeout(() => {
				this.loadOpportunityDetails(selectedId, index);
			}, 400);
		} else {
			this.loadOpportunityDetails(selectedId, index);
		}
	}

	handleAdd(event){
		this.newOpportunities = [
			...this.newOpportunities,
			{
				key : this.newOpportunities.length,
				newOpportunityId: null,
				newOppDetails: {
					hasOpportunityPromotion: false,
					hasClientOffer: false
				},
				isShowDetail : false,
				detailWrapperClass: '',
				hasLoadedOnce: false,
				amountToMove: 0.00
			}
		];
	}

	handleRemove(event) {
		const indexToRemove = Number(event.currentTarget.dataset.index);
		this.newOpportunities = this.newOpportunities.filter((_, idx) => idx !== indexToRemove);
	}

	handleToOppChange(event) {
		const selectedPromoId = event.target.dataset.id;
		console.log('selectedPromoId: ' + selectedPromoId)
		const selectedOppId = event.detail.value;
		console.log('selectedOppId: ' + selectedOppId)
		const updatedList = this.selectedPromotions.map(promo => {
			if (promo.id === selectedPromoId) {
				return {
					...promo,
					toOpportunityId: selectedOppId // new field we're adding
				};
			}
			return promo;
		});
		this.selectedPromotions = updatedList;
		console.log('selectedPromotions: ' + JSON.stringify(this.selectedPromotions))
	}

	async loadOpportunityDetails(oppId,index) {
		// this.isLoading = true;
		try{
			let result = await getOpportunityDetails({
				opportunityId: oppId,
			})
			const details = {
				name: result.opportunityName || '',
				projectName: result.projectName || '',
				unitName: result.unitName || '',
				netPrice: result.netPrice || 0.00,
				totalPaidAmount: result.totalPaidAmount || 0.00,
				opportunityPromotions: result.opportunityPromotions || [],
				clientOffers: result.clientOffers || [],
				receivedPromotions: result.receivedPromotions || [],
				hasOpportunityPromotion: result.opportunityPromotions.length > 0 ? true : false,
				hasClientOffer: result.clientOffers.length > 0 ? true : false
			};
			this.newOpportunities[index].newOppDetails = details;
			this.newOpportunities[index].isShowDetail = true;
			this.newOpportunities[index].detailWrapperClass  = 'fade-in fade-wrapper';
			this.newOpportunities[index].hasLoadedOnce = true;
			console.log('target item: ' + JSON.stringify(this.newOpportunities[index]))
			this.newOpportunities = [...this.newOpportunities];
			// this.isLoading = false;
		} catch (error) {
			// this.isLoading = false;
			console.error('Error loading Opportunity details:', JSON.stringify(error));
		}
	}

	handleMovePaymentAmountChange(event) {
		const index = parseInt(event.target.dataset.index, 10);
		const value = parseFloat(event.target.value);
		this.newOpportunities[index].amountToMove = isNaN(value) ? 0.00 : Math.round(value * 100) / 100;
		this.newOpportunities = [...this.newOpportunities];
	}

	handleURLChange(event) {
		this.urlDoc = event.target.value;
	}

	subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                sourceOppToTargetOpp,
                (message) => this.handleMessage(message)
            );
        }
    }

	handleMessage(message){
		const method = message?.method;
        const payload = message?.payload;
		console.log('payload: ' + JSON.stringify(payload))
        if (typeof this[method] === 'function') {
			if (method == 'setSelectedPromotion' || method == 'setSelectedSourceOpportunity'){
				this[method](payload);
			}
        } else {
            console.warn(`No method found for: ${method}`);
        }
	}

	setSelectedPromotion(payload) {
		const exists = this.selectedPromotions.some(p => p.id === payload.id);

		if (payload.isChecked) {
			if (!exists) {
				const item = { ...payload, animationClass: 'fade-in' };
				this.selectedPromotions = [...this.selectedPromotions, item];
			}
		} else {
			if (exists) {
				// Set fade-out class
				this.selectedPromotions = this.selectedPromotions.map(p =>
					p.id === payload.id ? { ...p, animationClass: 'fade-out' } : p
				);
				// Remove after fade-out
				setTimeout(() => {
					this.selectedPromotions = this.selectedPromotions.filter(p => p.id !== payload.id);
				}, 400); // Match animation time
			}
		}
		this.selectedPromotions = this.selectedPromotions.map((p,i) => {
			return {
				...p,
				style: `z-index: ${100 - i}; position: relative;`
			}
		})
	}

	setSelectedSourceOpportunity(payload){
		this.selectedSourceUnitCode = payload.unitCodes;
		this.selectedSourceOpportunityId = payload.oppId;
		this.selectedSourceOpportunityStageName = payload.stageName
	}

	validateURL(event) {
		const input = event.target;
		const value = input.value;
		if (!this.isValidURL(value)) {
			input.setCustomValidity('Please enter a valid website address, like www.example.com');
		} else {
			input.setCustomValidity('');
		}
		input.reportValidity();
	}

	isValidURL(value) {
		const regex = /^(https?:\/\/)?(www\.)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(\/[^\s]*)?$/;
    	return regex.test(value);
	}
	// clearData(){
	// 	this.newOpportunityId = null;
	// 	this.newOppDetails = null;
	// 	const oppPicker = this.template.querySelector('[data-id="newOppPicker"]');
	// 	oppPicker.clearData();
	// }
}