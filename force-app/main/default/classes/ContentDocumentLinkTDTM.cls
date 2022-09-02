/**
 * @description       : 
 * @author            : juangabriel.duarte@s4g.es 
 * @group             : 
 * @last modified on  : 04-06-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global without sharing class ContentDocumentLinkTDTM extends AbstractWorker{

    public ContentDocumentLinkTDTM() {
        super(String.valueOf(ContentDocumentLinkTDTM.class));
    }

    public override void afterInsert(SObject so){
        ContentDocumentLinkHelperTDTM.createPublicLinkForFile((ContentDocumentLink)so);
    }

    // public override void afterInsert(SObject so){
    //     ContentDocumentLinkHelperTDTM.createPublicLinkForFile((ContentVersion)so);
    // }
}