/**
 * @description This worker will calculate punctuation that is configured in scoring criteria object for fields that are configured
 * @author bruno.martin@s4g.es
 * @version 12/04/2022
 */
global with sharing class CalculateAutomaticPunctuationWorker extends PunctuationAbstractWorker {

    private Map<String, List<scoring_criteria__c>> responsesByQuestionId = new Map<String, List<scoring_criteria__c>>();
    private Map<String, outfunds__Funding_Request__c> fundingRequestsByFundingRequestId = new Map<String, outfunds__Funding_Request__c>();

    /**
     * @description Calling parent constructor
     */
    global CalculateAutomaticPunctuationWorker() {
        super(String.valueOf(CalculateAutomaticPunctuationWorker.class));
    }

    public override void bulkBeforeInsert(List<SObject> newRecords) {
        this.queryInformationIfRequired((List<outfunds__Review__c>) newRecords);
    }

    public override void bulkBeforeUpdate(List<SObject> oldRecords, List<SObject> newRecords) {
        this.queryInformationIfRequired((List<outfunds__Review__c>) newRecords);
    }

    public override void beforeInsert(SObject so) {
        this.calculateAllAutomaticPunctuationFields((outfunds__Review__c) so);
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        if (S4GUtils.isChanged(so, oldSo, String.valueOf(outfunds__Review__c.outfunds__Status__c))) {
            this.calculateAllAutomaticPunctuationFields((outfunds__Review__c) so);
        }
    }

    /**
     * @description This method will call all query methods depending on its conditions
     * @param newReviews List of new reviews
     */
    private void queryInformationIfRequired(List<outfunds__Review__c> newReviews) {
        if (this.isThereAtLeastOneChildReview(newReviews)) {
            super.getFundingProgramsToProcess(newReviews);
            this.queryQuestionFieldsToCheckInFundingRequests(newReviews);
            this.queryScoringCriteriaResponses();
        }
    }

    /**
     * @description This method will return true if at least one child review is found
     * @param newReviews List of new reviews to check
     * @return True or false if child review is found
     */
    private Boolean isThereAtLeastOneChildReview(List<outfunds__Review__c> newReviews) {
        for (outfunds__Review__c review : newReviews) {
            if (String.isNotBlank(review.ParentReview__c)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description This method will query all fields to be checked
     * @param newReviews new reviews
     */
    private void queryQuestionFieldsToCheckInFundingRequests(List<outfunds__Review__c> newReviews) {
        Set<String> fundingRequestIds = new Set<String>();
        Set<String> fundingRequestFieldsToBeQueried = new Set<String>();
        Set<String> fundingProgramIdsAlreadyProcessed = new Set<String>();
        for (outfunds__Review__c review : newReviews) {
            String fundingRequestId = this.getFundingRequestIdFromReview(review);
            fundingRequestIds.add(fundingRequestId);
            outfunds__Funding_Program__c fundingProgram = PunctuationAbstractWorker.fundingProgramByFundingRequestId.get(fundingRequestId);
            if (fundingProgram != null && !fundingProgramIdsAlreadyProcessed.contains(fundingProgram.Id)) {
                for (scoring_criteria__c question : fundingProgram.Criterios_de_puntuacion__r) {
                    if (String.isNotBlank(question.campo_en_solicitud__c)) {
                        fundingRequestFieldsToBeQueried.add(question.campo_en_solicitud__c);
                    }
                }
                fundingProgramIdsAlreadyProcessed.add(fundingProgram.Id);
            }
        }
        if (!fundingRequestFieldsToBeQueried.isEmpty()) {
            String query = 'SELECT {0} FROM outfunds__Funding_Request__c WHERE Id IN :fundingRequestIds';
            query = String.format(query, new List<String>{
                    String.join(new List<String>(fundingRequestFieldsToBeQueried), ',')
            });
            for (outfunds__Funding_Request__c fundingRequest : Database.query(query)) {
                this.fundingRequestsByFundingRequestId.put(fundingRequest.Id, fundingRequest);
            }
        }
    }

    /**
     * @description This method will retrieve the funding request related to review or parent review
     * @param review Review to be used to get funding request id
     * @return Funding request id found
     */
    private String getFundingRequestIdFromReview(outfunds__Review__c review) {
        String fundingRequestId;
        if (String.isNotBlank(review.outfunds__FundingRequest__c)) {
            fundingRequestId = review.outfunds__FundingRequest__c;
        } else {
            fundingRequestId = PunctuationAbstractWorker.parentReviewById.get(review.ParentReview__c).outfunds__FundingRequest__c;
        }
        return fundingRequestId;
    }

    /**
     * @description This method will query responses using parent class information about question queried
     */
    private void queryScoringCriteriaResponses() {
        if (this.responsesByQuestionId.isEmpty()) {
            for (scoring_criteria__c response : [
                    SELECT Id, Criterio_padre__c, Enunciado__c, Valor_Min__c, Valor_max__c, Puntuacion__c
                    FROM scoring_criteria__c
                    WHERE RecordTypeId = :CONSTANTS.SCORING_CRITERIA_RT_RESPONSE
                    AND Criterio_padre__c IN :PunctuationAbstractWorker.scoringCriteriaQuestionIdsRetrieved
                    WITH SECURITY_ENFORCED
            ]) {
                if (!this.responsesByQuestionId.containsKey(response.Criterio_padre__c)) {
                    this.responsesByQuestionId.put(response.Criterio_padre__c, new List<scoring_criteria__c>());
                }
                this.responsesByQuestionId.get(response.Criterio_padre__c).add(response);
            }
        }
    }

    /**
     * @description This method will calculate all field punctuation in review using its child method
     * @param review New reviews
     */
    private void calculateAllAutomaticPunctuationFields(outfunds__Review__c review) {
        if (String.isNotBlank(review.ParentReview__c)) {
            outfunds__Funding_Program__c fundingProgram = PunctuationAbstractWorker.fundingProgramByFundingRequestId.get(
                    PunctuationAbstractWorker.parentReviewById.get(review.ParentReview__c).outfunds__FundingRequest__c
            );
            String fundingRequestId = this.getFundingRequestIdFromReview(review);
            if (fundingProgram != null) {
                for (scoring_criteria__c question : fundingProgram.Criterios_de_puntuacion__r) {
                    if (this.responsesByQuestionId.containsKey(question.Id)
                            && !this.responsesByQuestionId.get(question.Id).isEmpty()
                            && String.isNotBlank(question.campo_en_solicitud__c)
                            && String.isNotBlank(question.Campo_en_Revision__c)) {
                        review.put(question.Campo_en_Revision__c, this.calculateAutomaticPunctuation(question, fundingRequestId));
                    }
                }
            }
        }
    }

    /**
     * @description This method will calculate punctuation for a particular field taking in consideration settings made using scoring criteria object
     * @param question Scoring Criteria question to be processed
     * @param fundingRequestId Funding Request Id where with value to be compared in its field
     * @return Punctuation calculated unless there is not configured properly that will return a null
     */
    private Decimal calculateAutomaticPunctuation(scoring_criteria__c question, String fundingRequestId) {
        Decimal calculatedPunctuation;
        for (scoring_criteria__c response : this.responsesByQuestionId.get(question.Id)) {
            Object valueToBeCompared = this.fundingRequestsByFundingRequestId.get(fundingRequestId).get(question.campo_en_solicitud__c);
            if (response.Valor_max__c != null
                    && response.Valor_Min__c != null
                    && response.Valor_Min__c <= (Decimal) valueToBeCompared
                    && response.Valor_max__c >= (Decimal) valueToBeCompared) {
                calculatedPunctuation = response.Puntuacion__c;
            } else if (String.isNotBlank(response.Enunciado__c)
                    && response.Enunciado__c.equals(valueToBeCompared)) {
                calculatedPunctuation = response.Puntuacion__c;
            }
            if (calculatedPunctuation != null) {
                break;
            }
        }
        return calculatedPunctuation;
    }

}