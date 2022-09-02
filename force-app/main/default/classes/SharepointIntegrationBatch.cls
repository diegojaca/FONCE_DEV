/**
 * @description This class will integrate files from salesforce system to sharepoint
 * @author bruno.martin@s4g.es
 * @version 21/06/2022
 */
public with sharing class SharepointIntegrationBatch implements Database.Batchable<SObject>, Schedulable, Database.AllowsCallouts {

    private static final Integer BATCH_SIZE = 5;

    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        return Database.getQueryLocator([
                SELECT
                        Id
                        , SharepointFilesConnectFileExternalId__c
                        , SharepointIntegrationTries__c
                        , SharepointIntegrationErrorMessage__c

                        , outfunds__Funding_Request__r.Id
                        , outfunds__Funding_Request__r.Name
                        , outfunds__Funding_Request__r.SharepointFolderName__c
                        , outfunds__Funding_Request__r.SharepointFilesConnectFolderExternalId__c

                        , outfunds__Funding_Request__r.outfunds__Applying_Contact__r.Id
                        , outfunds__Funding_Request__r.outfunds__Applying_Contact__r.Name
                        , outfunds__Funding_Request__r.outfunds__Applying_Contact__r.N_mero_de_Documento__c
                        , outfunds__Funding_Request__r.outfunds__Applying_Contact__r.SharepointFolderName__c
                        , outfunds__Funding_Request__r.outfunds__Applying_Contact__r.SharepointFilesConnectFolderExternalId__c

                        , outfunds__Funding_Request__r.outfunds__Applying_Organization__r.Id
                        , outfunds__Funding_Request__r.outfunds__Applying_Organization__r.Name
                        , outfunds__Funding_Request__r.outfunds__Applying_Organization__r.N_mero_de_Documento__c
                        , outfunds__Funding_Request__r.outfunds__Applying_Organization__r.SharepointFolderName__c
                        , outfunds__Funding_Request__r.outfunds__Applying_Organization__r.SharepointFilesConnectFolderExternalId__c

                        , Program__r.Id
                        , Program__r.Name
                        , Program__r.SharepointFilesConnectFolderExternalId__c
                        , Program__r.SharepointFolderName__c

                        , Program__r.Origin_Funding_Request__r.Id
                        , Program__r.Origin_Funding_Request__r.Name
                        , Program__r.Origin_Funding_Request__r.SharepointFolderName__c
                        , Program__r.Origin_Funding_Request__r.SharepointFilesConnectFolderExternalId__c

                        , Program__r.Origin_Funding_Request__r.outfunds__Applying_Contact__r.Id
                        , Program__r.Origin_Funding_Request__r.outfunds__Applying_Contact__r.Name
                        , Program__r.Origin_Funding_Request__r.outfunds__Applying_Contact__r.N_mero_de_Documento__c
                        , Program__r.Origin_Funding_Request__r.outfunds__Applying_Contact__r.SharepointFolderName__c
                        , Program__r.Origin_Funding_Request__r.outfunds__Applying_Contact__r.SharepointFilesConnectFolderExternalId__c

                        , Program__r.Origin_Funding_Request__r.outfunds__Applying_Organization__r.Id
                        , Program__r.Origin_Funding_Request__r.outfunds__Applying_Organization__r.Name
                        , Program__r.Origin_Funding_Request__r.outfunds__Applying_Organization__r.N_mero_de_Documento__c
                        , Program__r.Origin_Funding_Request__r.outfunds__Applying_Organization__r.SharepointFolderName__c
                        , Program__r.Origin_Funding_Request__r.outfunds__Applying_Organization__r.SharepointFilesConnectFolderExternalId__c

                        , ServiceDelivery__r.Id, ServiceDelivery__r.pmdm__ProgramEngagement__r.Id
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.Name
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.N_mero_de_Documento__c
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.SharepointFilesConnectFolderExternalId__c
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.SharepointFolderName__c

                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Id
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Name
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.SharepointFolderName__c
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.SharepointFilesConnectFolderExternalId__c

                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r.Id
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r.Name
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r.SharepointFolderName__c
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r.SharepointFilesConnectFolderExternalId__c

                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r.outfunds__Applying_Contact__r.Id
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r.outfunds__Applying_Contact__r.Name
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r.outfunds__Applying_Contact__r.N_mero_de_Documento__c
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r.outfunds__Applying_Contact__r.SharepointFolderName__c
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r.outfunds__Applying_Contact__r.SharepointFilesConnectFolderExternalId__c

                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r.outfunds__Applying_Organization__r.Id
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r.outfunds__Applying_Organization__r.Name
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r.outfunds__Applying_Organization__r.N_mero_de_Documento__c
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r.outfunds__Applying_Organization__r.SharepointFolderName__c
                        , ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r.outfunds__Applying_Organization__r.SharepointFilesConnectFolderExternalId__c

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
                WHERE RecordTypeId = :CONSTANTS.REQUIREMENT_RT_REQUIRE_DOCUMENT
                AND SharepointFilesConnectFileExternalId__c = NULL
                AND (
                        SharepointIntegrationTries__c < 5
                        OR SharepointIntegrationTries__c = NULL
                )
                AND (
                        outfunds__Funding_Request__r.outfunds__Status__c = :CONSTANTS.FUNDING_REQUEST_STATUS_AWARDED
                        OR Program__r.pmdm__Status__c = :CONSTANTS.PROGRAM_STATUS_COMPLETED
                        OR ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.pmdm__Status__c = :CONSTANTS.PROGRAM_STATUS_COMPLETED
                )
                WITH SECURITY_ENFORCED
        ]);
    }

    public void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
        this.execute((List<outfunds__Requirement__c>) scope);
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void finish(Database.BatchableContext batchableContext) {
    }

    public void execute(SchedulableContext schedulableContext) {
        SharepointIntegrationBatch.runMe();
    }

    public static void runMe() {
        SharepointIntegrationBatch.runMe(SharepointIntegrationBatch.BATCH_SIZE);
    }

    public static void runMe(Integer batchSize) {
        Database.executeBatch(new SharepointIntegrationBatch(), batchSize);
    }

    /**
     * @description This method will execute all logic
     * @param scope Requirements to be processed
     */
    public void execute(List<outfunds__Requirement__c> scope) {
        SharepointIntegrationBatchHelper helper = new SharepointIntegrationBatchHelper();
        helper.querySObjectInformation(scope);
        Map<String, ContentVersion> externalContentVersionByRequirementId = new Map<String, ContentVersion>();
        List<SObject> sObjectsToBeUpdated = new List<SObject>();
        for (outfunds__Requirement__c requirement : scope) {
            SharepointFolderInformationHelper sharePointInformation = helper.getFolderSObjectFolderPath(requirement);
            if (sharePointInformation == null) {
                continue;
            }

            try {
                helper.prepareFolderInformationToBeIntegrated(sharePointInformation, requirement);
                helper.insertFoldersWhenNecessary(sharePointInformation);
                externalContentVersionByRequirementId.putAll(helper.insertFileInSharepoint(sharePointInformation, requirement));
                sObjectsToBeUpdated.addAll(sharePointInformation.getSObjectToUpdate());
            } catch (Exception e) {
                outfunds__Requirement__c requirementToUpdate = new outfunds__Requirement__c(Id = requirement.Id);
                if (requirementToUpdate.SharepointIntegrationTries__c == null) {
                    requirementToUpdate.SharepointIntegrationTries__c = 0;
                }
                requirementToUpdate.SharepointIntegrationTries__c += 1;
                requirementToUpdate.SharepointIntegrationErrorMessage__c = e.getCause() + ' ' + e.getMessage();
                sObjectsToBeUpdated.addAll(sharePointInformation.getSObjectToUpdateOnException());
                sObjectsToBeUpdated.add(requirementToUpdate);
            }
        }
        if (!sObjectsToBeUpdated.isEmpty()) {
            WorkersManager.avoidAllWorkersExecution(true);
            sObjectsToBeUpdated.sort();
            update sObjectsToBeUpdated;
            //This statement should always be successful but if something makes it fail is better to save integration information than let it fail
            try {
                helper.prepareExternalContentStructure(scope, externalContentVersionByRequirementId);
            } catch (Exception e) {
                System.debug(LoggingLevel.DEBUG, e.getCause() + ' ' + e.getMessage());
            }
            WorkersManager.avoidAllWorkersExecution(false);
        }
    }

    public class SharepointIntegrationBatchException extends Exception {
    }
}