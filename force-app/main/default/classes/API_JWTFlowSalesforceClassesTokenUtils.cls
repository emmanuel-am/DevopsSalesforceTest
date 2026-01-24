public with sharing class API_JWTFlowSalesforceClassesTokenUtils {
    // API_JWTFlowSalesforceClassesTokenUtils.run();
    public static void run(){
        Auth.JWT jwt = new Auth.JWT();
        jwt.setSub('emmanuel_am1@curious-bear-5178gq.com');
        jwt.setAud('https://login.salesforce.com');
        jwt.setIss('3MVG9cHH2bfKACZYlvhZuxttOsHk_xjrrdhd_tvhnUd47oI2Qr_JIv0pVxKKnihqtkNkRNvvXNn_ObTbjTlhd');
        System.debug(jwt.toJSONString());

        //Create the object that signs the JWT bearer token
        Auth.JWS jws = new Auth.JWS(jwt,'integrationcert');

        String tokenEndpoint ='https://login.salesforce.com/services/oauth2/token';

        Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(tokenEndpoint, jws);

        //Get the access token
        String accessToken = bearer.getAccessToken();
        system.debug('Access Token--> \n '+accessToken);
        getUserInfo(accessToken);
    }

    public static void getUserInfo(String accessToken){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://dhn000002vxjomao-dev-ed.develop.my.salesforce.com/services/oauth2/userinfo');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer '+accessToken);
        req.setHeader('Content-Type', 'application/json');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        String response = res.getBody();
    }
}