@RestResource(urlMapping='/v1/webhook/stripe/*')
global class StripeWebhookListner {
   // https://course-pantherschools-dev-ed.develop.my.site.com/Webhooks/services/apexrest/v1/webhook/stripe/
    private static final String SIGNATURE_HEADER = 'Stripe-Signature';
    private static final String ALGORITHM = 'HmacSHA256';
    private static final String webhookSecret = 'whsec_z';

    @HttpPost
    global static void handleStripeWebhook() {
        RestRequest req = RestContext.request;
        String jsonBody = req.requestBody.toString();
        System.debug('Received Stripe webhook: \n ' + jsonBody);
        // Get headers for signature verification
        Map<String, String> headers = req.headers;

        System.debug('Headers: \n ' + JSON.serializePretty(headers));
        if(!isRequestValid(headers, jsonBody)){
            System.debug('Invalid request signature');
            RestContext.response.statusCode = 401;
            RestContext.response.responseBody = Blob.valueOf('{"status":"failure", "message":"Unauthorized request"}');
            return;
        }
         try {
            // Parse the webhook payload
            Map<String, Object> webhookData = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
            String eventType = (String) webhookData.get('type');
            Map<String, Object> eventData = (Map<String, Object>) webhookData.get('data');
            Map<String, Object> stripeObject = (Map<String, Object>) eventData.get('object');
            
            // Handle different Stripe events
            if (eventType == 'payment_intent.succeeded') {
                handlePaymentSuccess(stripeObject);
            } else if (eventType == 'payment_intent.created') {
                handlePaymentSuccess(stripeObject);
            } else if (eventType == 'invoice.payment_succeeded') {
                handleInvoicePayment(stripeObject);
            } else if (eventType == 'customer.subscription.created') {
                handleSubscriptionCreated(stripeObject);
            } else {
                System.debug('Unhandled Stripe event type: ' + eventType);
            }
            
            // Return success response
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf('{"status":"success"}');
            
        } catch (Exception e) {
            // Log error and return error response
            System.debug('Error processing Stripe webhook: ' + e.getMessage());
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('{"status":"error","message":"' + e.getMessage() + '"}');
        }
    }

    private static void handlePaymentSuccess(Map<String, Object> paymentIntent) {
        try {
            Decimal amount = ((Decimal) paymentIntent.get('amount')) / 100; // Convert from cents
            String currency_x = (String) paymentIntent.get('currency');
            String paymentId = (String) paymentIntent.get('id');
            String customerId = (String) paymentIntent.get('customer');
            
            // Create opportunity from payment
            Opportunity opp = new Opportunity(
                Name = 'Stripe Payment - ' + paymentId,
                Amount = amount,
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                Description = 'Payment processed via Stripe. Customer ID: ' + customerId + ', Currency: ' + currency_x.toUpperCase()
            );
            
            insert opp;
            System.debug('Created opportunity for Stripe payment: ' + opp.Id);
            
        } catch (Exception e) {
            System.debug('Error handling payment success: ' + e.getMessage());
            throw e;
        }
    }
    
    private static void handleInvoicePayment(Map<String, Object> invoice) {
        try {
            Decimal amount = ((Decimal) invoice.get('amount_paid')) / 100; // Convert from cents
            String currency_x = (String) invoice.get('currency');
            String invoiceId = (String) invoice.get('id');
            String customerId = (String) invoice.get('customer');
            
            // Create opportunity from invoice payment
            Opportunity opp = new Opportunity(
                Name = 'Stripe Invoice - ' + invoiceId,
                Amount = amount,
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                Description = 'Invoice payment via Stripe. Customer ID: ' + customerId + ', Currency: ' + currency_x.toUpperCase()
            );
            
            insert opp;
            System.debug('Created opportunity for Stripe invoice payment: ' + opp.Id);
            
        } catch (Exception e) {
            System.debug('Error handling invoice payment: ' + e.getMessage());
            throw e;
        }
    }
    
    private static void handleSubscriptionCreated(Map<String, Object> subscription) {
        try {
            String subscriptionId = (String) subscription.get('id');
            String customerId = (String) subscription.get('customer');
            String status = (String) subscription.get('status');
            
            // You might want to create a different record type for subscriptions
            // or use a custom object for recurring revenue tracking
            Opportunity opp = new Opportunity(
                Name = 'Stripe Subscription - ' + subscriptionId,
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                Description = 'New subscription created via Stripe. Customer ID: ' + customerId + ', Status: ' + status,
                Type = 'Existing Customer - Upgrade'
            );
            
            insert opp;
            System.debug('Created opportunity for Stripe subscription: ' + opp.Id);
            
        } catch (Exception e) {
            System.debug('Error handling subscription creation: ' + e.getMessage());
            throw e;
        }
    }

    // t=1749893981,v1=83ed45eee9795f654ace38c80e264f64c2590bf0b4c500c27dc6984910810a68,v0=2f828ae9577a5dc274e43bd80f2228b032accb85a021775eda484f253aa37e22
    public static Boolean isRequestValid(Map<String, String> headers, String payload) {
        String signatures = headers.get('Stripe-Signature');
        Map<String, String> parts = parseStripeSignature(signatures);
        String timestamp = parts.get('t');
        String expectetedSignature = parts.get('v1');
        if(String.isBlank(timestamp) || String.isBlank(expectetedSignature)){
            return false;
        }

        String finalPayload = timestamp + '.' + payload;
        Blob hash = Crypto.generateMac(ALGORITHM, Blob.valueOf(finalPayload), Blob.valueOf(webhookSecret) );
        String actualSingature = EncodingUtil.convertToHex(hash);
        return actualSingature.equals(expectetedSignature); // Placeholder for signature verification logic
    }

    // t=1749893981,v1=83ed45eee9795f654ace38c80e264f64c2590bf0b4c500c27dc6984910810a68,v0=2f828ae9577a5dc274e43bd80f2228b032accb85a021775eda484f253aa37e22
    private static Map<String, String> parseStripeSignature(String signature) {
        Map<String, String> parts = new Map<String, String>();
        String[] elements = signature.split(',');
        
        for (String element : elements) {
            String[] keyValue = element.split('=');
            if (keyValue.size() == 2) {
                parts.put(keyValue[0], keyValue[1]);
            }
        }
        
        return parts;
    }
}