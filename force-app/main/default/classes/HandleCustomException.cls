/**
@Author : Kandisa Technologies
@description : This class contains methods to Create log for Callout and Exception
*/
public with sharing class HandleCustomException extends Exception {
    /**
     * @description Method to create log record from Exception. This method will be called from multiple Classes
     * @return  KTXero__Log__c 
     * @param  e 
    */
    public static KTXero__Log__c logException(Exception e){
        KTXero__Log__c exc = new KTXero__Log__c();
        try{
            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String className = stackTrace.substringAfter('.').substringAfter('.').substringBefore('.');	
            String methodName = stackTrace.substringAfter('.').substringAfter('.').substringAfter('.').substringBefore(':');
                
            //Governer Limit of executingQuery 
            String queryLimit = '1. SOQL Queries used / SOQL Queries allowed: ' + Limits.getQueries() + '/' + Limits.getLimitQueries();
            String dmLimit = '2. Number of records queried so far /  Number allowed: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows();
            String dmlStat = '3. Number of DML statements used so far / Number allowed: ' +  Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements();   
            String cPUT = '4. Amount of CPU time (in ms) used so far / CPU usage time (in ms) allowed: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();
            
            //Log information in object
            exc.KTXero__Govt_Limit_in_Executing_Code__c = String.format('{0}\n{1}\n{2}\n{3}',new List<string>{queryLimit, dmLimit,dmlStat,cPUT});
            if(String.isNotBlank(e.getMessage())){

                exc.KTXero__Exception_Message__c = e.getMessage();
            }
            exc.KTXero__Exception_Type__c = e.getTypeName();
            exc.KTXero__Line_Number__c = e.getLineNumber();
            exc.KTXero__StackTrace__c = e.getStackTraceString();
            exc.KTXero__MethodName__c = methodName;
            exc.KTXero__ClassName__c = className;
            exc.KTXero__Callout_Log__c = false;
            
        }catch(Exception ex){
            throw ex;
        }   
        return exc;      
    }

    /**
     * @description Method to create log record of Callout. This method will be called from multiple Classes
     * @return  KTXero__Log__c 
     * @param  request 
     * @param  response 
    */
    public static KTXero__Log__c logCallout(HttpRequest request, HttpResponse response){
        KTXero__Log__c exc = new KTXero__Log__c();
        try{
            
            //Log information in object
            exc.Callout_Log__c = true;
            
            // HttpRequest request info
            exc.Request_Endpoint__c = request.getEndpoint();
            exc.Request_Body__c = request.getBody();
            exc.Request_Method__c = request.getMethod();
            
            //HttpResponse response info
            if(response.getBody().length() > 130000){
                exc.Response_body__c = response.getBody().left(130000);
            }else{
                exc.Response_body__c = response.getBody();
            }
            exc.Response_Status_Code__c = response.getStatusCode();
            exc.Response_Status__c = response.getStatus();
            // database.insert(exc);
        }catch(Exception e){
           throw e;
        }
        return exc;
    }
}