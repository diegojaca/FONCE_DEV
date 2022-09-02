/**
 * @description This class will test CalculateAutomaticPunctuationWorker
 * @author bruno.martin@s4g.es
 * @version 19/04/2022
 */
@IsTest
private class CalculateAutomaticPunctuationWorkerTest {

    private static final String REVIEW_FIELD_TO_VALIDATE_PICKLIST_FIELD = String.valueOf(outfunds__Review__c.Experiencia_de_la_universidad__c);
    private static final String FUNDING_REQUEST_FIELD_TO_VALIDATE_PICKLIST_FIELD = String.valueOf(outfunds__Funding_Request__c.ExperienciaenProyectosSimilares__c);
    private static final String REVIEW_FIELD_TO_VALIDATE_INTERVAL = String.valueOf(outfunds__Review__c.PorcentajeDeDiscapacidad__c);
    private static final String FUNDING_REQUEST_FIELD_TO_VALIDATE_INTERVAL = String.valueOf(outfunds__Funding_Request__c.PorcentajeDeDiscapacidad__c);

    @TestSetup
    static void prepareData() {
        WorkersManager.avoidAllWorkersExecution(true);
        outfunds__Funding_Program__c fundingProgram = PrepareTestData.createFundingPrograms(1).get(0);
        insert fundingProgram;

        scoring_criteria__c intervalQuestion = PrepareTestData.createScoringCriteriaQuestion(
                fundingProgram.Id
                , CalculateAutomaticPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE_INTERVAL
                , CalculateAutomaticPunctuationWorkerTest.FUNDING_REQUEST_FIELD_TO_VALIDATE_INTERVAL
        );
        scoring_criteria__c picklistQuestion = PrepareTestData.createScoringCriteriaQuestion(
                fundingProgram.Id
                , CalculateAutomaticPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE_PICKLIST_FIELD
                , CalculateAutomaticPunctuationWorkerTest.FUNDING_REQUEST_FIELD_TO_VALIDATE_PICKLIST_FIELD
        );
        insert new List<SObject>{
                intervalQuestion
                , picklistQuestion
        };
        scoring_criteria__c intervalResponse = PrepareTestData.createScoringCriteriaResponse(intervalQuestion.Id);
        intervalResponse.Valor_Min__c = 1;
        intervalResponse.Valor_max__c = 3;
        intervalResponse.Puntuacion__c = 1;
        scoring_criteria__c intervalResponse2 = PrepareTestData.createScoringCriteriaResponse(intervalQuestion.Id);
        intervalResponse2.Valor_Min__c = 4;
        intervalResponse2.Valor_max__c = 6;
        intervalResponse2.Puntuacion__c = 2;
        scoring_criteria__c picklistResponse = PrepareTestData.createScoringCriteriaResponse(picklistQuestion.Id);
        String picklistResponseString = 'Test';
        picklistResponse.Enunciado__c = picklistResponseString;
        picklistResponse.Puntuacion__c = 3;

        insert new List<SObject>{
                intervalResponse
                , intervalResponse2
                , picklistResponse
        };

        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        fundingRequest.put(CalculateAutomaticPunctuationWorkerTest.FUNDING_REQUEST_FIELD_TO_VALIDATE_INTERVAL, 2);
        fundingRequest.put(CalculateAutomaticPunctuationWorkerTest.FUNDING_REQUEST_FIELD_TO_VALIDATE_PICKLIST_FIELD, picklistResponseString);
        insert fundingRequest;

        outfunds__Review__c parentReview = PrepareTestData.createParentReviews(fundingRequest.Id, 1).get(0);
        insert parentReview;
        outfunds__Review__c childReview = PrepareTestData.createChildReviews(parentReview.Id, 1).get(0);
        insert childReview;
        WorkersManager.avoidAllWorkersExecution(false);
    }

    @IsTest
    static void testCalculateOnInsert() {
        outfunds__Review__c review = Database.query('SELECT Id, ParentReview__c,' + CalculateAutomaticPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE_INTERVAL
                + ', outfunds__FundingRequest__c FROM outfunds__Review__c WHERE ParentReview__c != NULL');
        System.assertEquals(null, review.get(CalculateAutomaticPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE_INTERVAL), 'Should be null because it has not been calculated yet');
        CalculateAutomaticPunctuationWorker worker = new CalculateAutomaticPunctuationWorker();

        Test.startTest();
        worker.bulkBeforeInsert(new List<outfunds__Review__c>{
                review
        });
        worker.beforeInsert(review);
        Test.stopTest();

        System.assertNotEquals(null, review.get(CalculateAutomaticPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE_INTERVAL), 'Should have been calculated');
        System.assertEquals(1, review.get(CalculateAutomaticPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE_INTERVAL), 'This worker should have set this value');
    }

    @IsTest
    static void testCalculateOnUpdate() {
        outfunds__Review__c review = Database.query('SELECT Id, ParentReview__c,' + CalculateAutomaticPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE_PICKLIST_FIELD
                + ', outfunds__FundingRequest__c, outfunds__Status__c FROM outfunds__Review__c WHERE ParentReview__c != NULL');
        outfunds__Review__c oldReview = review.clone(true);
        review.outfunds__Status__c = CONSTANTS.REVIEW_STATUS_SUBMITTED;
        System.assertEquals(null, review.get(CalculateAutomaticPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE_PICKLIST_FIELD), 'Should be null because it has not been calculated yet');
        CalculateAutomaticPunctuationWorker worker = new CalculateAutomaticPunctuationWorker();

        Test.startTest();
        worker.bulkBeforeUpdate(
                new List<outfunds__Review__c>{
                        oldReview
                }
                , new List<outfunds__Review__c>{
                        review
                });
        worker.beforeUpdate(oldReview, review);
        Test.stopTest();

        System.assertNotEquals(null, review.get(CalculateAutomaticPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE_PICKLIST_FIELD), 'Should have been calculated');
        System.assertEquals(3, review.get(CalculateAutomaticPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE_PICKLIST_FIELD), 'This worker should have set this value');
    }

}