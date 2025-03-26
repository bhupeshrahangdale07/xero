/**
*@Author : Kandisa Technologies
*@description : Schedule Class for Delete Callout Logs
*/
public with sharing class CalloutLogDeleteBatchJobscheduled implements Schedulable {
    /**
    *@description : Execute at regular intervals
    *@param sc
    */
    public void execute(SchedulableContext sc) {
        DeleteLogsBatch b = new DeleteLogsBatch(); 
        database.executebatch(b,200);
    }
}