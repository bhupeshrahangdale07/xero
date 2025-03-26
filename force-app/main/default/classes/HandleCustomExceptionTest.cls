@isTest
public with sharing class HandleCustomExceptionTest  {
    
    @isTest
    static void testLogException(){
        CalloutException e = new CalloutException();
    	e.setMessage('This is a constructed exception!');
        
        Test.startTest();
        KTXero__Log__c l = HandleCustomException.logException(e);

        System.assertEquals(false, l.Callout_Log__c,'Calllout log value should be false.');
        Test.stopTest();
    }

    @isTest
    static void testLogCallout(){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('/services/data');
        req.setMethod('GET');
        req.setHeader('Accept', 'application/xml');
        HttpResponse res = new HttpResponse();
        res.setBody('Any string');
        res.setStatus('202');
        res.setStatusCode(404);
        
        Test.startTest();
        Log__c l = HandleCustomException.logCallout(req,res);
        System.assertEquals(true, l.Callout_Log__c, 'Calllout log value should be true.');
        Test.stopTest();
    }

}