import {LightningElement,api,track,wire} from 'lwc';
import getFundingProgram from '@salesforce/apex/CreateWebSiteRequest.getFundingProgram';
import getFundingRequestRecordTypes from '@salesforce/apex/CreateWebSiteRequest.getFundingRequestRecordTypes';
import getTypesPrograms from '@salesforce/apex/CreateWebSiteRequest.getTypesPrograms';
import getFields from '@salesforce/apex/CreateWebSiteRequest.getFieldsBySections';
import getUniversities from '@salesforce/apex/CreateWebSiteRequest.getUniversities';
import PROGRAM_TYPE_CRUE from '@salesforce/label/c.PROGRAM_TYPE_CRUE';
import UNIVERSITY_COMBO_LABEL from '@salesforce/label/c.UNIVERSITY_COMBO_LABEL';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UniqueFundingRequestFormLwc extends LightningElement{

    @api program;
    @api accountId
    @api contactId; 
    @track fundingProgramId;
    wiredFundingProgram;
    @track type;
    @track description;
    @track isAgree = false;
    @api fundingRequestId;
    recordTypeMap = new Map();
    typeProgramMap = new Map();
    layoutNameMap = new Map();
    @track sectionsMap = [];
    @track recordTypeId;
    recordTypeDeveloperName;
    layoutName;
    errorFields = ["Name","outfunds__Applying_Contact__c","outfunds__FundingProgram__c","RecordTypeId", "ConsentimientoCesionDatosPersonales__c"];
    wiredFundingRequestRecordTypes;
    wiredTypesPrograms;
    @track activeSections = [];
    @track accountOptions = [];
    @track loaded = false;
    @track personalInfoSection = false;
    // @track disabledSaveButton = true;
    fundingrequestchange = false;
    isForUniversityPersons = false;
    isRequestForPerson = false;
    showUniversityOpt = false;
    UNIVERSITY_COMBO_LABEL = UNIVERSITY_COMBO_LABEL;

    connectedCallback(){
        //Decode program name DAJC 07/07/2022
        this.program = decodeURIComponent(this.program);
        this.handleGetFundingProgram();
    }

    /**
    * @description Check if show University combobox field
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 07/07/2022
    **/
    checkShowUniversityOptions(){
        this.showUniversityOpt = (this.type === PROGRAM_TYPE_CRUE && this.isRequestForPerson === true);
    }

    handleAgreeClick(){
        this.isAgree = true;
        this.getFundingProgramLayout();
    }

    @wire(getUniversities)
    wiredGetUniversities({error, data}){
        if (data) {
            data.forEach(account => {
                const option = {
                    label: account.Name,
                    value: account.Id
                };
                this.accountOptions = [...this.accountOptions, option];
            });
        } else if (error) {
            this.accountOptions = [];
        }
    }

    /**
    * @description Handle Account combobox change
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 07/07/2022
    * @param event
    **/
    handleAccountChange(event){
        this.accountId = event.detail.value;
    }

    handleSuccess(event) {
        this.loaded = false;
        this.fundingRequestId = event.detail.id;
        const selectedEvent = new CustomEvent("fundingrequestidchange", {
            detail: this.fundingRequestId   
        })
        this.dispatchEvent(selectedEvent);
        if(this.fundingrequestchange){
            this.handleFundingRequestChange();
        }
        const evt = new ShowToastEvent({
            title: '¡Éxito!',
            message: 'Su solicitud se ha guardado correctamente.',
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    /**
    * @description Validate required fields
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 07/07/2022
    **/
    validateRequiredFields(){
        let fieldsValid = true;
        //Validate required Account combobox
        this.template.querySelectorAll('lightning-combobox').forEach(element => {
            element.reportValidity();
            if (!element.reportValidity()) {
                fieldsValid = false;
            }
        });

        return fieldsValid;
    }

    handleSubmit(event){
        //Prevent standard submit
        event.preventDefault();
        //Chech required fields
        if(this.validateRequiredFields()){
            this.loaded = true;
            this.template.querySelector('lightning-record-edit-form').submit();
        }
    }

    handleError(event) {
        console.error('event error: ', JSON.stringify(event, undefined, 2));
        this.loaded = false;
    }

    handleGetFundingProgram(){
        getFundingProgram ({program:this.program})
            .then((data) => {
                this.fundingProgramId = data.Id;  
                this.type = data.Tipo_de_Programas_de_Becas__c;    
                this.description = data.outfunds__Description__c;   
                this.isForUniversityPersons = data.NeedPersonLeadInscription__c;
                this.isRequestForPerson = data.IsForPerson__c;
                this.error = undefined;
                this.checkShowUniversityOptions();
                this.handleGetTypesPrograms();
            }).catch((error) => {
                this.error = error;
            });
    }

    // controlar el parametro de entrada
    handleGetTypesPrograms(){
        getTypesPrograms({isForUniversityPersons: this.isForUniversityPersons})
            .then((data) => {
                let i=0;
                for(i; i<data.length; i++)  {
                    this.typeProgramMap.set(data[i].TypeValue__c, data[i].RecordTypeName__c);  
                    this.layoutNameMap.set(data[i].RecordTypeName__c, data[i].LayoutName__c);      
                }           
                this.error = undefined;
                this.handleGetFundingRequestRecordTypes();
            }).catch((error) => {
                this.error = error;
            });
    }

    handleGetFundingRequestRecordTypes(){
        getFundingRequestRecordTypes()
            .then((data) => {
                let i=0;
                for(i; i<data.length; i++)  {
                    this.recordTypeMap.set(data[i].DeveloperName, data[i].Id);        
                }             
                this.error = undefined;
                this.getFundingProgramLayout();
            }).catch((error) => {
                this.error = error;
            });
    }

    getFundingProgramLayout() {
        this.recordTypeDeveloperName = this.typeProgramMap.get(this.type);
        this.recordTypeId = this.recordTypeMap.get(this.recordTypeDeveloperName);
        this.layoutName = 'outfunds__Funding_Request__c-'+this.layoutNameMap.get(this.recordTypeDeveloperName);
        this.handleGetFields();
    }

    handleGetFields(){
        getFields({ layoutName: this.layoutName})
            .then((data) => {
                var sections = data;
                this.error = undefined;
                for(var section in sections){
                    var fieldsMap = [];
                    for(var field in sections[section]){
                        if(!this.errorFields.includes(field)){
                            fieldsMap.push({value:sections[section][field], key:field}); 
                        }
                    }   
                    this.activeSections.push(section);
                    this.sectionsMap.push({value:fieldsMap, key:section});
                }
                this.activeSections.push('Consentimiento de Datos Personales');
                this.personalInfoSection = true;

            })
            .catch((error) => {
                this.error = error;
                this.sectionsMap = undefined;
            });
    }

    handleNext(){
        this.fundingrequestchange = true;
    }

    handleFundingRequestChange(){
        const selectedEvent = new CustomEvent("fundingrequestchange", {
            detail: this.fundingRequestId   
        })
        this.dispatchEvent(selectedEvent);
    }

}