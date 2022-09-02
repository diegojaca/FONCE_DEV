import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import STATUS_FIELD from '@salesforce/schema/outfunds__Funding_Request__c.outfunds__Status__c';
import ID_FIELD from '@salesforce/schema/outfunds__Funding_Request__c.Id';
import SUBMITTEDDATE_FIELD from '@salesforce/schema/outfunds__Funding_Request__c.SubmittedDate__c';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFundingProgram from '@salesforce/apex/CreateWebSiteRequest.getFundingProgram';
import getTermsAndConditions from '@salesforce/apex/CreateWebSiteRequest.getTermsAndConditions';

export default class UniqueRegistrationProgressLwc extends NavigationMixin(LightningElement) {
    @track step = '1';
    @api contactId;
    @track accountId;
    @api fundingRequestId; 
    @api program;
    @track exit = false;
    @track exit = false;
    @track disabledExit = true;
    @api isUniversity;
    @api needResources;
    @api needRequirements;
    fundingRequestRecord;
    @api notNeedFundingRequestForm;
    type;
    wiredFundingProgram;
    @track termsAndConditions;
    @track isAgree = false;

    showStep1 = true;
    showStep2 = true;
    showStep3 = true;
    showStep4 = true;
    showStep5 = true;

    step1Completed = false;
    step2Completed = false;
    step3Completed = false;
    step4Completed = false;
    step5Completed = false;

    isFirstRender = true;

    connectedCallback() {
        //Decode program name DAJC 07/07/2022
        this.program = decodeURIComponent(this.program);
        this._handleResize = this.handleResize.bind(this);
        window.addEventListener('resize', this._handleResize);
        this.handleGetFundingProgram();
    }

    renderedCallback(){
        if(this.isFirstRender){
            this.managePathView(); 
            this.isFirstRender = false; 
        }
    }

    handleResize() {
        this.managePathView(); 
    }

    handleGetFundingProgram(){
        getFundingProgram({program:this.program})
            .then((data) => {
                this.type = data.Tipo_de_Programas_de_Becas__c;               
                this.error = undefined;
                this.handleGetTermsAndConditions();
            }).catch((error) => {
                this.error = error;
            });
    }

    handleGetTermsAndConditions(){
        getTermsAndConditions ({type:this.type, portalType:'Private'})
            .then((data) => {
                this.termsAndConditions = data.Value__c;         
                this.error = undefined;
            }).catch((error) => {
                this.error = error;
            });
    }
    
    handleContactChange(){
        this.step = '2';
        this.step1Completed = true;
        this.managePathView();
        if(!this.notNeedFundingRequestForm){
            this.step = '2';
            this.managePathView();
        }else{
            if(this.needResources === true){
                this.step = '3';
                this.managePathView();
            }else if(this.needRequirements === true){
                this.step = '4';
                this.managePathView();
            }
        }
    }

    handleAccountIdChange(event){
        this.accountId = event.detail;
    }

    handleAccountChange() {
        this.step = '2';
        this.step1Completed = true;
        this.managePathView();
    }

    handleFundingRequestIdChange(event) {
        this.fundingRequestId = event.detail;
    }

    handleFundingRequestChange() {
        this.step2Completed = true;
        if(this.needResources === true){
            this.step = '3';
            this.managePathView();
        }else if (this.needRequirements === true){
            this.step = '4';
            this.managePathView();
        }
    }

    handleContinue(){
        this.step = '5';
        this.managePathView();
    }

    handleRequirementsEmpty() {
        this.exit = true;
        this.step4Completed = true;
        this.step = '5';
        this.managePathView();
    }

    handleRequiredRequirementsEmpty() {
        this.disabledExit = false;
    }

    handleOnNextResources(){
        this.step = '4';
        this.step3Completed = true;
        this.managePathView();
    }

    exitForm(){
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.fundingRequestId;
        fields[STATUS_FIELD.fieldApiName] = 'En Trámite de Valoración';
        fields[SUBMITTEDDATE_FIELD.fieldApiName] = new Date().toISOString();
        this.fundingRequestRecord = { fields };
        this.updateFundingRequest();
        this.navigateToHomePage();
    }

