/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-06-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class ContentDocumentLinkHelperTDTMTest {

    @TestSetup
    static void prepareData() {
        Section__c section = PrepareTestData.createImageSection();
        insert section;

        ContentVersion content = PrepareTestData.createContentVersion();
        insert content;

        content = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id = :content.Id];
        ContentDocumentLink contentLink = PrepareTestData.createContentDocumentLink(section.Id, content.ContentDocumentId);
        insert contentLink;
    }

    @isTest
    public static void createPublicLinkForFileTest() {
        Section__c section = [SELECT Id,URL__c FROM Section__c LIMIT 1];
        ContentDocumentLink contentDocumentLink = [SELECT Id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :section.Id];

        Test.startTest();
        ContentDocumentLinkHelperTDTM.createPublicLinkForFile(contentDocumentLink);
        Test.stopTest();

        section = [SELECT Id,URL__c FROM Section__c LIMIT 1];
        System.assert(String.isNotBlank(section.URL__c), 'EL campo URL_-c se encuentra vacío');
    }
}