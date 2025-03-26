@isTest
public class CurrencyConfigControllerTest {
    
    @isTest
    static void testgetCurrency() {
  
        TestUtil.createXeroConnection(true);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorCurrency());

        Test.startTest();
        CurrencyConfigController.CurrecnyWrapper cw = CurrencyConfigController.getCurrency();
        if(Utils.getIsMultiCurrencyOrg()){
            System.assertNotEquals(null, cw.salesforceCurr,'Success');
        }else{
            System.assertEquals(null, cw.salesforceCurr,'Success');
        }
        Test.stopTest();

    }

    @isTest
    static void testgetCurrencyTokenExpire() {
  
        KTXero__Xero_Connection__c xc = TestUtil.createXeroConnection(false);
        xc.KTXero__Last_Token_Refresh_Time__c = System.now().addDays(-2);
        insert xc;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorCurrency());

        Test.startTest();
        CurrencyConfigController.CurrecnyWrapper cw = CurrencyConfigController.getCurrency();
        if(Utils.getIsMultiCurrencyOrg()){
            System.assertNotEquals(null, cw.salesforceCurr,'Success');
        }else{
            System.assertEquals(null, cw.salesforceCurr,'Success');
        }
        Test.stopTest();

    }
   
   
    @isTest
    static void testCreateCurrency() {

        //  KTXero__Encryption_Configuration__c cst = TestUtil.createEncryptionConfig();
        
        
        // KTXero__Xero_Connection__c obj = new KTXero__Xero_Connection__c(KTXero__Access_Token__c = Utils.processEncryption('eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTE1NzQ2MDAsImV4cCI6MTY5MTU3NjQwMCwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTQ4MjAwOSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6Ijg3Zjc5ZDE1ZThmYTQxZDg4OWU2MTc4MzBkNjY0YWUzIiwic2lkIjoiODdmNzlkMTVlOGZhNDFkODg5ZTYxNzgzMGQ2NjRhZTMiLCJqdGkiOiIzQkQ2M0E1MkE2RjRDRTQzNTdDRDM4NUQ2MkFDNjg4RiIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiODY3ZWQ0MDctZjg2MC00YTQ3LTkzY2UtNzY1ZDQ2ZjQ0YTVhIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.r9TWEy7q4n3rEKmgM_PTj1k2U-BSJNrZvSY3biHXPaQnn_R26TLhuV9qus0RIpDfs7XZ9P0bIadRkodXe_loYqOLRkRYo8bmquyq-IrPfx8cPx18qDxfpMK8nqr_n3CHF-JZpUw_4zV_JpiMUZ0zvEbTyMFjVT7W7AmAeeppL2QoC64EbSr_9E42bKoAn14q7KaLeWi6dQLSQJ6UowXgfiKoga9qrJ1CqznK-NMy7mkzwwT4nQDjieebBTo0KgKX7nCjX_cQKmUxOMzxkanZzprlGYkckIvyN88kkia_Vg-1T7jTAvIdPpb7qtF1DkhWxs4HiHI0Pk5zG65fGeqARA'), KTXero__Refresh_Token__c = Utils.processEncryption('iMrWhs51ztFLOM9sxr6Ge5juXHXU3mszSbQo-b3d0_I'), KTXero__Tenant_Id__c = Utils.processEncryption('7ba1138a-ae87-411a-ae0a-ed5768f597d4'));
        // insert obj;
        TestUtil.createXeroConnection(true);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorCreateCurr());

        Test.startTest();

        // String requestbody = '{"Id": "f6352318-0e29-46bb-8013-e938a05764dc","Status": "OK","ProviderName": "Salesforce Application","DateTimeUTC": "/Date(1691581592593)/","Currencies": [{"Code": "BZD","Description": "Belize  Dollar"}]}';
        // String strResult = CurrencyConfigController.createXeroCurrencies(requestbody);
        // System.assertNotEquals('', strResult, 'Success');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorCreateCurr1());
        String requestbody1 = 'GWP';
        String strResult = CurrencyConfigController.createXeroCurrencies(requestbody1);
        System.assertNotEquals('', strResult, 'Successfull');

        Test.stopTest();
    }

    @isTest
    static void testCreateCurrencyTokenExpire() {

        //  KTXero__Encryption_Configuration__c cst = TestUtil.createEncryptionConfig();
        
        
        // KTXero__Xero_Connection__c obj = new KTXero__Xero_Connection__c(KTXero__Access_Token__c = Utils.processEncryption('eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTE1NzQ2MDAsImV4cCI6MTY5MTU3NjQwMCwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTQ4MjAwOSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6Ijg3Zjc5ZDE1ZThmYTQxZDg4OWU2MTc4MzBkNjY0YWUzIiwic2lkIjoiODdmNzlkMTVlOGZhNDFkODg5ZTYxNzgzMGQ2NjRhZTMiLCJqdGkiOiIzQkQ2M0E1MkE2RjRDRTQzNTdDRDM4NUQ2MkFDNjg4RiIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiODY3ZWQ0MDctZjg2MC00YTQ3LTkzY2UtNzY1ZDQ2ZjQ0YTVhIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.r9TWEy7q4n3rEKmgM_PTj1k2U-BSJNrZvSY3biHXPaQnn_R26TLhuV9qus0RIpDfs7XZ9P0bIadRkodXe_loYqOLRkRYo8bmquyq-IrPfx8cPx18qDxfpMK8nqr_n3CHF-JZpUw_4zV_JpiMUZ0zvEbTyMFjVT7W7AmAeeppL2QoC64EbSr_9E42bKoAn14q7KaLeWi6dQLSQJ6UowXgfiKoga9qrJ1CqznK-NMy7mkzwwT4nQDjieebBTo0KgKX7nCjX_cQKmUxOMzxkanZzprlGYkckIvyN88kkia_Vg-1T7jTAvIdPpb7qtF1DkhWxs4HiHI0Pk5zG65fGeqARA'), KTXero__Refresh_Token__c = Utils.processEncryption('iMrWhs51ztFLOM9sxr6Ge5juXHXU3mszSbQo-b3d0_I'), KTXero__Tenant_Id__c = Utils.processEncryption('7ba1138a-ae87-411a-ae0a-ed5768f597d4'));
        // insert obj;
        KTXero__Xero_Connection__c xc = TestUtil.createXeroConnection(false);
        xc.KTXero__Last_Token_Refresh_Time__c = System.now().addDays(-1);
        insert xc;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorCreateCurr());

        Test.startTest();

        // String requestbody = '{"Id": "f6352318-0e29-46bb-8013-e938a05764dc","Status": "OK","ProviderName": "Salesforce Application","DateTimeUTC": "/Date(1691581592593)/","Currencies": [{"Code": "BZD","Description": "Belize  Dollar"}]}';
        // String strResult = CurrencyConfigController.createXeroCurrencies(requestbody);
        // System.assertNotEquals('', strResult, 'Success');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorCreateCurr1());
        String requestbody1 = 'GWP';
        String response = CurrencyConfigController.createXeroCurrencies(requestbody1);


        Test.stopTest();

        System.assertNotEquals('', response, 'Valid Response');
    }

    private class MockHttpResponseGeneratorCurrency implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Id\": \"122febdd-626f-4a81-8bfa-cbddee7e1f25\",\"Status\": \"OK\",\"ProviderName\": \"Salesforce Application\",\"DateTimeUTC\":\"/Date(1691574570141)/\",\"Currencies\": [{	\"Code\": \"USD\",	\"Description\": \"United States Dollar\"},{	\"Code\": \"AED\",\"Description\": \"United Arab Emirates Dirham\"},{\"Code\": \"AFN\",\"Description\": \"Afghan Afghani\"},{\"Code\": \"AMD\",\"Description\": \"Armenian Dram\"}]}');
            response.setStatusCode(200);
            return response;
        } 
    }

    private class MockHttpResponseGeneratorCreateCurr implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Code\":\"BZD\", \"Description\":\"BZD\"}');
            response.setStatusCode(200);
            return response;
        } 
    }
    
    @isTest
    static void testCreateCurrency2() {

        TestUtil.createXeroConnection(true);


        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorCreateCurr1());

        Test.startTest();

        String requestbody = '{"Id": "f6352318-0e29-46bb-8013-e938a05764dc","Status": "OK","ProviderName": "Salesforce Application","DateTimeUTC": "/Date(1691581592593)/","Currencies": [{"Code": "BZD","Description": "Belize  Dollar"}]}';
        String strResult = CurrencyConfigController.createXeroCurrencies(requestbody);
        System.assertNotEquals('', strResult, 'Success');    
     
        Test.stopTest();
    }
    
    private class MockHttpResponseGeneratorCreateCurr1 implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"ErrorNumber\": 10,\"Type\": \"ValidationException\",\"Message\": \"A validation exception occurred\",\"Elements\": [{\"Code\": \"GWP\",\"Description\": \"GWP\",\"ValidationErrors\": [{\"Message\": \"No currency exists for code \'GWP\'\"}]}]}');
            response.setStatusCode(400);
            return response;
        } 
    }

    @isTest
    static void testgetSFURL(){
        Test.startTest();
        String x = Utils.getSFURL('Currency');
        System.assertNotEquals('', x, 'Success');
        String y = Utils.getSFURL('Sites');
        System.assertNotEquals('', y, 'Success');
        String z = Utils.getSFURL('VFURL');
        System.assertNotEquals('', z, 'Success');
        String za = Utils.getSFURL('');
        System.assertNotEquals('', za, 'Success');
        Test.stopTest();
    }
}