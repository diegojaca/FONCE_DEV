import { LightningElement, track, api, wire } from 'lwc';
import getProgramEngagementsByProgram from '@salesforce/apex/CreateWebSiteRequest.getProgramEngagementsByProgram';
import getProgramType from '@salesforce/apex/CreateWebSiteRequest.getProgramType';
import { NavigationMixin } from 'lightning/navigation';
import PROGRAM_TYPE_CRUE from '@salesforce/label/c.PROGRAM_TYPE_CRUE';

export default class ProgramEngagementManagerLwc extends NavigationMixin(LightningElement) {

    @api recordId;
    @track managerClass;
    @track leadManagerClass;
    @track programEngagements;
    @track participantManagerClass;
    @track programEngagementId;

    get showAddParticipantsButton(){
        return !this.type || this.type !== PROGRAM_TYPE_CRUE;
    }

    connectedCallback(){
        this.showManager();
    }

    @wire(getProgramType, {recordId: '$recordId'})
    wiredGetProgramType({ error, data }) {
        if (data) {
            this.type = data.Origin_Funding_Request__r.outfunds__FundingProgram__r.Tipo_de_Programas_de_Becas__c
        } else if (error) {
            console.log('ERROR => ',error);
            this.error = error;
        }
    }

    showLeadManager(){
        this.managerClass = 'displayNone';
        this.leadManagerClass = 'displayBlock';
        this.participantManagerClass = 'displayNone';
    }

    showManager(){
        this.programEngagementId = null;
        this.programEngagements = [];
        this.managerClass = 'displayBlock';
        this.leadManagerClass = 'displayNone';
        this.participantManagerClass = 'displayNone';
        this.handleGetProgramEngagementsByProgram();
    }

    addRequirements(event){
        var key = event.currentTarget.dataset.id;
        this.programEngagementId = this.programEngagements[key].Id;
        this.managerClass = 'displayNone';
        this.leadManagerClass = 'displayNone';
        this.participantManagerClass = 'displayBlock';
    }

    handleGetProgramEngagementsByProgram(){
        getProgramEngagementsByProgram({recordId: this.recordId})
            .then((data) => {
                this.error = undefined; 
                for(let i in data){
                    let programEngagement = {
                        Name : data[i].Name,
                        pmdm__Stage__c : data[i].pmdm__Stage__c,
                        Index: parseInt(i) + 1,
                        Key: data[i].Id,
                        Id : data[i].Id
                    }
                    this.programEngagements.push(programEngagement);
                }
            }).catch((error) => {
                this.error = error;
                console.log('ERROR => ', this.error);
            });
    }

    showProgram(){
        this.navigateToProjectPage();
    }

    navigateToProjectPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/program/' + this.recordId
            }
        });
    }
}