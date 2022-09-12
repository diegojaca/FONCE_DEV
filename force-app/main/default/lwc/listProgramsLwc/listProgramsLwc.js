import { LightningElement, wire,api, track } from 'lwc';
import getPrograms from '@salesforce/apex/CreateWebSiteRequest.getPrograms';
import { NavigationMixin } from 'lightning/navigation';
import isGuest from '@salesforce/user/isGuest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ListProgramsLwc extends NavigationMixin(LightningElement) {
    @api programs;
    @api programRecord;//a0t1q000001N7duAAC

    @track showSearchComponent = false;
    @track showFormComponent = false;
    @track isPublicSite = isGuest;
    @api isUniversityPortal;
    portal;

    connectedCallback(){
        if(this.isPublicSite){
            this.portal = 'private';
        }else if(this.isUniversityPortal){
            this.portal = 'university';
        }else{
            this.portal = 'person';
        }
   } 

    @wire(getPrograms, {portal:'$portal'})
    wiredGetPrograms({ error, data }) {
        if (data) {
            this.programs = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.fundingPrograms = undefined;
        }
    }

    showSearch(event) {
        this.programRecord = this.programs[event.target.dataset.index];
        // this.navigateToInfoPage();
        if(this.isPublicSite){
            this.navigateToInfoPageFromPublicSite();
        }else{
            this.navigateToInfoPageFromPrivateSite();
        };
        
    }
    
    navigateToInfoPageFromPublicSite() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: '/programa/' + this.programRecord.Id
            }
        }).then(generatedUrl => {
            window.open(generatedUrl);
        });
    }

    navigateToInfoPageFromPrivateSite() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: 'programa/' + this.programRecord.Id
            }
        });
    }

    showForm(event) {
        this.programRecord = this.programs[event.target.dataset.index];
        event.preventDefault();
        event.stopPropagation();
        this.template.querySelector("c-requirements-modal-lwc").toggleModal();
    }

    changeBorderColor(event) {

        this.programRecord = this.programs[event.target.dataset.index];
        this.setBorderColor(event, this.programRecord.BorderColorPublicWeb__c, 3);
    }

    removeBorderColor(event) {
        this.setBorderColor(event, 'black', 1);
    }

    setBorderColor(event, color, borderWith){

        let targetId = event.target.dataset.targetId;
        this.template.querySelector(`[data-id="${targetId}"]`).style.borderColor = color;
        this.template.querySelector(`[data-id="${targetId}"]`).style.borderWidth = borderWith + "px";
    }
}