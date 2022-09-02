import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDomain from '@salesforce/apex/CreateWebSiteRequest.getDomain';

export default class OptionsRegisterModalLwc extends NavigationMixin(LightningElement) {

    @api isModalOpen;
    name;
    @api isForUniversity;
    type;
    @api program;

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

    // submitLoginPersonPortal() {
    //     this.isModalOpen = false;
    //     this.type = 'beneficiario';
    //     this.navigateToLoginPrivateSite();
    //     const selectedEvent = new CustomEvent("close")
    //     this.dispatchEvent(selectedEvent);
    // }

    submitNewLeadUniversity() {
        this.isModalOpen = false;
        this.type = 'University';
        this.navigateToLeadFormPageSite();
        const selectedEvent = new CustomEvent("close")
        this.dispatchEvent(selectedEvent);
    }

    // submitNewLeadPerson() {
    //     this.isModalOpen = false;
    //     this.type = 'Person';
    //     this.navigateToLeadFormPageSite();
    //     const selectedEvent = new CustomEvent("close")
    //     this.dispatchEvent(selectedEvent);
    // }

    // submitNewPerson() {
    //     this.isModalOpen = false;
    //     this.navigateToAutoRegisterPrivateSite();
    //     const selectedEvent = new CustomEvent("close")
    //     this.dispatchEvent(selectedEvent);
    // }

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
                url: '/formulario-unidiversidad?type='+this.type
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