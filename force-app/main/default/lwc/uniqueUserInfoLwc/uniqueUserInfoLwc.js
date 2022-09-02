import { LightningElement, api, wire, track } from 'lwc';
import Id from '@salesforce/user/Id';
import CONTACT_FIELD from '@salesforce/schema/User.ContactId';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFieldsBySections from '@salesforce/apex/CreateWebSiteRequest.getFieldsBySections';

export default class UniqueUserInfoLwc extends LightningElement {
    contactId;
    @api program;
    userId = Id;
    @track sectionsMap = [];
    errorFields = ["AccountId"];
    @track activeSections = [];

    @wire(getRecord, { recordId: '$userId', fields: [CONTACT_FIELD] })
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
                    title: 'Error loading user',
                    message,
                    variant: 'error',
                }),
            );
        } else if (data) {
            this.user = data;
            this.contactId = this.user.fields.ContactId.value;
            console.log(this.contactId);
        }
    }

    @wire(getFieldsBySections, {layoutName: 'Contact-Contact Layout Portal'})
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

    handleSuccess() {
        const toastEvent = new ShowToastEvent({
            title: `Se guardarón los cambios`, 
            variant:"success"
        })
        this.dispatchEvent(toastEvent);
    }

    // handleSubmit(){
    //     this.loaded = true;
    // }

}