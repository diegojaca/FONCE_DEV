/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 09-01-2022
 * @last modified by  : diego.jacanamijoy@s4g.es
**/
@IsTest
public with sharing class CreationServiceDeliveriesWorkerTest {
    
    @TestSetup
    static void makeData(){

        /** Insert bypass to flows with current user */
        insert new Bypasser__c(Disable_Autolaunched_Flows__c = true, SetupOwnerId = Userinfo.getProfileId());

        PrepareTestData.prepareTestEnvironment();

        WorkersManager.avoidAllWorkersExecution(true);

        Contact contact = PrepareTestData.createContact('Test');
        insert Contact;

        outfunds__Funding_Program__c fundingProgram = PrepareTestData.createFundingPrograms(1).get(0);
        insert fundingProgram;
        
        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        insert fundingRequest;

        //Insert payment setting
        PaymentSettings__c paymentStg = new PaymentSettings__c();
        paymentStg.PaymentPercentage__c = 20;
        insert paymentStg;

        //Insert dusbursement
        outfunds__Disbursement__c disbursement = new outfunds__Disbursement__c(
            outfunds__Funding_Request__c = fundingRequest.Id,
            PaymentSetting__c = paymentStg.Id
            );
        insert disbursement;

        Objective__c parentObjective = PrepareTestData.createObjectives(fundingRequest.Id, 1).get(0);
        parentObjective.Funding_Program__c = fundingProgram.Id;
        insert parentObjective; 

        outfunds__Requirement__c requirement = PrepareTestData.createRequirements(fundingProgram.Id, 1).get(0);
        requirement.Objective__c = parentObjective.Id;
        requirement.PaymentSetting__c = paymentStg.Id;
        insert requirement; 

        Objective__c objective = PrepareTestData.createObjectives(fundingRequest.Id, 1).get(0);
        objective.Objective__c = parentObjective.Id;
        insert objective; 

        pmdm__Program__c program = PrepareTestData.createPrograms(1).get(0);
        insert program; 

        pmdm__Service__c service = PrepareTestData.createServices(program.Id, 1).get(0);
        service.Objective__c = objective.Id;
        insert service; 

        WorkersManager.avoidAllWorkersExecution(false);
    }

    @IsTest
    static void creationServiceDeliveriesWorkerAfterTest(){

        System.assertEquals(0, [SELECT Count() FROM pmdm__ServiceDelivery__c]);

        pmdm__Program__c program = [SELECT Id FROM pmdm__Program__c].get(0);
        Contact contact = [SELECT Id FROM Contact].get(0);

        CreationServiceDeliveriesWorker worker =new CreationServiceDeliveriesWorker();

        pmdm__ProgramEngagement__c programEngagement = new pmdm__ProgramEngagement__c();
        programEngagement.pmdm__Program__c = program.Id;
        programEngagement.pmdm__Contact__c = contact.Id;
        programEngagement.Name= 'test';
        insert programEngagement;

        Test.startTest();
            worker.bulkAfterInsert(new List<pmdm__ProgramEngagement__c>{programEngagement});
            worker.afterInsert(programEngagement);
            worker.andFinallyAfter();
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM pmdm__ServiceDelivery__c], 'Requirement dont clone');
    }

    @IsTest
    static void realtedDisbursementToRequirementTest(){

        System.assertEquals(0, [SELECT Count() FROM outfunds__Requirement__c WHERE outfunds__Disbursement__c <> NULL], 'Must be return 0 record');
        
        //Insert program engagement
        pmdm__Program__c program = [SELECT Id FROM pmdm__Program__c].get(0);
        Contact contact = [SELECT Id FROM Contact].get(0);

        CreationServiceDeliveriesWorker worker = new CreationServiceDeliveriesWorker();

        pmdm__ProgramEngagement__c programEngagement = new pmdm__ProgramEngagement__c();
        programEngagement.pmdm__Program__c = program.Id;
        programEngagement.pmdm__Contact__c = contact.Id;
        programEngagement.Name= 'test';
        insert programEngagement;

        Test.startTest();
            worker.bulkAfterInsert(new List<pmdm__ProgramEngagement__c>{programEngagement});
            worker.afterInsert(programEngagement);
            worker.andFinallyAfter();
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM outfunds__Requirement__c WHERE outfunds__Disbursement__c <> NULL], 'Disbursement don´t related to requirement');
    }
}