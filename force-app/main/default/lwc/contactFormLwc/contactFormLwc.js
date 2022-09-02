import { LightningElement, api , track } from 'lwc';
import convertLead from '@salesforce/apex/CreateWebSiteRequest.convertLead';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContactByDni from '@salesforce/apex/CreateWebSiteRequest.getContactByDni';
import getProgramEngagementsByProgramAndContact from '@salesforce/apex/CreateWebSiteRequest.getProgramEngagementsByProgramAndContact';
import { createRecord } from 'lightning/uiRecordApi';
import PROGRAM_FIELD from '@salesforce/schema/pmdm__ProgramEngagement__c.pmdm__Program__c';
import CONTACT_FIELD from '@salesforce/schema/pmdm__ProgramEngagement__c.pmdm__Contact__c';
import NAME_FIELD from '@salesforce/schema/pmdm__ProgramEngagement__c.Name';
import PROGRAM_ENGAGEMENT_OBJECT from '@salesforce/schema/pmdm__ProgramEngagement__c';

export default class ContactFormLwc extends LightningElement {
    @track recordId;
    @track dni;
    notCorrectDni = true;
    loaded = false;
    showForm = false;
    disabledChange = true;
    @api programId;
    @track contactInfo;

    showList(){
        this.dni = null;
        this.notCorrectDni = true;
        this.loaded = false;
        this.recordId = null;
        this.disabledChange = true;
        this.showForm = false;
        const selectedEvent = new CustomEvent("exit")
        this.dispatchEvent(selectedEvent);
    }

    handleDni(event){
        this.dni = event.detail.value;
        this.validateDoc(this.dni);
    }

    searchContact(){
        this.loaded = true;
        this.showForm = true;
        this.handleGetContactByDni();
    }

    handleOnContactCreate(event){
        this.recordId = event.detail;
    }

    handleOnContactChange(){
        this.searchProgramEngagement();
        // this.showList();
    }

    validateWord(number, word){
        let correctWord = 'TRWAGMYFPDXBNJZSQVHLCKE';
        number = number % 23;
        correctWord = correctWord.substring(number, number + 1);
        return correctWord != word;
    }

    validateDoc(doc){
        var regular_expression_doc = /^[xyzXYZ\d]\d{7}[a-zA-Z]$/;
                
        let dniTemplate = this.template.querySelector(".dni");
        if(doc.length === 9) {
            if(regular_expression_doc.test(doc) === true) {
                if(!this.charIsLetter(doc.substring(0, 1))){
                    doc = doc.substring(0, doc.length - 1) + doc.substring(doc.length - 1, doc.length).toUpperCase();
                    let number = doc.substring(0, doc.length - 1);
                    let word = doc.substring(doc.length - 1, doc.length);
                    if (this.validateWord(number, word)) {
                        this.notCorrectDni = true;
                        this.recordId = null;
                        this.showForm = false;
                        this.disabledChange = true;
                        dniTemplate.setCustomValidity('Por favor, escriba la letra correcta.');
                    } else {
                        dniTemplate.setCustomValidity('');
                        this.notCorrectDni = false;
                    }
                }else{
                    doc = doc.substring(0, 1).toUpperCase() + doc.substring(1, doc.length - 1) + doc.substring(doc.length - 1, doc.length).toUpperCase();
                    let firstLetter = doc.substring(0, 1).toUpperCase();
                    let firstLetterNumber = firstLetter === 'X' ? 0 : firstLetter === 'Y' ? 1 : 2;
                    let number = firstLetterNumber + doc.substring(1, doc.length - 1);
                    let word = doc.substring(doc.length - 1, doc.length).toUpperCase();
                    if (this.validateWord(number, word)) {
                        this.notCorrectDni = true;
                        this.recordId = null;
                        this.showForm = false;
                        this.disabledChange = true;
                        dniTemplate.setCustomValidity('Por favor, escriba la letra correcta.');
                    } else {
                        dniTemplate.setCustomValidity('');
                        this.notCorrectDni = false;
                    }
                }
            } else{
                this.notCorrectDni = true;
                this.recordId = null;
                this.showForm = false;
                this.disabledChange = true;
                dniTemplate.setCustomValidity('El documento no tiene un formato correcto.');
            }
        } else {
            dniTemplate.setCustomValidity('Por favor, escriba un DNI/NIE en el formato correcto.');
            this.disabledChange = true;
            this.recordId = null;
            this.notCorrectDni = true;
            this.showForm = false;
        }
        dniTemplate.reportValidity();
    }

    charIsLetter(char) {
        if (typeof char !== 'string') {
          return false;
        }
        return /^[a-zA-Z]$/.test(char);
    }

    handleGetContactByDni(){
        getContactByDni({dni: this.dni})
            .then((data) => {
                this.loaded = false;
                this.error = null; 
                this.recordId = data.Id;
                this.contactInfo = 'Se encontró un contacto para el DNI/NIE buscado.'
                this.disabledChange = false;
            }).catch((error) => {
                this.contactInfo = 'No existe ningún contacto con el DNI/NIE buscado.'
                this.error = error;
                console.log('ERROR => ', this.error);
                this.loaded = false;
                this.recordId = null;
                this.disabledChange = true;
            });
    }

    searchProgramEngagement(){
        this.handleGetProgramEngagementsByProgramAndContact();
    }

    createProgramEngagement(){
        const fields = {};
        fields[CONTACT_FIELD.fieldApiName] = this.recordId;
        fields[PROGRAM_FIELD.fieldApiName] = this.programId;
        fields[NAME_FIELD.fieldApiName] = 'test';
        this.programEngagement = {apiName: PROGRAM_ENGAGEMENT_OBJECT.objectApiName, fields};
        this.insertProgramEngagement();
    }

    insertProgramEngagement(){
        createRecord(this.programEngagement)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Exito',
                    message: 'Participante creado',
                    variant: 'success'
                })
            );
            this.showList();
        })
        .catch(error => {
            console.log('ERROR => ', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creando el registro',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    } 

    handleGetProgramEngagementsByProgramAndContact(){
        getProgramEngagementsByProgramAndContact({programId: this.programId, contactId: this.recordId})
            .then((data) => {
                if(data.length === 0){
                    this.createProgramEngagement();
                }else{
                    this.showList();
                }
                this.error = undefined; 
            }).catch((error) => {
                this.error = error;
                console.log('ERROR => ', this.error);
            }
        );
    }
}