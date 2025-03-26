@isTest
public with sharing class SetupConfigControllerTest {
    
    @isTest
    static void testgetXeroConnection(){
        TestUtil.createXeroConnection(true);
        Test.startTest();
        SetupConfigController.XeroConnectionWrap sWrap = SetupConfigController.getXeroConnection();
        System.assertNotEquals(null, sWrap,'Valid result');
        Test.stopTest();
    }

    @isTest
    static void testscheduleRefreshToken(){

            Test.setMock(HttpCalloutMock.class, new MockHttpResponserefreshToken());
            
            TestUtil.createXeroConnection(true);
            Test.startTest();
    
            Boolean flag = SetupConfigController.scheduleRefreshToken();
            System.assertEquals(true, flag, 'Valid Result');
    
            Test.stopTest();
    }
   

    @isTest
    static void testgetSites(){
        Test.startTest();

        List<SetupConfigController.SiteWrapper> siteWrap = SetupConfigController.getSites();

        Test.stopTest();

        System.assertEquals(1, siteWrap.size(),'Valid Result');        
    }

    @isTest
    static void testgetSecureSiteURL(){
        Test.startTest();
        
        Site st = [SELECT Id FROM Site LIMIT 1];
        SiteDetail sd = [SELECT Id, DurableId, SecureUrl FROM SiteDetail WHERE DurableId =: st.Id];
        String siteURL = SetupConfigController.getSecureSiteURL(sd.DurableId);
        
        Test.stopTest();
        
        System.assertNotEquals(null, siteURL,'Valid Result');
    }

    @isTest
    static void testSaveXeroConnection(){
        TestUtil.createXeroConnection(true);
        Test.startTest();

        SetupConfigController.XeroConnectionWrap sWrap = SetupConfigController.getXeroConnection();
        SetupConfigController.XeroConnectionResultWrap xcWrap = SetupConfigController.saveXeroConnection(JSON.serialize(sWrap));
        System.assertEquals(true, xcWrap.flag,'Valid Result');

        Test.stopTest();
    }

    @isTest
    static void testfetchPermissionSets(){
        Test.startTest();
        
        List<SetupConfigController.PermissionWrapper> perWrap = SetupConfigController.fetchPermissionSets();

        System.assertEquals(3, perWrap.size(),'Valid Result');

        Test.stopTest();
    }

    @isTest
    static void testgetTenants(){
        TestUtil.createXeroConnection(true);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseConnectionCallout());
        Test.startTest();

        List<SetupConfigController.TenantWrapper> tenantWrap = SetupConfigController.getTenants();
        System.assertEquals(1, tenantWrap.size(),'Valid Result');

        Test.stopTest();
    }

    private class MockHttpResponseConnectionCallout implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('[{\"id\":\"cf6b8b63-d716-44b0-95af-bd67712fbf09\",\"authEventId\":\"26d39c35-5f4a-4ed3-865d-e458f5e93f52\",\"tenantId\":\"7ba1138a-ae87-411a-ae0a-ed5768f597d4\",\"tenantType\":\"ORGANISATION\",\"tenantName\":\"Demo Company (Global)\",\"createdDateUtc\":\"2023-07-26T05:07:57.0160230\",\"updatedDateUtc\":\"2023-07-26T05:07:57.0181750\"}]');
            response.setStatusCode(200);
            return response;
        }
    }
    private class MockHttpResponserefreshToken implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            // response.setBody('[{\"id\":\"cf6b8b63-d716-44b0-95af-bd67712fbf09\",\"authEventId\":\"26d39c35-5f4a-4ed3-865d-e458f5e93f52\",\"tenantId\":\"7ba1138a-ae87-411a-ae0a-ed5768f597d4\",\"tenantType\":\"ORGANISATION\",\"tenantName\":\"Demo Company (Global)\",\"createdDateUtc\":\"2023-07-26T05:07:57.0160230\",\"updatedDateUtc\":\"2023-07-26T05:07:57.0181750\"}]');
            response.setBody('{\"id_token\":\"eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE3MTQ0ODEyNzcsImV4cCI6MTcxNDQ4MTU3NywiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Ijg1NkM2NkUzQzE2QjQxRUJCMkZGOTkzNkUyQjFDMUUwIiwiaWF0IjoxNzE0NDgxMjc3LCJhdF9oYXNoIjoiclNBOHE1NGFiYVBHN3lzUVZtSWJTUSIsInN1YiI6IjI5NTgzNzhkZDI1OTUzMmVhN2FmNGM1ZjIzY2JlYmEwIiwiYXV0aF90aW1lIjoxNzE0NDgwOTc0LCJ4ZXJvX3VzZXJpZCI6IjBlMTgwYjNkLTMyZmMtNDFlNS1hMTI3LTg2NjEzODA0ZjQzNCIsImdsb2JhbF9zZXNzaW9uX2lkIjoiMzE0NTExZTFiY2M5NDYwNTgyZmFmNDAwZjI5OWVmNTkiLCJzaWQiOiIzMTQ1MTFlMWJjYzk0NjA1ODJmYWY0MDBmMjk5ZWY1OSIsInByZWZlcnJlZF91c2VybmFtZSI6InJhamVzaEBrYW5kaXNhdGVjaC5jb20iLCJlbWFpbCI6InJhamVzaEBrYW5kaXNhdGVjaC5jb20iLCJnaXZlbl9uYW1lIjoiUmFqZXNoIiwiZmFtaWx5X25hbWUiOiJTaGFoIiwibmFtZSI6IlJhamVzaCBTaGFoIiwiYW1yIjpbInB3ZCJdfQ.P2lk9_atpRy0b-TZ0yc5zYjqb5Z_uYrixu2l7fcoll20zqLhJVcUb3vUQuKkpBIlQdJ8yyRzBX6ZirON43y-BE4JpP10zYAwfS83U4USBLVmqu7tv1CFaW8MYn55ejCT28djwftK6ckHJg4vtHdjESrDJZ0whFBRlxNCI3y20IpfwmC18d3zVCGFn1zXZl7P0xWnL-ditE8NQDeVRFnYrn10I897pNvkK0-gTxyxN5zwrk0zNHUxUxBe3YBAe3WtXzIGogkRZxOADz8O1t4obV4FbvHD1--Mh2qG5lMnkB3YbRK0vwE5za0P4LZV7fuJu6KcbDLKEyQ6Z3oR6W6_UQ\",\"access_token\":\"eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE3MTQ0ODEyNzcsImV4cCI6MTcxNDQ4MzA3NywiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTcxNDQ4MDk3NCwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6IjMxNDUxMWUxYmNjOTQ2MDU4MmZhZjQwMGYyOTllZjU5Iiwic2lkIjoiMzE0NTExZTFiY2M5NDYwNTgyZmFmNDAwZjI5OWVmNTkiLCJqdGkiOiI1MjUwMDlDRDk0QkY0NjY0Mzk5Q0M5QzcxQjBBRDkyNSIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiZWEyMjE1NDAtNzI0Yy00OWRlLTgyMzUtYWI3Zjg0MGZhY2I4Iiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInB3ZCJdfQ.JJFKK6P5xkh9KxZ4rj_PS_mvFwFXlPM8GwbYQsb1PGLfkfZg2Fwym6c76yDSAo0DLoOFE1Qsz3DIhOEeeY_bTlqXaF1SYZJecHjqbeJ9cLY5X_HX5RVBU7kP-feThhwKlaE0dLsev8ERdDslC226XhFJ6SP7LypjXLl1DqSZPmN6fT7i9Zba8BZwXsqQMZN1xw-LnswE_ya1s8THF980MEDR6BUiQlyXpSCNXPdSeXK3KJNXlDLYbvvZnWbz9v01G_KDZJAWr6ZtqBMceqgxwihvmzKMNlDv24XU0iBFBbAR4YdyYKJpoFuSGNgBHA_J8EiHNRN4ahNqxs0vcqhMwg\",\"expires_in\":1800,\"token_type\":\"Bearer\",\"refresh_token\":\"AIBHuCz0MjOqi90crreQHSOxPHG6cSHTOhFjP55pkco\",\"scope\":\"email profile openid files projects accounting.settings accounting.attachments accounting.transactions assets accounting.contacts offline_access\"}');
            response.setStatusCode(200);
            return response;
        }
    }

    @isTest
    static void testAssignWebhookPermission() {

        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String uid = h.SubString(0,8);
        String pId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        User u = new User(Alias = uid, Email= uid + '@testdomain.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = pId, 
            TimeZoneSidKey='America/New_York', UserName= uid + '@testdomain.com');      
        insert u;

        // Call the method with the guest user id
        Test.startTest();
        Boolean result = SetupConfigController.assignWebhhokPermission(u.Id);
        Test.stopTest();

        // Assert that the result is true
        System.assertEquals(true, result, 'Success');
    }

    @isTest
    static void testAssignPermission(){

        PermissionSet pr = [SELECT Id, Label, Name FROM PermissionSet WHERE Name = 'Xero_Webhook_Permission_Set_for_Site_User' WITH SECURITY_ENFORCED LIMIT 1];
        Boolean flag = Utils.assignPermissions(pr.Id);
        System.assertEquals(True, flag, 'Success');
    }
}