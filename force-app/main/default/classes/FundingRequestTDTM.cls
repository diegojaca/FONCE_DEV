/**
 * @description       : 
 * @author            : Juan Gabriel Duarte
 * @group             : 
 * @last modified on  : 05-26-2022
 * @last modified by  : cesar.parra@s4g.es
 * Modifications Log 
 * Ver   Date         Author                Modification
 * 1.0   05-25-2021   Juan Gabriel Duarte   Initial Version
**/
global without sharing class FundingRequestTDTM extends AbstractWorker {

    public FundingRequestTDTM() {
        super(String.valueOf(FundingRequestTDTM.class));
    }

    public override void bulkBeforeInsert(List<SObject> newRecords) {
        FundingRequestHelperTDTM.renameFundingRequest((List<outfunds__Funding_Request__c>) newRecords);
    }

    public override void bulkBeforeUpdate(List<SObject> oldRecords, List<SObject> newRecords) {
    }

    public override void afterInsert(SObject so) {
        FundingRequestHelperTDTM.checkFundingProgram((outfunds__Funding_Request__c) so);
    }

    public override void andFinallyAfter() {
        if (Trigger.isInsert) {
            FundingRequestHelperTDTM.createRequirements();
            FundingRequestHelperTDTM.createObjectives();
            FundingRequestHelperTDTM.createParentReviewIfNecessary();
        }
    }

}