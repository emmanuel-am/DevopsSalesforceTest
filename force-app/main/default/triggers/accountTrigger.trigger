trigger accountTrigger on Account (before insert, after insert, after update) {
    list<Account> lstAccount = new list <Account>([SELECT id, Name FROM Account Limit 10]);
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            for(Account acc : lstAccount){
                System.debug('Nombre de la Cuenta: '+acc.Name);
            }
        }
    } 
    if(Trigger.isAfter){
        //Le decimos que si el trigger es after insert y no esta corriendo debido a batch , future o queueable
        //llamaremos a un metodo que hace un callout
        if(Trigger.isInsert && !System.isBatch() && !System.isFuture() && !System.isQueueable() ){
            Account acc = Trigger.new.get(0);
            if(acc.SyncWithS3__c == True && String.isBlank(acc.S3BucketName__c)){
                AccountTriggerHandler.createBucket(new List<Account>{acc});
            }
        }

        if(Trigger.isUpdate && !System.isBatch() && !System.isFuture() && !System.isQueueable() ){
            // check if sync with s3 is changed and marked as true
            Account acc = Trigger.new.get(0);
            Account oldRecord = Trigger.oldMap.get(acc.Id);
            if(acc.SyncWithS3__c <> oldRecord.SyncWithS3__c && acc.SyncWithS3__c == True && String.isBlank(acc.S3BucketName__c) ){
                AccountTriggerHandler.createBucket(new List<Account>{acc});
            }
        }
    }
}