import { LightningElement, api, wire } from "lwc";
import ConfirmModal from "c/confirmModal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import { CloseActionScreenEvent } from "lightning/actions";
import getMakeAPaymentConfig from "@salesforce/apex/ProceedPaymentController.getMakeAPaymentConfig";
import getPicklistValues from "@salesforce/apex/ProceedPaymentController.getPicklistValues";
import getCompanyBanks from "@salesforce/apex/ProceedPaymentController.getCompanyBanks";
import proceedPayment from "@salesforce/apex/ProceedPaymentController.proceedPayment";
import { publish, MessageContext } from "lightning/messageService";
import afterProceedPaymentChannel from "@salesforce/messageChannel/afterProceedPaymentChannel__c";

export default class ProceedPayment extends NavigationMixin(LightningElement) {
    @api recordId;
    paymentMethodOptions = [];
    configMap = {};
    paymentTypeMap = {};
    paymentMethodSections = [];
    isLoading;

    totalReceivedAmount = 0;

    @wire(MessageContext)
    messageContext;

    @wire(getMakeAPaymentConfig)
    wiredConfig({ error, data }) {
        if (data) {
            const optionSet = new Set();
            const activeConfigs = data.filter((config) => config.IsActive__c);
            activeConfigs.forEach((config) => {
                console.log("config: " + JSON.stringify(config));
                optionSet.add(config.PaymentType__c);
                if (!this.configMap[config.PaymentType__c]) {
                    this.configMap[config.PaymentType__c] = [];
                }
                this.configMap[config.PaymentType__c].push({
                    apiName: config.FieldAPI__c,
                    label: config.FieldLabel__c,
                    dataType: config.DataType__c,
                    maxLength: config.MaxTextLength__c,
                    maxDecimalDigits: config.DecimalStep__c,
                    picklistValues: config.PicklistValues__c
                        ? config.PicklistValues__c.split(";").map((each) => {
                              return { label: each, value: each };
                          })
                        : [],
                    sourceObjectAPI: config.SourceObjectAPI__c,
                    sourceFieldAPI: config.SourceFieldAPI__c,
                    order: config.Order__c,
                    required: config.IsRequired__c,
                    isCustomPicklist: config.IsCustomPicklist__c
                });
            });

            this.paymentMethodOptions = Array.from(optionSet).map((option) => {
                return { label: option, value: option };
            });
            this.sortConfig();
        } else if (error) {
            console.error("Error fetching custom metadata", error);
        }
    }

    connectedCallback() {
        this.setPaymentTypeMap();
    }

    renderedCallback() {
        this.injectStyle();
    }

    // ----- Start Handler -----
    handleAddSection() {
        const newSection = {
            id: Date.now(),
            selectedPaymentMethod: "",
            fields: []
        };
        this.paymentMethodSections = [...this.paymentMethodSections, newSection];
    }

