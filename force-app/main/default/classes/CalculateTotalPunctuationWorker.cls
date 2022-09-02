/**
 * @description This worker will calculate total punctuation in review object
 * @author bruno.martin@s4g.es
 * @version 12/04/2022
 */
global with sharing class CalculateTotalPunctuationWorker extends PunctuationAbstractWorker {

    private final List<String> statusesToBeValidated = new List<String>{
            CONSTANTS.REVIEW_STATUS_SUBMITTED
            , CONSTANTS.REVIEW_STATUS_REVISED
    };
    private Set<String> parentReviewsWithChildrenRecalculated = new Set<String>();
    private Set<String> parentReviewsInTrigger = new Set<String>();

    /**
     * @description Set worker Id
     */
    global CalculateTotalPunctuationWorker() {
        super(String.valueOf(CalculateTotalPunctuationWorker.class));
    }

    public override void bulkBeforeInsert(List<SObject> newRecords) {
        super.getFundingProgramsToProcess((List<outfunds__Review__c>) newRecords);
    }

    public override void bulkBeforeUpdate(List<SObject> oldRecords, List<SObject> newRecords) {
        super.getFundingProgramsToProcess((List<outfunds__Review__c>) newRecords);
    }

    public override void beforeInsert(SObject so) {
        outfunds__Review__c newReview = (outfunds__Review__c) so;
        this.calculateTotalPunctuation(newReview);
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        outfunds__Review__c newReview = (outfunds__Review__c) so;
        this.calculateTotalPunctuation(newReview);
    }

    public override void andFinallyAfter() {
        this.updateParentRecordsIfNecessary();
    }

    /**
     * @description This method will decide which type of calculation needs new review
     * @param newReview new review
     */
    private void calculateTotalPunctuation(outfunds__Review__c newReview) {
        if (String.isNotBlank(newReview.ParentReview__c)) {
            this.calculateTotalPunctuation(newReview, PunctuationAbstractWorker.parentReviewById.get(newReview.ParentReview__c).outfunds__FundingRequest__c);
            this.parentReviewsWithChildrenRecalculated.add(newReview.ParentReview__c);
        } else if (String.isNotBlank(newReview.outfunds__FundingRequest__c)) {
            if (!this.statusesToBeValidated.contains(newReview.outfunds__Status__c)) {
                this.calculateParentAverageFieldsFromChildFields(newReview);
            }
            this.calculateTotalPunctuation(newReview, newReview.outfunds__FundingRequest__c);
            this.parentReviewsInTrigger.add(newReview.Id);
        }
    }

    /**
    * @description This method will calculate total punctuation based on scoring criteria for child reviews.
    * If status is one of the closed ones and one punctuation is not set it will add an error to the record
    * @param newReview new review
    * @param fundingRequestId funding request id to be used to search funding program
    */
    private void calculateTotalPunctuation(outfunds__Review__c newReview, String fundingRequestId) {
        outfunds__Funding_Program__c program = PunctuationAbstractWorker.fundingProgramByFundingRequestId.get(fundingRequestId);
        if (program != null) {
            Decimal totalPoints = 0;
            for (scoring_criteria__c scoringCriteria : program.Criterios_de_puntuacion__r) {
                if (String.isNotBlank(scoringCriteria.Campo_en_Revision__c)
                        && PunctuationAbstractWorker.reviewFieldsApiNamesInLowerCase.contains(scoringCriteria.Campo_en_Revision__c.toLowerCase())) {
                    if (newReview.get(scoringCriteria.Campo_en_Revision__c) != null) {
                        totalPoints += (Decimal) newReview.get(scoringCriteria.Campo_en_Revision__c);
                    } else if (this.statusesToBeValidated.contains(newReview.outfunds__Status__c) && !BypassManager.skipValidationRules()) {
                        newReview.addError(
                                String.valueOf(outfunds__Review__c.outfunds__Status__c)
                                , 'Para finalizar la evaluación todos los campos de puntuación tienen que estar completos'
                        );
                        break;
                    }
                }
            }
            newReview.Puntaje_total__c = totalPoints;
        }
    }

    /**
     * @description This method will calculate average fields in parent from child records fields
     * @param newReview new parent review
     */
    private void calculateParentAverageFieldsFromChildFields(outfunds__Review__c newReview) {
        outfunds__Funding_Program__c program = PunctuationAbstractWorker.fundingProgramByFundingRequestId.get(newReview.outfunds__FundingRequest__c);
        List<outfunds__Review__c> childReviews = PunctuationAbstractWorker.parentReviewById.get(newReview.Id)?.Reviews__r;
        if (program == null || childReviews == null || childReviews.isEmpty()) {
            return;
        }
        for (scoring_criteria__c scoringCriteria : program.Criterios_de_puntuacion__r) {
            if (String.isNotBlank(scoringCriteria.Campo_en_Revision__c)
                    && PunctuationAbstractWorker.reviewFieldsApiNamesInLowerCase.contains(scoringCriteria.Campo_en_Revision__c.toLowerCase())) {
                Decimal fieldTotalPoints = this.calculateParentFieldAverageFromChildField(childReviews, scoringCriteria);
                newReview.put(scoringCriteria.Campo_en_Revision__c, fieldTotalPoints);
            }
        }
    }

    /**
     * @description This method will calculate field average using child reviews to set parent fields which are average values.
     * @param childReviews Child reviews for this parent
     * @param scoringCriteria Scoring criteria to be used
     * @return Average value calculated
     */
    private Decimal calculateParentFieldAverageFromChildField(List<outfunds__Review__c> childReviews, scoring_criteria__c scoringCriteria) {
        Decimal fieldTotalPoints = 0;
        Integer totalFieldsAddedFromReviews = 0;
        for (outfunds__Review__c childReview : childReviews) {
            if (childReview.get(scoringCriteria.Campo_en_Revision__c) != null) {
                fieldTotalPoints += (Decimal) childReview.get(scoringCriteria.Campo_en_Revision__c);
                totalFieldsAddedFromReviews += 1;
            }
        }
        if (totalFieldsAddedFromReviews != 0) {
            fieldTotalPoints = (fieldTotalPoints / totalFieldsAddedFromReviews).setScale(2);
        } else {
            fieldTotalPoints = null;
        }
        return fieldTotalPoints;
    }

    /**
     * @description Update parent reviews to recalculate its totals
     */
    private void updateParentRecordsIfNecessary() {
        if (!this.parentReviewsWithChildrenRecalculated.isEmpty()) {
            List<outfunds__Review__c> parentReviewsToUpdate = new List<outfunds__Review__c>();
            Set<String> parentReviewIds = new Set<String>();
            for (String parentReviewId : this.parentReviewsWithChildrenRecalculated) {
                if (!this.parentReviewsInTrigger.contains(parentReviewId)) {
                    outfunds__Review__c parentReview = new outfunds__Review__c(
                            Id = parentReviewId
                            , Puntaje_total__c = null
                    );
                    if (PunctuationAbstractWorker.parentReviewById.get(parentReviewId).outfunds__Status__c
                            .equals(CONSTANTS.REVIEW_STATUS_NOT_STARTED)) {
                        parentReview.outfunds__Status__c = CONSTANTS.REVIEW_STATUS_IN_PROGRESS;
                    }
                    parentReviewsToUpdate.add(parentReview);
                    parentReviewIds.add(parentReviewId);
                }
            }
            if (!parentReviewsToUpdate.isEmpty()) {
                this.refreshParentReviewData(parentReviewIds);
                WorkersManager.avoidWorkerExecution(String.valueOf(CalculateAutomaticPunctuationWorker.class), String.valueOf(CalculateTotalPunctuationWorker.class), true);
                update parentReviewsToUpdate;
                WorkersManager.avoidWorkerExecution(String.valueOf(CalculateAutomaticPunctuationWorker.class), String.valueOf(CalculateTotalPunctuationWorker.class), false);
            }
        }
    }

    /**
     * @description This method will refresh cached data in parent worker
     * @param parentReviewIds Parent reviews to be updated
     */
    private void refreshParentReviewData(Set<String> parentReviewIds) {
        for (outfunds__Review__c parentReview : super.queryParentReviews(parentReviewIds)) {
            PunctuationAbstractWorker.parentReviewById.put(parentReview.Id, parentReview);
        }
    }

}