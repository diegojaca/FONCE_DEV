/**
 * @description This class will test FundingRequestExecuteRollMeUpWorker
 * @author bruno.martin@s4g.es
 * @version 08/04/2022
 */
@IsTest
private class FundingRequestExecuteRollMeUpWorkerTest {

    @TestSetup
    static void prepareData() {
        outfunds__Funding_Program__c fundingProgram = PrepareTestData.createFundingPrograms(1).get(0);
        insert fundingProgram;

        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        insert fundingRequest;

        outfunds__Review__c review = PrepareTestData.createParentReviews(fundingRequest.Id, 1).get(0);
        insert review;
    }

    @IsTest
    static void testRunRollMeUp() {
        Test.startTest();
        FundingRequestExecuteRollMeUpWorker worker = new FundingRequestExecuteRollMeUpWorker();
        worker.newRecords = Database.query(
                'SELECT Id,outfunds__FundingProgram__c,'
                        + String.join(PrepareTestData.getRollUpDefinitionChildFieldsToBeQueried(String.valueOf(outfunds__Funding_Request__c.class)), ',')
                        + ' FROM outfunds__Funding_Request__c'
        );
        worker.andFinallyAfter();
        Test.stopTest();
    }

}