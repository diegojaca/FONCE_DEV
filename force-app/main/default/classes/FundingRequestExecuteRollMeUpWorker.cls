/**
 * @description This worker will execute RollMeUp Package
 * @author bruno.martin@s4g.es
 * @version 08/04/2022
 */
global with sharing class FundingRequestExecuteRollMeUpWorker extends AbstractWorker{

    global FundingRequestExecuteRollMeUpWorker(){
        super(String.valueOf(FundingRequestExecuteRollMeUpWorker.class));
    }

    public override void andFinallyAfter() {
        if (!CONSTANTS.COMMUNITY_USER_TYPES.contains(UserInfo.getUserType())) {
            RollupDetector detector = new RollupDetector();

            detector.checkRecordsToRollup(super.oldRecords, super.newRecords);
            detector.processRollupCalculation();
            detector.cleanUp();
        }
    }

}