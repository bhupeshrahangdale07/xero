@isTest
public with sharing class DeleteLogsBatchTest {
    @isTest
    static void testBatchExecution() {
        List<Log__c> logList = new List<Log__c>();
        for (Integer i = 0; i < 10; i++) {
            Log__c l = new Log__c();
            l.Callout_Log__c = true;
            logList.add(l);
        }
        insert logList;
        
        Test.startTest();
        DeleteLogsBatch batch = new DeleteLogsBatch();
        Database.executeBatch(batch, 10);
        Test.stopTest();
        
        List<Log__c> remainingLogs = [SELECT Id FROM Log__c WHERE Id IN :logList];
        System.assertEquals(0, remainingLogs.size(), 'Not all logs were successfully deleted');
        
    }
    
    @isTest
    static void testBatchExecution1() {
        List<Log__c> logList = new List<Log__c>();
        for (Integer i = 0; i < 10; i++) {
            Log__c l = new Log__c();
            l.Callout_Log__c = true;
            logList.add(l);
        }
        insert logList;
                
        // Create an instance of the batch class
        DeleteLogsBatch batch = new DeleteLogsBatch();
        
        batch.errorMap.put(logList[1].id, 'This is a sample erroe message');
        batch.errorMap.put(logList[2].id, 'This is a sample erroe message');
                
        Database.executeBatch(batch, 10);
        
        System.assertEquals(2, batch.errorMap.size(), 'Errors occurred during batch execution');
        list<log__c> newList = new list <Log__c> ([SELECT Id FROM Log__c WHERE Id IN :batch.errorMap.keyset()]);
        System.assertEquals(2, newList.size(), 'ErrorLogs inserted successfully');

    }
}