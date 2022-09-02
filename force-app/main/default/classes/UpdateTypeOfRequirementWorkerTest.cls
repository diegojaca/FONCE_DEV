/**
 * @description This class will test UpdateTypeOfRequirementWorker
 * @author bruno.martin@s4g.es
 * @version 27/07/2022
 */
@IsTest
private class UpdateTypeOfRequirementWorkerTest {

    @TestSetup
    static void prepareData() {
        Contact contact = PrepareTestData.createContact('test lastname');
        contact.N_mero_de_Documento__c = '123456789';
        insert contact;

        outfunds__Funding_Program__c fundingProgram = PrepareTestData.createFundingPrograms(1).get(0);
        fundingProgram.DoesFundingRequestRequireReview__c = true;
        insert fundingProgram;

        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        fundingRequest.External_ID__c = 'test_2022';
        fundingRequest.outfunds__Applying_Contact__c = contact.Id;
        insert fundingRequest;

        insert S4GTestFactory.createObject(String.valueOf(pmdm__Program__c.class));
    }

    @IsTest
    static void testSetTypeOfRequirementOnInsert() {
        outfunds__Funding_Request__c fundingRequest = [SELECT Id, outfunds__Status__c, Type_Requirement__c FROM outfunds__Funding_Request__c LIMIT 1];
        System.assertEquals(null, fundingRequest.Type_Requirement__c, 'Should be null');
        fundingRequest.outfunds__Status__c = CONSTANTS.FUNDING_REQUEST_STATUS_IN_PROGRESS;
        UpdateTypeOfRequirementWorker worker = new UpdateTypeOfRequirementWorker();

        Test.startTest();
        worker.bulkBefore(new List<outfunds__Funding_Request__c>{fundingRequest});
        worker.beforeInsert(fundingRequest);
        Test.stopTest();

        System.assertNotEquals(null, fundingRequest.Type_Requirement__c, 'Must be returned not null value');
    }

    @IsTest
    static void testSetTypeOfRequirementOnUpdate() {
        pmdm__Program__c program = [SELECT Id, pmdm__Status__c, Type_Requirement__c FROM pmdm__Program__c LIMIT 1];
        System.assertEquals(null, program.Type_Requirement__c, 'Should be null');
        program.pmdm__Status__c = CONSTANTS.PROGRAM_STATUS_ACTIVE;
        pmdm__Program__c oldProgram = program.clone(true);
        oldProgram.pmdm__Status__c = null;
        UpdateTypeOfRequirementWorker worker = new UpdateTypeOfRequirementWorker();

        Test.startTest();
        worker.bulkBefore(new List<pmdm__Program__c>{program});
        worker.beforeUpdate(oldProgram, program);
        Test.stopTest();

        System.assertNotEquals(null, program.Type_Requirement__c, 'Must be returned not null value');
    }
}