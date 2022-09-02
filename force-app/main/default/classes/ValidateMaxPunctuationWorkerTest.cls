/**
 * @description This class will test ValidateMaxPunctuationWorker
 * @author bruno.martin@s4g.es
 * @version 11/04/2022
 */
@IsTest
private class ValidateMaxPunctuationWorkerTest {

    private static final String REVIEW_FIELD_TO_VALIDATE = String.valueOf(outfunds__Review__c.Elementos_innovadores__c);

    @TestSetup
    static void prepareData() {
        outfunds__Funding_Program__c fundingProgram = PrepareTestData.createFundingPrograms(1).get(0);
        insert fundingProgram;

        S4GTestFactory.setDefaultValues(String.valueOf(scoring_criteria__c.class), String.valueOf(scoring_criteria__c.Puntaje_Max__c), Math.random() * 100);
        scoring_criteria__c scoringCriteria = PrepareTestData.createScoringCriteriaQuestion(fundingProgram.Id, ValidateMaxPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE, null);
        insert scoringCriteria;

        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        insert fundingRequest;

        outfunds__Review__c review = PrepareTestData.createParentReviews(fundingRequest.Id, 1).get(0);
        insert review;
    }

    @IsTest
    static void testPassValidation() {
        outfunds__Review__c review = Database.query('SELECT Id, outfunds__FundingRequest__c, ParentReview__c,' + ValidateMaxPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE + ' FROM outfunds__Review__c LIMIT 1');
        ValidateMaxPunctuationWorker worker = new ValidateMaxPunctuationWorker();

        Test.startTest();
        worker.bulkBeforeInsert(new List<outfunds__Review__c>{
                review
        });
        try {
            worker.beforeInsert(review);
        } catch (Exception e) {
            System.assert(false, 'Should have not thrown any exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testFailValidation() {
        outfunds__Review__c oldReview = Database.query('SELECT Id, outfunds__FundingRequest__c, ParentReview__c,' + ValidateMaxPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE + ' FROM outfunds__Review__c LIMIT 1');
        scoring_criteria__c scoringCriteria = [SELECT Id, Puntaje_Max__c, Campo_en_Revision__c FROM scoring_criteria__c WHERE Puntaje_Max__c != NULL LIMIT 1];
        outfunds__Review__c newReview = oldReview.clone(true);
        newReview.put(ValidateMaxPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE, scoringCriteria.Puntaje_Max__c + 1);
        ValidateMaxPunctuationWorker worker = new ValidateMaxPunctuationWorker();

        Test.startTest();
        worker.bulkBeforeUpdate(new List<outfunds__Review__c>{
                oldReview
        }, new List<outfunds__Review__c>{
                newReview
        });
        try {
            worker.beforeUpdate(oldReview, newReview);
        } catch (Exception e) {
            System.assert(false, 'Should have not thrown any exception');
        }
        Test.stopTest();

        System.assert(newReview.hasErrors(), 'Should have an error set by this worker');
        System.assertEquals(newReview.getErrors().get(0).getFields().get(0), ValidateMaxPunctuationWorkerTest.REVIEW_FIELD_TO_VALIDATE, 'This field should have an error');
        System.assertEquals(newReview.getErrors().get(0).getMessage(), Label.VMPW_ErrorMessage + ' ' + scoringCriteria.Puntaje_Max__c, 'Should have this error message');
    }
}