import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class ButtonGroupProgramLwc extends NavigationMixin(LightningElement) {

    @api recordId;

    navigateToProjectRequirementsPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/project-manager?recordId=' + this.recordId
            }
        });
    }

    navigateToProjectManagerPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/project-requirements?recordId=' + this.recordId
            }
        });
    }
}