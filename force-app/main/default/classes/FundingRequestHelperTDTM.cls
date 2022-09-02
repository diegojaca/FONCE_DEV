/**
 * @description       : 
 * @author            : Juan Gabriel Duarte
 * @group             : 
 * @last modified on  : 07-01-2022
 * @last modified by  : cesar.parra@s4g.es
 * Modifications Log 
 * Ver   Date         Author                Modification
 * 1.0   05-25-2021   Juan Gabriel Duarte   Initial Version
**/
public without sharing class FundingRequestHelperTDTM {
    private static Map<Id, Id> fundingProgramIdByFundingRequestId = new Map<Id, Id>();

    public FundingRequestHelperTDTM() {

    }

    /**
    * @description Permite renombrar las solicitudes
    * @author juangabriel.duarte@s4g.es  | 05-27-2021 
    * @param fundingRequests colección de registros de solicitudes después de su creación
    **/
    public static void renameFundingRequest(List<outfunds__Funding_Request__c> fundingRequests) {
        Set<Id> contactsId = new Set<Id>();
        Set<Id> programsId = new Set<Id>();
        for (outfunds__Funding_Request__c fundingReq : fundingRequests) {
            contactsId.add(fundingReq?.outfunds__Applying_Contact__c);
            programsId.add(fundingReq?.outfunds__FundingProgram__c);
        }

        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, Name FROM Contact WHERE Id IN :contactsId]);
        Map<Id, outfunds__Funding_Program__c> programs = new Map<Id, outfunds__Funding_Program__c>([
                SELECT Id, Name
                FROM outfunds__Funding_Program__c
                WHERE Id IN :programsId
        ]);

        List<String> variables;
        String rename;
        Date d = Date.today();
        String dayString = Datetime.newInstance(d.year(), d.month(), d.day()).format('dd/MM/YYYY');

        for (outfunds__Funding_Request__c fundingReq : fundingRequests) {
            if (contacts.containsKey(fundingReq?.outfunds__Applying_Contact__c) && programs.containsKey(fundingReq?.outfunds__FundingProgram__c)) {
                variables = new List<String>{
                        contacts.get(fundingReq?.outfunds__Applying_Contact__c).Name,
                        programs.get(fundingReq?.outfunds__FundingProgram__c).Name,
                        dayString
                };
                rename = String.join(variables, '-');
                fundingReq.Name = rename;
            }
        }

    }

    /**
    * @description Llena una colección que relaciona la solicitud y los programas becas para clonar la lista de requisitos en la solicitud
    * @author Juan Gabriel Duarte | 05-25-2021 
    * @param newFundingRequest funding request in trigger
    **/
    public static void checkFundingProgram(outfunds__Funding_Request__c newFundingRequest) {
        if (newFundingRequest.outfunds__FundingProgram__c != null) {
            FundingRequestHelperTDTM.fundingProgramIdByFundingRequestId.put(newFundingRequest.Id, newFundingRequest.outfunds__FundingProgram__c);
        }
    }

    /**
    * @description Permite crear el listado de requisitos sobre la solicitud de beca una vez registrada desde el web site o la comunidad
    * @author Juan Gabriel Duarte | 05-25-2021 
    **/
    public static void createRequirements() {
        if (!FundingRequestHelperTDTM.fundingProgramIdByFundingRequestId.isEmpty()) {

            Map<Id, List<outfunds__Requirement__c>> requirementsByFundingProgram = new Map<Id, List<outfunds__Requirement__c>>();
            //Consulta los requisitos para cada programa de beca para poblar la colección
            for (outfunds__Requirement__c requirement : [
                    SELECT Id, Funding_Program__c, outfunds__Type__c, Name, IsRequired__c, RequirementCategory__c
                    FROM outfunds__Requirement__c
                    WHERE Funding_Program__c IN :FundingRequestHelperTDTM.fundingProgramIdByFundingRequestId.values() 
                    AND RequirementCategory__c = 'Requisito de Solicitud'
            ]) {
                List<outfunds__Requirement__c> listRequirementIds = requirementsByFundingProgram.get(requirement.Funding_Program__c);
                if (listRequirementIds == null) {
                    listRequirementIds = new List<outfunds__Requirement__c>();
                    requirementsByFundingProgram.put(requirement.Funding_Program__c, listRequirementIds);
                }
                listRequirementIds.add(requirement);
            }

            List<outfunds__Requirement__c> requirementsToInsert = new List<outfunds__Requirement__c>();
            String fundingProgram;
            //Recorre las solicitudes registradas y según el programa beca inserta los requisitos
            for (String fundingRequestId : FundingRequestHelperTDTM.fundingProgramIdByFundingRequestId.keySet()) {
                fundingProgram = FundingRequestHelperTDTM.fundingProgramIdByFundingRequestId.get(fundingRequestId);
                if (requirementsByFundingProgram.containsKey(fundingProgram)) {
                    for (outfunds__Requirement__c requirement : requirementsByFundingProgram.get(fundingProgram)) {
                        requirementsToInsert.add(new outfunds__Requirement__c(
                                Name = requirement.Name,
                                outfunds__Funding_Request__c = fundingRequestId,
                                outfunds__Type__c = requirement.outfunds__Type__c,
                                IsRequired__c = requirement.IsRequired__c,
                                RecordTypeId = CONSTANTS.REQUIREMENT_RT_REQUIRE_DOCUMENT
                        ));
                    }
                }
            }

            insert requirementsToInsert;
            requirementsToInsert.clear();
        }
    }

    public static void createParentReviewIfNecessary() {
        if (!FundingRequestHelperTDTM.fundingProgramIdByFundingRequestId.isEmpty()) {
            Map<String, outfunds__Funding_Program__c> fundingProgramById = new Map<String, outfunds__Funding_Program__c>();
            for (outfunds__Funding_Program__c fundingProgram : [
                    SELECT Id, DoesFundingRequestRequireReview__c
                    FROM outfunds__Funding_Program__c
                    WHERE Id IN :FundingRequestHelperTDTM.fundingProgramIdByFundingRequestId.values()
            ]) {
                fundingProgramById.put(fundingProgram.Id, fundingProgram);
            }
            //This map will contain outfunds__Funding_Request__c record type Developer Names by its Ids
            Map<String, String> developerNameByRecordTypeId = new Map<String, String>();
            //This map will contain outfunds__Review__c record type Ids by its Developer Names
            Map<String, String> recordTypeIdByDeveloperName = new Map<String, String>();
            for (RecordType recordType : [
                    SELECT Id, DeveloperName, SobjectType
                    FROM RecordType
                    WHERE SobjectType IN :new List<String>{
                            String.valueOf(outfunds__Funding_Request__c.class)
                            , String.valueOf(outfunds__Review__c.class)
                    }
            ]) {
                if (recordType.SobjectType.equals(String.valueOf(outfunds__Funding_Request__c.class))) {
                    developerNameByRecordTypeId.put(recordType.Id, recordType.DeveloperName);
                } else if (recordType.SobjectType.equals(String.valueOf(outfunds__Review__c.class))) {
                    recordTypeIdByDeveloperName.put(recordType.DeveloperName, recordType.Id);
                }
            }

            List<outfunds__Review__c> reviewsToBeInserted = new List<outfunds__Review__c>();
            for (String fundingRequestId : FundingRequestHelperTDTM.fundingProgramIdByFundingRequestId.keySet()) {
                if (fundingProgramById.get(FundingRequestHelperTDTM.fundingProgramIdByFundingRequestId.get(fundingRequestId)).DoesFundingRequestRequireReview__c) {
                    outfunds__Funding_Request__c newRequest = (outfunds__Funding_Request__c) Trigger.newMap.get(fundingRequestId);
                    outfunds__Review__c review = new outfunds__Review__c(
                            Name = (Label.ParentReviewStartName + ' ' + newRequest.Name).abbreviate(80)
                            , outfunds__Status__c = CONSTANTS.REVIEW_STATUS_NOT_STARTED
                            , outfunds__FundingRequest__c = fundingRequestId
                    );
                    if (developerNameByRecordTypeId.containsKey(newRequest.RecordTypeId)
                            && recordTypeIdByDeveloperName.containsKey(developerNameByRecordTypeId.get(newRequest.RecordTypeId))) {
                        review.RecordTypeId = recordTypeIdByDeveloperName.get(developerNameByRecordTypeId.get(newRequest.RecordTypeId));
                    }
                    reviewsToBeInserted.add(review);
                }
            }

            if (!reviewsToBeInserted.isEmpty()) {
                WorkersManager.avoidWorkersExecutionPerObject(String.valueOf(outfunds__Review__c.class), String.valueOf(FundingRequestHelperTDTM.class), true);
                WorkersManager.avoidWorkerExecution(String.valueOf(ReviewExecuteRollMeUpWorker.class), String.valueOf(FundingRequestHelperTDTM.class), false);
                insert reviewsToBeInserted;
                WorkersManager.avoidWorkersExecutionPerObject(String.valueOf(outfunds__Review__c.class), String.valueOf(FundingRequestHelperTDTM.class), false);
            }
        }
    }

    /**
    * @description Permite crear el listado de objetivos sobre la solicitud de beca una vez registrada desde la comunidad
    * @author César Parra | 05-26-2022 
    **/
    public static void createObjectives() {
        if (!FundingRequestHelperTDTM.fundingProgramIdByFundingRequestId.isEmpty()) {

            Map<Id, List<Objective__c>> objectivesByFundingProgramId = new Map<Id, List<Objective__c>>();
            
            for (Objective__c objective : [
                    SELECT Id, Name, Funding_Program__c
                    FROM Objective__c
                    WHERE Funding_Program__c IN :FundingRequestHelperTDTM.fundingProgramIdByFundingRequestId.values()
            ]) {
                if(!objectivesByFundingProgramId.containsKey(objective.Funding_Program__c)){
                    objectivesByFundingProgramId.put(objective.Funding_Program__c, new List<Objective__c>());
                }    
                objectivesByFundingProgramId.get(objective.Funding_Program__c).add(objective);  
            }

            List<Objective__c> objectives = new List<Objective__c>();

            String fundingProgramId;

            for (String fundingRequestId : FundingRequestHelperTDTM.fundingProgramIdByFundingRequestId.keySet()) {
                fundingProgramId = FundingRequestHelperTDTM.fundingProgramIdByFundingRequestId.get(fundingRequestId);
                if (objectivesByFundingProgramId.containsKey(fundingProgramId)) {
                    for (Objective__c objective : objectivesByFundingProgramId.get(fundingProgramId)) {
                        objectives.add(new Objective__c(
                                Name = objective.Name,
                                Funding_Request__c = fundingRequestId,
                                Objective__c = objective.Id
                        ));
                    }
                }
            }

            insert objectives;
            objectives.clear();
        }
    }
}