import { LightningElement, track, wire } from 'lwc';
import getFundingRequestsByOwner from '@salesforce/apex/CreateWebSiteRequest.getFundingRequestsByOwner';
import getFundingRequestsByParents from '@salesforce/apex/CreateWebSiteRequest.getFundingRequestsByParents';
import userId from '@salesforce/user/Id';
import getFundingRequest from '@salesforce/apex/CreateWebSiteRequest.getFundingRequest';
// import saveFundingRequest from '@salesforce/apex/CreateWebSiteRequest.saveFundingRequest';
import FUNDING_REQUEST_FIELD from '@salesforce/schema/outfunds__Funding_Request__c.Funding_Request__c';
import FUNDING_PROGRAM_FIELD from '@salesforce/schema/outfunds__Funding_Request__c.outfunds__FundingProgram__c';
import CONTACT_FIELD from '@salesforce/schema/outfunds__Funding_Request__c.outfunds__Applying_Contact__c';
import RECORD_TYPE_FIELD from '@salesforce/schema/outfunds__Funding_Request__c.RecordTypeId';
import ORGANIZATION_FIELD from '@salesforce/schema/outfunds__Funding_Request__c.outfunds__Applying_Organization__c';
import NAME_FIELD from '@salesforce/schema/outfunds__Funding_Request__c.Name';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTypesPrograms from '@salesforce/apex/CreateWebSiteRequest.getTypesPrograms';
import getFundingRequestRecordTypes from '@salesforce/apex/CreateWebSiteRequest.getFundingRequestRecordTypes';
import getChildFundingPrograms from '@salesforce/apex/CreateWebSiteRequest.getChildFundingPrograms';

import FUNDING_REQUEST_OBJECT from '@salesforce/schema/outfunds__Funding_Request__c';

export default class FundingRequestManagerLwc extends LightningElement {
    userId = userId;
    @track fundingRequests;
    parentsFundingRequests;
    parentsFundingRequestIds = [];
    isLoaded = false;
    @track listComp = true;
    @track listForm = false;
    @track listContForm = false;
    @track fundingRequestId;
    fundingRequest;
    contactId;
    program;
    needResources = false;
    needRequirements = false;
    typeOptionSet = new Set();
    parentsFundingRequestMap = new Map();
    @track programType;
    typeOptions = [];
    typeProgramMap = new Map();
    contactLayoutNameMap = new Map();
    wiredTypesPrograms;
    recordTypeMap = new Map();
    @track contactLayoutName;
    childFundingProgramsMap = new Map();
    wiredChildFundingPrograms;

    @wire(getChildFundingPrograms)
    wiredGetChildFundingPrograms(value) {
        this.wiredChildFundingPrograms = value;
        const { data, error } = value;
        if (data) {
            this.error = undefined;
            for(let i in data){
                this.childFundingProgramsMap.set(data[i].Tipo_de_Programas_de_Becas__c, data[i]);   
            }
        } else if (error) {
            this.error = error;
            this.childFundingProgramsMap = undefined;
        }
    }

    // @wire(getFundingRequestsByOwner, {userId:'$userId'})
    // wiredGetFundingRequestsByOwner(value) {
    //     this.wiredParentsFundingRequests = value;
    //     const { data, error } = value;
    //     if (data) {
    //         this.parentsFundingRequests = data;
    //         this.error = undefined;
    //         for(let parent in data){
    //             this.parentsFundingRequestIds.push(data[parent].Id);
    //             this.typeOptionSet.add(data[parent].outfunds__FundingProgram__r.Tipo_de_Programas_de_Becas__c);
    //             this.parentsFundingRequestMap.set(data[parent].outfunds__FundingProgram__r.Tipo_de_Programas_de_Becas__c, data[parent]);   
    //         }
    //         this.typeOptionSet.forEach(key => this.typeOptions.push({ label: key, value: key }));
    //         this.handleGetFundingProgramsByParents();
    //     } else if (error) {
    //         this.error = error;
    //         this.parentsFundingRequests = undefined;
    //     }
    // }

    connectedCallback(){
        this.handleGetFundingRequestsByOwner();
    }

