//Basic authentication siempre usa username : password se tiene que convertir en blob format, el blob format tiene que ser encode into base64 format
//ese es el base64 industry standard no puede ser cambiado  por cualquier username y password authentication o basic authentication
public with sharing class API_Basic_Authentication_ZendeskTicket {

    /*
    API_Basic_Authentication_ZendeskTicket.TicektWrapper wrapper = new API_Basic_Authentication_ZendeskTicket.TicektWrapper();
    wrapper.body = 'Dynamic body';
    wrapper.subject = 'Testing from Salesforce Apex!';
    wrapper.priority = 'urgent';
    wrapper.name = 'Amit Singh';
    wrapper.email = 'asingh@example.org';

    API_Basic_Authentication_ZendeskTicket.createTicket(wrapper);
    */
    public class TicektWrapper {
        public String body;
        public String subject;
        public String priority;
        public String name;
        public String email;
    }
    public static void createTicket(TicektWrapper wrapper){ // Enhance it para recibir parametros
        /*
            Case -->
                    Case is Created in Salesforce
                    Zendesk caso debe ser creado tambien en zendesk
            Salesforce Case should be updated with the Zendesk ticket Id
        */
        String header = System.Label.Zendesk_Username +':'+System.Label.Zendesk_APITOKEN; //convinamos username y password con : como string
        Blob headerValue = Blob.valueOf(header); //convertimos el header a blob porque el metodo base64Encode retorna un string pero aceptar un valor blob

        //body en forma de String
        String requestBody=		'{'+
		'    "ticket": {'+
		'        "comment": {'+
		'            "body": "'+wrapper.body+'"'+
		'        },'+
		'        "priority": "'+wrapper.priority+'",'+
		'        "subject": "'+wrapper.subject+'",'+
		'        "requester": {'+
		'            "locale_id": 8,'+
		'            "name": "'+wrapper.name+'",'+
		'            "email": "'+wrapper.email+'"'+
		'        }'+
		'    }'+
		'}';

        //Si asignamos en body 2 lineas y un salto de linea entre ellas nos dara error para arreglar eso tenemos que usar regex para remplazar las nuevas lineas con espacios, debemos buscar en google para remplazar caracteres especiales de una string
        //Buscamos en google how to replace special characters in string from salesforce apex
        System.debug('requestBody \n '+ requestBody);
        //Buscar en los logs user_debug

        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint('https://pantherschools.zendesk.com/api/v2/tickets');
        httpReq.setMethod('POST'); //como es post 99% de las apis aceptan body en forma de string en forma de XML o JSON
        httpReq.setBody(requestBody); // String --> XML/JSON
        httpReq.setHeader('Content-Type','application/json'); //api acepta el JSON format por eso content-type de este tipo
        httpReq.setHeader('Accept','application/json'); //queremos tener la respuesta en JSON format
        httpReq.setHeader('Authorization','Basic '+EncodingUtil.base64Encode( headerValue ) );
            
        Http http = new Http(); //Object de HTTP class cual nos da la interface para llamar el http method
        try{
            HttpResponse httpRes = http.send(httpReq);
            if(httpRes.getStatusCode() == 201){
                System.debug('SUCCESS \n '+httpRes.getBody());
                //ya sabemos como conseguir el valor exacto que buscas desde el json y ponerlo en el objeto en este caso Zendesk Ticket Id
                //Una vez la respuesta es exitosa puedes usar apex class deserialize method conseguir la info
                //puedes usar el case id para updates
                // Success
            } else {
                // 400
                System.debug('ERROR \n '+ httpRes.getBody());
                // error
                //error viene cuando estamos enviando algo que no es aceptado por el sistema, cuando tienes por ejemplo status 400 es tambien una respuesta no una excepcion
            }
        }catch(System.CalloutException ex){
        //solo trae excepciones relacionadas a callout
        //exception solo hay cuando hay un problema el sistema como no poder reconocer el url que tratas de llamar no esta autorizado es una excepcion no una respuesta, necesitamos ver si es un respuesta exitosa o con error 
        }catch(System.Exception ex){
        //
        }
    }
}