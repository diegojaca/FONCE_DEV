import { LightningElement, wire,api,track  } from 'lwc';
import getInnerData from '@salesforce/apex/CreateWebSiteRequest.getInnerData';
import PDF_LOGO from '@salesforce/resourceUrl/iconoPdf';
import SECTION_LINE from '@salesforce/resourceUrl/lineaImagen';
import { NavigationMixin } from 'lightning/navigation';
import isGuest from '@salesforce/user/isGuest';
import PROGRAM_UNIQUE_NAME from '@salesforce/schema/outfunds__Funding_Program__c.Nombre_Convocatoria__c';
import MINIMUN_REQUIREMENTS from '@salesforce/schema/outfunds__Funding_Program__c.Minimum_Requirements__c';

export default class WebSectionsLwc extends NavigationMixin(LightningElement) {
    @api sectionsInner = [];
    @api programId;
    @track isPublicSite = isGuest;
    @track openOptionsModal = false;
    @track isForUniversity;
    @track needPersonLead;
    @track isInProgress;
    @track programRecord = [];
    @track openRequirementsModal = false;
    @track registerOption = true;
    @track otherButtons = [];
    accessButtonExit;
    registerButtonExit;
    otherButtonExit;
    program;

    pdfLogoUrl = PDF_LOGO;
    sectionLine = SECTION_LINE;

    @wire(getInnerData, {programId: '$programId'})
    wiredSectionsInner({ error, data }) {
        if (data) {
            console.log(data);
            if(data.length === 0){
                this.registerOption = false;
            }
            this.isForUniversity = data[0].ProgramaBeca__r.IsForUniversity__c;
            this.needPersonLead = data[0].ProgramaBeca__r.NeedPersonLeadInscription__c;
            this.isInProgress = data[0].ProgramaBeca__r.IsInProgress__c;
            const fields = [];
            this.program = data[0].ProgramaBeca__r.Nombre_Convocatoria__c;
            fields[PROGRAM_UNIQUE_NAME.fieldApiName] = this.program;
            fields[MINIMUN_REQUIREMENTS.fieldApiName] = data[0].ProgramaBeca__r.Minimum_Requirements__c;
            this.programRecord = fields;
            this.error = undefined;
            for(let i in data){
                if(data[i].RecordType.DeveloperName === 'ButtonGroup'){
                    for(let j in data[i].Sections__r){
                        if(data[i].Sections__r[j].Type__c === 'AccessButton' && data[i].Sections__r[j].IsVisible__c){
                            this.accessButtonExit = true;
                        }else if(data[i].Sections__r[j].Type__c === 'RegisterButton' && data[i].Sections__r[j].IsVisible__c){
                            this.registerButtonExit = true;
                        }else if(data[i].Sections__r[j].Type__c === 'Other' && data[i].Sections__r[j].IsVisible__c){
                            this.otherButtonExit = true;
                            this.otherButtons.push(data[i].Sections__r[j]);
                        }
                        
                    }
                }else if(data[i].RecordType.DeveloperName === 'Principal'){
                    this.sectionsInner.push(data[i]);
                }
            }
        } else if (error) {
            this.error = error;
            this.sectionsInner = undefined;
            this.buttons = undefined;
        }
    }

    showForm(event) {
        event.preventDefault();
        event.stopPropagation();
        this.template.querySelector("c-requirements-modal-lwc").toggleModal();
    }

    showPrograms() {
        this.navigateToProgramsPage();
    }

    navigateToProgramsPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/'
            }
        });
    }

    buttonAction(event){
        this.navigateToCustomPage(this.otherButtons[event.target.dataset.index].URL__c);
    }

    navigateToCustomPage(url) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

    showModal() {
        this.openOptionsModal = true;
    }

    handleOnClose(){
        this.openOptionsModal = false;
    }


































    // navigateToFormPage() {
    //     this[NavigationMixin.GenerateUrl]({
    //         type: 'standard__webPage',
    //         attributes: {
    //             url: '/s/formulario-inscripcion?program=' + this.program
    //         }
    //     }).then(generatedUrl => {
    //         window.open(generatedUrl);
    //     });
    // }

    // navigateToProgramsPageFromPublicSite() {
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__webPage',
    //         attributes: {
    //             url: '/'
    //         }
    //     });
    // }

    // navigateToProgramsPageFromPrivateSite() {
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__webPage',
    //         attributes: {
    //             url: '/becas'
    //         }
    //     });
    // }
  

    // showProgramsFromPrivateSite() {
    //     this.navigateToProgramsPageFromPrivateSite();
    // }

    // showProgramsFromPublicSitee() {
    //     this.navigateToProgramsPageFromPublicSite();
    // }

    

    
    
}