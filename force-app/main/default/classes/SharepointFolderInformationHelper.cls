/**
 * @description This class will provide a way to save information about sharepoint folders while providing utility methods for them
 * @author bruno.martin@s4g.es
 * @version 24/06/2022
 */
public with sharing class SharepointFolderInformationHelper {

    public List<String> folderSObjectFolderPath;
    public String folderIdWhereFileMustBeInserted;
    private static final String SHAREPOINT_FILES_CONNECT_FOLDER_EXTERNAL_ID_FIELD_NAME = 'SharepointFilesConnectFolderExternalId__c';
    private static final String SHAREPOINT_FOLDER_NAME_FIELD_NAME = 'SharepointFolderName__c';
    private static final String ROOT_FOLDER_PATH = 'Shared Documents';
    private List<String> foldersAlreadyCreated = new List<String>();
    private List<String> foldersToBeCreated = new List<String>();
    private Map<String, SObject> recordByFolderName = new Map<String, SObject>();

    public SharepointFolderInformationHelper(List<String> folderSObjectFolderPath) {
        this.folderSObjectFolderPath = folderSObjectFolderPath;
    }

    /**
     * @description This method will decide if has to break a loop in these conditions
     * @return True or false
     */
    public Boolean hasToBreakLoop() {
        return String.isNotBlank(this.folderIdWhereFileMustBeInserted) && this.foldersAlreadyCreated.isEmpty() && this.foldersToBeCreated.isEmpty();
    }

    /**
     * @description This method will add folder information extracted from sobject
     * @param so SObject with required information
     */
    public void addFolderInformation(SObject so) {
        String externalId = (String) so.get(SharepointFolderInformationHelper.SHAREPOINT_FILES_CONNECT_FOLDER_EXTERNAL_ID_FIELD_NAME);
        String folderName = (String) so.get(SharepointFolderInformationHelper.SHAREPOINT_FOLDER_NAME_FIELD_NAME);
        if (String.isNotBlank(externalId) && String.isNotBlank(folderName)) {
            if (this.foldersAlreadyCreated.isEmpty() && this.foldersToBeCreated.isEmpty()) {
                this.folderIdWhereFileMustBeInserted = externalId;
            } else {
                this.addBefore(this.foldersAlreadyCreated, folderName);
            }
        } else {
            folderName = (String) so.get('Name');
            try {
                folderName = folderName + '-' + (String) so.get('N_mero_de_Documento__c');
            } catch (SObjectException sObjectException) {
                folderName = folderName + '-' + (String) so.get('Id');
            }
            //Folders in Sharepoint can not include these special characters " * : < > ? / \ | Those characters are going to be replaced by -
            folderName = folderName
                    .replace('"', '-')
                    .replace('*', '-')
                    .replace(':', '-')
                    .replace('<', '-')
                    .replace('>', '-')
                    .replace('?', '-')
                    .replace('/', '-')
                    .replace('\\', '-')
                    .replace('|', '-')
                    .replace('#', '-');
            this.addBefore(this.foldersToBeCreated, folderName);
            Id recordId = (Id) so.get('Id');
            this.recordByFolderName.put(folderName, recordId.getSobjectType().newSObject(recordId));
        }
    }

    /**
     * @description This method will add at the beginning of the list
     * @param stringList String list
     * @param stringToAdd string to be added
     */
    private void addBefore(List<String> stringList, String stringToAdd) {
        if (stringList.isEmpty()) {
            stringList.add(stringToAdd);
        } else {
            stringList.add(0, stringToAdd);
        }
    }

    /**
     * @description This method will create folders in Sharepoint using its API
     */
    public void createFoldersInSharepoint() {
        String filesConnectUniqueId;
        for (String folderToBeCreated : this.foldersToBeCreated) {
            try {
                String sharepointUniqueId = FilesConnectHelper.createSharepointFolder(this.getFolderPathToBeCreated(folderToBeCreated));
                filesConnectUniqueId = FilesConnectHelper.getSharepointFolderFilesConnectId(sharepointUniqueId);
                SObject soToUpdate = this.recordByFolderName.get(folderToBeCreated);
                soToUpdate.put(SharepointFolderInformationHelper.SHAREPOINT_FOLDER_NAME_FIELD_NAME, folderToBeCreated);
                soToUpdate.put(SharepointFolderInformationHelper.SHAREPOINT_FILES_CONNECT_FOLDER_EXTERNAL_ID_FIELD_NAME, filesConnectUniqueId);
                this.foldersAlreadyCreated.add(folderToBeCreated);
            } catch (Exception e) {
                throw new SharepointIntegrationBatch.SharepointIntegrationBatchException(
                        'Error creating folder ' + folderToBeCreated + ' for SObject '
                                + ((Id) this.recordByFolderName.get(folderToBeCreated).get('Id')).getSobjectType()
                                + '. API call information: \n' + e.getMessage()
                );
            }
        }
        this.folderIdWhereFileMustBeInserted = filesConnectUniqueId;
    }

    /**
     * @description This method will generate path to be used when creating a new folder in Sharepoint
     * @param folderToBeCreated Folder name to be created
     * @return Folder path to be created
     */
    private String getFolderPathToBeCreated(String folderToBeCreated) {
        List<String> folderPaths = new List<String>{
                SharepointFolderInformationHelper.ROOT_FOLDER_PATH
        };
        if (!this.foldersAlreadyCreated.isEmpty()) {
            folderPaths.add(String.join(this.foldersAlreadyCreated, '/'));
        }
        folderPaths.add(folderToBeCreated);
        return String.join(folderPaths, '/');
    }

    /**
     * @description This method will add requirements to be updated to a map that is being used to save information about folders and records
     * @param requirementId Requirement id
     * @param filesConnectFileId Files connect file id
     */
    public void addRequirementToBeUpdated(String requirementId, String filesConnectFileId) {
        this.recordByFolderName.put('File', new outfunds__Requirement__c(
                Id = requirementId
                , SharepointFilesConnectFileExternalId__c = filesConnectFileId
                , SharepointIntegrationErrorMessage__c = null
        ));
    }

    /**
     * @description This method will return all sobject that should be updated
     * @return SObjects to be updated
     */
    public List<SObject> getSObjectToUpdate() {
        return this.recordByFolderName.values();
    }

    /**
     * @description This method will return all sObjects that should be updated when an exception has been thrown
     * @return SObjects to be updated
     */
    public List<SObject> getSObjectToUpdateOnException() {
        List<SObject> sObjectsToUpdate = new List<SObject>();
        for (SObject so : this.recordByFolderName.values()) {
            if (so.isSet(SharepointFolderInformationHelper.SHAREPOINT_FOLDER_NAME_FIELD_NAME) && so.isSet(SharepointFolderInformationHelper.SHAREPOINT_FILES_CONNECT_FOLDER_EXTERNAL_ID_FIELD_NAME)) {
                sObjectsToUpdate.add(so);
            }
        }
        return sObjectsToUpdate;
    }

}