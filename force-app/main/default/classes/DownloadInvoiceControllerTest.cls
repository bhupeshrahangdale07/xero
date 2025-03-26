@isTest
public class DownloadInvoiceControllerTest {

    @isTest
    static void testgetCurrency() {
        
        Account acc = TestUtil.createAccount(True);

        Opportunity opp = TestUtil.createOpportunity(True, acc.Id);

        // KTXero__Xero_Connection__c obj = new KTXero__Xero_Connection__c(KTXero__Access_Token__c = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTE1NzQ2MDAsImV4cCI6MTY5MTU3NjQwMCwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTQ4MjAwOSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6Ijg3Zjc5ZDE1ZThmYTQxZDg4OWU2MTc4MzBkNjY0YWUzIiwic2lkIjoiODdmNzlkMTVlOGZhNDFkODg5ZTYxNzgzMGQ2NjRhZTMiLCJqdGkiOiIzQkQ2M0E1MkE2RjRDRTQzNTdDRDM4NUQ2MkFDNjg4RiIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiODY3ZWQ0MDctZjg2MC00YTQ3LTkzY2UtNzY1ZDQ2ZjQ0YTVhIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.r9TWEy7q4n3rEKmgM_PTj1k2U-BSJNrZvSY3biHXPaQnn_R26TLhuV9qus0RIpDfs7XZ9P0bIadRkodXe_loYqOLRkRYo8bmquyq-IrPfx8cPx18qDxfpMK8nqr_n3CHF-JZpUw_4zV_JpiMUZ0zvEbTyMFjVT7W7AmAeeppL2QoC64EbSr_9E42bKoAn14q7KaLeWi6dQLSQJ6UowXgfiKoga9qrJ1CqznK-NMy7mkzwwT4nQDjieebBTo0KgKX7nCjX_cQKmUxOMzxkanZzprlGYkckIvyN88kkia_Vg-1T7jTAvIdPpb7qtF1DkhWxs4HiHI0Pk5zG65fGeqARA', KTXero__Refresh_Token__c = 'iMrWhs51ztFLOM9sxr6Ge5juXHXU3mszSbQo-b3d0_I', KTXero__Tenant_Id__c = '7ba1138a-ae87-411a-ae0a-ed5768f597d4', KTXero__Last_Token_Refresh_Time__c = System.now());
        // insert obj;

        TestUtil.createXeroConnection(true);

        Invoice__c testInvoice = new Invoice__c(Name = 'Test Invoice', Invoice_Id__c = '123', Status__c = 'Paid', KTXero__Opportunity__c = opp.Id, KTXero__Account__c = acc.Id);
        insert testInvoice;

        Invoice__c testInvoice1 = [SELECT Id FROM Invoice__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForDLInvoice());

        Test.startTest();
        DownloadInvoiceController.ResultWrap inv = DownloadInvoiceController.downloadInvoice(testInvoice1.Id);
        System.assertEquals(true, inv.successFlag, 'Success');
        Test.stopTest();

    }

    private class MockHttpResponseGeneratorForDLInvoice implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            String str = 'abc';
            response.setBodyAsBlob(Blob.valueOf(str));
            response.setStatusCode(200);
            return response;
        } 
    }


    @isTest
    static void testgetCurrency1() {
        
        Account acc = TestUtil.createAccount(True);

        Opportunity opp = TestUtil.createOpportunity(True, acc.Id);


        TestUtil.createXeroConnection(true);

        Invoice__c testInvoice = new Invoice__c(Name = 'Test Invoice', Invoice_Id__c = '123', Status__c = 'Paid', KTXero__Opportunity__c = opp.Id, KTXero__Account__c = acc.Id);
        insert testInvoice;

        Invoice__c testInvoice1 = [SELECT Id FROM Invoice__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorContact4());

        Test.startTest();
        DownloadInvoiceController.ResultWrap inv = DownloadInvoiceController.downloadInvoice(testInvoice1.Id);
        System.assertEquals(null, inv.successFlag, 'Success');
        Test.stopTest();

    }

       /**
     * @description Mock Class to setup a test response
    */
    private class MockHttpResponseGeneratorContact4 implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"ErrorNumber\": 10,\"Type\": \"ValidationException\",\"Message\": \"A validation exception occurred\",\"Elements\": [{\"ContactID\": \"89d59636-6524-47b2-b047-0000000000000\",\"ContactNumber\": \"Cust_4\",\"AccountNumber\": \"Cust_4\",\"ContactStatus\": \"ACTIVE\",\"Name\": \"cpName\",\"FirstName\": \"MyCustomerFirstName2\",\"LastName\": \"MyCustomerLastName1\",\"EmailAddress\": \"sfgdg@sdfs.lo\",\"SkypeUserName\": \"\",\"BankAccountDetails\": \"bkname&amp; bankacname sortcode accnumber bicswift iban\",\"ContactGroups\": [],\"IsSupplier\": false,\"IsCustomer\": false,\"ContactPersons\": [],\"HasAttachments\": false,\"HasValidationErrors\": true,\"ValidationErrors\": [{\"Message\": \"The BankAccountDetails field cannot be more than 50 characters long.\"}]}]}');
            response.setStatusCode(400);
            return response;
        }
    }//----------------testxerocontactSync to cover Exception object---------------

    
}