/**
 * @description       : 
 * @author            : juangabriel.duarte@s4g.es 
 * @group             : 
 * @last modified on  : 04-06-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class ContentDocumentLinkHelperTDTM {
    public ContentDocumentLinkHelperTDTM() {

    }

    public static void createPublicLinkForFile(ContentDocumentLink contentDocumentLink){
       
        String cdlIdPrefix = String.valueOf(contentDocumentLink.LinkedEntityId).substring(0,3);

        if(cdlIdPrefix==getSectionKeyPrefix()){

            ContentVersion contentVersion = [SELECT Id,contentDocumentId FROM ContentVersion WHERE contentDocumentId =: contentDocumentLink.contentDocumentid];
            
            ContentDistribution contentDistribution = createContentDistribution(contentVersion.Id);

            Database.SaveResult[] srList = Database.insert(new List<contentDistribution>{contentDistribution}, true);
            Id contentDistributionId;
            
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    contentDistributionId = sr.getId();
                }
            }

            ContentDistribution contentDistributionResult = [SELECT DistributionPublicUrl, ContentDownloadUrl 
                                                                    FROM ContentDistribution 
                                                                    WHERE Id=:contentDistributionId];
                Section__c section = new Section__c(Id=contentDocumentLink.LinkedEntityId, URL__c=contentDistributionResult.ContentDownloadUrl);
                update section;
        }
    }
    
    
    public static ContentDistribution createContentDistribution(Id contentVersionId){
        ContentDistribution newDist = new ContentDistribution();
        newDist.ContentVersionId = contentVersionId;
        newDist.Name = String.valueOf(contentVersionId);
        newDist.PreferencesNotifyOnVisit = false;
        newDist.PreferencesAllowViewInBrowser = true;
        newDist.PreferencesAllowOriginalDownload=true;
        system.debug('createContentDistribution creted');
        return newDist;
    }

    public static String getSectionKeyPrefix(){
        schema.sObjectType sObjType = Schema.getGlobalDescribe().get('Section__c');
        return (sObjType.getDescribe().getKeyPrefix());
    }
}