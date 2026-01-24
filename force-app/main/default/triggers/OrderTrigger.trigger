trigger OrderTrigger on Order (after insert) {
    if(Trigger.isAfter){
        if(Trigger.isInsert && !System.isBatch() && !System.isFuture() && !System.isQueueable() ){
            OrderTriggerHandler.createFolderInsideBucket(Trigger.new.get(0));
            //OrderTriggerHandler.publishEvent(Trigger.New);
        }
    }
}