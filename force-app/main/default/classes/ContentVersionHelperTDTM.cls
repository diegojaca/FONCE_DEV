/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 11-17-2021
 * @last modified by  : cesar.parra@s4g.es
 **/
public without sharing class ContentVersionHelperTDTM {

    private static Map<Id, ContentDocumentLink> contentDocumentLinkByContentDocumentId = new Map<Id, ContentDocumentLink>();
    private static Map<Id, outfunds__Requirement__c> requirementById = new Map<Id, outfunds__Requirement__c>();

    public ContentVersionHelperTDTM() {

    }

    public static void createContentDocumentLink(ContentVersion contentVersion) {
        System.debug('createContentDocumentLink');
        if(String.isNotBlank(contentVersion.Guest_Record_fileupload__c)){
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
            contentDocumentLink.LinkedEntityId = contentVersion.Guest_Record_fileupload__c;
            // ShareType is either 'V', 'C', or 'I'
            // V = Viewer, C = Collaborator, I = Inferred
            contentDocumentLink.ShareType = 'V';
            ContentVersionHelperTDTM.contentDocumentLinkByContentDocumentId.put(contentDocumentLink.ContentDocumentId, contentDocumentLink);
            ContentVersionHelperTDTM.requirementById.put(contentVersion.Guest_Record_fileupload__c, new outfunds__Requirement__c(Id = contentVersion.Guest_Record_fileupload__c, outfunds__Status__c = 'In Progress	'));
        }
        
    }

    public static void insertContentDocumentLinks() {
        insert ContentVersionHelperTDTM.contentDocumentLinkByContentDocumentId.values();
        ContentVersionHelperTDTM.contentDocumentLinkByContentDocumentId.clear();
    }

    public static void updateRequirement() {
        update ContentVersionHelperTDTM.requirementById.values();
        ContentVersionHelperTDTM.requirementById.clear();
    }
}