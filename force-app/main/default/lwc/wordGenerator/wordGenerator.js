import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import validateRecordIdtoGetDocTemplate from '@salesforce/apex/WordContentController.validateRecordIdtoGetDocumentTemplate';
import startGenerateDocx from '@salesforce/apex/WordContentController.startGenerateDocx';

export default class WordGenerator extends NavigationMixin(LightningElement) {
    @api currentRecordId;
    @api selectedLanguage = 'TH';
    @api templateMappingType;
    @api paramInput;
    currentPageRef;

    remainingZipIds = [];
    remainingDocNames = [];
    fieldAPINameSaveToExistingFiles = [];
    

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            //it gets executed before the connected callback and avilable to use
            this.currentPageRef = currentPageReference;
            
            this.generatefile();
        }
    }

    generatefile(){
        if(this.currentPageRef.type == 'standard__quickAction'){
            const param = {
                targetRecordId: this.currentRecordId,
                language: this.selectedLanguage,
                templateMappingType: this.templateMappingType,
                paramInput: this.paramInput
            };
            validateRecordIdtoGetDocTemplate(param).then(files => {
                if (files.length == 0) {
                    this.showErrorToast('Template Not Found.');
                } else if (files[0].ErrorMessage) {
                    this.showErrorToast(files[0].ErrorMessage);
                } else {
                    this.generateDocument(files);
                }
            })
            .catch(error => {
                console.error('validateRecordIdtoGetDocTemplate error: ', error);
                this.handlerError(error);
            });
        }
        else{
            if(this.currentPageRef.state.c__recordId){
                this.currentRecordId = this.currentPageRef.state.c__recordId;
            }
            if(this.currentPageRef.state.c__remainingDocNameList){
                this.remainingDocNames = this.currentPageRef.state.c__remainingDocNameList.split(',');
            }
            if(this.currentPageRef.state.c__remainingList){
                this.remainingZipIds = this.currentPageRef.state.c__remainingList.split(',');
            }
            if(this.currentPageRef.state.c__remainingFieldAPISaveToExistingList){
                this.fieldAPINameSaveToExistingFiles = this.currentPageRef.state.c__remainingFieldAPISaveToExistingList.split(',');
            }
            this.zipFileToWordAfterReplaceAllSyntax();
        }

    }

    zipFileToWordAfterReplaceAllSyntax(){
        // ถ้าไม่มี file ที่ต้อง gen แล้ว ให้ redirect ไปที่ record ตัวเอง
        if(this.remainingDocNames.length == 0){
            window.location.href = '/' + this.currentRecordId

            // setTimeout(() => {
                // this.dispatchEvent(new RefreshEvent());
                
            //     window.location.reload();
            //   }, 300);

            // this[NavigationMixin.Navigate]({
            //     type: 'standard__recordPage',
            //     attributes: {
            //         recordId: this.currentRecordId,
            //         actionName: 'view'
            //     }
            // });
        }

        // ถ้ามี file ที่ต้อง gen ต่อ ให้ redirect ไปที่ ZipDocument เพื่อ gen file ต่อไป
        else{
            
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: "/apex/ZipDocument?id=" + this.remainingZipIds[0] + 
                    "&recordId=" + this.currentRecordId + 
                    "&remainingList=" + this.remainingZipIds + 
                    "&remainingDocNameList=" + this.remainingDocNames + 
                    "&remainingFieldAPISaveToExistingList=" + this.fieldAPINameSaveToExistingFiles
                }
            });
        }
    }

    generateDocument(files){
        this.remainingZipIds = [];
        this.remainingDocNames = [];
        this.fieldAPINameSaveToExistingFiles = [];

        files.forEach(file => {
            if (file.ErrorMessage) {
                this.showErrorToast(file.ErrorMessage);
            } 
            else{
                this.remainingZipIds.push(file.DocumentId);
                this.remainingDocNames.push(file.RunningNumber);
                if(file.DocumentTemplateMappingMDT.IsSaveToExistingFile__c){
                    this.fieldAPINameSaveToExistingFiles.push(file.DocumentTemplateMappingMDT.FieldAPINameSaveToExistingFile__c);
                }
                else{
                    this.fieldAPINameSaveToExistingFiles.push('no');
                }
            }
        });

        files.forEach((file, index) => {
            const param = {
                targetRecordId: this.currentRecordId,
                documentDetailString: JSON.stringify(file)
            };

            startGenerateDocx(param).then(result => {
                if((files.length - 1) == index){
                    this.showSuccessToast('Starting create a document...');
                    this.zipFileToWordAfterReplaceAllSyntax();
                }
    
            }).catch(error => {
                console.error('startGenerateDocx error: ', error);
                this.handlerError(error);
            });
        });
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