import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDomain from '@salesforce/apex/CreateWebSiteRequest.getDomain';
import getFundingProgram from '@salesforce/apex/CreateWebSiteRequest.getFundingProgram';

export default class OptionsFundingRequestRegisterModalLwc extends NavigationMixin(LightningElement) {

    @api isModalOpen;
    name;
    @api isForUniversity;
    @api needPersonLead;
    @api isInProgress;
    type;
    @api program;
    typeProgram;
    wiredFundingProgram

    domain;

    @wire(getDomain)
    wiredGetDomain({ error, data }) {
        if (data) {
            this.domain = data;
        } else if (error) {
            this.error = error;
            this.domain = undefined;
        }
    }

    @wire(getFundingProgram, {program:'$program'})
    wiredGetFundingProgram(value) {
        this.wiredFundingProgram = value;
        const { data, error } = value;
        if (data) {
            this.typeProgram = data.Tipo_de_Programas_de_Becas__c;               
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }

    renderedCallback(){
        this.template.querySelector('button').focus();
    }

    closeModal() {
        this.isModalOpen = false;
        const selectedEvent = new CustomEvent("close")
        this.dispatchEvent(selectedEvent);
    }
    
    submitLoginUniversityPortal() {
        this.isModalOpen = false;
        this.type = 'universidad';
        this.navigateToLoginPrivateSite();
        const selectedEvent = new CustomEvent("close")
        this.dispatchEvent(selectedEvent);
    }

    submitLoginPersonPortal() {
        this.isModalOpen = false;
        this.type = 'beneficiario';
        this.navigateToLoginPrivateSite();
        const selectedEvent = new CustomEvent("close")
        this.dispatchEvent(selectedEvent);
    }

    submitNewLeadUniversity() {
        this.isModalOpen = false;
        this.type = 'University';
        this.navigateToLeadFormPageSite();
        const selectedEvent = new CustomEvent("close")
        this.dispatchEvent(selectedEvent);
    }

    submitNewLeadPerson() {
        this.isModalOpen = false;
        this.type = this.typeProgram==='CAMPUS INCLUSIVO, CAMPUS SIN LÍMITE'?'PersonCampusInclusivos':'Person';
        this.navigateToLeadFormPageSite();
        const selectedEvent = new CustomEvent("close")
        this.dispatchEvent(selectedEvent);
    }

    submitNewPerson() {
        this.isModalOpen = false;
        this.navigateToAutoRegisterPrivateSite();
        const selectedEvent = new CustomEvent("close")
        this.dispatchEvent(selectedEvent);
    }

    navigateToLoginPrivateSite() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: 'https://'+this.domain+'/'+this.type+'/s/login' 
            }
        }).then(generatedUrl => {
            window.open(generatedUrl);
        });
    }

    navigateToLeadFormPageSite() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: '/formulario-unidiversidad?type='+this.type+'&program='+this.program  
            }
        }).then(generatedUrl => {
            window.open(generatedUrl);
        });
    }
    
    navigateToAutoRegisterPrivateSite() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: 'https://'+this.domain+'/beneficiario/s/login/SelfRegister' 
            }
        }).then(generatedUrl => {
            window.open(generatedUrl);
        });
    }

}