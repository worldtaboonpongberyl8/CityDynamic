import { LightningElement, api, wire } from "lwc";
import getPaymentTermMasterWithLineItem from "@salesforce/apex/PaymentTermLineItemAdjustmentController.getPaymentTermMasterWithLineItem";
import getOpportunityPayment from "@salesforce/apex/OpportunityPaymentAdjustmentController.getOpportunityPayment";
import upsertOppPayments from "@salesforce/apex/OpportunityPaymentAdjustmentController.upsertOppPayments";
import deleteOppPayments from "@salesforce/apex/OpportunityPaymentAdjustmentController.deleteOppPayments";
import validateIsGrantedProfileProfile from "@salesforce/apex/OpportunityPaymentAdjustmentController.validateIsGrantedProfileProfile";
import ConfirmModal from "c/confirmModal";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { subscribe, MessageContext } from 'lightning/messageService';
import afterProceedPaymentChannel from '@salesforce/messageChannel/afterProceedPaymentChannel__c';
import PAYMENTMASTER_FIELD from "@salesforce/schema/Opportunity.PaymentTermMaster__c";
import CONTRACTAMOUNT_FIELD from "@salesforce/schema/Opportunity.InitialContractAmount__c";
import RESERVATIONAMOUNT_FIELD from "@salesforce/schema/Opportunity.InitialReservationAmount__c";
import INSTALLMENTAMOUNT_FIELD from "@salesforce/schema/Opportunity.InitialTotalInstallmentAmount__c";
import TRANSFERAMOUNT_FIELD from "@salesforce/schema/Opportunity.InitialTransferAmount__c";

export default class OpportunityPaymentAdjustment extends LightningElement {
    @api recordId;
    @api isHideFooter;
    @api isHideHeader;
    isLoading;
    isViewMode;
    canSplitContract;
    isCRMProfile;
    paymentTermRecord = {};
    opportunityPaymentData = [];
    deletedOppPaymentData = [];
    initialReservationAmount;
    initialContractAmount;
    initialInstallmentAmount;
    initialTransferAmount;
    subscription = null;