    navigateToHomePage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/'
            }
        });
    }

    selectStep1() {
        this.step = '1';
        this.managePathView();
    }
 
    selectStep2() {
        this.step = '2';
        this.managePathView();
    }
 
    selectStep3() {
        this.step = '3';
        this.managePathView();
    }

    selectStep4() {
        this.step = '4';
        this.managePathView();
    }

    selectStep5() {
        this.step = '5';
        this.managePathView();
    }

    get isSelectStep1() {
        if(this.step === "1"){
            return "displayBlock"
        }else{
            return "displayNone"
        }
    }

    get isSelectStep2() {
        if(this.step === "2"){
            return "displayBlock"
        }else{
            return "displayNone"
        }
    }

    get isSelectStep3() {
        if(this.step === "3"){
            return "displayBlock"
        }else{
            return "displayNone"
        }
    }

    get isSelectStep4() {
        if(this.step === "4"){
            return "displayBlock"
        }else{
            return "displayNone"
        }
    }

    get isSelectStep5() {
        if(this.step === "5"){
            return "displayBlock"
        }else{
            return "displayNone"
        }
    }

    get programName() {
        return this.program;
    }

    updateFundingRequest(){
        updateRecord(this.fundingRequestRecord)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Presentada',
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating record',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    }    
    
    handleAgreeClick(){
        this.isAgree = true;
    }

    get isAgreeCondition(){
        if(this.fundingRequestId === undefined){
            return this.isAgree;
        }else{
            return true;
        }
    }

    managePathView(){
        //Decides which screen we are into and accordingly renders the path.
        let width = this.template.querySelector('.datatableSize').offsetWidth;

        let mobile = width<576;
        let tab = (576<width)&&(width<900);

        if (mobile || tab) {
            switch(this.step){
                case '1':
                    this.step1();
                    break;
                case '2':
                    this.step2();
                    break;
                case '3':
                    this.step3();
                    break;
                case '4':
                    this.step4();
                    break;
                case '5':
                    this.step5();
                    break;
            }
        }
        else{
            this.showStep1 = true;
            this.showStep2 = true;
            this.showStep3 = true;
            this.showStep4 = true;
            this.showStep5 = true;
        }
    }

    step1(){

        this.showStep1 = true;
        this.showStep2 = true;
        this.showStep3 = true;
        this.showStep4 = false;
        this.showStep5 = false;
    }

    step2(){

        this.showStep1 = true;
        this.showStep2 = true;
        this.showStep3 = true;
        this.showStep4 = false;
        this.showStep5 = false;
    }

    step3(){

        this.showStep1 = false;
        this.showStep2 = true;
        this.showStep3 = true;
        this.showStep4 = true;
        this.showStep5 = false;
    }

    step4(){

        this.showStep1 = false;
        this.showStep2 = false;
        this.showStep3 = true;
        this.showStep4 = true;
        this.showStep5 = true;
    }

    step5(){

        this.showStep1 = false;
        this.showStep2 = false;
        this.showStep3 = false;
        this.showStep4 = true;
        this.showStep5 = true;
    }

    step6(){

        this.showStep1 = false;
        this.showStep2 = false;
        this.showStep3 = false;
        this.showStep4 = false;
        this.showStep5 = true;
    }

    step7(){
        
        this.showStep1 = false;
        this.showStep2 = false;
        this.showStep3 = false;
        this.showStep4 = false;
        this.showStep5 = true;
    }


    get ariaLabel1(){
        if(this.step === '1' && !this.step1Completed){
            return 'Paso actual información solicitante';
        }
        else if(this.step1Completed){
            return 'Paso información solicitante realizado';
        }else{
            return null;
        }
    }

    get ariaLabel2(){
        if(this.step === '2' && !this.step2Completed){
            return 'Paso actual información solicitud';
        }
        else if(this.step2Completed){
            return 'Paso información solicitud realizado';
        }else{
            return null;
        }
    }

    get ariaLabel3(){
        if(this.step === '3' && !this.step3Completed){
            return 'Paso actual listado de recursos';
        }
        else if(this.step3Completed){
            return 'Paso listado de recursos realizado';
        }else{
            return null;
        }
    }

    get ariaLabel4(){
        if(this.step === '4' && !this.step4Completed){
            return 'Paso actual listado de requisitos';
        }
        else if(this.step4Completed){
            return 'Paso listado de requisitos realizado';
        }else{
            return null;
        }
    }

    get ariaLabel5(){
        if(this.step === '5'){
            return 'Paso actual fin de formulario';
        }
    }

    get ariaCurrent1(){
        if(this.step === '1'){
            return true;
        }else{
            return false;
        }
    }

    get ariaCurrent2(){
        if(this.step === '2'){
            return true;
        }else{
            return false;
        }
    }

    get ariaCurrent3(){
        if(this.step === '3'){
            return true;
        }else{
            return false;
        }
    }

    get ariaCurrent4(){
        if(this.step === '4'){
            return true;
        }else{
            return false;
        }
    }

    get ariaCurrent5(){
        if(this.step === '5'){
            return true;
        }else{
            return false;
        }
    }

}