import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getFundingRequest from '@salesforce/apex/CreateWebSiteRequest.getFundingRequest';

export default class ButtonGroupFundingRequestLwc extends NavigationMixin(LightningElement) {

    @api recordId;
    requestStatus;
    programStatus;
    disabledEdit = true;
    disabledAllegations = true;
    showAllegationsForm = false;

    connectedCallback(){
        this.handleGetFundingRequest();
    }

    handleGetFundingRequest(){
        getFundingRequest ( { fundingRequestId: this.recordId})
            .then((data) => {
                this.requestStatus = data.outfunds__Status__c;
                this.programStatus = data.outfunds__FundingProgram__r.outfunds__Status__c;
                if(this.requestStatus === 'En Proceso de Alegaciones/Subsanaciones'){
                    this.disabledAllegations = false;
                }else if((this.requestStatus === 'In progress' || this.requestStatus === 'Rejected' || this.requestStatus === 'Pendiente de Documentación') && this.programStatus === 'In progress'){
                    this.disabledEdit = false;
                }
            }).catch((error) => {
                this.error = error;
            }
        );
    }

    editHandler(){
        this.navigateToFormPage();
    }

    allegationsHandler(){
        this.showAllegationsForm = true;
    }

    successAllegationsFormHandler(){
        this.showAllegationsForm = false;
    }

    navigateToFormPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/formulario-inscripcion?recordId=' + this.recordId
            }
        });
    }
}