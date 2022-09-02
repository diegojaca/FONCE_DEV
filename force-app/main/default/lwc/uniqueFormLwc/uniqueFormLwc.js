import { LightningElement, api, wire, track } from 'lwc';
import Id from '@salesforce/user/Id';
import CONTACT_FIELD from '@salesforce/schema/User.ContactId';
import { getRecord } from 'lightning/uiRecordApi';
import getFundingRequest from '@salesforce/apex/CreateWebSiteRequest.getFundingRequest';
import getFundingProgram from '@salesforce/apex/CreateWebSiteRequest.getFundingProgram';
import getActualFundingRequests from '@salesforce/apex/CreateWebSiteRequest.getActualFundingRequests';

export default class UniqueFormLwc extends LightningElement {
    contactId;
    @api program;
    userId = Id;
    @api isUniversity = false;
    @api needResources = false;
    @api needRequirements = false;
    @api fundingRequestId; 
    @track openFundingRequest;
    countFundingRequest;
    userId = Id;
    createForm = false;
    requestStatus;
    programStatus;
    @track formClass = 'displayBlock';
    @track alertClass = 'displayNone';
    programType = '';

    connectedCallback(){
        if(this.program){
            this.program = decodeURIComponent(this.program);
        }
        if(this.program && !this.fundingRequestId){
            this.createForm = true;
        }
    }

    @wire(getRecord, { recordId: '$userId', fields: [CONTACT_FIELD] })
    wiredRecord({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.user = data;
            this.contactId = this.user.fields.ContactId.value;
            if(this.createForm){
                this.handleGetActualFundingRequests();
            }
        }
    }

    @wire(getFundingProgram, { program: '$program'})
    wiredGetProgram({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.needResources = data.NeedResources__c;
            this.needRequirements = data.NeedRequirementsInRequest__c;
            this.openFundingRequest = true;
            this.programType = data.Tipo_de_Programas_de_Becas__c;
        }
    }

    @wire(getFundingRequest, { fundingRequestId: '$fundingRequestId'})
    wiredGetFundingRequest({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.program = data.outfunds__FundingProgram__r.Nombre_Convocatoria__c;
            this.needResources = data.outfunds__FundingProgram__r.NeedResources__c;
            this.needRequirements = data.outfunds__FundingProgram__r.NeedRequirementsInRequest__c;
            if(data.outfunds__Status__c !== 'In progress' && data.outfunds__Status__c !== 'Rejected' && data.outfunds__Status__c !== 'Pendiente de Documentación'){
                this.openFundingRequest = false;
            }else{
                this.openFundingRequest = true;
            }         
        }
    }

    handleGetActualFundingRequests(){
        getActualFundingRequests ( { program: decodeURIComponent(this.program), contactId: this.contactId})
            .then((data) => {
                if(data.length > 0 && this.programType !== 'POR TALENTO DIGITAL'){
                    this.fundingRequestId = data[0].Id;
                    this.formClass = 'displayNone';
                    this.alertClass = 'displayBlock';
                }
            }).catch((error) => {
                this.error = error;
            }
        );
    }

    navigateToFormPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/formulario-inscripcion?recordId=' + this.fundingRequestId
            }
        });
    }

    editHandler(){
        this.navigateToFormPage();
    }
}