/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 06-30-2022
 * @last modified by  : cesar.parra@s4g.es
**/
@IsTest
public with sharing class FundingRequestHelperTDTMTest {

    private static final String  TEST_LASTNAME = 'test lastname';
    private static final String  DOC_NUMBER_EXT_ID = '123456789';
    private static final String  EXT_ID = 'test_2022';
    
    @TestSetup
    static void makeData(){

        Contact contact = PrepareTestData.createContact(TEST_LASTNAME);
        contact.N_mero_de_Documento__c = DOC_NUMBER_EXT_ID;
        insert contact;
        
        outfunds__Funding_Program__c fundingProgram = PrepareTestData.createFundingPrograms(1).get(0);
        fundingProgram.DoesFundingRequestRequireReview__c = true;
        insert fundingProgram;

        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        fundingRequest.External_ID__c = EXT_ID;
        fundingRequest.outfunds__Applying_Contact__c = contact.Id;
        insert fundingRequest;

        outfunds__Requirement__c requirement = PrepareTestData.createRequirements(fundingProgram.Id, 1).get(0);
        requirement.RequirementCategory__c = 'Requisito de Solicitud';
        insert requirement;

        Objective__c objective = PrepareTestData.createObjectives(fundingRequest.Id, 1).get(0);
        insert objective;
    }

    @IsTest
    static void renameFundingRequestOk(){

        outfunds__Funding_Request__c fundingrequest = [SELECT Name, outfunds__Applying_Contact__c, outfunds__FundingProgram__c FROM outfunds__Funding_Request__c LIMIT 1];
        String originalName = fundingrequest.Name;

        Test.startTest();
            FundingRequestHelperTDTM.renameFundingRequest(new List<outfunds__Funding_Request__c>{fundingrequest});
        Test.stopTest();

        System.AssertNotEquals(originalName, fundingrequest.Name, 'Funding request does not renamed');
    }
}