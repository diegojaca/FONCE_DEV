/**
 * @description       : 
 * @author            : juangabriel.duarte@s4g.es 
 * @group             : 
 * @last modified on  : 11-18-2021
 * @last modified by  : juangabriel.duarte@s4g.es 
**/
trigger TDTM_ContentDocumentLink on ContentDocumentLink (before insert, before update, before delete, after insert, 
after update, after delete, after undelete) {

npsp.TDTM_Config_API.run(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, 
    Trigger.isUnDelete, Trigger.new, Trigger.old, Schema.Sobjecttype.ContentDocumentLink);
}