/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 06-01-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
@IsTest
public with sharing class ContentVersionTDTMTest {

    private static final String  TEST_ACCOUNT_NAME = 'test accName';
    
    @IsTest
    static void afterInsertOk(){

        insert PrepareTestData.createHandler(String.valueOf(ContentVersion.class), String.valueOf(ContentVersionTDTM.class));

        outfunds__Funding_Program__c fundingProgram = PrepareTestData.createFundingPrograms(1).get(0);
        insert fundingProgram;
        
        outfunds__Requirement__c requirement = PrepareTestData.createRequirements(fundingProgram.Id, 1).get(0);
        insert requirement;

        ContentVersion contentVersion = PrepareTestData.createContentVersion();
        contentVersion.Guest_Record_fileupload__c = requirement.Id;

        Test.startTest();
            insert contentVersion;
        Test.stopTest();

        System.assertNotEquals(null, contentVersion.Id, 'The Id must not be null');
    }

}