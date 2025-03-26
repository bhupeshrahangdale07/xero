@isTest
public class XeroOAuthPageControllerTest {
    @isTest
    static void testpageLoad(){
        PageReference testPage = Page.XeroOAuthPage;
        Test.setCurrentPage(testPage);
        KTXero__Xero_Connection__c kt = TestUtil.createXeroConnection(true);
        System.assertNotEquals(null, kt.Id,'Successfull Xero Connection Record Creation');
        Test.startTest();
        XeroOAuthPageController xcp = new XeroOAuthPageController();
        PageReference testPage1 = xcp.fetchAccessToken();
        System.assertEquals(true, testPage1.getRedirect(),'Valid Redirect');
        Test.stopTest();
    }

    @isTest
    static void testpageLoadMessage(){
        PageReference testPage = Page.XeroOAuthPage;
        Test.setCurrentPage(testPage);

        KTXero__Xero_Connection__c kt = TestUtil.createXeroConnection(true);
        System.assertNotEquals(null, kt.Id,'Successfull Xero Connection Record Creation');
        testPage.getParameters().put('code', '123');

        Test.setMock(HttpCalloutMock.class, new MockHttpResponsetokenGenerator());
        Test.startTest();
        
        XeroOAuthPageController xcp = new XeroOAuthPageController();
        PageReference testPage1 = xcp.fetchAccessToken();
        System.assertEquals(true, testPage1.getRedirect(),'Valid Redirect');
        
        Test.stopTest();
    }

    private class MockHttpResponsetokenGenerator implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            response.setBody('{\"id_token\":\"eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTIwMTgzNjUsImV4cCI6MTY5MjAxODY2NSwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Ijg1NkM2NkUzQzE2QjQxRUJCMkZGOTkzNkUyQjFDMUUwIiwiaWF0IjoxNjkyMDE4MzY1LCJhdF9oYXNoIjoiZVFMZ2NrcWItQldSRVpFZnVfa1AxZyIsInN1YiI6IjI5NTgzNzhkZDI1OTUzMmVhN2FmNGM1ZjIzY2JlYmEwIiwiYXV0aF90aW1lIjoxNjkxNjU1MzQ5LCJ4ZXJvX3VzZXJpZCI6IjBlMTgwYjNkLTMyZmMtNDFlNS1hMTI3LTg2NjEzODA0ZjQzNCIsImdsb2JhbF9zZXNzaW9uX2lkIjoiN2FlMGRjYjk5ZDYyNDIzNzk5Yjg3ZjdkMDhmNzRlOGYiLCJzaWQiOiI3YWUwZGNiOTlkNjI0MjM3OTliODdmN2QwOGY3NGU4ZiIsInByZWZlcnJlZF91c2VybmFtZSI6InJhamVzaEBrYW5kaXNhdGVjaC5jb20iLCJlbWFpbCI6InJhamVzaEBrYW5kaXNhdGVjaC5jb20iLCJnaXZlbl9uYW1lIjoiUmFqZXNoIiwiZmFtaWx5X25hbWUiOiJTaGFoIiwibmFtZSI6IlJhamVzaCBTaGFoIiwiYW1yIjpbInNzbyJdfQ.SytJuoExds64WZN6skfHEIB7pWSO3O2BMIaaDeHeYiyLwuOYisGM9LTV0QfkScvMBCkOKt738kWtTWfE06Kj5xcBZGqx0QVM-U6XBuDQCnh5gSXrRyu9nXTwa-6OCdnqElwBCqecPdPwATbF1dIqI1pwKYfxZnIQtQR2G8HxSEUSXdRfaC-8BMvBPtGK-gpd3NwKAi7rnduCivAb0jh_q4dFqYUvzY9eWB_JT6fcxtfGinF55vEZ0oAezKtWFGO_kENeNPk6rg4gH3I4sNdtVdrE12ClFh5XKv4OGJw6uYsEcCDU0nSHA3W1DJKb8JyjYjGO8lcl0fMT5uYOV23szg\",\"access_token\":\"eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTIwMTgzNjUsImV4cCI6MTY5MjAyMDE2NSwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTY1NTM0OSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6IjdhZTBkY2I5OWQ2MjQyMzc5OWI4N2Y3ZDA4Zjc0ZThmIiwic2lkIjoiN2FlMGRjYjk5ZDYyNDIzNzk5Yjg3ZjdkMDhmNzRlOGYiLCJqdGkiOiJGMTM4QjZGMUMwQURBOTg3Mjc5QzA1MTc5NkFENEVBQSIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiYjdhOGQ1NzItNTY3Yy00NTA5LTk3ZGQtZWQzZTM4ODcwOGMwIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.gmkl2FWBp5Hoj8BrmPLE0VHoD5u1zE150Sso56_wxWLVw9L-yRWAhc3B-c449xbnDzf5Q9PhjePNJV39Ak5ekC3l_QxGByEWbnYXI_Fclj7J9SA897CwWRQo_X3pboxcpGNuqkksqoSqwYU6RLCsWun5otJkvTnGnXIcJI-QlpD4UXSbnh6ghEW11rVsgASWZ8hzA-XBfmkLyRgnpaGwE2WaEWs_wOIQXTr4De2geYxC2zK9dCvsgzSLUx-XJ1rqw1_XwiTkVnSpZLTvixrE-qolVZrl-tE4FqWQ9IDlHH1FO9L2baod6nr6DTUBogIbY4zg_KuRTbM7UK3kaVONUQ\",\"expires_in\":1800,\"token_type\":\"Bearer\",\"refresh_token\":\"2Juhvb9Q7DkLe-tB4qY1nOmrXPPjcYdZMWqAoVXZPAs\",\"scope\":\"email profile openid files projects accounting.settings accounting.attachments accounting.transactions assets accounting.contacts offline_access\"}');
            response.setStatusCode(200);
            return response;
        }
    }//----------------testTokenGeneration---------------
}