@RestResource(urlMapping='/v1/webhooks/quickbooks/*')
// /services/apexrest/v1/webhooks/quickbooks/
global class QuickBooksWebhookListener {

    public static final String verifierToken = '7149e6d0-3edc';
    public static final String SIGNATURE_HEADER = 'intuit-signature';
    public static final String ALGORITHM = 'HmacSHA256';
    
    @HttpPost
    global static void doPost(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String requestBody = req.requestBody.toString();
        System.debug('Received QuickBooks webhook request: \n ' + requestBody);

        Map<String, String> headers = req.headers;
        if(!isRequestValid(requestBody, headers)){
            System.debug('Invalid request signature');
            res.statusCode = 401; // Unauthorized
            res.responseBody = Blob.valueOf('{"status":"error", "message":"Invalid request signature"}');
            return;
        }
        System.debug('Valid request signature');
        /** Return the response to Quickbooks */
        res.statusCode = 200;
        res.responseBody = Blob.valueOf('{"status":"success", "message":"Valid request signature"}');
    }

    public static Boolean isRequestValid(String pyaload, Map<String, String> headers){
        //Boolean isValid = false;
        String requestSignature = headers.get(SIGNATURE_HEADER);
        /** check if requestSignature is blank then return false */
        if( String.isBlank(requestSignature)){
            System.debug('Request signature is blank');
            return false;
        }
        Blob privateKey = Blob.valueOf(verifierToken);
        Blob payloadBlob = Blob.valueOf(pyaload);
        Blob encodedHash = Crypto.generateMac(ALGORITHM, payloadBlob, privateKey);
        String expectedSignature = EncodingUtil.base64Encode(encodedHash);
        //isValid = expectedSignature.equals(requestSignature);
        return expectedSignature.equals(requestSignature);
    }
}

// https://course-pantherschools-dev-ed.develop.my.site.com/Webhooks/services/apexrest/v1/webhooks/quickbooks/