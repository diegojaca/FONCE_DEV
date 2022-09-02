/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 09-13-2021
 * @last modified by  : cesar.parra@s4g.es
**/
trigger TDTM_FundingRequest on outfunds__Funding_Request__c (before insert, before update, before delete, after insert,
        after update, after delete, after undelete) {
    npsp.TDTM_Config_API.run(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete,
            Trigger.isUnDelete, Trigger.new, Trigger.old, Schema.Sobjecttype.outfunds__Funding_Request__c);
}