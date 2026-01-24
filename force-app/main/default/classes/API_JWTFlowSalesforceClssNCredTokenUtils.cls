public with sharing class API_JWTFlowSalesforceClssNCredTokenUtils {
     // API_JWTFlowSalesforceClssNCredTokenUtils.run();
    public static void run(){
        Auth.JWT jwt = new Auth.JWT();
        jwt.setSub('emmanuel_am1@curious-bear-5178gq.com');
        jwt.setAud('https://login.salesforce.com');
        jwt.setIss('3MVG9OGq41FnYVsH3MVG9cHH2bfKACZYlvhZuxttOsHk_xjrrdhd_tvhnUd47oI2Qr_JIv0pVxKKnihqtkNkRNvvXNn_ObTbjTlhd');
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
        String loggedInUserInfo ='/services/oauth2/userinfo';

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:JWTOrg'+loggedInUserInfo);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');

        HTTPResponse res = (new Http()).send(req);
        System.debug(res.getstatuscode());
        System.debug(res.getBody());
    }
}