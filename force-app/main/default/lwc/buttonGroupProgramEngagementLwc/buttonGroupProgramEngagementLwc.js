import { LightningElement, api, track } from 'lwc';

export default class ButtonGroupProgramEngagementLwc extends LightningElement {
    
    @api recordId;
    @track showManagerComponent = false;

    showManager(){
        this.showManagerComponent = this.showManagerComponent === true ? false : true;
    }

}