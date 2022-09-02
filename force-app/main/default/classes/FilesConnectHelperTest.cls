/**
 * @description This class will test FilesConnectHelper
 * @author bruno.martin@s4g.es
 * @version 04/08/2022
 */
@IsTest
public class FilesConnectHelperTest {

    @SuppressWarnings('PMD.AvoidHardcodingId')
    private static String repositoryId = '0XC1q0000008OpdGAE';

    @IsTest
    static void testGetRepositories() {
        Test.startTest();
        ConnectApi.ContentHub.setTestGetRepositories(new ConnectApi.ContentHubRepositoryCollection());
        ConnectApi.ContentHubRepositoryCollection repositories = FilesConnectHelper.getRepositories();
        Test.stopTest();
        System.assertNotEquals(null, repositories, 'Should not be null');
    }

    @IsTest
    static void testGetRootFolder() {
        Test.startTest();
        ConnectApi.ContentHub.setTestGetRepositoryFolder(FilesConnectHelperTest.repositoryId, 'root', new ConnectApi.RepositoryFolderDetail());
        ConnectApi.RepositoryFolderDetail folderDetail = FilesConnectHelper.getRootFolder(FilesConnectHelperTest.repositoryId);
        Test.stopTest();
        System.assertNotEquals(null, folderDetail, 'Should not be null');
    }

    @IsTest
    static void testGetFolder() {
        Test.startTest();
        ConnectApi.ContentHub.setTestGetRepositoryFolder(FilesConnectHelperTest.repositoryId, 'test', new ConnectApi.RepositoryFolderDetail());
        ConnectApi.RepositoryFolderDetail folderDetail = FilesConnectHelper.getFolder(FilesConnectHelperTest.repositoryId, 'test');
        Test.stopTest();
        System.assertNotEquals(null, folderDetail, 'Should not be null');
    }

    @IsTest
    static void testGetFolderItems() {
        Test.startTest();
        ConnectApi.ContentHub.setTestGetRepositoryFolderItems(FilesConnectHelperTest.repositoryId, 'test', new ConnectApi.RepositoryFolderItemsCollection());
        ConnectApi.RepositoryFolderItemsCollection folderItems = FilesConnectHelper.getFolderItems(FilesConnectHelperTest.repositoryId, 'test');
        Test.stopTest();
        System.assertNotEquals(null, folderItems, 'Should not be null');
    }

    @IsTest
    static void testGetTypes() {
        Test.startTest();
        ConnectApi.ContentHub.setTestGetAllowedItemTypes(FilesConnectHelperTest.repositoryId, 'test', new ConnectApi.ContentHubAllowedItemTypeCollection());
        ConnectApi.ContentHubAllowedItemTypeCollection types = FilesConnectHelper.getTypes(FilesConnectHelperTest.repositoryId, 'test');
        Test.stopTest();
        System.assertNotEquals(null, types, 'Should not be null');
    }

    @IsTest
    static void testCreateSharepointFolderSuccess() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FilesConnectHelperCalloutMock(FilesConnectHelperCalloutMock.PossibleProcesses.CREATE_SHAREPOINT_FOLDER, 201));
        String uniqueId = FilesConnectHelper.createSharepointFolder('Shared Documents/Test');
        Test.stopTest();
        System.assertEquals('test', uniqueId, 'Should have this value');
    }

    @IsTest
    static void testCreateSharepointFolderError() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FilesConnectHelperCalloutMock(FilesConnectHelperCalloutMock.PossibleProcesses.CREATE_SHAREPOINT_FOLDER, 400));
        try {
            FilesConnectHelper.createSharepointFolder('Shared Documents/Test');
            System.assert(false, 'Should have thrown an exception');
        } catch (FilesConnectHelper.FilesConnectHelperException filesConnectHelperException) {
        } catch (Exception e) {
            System.assert(false, 'Should have not thrown an exception of this type');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetSharepointFolderFilesConnectId() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FilesConnectHelperCalloutMock(FilesConnectHelperCalloutMock.PossibleProcesses.CREATE_SHAREPOINT_FOLDER_ID, 201));
        String uniqueId = FilesConnectHelper.getSharepointFolderFilesConnectId('test');
        Test.stopTest();
        System.assertNotEquals(null, uniqueId, 'Should not be null');
    }

    @IsTest
    static void testCreateFile() {
        ContentVersion contentVersion = FilesConnectHelperTest.createContentVersion();
        insert contentVersion;
        contentVersion = [SELECT Id, VersionData, PathOnClient, Title, FileExtension FROM ContentVersion WHERE Id = :contentVersion.Id];

        ConnectApi.ContentHubFieldValueInput param = new ConnectApi.ContentHubFieldValueInput();
        param.name = 'name';
        param.value = contentVersion.PathOnClient;
        ConnectApi.ContentHubItemInput fileInput = new ConnectApi.ContentHubItemInput();
        fileInput.itemTypeId = 'item:L3NpdGVzL0ZPTkNFX1Rlc3Q:033aed22-2c6f-4a46-8c5d-535c9052bc54:01fc531a-8e38-472e-a495-c6fa217b5221:0x0101'; // obtained via getAllowedTypes
        fileInput.fields = new ConnectApi.ContentHubFieldValueInput[]{
                param
        };
        String convertedType = MimeHelper.getMimiType(contentVersion.FileExtension);
        ConnectApi.BinaryInput fileBinaryInput = new ConnectApi.BinaryInput(contentVersion.VersionData, convertedType, contentVersion.PathOnClient);
        Test.startTest();
        ConnectApi.ContentHub.setTestAddRepositoryItem(FilesConnectHelperTest.repositoryId, 'test'
                , fileInput
                , fileBinaryInput
                , new ConnectApi.RepositoryFolderItem()
        );
        System.assertNotEquals(null, ConnectApi.ContentHub.addRepositoryItem(FilesConnectHelperTest.repositoryId, 'test', fileInput, fileBinaryInput)
                , 'Should have worked in this case test set of content hub');

        //This part is only used to cover the method called. I can not test anything because Files Connect setTest method is asserting
        // object instances for fileInput and fileBinaryInput instead its content.
        ConnectApi.RepositoryFolderItem repositoryFolderItem = FilesConnectHelper.createFile(FilesConnectHelperTest.repositoryId, 'test'
                , contentVersion
        );
        Test.stopTest();
        System.assertEquals(null, repositoryFolderItem, 'Should be null because I had to make it this way because of assertion made by FilesConnect API');
    }

    @IsTest
    static void testPrepareNewContentVersion() {
        Test.startTest();
        ContentVersion contentVersion = FilesConnectHelperTest.createContentVersion();
        contentVersion = FilesConnectHelperTest.prepareNewContentVersion(contentVersion);
        Test.stopTest();
        System.assertNotEquals(null, contentVersion, 'Should not be null');
    }

    private static ContentVersion createContentVersion() {
        return new ContentVersion(
                VersionData = Blob.valueOf('test')
                , PathOnClient = 'test.jpg'
                , Title = 'test'
        );
    }

    public static ContentVersion prepareNewContentVersion(ContentVersion contentVersion){
        ConnectApi.RepositoryFileSummary repositoryFileSummary = new ConnectApi.RepositoryFileSummary();
        repositoryFileSummary.id = '1';
        repositoryFileSummary.externalDocumentUrl = '/test';
        return FilesConnectHelper.prepareNewContentVersion(FilesConnectHelperTest.repositoryId, contentVersion, repositoryFileSummary);
    }
}