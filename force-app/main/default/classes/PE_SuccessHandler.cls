public with sharing class PE_SuccessHandler implements EventBus.EventPublishSuccessCallback {
    public void onSuccess(EventBus.SuccessResult result){ 
        System.debug('Success'); 
        System.debug(result.getEventUuids());  
    } 
}