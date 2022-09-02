import { LightningElement, api, track, wire } from 'lwc';
import getFieldsBySections from '@salesforce/apex/CreateWebSiteRequest.getFieldsBySections';

export default class UniqueContactFormLwc extends LightningElement {
    @api contactId;
    // @api contactChange;
    @track sectionsMap = [];
    errorFields = ["AccountId"];
    @track activeSections = [];
    @track loaded = false;
    @api layoutName = 'Contact-Contact Layout Portal';
    @api dni;
    @api buttonName = 'Continuar';
    
    @wire(getFieldsBySections, {layoutName: '$layoutName'})
    wiredGetFieldsBySections({ error, data }) {
        if (data) {
            this.sectionsMap = [];
            this.activeSections = [];
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

    renderedCallback(){
        let dniTemplate = this.template.querySelector(".N_mero_de_Documento__c"); 
        if(this.dni != null && dniTemplate != null){
            dniTemplate.value = this.dni;
        } 
    }

    handleSuccess(event) {
        this.loaded = false;
        if(this.contactId === undefined || this.contactId === null) {
            this.contactId = event.detail.id;
            const selectedEvent = new CustomEvent("contactcreate",{detail: this.contactId})
            this.dispatchEvent(selectedEvent);
        }
        const selectedEvent = new CustomEvent("contactchange")
        this.dispatchEvent(selectedEvent);
    }

    handleSubmit(){
        this.loaded = true;
    }

    handleError(event) {
        this.loaded = false;
        console.log('ERROR => ',event.detail);
    }
}