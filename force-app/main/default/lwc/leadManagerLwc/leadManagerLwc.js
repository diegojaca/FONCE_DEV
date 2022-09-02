import { LightningElement, track, api } from 'lwc';
import getLeadsByOwner from '@salesforce/apex/ExperienceCloudController.getLeadsByOwner';
import userId from '@salesforce/user/Id';

export default class LeadManagerLwc extends LightningElement {

    userId = userId;
    @track leads;
    isLoaded = false;
    @track recordId;
    @track managerClass;
    @track leadFormClass;
    @track contactFormClass;
    @api programId;
    @api type;

    connectedCallback(){
        this.showManager();
    }

    handleGetLeadsByOwner(){
        getLeadsByOwner({type: this.type})
            .then((data) => {
                this.error = undefined; 
                for(let i in data){
                    let lead = {
                        Name : data[i].Name,
                        N_mero_de_Documento__c : data[i].N_mero_de_Documento__c,
                        Index: parseInt(i) + 1,
                        Key: data[i].Id,
                        Id : data[i].Id
                    }
                    this.leads.push(lead);
                }
            }).catch((error) => {
                this.error = error;
                console.log('ERROR => ', this.error);
            });
            
    }

    addContact(){
        this.managerClass = 'displayNone';
        this.leadFormClass = 'displayNone';
        this.contactFormClass = 'displayBlock';
    }

    viewLead(event){
        this.recordId = this.leads[event.currentTarget.dataset.id].Id;
        this.managerClass = 'displayNone';
        this.leadFormClass = 'displayBlock';
        this.contactFormClass = 'displayNone';
    }

    showManager(){
        this.leads = [];
        this.managerClass = 'displayBlock';
        this.leadFormClass = 'displayNone';
        this.contactFormClass = 'displayNone';
        this.handleGetLeadsByOwner();
    }

    showProgramEngagements(){
        const selectedEvent = new CustomEvent("exit")
        this.dispatchEvent(selectedEvent);
    }
}