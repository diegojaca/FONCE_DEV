import { LightningElement, track } from 'lwc';

export default class ListOptionsLwc extends LightningElement {

    @track openOptionsModal = false;
    @track isUnidiversidad;

    // showPersonModal() {
    //     this.isUnidiversidad= false;
    //     this.openOptionsModal = true;
    // }

    showUniversityModal() {
        this.isUnidiversidad= true;
        this.openOptionsModal = true;
    }

    handleOnClose(){
        this.openOptionsModal = false;
    }
}