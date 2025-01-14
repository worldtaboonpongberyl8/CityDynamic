import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class MyModal extends LightningModal {

    @api title = 'Confirm';
    @api message = 'Are you sure you want to proceed?';

    handleConfirm() {
        this.close(true); 
    }

    handleCancel() {
        this.close(false); 
    }

}