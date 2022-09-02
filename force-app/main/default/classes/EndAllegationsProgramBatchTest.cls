/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 05-26-2022
 * @last modified by  : cesar.parra@s4g.es
**/
@isTest
public with sharing class EndAllegationsProgramBatchTest {
    @TestSetup
    static void setup(){
        PrepareTestData.prepareTestEnvironment();

        outfunds__Funding_Program__c fundingProgram = PrepareTestData.createFundingPrograms(1).get(0);
        fundingProgram.outfunds__Status__c = 'In progress';
        fundingProgram.AllegationsEndDate__c = Date.Today().addDays(-1);
        insert fundingProgram;
        
        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        fundingRequest.outfunds__Status__c = 'En Proceso de Alegaciones/Subsanaciones';
        insert fundingRequest;
    }
    
    @IsTest
    static void fundingProgramAllegationsEndTest(){
        outfunds__Funding_Program__c fundingProgram = [SELECT Id FROM outfunds__Funding_Program__c LIMIT 1];
        
        System.assertEquals(0, [SELECT Count() FROM outfunds__Funding_Request__c WHERE outfunds__FundingProgram__c = :fundingProgram.Id AND outfunds__Status__c = 'Resolución Final']);

        Test.startTest();
        EndAllegationsProgramBatch.runMe();
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM outfunds__Funding_Request__c WHERE outfunds__FundingProgram__c = :fundingProgram.Id AND outfunds__Status__c = 'Resolución Final']);
    }

    @isTest
    static void runScheduleBatchTest(){
        EndAllegationsProgramBatch endAllegationsProgramBatch = new EndAllegationsProgramBatch();
        String cron_schedule = '0 0 23 * * ?'; 
        Test.startTest();
        System.schedule('EndAllegationsProgramBatch Schedule', cron_schedule, endAllegationsProgramBatch);
        Test.stopTest();
    }
}