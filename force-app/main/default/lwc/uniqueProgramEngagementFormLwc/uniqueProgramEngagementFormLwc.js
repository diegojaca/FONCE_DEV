import { api, LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTypesPrograms from '@salesforce/apex/CreateWebSiteRequest.getTypesPrograms';
import getFundingProgram from '@salesforce/apex/CreateWebSiteRequest.getFundingProgram';
import getProgramEngagementRecordTypes from '@salesforce/apex/CreateWebSiteRequest.getProgramEngagementRecordTypes';
import getFields from '@salesforce/apex/CreateWebSiteRequest.getFieldsBySections';

export default class UniqueProgramEngagementFormLwc extends LightningElement {

    @api recordId;
    @api programName;

    @track activeSections = [];
    @track sectionsMap = [];

    type;
    isForUniversityPersons;
    isRequestForPerson;
    error;
    recordTypeDeveloperName;
    recordTypeId;
    layoutName;
    loaded = false;

    errorFields = [];

    recordTypeMap = new Map();
    typeProgramMap = new Map();
    layoutNameMap = new Map();

    connectedCallback(){
        this.handleGetFundingProgram();
    }

    /**
    * @description This method get Funding program Data by Program Name
    * @author diego.jacanamijoy@s4g.es | 15-09-2022
    **/
    handleGetFundingProgram(){
        getFundingProgram ({program: this.programName})
            .then((data) => { 
                this.type = data.Tipo_de_Programas_de_Becas__c;    
                this.isForUniversityPersons = data.NeedPersonLeadInscription__c;
                this.isRequestForPerson = data.IsForPerson__c;
                this.error = undefined;
                this.handleGetTypesPrograms();
            }).catch((error) => {
                this.error = error;
            });
    }

    
    /**
    * @description This method get metadata records of Type
    * @author diego.jacanamijoy@s4g.es | 15-09-2022
    **/
    handleGetTypesPrograms(){
        getTypesPrograms({isForUniversityPersons: this.isForUniversityPersons})
            .then((data) => {
                /** Iterate data to make maps */
                for(let i = 0; i < data.length; i++)  {
                    this.typeProgramMap.set(data[i].TypeValue__c, data[i].RecordTypeName__c);  
                    this.layoutNameMap.set(data[i].RecordTypeName__c, data[i].LayoutName__c);      
                }

                this.error = undefined;
                this.handleGetProgramEngagementRecordTypes();
            }).catch((error) => {
                this.error = error;
            });
    }

    /**
    * @description This method get recordTypes of ProgramEngagement object
    * @author diego.jacanamijoy@s4g.es | 15-09-2022
    **/
    handleGetProgramEngagementRecordTypes(){
        getProgramEngagementRecordTypes()
            .then((data) => {
                /** Iterate data to make maps */
                for(let i = 0; i < data.length; i++)  {
                    this.recordTypeMap.set(data[i].DeveloperName, data[i].Id);        
                }

                this.error = undefined;
                this.getProgramEngagementLayout();
            }).catch((error) => {
                this.error = error;
            });
    }

    /**
    * @description This method get Program engagement layout to search fields
    * @author diego.jacanamijoy@s4g.es | 15-09-2022
    **/
    getProgramEngagementLayout() {
        this.recordTypeDeveloperName = this.typeProgramMap.get(this.type);
        this.recordTypeId = this.recordTypeMap.get(this.recordTypeDeveloperName);
        this.layoutName = 'pmdm__ProgramEngagement__c-' + this.layoutNameMap.get(this.recordTypeDeveloperName);
        this.handleGetFields();
    }

    /**
    * @description This method search fields by layout name
    * @author diego.jacanamijoy@s4g.es | 15-09-2022
    **/
    handleGetFields(){
        getFields({ layoutName: this.layoutName})
            .then((data) => {

                var sections = data;
                this.error = undefined;

                /** Iterate sections by layout */
                for(var section in sections){

                    var fieldsMap = [];
                    for(var field in sections[section]){
                        /** Make field map by section */
                        if(!this.errorFields.includes(field)){
                            fieldsMap.push({value:sections[section][field], key:field}); 
                        }
                    }   

                    this.activeSections.push(section);
                    this.sectionsMap.push({value:fieldsMap, key:section});
                }

            })
            .catch((error) => {
                this.error = error;
                this.sectionsMap = undefined;
            });
    }

    /**
    * @description This method handle the success event
    * @author diego.jacanamijoy@s4g.es | 15-09-2022
    **/
    handleSuccess(event) {

        this.loaded = false;

        this.dispatchEvent(
            new ShowToastEvent({
                message: 'Registro actualizado',
                variant: 'success'
            })
        );
    }

    /**
    * @description This method handle the submit event
    * @author diego.jacanamijoy@s4g.es | 15-09-2022
    **/
    handleSubmit(){
        this.loaded = true;
    }

    /**
    * @description This method handle the error event
    * @author diego.jacanamijoy@s4g.es | 15-09-2022
    **/
    handleError(event) {

        this.loaded = false;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error actualizando',
                message: event.detail,
                variant: 'error'
            })
        );
    }
}