    handleGetFundingRequestsByOwner(){
        getFundingRequestsByOwner({userId: this.userId})
            .then((data) => {
                this.parentsFundingRequests = data;
                this.error = undefined;
                for(let parent in data){
                    this.parentsFundingRequestIds.push(data[parent].Id);
                    this.typeOptionSet.add(data[parent].outfunds__FundingProgram__r.Tipo_de_Programas_de_Becas__c);
                    this.parentsFundingRequestMap.set(data[parent].outfunds__FundingProgram__r.Tipo_de_Programas_de_Becas__c, data[parent]);   
                }
                this.typeOptionSet.forEach(key => this.typeOptions.push({ label: key, value: key }));
                console.log('this-> ',this.parentsFundingRequests);
                this.handleGetFundingProgramsByParents();  
            }).catch((error) => {
                this.error = error;
                this.parentsFundingRequests = undefined;
            });
    }

    handleGetFundingProgramsByParents(){
        getFundingRequestsByParents ({parentIds: this.parentsFundingRequestIds})
            .then((data) => {
                this.fundingRequests = data;  
                this.error = undefined;  
            }).catch((error) => {
                this.error = error;
            });
    }

    @wire(getTypesPrograms, {isForUniversityPersons:true})
    wiredGetTypesPrograms(value) {
        this.wiredTypesPrograms = value;
        const { data, error } = value;
        if (data) {
            let i=0;
            for(i; i<data.length; i++)  {
                this.typeProgramMap.set(data[i].TypeValue__c, data[i].RecordTypeName__c);  
                this.contactLayoutNameMap.set(data[i].TypeValue__c, data[i].ContactLayoutName__c);      
            }                
            this.error = undefined;
            this.handleGetFundingRequestRecordTypes();
        } else if (error) {
            this.error = error;
        }
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

    handleTypeOptionsChange(event){
        this.contactLayoutName = undefined;
        this.programType = event.detail.value;
        this.contactLayoutName = this.contactLayoutNameMap.get(this.programType);
    }

    addRow(){
        this.listComp = false;
        this.listForm = false;
        this.listContForm = true;
        //action que reirge al componenete
    }
    
    updateRow(event){
        this.fundingRequestId = this.fundingRequests[event.target.dataset.index].Id;
        this.handleGetFundingRequest();
        this.listComp = false;
        this.listForm = true;
        this.listContForm = false;
        //accion que redirige al componente de modificar
    } 
    previousFromForm(){
        this.listComp = true;
        this.listForm = false;
        this.listContForm = false;
    }
    
    handleGetFundingRequest(){
        getFundingRequest ( { fundingRequestId: this.fundingRequestId})
            .then((data) => {
                this.program = data.outfunds__FundingProgram__r.Nombre_Convocatoria__c;
                this.needResources = data.outfunds__FundingProgram__r.NeedResources__c;
                this.needRequirements = data.outfunds__FundingProgram__r.NeedRequirementsInRequest__c;
                this.contactId = data.outfunds__Applying_Contact__c;
            }).catch((error) => {
                this.error = error;
            }
        );
    }

    handleContactCreate(event){
        const fields = {};
        fields[FUNDING_REQUEST_FIELD.fieldApiName] = this.parentsFundingRequestMap.get(this.programType).Id;
        fields[FUNDING_PROGRAM_FIELD.fieldApiName] = this.childFundingProgramsMap.get(this.programType).Id;
        fields[CONTACT_FIELD.fieldApiName] = event.detail;
        fields[RECORD_TYPE_FIELD.fieldApiName] = this.recordTypeMap.get(this.typeProgramMap.get(this.programType));
        fields[ORGANIZATION_FIELD.fieldApiName] = this.parentsFundingRequestMap.get(this.programType).outfunds__Applying_Organization__c;
        fields[NAME_FIELD.fieldApiName] = 'test';
        this.fundingRequest = {apiName: FUNDING_REQUEST_OBJECT.objectApiName, fields};
        this.insertFundingRequest();
    }

    insertFundingRequest(){
        createRecord(this.fundingRequest)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Exito',
                    message: 'Beneficiario creado',
                    variant: 'success'
                })
            );
            this.typeOptionSet.clear();
            this.typeOptions = [];
            this.programType = undefined;
            this.contactLayoutName = undefined;
            this.handleGetFundingRequestsByOwner();
            this.previousFromForm();
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creando el registro',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    } 
}