import { LightningElement, api, track, wire} from 'lwc';
import { refreshApex } from "@salesforce/apex";
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

export default class ProgramRequirementsLwc extends NavigationMixin(LightningElement) {

    @api programId;

    navigateToProjectPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/program/' + this.programId
            }
        });
    }

}