    async handleSelectPaymentMethod(event) {
        const sectionId = event.target.dataset.id;
        const selectedOption = event.target.value;

        this.paymentMethodSections = await Promise.all(
            this.paymentMethodSections.map(async (section) => {
                if (section.id == sectionId) {
                    section.selectedPaymentMethod = selectedOption;
                    section.fields = await Promise.all(
                        this.configMap[selectedOption].map(async (config) => {
                            let field = {
                                apiName: config.apiName,
                                label: config.label,
                                value: "",
                                dataType: config.dataType,
                                maxLength: config.maxLength,
                                maxDecimalDigits: config.maxDecimalDigits,
                                picklistValues: config.picklistValues,
                                sourceObjectAPI: config.sourceObjectAPI,
                                sourceFieldAPI: config.sourceFieldAPI,
                                order: config.order,
                                isText: config.dataType === "Text",
                                isDecimal: config.dataType === "Decimal",
                                isDate: config.dataType === "Date",
                                isPicklist: config.dataType === "Picklist",
                                required: config.required
                            };
                            if (config.dataType === "Picklist") {
                                try {
                                    if (config.sourceObjectAPI && config.sourceFieldAPI) {
                                        const values = await getPicklistValues({
                                            objectName: config.sourceObjectAPI,
                                            fieldName: config.sourceFieldAPI
                                        });
                                        field.picklistValues = values.map((each) => {
                                            return { label: each.label, value: each.value };
                                        });
                                        // this.paymentMethodOptions = [...this.paymentMethodOptions];
                                    }
                                    if (config.isCustomPicklist && config.apiName === "CompanyBank__c") {
                                        const values = await getCompanyBanks({
                                            opportunityId: this.recordId
                                        });
                                        console.log("values: " + JSON.stringify(values));
                                        field.picklistValues = values.map((each) => {
											if (each.isDefault){
												field.value = each.value
											}
                                            return { label: each.label, value: each.value };
                                        });
                                        // field.value = values.filter((each) => each.isDefault).map((item) => item.value);
                                        // this.paymentMethodOptions = [...this.paymentMethodOptions];
                                    }
                                } catch (error) {
                                    console.error("error: " + JSON.stringify(error));
                                }
                                // if (config.sourceObjectAPI && config.sourceFieldAPI) {
                                //     getPicklistValues({
                                //         objectName: config.sourceObjectAPI,
                                //         fieldName: config.sourceFieldAPI
                                //     })
                                //         .then((values) => {
                                //             field.picklistValues = values.map((each) => {
                                //                 return { label: each.label, value: each.value };
                                //             });
                                //             this.paymentMethodOptions = [...this.paymentMethodOptions];
                                //         })
                                //         .catch((error) => {
                                //             console.error(
                                //                 'Error fetching picklist values: ' + JSON.stringify(error)
                                //             );
                                //         });
                                // }
                                // if (config.isCustomPicklist && config.apiName === 'CompanyBank__c') {
                                // 	console.log('retrieve company banks')
                                // 	getCompanyBanks({
                                // 		opportunityId : this.recordId
                                // 	}).then((values) => {
                                // 		console.log('values: ' + JSON.stringify(values))
                                // 		field.picklistValues = values.map((each) => {
                                // 			return { label: each.label, value: each.value };
                                // 		});
                                // 		field.value = values.filter(each => each.isDefault).map(item => item.value)
                                // 		this.paymentMethodOptions = [...this.paymentMethodOptions];
                                // 		this.paymentMethodSections = [...this.paymentMethodSections]
                                // 	}).catch((error) => {
                                // 		console.error(
                                // 			'Error fetching company banks: ' + JSON.stringify(error)
                                // 		);
                                // 	});
                                // }
                            }
                            console.log("field: " + JSON.stringify(field));
                            return field;
                        })
                    );
                }
                console.log("section: " + JSON.stringify(section));
                return section;
            })
        );
        // this.paymentMethodSections = [...this.paymentMethodSections]
    }

    handleInputChange(event) {
        const sectionId = event.target.dataset.id;
        const fieldApiName = event.target.dataset.field;
        const value = event.target.value;

        this.paymentMethodSections = this.paymentMethodSections.map((section) => {
            if (section.id == sectionId) {
                section.fields = section.fields.map((field) => {
                    if (field.apiName === fieldApiName) {
                        if (fieldApiName === "ReceivedAmount__c") {
                            field.value = parseFloat(value);
                            this.calculateTotalReceivedAmount();
                        } else {
                            field.value = value;
                        }
                    }
                    return field;
                });
            }
            return section;
        });
    }

    handleRemoveSection(event) {
        const sectionId = event.target.dataset.id;
        this.paymentMethodSections = this.paymentMethodSections.filter((section) => section.id != sectionId);
        this.calculateTotalReceivedAmount();
    }

    handleApplyAmount() {
        const oppPayment = this.template.querySelector("c-opportunity-payment-adjustment");
        oppPayment.applyPaymentAmountToEachPayment(this.totalReceivedAmount);
    }

