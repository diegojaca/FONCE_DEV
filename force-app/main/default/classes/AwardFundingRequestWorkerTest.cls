/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 09-01-2022
 * @last modified by  : diego.jacanamijoy@s4g.es
**/
@IsTest
public with sharing class AwardFundingRequestWorkerTest {

    private static final String LAST_NAME_CONTACT = 'Test LastName';
    
    @TestSetup
    static void makeData(){

        /** Insert bypass to flows with current user */
        insert new Bypasser__c(Disable_Autolaunched_Flows__c = true, SetupOwnerId = Userinfo.getProfileId());

        PrepareTestData.prepareTestEnvironment();

        Contact contact = PrepareTestData.createContact(LAST_NAME_CONTACT);
        insert contact;

        WorkersManager.avoidAllWorkersExecution(true);
        outfunds__Funding_Program__c fundingProgram = PrepareTestData.createFundingPrograms(1).get(0);
        insert fundingProgram;

        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        fundingRequest.outfunds__Applying_Contact__c = contact.Id;
        insert fundingRequest;

        Objective__c objective = PrepareTestData.createObjectives(fundingRequest.Id, 1).get(0);//new Objective__c(Funding_Request__c = fundingRequest.Id);
        insert objective; 

        outfunds__Requirement__c requirement = PrepareTestData.createRequirements(fundingProgram.Id, 1).get(0);
        requirement.RequirementCategory__c = CONSTANTS.REQUIREMENT_CATEGORY_PROJECT_REQUIREMENT;
        insert requirement;
        WorkersManager.avoidAllWorkersExecution(false);
    }

    @IsTest
    static void beforeUpdateOk(){

        outfunds__Funding_Request__c fundingRequest = [SELECT outfunds__Status__c, RecordTypeId FROM outfunds__Funding_Request__c LIMIT 1];
        
        Test.startTest();
            fundingRequest.outfunds__Status__c = CONSTANTS.FUNDING_REQUEST_STATUS_AWARDED;
            fundingRequest.outfunds__Awarded_Amount__c = 10;
            update fundingRequest;
        Test.stopTest();

        fundingRequest = [SELECT outfunds__Status__c FROM outfunds__Funding_Request__c WHERE Id =: fundingRequest.Id LIMIT 1];
        System.assertEquals(CONSTANTS.FUNDING_REQUEST_STATUS_AWARDED, fundingRequest.outfunds__Status__c, 'Record dont updated');
    }

    @IsTest
    static void awardFundingRequestWorkerBeforeTest(){

        AwardFundingRequestWorker worker =new AwardFundingRequestWorker();

        outfunds__Funding_Request__c fundingRequest = [SELECT outfunds__Status__c, Program__c, RecordTypeId, Name, OwnerId, outfunds__Applying_Organization__c, IndividualRequest__c, outfunds__Applying_Contact__c, EndProjectDate__c, EndProgressDate__c, EndLoadStudentDate__c FROM outfunds__Funding_Request__c LIMIT 1];
        outfunds__Funding_Request__c oldFundingRequest = fundingRequest.clone(true);
        fundingRequest.outfunds__Status__c = CONSTANTS.FUNDING_REQUEST_STATUS_AWARDED;

        worker.newRecordsMap.put(fundingRequest.Id, fundingRequest);
        
        Test.startTest();
            worker.beforeUpdate(oldFundingRequest, fundingRequest);
            worker.andFinallyBefore();
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM pmdm__Program__c], 'Program dont created');
    }

    @IsTest
    static void awardFundingRequestWorkerAfterTest(){

        System.assertEquals(1, [SELECT Count() FROM outfunds__Requirement__c ], 'Requirement dont created');
        System.assertEquals(0, [SELECT Count() FROM pmdm__Service__c ]);

        AwardFundingRequestWorker worker =new AwardFundingRequestWorker();

        outfunds__Funding_Request__c fundingRequest = [SELECT outfunds__Status__c, RecordTypeId, Program__c, Name, IndividualRequest__c, outfunds__Applying_Contact__c, outfunds__FundingProgram__c, OwnerId, outfunds__Applying_Organization__c, EndProjectDate__c, EndProgressDate__c, EndLoadStudentDate__c FROM outfunds__Funding_Request__c LIMIT 1];
        outfunds__Funding_Request__c oldFundingRequest = fundingRequest.clone(true);
        fundingRequest.outfunds__Status__c = CONSTANTS.FUNDING_REQUEST_STATUS_AWARDED;

        pmdm__Program__c program = new pmdm__Program__c();
        program.Name = fundingRequest.Name;
        program.pmdm__Status__c = 'Active';
        insert program;

        fundingRequest.Program__c = program.Id;

        worker.newRecordsMap.put(fundingRequest.Id, fundingRequest);
        worker.oldRecordsMap.put(oldFundingRequest.Id, oldFundingRequest);

        Test.startTest();
            worker.bulkAfterUpdate(new List<outfunds__Funding_Request__c>{oldFundingRequest}, new List<outfunds__Funding_Request__c>{fundingRequest});
            worker.andFinallyAfter();
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM outfunds__Requirement__c WHERE Program__c = :program.Id], 'Requirement dont clone');
        System.assertEquals(1, [SELECT Count() FROM pmdm__Service__c WHERE pmdm__Program__c = :program.Id], 'Objective dont clone');
    }

    @IsTest
    static void createPaymentTest(){

        System.assertEquals(0, [SELECT Count() FROM outfunds__Disbursement__c], 'Must be return 0 records');

        AwardFundingRequestWorker worker =new AwardFundingRequestWorker();

        outfunds__Funding_Request__c fundingRequest = [SELECT outfunds__Status__c, Program__c, Name, RecordTypeId, outfunds__FundingProgram__c, IndividualRequest__c, outfunds__Applying_Contact__c, outfunds__Awarded_Amount__c, OwnerId, outfunds__Applying_Organization__c, EndProjectDate__c, EndProgressDate__c, EndLoadStudentDate__c FROM outfunds__Funding_Request__c LIMIT 1];
        outfunds__Funding_Request__c oldFundingRequest = fundingRequest.clone(true);
        fundingRequest.outfunds__Status__c = CONSTANTS.FUNDING_REQUEST_STATUS_AWARDED;

        pmdm__Program__c program = new pmdm__Program__c();
        program.Name = fundingRequest.Name;
        program.pmdm__Status__c = 'Active';
        insert program;

        //Insert payment setting
        PaymentSettings__c paymentStg = new PaymentSettings__c();
        paymentStg.PaymentPercentage__c = 20;
        paymentStg.FundingProgram__c = fundingRequest.outfunds__FundingProgram__c;
        insert paymentStg;

        //Update Requirement
        outfunds__Requirement__c requirement = [SELECT Id FROM outfunds__Requirement__c LIMIT 1];
        requirement.PaymentSetting__c = paymentStg.Id;
        update requirement;

        fundingRequest.Program__c = program.Id;

        worker.newRecordsMap.put(fundingRequest.Id, fundingRequest);
        worker.oldRecordsMap.put(oldFundingRequest.Id, oldFundingRequest);

        Test.startTest();
            worker.bulkAfterUpdate(new List<outfunds__Funding_Request__c>{oldFundingRequest}, new List<outfunds__Funding_Request__c>{fundingRequest});
            worker.andFinallyAfter();
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM outfunds__Disbursement__c], 'Disbursement dont created');
        System.assertEquals(1, [SELECT Count() FROM outfunds__Requirement__c WHERE Program__c = :program.Id AND outfunds__Disbursement__c <> NULL], 'Requirement dont clone');
    }

    @IsTest
    static void createProgramEnagementTest(){

        System.assertEquals(0, [SELECT Count() FROM pmdm__ProgramEngagement__c], 'Must be return 0 records');

        AwardFundingRequestWorker worker = new AwardFundingRequestWorker();

        outfunds__Funding_Request__c fundingRequest = [SELECT outfunds__Status__c, Program__c, Name, RecordTypeId, outfunds__FundingProgram__c, IndividualRequest__c, outfunds__Applying_Contact__c, outfunds__Awarded_Amount__c, OwnerId, outfunds__Applying_Organization__c, EndProjectDate__c, EndProgressDate__c, EndLoadStudentDate__c FROM outfunds__Funding_Request__c LIMIT 1];

        outfunds__Funding_Request__c oldFundingRequest = fundingRequest.clone(true);
        fundingRequest.outfunds__Status__c = CONSTANTS.FUNDING_REQUEST_STATUS_AWARDED;
        fundingRequest.IndividualRequest__c = true;

        pmdm__Program__c program = new pmdm__Program__c();
        program.Name = fundingRequest.Name;
        program.pmdm__Status__c = 'Active';
        insert program;

        fundingRequest.Program__c = program.Id;

        worker.newRecordsMap.put(fundingRequest.Id, fundingRequest);
        worker.oldRecordsMap.put(oldFundingRequest.Id, oldFundingRequest);

        Test.startTest();
            worker.bulkAfterUpdate(new List<outfunds__Funding_Request__c>{oldFundingRequest}, new List<outfunds__Funding_Request__c>{fundingRequest});
            worker.andFinallyAfter();
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM pmdm__ProgramEngagement__c], 'Program Engagement dont created');
    }

    @IsTest
    static void relateProyectToIndividualCRUErequest(){

        //Get program
        outfunds__Funding_Program__c program = [SELECT Id FROM outfunds__Funding_Program__c LIMIT 1];
        program.Tipo_de_Programas_de_Becas__c = CONSTANTS.CRUE_PRACTICES;

        //Create program
        pmdm__Program__c proyect = new pmdm__Program__c();
        proyect.Name = 'Proyect Test Name';
        proyect.pmdm__Status__c = 'Active';
        insert proyect;
        
        //Get University request
        outfunds__Funding_Request__c universityRequest = [SELECT outfunds__Applying_Contact__c, OwnerId FROM outfunds__Funding_Request__c WHERE outfunds__FundingProgram__c =: program.Id LIMIT 1];
        universityRequest.IndividualRequest__c = false;
        universityRequest.outfunds__Status__c = CONSTANTS.FUNDING_REQUEST_STATUS_AWARDED;
        universityRequest.Program__c = proyect.Id;
        universityRequest.outfunds__Awarded_Amount__c = 10;
        universityRequest.AlumnosPracticasConcedidos__c = 3;

        //Update records
        WorkersManager.avoidAllWorkersExecution(true);
        update program;
        update universityRequest;
        WorkersManager.avoidAllWorkersExecution(false);

        Contact contact = PrepareTestData.createContact('Test Last Name 2');
        insert contact;

        //Create individual request
        outfunds__Funding_Request__c oldIndividualRequest = PrepareTestData.createFundingRequests(program.Id, 1).get(0);
        oldIndividualRequest.outfunds__Applying_Contact__c = contact.Id;
        oldIndividualRequest.IndividualRequest__c = true;
        oldIndividualRequest.Name = 'PRÁCTICAS “FUNDACIÓN ONCE-CRUE” Individuo';
        oldIndividualRequest.OwnerId = universityRequest.OwnerId;
        oldIndividualRequest.recordTypeId = S4GUtils.getRecordTypeIdByDevName('outfunds__Funding_Request__c', 'FundacionONCECRUEAlumno');

        outfunds__Funding_Request__c newIndividualRequest = oldIndividualRequest.clone();
        newIndividualRequest.outfunds__Status__c = CONSTANTS.FUNDING_REQUEST_STATUS_AWARDED;

        AwardFundingRequestWorker worker = new AwardFundingRequestWorker();

        Test.startTest();
            worker.beforeUpdate(oldIndividualRequest, newIndividualRequest);
            worker.andFinallyAfter();
        Test.stopTest();

        System.assertEquals(proyect.Id, newIndividualRequest.Program__c, 'Proyect don´t related');
        System.assertEquals(1, [SELECT Count() FROM pmdm__ProgramEngagement__c WHERE pmdm__Contact__c =: contact.Id], 'Must be return one record');

    }
}