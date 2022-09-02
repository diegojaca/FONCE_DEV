/**
 * @description This abstract class will provide Punctuation Workers with common methods
 * @author bruno.martin@s4g.es
 * @version 12/04/2022
 */
global abstract with sharing class PunctuationAbstractWorker extends AbstractWorker {

    public static Map<String, outfunds__Funding_Program__c> fundingProgramByFundingRequestId = new Map<String, outfunds__Funding_Program__c>();
    public static Set<String> reviewFieldsApiNamesInLowerCase = Schema.SObjectType.outfunds__Review__c.fields.getMap().keySet();
    public static Set<String> scoringCriteriaQuestionIdsRetrieved = new Set<String>();
    public static Map<String, outfunds__Review__c> parentReviewById = new Map<String, outfunds__Review__c>();

    /**
     * @description Set worker Id
     * @param workerId Set child worker Id
     */
    global PunctuationAbstractWorker(String workerId) {
        super(workerId);
    }

    /**
    * @description This method will query all funding programs information required in this worker
    * @param newReviews new records
    */
    protected void getFundingProgramsToProcess(List<outfunds__Review__c> newReviews) {
        if (PunctuationAbstractWorker.fundingProgramByFundingRequestId.isEmpty()) {
            Set<String> fundingRequests = new Set<String>();
            Set<String> parentReviewIds = new Set<String>();
            for (outfunds__Review__c review : newReviews) {
                if (String.isNotBlank(review.outfunds__FundingRequest__c)) {
                    fundingRequests.add(review.outfunds__FundingRequest__c);
                    parentReviewIds.add(review.Id);
                }
                if (String.isNotBlank(review.ParentReview__c)) {
                    parentReviewIds.add(review.ParentReview__c);
                }
            }
            for (outfunds__Review__c parentReview : this.queryParentReviews(parentReviewIds)) {
                fundingRequests.add(parentReview.outfunds__FundingRequest__c);
                PunctuationAbstractWorker.parentReviewById.put(parentReview.Id, parentReview);
            }
            for (outfunds__Funding_Program__c fundingProgram : [
                    SELECT Id
                            , (
                            SELECT Id
                            FROM outfunds__FundingRequests__r
                            WHERE Id IN :fundingRequests
                    )
                            , (
                            SELECT Id, Puntaje_Max__c, Campo_en_Revision__c, campo_en_solicitud__c
                            FROM Criterios_de_puntuacion__r
                            WHERE RecordTypeId = :CONSTANTS.SCORING_CRITERIA_RT_QUESTION
                    )
                    FROM outfunds__Funding_Program__c
                    WHERE Id IN (
                            SELECT outfunds__FundingProgram__c
                            FROM outfunds__Funding_Request__c
                            WHERE Id IN :fundingRequests
                    )
                    WITH SECURITY_ENFORCED
            ]) {
                for (outfunds__Funding_Request__c request : fundingProgram.outfunds__FundingRequests__r) {
                    PunctuationAbstractWorker.fundingProgramByFundingRequestId.put(request.Id, fundingProgram);
                }
                for (scoring_criteria__c scoringCriteria : fundingProgram.Criterios_de_puntuacion__r) {
                    PunctuationAbstractWorker.scoringCriteriaQuestionIdsRetrieved.add(scoringCriteria.Id);
                }
            }
        }
    }

    /**
     * @description This method will be used to query parent reviews with its child reviews
     * @param parentReviewIds parentReviewsIds
     * @return Parent reviews queried
     */
    protected List<outfunds__Review__c> queryParentReviews(Set<String> parentReviewIds) {
        return Database.query(
                'SELECT Id, outfunds__FundingRequest__c, outfunds__Status__c'
                        + ' , (SELECT '
                        + String.join(S4GUtils.getAllFieldsInSObject(String.valueOf(outfunds__Review__c.class), true, false), ',')
                        + ' FROM Reviews__r)'
                        + ' FROM outfunds__Review__c'
                        + ' WHERE Id IN :parentReviewIds'
                        + ' AND outfunds__FundingRequest__c != NULL'
        );
    }

}