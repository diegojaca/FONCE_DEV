import { LightningElement, track, wire, api } from 'lwc';
import getUniversityProgram from '@salesforce/apex/CreateWebSiteRequest.getUniversityProgram';

export default class UniqueUniversityFormLwc extends LightningElement {
    @api program;
    @track needResources;
    @track isUniversity = true;
    @api fundingRequestId;
    needRequirements = false;

    connectedCallback(){
        if(this.program){
            this.program = decodeURIComponent(this.program);
        }
    }

    @wire(getUniversityProgram, {name:'$program'})
    wiredGetUniversityProgram({ error, data }) {
        if (data) {
            this.needResources = data.NeedResources__c;
            this.needRequirements = data.NeedRequirementsInRequest__c;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.program = undefined;
        }
    }    
}