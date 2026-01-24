public with sharing class OrderTriggerHandler {
    public static void createFolderInsideBucket(Order order){
        List<Account> accList = [SELECT Id, SyncWithS3__c, S3BucketName__c FROM Account WHERE Id =: order.AccountId LIMIT 1];
        if(accList?.size() > 0 && accList.get(0).SyncWithS3__c && String.isNotBlank( accList.get(0).S3BucketName__c ) ){
            // create a folder
            createFolderInsideBucket(accList.get(0).S3BucketName__c, 'orders', order.OrderNumber.toLowerCase()+'-'+String.valueOf(order.Id).toLowerCase() );
        }
    }

    @future(callout = true)
    public static void createFolderInsideBucket(String bucketPath, String folderPath, String folderName ) {
        String endPoint = EncodingUtil.urlEncode(bucketPath, 'UTF-8') + '/'+ EncodingUtil.urlEncode(folderPath, 'UTF-8') +'/'+ EncodingUtil.urlEncode(folderName, 'UTF-8') +'/';
        API_AWSS3Manager.createFolderInsideBucket(endPoint);
    }

    public static void publishEvent(List<Order> newRecords){
        List<Order> orderToPublish = [SELECT OrderNumber FROM Order WHERE Id IN:newRecords ];
        List<OrderStatus__e> orderStatusList = new List<OrderStatus__e>();
        for(Order ord: orderToPublish ){
           OrderStatus__e orderStatus = new OrderStatus__e();
           orderStatus.Order_Number__c = ord.OrderNumber;
           orderStatus.Total_Amount_in_USD__c = 0.00;
           orderStatusList.add(orderStatus);
        }
        EventBus.publish(orderStatusList);
        // throw the Error
        Integer i = 10/0; //si hay un error en la transaccion entera el evento no sera publicado porque tenemos la opcion en el evento de publish after commit
        // si cambiamos publish behavior a publish immediately aunque este el error si te llega la info en maven aunque no crea la orden en salesforce
    }
}