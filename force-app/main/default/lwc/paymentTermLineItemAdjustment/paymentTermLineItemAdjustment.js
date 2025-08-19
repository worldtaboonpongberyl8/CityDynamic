import { LightningElement, api, wire } from "lwc";
import getPaymentTermMasterWithLineItem from "@salesforce/apex/PaymentTermLineItemAdjustmentController.getPaymentTermMasterWithLineItem";
import upsertPaymentTermLineItem from "@salesforce/apex/PaymentTermLineItemAdjustmentController.upsertPaymentTermLineItem";
import ConfirmModal from 'c/confirmModal'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PaymentTermLineItemAdjustment extends LightningElement {
    @api recordId;
    isLoading;
    paymentTermRecord = {};
    allAmountAndPercent = {
        contractAmount: null,
        contractPercent: null,
        totalInstallmentAmount: null,
        totalInstallmentPercent: null
    };
    paymentTermLineItemData = [];
    error;

    get isNewPaymentTerm() {
        return (
            this.paymentTermLineItemData.length === 0 ||
            this.paymentTermLineItemData.every((item) => item.isNew === true)
        );
    }
    get isEditPaymentTerm() {
        return this.paymentTermLineItemData.length > 0;
    }
    get isSeriesPayment() {
        return this.paymentTermRecord.Type__c === "Series";
    }
    get isBulletPayment() {
        return this.paymentTermRecord.Type__c === "Bullet";
    }

    // ----- Start Init -----
    async connectedCallback() {
        this.isLoading = true;
        console.log("recordId: " + this.recordId);
        this.paymentTermRecord = await getPaymentTermMasterWithLineItem({ paymentTermMasterId: this.recordId });
        if (this.paymentTermRecord.Payment_Term__r) {
            this.initPaymentTermLineItemDataWrapper();
        }
        console.log("paymentTermRecord: " + JSON.stringify(this.paymentTermRecord));
        this.injectStyle();
        this.isLoading = false;
    }
    // ----- End Init -----

    // ----- Start Handler -----
    handleContractAmountChange(event) {
        let newValue = parseFloat(event.target.value);
        this.allAmountAndPercent = {
            ...this.allAmountAndPercent,
            contractAmount: newValue,
            contractPercent: null
        };
    }

    handleContractPercentChange(event) {
        let newValue = parseFloat(event.target.value);
        this.allAmountAndPercent = {
            ...this.allAmountAndPercent,
            contractAmount: null,
            contractPercent: newValue
        };
    }

    handleInstallmentAmountChange(event) {
        let newValue = parseFloat(event.target.value);
        this.allAmountAndPercent = {
            ...this.allAmountAndPercent,
            totalInstallmentAmount: newValue,
            totalInstallmentPercent: null
        };
    }

    handleInstallmentPercentChange(event) {
        let newValue = parseFloat(event.target.value);
        this.allAmountAndPercent = {
            ...this.allAmountAndPercent,
            totalInstallmentAmount: null,
            totalInstallmentPercent: newValue
        };
    }

    handleGenerateTableData() {
        this.generatePaymentTermLineItemDataWrapper();
    }

    handleClearData() {
        this.allAmountAndPercent = {
            contractAmount: null,
            contractPercent: null,
            totalInstallmentAmount: null,
            totalInstallmentPercent: null
        };
        this.paymentTermLineItemData = [];
    }

    handleAdjustAmount(event) {
        const term = event.target.dataset.id;
        const newAmount = parseFloat(event.target.value);
        if (this.isSeriesPayment && term.includes("Installment")) {
            this.paymentTermLineItemData = this.paymentTermLineItemData.map((item) => {
                if (item.term.includes("Installment")) {
                    return { ...item, amount: newAmount, percent: null };
                }
                return item;
            });
        } else {
            this.paymentTermLineItemData = this.paymentTermLineItemData.map((item) => {
                if (item.term === term) {
                    return { ...item, amount: newAmount, percent: null };
                }
                return item;
            });
        }
        this.paymentTermLineItemData = [...this.paymentTermLineItemData];
    }

    handleAdjustPercent(event) {
        const term = event.target.dataset.id;
        const newPercent = parseFloat(event.target.value);
        if (this.isSeriesPayment && term.includes("Installment")) {
            this.paymentTermLineItemData = this.paymentTermLineItemData.map((item) => {
                if (item.term.includes("Installment")) {
                    return { ...item, percent: newPercent, amount: null };
                }
                return item;
            });
        } else {
            this.paymentTermLineItemData = this.paymentTermLineItemData.map((item) => {
                if (item.term === term) {
                    return { ...item, percent: newPercent, amount: null };
                }
                return item;
            });
        }

        this.paymentTermLineItemData = [...this.paymentTermLineItemData];
    }
    /* */
    handleCheckboxChange(event) {
        const term = event.target.dataset.id;
        const isChecked = event.target.checked;
        this.paymentTermLineItemData = this.paymentTermLineItemData.map((item) => {
            if (item.term === term) {
                return { ...item, isAllowedPayment: isChecked };
            }
            return item;
        });
        
        this.paymentTermLineItemData = [...this.paymentTermLineItemData];
    }
    /* */
    handleFetchData(){
        if (this.isNewPaymentTerm){
            this.generatePaymentTermLineItemDataWrapper()
        } else {
            this.connectedCallback();
        }
       
    }

    async handleSaveLineItem(){
        const isConfirm = await ConfirmModal.open({
            size: 'small', 
            description: 'Confirm Action Modal',
            title: 'Confirm Action',
            message: 'Are you sure you want to proceed?' 
        })
        if (isConfirm){
            try{
                this.isLoading = true;
                const upsertedResult = await upsertPaymentTermLineItem({paymentTermLineItemToBeUpsertedJSON : JSON.stringify(this.paymentTermLineItemData)})
                if (upsertedResult){
                    this.showToast('Success', 'Payment term line item saved successfully', 'success');
                    this.connectedCallback();
                } else {
                    this.showToast('Error', 'Failed to save payment term line item', 'error');
                    this.isLoading = false;
                }
            }catch(error){
                this.showToast('Error', 'Failed to save payment term line item', 'error');
                console.error('ERROR: ' + JSON.stringify(error))
                this.isLoading = false;
            }
        } 
    }
    // ----- End Handler -----

    // ----- Start Service -----
    initPaymentTermLineItemDataWrapper() {
        console.log('call initPaymentTermLineItemDataWrapper ')
        this.paymentTermLineItemData = this.paymentTermRecord.Payment_Term__r.map((eachItem) => {
            let wrapper = {
                id: eachItem.Id,
                order: eachItem.Order__c,
                term: eachItem.Term__c,
                amount: eachItem.Amount__c,
                percent: eachItem.Percent__c,
                isAllowedPayment: eachItem.IsAllowedPaymentByGateway__c,
                paymentTermMasterId : eachItem.PaymentTermMaster__c,
                isNew: false
            };
            wrapper.isTransfer = eachItem.Term__c === "Transfer" ? true : false;
            wrapper.isInstallment = eachItem.Term__c.includes("Installment") ? true : false;
            return wrapper;
        });
    }
    generatePaymentTermLineItemDataWrapper() {
        const numberOfInstallment = this.paymentTermRecord.NoofInstallment__c;
        const avgInstallmentAmount =
            this.allAmountAndPercent.totalInstallmentAmount &&
            (numberOfInstallment !== 0 || numberOfInstallment !== null)
                ? parseFloat((this.allAmountAndPercent.totalInstallmentAmount / numberOfInstallment).toFixed(2))
                : null;
        const avgInstallmentPercent =
            this.allAmountAndPercent.totalInstallmentPercent &&
            (numberOfInstallment !== 0 || numberOfInstallment !== null)
                ? parseFloat((this.allAmountAndPercent.totalInstallmentPercent / numberOfInstallment).toFixed(2))
                : null;
        let targetLineItemData = [];
        // add Contract term
        targetLineItemData.push({
            id: null,
            order: 1,
            term: "Contract",
            amount: this.allAmountAndPercent.contractAmount,
            percent: this.allAmountAndPercent.contractPercent,
            isNew: true,
            isTransfer: false,
            isInstallment: false,
            isAllowedPayment: false,
            paymentTermMasterId : this.paymentTermRecord.Id
        });
        // add Installment term (if any)
        for (let i = 1; i < numberOfInstallment + 1; i++) {
            targetLineItemData.push({
                id: null,
                order: i + 1,
                term: "Installment " + i.toString(),
                amount: avgInstallmentAmount,
                percent: avgInstallmentPercent,
                isNew: true,
                isTransfer: false,
                isInstallment: true,
                isAllowedPayment: false,
                paymentTermMasterId : this.paymentTermRecord.Id
            });
        }
        // add Transfer term
        targetLineItemData.push({
            id: null,
            order: 2 + numberOfInstallment,
            term: "Transfer",
            amount: null,
            percent: null,
            isNew: true,
            isTransfer: true,
            isInstallment: false,
            isAllowedPayment: false,
            paymentTermMasterId : this.paymentTermRecord.Id
        });
        this.paymentTermLineItemData = [...targetLineItemData];
    }
    injectStyle(){
        const inputAligncenter = document.createElement("style");
        inputAligncenter.innerText = `.number-input input{ text-align: right!important; }`;
        document.body.appendChild(inputAligncenter);
    }
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }
    // ----- End Service -----
}