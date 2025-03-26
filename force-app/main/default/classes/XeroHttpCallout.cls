/**
 * @description Class to manage Callouts happen to Xero
 * @Author : Kandisa Technologies
 * @CreatedDate : 3 Sept 2023
*/
public with sharing class XeroHttpCallout {
    
    /**
     * @description Method to fetch all the currencies from Salesforce as well as Xero
     * @return CalloutWrapper
     * @param endPointUrl
     * @param setHeader
     * @param setMethod
     * @param sBody
    */
    public static CalloutWrapper xeroCallout(String endPointUrl, Map<String, String> setHeader, String setMethod, String sBody){
        CalloutWrapper cw = new CalloutWrapper();
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endPointUrl);
        request.setMethod(setMethod);
        request.setTimeout(120000);
        for(String s : setHeader.keyset()){
            request.setHeader(s, setHeader.get(s));
        }
        request.setHeader('Accept','application/json');
        if(setMethod != 'GET' && sBody != ''){
            request.setBody(sBody);
        }
        HttpResponse response = http.send(request);
        Log__c exc = HandleCustomException.logCallout(request,response);
        cw.response = response;
        cw.exc = exc;
        return cw;
    }

    /**
     * @description Class to manage response receiving from Xero callouts
    */
    public class CalloutWrapper{

        /**
         * @description Holds the response 
        */ 
        @AuraEnabled public HttpResponse response {get; set;}
        /**
         * @description Holds the exception in case of failing 
        */ 
        @AuraEnabled public KTXero__Log__c exc {get; set;}
    }
}