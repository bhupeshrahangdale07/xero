/**
@Author : Kandisa Technologies
@description : Batch class to delete Callout logs
*/
public with sharing class DeleteLogsBatch implements Database.Batchable<sObject>{

    public Set<Id> allSuccessId = new Set<Id>();
    public Map<Id,String> errorMap = new Map<Id,String>();

    /**
     * @description Start Method
     * @return Database.QueryLocator
     * @param  bc
    */
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id FROM KTXero__Log__c WHERE Callout_Log__c = true WITH SECURITY_ENFORCED';
       
        return Database.getQueryLocator(String.escapeSingleQuotes(query));
    }
    
    /**
     * @description Execute Method
     * @param  bc 
     * @param scope
    */
    public void execute(Database.BatchableContext bc, List<KTXero__Log__c> scope){
        // Delete Logs
        if(scope.size() > 0 && KTXero__Log__c.getSObjectType().getDescribe().isDeletable()){

            Database.DeleteResult[] drList = Database.delete(scope, false);
    
            // Iterate through each returned result
            for(Database.DeleteResult dr : drList) {
                if (dr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    allSuccessId.add(dr.getId());
                }else {
                    // Operation failed, so get all errors
                    String error = '';              
                    for(Database.Error err : dr.getErrors()) {
                        error += err.getStatusCode() +':'+err.getMessage() +', ';
                    }
                    errorMap.put(dr.getId(),error);
                }
            }
        }
    }
    
    /**
     * @description finish Method
     * @param  bc
    */
    public void finish(Database.BatchableContext bc) {
        if(errorMap.keySet().size()>0){
            List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
            for(Id i : errorMap.keySet()){
                KTXero__Log__c exc = new KTXero__Log__c();
                exc.Exception_Message__c = errorMap.get(i);
                exc.StackTrace__c = i;
                exc.MethodName__c = 'execute';
                exc.ClassName__c = 'DeleteLogsBatch';
                logList.add(exc);
            }

            if(logList.size()>0){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    throw new CustomException(flsWrap.message);
                }
            }
        }
    }
}