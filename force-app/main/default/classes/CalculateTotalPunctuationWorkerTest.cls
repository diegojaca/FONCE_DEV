/**
 * @description This class will test CalculateTotalPunctuationWorker
 * @author bruno.martin@s4g.es
 * @version 12/04/2022
 */
@IsTest
private class CalculateTotalPunctuationWorkerTest {

    private static final String REVIEW_FIELD_TO_VALIDATE = String.valueOf(outfunds__Review__c.Elementos_innovadores__c);

    @TestSetup
    static void prepareData() {
        WorkersManager.avoidAllWorkersExecution(true);
        outfunds__Funding_Program__c fundingProgram = PrepareTestData.createFundingPrograms(1).get(0);
        insert fundingProgram;

        insert PrepareTestData.createScoringCriteriaQuestion(fundingProgram.Id, CalculateTotalPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE, null);

        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        insert fundingRequest;

        outfunds__Review__c parentReview = PrepareTestData.createParentReviews(fundingRequest.Id, 1).get(0);
        parentReview.outfunds__Status__c = CONSTANTS.REVIEW_STATUS_NOT_STARTED;
        insert parentReview;
        outfunds__Review__c childReview = PrepareTestData.createChildReviews(parentReview.Id, 1).get(0);
        childReview.put(CalculateTotalPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE, 10);
        insert childReview;
        WorkersManager.avoidAllWorkersExecution(false);
    }

    @IsTest
    static void testInsertChildReview() {
        outfunds__Review__c review = Database.query('SELECT Id, outfunds__FundingRequest__c, ParentReview__c,' + CalculateTotalPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE
                + ' FROM outfunds__Review__c WHERE ParentReview__c != NULL LIMIT 1');
        review.outfunds__Status__c = CONSTANTS.REVIEW_STATUS_SUBMITTED;
        CalculateTotalPunctuationWorker worker = new CalculateTotalPunctuationWorker();

        insert PrepareTestData.createHandler(String.valueOf(outfunds__Review__c.class), String.valueOf(CalculateTotalPunctuationWorker.class));
        Test.startTest();
        worker.bulkBeforeInsert(new List<outfunds__Review__c>{
                review
        });
        worker.beforeInsert(review);
        worker.andFinallyAfter();
        Test.stopTest();

        System.assertEquals(10, review.Puntaje_total__c, 'Should have been added to that field');

        outfunds__Review__c parentReview = Database.query('SELECT Id, Puntaje_total__c, outfunds__Status__c, ParentReview__c,' + CalculateTotalPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE
                + ' FROM outfunds__Review__c WHERE ParentReview__c = NULL LIMIT 1');
        System.assertEquals(10, parentReview.get(CalculateTotalPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE), 'Should have been added to that field');
        System.assertEquals(10, parentReview.Puntaje_total__c, 'Should have been added to that field');
    }

    @IsTest
    static void testUpdateChildReview() {
        outfunds__Review__c review = Database.query('SELECT Id, outfunds__FundingRequest__c, ParentReview__c,' + CalculateTotalPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE
                + ' FROM outfunds__Review__c WHERE ParentReview__c != NULL LIMIT 1');
        review.outfunds__Status__c = CONSTANTS.REVIEW_STATUS_SUBMITTED;
        CalculateTotalPunctuationWorker worker = new CalculateTotalPunctuationWorker();

        Test.startTest();
        worker.bulkBeforeUpdate(new List<outfunds__Review__c>{
                review
        }, new List<outfunds__Review__c>{
                review
        });
        worker.beforeUpdate(review, review);
        Test.stopTest();

        System.assertEquals(10, review.Puntaje_total__c, 'Should have been added to that field');
    }

    @IsTest
    static void testSetErrorOnUpdateUpdate() {
        outfunds__Review__c review = Database.query('SELECT Id, outfunds__FundingRequest__c, ParentReview__c,' + CalculateTotalPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE
                + ' FROM outfunds__Review__c WHERE ParentReview__c != NULL LIMIT 1');
        review.outfunds__Status__c = CONSTANTS.REVIEW_STATUS_SUBMITTED;
        review.put(CalculateTotalPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE, null);
        CalculateTotalPunctuationWorker worker = new CalculateTotalPunctuationWorker();

        Test.startTest();
        worker.bulkBeforeUpdate(new List<outfunds__Review__c>{
                review
        }, new List<outfunds__Review__c>{
                review
        });
        worker.beforeUpdate(review, review);
        Test.stopTest();

        System.assertEquals(0, review.Puntaje_total__c, 'Should have been added to that field');
        System.assert(review.hasErrors(), 'Should have one error');
        System.assertEquals(
                review.getErrors().get(0).getFields().get(0)
                , String.valueOf(outfunds__Review__c.outfunds__Status__c)
                , 'Should have set an error message in this field'
        );
    }

    @IsTest
    static void testInsertParentReview(){
        outfunds__Review__c review = Database.query('SELECT Id, outfunds__FundingRequest__c, outfunds__Status__c, ParentReview__c,' + CalculateTotalPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE
                + ' FROM outfunds__Review__c WHERE ParentReview__c = NULL LIMIT 1');
        CalculateTotalPunctuationWorker worker = new CalculateTotalPunctuationWorker();

        Test.startTest();
        worker.bulkBeforeInsert(new List<outfunds__Review__c>{
                review
        });
        worker.beforeInsert(review);
        Test.stopTest();

        System.assertEquals(10, review.get(CalculateTotalPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE), 'Should have been added to that field');
        System.assertEquals(10, review.Puntaje_total__c, 'Should have been added to that field');
    }

    @IsTest
    static void testInsertParentReviewWithNullFieldValueInChildren(){
        outfunds__Review__c childReview = Database.query('SELECT Id, outfunds__FundingRequest__c, ParentReview__c,' + CalculateTotalPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE
                + ' FROM outfunds__Review__c WHERE ParentReview__c != NULL LIMIT 1');
        childReview.put(CalculateTotalPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE, null);
        update childReview;
        outfunds__Review__c review = Database.query('SELECT Id, outfunds__FundingRequest__c, outfunds__Status__c, ParentReview__c,' + CalculateTotalPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE
                + ' FROM outfunds__Review__c WHERE ParentReview__c = NULL LIMIT 1');
        CalculateTotalPunctuationWorker worker = new CalculateTotalPunctuationWorker();

        Test.startTest();
        worker.bulkBeforeInsert(new List<outfunds__Review__c>{
                review
        });
        worker.beforeInsert(review);
        Test.stopTest();

        System.assertEquals(null, review.get(CalculateTotalPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE), 'Should have been added to that field');
        System.assertEquals(0, review.Puntaje_total__c, 'Should have been added to that field');
    }

}