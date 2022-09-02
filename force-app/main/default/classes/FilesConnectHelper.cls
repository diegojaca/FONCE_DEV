/**
 * @description This class will provide Files Connect methods to be used to connect throw it
 */
@SuppressWarnings('PMD')
public with sharing class FilesConnectHelper {

    private static final String FILES_CONNECT_ID_FORMAT = 'item:{0}:{1}:{2}:{3}';

    /**
     * @description This method will return all possible repositories configured in Salesforce instance
     * @return All repositories information
     */
    public static ConnectApi.ContentHubRepositoryCollection getRepositories() {

        return ConnectApi.ContentHub.getRepositories();
    }

    /**
     * @description This method will retrieve root folder on repository
     * @param repoId Repository Id
     * @return Root folder information
     */
    public static ConnectApi.RepositoryFolderDetail getRootFolder(String repoId) {

        return ConnectApi.ContentHub.getRepositoryFolder(repoId, 'root');
    }

    /**
     * @description This method will retrieve the folder information requested
     * @param repoId Repository Id
     * @param folderId Folder Id
     * @return Folder information
     */
    public static ConnectApi.RepositoryFolderDetail getFolder(String repoId, String folderId) {
        return ConnectApi.ContentHub.getRepositoryFolder(repoId, folderId);
    }

    /**
     * @description This method will retrieve information about all items in a folder
     * @param repoId Repository Id
     * @param folderId Folder Id
     * @return Items information
     */
    public static ConnectApi.RepositoryFolderItemsCollection getFolderItems(String repoId, String folderId) {
        return ConnectApi.ContentHub.getRepositoryFolderItems(repoId, folderId);
    }

    /**
     * @description This method will return which types are allowed in the folder
     * @param repoId Repository Id
     * @param parentFolderId Folder Id
     * @return All types allowed
     */
    public static ConnectApi.ContentHubAllowedItemTypeCollection getTypes(String repoId, String parentFolderId) {
        return ConnectApi.ContentHub.getAllowedItemTypes(repoId, parentFolderId);
    }

    /**
     * @description This method will create a folder in Sharepoint using its API
     * @param route folder route to be inserted
     * @return Sharepoint unique Id or exception
     */
    public static String createSharepointFolder(String route) {

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:SharepointAPI/folders');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');

        SharepointFolderCreateRequestModel model = new SharepointFolderCreateRequestModel(route);

        request.setBody(JSON.serialize(model));

        Http http = new Http();
        HttpResponse response = http.send(request);

        String body = response.getBody();
        if (response.getStatusCode() != 201) {
            throw new FilesConnectHelperException('StatusCode: ' + response.getStatusCode() + ' Body: ' + body);
        }

        SharepointFolderCreateResponseModel res = (SharepointFolderCreateResponseModel) JSON.deserialize(body, SharepointFolderCreateResponseModel.class);

        return res.UniqueId;
    }

    /**
     * @description This class will format returned Sharepoint id into Files Connect Id
     * @param folderUniqueId Folder Id
     * @return Folder Id in Files Connect format
     */
    public static String getSharepointFolderFilesConnectId(String folderUniqueId) {

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:SharepointAPI/GetFolderById(%27' + folderUniqueId + '%27)?$expand=ListItemAllFields/ParentList,ListItemAllFields/ParentList/ParentWeb,Properties&$select=ListItemAllFields/ParentList/ParentWeb/Id,ListItemAllFields/ParentList/ParentWeb/ServerRelativeUrl,ListItemAllFields/ParentList/Id,Properties/vti_x005f_doclibrowid');
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');

        Http http = new Http();

        HttpResponse httpResponse = http.send(req);

        String body = httpResponse.getBody();

        SharepointFolderDetailResponseModel res = (SharepointFolderDetailResponseModel) JSON.deserialize(body, SharepointFolderDetailResponseModel.class);

        return String.format(FilesConnectHelper.FILES_CONNECT_ID_FORMAT, new String[]{
                EncodingUtil.base64Encode(Blob.valueOf(res.ListItemAllFields.ParentList.ParentWeb.ServerRelativeUrl)).remove('='),
                res.ListItemAllFields.ParentList.ParentWeb.Id,
                res.ListItemAllFields.ParentList.Id,
                // res.ListItemAllFields.Id
                String.valueOf(res.Properties.vti_x005f_doclibrowid)
        });
    }

    /**
     * @description This class will create a fine in repository and folder id provided using Content Version data
     * @param repoId Repository Id
     * @param folderId Folder Id
     * @param data Data to be passed
     * @return Files connect information about file inserted
     */
    public static ConnectApi.RepositoryFolderItem createFile(String repoId, String folderId, ContentVersion data) {

        ConnectApi.ContentHubFieldValueInput param = new ConnectApi.ContentHubFieldValueInput();
        param.name = 'name';
        // param.value = data.Title;
        param.value = data.PathOnClient;

        ConnectApi.ContentHubItemInput fileInput = new ConnectApi.ContentHubItemInput();
        // fileInput.itemTypeId = 'file';
        fileInput.itemTypeId = 'item:L3NpdGVzL0ZPTkNFX1Rlc3Q:033aed22-2c6f-4a46-8c5d-535c9052bc54:01fc531a-8e38-472e-a495-c6fa217b5221:0x0101'; // obtained via getAllowedTypes
        fileInput.fields = new ConnectApi.ContentHubFieldValueInput[]{
                param
        };

        String convertedType = MimeHelper.getMimiType(data.FileExtension);

        ConnectApi.BinaryInput fileBinaryInput = new ConnectApi.BinaryInput(data.VersionData, convertedType, data.PathOnClient);


        ConnectApi.RepositoryFolderItem repositoryFolderItem;
        if (!Test.isRunningTest()) {
            repositoryFolderItem = ConnectApi.ContentHub.addRepositoryItem(repoId, folderId, fileInput, fileBinaryInput);
        }
        return repositoryFolderItem;
    }

    /**
     * @description This method will create new Content Version with external information in order to substitute the Content Version in Salesforce
     * @param repoId Repository Id
     * @param originalCV Original Content Version
     * @param file File information
     * @return Content Version with external information
     */
    public static ContentVersion prepareNewContentVersion(String repoId, ContentVersion originalCV, ConnectApi.RepositoryFileSummary file) {
        return new ContentVersion(
                ExternalDataSourceId = repoId,
                ExternalDocumentInfo1 = file.externalDocumentUrl,
                ExternalDocumentInfo2 = file.id,
                Title = originalCV.Title,
                ContentLocation = 'E',
                Origin = 'H',
                PathOnClient = originalCV.PathOnClient
        );
    }


    private class SharepointFolderCreateRequestModel {

        public String ServerRelativeUrl;

        public SharepointFolderCreateRequestModel(String route) {
            this.ServerRelativeUrl = route;
        }
    }

    private class SharepointFolderCreateResponseModel {

        public String UniqueId;
    }


    private class SharepointFolderDetailResponseModel {

        public ListItemModel ListItemAllFields;
        public PropertiesModel Properties;
    }

    private class ListItemModel {

        // for some reason when selecting the id, it comes both in case sensitive and insientive versions (Id and ID)
        // which breaks the deserializer indicating a duplicate field, therefore we opt to inspect the properties

        // public String Id; 

        public ParentListModel ParentList;
    }

    private class ParentListModel {

        public String Id;
        public ParentWebModel ParentWeb;
    }

    private class ParentWebModel {

        public String Id;
        public String ServerRelativeUrl;
    }

    private class PropertiesModel {

        public Integer vti_x005f_doclibrowid;
    }

    public class FilesConnectHelperException extends Exception {
    }
}