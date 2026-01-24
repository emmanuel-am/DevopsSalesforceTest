// Org Base Url - Instance Url + services/apexrest/v1/PS_AccountManager
// https://integration-org2-dev-ed.develop.my.salesforce.com/services/apexrest/v1/PS_AccountManager/
//
@RestResource(urlMapping = '/v1/PS_AccountManager/*') //usas el * para poder extender mas despues
global with sharing class PS_AccountManager {
    /**
    * @httpGet - GET
    * @httpPost - POST
    * @httpPut - PUT
    * @hpptPatch - PATCH
    * @delete - DELETE
    */
    /** List all the Salesforce Accounts - GET */
    /*@httpGet
    global static List<Account> getAccountList(){
        RestRequest req = RestContext.request; //te da que viene a ti
        System.debug(System.JSON.serializePretty(req));
        RestResponse res = RestContext.response;
        System.debug(System.JSON.serializePretty(res));
        return [SELECT Id, Name, Industry, Phone, Fax FROM Account LIMIT 10];
    }*/

    @httpDelete
    global static void deleteRecords(){
        String accountId = RestContext.request.requestURI.substringAfterLast('/');
        Database.delete(accountId);
    }

    @httpPatch
    global static Account updateAccount(){
        RestRequest req = RestContext.request;
        String accountId = req.requestURI.substringAfterLast('/');
        String request = req.requestBody.toString();
        Map<String,String> urlParams = req.params;
        //_HttpMethod=PATCH&name=Amit Singh
        //'_HttpMethod' => PATCH
        //'name' => Amith Singh
        //asi es como se accedera a los parametros del URL, y ya puedes hacer algo con el mapa y sus valores del URL
        Map<String,String> headersMap = req.headers;
        //puedes hacer lo mismo con los headers y token, todo lo que envies como request estara disponible en Rest Request Class 
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(request);
        //Name, Active, Industry
        Account accountToUdapte = new Account(Id = accountId);
        accountToUdapte.Name = (String)responseMap.get('accountName');
        accountToUdapte.Active__c = (String)responseMap.get('active');
        accountToUdapte.Industry = (String)responseMap.get('accountIndustry');
        accountToUdapte.AnnualRevenue = (Decimal)responseMap.get('AnnualRevenue');
        Database.update(accountToUdapte);
        return accountToUdapte;
    }

     /** List all the Salesforce Accounts - GET */
    // /v1/PS_AccountManager/001Hu000038SWuZIAW/Contacts
    //Se recomienda no pasar body en el get metodo, se recomienda por medio de la URL
    @httpGet
    global static Account getAccountList(){

        RestRequest req = RestContext.request;
        System.debug(System.JSON.serializePretty(req));

        RestResponse res = RestContext.response;
        System.debug(System.JSON.serializePretty(res));
        
        // /v1/PS_AccountManager/001Hu000038vjRiIAI
        /**
        * 1 - Get the Account ID from URL
            * 1.1 - get last index of /
            * 1.2 - use the substring method of your String Apex Class
            * 1.1.1 - subStringAfterLast method of your String class
        * 2 - Query the Account with all the Information
        */
        String accountId = req.requestURI.substringAfterLast('/');
        Account accRecord = [SELECT 
                                Id, Name, Rating, Phone, Fax, Industry, BillingAddress, ShippingAddress
                                FROM
                                    Account
                                WHERE
                                    Id =: accountId
                                LIMIT 1
                            ];
        return accRecord;
    }

    /** Create an Account - POST */
    @httpPost
    global static Account createAccount(){ // le pasas method arguments o request body no ambos, si le pasas arguments el requestBody sera null
        /** Get the information about Request */
        RestRequest req = RestContext.request;
        System.debug(System.JSON.serializePretty(req));

        /** get the request body */
        String requeBody = req.requestBody?.toString(); // Convert Blob into String format
        System.debug( requeBody );

        RestResponse res = RestContext.response;
        System.debug(System.JSON.serializePretty(res));
        
        //PS_AccountService.formatString(null);
        if(String.isBlank(requeBody)){
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('{"message": "Request Body can not be blank!"}');
            //return res;
         }

        Account acc = new Account();
        acc.Name = UUID.randomUUID().toString();
        acc.Phone = '98876655623';
        
        return acc;
    }
    
    /* Si te dicen quepor ejemplo no quieren los atributos de la respuesta que dice attributes y type y url
     {
        "attributes":{
            "type":"Account",
            "url": "/services/data/v59.0/sobjects/Account/000121232"
        },
        "Id": "7686876",
        "Name": "Test"
     }
    
    solo quieres los demas campos, la solucion sera crear un response wrapper donde esten todas las 
     variables incluso para billing addres, creamos su clase
    */
    public class AccountWrapper {
        public String id;
        public String name;
        public BillingAddress billigAddress;
    }

    public class BillingAddress {
        public String city;
    }
}