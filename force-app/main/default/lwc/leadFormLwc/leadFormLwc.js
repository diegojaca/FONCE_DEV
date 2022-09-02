import { LightningElement, api, track, wire } from 'lwc';
import convertLead from '@salesforce/apex/CreateWebSiteRequest.convertLead';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';
import PROGRAM_FIELD from '@salesforce/schema/pmdm__ProgramEngagement__c.pmdm__Program__c';
import CONTACT_FIELD from '@salesforce/schema/pmdm__ProgramEngagement__c.pmdm__Contact__c';
import NAME_FIELD from '@salesforce/schema/pmdm__ProgramEngagement__c.Name';
import PROGRAM_ENGAGEMENT_OBJECT from '@salesforce/schema/pmdm__ProgramEngagement__c';
import getProgramEngagementsByProgramAndContact from '@salesforce/apex/CreateWebSiteRequest.getProgramEngagementsByProgramAndContact';
import ID from '@salesforce/user/Id';
import { updateRecord } from 'lightning/uiRecordApi';
import BECADEINTERES_FIELD from '@salesforce/schema/Lead.BecaDeInteres__c';
// import COMUNIDADAUTONOMA_FIELD from '@salesforce/schema/Lead.ComunidadAutonoma__c';
// import RECORDTYPEID_FIELD from '@salesforce/schema/Lead.RecordTypeId';
import OWNERID_FIELD from '@salesforce/schema/Lead.OwnerId';
import ID_FIELD from '@salesforce/schema/Lead.Id';
import fireAssignmentRule from '@salesforce/apex/CreateWebSiteRequest.fireAssignmentRule';
import { getRecord } from 'lightning/uiRecordApi';

// const FIELDS = [BECADEINTERES_FIELD];

export default class LeadFormLwc extends LightningElement {
    @api recordId;
    @api programId;
    contactId;
    programEngagement;
    disabledAcept = false;  
    programEngagementExist = false;
    @track loaded = false;
    @track alertForm = false;
    userId = ID;
    

    @wire(getRecord, { recordId: '$recordId', fields: [BECADEINTERES_FIELD]  })
    lead;

    showList(){
        this.contactId = null;
        this.programEngagement = null;
        this.disabledAcept = false;
        const selectedEvent = new CustomEvent("exit")
        this.dispatchEvent(selectedEvent);
    }

    convertLead(){
        this.alertForm = false;
        this.loaded = true;
        this.disabledAcept = true;
        this.handleConvertLead(this.recordId);
    }

    handleConvertLead(leadId){
        convertLead({leadId: leadId})
            .then((data) => {
                this.contactId = data;
                this.error = undefined; 
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Éxito",
                        message: "Candidato convertido",
                        variant: "success"
                    })
                );
                this.searchProgramEngagement();
            }).catch((error) => {
                this.error = error;
                this.loaded = false;
                console.log('ERROR => ', this.error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: "Candidato no convertido",
                        variant: "error"
                    })
                );
            });
    }

    searchProgramEngagement(){
        this.handleGetProgramEngagementsByProgramAndContact();
    }

    createProgramEngagement(){
        const fields = {};
        fields[CONTACT_FIELD.fieldApiName] = this.contactId;
        fields[PROGRAM_FIELD.fieldApiName] = this.programId;
        fields[NAME_FIELD.fieldApiName] = 'test';
        this.programEngagement = {apiName: PROGRAM_ENGAGEMENT_OBJECT.objectApiName, fields};
        this.insertProgramEngagement();
    }

    insertProgramEngagement(){
        createRecord(this.programEngagement)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Exito',
                    message: 'Participante creado',
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            this.error = error;
            console.log('ERROR => ', this.error);
            this.loaded = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creando el registro',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    } 

    handleGetProgramEngagementsByProgramAndContact(){
        getProgramEngagementsByProgramAndContact({programId: this.programId, contactId: this.contactId})
            .then((data) => {
                if(data.length === 0){
                    this.createProgramEngagement();
                }
                this.loaded = false;
                this.error = undefined; 
            }).catch((error) => {
                this.loaded = false;
                this.error = error;
                console.log('ERROR => ', this.error);
            }
        );
    }

    showAlertForm(){
        this.alertForm = true;
    }

    showLeadForm(){
        this.alertForm = false;
    }

    assignLead(){
        this.handleUpdateOwner();
    }

    assignToQueue(){
        this.handleAssignToQueue();
    }

    handleUpdateOwner(){

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[OWNERID_FIELD.fieldApiName] = this.userId;

        const recordInput = { fields };
        
        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Propietario actualizado',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                this.error = error;
                console.log('ERROR => ', this.error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error actualizando',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    handleAssignToQueue(){
        fireAssignmentRule({leadId: this.recordId})
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Éxito",
                        message: "Interesado devuelto a la lista",
                        variant: "success"
                    })
                );
            }).catch((error) => {
                this.error = error;
                console.log('ERROR => ', this.error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: "Error actualizando",
                        variant: "error"
                    })
                );
            });
    }

    get isCampus(){
        return this.lead?.data?.fields[BECADEINTERES_FIELD.fieldApiName].value ===  'CAMPUS INCLUSIVO, CAMPUS SIN LÍMITE';
    }
}