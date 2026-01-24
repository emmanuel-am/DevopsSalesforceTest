@IsTest
public with sharing class Assignment_CaseTriggerErrorMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req){
        
        String json = '{ "errorMessage": "This is an error message!" }';

        HttpResponse response = new HttpResponse();
        response.setBody(json);
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(403);
        response.setStatus('ERROR');
        return response;
    }
}