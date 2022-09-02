/**
 * @description This class will provide methods for SharepointIntegrationBatch
 * @author bruno.martin@s4g.es
 * @version 27/06/2022
 */
public with sharing class SharepointIntegrationBatchHelper {

    private static final Map<String, List<String>> FOLDER_STRUCTURE_BY_INTERNAL_ID = new Map<String, List<String>>{
            'outfunds__Funding_Request__c' => new List<String>{
                    'outfunds__Funding_Request__r'
                    , 'outfunds__Applying_Organization__r/outfunds__Applying_Contact__r'
            }
            , 'pmdm__Program__c' => new List<String>{
                    'Program__r'
                    , 'Id'
                    , 'outfunds__Applying_Organization__r/outfunds__Applying_Contact__r'
            }
            , 'pmdm__ServiceDelivery__c' => new List<String>{
                    'ServiceDelivery__r.pmdm__ProgramEngagement__r'
                    , 'pmdm__Program__r'
                    , 'Id'
                    , 'outfunds__Applying_Organization__r/outfunds__Applying_Contact__r'
            }
    };
    private Map<String, SObject> sObjectByOtherSObjectId = new Map<String, SObject>();

    private String sharepointRepositoryId = FilesConnectHelper.getRepositories().repositories.get(0).id;

    /**
     * @description This method will query information for this process
     * @param scope Requirements
     */
    public void querySObjectInformation(List<outfunds__Requirement__c> scope) {
        Set<String> programIdsToQuery = new Set<String>();
        for (outfunds__Requirement__c requirement : scope) {
            if (String.isNotBlank(requirement.Program__r?.Id)) {
                if (requirement.Program__r.Origin_Funding_Request__r != null) {
                    this.sObjectByOtherSObjectId.put(requirement.Program__r.Id, requirement.Program__r.Origin_Funding_Request__r);
                } else {
                    programIdsToQuery.add(requirement.Program__r.Id);
                }
            } else if (String.isNotBlank(requirement.ServiceDelivery__r?.pmdm__ProgramEngagement__r?.pmdm__Program__r?.Id)) {
                if (requirement.ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r != null) {
                    this.sObjectByOtherSObjectId.put(
                            requirement.ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Id
                            , requirement.ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Origin_Funding_Request__r
                    );
                } else {
                    programIdsToQuery.add(requirement.ServiceDelivery__r.pmdm__ProgramEngagement__r.pmdm__Program__r.Id);
                }
            }
        }
        if (programIdsToQuery.isEmpty()) {
            return;
        }

        for (pmdm__Program__c program : [
                SELECT Id
                        , (
                        SELECT Id, Name, SharepointFolderName__c, SharepointFilesConnectFolderExternalId__c

                                , outfunds__Applying_Contact__r.Id, outfunds__Applying_Contact__r.Name, outfunds__Applying_Contact__r.N_mero_de_Documento__c
                                , outfunds__Applying_Contact__r.SharepointFolderName__c, outfunds__Applying_Contact__r.SharepointFilesConnectFolderExternalId__c

                                , outfunds__Applying_Organization__r.Id, outfunds__Applying_Organization__r.Name, outfunds__Applying_Organization__r.N_mero_de_Documento__c
                                , outfunds__Applying_Organization__r.SharepointFolderName__c, outfunds__Applying_Organization__r.SharepointFilesConnectFolderExternalId__c
                        FROM Funding_Requests__r
                        ORDER BY CreatedDate ASC
                        LIMIT 1
                )
                FROM pmdm__Program__c
                WHERE Id IN :programIdsToQuery
                WITH SECURITY_ENFORCED
        ]) {
            this.sObjectByOtherSObjectId.put(program.Id, program.Funding_Requests__r.get(0));
        }
    }

    /**
     * @description This method will set folder path information to be used later
     * @param requirement Requirement to be processed
     * @return Sharepoint folder information
     */
    public SharepointFolderInformationHelper getFolderSObjectFolderPath(outfunds__Requirement__c requirement) {
        SharepointFolderInformationHelper sharePointInformation;
        if (requirement.outfunds__Funding_Request__r != null) {
            sharePointInformation = new SharepointFolderInformationHelper(SharepointIntegrationBatchHelper.FOLDER_STRUCTURE_BY_INTERNAL_ID.get(String.valueOf(outfunds__Funding_Request__c.class)));
        } else if (requirement.Program__r != null) {
            sharePointInformation = new SharepointFolderInformationHelper(SharepointIntegrationBatchHelper.FOLDER_STRUCTURE_BY_INTERNAL_ID.get(String.valueOf(pmdm__Program__c.class)));
        } else if (requirement.ServiceDelivery__r != null) {
            sharePointInformation = new SharepointFolderInformationHelper(SharepointIntegrationBatchHelper.FOLDER_STRUCTURE_BY_INTERNAL_ID.get(String.valueOf(pmdm__ServiceDelivery__c.class)));
        }
        return sharePointInformation;
    }

    /**
     * @description This methods will prepare all necessary information to be used in the integration
     * @param sharePointInformation Sharepoint folder information
     * @param requirement requirement
     */
    public void prepareFolderInformationToBeIntegrated(SharepointFolderInformationHelper sharePointInformation, outfunds__Requirement__c requirement) {
        SObject currentSObject = requirement;
        for (String sObjectInPath : sharePointInformation.folderSObjectFolderPath) {
            if (sharePointInformation.hasToBreakLoop()) {
                break;
            }
            currentSObject = this.getNextSObject(sObjectInPath, currentSObject);
            sharePointInformation.addFolderInformation(currentSObject);
        }
    }

    /**
     * @description This method will return next sobject in folder structure. Folder structure is defined in FOLDER_STRUCTURE_BY_INTERNAL_ID
     * @param sObjectInPath String containing which sObject will have to be returned next with some logic in it
     * @param currentSObject Current sObject
     * @return SObject found
     */
    public SObject getNextSObject(String sObjectInPath, SObject currentSObject) {
        List<String> sObjectsInPath = sObjectInPath.split('/');
        SObject nextSO;
        for (String sObjectToGet : sObjectsInPath) {
            if (nextSO != null) {
                continue;
            }

            SObject so = currentSObject;
            for (String partOfPatch : sObjectToGet.split('\\.')) {
                if (sObjectToGet.endsWith('__r')) {
                    so = so.getSObject(partOfPatch);
                } else {
                    so = this.sObjectByOtherSObjectId.get((String) so.get(partOfPatch));
                }
            }
            nextSO = so;
        }
        if (nextSO == null) {
            throw new SharepointIntegrationBatch.SharepointIntegrationBatchException(
                    'Tried to get ' + String.join(sObjectsInPath, ' or ') + ' from ' + currentSObject.getSObjectType() + ' but found nothing.'
            );
        }
        return nextSO;
    }

    /**
     * @description This method will insert all folders that has to be created
     * @param sharePointInformation Sharepoint folder information
     */
    public void insertFoldersWhenNecessary(SharepointFolderInformationHelper sharePointInformation) {
        if (String.isNotBlank(sharePointInformation.folderIdWhereFileMustBeInserted)) {
            return;
        }
        sharePointInformation.createFoldersInSharepoint();
    }

    /**
     * @description This method will insert file in sharepoint using FilesConnectHelper
     * @param sharePointInformation Sharepoint folder information
     * @param requirement Requirement
     * @return External content version prepared
     */
    public Map<String, ContentVersion> insertFileInSharepoint(SharepointFolderInformationHelper sharePointInformation, outfunds__Requirement__c requirement) {
        if (requirement.ContentDocumentLinks.isEmpty()) {
            throw new SharepointIntegrationBatch.SharepointIntegrationBatchException('There is no file to be integrated for this requirement.');
        }
        ContentVersion actualContentVersion = requirement.ContentDocumentLinks.get(0).ContentDocument.LatestPublishedVersion;
        ConnectApi.RepositoryFolderItem createdItem = FilesConnectHelper.createFile(
                this.sharepointRepositoryId
                , sharePointInformation.folderIdWhereFileMustBeInserted
                , actualContentVersion
        );
        Map<String, ContentVersion> externalContentVersionByRequirementId = new Map<String, ContentVersion>{
                requirement.Id
                        => FilesConnectHelper.prepareNewContentVersion(this.sharepointRepositoryId, actualContentVersion, createdItem.file)
        };
        sharePointInformation.addRequirementToBeUpdated(requirement.Id, createdItem.file.id);
        return externalContentVersionByRequirementId;
    }

    /**
     * @description This method will prepare Contents for external data sources, deleting and inserting records
     * @param scope Requirements
     * @param externalContentVersionByRequirementId External content versions prepared by requirement ids
     */
    public void prepareExternalContentStructure(List<outfunds__Requirement__c> scope, Map<String, ContentVersion> externalContentVersionByRequirementId) {
        Map<String, String> requirementIdByContentDocumentIdToDelete = new Map<String, String>();
        for (outfunds__Requirement__c requirement : scope) {
            if (externalContentVersionByRequirementId.containsKey(requirement.Id)) {
                requirementIdByContentDocumentIdToDelete.put(
                        requirement.ContentDocumentLinks.get(0).ContentDocumentId
                        , requirement.Id
                );
            }
        }
        Map<String, List<String>> linkedEntitiesByRequirementId = this.getLinkedEntitiesByRequirementId(requirementIdByContentDocumentIdToDelete);

        this.deleteInternalContentDocuments(requirementIdByContentDocumentIdToDelete.keySet());
        this.insertNewContentVersions(externalContentVersionByRequirementId);
        this.insertContentDocumentLinksForExternalContentDocuments(externalContentVersionByRequirementId, linkedEntitiesByRequirementId);
    }

    /**
     * @description This method will query all ContentDocumentLinks in order to be substituted later
     * @param requirementIdByContentDocumentIdToDelete Requirement ids by content document ids that are going to be deleted
     * @return Content document links for each requirement
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private Map<String, List<String>> getLinkedEntitiesByRequirementId(Map<String, String> requirementIdByContentDocumentIdToDelete) {
        Map<String, List<String>> linkedEntitiesByRequirementId = new Map<String, List<String>>();
        for (ContentDocumentLink contentDocumentLink : [
                SELECT LinkedEntityId, LinkedEntity.Type, ContentDocumentId
                FROM ContentDocumentLink
                WHERE ContentDocumentId IN :requirementIdByContentDocumentIdToDelete.keySet()
        ]) {
            if (contentDocumentLink.LinkedEntity.Type == 'User' || ((String) contentDocumentLink.LinkedEntityId).left(3) == '005') {
                continue;
            }
            String requirementId = requirementIdByContentDocumentIdToDelete.get(contentDocumentLink.ContentDocumentId);
            if (!linkedEntitiesByRequirementId.containsKey(requirementId)) {
                linkedEntitiesByRequirementId.put(requirementId, new List<String>());
            }
            linkedEntitiesByRequirementId.get(requirementId).add(contentDocumentLink.LinkedEntityId);
        }
        return linkedEntitiesByRequirementId;
    }

    /**
     * @description This method will delete all content documents which have been just integrated
     * @param contentDocumentIdsToDelete Content document ids to delete
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void deleteInternalContentDocuments(Set<String> contentDocumentIdsToDelete) {
        List<ContentDocument> contentDocumentsToDelete = new List<ContentDocument>();
        for (String contentDocumentIdToDelete : contentDocumentIdsToDelete) {
            contentDocumentsToDelete.add(new ContentDocument(Id = contentDocumentIdToDelete));
        }
        delete contentDocumentsToDelete;
    }

    /**
     * @description This method will insert all external content document versions prepared
     * @param externalContentVersionByRequirementId External content document versions by requirement ids
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void insertNewContentVersions(Map<String, ContentVersion> externalContentVersionByRequirementId) {
        List<ContentVersion> contentVersions = externalContentVersionByRequirementId.values();
        Map<String, String> requirementIdByContentVersionIdentifier = new Map<String, String>();
        for (String requirementId : externalContentVersionByRequirementId.keySet()) {
            ContentVersion contentVersion = externalContentVersionByRequirementId.get(requirementId);
            requirementIdByContentVersionIdentifier.put(contentVersion.ExternalDocumentInfo2, requirementId);
        }
        insert contentVersions;
        for (ContentVersion contentVersion : contentVersions) {
            String requirementId = requirementIdByContentVersionIdentifier.get(contentVersion.ExternalDocumentInfo2);
            externalContentVersionByRequirementId.get(requirementId).Id = contentVersion.Id;
        }
    }

    /**
     * @description This method will insert all content document links for new external content document versions
     * @param externalContentVersionByRequirementId External content document versions by requirement ids
     * @param linkedEntitiesByRequirementId Content document links for each requirement
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void insertContentDocumentLinksForExternalContentDocuments(
            Map<String, ContentVersion> externalContentVersionByRequirementId
            , Map<String, List<String>> linkedEntitiesByRequirementId
    ) {
        Map<String, String> contentDocumentIdByContentVersionId = new Map<String, String>();
        for (ContentVersion newContentVersion : [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE Id IN :externalContentVersionByRequirementId.values()
                WITH SECURITY_ENFORCED
        ]) {
            contentDocumentIdByContentVersionId.put(newContentVersion.Id, newContentVersion.ContentDocumentId);
        }

        List<ContentDocumentLink> contentDocumentLinksToBeInserted = new List<ContentDocumentLink>();
        for (String requirementId : linkedEntitiesByRequirementId.keySet()) {
            String newExternalContentDocument = contentDocumentIdByContentVersionId.get(externalContentVersionByRequirementId.get(requirementId).Id);
            for (String linkedEntityId : linkedEntitiesByRequirementId.get(requirementId)) {
                contentDocumentLinksToBeInserted.add(new ContentDocumentLink(
                        LinkedEntityId = linkedEntityId
                        , ContentDocumentId = newExternalContentDocument
                ));
            }
        }
        if (!contentDocumentLinksToBeInserted.isEmpty()) {
            insert contentDocumentLinksToBeInserted;
        }
    }

}