    get hasNoOpportunityPayment() {
        if (this.opportunityPaymentData) {
            return this.opportunityPaymentData.length === 0;
        }
        return true;
    }

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [
            PAYMENTMASTER_FIELD,
            CONTRACTAMOUNT_FIELD,
            RESERVATIONAMOUNT_FIELD,
            INSTALLMENTAMOUNT_FIELD,
            TRANSFERAMOUNT_FIELD,
        ]
    })
    wiredRecord({ error, data }) {
        if (error) {
            console.log("error occured");
        } else if (data) {
            // console.log("detect data: " + JSON.stringify(data));
            this.initialReservationAmount = getFieldValue(data, RESERVATIONAMOUNT_FIELD);
            this.initialContractAmount = getFieldValue(data, CONTRACTAMOUNT_FIELD);
            this.initialInstallmentAmount = getFieldValue(data, INSTALLMENTAMOUNT_FIELD);
            this.initialTransferAmount = getFieldValue(data, TRANSFERAMOUNT_FIELD);
            this.refresh();
        }
    }

    @wire(MessageContext)
    messageContext;


    // ----- Start Init -----
    async refresh() {
        console.log("call refresh");
        this.isLoading = true;
        this.isViewMode = true;
        this.deletedOppPaymentData = [];
        try {
            let opportunityPaymentRecords = await getOpportunityPayment({ oppId: this.recordId });
            if (opportunityPaymentRecords) {
                this.opportunityPaymentData = opportunityPaymentRecords;
                let paymentTermMasterId = this.opportunityPaymentData[0].Opportunity__r.PaymentTermMaster__c;
                this.paymentTermRecord = await getPaymentTermMasterWithLineItem({
                    paymentTermMasterId: paymentTermMasterId
                });
            }
            this.isCRMProfile = await validateIsGrantedProfileProfile();
            this.initOpportunityPaymentDataWrapper();
            this.initPaymentMasterWrapper();
            this.validateCanSplitContract();
            this.isLoading = false;
        } catch (error) {
            console.error(error);
        }
    }

    renderedCallback() {
        this.injectStyle();
        // if (this.isHideHeader){
        //     this.injectStyleFromParent();
        // }
    }

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    // ----- End Init -----

    // ----- Start Handler -----
    handleAdjustDueDate(event) {
        const term = event.target.dataset.id;
        const newDate = event.target.value;
        this.opportunityPaymentData = this.opportunityPaymentData.map((item) => {
            if (item.term === term) {
                return { ...item, dueDate: newDate };
            }
            return item;
        });
    }

    handleAdjustAmount(event) {
        const term = event.target.dataset.id;
        const newAmount = event.target.value ? parseFloat(event.target.value) : 0.0;
        let targetOppPayment = this.opportunityPaymentData.find((data) => data.term === term);
        let differentiate = parseFloat((targetOppPayment.amount - newAmount).toFixed(2));
        console.log("differentiate: " + differentiate);
        targetOppPayment.amount = newAmount;
        let transferPaymentTerm = this.opportunityPaymentData.find((data) => data.term === "Transfer");
        console.log("transferPaymentTerm.amount: " + transferPaymentTerm.amount);
        let originalTransferAmount = parseFloat(parseFloat(transferPaymentTerm.amount).toFixed(2));
        let newTransferAmount = originalTransferAmount + differentiate;
        newTransferAmount = parseFloat(parseFloat(newTransferAmount).toFixed(2));
        console.log("newTransferAmount: " + newTransferAmount);
        transferPaymentTerm.amount = newTransferAmount;
        transferPaymentTerm.remaining = newTransferAmount;
        this.opportunityPaymentData = [...this.opportunityPaymentData];
    }

    handleToggleEditMode() {
        this.isViewMode = false;
    }

    handleSplitContract() {
        this.isViewMode = false;
        let updatedPaymentData = [];
        let contractTerms = this.opportunityPaymentData.filter((payment) => payment.term.includes("Contract"));
        if (contractTerms.length > 0) {
            let totalContractAmount = contractTerms.reduce((total, payment) => total + payment.amount, 0);
            let splitAmount = parseFloat((totalContractAmount / (contractTerms.length + 1)).toFixed(2));
            for (let i = 0; i < contractTerms.length; i++) {
                contractTerms[i].amount = splitAmount;
                contractTerms[i].remaining = splitAmount;
                contractTerms[i].order = contractTerms[0].order + i;
                // contractTerms[i].term = `Contract${i === 0 ? "" : " " + (i + 1)}`;
                contractTerms[i].term = "Contract " + (i + 1).toString();
            }
            // add diff into transfer payment
            let diff = parseFloat(totalContractAmount.toFixed(2)) - splitAmount * (contractTerms.length + 1);
            let transferPaymentTerm = this.opportunityPaymentData.find((data) => data.term === "Transfer");
            let oldTransferAmount = parseFloat(transferPaymentTerm.amount) || 0;
            let newTransferAmount = oldTransferAmount + parseFloat(diff.toFixed(2));
            transferPaymentTerm.amount = parseFloat(newTransferAmount.toFixed(2));

            let originalDueDate = new Date(contractTerms[0].dueDate);
            console.log("originalDueDate: " + originalDueDate);
            let newDueDate = new Date(originalDueDate);
            newDueDate.setDate(originalDueDate.getDate() + 14 * contractTerms.length);
            let year = newDueDate.getFullYear();
            let month = String(newDueDate.getMonth() + 1).padStart(2, "0"); // Months are zero-based, so add 1
            let day = String(newDueDate.getDate()).padStart(2, "0");
            let formattedDate = contractTerms[0].dueDate != null ? `${year}-${month}-${day}` : null;
            let newContract = {
                amount: splitAmount,
                remaining: splitAmount,
                dueDate: formattedDate,
                order: contractTerms.length + 1,
                receivedAmount: null,
                receivedDate: null,
                status: "",
                term: `Contract ${contractTerms.length + 1}`,
                oppId: this.recordId,
                isNewRecord: true,
                canDeleteSplittedContract: true,
				isAllowedPayment : false
            };
            console.log("newContract: " + JSON.stringify(newContract));
            contractTerms.push(newContract);
            let otherPayments = this.opportunityPaymentData.filter((payment) => !payment.term.includes("Contract"));
            for (let i = 0; i < otherPayments.length; i++) {
                if (otherPayments[i].term === "Reservation") {
                    updatedPaymentData.push(otherPayments[i]);
                    updatedPaymentData = updatedPaymentData.concat(contractTerms);
                } else {
                    updatedPaymentData.push(otherPayments[i]);
                }
            }
            this.opportunityPaymentData = updatedPaymentData;
            this.opportunityPaymentData.forEach((payment, index) => {
                payment.order = index + 1;
            });
        }
        this.validateCanSplitContract();
    }

    handleDeleteSplittedContract(event) {
        const term = event.target.dataset.id;
        let newSplitAmount;
        let oldContractTerms = this.opportunityPaymentData.filter((payment) => payment.term.includes("Contract"));
        if (oldContractTerms.length > 0) {
            let totalContractAmount = oldContractTerms.reduce((total, payment) => total + payment.amount, 0);
            newSplitAmount = parseFloat((totalContractAmount / (oldContractTerms.length - 1)).toFixed(2));
            // add diff into transfer payment
            let diff = parseFloat(totalContractAmount.toFixed(2)) - newSplitAmount * (oldContractTerms.length - 1);
            let transferPaymentTerm = this.opportunityPaymentData.find((data) => data.term === "Transfer");
            let oldTransferAmount = parseFloat(transferPaymentTerm.amount) || 0;
            let newTransferAmount = oldTransferAmount + parseFloat(diff.toFixed(2));
            transferPaymentTerm.amount = parseFloat(newTransferAmount.toFixed(2));
        }
        let deletedOppPayment = this.opportunityPaymentData.find((each) => each.term === term);
        console.log("deletedOppPayment: " + JSON.stringify(deletedOppPayment));
        if (deletedOppPayment.id) {
            this.deletedOppPaymentData.push(deletedOppPayment);
        }
        this.opportunityPaymentData = this.opportunityPaymentData.filter((each) => each.term !== term);
        let contractTerms = this.opportunityPaymentData.filter((payment) => payment.term.includes("Contract"));
        let originalDueDate = new Date(contractTerms[0].dueDate);
        if (contractTerms.length > 0) {
            for (let i = 0; i < contractTerms.length; i++) {
                let newDueDate = new Date(originalDueDate);
                newDueDate.setDate(originalDueDate.getDate() + 14 * i);
                let year = newDueDate.getFullYear();
                let month = String(newDueDate.getMonth() + 1).padStart(2, "0"); // Months are zero-based, so add 1
                let day = String(newDueDate.getDate()).padStart(2, "0");
                let formattedDate = contractTerms[0].dueDate != null ? `${year}-${month}-${day}` : null;
                contractTerms[i].amount = newSplitAmount;
                contractTerms[i].order = contractTerms[0].order + i;
                // contractTerms[i].term = `Contract${i === 0 ? "" : " " + (i + 1)}`;
                contractTerms[i].term = contractTerms.length !== 0 ? "Contract " + (i + 1).toString() : "Contract";
                contractTerms[i].dueDate = formattedDate;
                contractTerms[i].remaining = newSplitAmount;
            }
        }
        this.opportunityPaymentData.forEach((payment, index) => {
            payment.order = index + 1;
        });
        this.validateCanSplitContract();
    }

    async handleSaveOppPayment() {
        this.isLoading = true;
        if (!this.validateDueDateSortedAscending()) {
            this.showToast("Error", "Due Date of each payment term is not sorted", "error");
            this.isLoading = false;
        } else {
            const isConfirm = await ConfirmModal.open({
                size: "small",
                description: "Confirm Action Modal",
                title: "Confirm Action",
                message: "Are you sure you want to proceed?"
            });
            if (isConfirm) {
                try {
                    let deletedOppPayment;
                    if (this.deletedOppPaymentData.length > 0) {
                        console.log("deletedOppPaymentData: " + JSON.stringify(this.deletedOppPaymentData));
                        deletedOppPayment = await deleteOppPayments({
                            oppPaymentsToBeDeletedJSON: JSON.stringify(this.deletedOppPaymentData)
                        });
                    }
                    let upsertedOppPayment = await upsertOppPayments({
                        oppPaymentsToBeUpsertedJSON: JSON.stringify(this.opportunityPaymentData)
                    });

                    if (upsertedOppPayment || deletedOppPayment) {
                        this.showToast("Success", "Opportunity Payment saved succesfully", "success");
                    } else {
                        this.showToast("Error", "Fail to save Opportunity Payment", "error");
                    }
                    this.isLoading = false;
                    this.refresh();
                } catch (error) {
                    this.showToast("Error", "Fail to save Opportunity Payment", "error");
                    console.error(error);
                    this.isLoading = false;
                }
            } else {
                this.isLoading = false;
            }
        }
    }

    async handleCancel() {
        const isConfirm = await ConfirmModal.open({
            size: "small",
            description: "Confirm Action Modal",
            title: "Confirm Action",
            message: "Are you sure you want to cancel?"
        });
        if (isConfirm) {
            this.refresh();
        }
    }

    // ----- End Handler -----

    // ----- Start Service -----
    injectStyle() {
        const inputAligncenter = document.createElement("style");
        inputAligncenter.innerText = `.number-input input{ text-align: right!important; }
                                        .date-format-hide .slds-form-element__help{ display: none; }
                                        .date-format-hide .slds-show{ display: block; }
                                        .slds-input[disabled], .slds-input.slds-is-disabled {color: #a49e9e !important; border-color : #a49e9e !important}
                                    `;
        document.body.appendChild(inputAligncenter);
    }

    injectStyleFromParent() {
        const inputAligncenter = document.createElement("style");
        inputAligncenter.innerText = `.number-input input{ text-align: right!important; }
                                        .date-format-hide .slds-form-element__help{ display: none; }
                                        .date-format-hide .slds-show{ display: block; }
                                        .slds-input[disabled], .slds-input.slds-is-disabled {color: #a49e9e !important; border-color : #a49e9e !important}
                                        .table-container{ height: 250px!important; overflow-y: scroll;}
                                    `;
        document.body.appendChild(inputAligncenter);
    }

    initOpportunityPaymentDataWrapper() {
        this.opportunityPaymentData = this.opportunityPaymentData.map((eachItem) => {
            let wrapper = {
                id: eachItem.Id,
                order: eachItem.Order__c,
                term: eachItem.Term__c,
                amount: eachItem.Amount__c,
                dueDate: eachItem.DueDate__c,
                receivedDate: eachItem.ReceivedDate__c,
                receivedAmount: eachItem.ReceivedAmount__c == 0 ? null : eachItem.ReceivedAmount__c,
                remaining: eachItem.Remaining__c,
                status: eachItem.PaymentStatus__c,
                oppId: eachItem.Opportunity__c,
                isNewRecord: false,
				isAllowedPayment : eachItem.IsAllowedPaymentByGateway__c
            };
            wrapper.isDisabled =
                eachItem.PaymentStatus__c === "Partially Paid" ||
                eachItem.PaymentStatus__c === "Fully Paid" ||
                eachItem.Term__c === "Transfer";
            wrapper.canDeleteSplittedContract =
                ["Contract 2", "Contract 3", "Contract 4"].includes(eachItem.Term__c) &&
                eachItem.PaymentStatus__c !== "Partially Paid" &&
                eachItem.PaymentStatus__c !== "Fully Paid";
            wrapper.cssClass = this.isHideHeader && eachItem.PaymentStatus__c === "Fully Paid" ? 'grey-bg' : '';
            return wrapper;
        });
    }

    initPaymentMasterWrapper() {
        this.paymentTermRecord = {
            name: this.paymentTermRecord.Name,
            type: this.paymentTermRecord.Type__c,
            dueDate: this.paymentTermRecord.DueDate__c,
            noOfInstallment: this.paymentTermRecord.NoofInstallment__c
        };
    }

    validateDueDateSortedAscending() {
        for (let i = 0; i < this.opportunityPaymentData.length - 1; i++) {
            let currentDate = new Date(this.opportunityPaymentData[i].dueDate);
            let nextDate = new Date(this.opportunityPaymentData[i + 1].dueDate);
            if (currentDate > nextDate) {
                return false;
            }
        }
        return true;
    }

    validateCanSplitContract() {
        let contractTerms = this.opportunityPaymentData.filter((payment) => payment.term.includes("Contract"));
        if (contractTerms.length >= 3) {
            this.canSplitContract = false;
            return;
        }
        let allValidStatus = contractTerms.every(
            (payment) => payment.status !== "Partially Paid" && payment.status !== "Fully Paid"
        );
        this.canSplitContract = allValidStatus;
    }

    @api
    async applyPaymentAmountToEachPayment(paymentAmount) {
        await this.refresh();
        console.log('call applyPaymentAmountToEachPayment')
        let remainingPayment = parseFloat(paymentAmount);
        if (isNaN(remainingPayment)) {
            alert('Please enter a valid payment amount.');
            return;
        }
        const today = new Date();
        this.opportunityPaymentData = this.opportunityPaymentData.map(payment => {
            if (remainingPayment <= 0) return payment;
            console.log('payment: ' + JSON.stringify(payment))
            let remainingBalance = payment.remaining;
            // console.log('term: ' + payment.term)
            // console.log('remainingBalance: ' + remainingBalance)
            if (remainingBalance > 0) {
                let allocatedAmount = Math.min(remainingBalance, remainingPayment);
                console.log('allocatedAmount: ' + allocatedAmount)
                payment.receivedAmount = payment.receivedAmount == null ? 0 + allocatedAmount : payment.receivedAmount + allocatedAmount;
                payment.remaining = payment.amount - payment.receivedAmount;
                remainingPayment -= allocatedAmount;
                payment.status = payment.remaining === 0 ? 'Fully Paid' : 'Partially Paid';
                payment.receivedDate = today.toISOString().split('T')[0];
            }
            return payment;
        });
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                afterProceedPaymentChannel,
                (message) => this.refresh()
            );
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
    // ----- End Service -----
}