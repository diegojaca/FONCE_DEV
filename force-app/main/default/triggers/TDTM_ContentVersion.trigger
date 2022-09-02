/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 11-16-2021
 * @last modified by  : cesar.parra@s4g.es
**/
trigger TDTM_ContentVersion on ContentVersion (before insert, before update, before delete, after insert, 
after update, after delete, after undelete) {

npsp.TDTM_Config_API.run(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, 
    Trigger.isUnDelete, Trigger.new, Trigger.old, Schema.Sobjecttype.ContentVersion);
}