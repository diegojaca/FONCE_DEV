/**
 * @description 
 * @author bruno.martin@s4g.es
 * @version 27/07/2022
 */
trigger ProgramTrigger on pmdm__Program__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    npsp.TDTM_Config_API.run(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete,
            Trigger.isUndelete, Trigger.new, Trigger.old, Schema.SObjectType.pmdm__Program__c);
}