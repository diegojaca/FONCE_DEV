/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 11-17-2021
 * @last modified by  : cesar.parra@s4g.es
**/
global without sharing class ContentVersionTDTM extends AbstractWorker{
    
    public ContentVersionTDTM() {
        super(String.valueOf(ContentVersionTDTM.class));
    }
    
    public override void afterInsert(SObject so){
        ContentVersionHelperTDTM.createContentDocumentLink((ContentVersion)so);
    }

    public override void andFinallyAfter(){        
        
        if (Trigger.isInsert) {             
            ContentVersionHelperTDTM.insertContentDocumentLinks();
            ContentVersionHelperTDTM.updateRequirement();
        }
    }
}