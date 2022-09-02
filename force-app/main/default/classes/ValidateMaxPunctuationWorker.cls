/**
 * @description This worker will validate max punctuation set in fields in review records for manually selected punctuation
 * @author bruno.martin@s4g.es
 * @version 11/04/2022
 */
global with sharing class ValidateMaxPunctuationWorker extends PunctuationAbstractWorker {

    /**
     * @description Set worker Id
     */
    global ValidateMaxPunctuationWorker() {
        super(String.valueOf(ValidateMaxPunctuationWorker.class));
    }

    public override void bulkBeforeInsert(List<SObject> newRecords) {
        super.getFundingProgramsToProcess((List<outfunds__Review__c>) newRecords);
    }

    public override void bulkBeforeUpdate(List<SObject> oldRecords, List<SObject> newRecords) {
        super.getFundingProgramsToProcess((List<outfunds__Review__c>) newRecords);
    }

    public override void beforeInsert(SObject so) {
        this.checkFieldsDefinedInProgram((outfunds__Review__c) so, null);
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        this.checkFieldsDefinedInProgram((outfunds__Review__c) so, oldSo);
    }

    /**
     * @description This method will check every field defined in scoring criteria records related to funding program
     * @param newReview new review
     * @param oldSo old review or null in insert
     */
    private void checkFieldsDefinedInProgram(outfunds__Review__c newReview, SObject oldSo) {
        outfunds__Funding_Program__c program;
        if (String.isNotBlank(newReview.outfunds__FundingRequest__c)) {
            program = PunctuationAbstractWorker.fundingProgramByFundingRequestId.get(newReview.outfunds__FundingRequest__c);
        } else {
            program = PunctuationAbstractWorker.fundingProgramByFundingRequestId.get(
                    PunctuationAbstractWorker.parentReviewById.get(newReview.ParentReview__c).outfunds__FundingRequest__c
            );
        }
        if (program != null) {
            for (scoring_criteria__c scoringCriteria : program.Criterios_de_puntuacion__r) {
                if (scoringCriteria.Puntaje_Max__c != null
                        && String.isNotBlank(scoringCriteria.Campo_en_Revision__c)
                        && PunctuationAbstractWorker.reviewFieldsApiNamesInLowerCase.contains(scoringCriteria.Campo_en_Revision__c.toLowerCase())) {
                    if (oldSo == null || (oldSo != null && S4GUtils.isChanged(newReview, oldSo, scoringCriteria.Campo_en_Revision__c))) {
                        this.checkValueSetInField(newReview, scoringCriteria);
                    }
                }
            }
        }
    }

    /**
     * @description This method will set error in field defined in scoring criteria if maximum punctuation is exceeded
     * @param newReview new review
     * @param scoringCriteria scoring criteria containing maximum punctuation information and in which field is applied
     */
    private void checkValueSetInField(outfunds__Review__c newReview, scoring_criteria__c scoringCriteria) {
        if ((Decimal) newReview.get(scoringCriteria.Campo_en_Revision__c) > scoringCriteria.Puntaje_Max__c && !BypassManager.skipValidationRules()) {
            newReview.addError(scoringCriteria.Campo_en_Revision__c, Label.VMPW_ErrorMessage + ' ' + scoringCriteria.Puntaje_Max__c);
        }
    }

}