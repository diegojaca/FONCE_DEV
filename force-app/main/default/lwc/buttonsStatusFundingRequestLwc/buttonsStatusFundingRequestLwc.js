import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import STATUS_FIELD from '@salesforce/schema/outfunds__Funding_Request__c.outfunds__Status__c';
import ID_FIELD from '@salesforce/schema/outfunds__Funding_Request__c.Id';

export default class ButtonsStatusFundingRequestLwc extends LightningElement {

    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD]})
    request;

    get showEvaluateButtons(){
        const status = this.request?.data?.fields[STATUS_FIELD.fieldApiName].value;
        return status === 'En Trámite de Valoración' || status === 'Pendiente de Documentación';
    }

    get showGrantedButton(){
        const status = this.request?.data?.fields[STATUS_FIELD.fieldApiName].value;
        return status === 'Aceptada' || status === 'Lista de Espera';
    }

    get showAwaitListButton(){
        return this.request?.data?.fields[STATUS_FIELD.fieldApiName].value === 'Aceptada';
    }

    /**
    * @description This method update request status
    * @author diego.jacanamijoy@s4g.es | 11-07-2022
    **/
    handleUpdateStatus(event){

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = event.target.name;

        const recordInput = { fields };
        
        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Estado de solicitud actualizado',
                        variant: 'success'
                    })
                );
                // Display fresh data in the form
                return refreshApex(this.request);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error actualizando',
                        message: this.checkErrorMessage(error),
                        variant: 'error'
                    })
                );
            });
    }

    /**
    * @description This method check error message to show
    * @author diego.jacanamijoy@s4g.es | 11-07-2022
    **/
    checkErrorMessage(errorMessage) {

        let result = errorMessage.body.message;

        if (errorMessage.body?.output?.errors[0]?.errorCode === 'FIELD_CUSTOM_VALIDATION_EXCEPTION') {
            result = errorMessage.body.output.errors[0].message;
        }

        return result;
    }
}