import { LightningElement, api, track, wire } from 'lwc';
import getRequirements from '@salesforce/apex/CreateWebSiteRequest.getRequirements';

export default class UniqueRequirementsUploaderLwc extends LightningElement {

    @api fundingRequestId = null;
    @api programId = null;
    @api serviceDeliveryIds;
    @track requirements;
    @track requirementsPresented;
    @api status = '';
    @api type = '';
    @api alertMsg = 'Su solicitud no estará completa hasta que no se suba la documentación requerida.';

    connectedCallback(){
        this.handleFileLoad();
    }

    handleGetRequirements(){
        getRequirements({fundingRequestId: this.fundingRequestId, programId: this.programId, serviceDeliveryIds: this.serviceDeliveryIds, types: this.types, status: this.status})
            .then((data) => {
                this.requirements = data;
                let requiredRequirements = 0;
                for(let requirement in data){
                    if(data[requirement].IsRequired__c){
                        requiredRequirements ++;
                    }
                }
                if(requiredRequirements === 0){
                    const selectedEvent = new CustomEvent("requiredrequirementsempty")
                    this.dispatchEvent(selectedEvent);
                }
            }).catch((error) => {
                this.error = error;
                console.log('ERROR => ', this.error);
            });
    }

    handleGetRequirementsPresented(){
        getRequirements({fundingRequestId: this.fundingRequestId, programId: this.programId, serviceDeliveryIds: this.serviceDeliveryIds, types: this.types, status: 'Accepted,In Progress,Rejected'})
            .then((data) => {
                this.requirementsPresented = data;
            }).catch((error) => {
                this.error = error;
                console.log('ERROR => ', this.error);
            });
    }

    get acceptedFormats() {
        return ['.pdf', '.png'];
    }

    handleFileLoad(){
        this.handleGetRequirements();
        this.handleGetRequirementsPresented();
    }
    
}