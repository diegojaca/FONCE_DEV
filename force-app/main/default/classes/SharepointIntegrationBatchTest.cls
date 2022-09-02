/**
 * @description This class will test these classes SharepointIntegrationBatch, SharepointIntegrationBatchHelper and SharepointFolderInformationHelper
 * @author bruno.martin@s4g.es
 * @version 05/08/2022
 */
@IsTest
private class SharepointIntegrationBatchTest {

    @SuppressWarnings('PMD.AvoidHardcodingId')
    private static String repositoryId = '0XC1l0000008OX0GAM';// Dev Id '0XC1q0000008OpdGAE';

    @TestSetup
    static void prepareData() {
        WorkersManager.avoidAllWorkersExecution(true);
        S4GTestFactory.setDefaultValues(String.valueOf(Contact.class), String.valueOf(Contact.N_mero_de_Documento__c), '39157712M');
        Contact contact = PrepareTestData.createContact('test');
        insert contact;
        outfunds__Funding_Program__c fundingProgram = PrepareTestData.createFundingPrograms(1).get(0);
        insert fundingProgram;
        S4GTestFactory.setDefaultValues(String.valueOf(pmdm__Program__c.class), String.valueOf(pmdm__Program__c.pmdm__Status__c), CONSTANTS.PROGRAM_STATUS_COMPLETED);
        pmdm__Program__c program = PrepareTestData.createPrograms(1).get(0);
        insert program;
        pmdm__Service__c service = PrepareTestData.createServices(program.Id, 1).get(0);
        insert service;
        pmdm__ProgramEngagement__c programEngagement = PrepareTestData.createProgramEngagements(program.Id, contact.Id, 1).get(0);
        insert programEngagement;
        pmdm__ServiceDelivery__c serviceDelivery = PrepareTestData.createServiceDeliveries(programEngagement.Id, service.Id, 1).get(0);
        insert serviceDelivery;
        S4GTestFactory.setDefaultValues(String.valueOf(outfunds__Funding_Request__c.class), String.valueOf(outfunds__Funding_Request__c.outfunds__Applying_Contact__c), contact.Id);
        S4GTestFactory.setDefaultValues(String.valueOf(outfunds__Funding_Request__c.class), String.valueOf(outfunds__Funding_Request__c.Program__c), program.Id);
        S4GTestFactory.setDefaultValues(String.valueOf(outfunds__Funding_Request__c.class), String.valueOf(outfunds__Funding_Request__c.outfunds__Awarded_Amount__c), 10);
        S4GTestFactory.setDefaultValues(String.valueOf(outfunds__Funding_Request__c.class), String.valueOf(outfunds__Funding_Request__c.outfunds__Status__c), CONSTANTS.FUNDING_REQUEST_STATUS_AWARDED);
        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        insert fundingRequest;
        program.Origin_Funding_Request__c = fundingRequest.Id;
        update program;

        List<outfunds__Requirement__c> requirements = new List<outfunds__Requirement__c>{
                new outfunds__Requirement__c(
                        RecordTypeId = CONSTANTS.REQUIREMENT_RT_REQUIRE_DOCUMENT
                        , Name = 'FundingRequestTest'
                        , outfunds__Funding_Request__c = fundingRequest.Id
                )
                , new outfunds__Requirement__c(
                        RecordTypeId = CONSTANTS.REQUIREMENT_RT_REQUIRE_DOCUMENT
                        , Name = 'ProgramTest'
                        , Program__c = program.Id
                )
                , new outfunds__Requirement__c(
                        RecordTypeId = CONSTANTS.REQUIREMENT_RT_REQUIRE_DOCUMENT
                        , Name = 'ServiceDeliveryTest'
                        , ServiceDelivery__c = serviceDelivery.Id
                )
        };
        insert requirements;
        List<ContentVersion> contentVersions = new List<ContentVersion>{
                PrepareTestData.createContentVersion()
                , PrepareTestData.createContentVersion()
                , PrepareTestData.createContentVersion()
        };
        insert contentVersions;
        Map<String, String> contentDocumentIdByContentVersionId = new Map<String, String>();
        for (ContentDocument contentDocument : [SELECT Id, LatestPublishedVersionId FROM ContentDocument WHERE LatestPublishedVersionId IN :contentVersions]) {
            contentDocumentIdByContentVersionId.put(contentDocument.LatestPublishedVersionId, contentDocument.Id);
        }
        System.assertEquals(3, contentDocumentIdByContentVersionId.values().size(), 'Should have this size');
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for (Integer i = 0; i < requirements.size(); i++) {
            contentDocumentLinks.add(PrepareTestData.createContentDocumentLink(
                    requirements.get(i).Id
                    , contentDocumentIdByContentVersionId.get(contentVersions.get(i).Id)
            ));
        }
        insert contentDocumentLinks;
        WorkersManager.avoidAllWorkersExecution(false);
    }

