import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AllegationsFormLwc extends LightningElement {

    @api recordId;

    successHandler(){
        this.dispatchEvent(
            new ShowToastEvent({
                title: "Éxito",
                message: "Su alegación se ha adjuntado a la solicitud",
                variant: "success"
            })
        );
        const selectedEvent = new CustomEvent("success")
        this.dispatchEvent(selectedEvent);
    }

    errorHandler(event){
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: event.detail,
                variant: 'error'
            })
        );
    }
}