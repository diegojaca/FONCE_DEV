/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 08-19-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
global with sharing class AwardFundingRequestWorker extends AbstractWorker {
    
    private Map<String, pmdm__Program__c> programByFundingRequestId = new Map<String, pmdm__Program__c>();
    private Map<String, List<Objective__c>> objectivesByFundingRequestId = new Map<String, List<Objective__c>>();
    private Map<String, List<outfunds__Requirement__c>> requirementsByFundingProgramId = new Map<String, List<outfunds__Requirement__c>>();
    private Map<String, outfunds__Disbursement__c> disbursByProgrAndRequest = new Map<String, outfunds__Disbursement__c>();
    private Map<String, outfunds__Funding_Request__c> fundRequestByProgram = new Map<String, outfunds__Funding_Request__c>();
    private List<pmdm__ProgramEngagement__c> programEngmToInsert = new List<pmdm__ProgramEngagement__c>();
    private List<SObject> recordsToInsertAfter = new List<SObject>();
    private static String crueProyectId; 
    private static List<String> crueRequestRecordTypes = new List<String>();

    public AwardFundingRequestWorker() {
        super(String.valueOf(AwardFundingRequestWorker.class));
    }

    public override void bulkAfterUpdate(List<SObject> oldRecords, List<SObject> newRecords){
        Set<String> fundingProgramIds = new Set<String>();
        for(outfunds__Funding_Request__c newFundingRequest : (List<outfunds__Funding_Request__c>) newRecords){
            if(String.IsNotBlank(newFundingRequest.outfunds__FundingProgram__c) && !this.isCRUEIndividualRequest(newFundingRequest)){
                fundingProgramIds.add(newFundingRequest.outfunds__FundingProgram__c);
                this.fundRequestByProgram.put(newFundingRequest.outfunds__FundingProgram__c, newFundingRequest);
            }
        }
        this.getRequirements(fundingProgramIds);
        this.getObjectives(newRecords);
        this.createDisbursementsByProgram(fundingProgramIds);
	}

    public override void beforeUpdate(SObject oldSo, SObject so){
        if (String.isNotBlank(((outfunds__Funding_Request__c) so).outfunds__Status__c)
                && ((outfunds__Funding_Request__c) so).outfunds__Status__c.equals(CONSTANTS.FUNDING_REQUEST_STATUS_AWARDED) 
                && S4GUtils.isChanged(so, oldSo, String.valueOf(outfunds__Funding_Request__c.outfunds__Status__c))
                && String.IsBlank(((outfunds__Funding_Request__c) so).Program__c)) {

            //Check if th request is CRUE and from individual, to related proyect
            if(this.isCRUEIndividualRequest((outfunds__Funding_Request__c) so)){
                so.put('Program__c', this.getProyectForUniversityCRUERequest());
                this.createProgramEngagement((outfunds__Funding_Request__c) so);
            }else{
                this.programByFundingRequestId.put(((outfunds__Funding_Request__c) so).Id, createProgram(((outfunds__Funding_Request__c) so)));
            }
        }
    }
    
    public override void andFinallyBefore(){

        if(this.programByFundingRequestId.values().size() == 0){
            return;
        }

        List<pmdm__Program__c> programs = this.programByFundingRequestId.values();

        Database.SaveResult[] insertPrograms = Database.insert(programs, false);

        for(Integer i = 0; i < insertPrograms.size(); i++){
            for(String fundingRequestId : this.programByFundingRequestId.keySet()){
                if(insertPrograms[i].isSuccess() && this.programByFundingRequestId.get(fundingRequestId).Id.equals(insertPrograms[i].getId())){
                    ((outfunds__Funding_Request__c)super.newRecordsMap.get(fundingRequestId)).Program__c = this.programByFundingRequestId.get(fundingRequestId).Id;
                }
            }
            if(!insertPrograms[i].isSuccess()){
                programs[i].addError('Error al crear el proyecto.');
            }
        }
    }

    public override void andFinallyAfter(){
        
        for(outfunds__Funding_Request__c fundingRequest : (List<outfunds__Funding_Request__c>)super.newRecordsMap.values()){
            if(String.IsNotBlank(fundingRequest.Program__c) 
                && super.oldRecordsMap.containsKey(fundingRequest.Id)
                && fundingRequest.outfunds__Status__c.equals(CONSTANTS.FUNDING_REQUEST_STATUS_AWARDED) 
                && S4GUtils.isChanged(fundingRequest, (outfunds__Funding_Request__c)super.oldRecordsMap.get(fundingRequest.Id), String.valueOf(outfunds__Funding_Request__c.outfunds__Status__c))
                && !this.isCRUEIndividualRequest(fundingRequest)){
                this.createDisbursements();
                this.cloneObjectives(fundingRequest);
                this.createProgramEngagement(fundingRequest);
                this.cloneRequirements(fundingRequest);
            }
        }

        //Sort list by SObject
        this.recordsToInsertAfter.sort();

        //Insert all records
        Database.SaveResult[] insertRecords = Database.insert(this.recordsToInsertAfter, false);

        for(Integer i = 0; i < insertRecords.size(); i++){
            if(!insertRecords[i].isSuccess()){
                this.recordsToInsertAfter[i].addError('Error al crear ' + S4GUtils.getSObjectLabelById(insertRecords[i].getId()));
            }
        }
        
        this.insertProgramEngm();
    }

    /**
    * @description Method to insert Disbursemen records
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-28-2022 
    **/
    private void createDisbursements(){

        //Check records to insert
        if(!this.disbursByProgrAndRequest.values().isEmpty()){

            //This record is created beside, because his Ids are necesary to update outfunds__Requirement__c records 
            WorkersManager.avoidAllWorkersExecution(true);
            outfunds__Disbursement__c[] auxToInsert = new List<outfunds__Disbursement__c>(new Set<outfunds__Disbursement__c>(this.disbursByProgrAndRequest.values()));
            Database.SaveResult[] insertDisbursements = Database.insert(auxToInsert, false);
            WorkersManager.avoidAllWorkersExecution(false);

            for(Integer i = 0; i < insertDisbursements.size(); i++){
                if(!insertDisbursements[i].isSuccess()){
                    auxToInsert[i].addError('Error al crear el Pago.');
                }
            } 
        }
    }

    /**
    * @description Methos to insert program engagement records
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 07-04-2022 
    **/
    private void insertProgramEngm(){

        //Check records to insert
        if(!this.programEngmToInsert.isEmpty()){

            //This record is created beside, because it´s necesary Service records created
            Database.SaveResult[] resultprogramEngmToInsert = Database.insert(this.programEngmToInsert, false);

            for(Integer i = 0; i < resultprogramEngmToInsert.size(); i++){
                if(!resultprogramEngmToInsert[i].isSuccess()){
                    for (Database.Error err : resultprogramEngmToInsert[i].getErrors()) {
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                    this.programEngmToInsert[i].addError('Error al crear el Program Engamenet.');
                }
            } 
        }
    }

    /**
    * @description create a new Program
    * @param fundingRequest modified funding request record
    */
    private pmdm__Program__c createProgram(outfunds__Funding_Request__c fundingRequest){
        return new pmdm__Program__c(
            Name = fundingRequest.Name,
            pmdm__Status__c = 'Active',
            OwnerId = fundingRequest.OwnerId,
            Account__c = fundingRequest.outfunds__Applying_Organization__c, 
            pmdm__EndDate__c = fundingRequest.EndProjectDate__c,
            pmdm__StartDate__c = Date.Today(),
            EndProgressDate__c = fundingRequest.EndProgressDate__c,
            EndLoadStudentDate__c = fundingRequest.EndLoadStudentDate__c,
            Origin_Funding_Request__c = fundingRequest.Id
        );
    }
    /**
    * @description search a funding requests´s objectives
    * @param fundingRequests modified funding request records
    */
    private void getObjectives(List<outfunds__Funding_Request__c> fundingRequests){
        for(Objective__c objective : [SELECT Id, Name, Funding_Request__c, OwnerId FROM Objective__c WHERE Funding_Request__c IN :fundingRequests]){
            if(!this.objectivesByFundingRequestId.containsKey(objective.Funding_Request__c)){
                this.objectivesByFundingRequestId.put(objective.Funding_Request__c, new List<Objective__c>());
            }
            this.objectivesByFundingRequestId.get(objective.Funding_Request__c).add(objective);
        }
    }
    /**
    * @description search a funding programs´s requirements
    * @param fundingProgramIds modified funding request´s funding program ids
    */
    private void getRequirements(Set<String> fundingProgramIds){
        for(outfunds__Requirement__c requirement : [
                SELECT Id, Name, outfunds__Type__c, outfunds__Status__c, IsRequired__c, Funding_Program__c, OwnerId
                FROM outfunds__Requirement__c
                WHERE Funding_Program__c IN :fundingProgramIds
                AND Objective__c = NULL
                AND RequirementCategory__c = :CONSTANTS.REQUIREMENT_CATEGORY_PROJECT_REQUIREMENT
        ]){
            if(!this.requirementsByFundingProgramId.containsKey(requirement.Funding_Program__c)){
                this.requirementsByFundingProgramId.put(requirement.Funding_Program__c, new List<outfunds__Requirement__c>());
            }
            this.requirementsByFundingProgramId.get(requirement.Funding_Program__c).add(requirement);
        }
    }

    /**
    * @description Create Disbursement records by PaymentSetting
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-22-2022 
    * @param fundingProgramIds Ids of funding programs
    **/
    private void createDisbursementsByProgram(Set<String> fundingProgramIds){

        for(PaymentSettings__c paymentStg: [SELECT FundingProgram__c, PaymentPercentage__c, (SELECT Id FROM Requirements__r) 
                                            FROM PaymentSettings__c
                                            WHERE FundingProgram__c IN: fundingProgramIds]){

            //calculate variables to outfunds__Amount__c
            Decimal paymentPercentage = paymentStg.PaymentPercentage__c <> null ? paymentStg.PaymentPercentage__c : 0;
            Decimal fundRequestAmount = this.fundRequestByProgram.get(paymentStg.FundingProgram__c).outfunds__Awarded_Amount__c <> null ? 
                                        this.fundRequestByProgram.get(paymentStg.FundingProgram__c).outfunds__Awarded_Amount__c : 0;

            //New Disbursement record
            outfunds__Disbursement__c disbursement = new outfunds__Disbursement__c(
                    outfunds__Amount__c = (paymentPercentage * fundRequestAmount) / 100,
                    outfunds__Funding_Request__c = this.fundRequestByProgram.get(paymentStg.FundingProgram__c).Id,
                    PaymentSetting__c = paymentStg.Id
                    );

            //Build Map of disbursements by program and request
            for(outfunds__Requirement__c requirement: paymentStg.Requirements__r){
                this.disbursByProgrAndRequest.put(paymentStg.FundingProgram__c + '-' + requirement.Id, disbursement);
            }
        }
    }

    /**
    * @description clone a list of objectives
    * @param fundingRequest modified funding request record
    */
    private void cloneObjectives(outfunds__Funding_Request__c fundingRequest){
        if(this.objectivesByFundingRequestId.containsKey(fundingRequest.Id)){
            for(Objective__c objective : this.objectivesByFundingRequestId.get(fundingRequest.Id)){
                pmdm__Service__c service = new pmdm__Service__c();
                service.Name = objective.Name;
                service.pmdm__Program__c = fundingRequest.Program__c;
                service.Objective__c = objective.Id;
                service.OwnerId = fundingRequest.OwnerId;
                this.recordsToInsertAfter.add(service);
            }
        }
    }

    /**
    * @description Create Program Engagement
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 07-01-2022 
    * @param fundingRequest 
    **/
    private void createProgramEngagement(outfunds__Funding_Request__c fundingRequest){
        if (fundingRequest.IndividualRequest__c && String.isNotBlank(fundingRequest.outfunds__Applying_Contact__c)) {
            //Add record to global list to insert
            this.programEngmToInsert.add(new pmdm__ProgramEngagement__c(
                pmdm__Contact__c = fundingRequest.outfunds__Applying_Contact__c,
                pmdm__Program__c = fundingRequest.Program__c,
                OwnerId = fundingRequest.OwnerId
            ));
        }
    }

    /**
    * @description clone a list of requirements
    * @param fundingRequest modified funding request record
    */
    private void cloneRequirements(outfunds__Funding_Request__c fundingRequest){
        if(this.requirementsByFundingProgramId.containsKey(fundingRequest.outfunds__FundingProgram__c)){
            for(outfunds__Requirement__c requirement : this.requirementsByFundingProgramId.get(fundingRequest.outfunds__FundingProgram__c)){
                outfunds__Requirement__c newRequirement = requirement.clone(false, true, false, false);
                newRequirement.Funding_Program__c = null; 
                newRequirement.Program__c = fundingRequest.Program__c;
                newRequirement.outfunds__Disbursement__c = this.disbursByProgrAndRequest.get(fundingRequest.outfunds__FundingProgram__c  + '-' + requirement.Id)?.Id;
                newRequirement.OwnerId = fundingRequest.OwnerId;
                newRequirement.recordTypeId = CONSTANTS.REQUIREMENT_RT_REQUIRE_DOCUMENT;
                this.recordsToInsertAfter.add(newRequirement);
            }
        }
    }

    /**
    * @description This method check if request is of individual and CRUE Program
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 07-11-2022 
    * @param fundingRequest 
    **/
    private Boolean isCRUEIndividualRequest(outfunds__Funding_Request__c fundingRequest){
        return this.isCrueRecordType(fundingRequest.recordTypeId) && fundingRequest.IndividualRequest__c;
    }

    /**
    * @description Check if record type is CRUE
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 07-12-2022 
    * @param recordTypeId 
    * @return Boolean 
    **/
    private Boolean isCrueRecordType(String recordTypeId){

        if(crueRequestRecordTypes.isEmpty()){
            crueRequestRecordTypes.add(S4GUtils.getRecordTypeIdByDevName('outfunds__Funding_Request__c', 'FundacionONCECRUEAlumno'));
            crueRequestRecordTypes.add(S4GUtils.getRecordTypeIdByDevName('outfunds__Funding_Request__c', 'FundacionONCECRUEUniversidad'));
        }

        return crueRequestRecordTypes.contains(recordTypeId);
    }

    /**
    * @description get Proyect of CRUE request
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 07-11-2022 
    * @return String 
    **/
    private String getProyectForUniversityCRUERequest(){
        
        if(String.isBlank(crueProyectId)){
            try {
                crueProyectId = [SELECT 
                            Program__c 
                        FROM outfunds__Funding_Request__c 
                        WHERE outfunds__FundingProgram__r.Tipo_de_Programas_de_Becas__c = : CONSTANTS.CRUE_PRACTICES
                        AND IndividualRequest__c = false 
                        AND outfunds__Status__c =: CONSTANTS.FUNDING_REQUEST_STATUS_AWARDED 
                        ORDER BY CREATEDDATE DESC 
                        LIMIT 1].Program__c;   
            } catch (Exception e) {
                crueProyectId = null;
            }
        }
        return crueProyectId;
    }

}