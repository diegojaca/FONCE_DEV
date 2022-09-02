/**
 * @description This class will serve as mock for FilesConnectHelperTest
 * @author bruno.martin@s4g.es
 * @version 04/08/2022
 */
@IsTest
public class FilesConnectHelperCalloutMock implements HttpCalloutMock {

    private FilesConnectHelperCalloutMock.PossibleProcesses process;
    private Integer statusCode;
    public enum PossibleProcesses {
        CREATE_SHAREPOINT_FOLDER
        , CREATE_SHAREPOINT_FOLDER_ID
    }

    public FilesConnectHelperCalloutMock(FilesConnectHelperCalloutMock.PossibleProcesses process, Integer statusCode) {
        this.process = process;
        this.statusCode = statusCode;
    }

    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(this.statusCode);
        if (this.statusCode == 201) {
            if (this.process == FilesConnectHelperCalloutMock.PossibleProcesses.CREATE_SHAREPOINT_FOLDER) {
                response.setBody('{"UniqueId":"test"}');
            } else if (this.process == FilesConnectHelperCalloutMock.PossibleProcesses.CREATE_SHAREPOINT_FOLDER_ID) {
                response.setBody('{'
                        + '"ListItemAllFields":{"ParentList":{"Id":"1", "ParentWeb":{"Id":"2", "ServerRelativeUrl":"/test"}}}'
                        + ', "Properties":{"vti_x005f_doclibrowid":3}'
                        + '}'
                );
            }
        }
        return response;
    }
}