import { LightningElement, api, track, wire } from 'lwc';
import getFieldsBySections from '@salesforce/apex/CreateWebSiteRequest.getFieldsBySections';
import ACCOUNTID_FIELD from '@salesforce/schema/Contact.AccountId';

import { getRecord } from 'lightning/uiRecordApi';

export default class UniqueAccountFormLwc extends LightningElement {
    @track accountId;
    @api contactId;
    // @api accountChange;
    @track sectionsMap =[];
    errorFields = ["npe01__One2OneContact__c"];
    @track activeSections = [];
    @track loaded = false;

    @wire(getRecord, { recordId: '$contactId', fields: [ACCOUNTID_FIELD] })
    wiredRecord({ error, data }) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading account',
                    message,
                    variant: 'error',
                }),
            );
        } else if (data) {
            this.accountId = data.fields.AccountId.value;
            this.error = undefined;
            const selectedEvent = new CustomEvent("accountidchange", {
                detail: this.accountId
            })
            this.dispatchEvent(selectedEvent);
        }
    }

    
    @wire(getFieldsBySections, {layoutName: 'Account-University Layout'})
    wiredGetFieldsBySections({ error, data }) {
        if (data) {
            var sections = data;
            this.error = undefined;
            for(var section in sections){
                var fieldsMap = [];
                for(var field in sections[section]){
                    if(!this.errorFields.includes(field)){
                        fieldsMap.push({value:sections[section][field], key:field}); 
                    }
                }   
                this.activeSections.push(section);
                this.sectionsMap.push({value:fieldsMap, key:section});
            }
        } else if (error) {
            this.error = error;
            this.sectionsMap = undefined;
        }
    }

    handleSuccess(event) {
        this.loaded = false;
        this.accountId = event.detail.id;
        const selectedEvent = new CustomEvent("accountchange")
        this.dispatchEvent(selectedEvent);
    }

    handleSubmit(){
        this.loaded = true;
    }

    handleError(event) {
        this.loaded = false;
        console.log('Error: ',event.detail);
    }
}