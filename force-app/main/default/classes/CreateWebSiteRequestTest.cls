/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 07-21-2022
 * @last modified by  : cesar.parra@s4g.es
**/
@IsTest
public with sharing class CreateWebSiteRequestTest {

    private static final String  TEST_LASTNAME = 'test lastname';
    private static final String  TEST_ACCOUNT_NAME = 'test accName';
    private static final String  DOC_NUMBER_EXT_ID = '123456789';
    private static final String  PROGRAM_NAME = 'test_program_name';
    private static final String  PROGRAM_TYPE = 'UNIDIVERSIDAD';
    private static final String  FND_REQUEST_RECORDTYPE_ALUMN_SCHOLARCHIP = 'AlumniScholarships';
    private static final String  EXT_ID = 'test_2022';
    private static final String  TYPE_REQUIREMENT_PRELIMINARY_APP = 'Preliminary Application';		
    private static final String  STATUS_IN_PROGRESS = 'In Progress';
    private static final String  CONTACT_PORTAL_LAYOUT_RETRIEVE = 'Contact-Contact Layout Portal';
    private static final String PRIVATE_PORTAL = 'private';
    private static final String PERSON_PORTAL = 'person';
    private static final String UNIVERSITY_PORTAL = 'university';
    private static final String CAMPAIGN_NAME = 'Test campaign name';
    private static final String LEAD_LAST_NAME = 'Test Lead lastName';
    private static final String LEAD_INDIVIDUAL_COMPANY = 'Individuo';
    private static final String LEAD_PERSON_RT = 'Person';
    
    
    @TestSetup
    static void makeData(){

        Contact contact = PrepareTestData.createContact(TEST_LASTNAME);
        contact.N_mero_de_Documento__c = DOC_NUMBER_EXT_ID;
        insert contact;

        Account account = PrepareTestData.createAccount(TEST_ACCOUNT_NAME);
        account.npe01__One2OneContact__c = contact.Id;
        insert account;
        
        outfunds__Funding_Program__c fundingProgram = PrepareTestData.createFundingPrograms(1).get(0);
        fundingProgram.Tipo_de_Programas_de_Becas__c = PROGRAM_TYPE;
        fundingProgram.IsForUniversity__c = false;
        fundingProgram.Nombre_Convocatoria__c = PROGRAM_NAME;
        insert fundingProgram;

        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        fundingRequest.External_ID__c = EXT_ID;
        insert fundingRequest;

        outfunds__Requirement__c requirement = PrepareTestData.createRequirements(fundingProgram.Id, 1).get(0);
        requirement.outfunds__Type__c = TYPE_REQUIREMENT_PRELIMINARY_APP;
        requirement.outfunds__Funding_Request__c = fundingRequest.Id;
        requirement.outfunds__Status__c = STATUS_IN_PROGRESS;
        insert requirement;

        Section__c section = PrepareTestData.createImageSection();
        section.RecordTypeId = CONSTANTS.SECTION_RT_MAIN;
        section.ProgramaBeca__c = fundingProgram.Id;
        insert section;

        insert PrepareTestData.createResources(fundingRequest.Id, 1).get(0);

    }

    @Istest
    static void createContactOk(){

        Contact contact = [SELECT N_mero_de_Documento__c FROM Contact LIMIT 1];

        Test.startTest();
            CreateWebSiteRequest.createContact(contact);
        Test.stopTest();

        Contact[] contacts = [SELECT N_mero_de_Documento__c FROM Contact];
        System.assertEquals(1, contacts.size(), 'Must be return one record');
        System.assertEquals(DOC_NUMBER_EXT_ID, contacts[0].N_mero_de_Documento__c, 'The document number is not match');
    }

    @IsTest
    static void createFundingRequestOk(){

        outfunds__Funding_Request__c fundingRequest = [SELECT External_ID__c FROM outfunds__Funding_Request__c LIMIT 1];

        Test.startTest();
            CreateWebSiteRequest.createFundingRequest(fundingRequest, FND_REQUEST_RECORDTYPE_ALUMN_SCHOLARCHIP);
        Test.stopTest();

        fundingRequest = [SELECT Recordtype.DeveloperName FROM outfunds__Funding_Request__c LIMIT 1];
        System.assertEquals(FND_REQUEST_RECORDTYPE_ALUMN_SCHOLARCHIP, fundingRequest.Recordtype.DeveloperName, 'Recordtype name don´t match');
    }

    @Istest
    static void getChildFundingProgramsOk(){

        Test.startTest();
            List<outfunds__Funding_Program__c> fundingProgram = CreateWebSiteRequest.getChildFundingPrograms();
        Test.stopTest();

        System.assertEquals(1, fundingProgram.size(), 'Must be return one record');
    }

    @IsTest
    static void getFundingProgramOk(){

        outfunds__Funding_Program__c fundingProgram = [SELECT Id FROM outfunds__Funding_Program__c WHERE Nombre_Convocatoria__c = :PROGRAM_NAME LIMIT 1];

        Test.startTest();
            outfunds__Funding_Program__c fundingProgramResponse = CreateWebSiteRequest.getFundingProgram(PROGRAM_NAME);
        Test.stopTest();

        System.assertEquals(fundingProgram.Id, fundingProgramResponse.Id, 'The ids don´t match');
    }

    @IsTest
    static void getFundingRequestRecordTypesOk(){

        Test.startTest();
            List<RecordType> recordtypes = CreateWebSiteRequest.getFundingRequestRecordTypes();
        Test.stopTest();

        System.assertNotEquals(0, recordtypes.size(), 'Must be return recordtypes');
    }

    @IsTest
    static void getTypesProgramsOk(){

        List<Type__mdt> types = [SELECT TypeValue__c FROM Type__mdt WHERE IsForUniversityPersons__c = false];

        Test.startTest();
            List<Type__mdt> typesResult = CreateWebSiteRequest.getTypesPrograms(false);
        Test.stopTest();

        System.assertEquals(types.size(), typesResult.size(), 'The number of records is not equals');
    }

    @IsTest
    static void getFieldsOK(){

        Field_Definition__mdt fieldDefinitionMtd = [SELECT Field__r.QualifiedApiName, TypeLayout__r.TypeValue__c, Entity__r.QualifiedApiName FROM Field_Definition__mdt LIMIT 1];

        Test.startTest();
            Field_Definition__mdt[] fieldDefinitionMtdResult = CreateWebSiteRequest.getFields(fieldDefinitionMtd.TypeLayout__r.TypeValue__c, fieldDefinitionMtd.Entity__r.QualifiedApiName);
        Test.stopTest();

        System.assertEquals(fieldDefinitionMtd.Entity__r.QualifiedApiName, fieldDefinitionMtdResult[0].Entity__r.QualifiedApiName, 'The Entity api names don´t match');
        System.assertEquals(fieldDefinitionMtd.Field__r.QualifiedApiName, fieldDefinitionMtdResult[0].Field__r.QualifiedApiName, 'The field api names don´t match');
    }

    @Istest
    static void getRequirementsTypeAndStatusNullOk(){

        outfunds__Funding_Request__c fundingRequest = [SELECT External_ID__c FROM outfunds__Funding_Request__c LIMIT 1];

        Test.startTest();
            List<outfunds__Requirement__c> requirements = CreateWebSiteRequest.getRequirements(fundingRequest.Id, null, null, null, null);
        Test.stopTest();

        System.assertEquals(1, requirements.size(), 'Must be return one requirement');
    }

    @Istest
    static void getRequirementsOk(){

        outfunds__Funding_Request__c fundingRequest = [SELECT External_ID__c FROM outfunds__Funding_Request__c LIMIT 1];

        Test.startTest();
            List<outfunds__Requirement__c> requirements = CreateWebSiteRequest.getRequirements(fundingRequest.Id, STATUS_IN_PROGRESS, TYPE_REQUIREMENT_PRELIMINARY_APP, null, null);
        Test.stopTest();

        System.assertEquals(1, requirements.size(), 'Must be return one requirement');
    }

    @IsTest
    static void getFieldsByLayoutNameOk(){

        Test.startTest();
            Map<String, Boolean> result = CreateWebSiteRequest.getFields(CONTACT_PORTAL_LAYOUT_RETRIEVE);
        Test.stopTest();

        System.assertNotEquals(NULL, result, 'Layout don´t found');
    }

    @IsTest
    static void getFieldsBySectionsOK(){

        Test.startTest();
        Map<String, Map<String, Boolean>> result = CreateWebSiteRequest.getFieldsBySections(CONTACT_PORTAL_LAYOUT_RETRIEVE);
        Test.stopTest();

        System.assertNotEquals(NULL, result, 'Layout don´t found');
    }

    @Istest
    static void getContactByDni(){

        Test.startTest();
            Contact contact = CreateWebSiteRequest.getContactByDni(DOC_NUMBER_EXT_ID);
        Test.stopTest();

        System.assertEquals(DOC_NUMBER_EXT_ID, contact.N_mero_de_Documento__c, 'The document numbers don´t match');
    }

    @IsTest
    static void getProgramsOk(){

        outfunds__Funding_Program__c[] fundingPrograms = PrepareTestData.createFundingPrograms(3);
        fundingPrograms[0].outfunds__Top_Level__c = false;
        fundingPrograms[0].visiblePublicWeb__c = true;
        fundingPrograms[0].OrderPublicWeb__c = 1;
        fundingPrograms[0].ColorPublicWeb__c = 'slds-card redColor';
        fundingPrograms[1].outfunds__Top_Level__c = false;
        fundingPrograms[1].IsForPerson__c = true;
        fundingPrograms[2].outfunds__Top_Level__c = false;
        fundingPrograms[2].IsForUniversity__c = true;
        insert fundingPrograms;

        Test.startTest();
            outfunds__Funding_Program__c[] result1 = CreateWebSiteRequest.getPrograms(PRIVATE_PORTAL);
            outfunds__Funding_Program__c[] result2 = CreateWebSiteRequest.getPrograms(PERSON_PORTAL);
            outfunds__Funding_Program__c[] result3 = CreateWebSiteRequest.getPrograms(UNIVERSITY_PORTAL);
        Test.stopTest();

        System.assertEquals(1, result1.size(), 'Must be return one record from result1');
        System.assertEquals(1, result2.size(), 'Must be return one record from result2');
        System.assertEquals(1, result3.size(), 'Must be return one record from result3');
    }

    @Istest
    static void getUniversityByContactOk(){

        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Account account = [SELECT  Id FROM Account LIMIT 1];

        Test.startTest();
            Account accountResult = CreateWebSiteRequest.getUniversityByContact(contact.Id);
        Test.stopTest();

        System.assertEquals(account.Id, accountResult.Id, 'The accounts ids doesn´t match');
    }

    @IsTest
    static void getUniversityProgramOK(){

        Test.startTest();
            outfunds__Funding_Program__c result = CreateWebSiteRequest.getUniversityProgram(PROGRAM_NAME);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Must be return one record');
    }

    @IsTest
    static void getLeadRecordTypeOK(){

        RecordType leadRct = [SELECT DeveloperName FROM RecordType WHERE SobjectType = 'Lead' LIMIT 1];

        Test.startTest();
            RecordType result = CreateWebSiteRequest.getLeadRecordType(leadRct.DeveloperName);
        Test.stopTest();

        System.assertEquals(leadRct.Id, result.Id, 'The recordtypes ids don´t match');
    }

    @IsTest
    static void getLeadTypesOK(){

        LeadType__mdt[] leadTypes = [SELECT RecordTypeName__c, LayoutName__c FROM LeadType__mdt];

        Test.startTest();
            LeadType__mdt[] leadTypesResult = CreateWebSiteRequest.getLeadTypes();
        Test.stopTest();

        System.assertEquals(leadTypes.size(), leadTypesResult.size(), 'The quantity of records must be same');
    }

    @IsTest
    static void getInnerDataOK(){

        outfunds__Funding_Program__c program = [SELECT Id FROM outfunds__Funding_Program__c LIMIT 1];

        Test.startTest();
            List<Section__c> result = CreateWebSiteRequest.getInnerData(program.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Must be return one record');
    }

    @IsTest
    static void saveResourcesOK(){

        Recurso__c resource = [SELECT Id FROM Recurso__c LIMIT 1];
        resource.Cantidad__c = System.today().day();

        Test.startTest();
            CreateWebSiteRequest.saveResources(new List<Recurso__c>{resource});
        Test.stopTest();

        System.assertEquals(System.today().day(), [SELECT Cantidad__c FROM Recurso__c LIMIT 1].Cantidad__c, 'The quantity is not the same');
    }

    @IsTest
    static void getFundingRequestOK(){

        outfunds__Funding_Request__c fundingRequest = [SELECT Id FROM outfunds__Funding_Request__c LIMIT 1];

        Test.startTest();
            outfunds__Funding_Request__c result = CreateWebSiteRequest.getFundingRequest(fundingRequest.Id);
        Test.stopTest();

        System.assertEquals(fundingRequest.Id, result.Id, 'The ids don´t are the same');
    }

    @IsTest
    static void getContentDistributionsNotFoundOk(){

        Test.startTest();
            List<ContentDistribution> result = CreateWebSiteRequest.getContentDistributions(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Must be return 0 records');
    }

    @IsTest
    static void getFundingRequestsByParentsOK(){

        outfunds__Funding_Request__c parentFundingRequest = [SELECT outfunds__FundingProgram__c FROM outfunds__Funding_Request__c LIMIT 1];
        
        outfunds__Funding_Request__c childFundingRequest = PrepareTestData.createFundingRequests(parentFundingRequest.outfunds__FundingProgram__c, 1).get(0);
        childFundingRequest.Funding_Request__c = parentFundingRequest.Id;
        insert childFundingRequest;

        Test.startTest();
            List<outfunds__Funding_Request__c> result = CreateWebSiteRequest.getFundingRequestsByParents(new List<String>{parentFundingRequest.Id});
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Must be return one record');
        
    }

    @IsTest
    static void getFundingRequestsByOwnerOK(){

        outfunds__Funding_Program__c program = [SELECT Id FROM outfunds__Funding_Program__c LIMIT 1];

        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(program.Id, 1).get(0);
        fundingRequest.outfunds__Status__c = CONSTANTS.FUNDING_REQUEST_STATUS_AWARDED;
        fundingRequest.EstadoDeRevision__c = CONSTANTS.FUNDING_REQUEST_REVIEW_STATUS_GRANTED;
        fundingRequest.outfunds__Awarded_Amount__c = 10;
        insert fundingRequest;

        Id ownerId = [SELECT OwnerId FROM outfunds__Funding_Request__c WHERE Id =: fundingRequest.Id LIMIT 1].OwnerId;

        Test.startTest();
            List<outfunds__Funding_Request__c> result = CreateWebSiteRequest.getFundingRequestsByOwner(ownerId);
        Test.stopTest();

        System.assertEquals(fundingRequest.Id, result[0].Id, 'The ids aren´t the same');
    }

    @IsTest
    static void getResourcesByFundingRequestIdOK(){

        outfunds__Funding_Request__c fundingRequest = [SELECT Id FROM outfunds__Funding_Request__c LIMIT 1];

        Test.startTest();
            List<Recurso__c> result = CreateWebSiteRequest.getResourcesByFundingRequestId(fundingRequest.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Must be return one record');
        System.assertEquals(fundingRequest.Id, result[0].Funding_Request__c, 'The funding request ids are not the same');
    }

    @Istest
    static void deleteResourceOK(){

        List<Recurso__c> resources = [SELECT Id FROM Recurso__c];
        System.assertEquals(1, resources.size(), 'Must be return one record');

        Test.startTest();
            CreateWebSiteRequest.deleteResource(resources[0].Id);
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Recurso__c], 'The record is not deleted');
    }

    @IsTest
    static void getPortalConfigOK(){

        Integer quantityPortalConf = [SELECT Count()  FROM Portal_Config__mdt];

        Test.startTest();
            List<Portal_Config__mdt> result = CreateWebSiteRequest.getPortalConfig();
        Test.stopTest();

        System.assertEquals(quantityPortalConf, result.size(), 'The quanity of records is not same');
    }

    @IsTest
    static void getTermsAndConditionsOK(){

        Portal_Config__mdt portalConfig = [SELECT Value__c FROM Portal_Config__mdt WHERE Type_Program__r.TypeValue__c = :PROGRAM_TYPE AND Config_Type__c = 'Terms And Conditions' AND Portal_Type__c = :PRIVATE_PORTAL LIMIT 1];

        Test.startTest();
            Portal_Config__mdt result = CreateWebSiteRequest.getTermsAndConditions(PROGRAM_TYPE, PRIVATE_PORTAL);
        Test.stopTest();

        System.assertEquals(portalConfig.Value__c, result.Value__c, 'The values aren´t same');
    }

    @IsTest
    static void createMemberCampaignOk(){

        System.assertEquals(0, [SELECT Count() FROM CampaignMember], 'Must be return 0 records');

        //Insert Campaign
        Campaign camp = new Campaign(Name = CAMPAIGN_NAME);
        insert camp;

        //Insert Lead
        Lead lead = PrepareTestData.createLead(LEAD_LAST_NAME, LEAD_INDIVIDUAL_COMPANY, LEAD_PERSON_RT);
        insert lead;

        Test.startTest();
            CreateWebSiteRequest.createMemberCampaign(lead.Id, camp.Id);
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM CampaignMember], 'Must be return 1 record');

    }

    @IsTest
    static void createMemberCampaignKO(){

        System.assertEquals(0, [SELECT Count() FROM CampaignMember], 'Must be return 0 records');

        Test.startTest();
            try {
                CreateWebSiteRequest.createMemberCampaign(null, null);    
            } catch (Exception e) {
                
            }
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM CampaignMember], 'Must be return 0 records');

    }
}