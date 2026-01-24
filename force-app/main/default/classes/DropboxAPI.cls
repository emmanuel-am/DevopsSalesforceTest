public with sharing class DropboxAPI {

    //Call Method testUploadFile( DropboxAPI.testUploadFile('0685e000002tEEHAA2', 'Test');
    //Call Method listFolder   
    //List<DropboxFile> files = DropboxAPI.listFolder('/Test', 20);
    //System.debug(JSON.serializePretty(files));

    public static void testUploadFile(String fileId, String filePath){
        if(String.isBlank(fileId)){
            fileId = '0685e000002tEEHAA2';
        }
        
        if(String.isBlank(filePath)){
            filePath = '/';
        }

        ContentVersion cv = [
            SELECT Id, Title, ContentDocumentId, FileExtension, VersionData, ContentSize, PathOnClient 
            FROM ContentVersion 
            WHERE Id = :fileId
            LIMIT 1
        ];

        //Determine file name - use PathONClient if available, otherwise build from Title and FileExtension
        String fileName = cv.Title;
        if(String.isNotBlank(cv.FileExtension)){
            fileName += '.' + cv.FileExtension;
        }
        //Get the file content as Blob
        Blob fileContent = cv.VersionData;
        DropboxFile file = uploadFile(fileContent, fileName, filePath);
        //Store the information inside Salesforce
        if(!String.isBlank(file.id)){
            DropBoxFile__c dropboxFile = new DropBoxFile__c();
            DropboxFile.Dropbox_File_Id__c = file.id;
            dropboxFile.Name = fileName;
            dropboxFile.Dropbox_Path__c = file.path;
            dropboxFile.File_Size__c = file.size;
            //dropboxFile.RecordId__c = file?.recordId
            dropboxFile.Content_Document_Id__c = cv.ContentDocumentId;
            dropboxFile.ServerUrl__c = 'https://www.dropbox.com/home'+file.path;

            insert as system dropboxFile;
        }
    }

    public static DropboxFile uploadFile(Blob fileContent, String fileName, String path){
        HttpRequest httpReq = new HttpRequest();
        // htpps://content.dropboxapi.com/2/files/upload
        httpReq.setEndpoint('callout:DropboxContent'+'/2/files/upload');
        httpReq.setMethod('POST');
        httpReq.setHeader('Content-Type', 'application/octet-stream');
        
        /** Replace any space with _ in the file name & encode it to UTF-8 format */
        fileName = EncodingUtil.urlEncode(fileName.replace(' ', '_'), 'UTF-8');
        System.debug('file name is '+ fileName);
        // /Hack/
        if(path.startsWith('/') && path.endsWith('/')){
            path = path + fileName;
        }
        // /Hack
        else if(path.startsWith('/') && !path.endsWith('/')){
            path = path + '/' + fileName;
        }
         // Hack/
        else if(!path.startsWith('/') && path.endsWith('/')){
            path = '/' + path + fileName;
        }
         // Hack/
        else {
            path = '/' + path + '/' + fileName;
        }
        System.debug('File path is '+ path);
        Map<String, Object> argumentMap = new Map <String, Object>{
            'mode' => 'add',
            'autorename' => false,
            'mute' => false,
            'path' => path
        };
        // {"path":"/Hack/Mahs.png","mode":{".tag":"add"},"autorename":false}
        httpReq.setHeader('Dropbox-API-Arg', JSON.serialize(argumentMap));
        httpReq.setBodyAsBlob(fileContent);
        DropboxFile file = new DropboxFile();
        try{
            HttpResponse httpRes = (new Http()).send(httpReq);
            if(httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201 ){
                System.debug(httpRes.getBody());
                System.debug(System.LoggingLevel.ERROR, 'successfully uploaded the file to Dropbox '+ httpRes.getBody());
                Map<String, Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(httpRes.getBody());
                file.id = (String)responseMap.get('id');
                file.name = (String)responseMap.get('name');
                file.path = (String)responseMap.get('path_display');
                file.isFolder = false;
                file.size = (Integer)responseMap.get('size');
            }else{
                System.debug(System.LoggingLevel.ERROR, 'There was an error while uploading the file to Dropbox '+ httpRes.getBody());
            }    
        }catch(System.CalloutException ex){
            System.debug(System.LoggingLevel.ERROR, 'Exception Ocurred while uploading the file to Drpbox '+ ex.getStackTraceString());
            System.debug(System.LoggingLevel.ERROR, 'Exception Ocurred while uploading the file to Drpbox '+ ex.getMessage());
        }catch(System.Exception ex){
            System.debug(System.LoggingLevel.ERROR, 'Generic Exception Ocurred while uploading the file to Drpbox '+ ex.getStackTraceString());
        }
        return file;
    }

    public static List<DropboxFile> listFolder(String filePath, Integer limitx){
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint('callout:DropboxAPI'+'/2/files/list_folder');
        httpReq.setMethod('POST');
        httpReq.setHeader('Content-Type', 'application/json');
        // {"path":"","recursive":false,"include_media_info":true,"include_mounted_folders":true,"limit":20}
        Map<String, Object> requestBody = new Map<String, Object>{
            'path' => filePath,
            'recursive' => false,
            'include_media_info' => true,
            'include_deleted' => false,
            'limit' => limitx
        };
        httpReq.setBody(JSON.serialize(requestBody));
        List<DropboxFile> files = new List<DropboxFile>();
        try{
            HttpResponse httpRes = (new Http()).send(httpReq);
            if(httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201 ){
                System.debug(httpRes.getBody());
                System.debug(System.LoggingLevel.ERROR, 'successfully uploaded the file to Dropbox '+ httpRes.getBody());
                Map<String, Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(httpRes.getBody());
                List<Object> entries = (List<Object>)responseMap.get('entries');
                for(Object entry : entries){
                    Map<String, Object> fileMap = (Map<String,Object>) entry;
                    DropboxFile file = new DropboxFile();
                    file.id = (String)fileMap.get('id');
                    file.name = (String)fileMap.get('name');
                    file.path = (String) fileMap.get('path_display');
                    file.isFolder = 'folder'.equals(fileMap.get('.tag'));
                    file.size = fileMap.containsKey('size') ? (Integer) fileMap.get('size') : 0;
                    file.modifiedTime = fileMap.containsKey('server_modified') ? (String) fileMap.get('server_modified') : '';
                    files.add(file);
                }
            }else{
                System.debug(System.LoggingLevel.ERROR, 'There was an error while listing the file to Dropbox '+ httpRes.getBody());
            }    
        }catch(System.CalloutException ex){
            System.debug(System.LoggingLevel.ERROR, 'Exception Ocurred while listing the file to Drpbox '+ ex.getStackTraceString());
            System.debug(System.LoggingLevel.ERROR, 'Exception Ocurred while listing the file to Drpbox '+ ex.getMessage());
            throw new DropboxException('Generic Exception Occured while listing the file to Dropbox '+ ex.getStackTraceString() + ' '+  'Exception Ocurred while listing the file to Drpbox '+ ex.getMessage());
        }catch(System.Exception ex){
            System.debug(System.LoggingLevel.ERROR, 'Generic Exception Ocurred while listing the file to Drpbox '+ ex.getStackTraceString());
            throw new DropboxException('Generic Exception Occured while listing the file to Dropbox '+ ex.getStackTraceString());
        }
        return files;
    }
    public class DropboxException extends Exception {}
}





