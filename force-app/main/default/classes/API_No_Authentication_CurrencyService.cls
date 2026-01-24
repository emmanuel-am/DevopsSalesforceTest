public with sharing class API_No_Authentication_CurrencyService {
    public static void getExchangeRates() {

        /*Callouts Only */
        /*Step 1 - Prepare the request */
        HttpRequest httpReq = new HttpRequest();
        //Si tu estas haciendo un callout a un sisetma externo tu tienes un URL
        /* Step 1.1 - Send the endpoint */
        httpReq.setEndpoint('https://open.er-api.com/v6/latest/USD');
        /* Step1.2 - Set the Headers */
        httpReq.setHeader('Content-Type', 'application/json'); //cual es la respuesta el sistema va a darnos, en este caso estamos cosniguiendo la informacion en el formato de JSON 
        //Cuando tu API esta retornando JSON como respuesta le decimos que acepte JSON, no importa los diferentes formatos que tienes disponibles solo acepto JSON
        httpReq.setHeader('Accept', 'application/json'); // JSON, XML, Text, HTML
        /* Step1.3 - Set the Method */
        //Debido a que podemos aceptar este URL desde el browser sin autenticacion o algo requerido significa es un metodo get
        httpReq.setMethod('GET'); //GET, POST, PUT, PATCH, DELETE
        /* Step 2 - Send the Request */ 
        //siempre que hacemos un callout necesitamos que poner el callout dentro de un try catch
        try{
            Http http = new Http();
            HttpResponse httpResp = http.send(httpReq);
            /* Step 3 - Print the information */
            /*
            getStatus()
            getStatusCode()y
            getBody()
            getXmlStreamReader() ---> SOAP
            getBodyAsBlob()
        */
            String responseBody = httpResp.getBody();
            Integer statusCode = httpResp.getStatusCode();
            String status = httpResp.getStatus();
            System.debug('The Response from Currency API: '+status);
            System.debug('The Response from Currency API: '+responseBody);
            System.debug('The Response from Currency API: '+statusCode);
        }catch(System.CalloutException calloutEx){ //si hay un error debido al callout este bloque se ejecuta
            System.debug('System.CalloutException.... '+ calloutEx.getStackTraceString());
            if(String.valueOf(calloutEx).startsWith('System.CalloutException: Unauthorized endpoint')){
                //Remote Site missing Error
                System.debug('CalloutException ...');
            }
        }catch(System.Exception ex){
            System.debug('Exception Executed ...'+ex.getStackTraceString());
            if(String.valueOf(ex).startsWith('System.CalloutException: Unauthorized endpoint')){
                //Remote Site missing Error
                System.debug('Executed ...');
            }
        }
    }
}