    async handleConfirm() {
        if (!this.validateAllRequiredField()) {
            this.showToast("Error", "Please input all required fields", "error");
        } else {
            const isConfirm = await ConfirmModal.open({
                size: "small",
                description: "Confirm Action Modal",
                title: "Confirm Action",
                message: "Are you sure you want to make a payment?"
            });
            if (isConfirm) {
                this.isLoading = true;
                try {
                    const paymentMethods = this.paymentMethodSections.map((section) => {
                        const paymentMethod = {};
                        section.fields.forEach((field) => {
                            paymentMethod[field.apiName] = field.value;
                        });
                        paymentMethod.PaymentType__c = this.paymentTypeMap[section.selectedPaymentMethod];
                        return paymentMethod;
                    });
                    // console.log("paymentMethods: " + JSON.stringify(paymentMethods));
                    let paymentReceiptId;
                    for (const paymentMethod of paymentMethods) {
                        const savedResult = await proceedPayment({
                            opportunityId: this.recordId,
                            recievedAmount: paymentMethod.ReceivedAmount__c,
                            paymentMethods: [paymentMethod],
                            receiptId: paymentReceiptId
                        });
                        if (savedResult.PaymentReceipt__c) {
                            paymentReceiptId = savedResult.PaymentReceipt__c[0].Id;
                        } else {
                            continue;
                        }
                    }
                    this.showToast("Success", "Proceed Payment Successfully!", "success");
                    const message = {
                        messageText: "Invoke Refresh"
                    };
                    publish(this.messageContext, afterProceedPaymentChannel, message);
                    this.navigateToRecordPage(paymentReceiptId);
                    this.isLoading = false;
                } catch (error) {
                    console.error(JSON.stringify(error));
                    this.showToast("Error", "Proceed Payment Fail. Please contact Admin", "error");
                    this.isLoading = false;
                }
            } else {
                this.isLoading = false;
            }
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    // ----- End Handler -----

    // ----- Start Service -----
    injectStyle() {
        const inputAlign = document.createElement("style");
        inputAlign.innerText = `.number-input input{ text-align: right!important; } 
                                        .date-format-hide .slds-form-element__help{ display: none; } 
                                        .date-format-hide .slds-show{ display: block; }
                                        .slds-input[disabled], .slds-input.slds-is-disabled {color: #a49e9e !important; border-color : #a49e9e !important}
                                    `;
        document.body.appendChild(inputAlign);
    }

    calculateTotalReceivedAmount() {
        let receivedAmount = 0;
        this.paymentMethodSections.forEach((section) => {
            if (section.fields) {
                section.fields.forEach((field) => {
                    if (field.apiName === "ReceivedAmount__c") {
                        receivedAmount += parseFloat(field.value.toFixed(2));
                    }
                });
            }
        });
        this.totalReceivedAmount = receivedAmount;
    }

    sortConfig() {
        for (let key in this.configMap) {
            if (this.configMap.hasOwnProperty(key)) {
                this.configMap[key].sort((a, b) => a.order - b.order);
            }
        }
    }

    navigateToRecordPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: recordId,
                actionName: "view"
            }
        });
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toastEvent);
    }

    validateAllRequiredField() {
        const allValid = [...this.template.querySelectorAll("lightning-input, lightning-combobox")].reduce(
            (validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            },
            true
        );
        return allValid;
    }

    async setPaymentTypeMap() {
        let paymentTypePicklistValues = await getPicklistValues({
            objectName: "PaymentMethod__c",
            fieldName: "PaymentType__c"
        });
        paymentTypePicklistValues.forEach((eachPicklist) => {
            this.paymentTypeMap[eachPicklist.label] = eachPicklist.value;
        });
        // console.log('this.paymentTypeMap: ' + JSON.stringify(this.paymentTypeMap))
    }
    // ----- End Service -----
}