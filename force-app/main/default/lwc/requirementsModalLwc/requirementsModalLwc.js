import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

const ESC_KEY_CODE = 27;
const ESC_KEY_STRING = 'Escape';
const TAB_KEY_CODE = 9;
const TAB_KEY_STRING = 'Tab';
export default class RequirementsModalLwc extends NavigationMixin(LightningElement) {

    isFirstRender = true;
    isOpen = false;
    @api program;
    name;

    renderedCallback() {
        this.template.querySelector('button').focus();  
    }

    @api
    toggleModal() {
        this.isOpen = !this.isOpen;
    }

    @api
    get cssClass() {
        const baseClasses = ['slds-modal'];
        baseClasses.push([this.isOpen ? 'slds-visible slds-fade-in-open' : 'slds-hidden']);
        return baseClasses.join(' ');
    }

    @api
    get modalAriaHidden() {
        return !this.isOpen;
    }

    closeModal(event) {
        event.stopPropagation();
        this.toggleModal();
    }

    innerClickHandler(event) {
        event.stopPropagation();
    }

    handleKeyPress(event) {
        this.innerKeyUpHandler(event);
    }

    innerKeyUpHandler(event) {
        if (event.keyCode === ESC_KEY_CODE || event.code === ESC_KEY_STRING) {
            this.toggleModal();
        } else if (event.keyCode === TAB_KEY_CODE || event.code === TAB_KEY_STRING) {
            const el = this.template.activeElement;
            let focusableElement;
            if (el && el.classList.contains('lastLink')) {
                focusableElement = this._getCloseButton();
            }
            if (focusableElement) {
                focusableElement.focus();
            }
        }
    }

    _getCloseButton() {
        let closeButton = this.template.querySelector('button[title="X, cerrar ventana"]');
        if (!closeButton) {
            // if no header is present, the first button is
            // always the cancel button
            closeButton = this.template.querySelector('button');
        }
        return closeButton;
    }

    navigateToFormPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/formulario-inscripcion?program=' +  this.name
            }
        });
    }

    submitDetails(event){
        this.name = this.program.Nombre_Convocatoria__c;
        event.stopPropagation();
        this.navigateToFormPage();
        this.toggleModal();
    }

}