    @IsTest
    static void testRunMe() {
        Test.startTest();
        SharepointIntegrationBatchTest.prepareRepositoryInFilesConnect();
        SharepointIntegrationBatch.runMe();
        Test.stopTest();
        List<outfunds__Requirement__c> requirements = [
                SELECT Id, SharepointFilesConnectFileExternalId__c, SharepointIntegrationTries__c, SharepointIntegrationErrorMessage__c
                FROM outfunds__Requirement__c
        ];
        for (outfunds__Requirement__c requirement : requirements) {
            System.assertEquals(null, requirement.SharepointFilesConnectFileExternalId__c, 'Should not have value because it should have failed');
            System.assertEquals(1, requirement.SharepointIntegrationTries__c, 'Should have marked one try');
            System.assertNotEquals(null, requirement.SharepointIntegrationErrorMessage__c, 'Should not be null');
        }
    }

    @IsTest
    static void testScheduleExecuteWithExceptions() {
        WorkersManager.avoidAllWorkersExecution(true);
        pmdm__Program__c program = [SELECT Id FROM pmdm__Program__c];
        program.Origin_Funding_Request__c = null;
        update program;
        pmdm__ProgramEngagement__c programEngagement = [SELECT Id FROM pmdm__ProgramEngagement__c];
        programEngagement.SharepointFilesConnectFolderExternalId__c = 'Test';
        programEngagement.SharepointFolderName__c = 'Test';
        update programEngagement;
        WorkersManager.avoidAllWorkersExecution(true);
        Test.startTest();
        SharepointIntegrationBatchTest.prepareRepositoryInFilesConnect();
        SharepointIntegrationBatch batch = new SharepointIntegrationBatch();
        System.schedule('SharepointIntegrationBatch', '0 0 12 1/1 * ? *', batch);
        Test.stopTest();
        List<outfunds__Requirement__c> requirements = [
                SELECT Id, SharepointFilesConnectFileExternalId__c, SharepointIntegrationTries__c, SharepointIntegrationErrorMessage__c
                FROM outfunds__Requirement__c
        ];
        for (outfunds__Requirement__c requirement : requirements) {
            System.assertEquals(null, requirement.SharepointFilesConnectFileExternalId__c, 'Should not have value because it should have failed');
        }
    }

    @IsTest
    static void testPrepareExternalContentStructure() {
        outfunds__Requirement__c requirement = [
                SELECT Id
                        , (
                        SELECT
                                ContentDocumentId, ContentDocument.LatestPublishedVersionId
                                , ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.VersionData
                                , ContentDocument.LatestPublishedVersion.FileType, ContentDocument.LatestPublishedVersion.FileExtension
                                , ContentDocument.LatestPublishedVersion.PathOnClient, ContentDocument.LatestPublishedVersion.ContentDocumentId
                        FROM ContentDocumentLinks
                        ORDER BY SystemModstamp DESC
                        LIMIT 1
                )
                FROM outfunds__Requirement__c
                LIMIT 1
        ];
        String contentDocumentId = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :requirement.Id].ContentDocumentId;
        ContentVersion contentVersion = [
                SELECT Id, LatestPublishedVersion.Title, LatestPublishedVersion.PathOnClient
                FROM ContentDocument
                WHERE Id = :contentDocumentId
        ].LatestPublishedVersion;
        ContentVersion externalContentVersion = FilesConnectHelperTest.prepareNewContentVersion(contentVersion);
        Map<String, ContentVersion> externalContentVersionByRequirementId = new Map<String, ContentVersion>{
                requirement.Id => externalContentVersion
        };
        SharepointIntegrationBatchTest.prepareRepositoryInFilesConnect();
        SharepointIntegrationBatchHelper helper = new SharepointIntegrationBatchHelper();

        Test.startTest();
        helper.prepareExternalContentStructure(
                new List<outfunds__Requirement__c>{
                        requirement
                }
                , externalContentVersionByRequirementId
        );
        Test.stopTest();

        System.assertNotEquals(null, externalContentVersion.Id, 'Should have been inserted');
    }

    @IsTest
    static void testRequirementsToBeUpdated() {
        Test.startTest();
        SharepointFolderInformationHelper folderInformationHelper = new SharepointFolderInformationHelper(new List<String>());
        outfunds__Requirement__c requirement = [SELECT Id FROM outfunds__Requirement__c LIMIT 1];
        folderInformationHelper.addRequirementToBeUpdated(
                requirement.Id
                , 'TestFileId'
        );
        List<SObject> sObjectsToUpdate = folderInformationHelper.getSObjectToUpdate();
        Test.stopTest();
        System.assertEquals(1, sObjectsToUpdate.size(), 'Should have this size');
        System.assertEquals(requirement.Id, sObjectsToUpdate.get(0).Id, 'Should have this Id');
    }

    private static void prepareRepositoryInFilesConnect() {
        ConnectApi.ContentHubRepositoryCollection repositoryCollection = new ConnectApi.ContentHubRepositoryCollection();
        ConnectApi.ContentHubRepository repository = new ConnectApi.ContentHubRepository();
        repository.id = SharepointIntegrationBatchTest.repositoryId;
        repositoryCollection.repositories = new List<ConnectApi.ContentHubRepository>{
                repository
        };
        ConnectApi.ContentHub.setTestGetRepositories(repositoryCollection);
    }
}