/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 06-02-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
@IsTest
public with sharing class ContentDocumentLinkTDTMTest {

    @IsTest
    static void afterInsertOk(){

        ContentDocumentLinkTDTM worker = new ContentDocumentLinkTDTM();

        Section__c section = PrepareTestData.createImageSection();
        insert section;

        ContentVersion content = PrepareTestData.createContentVersion();
        insert content;

        content = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id = :content.Id];
        ContentDocumentLink contentLink = PrepareTestData.createContentDocumentLink(section.Id, content.ContentDocumentId);
        insert contentLink;

        Test.startTest();
            worker.afterInsert(contentLink);
        Test.stopTest();

        System.assertNotEquals(null, contentLink.Id, 'Must be not null id');
    }
}