/**
    First Version
    public with sharing class DropboxAPI {

        //Call class DropboxAPI.testUploadFile();

        public static void testUploadFile(){
            Id fileId = '0685e000002tEEHAA2';
            ContentVersion cv = [
                SELECT Id, Title, FileExtension, VersionData, ContentSize, PathOnClient 
                FROM ContentVersion 
                WHERE Id = :fileId
                LIMIT 1
            ];

            //Determine file name - use PathONClient if available, otherwise build from Title and FileExtension
            String fileName = cv.Title;
            if(String.isNotBlank(cv.FileExtension)){
                fileName += '.' + cv.PathOnClient;
            }
            //Get the file content as Blob
            Blob fileContent = cv.VersionData;
            uploadFile(fileContent, fileName, '/Salesforce/');
        }

        public static void uploadFile(Blob fileContent, String fileName, String path){
            HttpRequest httpReq = new HttpRequest();
            // htpps://content.dropboxapi.com/2/files/upload
            httpReq.setEndpoint('callout:DropboxContent'+'/2/files/upload');
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type', 'application/octet-stream');
            
            //Replace any space with _ in the file name & encode it to UTF-8 format
            fileName = EncodingUtil.urlEncode(fileName.replace(' ', '_'), 'UTF-8');
            System.debug('file name is '+ fileName);
            // /Hack/
            if(path.startsWith('/') && path.endsWith('/')){
                path = path + fileName;
            }
            // /Hack
            else if(path.startsWith('/') && !path.endsWith('/')){
                path = path + '/' + fileName;
            }
            // Hack/
            else if(!path.startsWith('/') && path.endsWith('/')){
                path = '/' + path + fileName;
            }
            // Hack/
            else {
                path = '/' + path + '/' + fileName;
            }
            System.debug('File path is '+ path);
            Map<String, Object> argumentMap = new Map <String, Object>{
                'mode' => 'add',
                'autorename' => false,
                'mute' => false,
                'path' => path
            };
            // {"path":"/Hack/Mahs.png","mode":{".tag":"add"},"autorename":false}
            httpReq.setHeader('Dropbox-API-Arg', JSON.serialize(argumentMap));
            httpReq.setBodyAsBlob(fileContent);
            try{
                HttpResponse httpRes = (new Http()).send(httpReq);
                if(httpRes.getStatusCode() == 200 || httpRes.getStatusCode() == 201 ){
                    System.debug(System.LoggingLevel.ERROR, 'successfully uploaded the file to Dropbox '+ httpRes.getBody());
                }else{
                    System.debug(System.LoggingLevel.ERROR, 'There was an error while uploading the file to Dropbox '+ httpRes.getBody());
                }    
            }catch(System.CalloutException ex){
                System.debug(System.LoggingLevel.ERROR, 'Exception Ocurred while uploading the file to Drpbox '+ ex.getStackTraceString());
            }catch(System.Exception ex){
                System.debug(System.LoggingLevel.ERROR, 'Generic Exception Ocurred while uploading the file to Drpbox '+ ex.getStackTraceString());
            }
        }
    }
 */