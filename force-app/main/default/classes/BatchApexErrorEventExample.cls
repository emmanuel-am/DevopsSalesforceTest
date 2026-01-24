public with sharing class BatchApexErrorEventExample implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Name FROM Account');
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        Integer i = 100/0;
    }

    public void finish(Database.BatchableContext bc) {

    }
}