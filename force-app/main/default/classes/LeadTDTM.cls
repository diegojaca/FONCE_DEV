/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 04-28-2022
 * @last modified by  : cesar.parra@s4g.es
**/
global without sharing class LeadTDTM extends AbstractWorker{
    
    public LeadTDTM() {
        super(String.valueOf(LeadTDTM.class));
    }
    
    public override void bulkAfterInsert(List<SObject> newRecords){
        LeadHelperTDTM.prepareLeads((List<Lead>) newRecords);
    }

    public override void andFinallyAfter(){  
        if (Trigger.isInsert) {    
            LeadHelperTDTM.assignmentRule();
        }
    }

}