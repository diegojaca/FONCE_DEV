import { LightningElement, api, track, wire } from 'lwc';
import getFields from '@salesforce/apex/CreateWebSiteRequest.getFields';
import createMemberCampaign from '@salesforce/apex/CreateWebSiteRequest.createMemberCampaign';
import getLeadRecordType from '@salesforce/apex/CreateWebSiteRequest.getLeadRecordType';
import getLeadTypes from '@salesforce/apex/CreateWebSiteRequest.getLeadTypes';
import { NavigationMixin } from 'lightning/navigation';
import getFundingProgram from '@salesforce/apex/CreateWebSiteRequest.getFundingProgram';
import getTermsAndConditions from '@salesforce/apex/CreateWebSiteRequest.getTermsAndConditions';
import PERSON_LEAD_RT from '@salesforce/label/c.PERSON_LEAD_RT';

export default class UniqueLeadFormLwc extends NavigationMixin(LightningElement) {
    @track leadChange = false;
    @track fieldsMap = [];
    errorFields = ['Status','Company', 'University__c', 'OtherUniversity__c', 'BecaDeInteres__c'];
    @track recordTypeId;
    @api recordTypeDeveloperName;
    @api program;
    layoutNameMap = new Map();
    @track isAgree = false;
    @track loaded = false;
    @track university = 'Individuo';
    @track isOther = false;
    @track termsAndConditions;
    type;
    saveButtonDisabled = false;
    requiredFields = ['Address'];

    connectedCallback(){
        this.handleGetLeadRecordType();
        this.handleGetLeadTypes();
    }

    @wire(getFundingProgram, {program:'$program'})
    wiredGetFundingProgram(value) {
        this.wiredFundingProgram = value;
        const { data, error } = value;
        if (data) {
            this.type = data.Tipo_de_Programas_de_Becas__c;               
            this.error = undefined;
            this.handleGetTermsAndConditions();
        } else if (error) {
            this.error = error;
        }
    }

    handleGetTermsAndConditions(){
        getTermsAndConditions ({type:this.type, portalType:'Public'})
            .then((data) => {
                this.termsAndConditions = data.Value__c;         
                this.error = undefined;
            }).catch((error) => {
                this.error = error;
            });
    }

    handleGetLeadRecordType(){
        getLeadRecordType({ developerName: this.recordTypeDeveloperName})
            .then((data) => {
                this.recordTypeId = data.Id;
                this.error = undefined;
            })
            .catch((error) => {
                console.log('error: ',error);
                this.error = error;
                this.recordTypeId = undefined;
            });
    }

    handleGetLeadTypes(){
        getLeadTypes({ developerName: this.recordTypeDeveloperName})
            .then((data) => {
                let i=0;
                for(i; i<data.length; i++)  {
                    this.layoutNameMap.set(data[i].RecordTypeName__c, data[i].LayoutName__c);      
                }                
                this.error = undefined;
                this.getLeadLayout();
            })
            .catch((error) => {
                this.error = error;
            });
    }

    getLeadLayout() {
        this.layoutName = 'Lead-'+this.layoutNameMap.get(this.recordTypeDeveloperName);
        this.handleGetFields();
    }

    handleGetFields(){
        getFields({ layoutName: this.layoutName})
            .then((data) => {
                var fields = data;
                this.error = undefined;
                for(var key in fields){
                    if(!this.errorFields.includes(key) && !this.requiredFields.includes(key)){
                        this.fieldsMap.push({value:fields[key], key:key}); 
                    }
                    if(this.requiredFields.includes(key)){
                        this.fieldsMap.push({value:true, key:key}); 
                    }
                }
            })
            .catch((error) => {
                this.error = error;
                this.fields = undefined;
            });
    }

    handleAgreeClick(){
        this.isAgree = true;
    }

    handleSuccess(event) {
        this.loaded = false;
        this.leadChange = true;
        //Validate if related Lead to campaign
        this.checkLeadToCampaign(event.detail.id);
    }

    /**
    * @description Create Campaign Member record
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-15-2022
    * @param  newLeadId Lead Id
    **/
    checkLeadToCampaign(newLeadId){
        //Check if recordtype is Person and there is Campaign
        if(this.recordTypeDeveloperName === PERSON_LEAD_RT && this.wiredFundingProgram.data.Campaign__c){
            //It´s mecesary use custom apex to create record with guest user
            createMemberCampaign({ leadId: newLeadId, campaignId: this.wiredFundingProgram.data.Campaign__c})
            .then((data) => {
                this.error = undefined;
            })
            .catch((error) => {
                this.error = error;
            });
        }
    }

    handleSubmit(){   
        this.loaded = true;
    }

    handleChangeUniversity(event){
        let university = event.detail.value;
        if(university === 'Otra'){
            this.isOther = true;
        }else{ 
            this.isOther = false;
            this.university = university;
        }
    }
    handleChangeOtherUniversity(event){
        let university = event.detail.value;
        this.university = university;
    }

    navigateToHomePageSite() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/' 
            }
        });
    }

    handleError(event){
        this.loaded = false;
        console.log('error: ',event.detail);
    }

    get isUniversity(){
        return this.recordTypeDeveloperName === 'University';
    }

    validateDoc(doc){
        var regular_expression_doc = /^[xyzXYZ\d]\d{7}[a-zA-Z]$/;
        let dniTemplate = this.template.querySelector(".N_mero_de_Documento__c");

        if(doc.length === 9) {
            if(regular_expression_doc.test(doc) === true) {
                if(!this.charIsLetter(doc.substring(0, 1))){
                    let number;
                    let correctWord;
                    let word;
                    doc = doc.substring(0, doc.length - 1) + doc.substring(doc.length - 1, doc.length).toUpperCase();
                    dniTemplate.value = doc;
                    number = doc.substring(0, doc.length - 1);
                    word = doc.substring(doc.length - 1, doc.length);
                    number = number % 23;
                    correctWord = 'TRWAGMYFPDXBNJZSQVHLCKE';
                    correctWord = correctWord.substring(number, number + 1);
                    if (correctWord != word) {
                        this.saveButtonDisabled = true;
                        alert('Por favor, escriba un DNI con la letra correcta.');
                    } else {
                        this.saveButtonDisabled = false;
                    }
                }else{
                    doc = doc.substring(0, 1).toUpperCase() + doc.substring(1, doc.length - 1) + doc.substring(doc.length - 1, doc.length).toUpperCase();
                    dniTemplate.value = doc;
                    this.saveButtonDisabled = false;
                }
            } else{
                this.saveButtonDisabled = true;
                alert('El documento no tiene un formato correcto.');
            }
        } else {
            this.saveButtonDisabled = true;
        }
    }

    charIsLetter(char) {
        if (typeof char !== 'string') {
          return false;
        }
        return /^[a-zA-Z]$/.test(char);
    }

    handleChangeField(event){
        if(event.currentTarget.dataset.id === 'N_mero_de_Documento__c'){
            this.validateDoc(event.target.value);
        }
    }

}