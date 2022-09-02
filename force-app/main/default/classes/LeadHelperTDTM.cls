/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 04-28-2022
 * @last modified by  : cesar.parra@s4g.es
**/
public without sharing class LeadHelperTDTM {

    private static List<Lead> leadsToUpdate = new List<Lead>();

    public static void prepareLeads(List<Lead> leads){
        for(Lead lead : leads){
            LeadHelperTDTM.leadsToUpdate.add(new Lead(Id = lead.Id, RecordTypeId = lead.RecordTypeId));
        }
    }

    public static void assignmentRule(){    
        AssignmentRule assignmentRule = new AssignmentRule();
        assignmentRule = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Lead' AND Active = TRUE AND Name = :CONSTANTS.ASSIGNMENT_RULE_NAME].get(0);

        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId = assignmentRule.Id;
        Database.update(LeadHelperTDTM.leadsToUpdate, dmlOpts);
    }

}