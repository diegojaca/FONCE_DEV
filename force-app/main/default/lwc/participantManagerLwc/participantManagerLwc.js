import { LightningElement, track, api, wire } from 'lwc';
import getProgramEngagement from '@salesforce/apex/CreateWebSiteRequest.getProgramEngagement';
import { refreshApex } from "@salesforce/apex";
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import STAGE_FIELD from '@salesforce/schema/pmdm__ProgramEngagement__c.pmdm__Stage__c';
import ID_FIELD from '@salesforce/schema/pmdm__ProgramEngagement__c.Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// Import custom labels
import PROGRAM_TYPE_CRUE from '@salesforce/label/c.PROGRAM_TYPE_CRUE';

export default class ParticipantManagerLwc extends LightningElement {

    @track requirementsClass;
    @track contactFormClass;
    @api programEngagementId;
    @track contactId;
    @track serviceDeliveries = [];
    @track serviceDeliveryIds = [];
    wiredProgramEngagement;
    @track objectivesIsNotEmpty = false;
    @track isNotRequiredRequirementsEmpty = true;
    @api returnVisible = false;
    @api finishVisible = false;
    programName;
    programType;
    @track infoText = 'Desde la pestaña "Requisitos" podrá agregar documentación. Desde la pestaña "Contacto" podrá acceder a los datos del contacto y modificarlos si fuera necesario.';

    @api get showProgramEngamenetTab() {
        return this.programType === PROGRAM_TYPE_CRUE;
    }
    
    @wire(getRecord, { recordId: '$programEngagementId'})
    wiredGetRecord({ data, error }) {
        if (data) {
            this.handleFileLoad();
        } else if (error) {
            console.error('ERROR => ', JSON.stringify(error));
        }
    }

    @wire(getProgramEngagement, {programEngagementId: '$programEngagementId'})
    wiredGetProgramEngagement(value) {
        this.wiredProgramEngagement = value;
        const {data, error} = value;
        if (data) {
            this.error = undefined; 
            this.contactId = data.pmdm__Contact__c;
            this.serviceDeliveries = data.pmdm__ServiceDeliveries__r;
            this.programName = data.pmdm__Program__r?.Origin_Funding_Request__r?.outfunds__FundingProgram__r?.Nombre_Convocatoria__c;
            this.programType = data.pmdm__Program__r?.Origin_Funding_Request__r?.outfunds__FundingProgram__r?.Tipo_de_Programas_de_Becas__c;
            for(let serviceDelivery in this.serviceDeliveries){
                this.serviceDeliveryIds.push(this.serviceDeliveries[serviceDelivery].Id);
            }
            this.objectivesIsNotEmpty = true;
        } else if (error) {
            this.error = error;
            console.log('ERROR => ', this.error);
        }
    }

    // handleGetProgramEngagement(){
    //     getProgramEngagement({programEngagementId: this.programEngagementId})
    //         .then((data) => {
    //             console.log('data: ',data);
    //             this.error = undefined; 
    //             this.contactId = data.pmdm__Contact__c;
    //             this.serviceDeliveries = data.pmdm__ServiceDeliveries__r;
    //             for(i in data){
    //                 this.serviceDeliveryIds.push(data[i].pmdm__Service__r.Objective__c);
    //             }
    //             console.log('this.serviceDeliveryIds: ',this.serviceDeliveryIds);
    //         }).catch((error) => {
    //             this.error = error;
    //             console.log('ERROR 1=> ', this.error);
    //         });
    // }

    handleFileLoad(){
        return refreshApex(this.wiredProgramEngagement);
    }

    connectedCallback(){
        //this.showRequirements();
        // this.handleGetProgramEngagement();
        // this.handleGetProgramEngagement();
        if(this.finishVisible){
            this.infoText = this.infoText + ' Desde la pestaña "Finalizar" podrá finalizar el proceso.';
        }
    }

    showList(){
        this.objectivesIsNotEmpty = false;
        this.serviceDeliveryIds = [];
        const selectedEvent = new CustomEvent("exit")
        this.dispatchEvent(selectedEvent);
    }

    handleRequiredRequirementsEmpty(){
        this.isNotRequiredRequirementsEmpty = false;
    }

    participantFinished(){
        this.isNotRequiredRequirementsEmpty = true;
        this.handleUpdateStage();
    }

    handleUpdateStage(){

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.programEngagementId;
        fields[STAGE_FIELD.fieldApiName] = 'Applied';

        const recordInput = { fields };
        
        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Etapa de participante actualizado',
                        variant: 'success'
                    })
                );
                // Display fresh data in the form
                // return refreshApex(this.request);
            })
            .catch(error => {
                this.isNotRequiredRequirementsEmpty = false;
                console.log('Error: ',error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error actualizando',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}