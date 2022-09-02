import { LightningElement, track, api, wire } from 'lwc';
import RESOURCE_OBJECT from '@salesforce/schema/Recurso__c';
import NAME_FIELD from '@salesforce/schema/Recurso__c.Name';
import AMOUNT_FIELD from '@salesforce/schema/Recurso__c.Cantidad__c';
import BUDGETAMOUNT_FIELD from '@salesforce/schema/Recurso__c.Presupuesto__c';
import BUDGETPERCENT_FIELD from '@salesforce/schema/Recurso__c.PorcentajeDelPresupuesto__c';
// import FUNDINGREQUEST_FIELD from '@salesforce/schema/Recurso__c.Funding_Request__c';
import RESOURCETYPE_FIELD from '@salesforce/schema/Recurso__c.TipoDeRecurso__c';
import WORKINGDAY_FIELD from '@salesforce/schema/Recurso__c.Jornada__c';
import saveResources from '@salesforce/apex/CreateWebSiteRequest.saveResources';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getResourcesByFundingRequestId from '@salesforce/apex/CreateWebSiteRequest.getResourcesByFundingRequestId';
import deleteResource from '@salesforce/apex/CreateWebSiteRequest.deleteResource';

export default class DynamicDatatableLwc extends LightningElement {
    @track resourceList = []; 
    @track index = 0;

    @api fundingRequestId;

    @track name = NAME_FIELD;
    @track amount = AMOUNT_FIELD;
    @track budgetAmount = BUDGETAMOUNT_FIELD;
    @track budgetPercent = BUDGETPERCENT_FIELD;

    @track resourceTypePicklist;
    @track workingDayTypePicklist;
    isLoaded = false;
    message;
    error;


    @wire(getObjectInfo, { objectApiName: RESOURCE_OBJECT })
    resourceMetadata;


    @wire(getPicklistValues,{recordTypeId: '$resourceMetadata.data.defaultRecordTypeId', fieldApiName: RESOURCETYPE_FIELD})
    wiredResourceTypePicklist({ error, data }) {
        if (error) {
            this.error = error
        } else if (data) {
            this.resourceTypePicklist = data.values;
        }
    }

    @wire(getPicklistValues,{recordTypeId: '$resourceMetadata.data.defaultRecordTypeId', fieldApiName: WORKINGDAY_FIELD})
    wiredWorkingDayTypePicklist({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.workingDayTypePicklist = data.values;
        }
    }   

    connectedCallback(){
        this.getResources();
    }

    // @wire(getResourcesByFundingRequestId, {fundingRequestId: '$fundingRequestId'})
    // wiredGetResourcesByFundingRequestId({ error, data }) {
    //     if (data) {
    //         this.index = data.length;
    //         for(let i in data){
    //             let resource = {
    //                 Name : data[i].Name,
    //                 Cantidad__c : data[i].Cantidad__c,
    //                 Jornada__c : data[i].Jornada__c,
    //                 Presupuesto__c : data[i].Presupuesto__c,
    //                 PorcentajeDelPresupuesto__c : data[i].PorcentajeDelPresupuesto__c,
    //                 Funding_Request__c : data[i].Funding_Request__c,
    //                 Id : data[i].Id,
    //                 TipoDeRecurso__c: data[i].TipoDeRecurso__c,
    //                 Key: data[i].Id
    //             }
    //             this.resourceList.push(resource);
    //         }
    //         console.log('this.resourceList ',this.resourceList);
    //         this.addRow();
    //     } else if (error) {
    //         console.log('error: ',error);
    //         this.error = error;
    //     }
    // }

    getResources(){
        getResourcesByFundingRequestId( {fundingRequestId: this.fundingRequestId})
            .then(data => {
                this.index = data.length;
                for(let i in data){
                    let resource = {
                        Name : data[i].Name,
                        Cantidad__c : data[i].Cantidad__c,
                        Jornada__c : data[i].Jornada__c,
                        Presupuesto__c : data[i].Presupuesto__c,
                        PorcentajeDelPresupuesto__c : data[i].PorcentajeDelPresupuesto__c,
                        Funding_Request__c : data[i].Funding_Request__c,
                        Id : data[i].Id,
                        TipoDeRecurso__c: data[i].TipoDeRecurso__c,
                        Key: data[i].Id,
                        Index: parseInt(i) + 1
                    }
                    this.resourceList.push(resource);
                }
                this.addRow();
            })
            .catch(error => {
                this.error = error;
                console.log('error: ',error);
            });
    }

    addRow(){
        let resource = {
            Name : '',
            Cantidad__c : 1,
            Jornada__c : '',
            Presupuesto__c : 1,
            PorcentajeDelPresupuesto__c : 1,
            Funding_Request__c : '',
            TipoDeRecurso__c: '',
            Key: '',
            Index: 0
        }
        this.index++;
        var i = this.index;
        resource.Key = i;
        resource.Name = 'Recurso '+i;
        resource.Funding_Request__c = this.fundingRequestId;
        resource.Index = this.index;
        this.resourceList.push(JSON.parse(JSON.stringify(resource)));
    }
    
    removeRow(event){

        this.isLoaded = true;
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        if(this.resourceList[key].Id && this.resourceList[key].Id.length === 18){
            this.removeRecord(this.resourceList[key].Id);
        }
        if(this.resourceList.length>1){
            this.resourceList.splice(key, 1);
            this.index--;
            this.isLoaded = false;
        }else if(this.resourceList.length == 1){
            this.resourceList = [];
            this.index = 0;
            this.isLoaded = false;
            this.addRow();
        }
    } 

    removeRecord(resourceId){    
        deleteResource({resourceId : resourceId})
        
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Borrado completado!',
                        variant: 'success',
                    }),
                );
            })
            .catch(error => {
                console.log('error: ',error.body.message);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });
    }

    handleNameChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        this.resourceList[key].Name = event.target.value;
    }
    
    handleAmountChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        this.resourceList[key].Cantidad__c = event.target.value;
    }

    handleWorkDayTypeChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        this.resourceList[key].Jornada__c = event.target.value;
    }

    handleBudgetAmountChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        this.resourceList[key].Presupuesto__c = event.target.value;
    }
    
    handleBudgetPercentChange(event) {
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        this.resourceList[key].PorcentajeDelPresupuesto__c = event.target.value;
    }

    handleResourceTypeChange(event){
        var selectedRow = event.currentTarget;
        var key = selectedRow.dataset.id;
        this.resourceList[key].TipoDeRecurso__c = event.target.value;
    }

    handleNext(){
        this.resourceList = this.resourceList.filter(element => { return element.TipoDeRecurso__c != ''})
        if(this.resourceList.length>0){
            this.saveRecord();
        }else{
            const selectedEvent = new CustomEvent('next');
            this.dispatchEvent(selectedEvent);
        }
        
    }

    saveRecord(){     
        saveResources({resources : this.resourceList})
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Recursos guardados!',
                        variant: 'success',
                    }),
                );
                
                
                const selectedEvent = new CustomEvent('next');
                this.dispatchEvent(selectedEvent);
            })
            .catch(error => {
                console.log('error: ',error.body.message);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });
    }
      
}