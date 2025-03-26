@isTest
public with sharing class XeroSyncControllerTest{
    @IsTest
    static void testgetInvoice() {
        TestUtil.createXeroConnection(true);
        
        Invoice__c inv = new Invoice__c( Name = 'Test Invoice', Invoice_Id__c = 'INV-001', Status__c = 'Pending');
        insert inv;
        
        Test.startTest();
        XeroSyncController.InvoiceWrapper result1 = XeroSyncController.getInvoice(inv.Id);
        XeroSyncController.getInvoice(inv.id);
        Test.stopTest();
        
        System.assertEquals(inv.Invoice_Id__c, result1.invId,'ID should be matched.');
        System.assertEquals(inv.Name, result1.invName,'Invoice name should be matched');
        System.assertEquals(inv.Status__c, result1.invStatus,'Invoice status should matched.');
    }//----------------testGetInvoice---------------

     
    @IsTest
    static void testinvoiceSync(){
        Invoice__c testInvoice = new Invoice__c(Name = 'Test Invoice', Invoice_Id__c = '123', Status__c = 'Paid');
        insert testInvoice;
        
        List<Invoice_Line_Item__c> testLineItems = new List<Invoice_Line_Item__c>{
            new Invoice_Line_Item__c(Name = 'Line Item 1', Line_Item_Id__c = 'LI001', Invoice__c = testInvoice.Id),
            new Invoice_Line_Item__c(Name = 'Line Item 2', Line_Item_Id__c = 'LI002', Invoice__c = testInvoice.Id)};
        insert testLineItems;
        
        List<Payment__c> testPayments = new List<Payment__c>{
            new Payment__c(Name = 'Payment 1', Payment_Id__c = 'PAY001', Invoice__c = testInvoice.Id),
            new Payment__c(Name = 'Payment 2', Payment_Id__c = 'PAY002', Invoice__c = testInvoice.Id)};
         insert testPayments;
        
        KTXero__Xero_Connection__c kt = TestUtil.createXeroConnection(true);
        System.assertNotEquals(null,kt.Id,'success');

        KTXero__Invoice_Configuration_Options__c kt1 = TestUtil.createInvoiceConfigurationOptions(true);
        System.assertNotEquals(null,kt1.Id,'success');
     
        Opportunity opp1 = new Opportunity();

        Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Main St',
            BillingCity = 'Testville',
            BillingState = 'Teststate',
            BillingPostalCode = '12345',
            BillingCountry = 'Test Country',
            Phone = '1234567890'
        );
        insert acc;
        // accId = acc.Id;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today() + 30,
            AccountId = acc.Id,
            Amount = 50000
        );
        insert opp;

        opp1 = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'PMBr',
            IsActive = true,
            Description = 'This is a test product.',
            KTXero__Xero_ItemID__c = 'ec4362af-a038-4984-ab93-1bba3b6bd402'
        );
        Product2 testProduct1 = new Product2(
            Name = 'Test Product',
            ProductCode = 'TestCode',
            IsActive = true,
            Description = 'This is a test product.',
            KTXero__Xero_ItemID__c = ''
        ); 
        insert testProduct;
        insert testProduct1;

        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = test.getStandardPricebookId(),
            Product2Id = testProduct.id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert testPricebookEntry;
        
        OpportunityLineItem oli1 = new OpportunityLineItem(
            OpportunityId = opp1.Id,
            Quantity = 2,
            TotalPrice = 2000,
            Product2Id = testProduct.id,
            PricebookEntryId = testPricebookEntry.id
            // Line_Item_Id__c = 'a21423b7-c179-42f5-b2ec-17f9ce8f7804' 
        );
        insert oli1;
        
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = opp1.Id,
            Quantity = 1,
            TotalPrice = 1000,
            Product2Id = testProduct.id,
            PricebookEntryId = testPricebookEntry.id
        );
        insert oli2;
    
        Invoice__c inv1 = new Invoice__c(
            Opportunity__c = opp1.Id,
            KTXero__Invoice_Id__c = 'de2b30a2-afb2-4649-998f-4fd17554058a',
            Name = 'Test Invoice 1'
        );
        insert inv1;

        KTXero__Invoice_Line_Item__c xeroInv = new KTXero__Invoice_Line_Item__c();
        xeroInv.KTXero__Item_Code__c = 'Test205';
        xeroInv.KTXero__Product__c = testProduct.id;
        xeroInv.KTXero__Invoice__c = inv1.Id;
        xeroInv.KTXero__Line_Item_Id__c = 'a21423b7-c179-42f5-b2ec-17f9ce8f7804';
        insert xeroInv;
        
        
        KTXero__Xero_Connection__c testObj = [SELECT Id, Name, KTXero__Webhook_Key__c, KTXero__Client_Id__c, KTXero__Client_Secret__c, KTXero__Access_Token__c 
                                                FROM KTXero__Xero_Connection__c ORDER BY CreatedDate DESC LIMIT 1];
        
        System.assertEquals('testkey',Utils.processDecryption(testObj.KTXero__Webhook_Key__c),'success');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorInvoice());
        Test.startTest();
        InvoiceCreationWrapper.XeroConWrapper result = XeroSyncController.invoiceSync('de2b30a2-afb2-4649-998f-4fd17554058a', inv1.Id);
        system.assertNotEquals(null,result,'success');
        Test.stopTest();
    } 
    
     /**
     * @description Mock Class to setup a test response
    */
    private class MockHttpResponseGeneratorInvoice implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Id\":\"4a0b3db9-dd9a-4a5d-941b-58c6215d1134\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"/Date(1684831274579)/\",\"Invoices\":[{\"Type\":\"ACCREC\",\"InvoiceID\":\"de2b30a2-afb2-4649-998f-4fd17554058a\",\"InvoiceNumber\":\"INV-0051\",\"Reference\":\"001Dn00000Qc9GaIAJ\",\"Prepayments\":[],\"Payments\":[{\"Date\":\"Date(1684420182133+0000)\",\"PaymentID\":\"xeroPaymentId\",\"Amount\":100,\"CurrencyRate\":1.0000000000,\"HasAccount\":true,\"HasValidationErrors\":false}],\"Overpayments\":[],\"AmountDue\":0.00,\"AmountPaid\":0.00,\"SentToContact\":false,\"CurrencyRate\":1.0000000000,\"TotalDiscount\":0.00,\"IsDiscounted\":true,\"HasAttachments\":false,\"HasErrors\":false,\"Attachments\":[],\"InvoicePaymentServices\":[],\"Contact\":{\"ContactID\":\"37d78e0c-cd12-4dba-b518-8043c8b28480\",\"ContactStatus\":\"ACTIVE\",\"Name\":\"TestAccountBK6\",\"FirstName\":\"Test\",\"LastName\":\"Contact\",\"EmailAddress\":\"bhagyashree.k@kandisatech.com\",\"BankAccountDetails\":\"\",\"Addresses\":[{\"AddressType\":\"STREET\",\"City\":\"\",\"Region\":\"\",\"PostalCode\":\"\",\"Country\":\"\"},{\"AddressType\":\"POBOX\",\"AddressLine1\":\"test123\",\"City\":\"mum\",\"Region\":\"mh\",\"PostalCode\":\"852963\",\"Country\":\"in\"}],\"Phones\":[{\"PhoneType\":\"DEFAULT\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"DDI\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"FAX\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"MOBILE\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"}],\"UpdatedDateUTC\":\"/Date(1684420181097+0000)/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":true,\"SalesTrackingCategories\":[],\"PurchasesTrackingCategories\":[],\"ContactPersons\":[],\"HasValidationErrors\":false},\"DateString\":\"2023-04-18T00:00:00\",\"Date\":\"/Date(1681776000000+0000)/\",\"DueDateString\":\"2023-04-21T00:00:00\",\"DueDate\":\"/Date(1682035200000+0000)/\",\"BrandingThemeID\":\"f04ccf02-5a40-4ee2-a786-d6b97a34b8f4\",\"Status\":\"DRAFT\",\"LineAmountTypes\":\"Exclusive\",\"LineItems\":[{\"ItemCode\":\"PMBr\",\"Description\":\"Project management & implementation - branding workshop with your team - follow up session\",\"UnitAmount\":200,\"TaxType\":\"OUTPUT\",\"TaxAmount\":16.5,\"LineAmount\":200,\"AccountCode\":\"200\",\"Item\":{\"ItemID\":\"ec4362af-a038-4984-ab93-1bba3b6bd402\",\"Name\":\"Project management & implementation - branding\",\"Code\":\"PMBr\"},\"Tracking\":[{\"Name\":\"TR001\",\"Option\":\"Option1\",\"TrackingCategoryID\":\"TCID-001\",\"TrackingOptionID\":\"TO001\"}],\"Quantity\":15.0000,\"DiscountRate\":85.00,\"LineItemID\":\"a21423b7-c179-42f5-b2ec-17f9ce8f7804\",\"DiscountAmount\":0.0000,\"ValidationErrors\":[]},   {\"ItemCode\":\"TestCode\",\"Description\":\"Project management & implementation - branding workshop with your team - follow up session\",\"UnitAmount\":200,\"TaxType\":\"OUTPUT\",\"TaxAmount\":16.5,\"LineAmount\":200,\"AccountCode\":\"200\",\"Item\":{\"ItemID\":\"123456\",\"Name\":\"Project management & implementation - branding\",\"Code\":\"TestCode\"},\"Tracking\":[{\"Name\":\"TR001\",\"Option\":\"Option1\",\"TrackingCategoryID\":\"TCID-001\",\"TrackingOptionID\":\"TO001\"}],\"Quantity\":15.0000,\"DiscountRate\":90.00,\"LineItemID\":\"123456789\",\"DiscountAmount\":0.0000,\"ValidationErrors\":[]}   ],\"SubTotal\":0.00,\"TotalTax\":0.00,\"Total\":0.00,\"UpdatedDateUTC\":\"/Date(1684420182133+0000)/\",\"CurrencyCode\":\"USD\"}]}');
            response.setStatusCode(200);
            return response;
        } 
    }//----------------testinvoiceSync---------------
    
    @IsTest
    static void testgetxeroContact(){
        Xero_Contact__c testContact = new Xero_Contact__c(First_Name__c = 'Testname', Company_Name__c = 'Test Company', Reference_Id__c = '123');
        insert testContact;
        
        // KTXero__Xero_Connection__c obj = new KTXero__Xero_Connection__c(KTXero__Access_Token__c = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTE1NzQ2MDAsImV4cCI6MTY5MTU3NjQwMCwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTQ4MjAwOSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6Ijg3Zjc5ZDE1ZThmYTQxZDg4OWU2MTc4MzBkNjY0YWUzIiwic2lkIjoiODdmNzlkMTVlOGZhNDFkODg5ZTYxNzgzMGQ2NjRhZTMiLCJqdGkiOiIzQkQ2M0E1MkE2RjRDRTQzNTdDRDM4NUQ2MkFDNjg4RiIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiODY3ZWQ0MDctZjg2MC00YTQ3LTkzY2UtNzY1ZDQ2ZjQ0YTVhIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.r9TWEy7q4n3rEKmgM_PTj1k2U-BSJNrZvSY3biHXPaQnn_R26TLhuV9qus0RIpDfs7XZ9P0bIadRkodXe_loYqOLRkRYo8bmquyq-IrPfx8cPx18qDxfpMK8nqr_n3CHF-JZpUw_4zV_JpiMUZ0zvEbTyMFjVT7W7AmAeeppL2QoC64EbSr_9E42bKoAn14q7KaLeWi6dQLSQJ6UowXgfiKoga9qrJ1CqznK-NMy7mkzwwT4nQDjieebBTo0KgKX7nCjX_cQKmUxOMzxkanZzprlGYkckIvyN88kkia_Vg-1T7jTAvIdPpb7qtF1DkhWxs4HiHI0Pk5zG65fGeqARA', KTXero__Refresh_Token__c = 'iMrWhs51ztFLOM9sxr6Ge5juXHXU3mszSbQo-b3d0_I', KTXero__Tenant_Id__c = '7ba1138a-ae87-411a-ae0a-ed5768f597d4');
        // insert obj;
        TestUtil.createXeroConnection(true);
        
        Invoice__c inv = new Invoice__c( Name = 'Test Invoice', Invoice_Id__c = 'INV-001', Status__c = 'Pending');
        insert inv;
        
        Test.startTest();
        XeroSyncController.getxeroContact(testContact.Id);
        XeroSyncController.InvoiceWrapper result = XeroSyncController.getInvoice(inv.Id);
        //XeroSyncController.invoiceSync('',inv.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result,'success');
        
    }//----------------testgetxeroContact---------------
    
    @isTest
    static void testxerocontactSync(){

        Xero_Contact__c testContact = new Xero_Contact__c(
            First_Name__c = 'Jack', 
            Last_Name__c = 'Rogers',
            Email_Address__c = 'jrogers@burlington.com',
            Company_Name__c = 'BurlingtonTextilesCorpofAmerica', 
            Reference_Id__c = '01a37a47-2ef4-485a-87ed-73578e92c011'
        );
        insert testContact;

        KTXero__Xero_Connection__c kt = TestUtil.createXeroConnection(true);
        System.assertNotEquals(null,kt.Id,'success');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorContact());
        
        Test.startTest();
        InvoiceCreationWrapper.XeroConWrapper xw = XeroSyncController.xerocontactSync(testContact.Reference_Id__c, testContact.id);
        System.assertEquals(true,xw.successFlag,'success');

        Test.stopTest();
    }
    
     /**
     * @description Mock Class to setup a test response
    */
    private class MockHttpResponseGeneratorContact implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Id\":\"ecd6735e-b744-4a1d-989a-da33cb25befc\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"\\/Date(1685086084614)\\/\",\"Contacts\":[{\"ContactID\":\"01a37a47-2ef4-485a-87ed-73578e92c011\",\"ContactStatus\":\"ACTIVE\",\"Name\":\"BurlingtonTextilesCorpofAmerica\",\"FirstName\":\"Jack\",\"LastName\":\"Rogers\",\"EmailAddress\":\"jrogers@burlington.com\",\"Addresses\":[{\"AddressType\":\"POBOX\",\"AddressLine1\":\"525S.LexingtonAve\",\"City\":\"Burlington\",\"Region\":\"NC\",\"PostalCode\":\"27215\",\"Country\":\"USA\"},{\"AddressType\":\"STREET\"}],\"Phones\":[{\"PhoneType\":\"DDI\"},{\"PhoneType\":\"DEFAULT\"},{\"PhoneType\":\"FAX\"},{\"PhoneType\":\"MOBILE\"}],\"UpdatedDateUTC\":\"\\/Date(1685085520190+0000)\\/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":true,\"ContactPersons\":[{\"FirstName\":\"test3\",\"LastName\":\"test3\",\"EmailAddress\":\"test3@test.com\",\"IncludeInEmails\":true},{\"FirstName\":\"test1\",\"LastName\":\"test1\",\"EmailAddress\":\"test1@test.com\",\"IncludeInEmails\":true},{\"FirstName\":\"test\",\"LastName\":\"test\",\"EmailAddress\":\"test@test.com\",\"IncludeInEmails\":true},{\"FirstName\":\"test2\",\"LastName\":\"test2\",\"EmailAddress\":\"test2@test.com\",\"IncludeInEmails\":true},{\"FirstName\":\"test4\",\"LastName\":\"test4\",\"EmailAddress\":\"test4@test.com\",\"IncludeInEmails\":true}],\"HasAttachments\":false,\"Attachments\":[],\"HasValidationErrors\":false}]}');
            response.setStatusCode(200);
            return response;
        }
    }//----------------testxerocontactSync---------------


    // to test XeroContactSunc for Delivery type
    @isTest
    static void testxerocontactSync1(){

        Xero_Contact__c testContact = new Xero_Contact__c(
            First_Name__c = 'Jack', 
            Last_Name__c = 'Rogers',
            Email_Address__c = 'jrogers@burlington.com',
            Company_Name__c = 'BurlingtonTextilesCorpofAmerica', 
            Reference_Id__c = '01a37a47-2ef4-485a-87ed-73578e92c011'
        );
        insert testContact;

        KTXero__Xero_Connection__c kt = TestUtil.createXeroConnection(true);
        System.assertNotEquals(null,kt.Id,'success');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorContact1());
        
        Test.startTest();
        InvoiceCreationWrapper.XeroConWrapper xw = XeroSyncController.xerocontactSync(testContact.Reference_Id__c, testContact.id);
        System.assertEquals(true,xw.successFlag,'success');

        Test.stopTest();
    }
    
     /**
     * @description Mock Class to setup a test response
    */
    private class MockHttpResponseGeneratorContact1 implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Id\":\"ecd6735e-b744-4a1d-989a-da33cb25befc\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"\\/Date(1685086084614)\\/\",\"Contacts\":[{\"ContactID\":\"01a37a47-2ef4-485a-87ed-73578e92c011\",\"ContactStatus\":\"ACTIVE\",\"Name\":\"BurlingtonTextilesCorpofAmerica\",\"FirstName\":\"Jack\",\"LastName\":\"Rogers\",\"EmailAddress\":\"jrogers@burlington.com\",\"Addresses\":[{\"AddressType\":\"DELIVERY\",\"AddressLine1\":\"525S.LexingtonAve\",\"City\":\"Burlington\",\"Region\":\"NC\",\"PostalCode\":\"27215\",\"Country\":\"USA\"},{\"AddressType\":\"STREET\"}],\"Phones\":[{\"PhoneType\":\"DDI\"},{\"PhoneType\":\"DEFAULT\"},{\"PhoneType\":\"FAX\"},{\"PhoneType\":\"MOBILE\"}],\"UpdatedDateUTC\":\"\\/Date(1685085520190+0000)\\/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":true,\"ContactPersons\":[{\"FirstName\":\"test3\",\"LastName\":\"test3\",\"EmailAddress\":\"test3@test.com\",\"IncludeInEmails\":true},{\"FirstName\":\"test1\",\"LastName\":\"test1\",\"EmailAddress\":\"test1@test.com\",\"IncludeInEmails\":true},{\"FirstName\":\"test\",\"LastName\":\"test\",\"EmailAddress\":\"test@test.com\",\"IncludeInEmails\":true},{\"FirstName\":\"test2\",\"LastName\":\"test2\",\"EmailAddress\":\"test2@test.com\",\"IncludeInEmails\":true},{\"FirstName\":\"test4\",\"LastName\":\"test4\",\"EmailAddress\":\"test4@test.com\",\"IncludeInEmails\":true}],\"HasAttachments\":false,\"Attachments\":[],\"HasValidationErrors\":false}]}');
            response.setStatusCode(200);
            return response;
        }
    }//----------------testxerocontactSync to test Delivery---------------



    // to test XeroContactSync for Error object
    @isTest
    static void testxerocontactSync2(){

        Xero_Contact__c testContact = new Xero_Contact__c(
            First_Name__c = 'Jack', 
            Last_Name__c = 'Rogers',
            Email_Address__c = 'jrogers@burlington.com',
            Company_Name__c = 'BurlingtonTextilesCorpofAmerica', 
            Reference_Id__c = '01a37a47-2ef4-485a-87ed-73578e92c011'
        );
        insert testContact;

        KTXero__Xero_Connection__c kt = TestUtil.createXeroConnection(true);
        System.assertNotEquals(null,kt.Id,'success');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorContact3());
        
        Test.startTest();
        try{

            InvoiceCreationWrapper.XeroConWrapper xw = XeroSyncController.xerocontactSync(testContact.Reference_Id__c, testContact.id);
            System.assertEquals(true,xw.successFlag,'success');
        }catch(Exception e){
            HandleCustomException.logException(e);
        }

        Test.stopTest();
    }
    
     /**
     * @description Mock Class to setup a test response
    */
    private class MockHttpResponseGeneratorContact3 implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Id\":\"ecd6735e-b744-4a1d-989a-da33cb25befc\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"\\/Date(1685086084614)\\/\",\"Contacts\":[{\"ContactID\":\"01a37a47-2ef4-485a-87ed-73578e92c011\",\"ContactStatus\":\"ACTIVE\",\"Name\":\"BurlingtonTextilesCorpofAmerica\",\"FirstName\":\"Jack\",\"LastName\":\"Rogers\",\"EmailAddress\":\"jrogers@burlington.com\",\"Addresses\":[{\"AddressType\":\"DELIVERY\",\"AddressLine1\":\"525S.LexingtonAve\",\"City\":\"Burlington\",\"Region\":\"NC\",\"PostalCode\":\"27215\",\"Country\":\"USA\"},{\"AddressType\":\"STREET\"}],\"Phones\":[{\"PhoneType\":\"DDI\"},{\"PhoneType\":\"DEFAULT\"},{\"PhoneType\":\"FAX\"},{\"PhoneType\":\"MOBILE\"}],\"UpdatedDateUTC\":\"\\/Date(1685085520190+0000)\\/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":true,\"ContactPersons\":[{\"FirstName\":\"test3\",\"LastName\":\"test3\",\"EmailAddress\":\"test3@test.com\",\"IncludeInEmails\":true},{\"FirstName\":\"test1\",\"LastName\":\"test1\",\"EmailAddress\":\"test1@test.com\",\"IncludeInEmails\":true},{\"FirstName\":\"test\",\"LastName\":\"test\",\"EmailAddress\":\"test@test.com\",\"IncludeInEmails\":true},{\"FirstName\":\"test2\",\"LastName\":\"test2\",\"EmailAddress\":\"test2@test.com\",\"IncludeInEmails\":true},{\"FirstName\":\"test4\",\"LastName\":\"test4\",\"EmailAddress\":\"test4@test.com\",\"IncludeInEmails\":true}],\"HasAttachments\":false,\"Attachments\":[],\"HasValidationErrors\":false}]}');
            response.setStatusCode(400);
            return response;
        }
    }//----------------testxerocontactSync to test XeroContactSync for Error object---------------
    


    // to test XeroContactSync for Error object
    @isTest
    static void testxerocontactSync3(){

        Xero_Contact__c testContact = new Xero_Contact__c(
            First_Name__c = 'Jack', 
            Last_Name__c = 'Rogers',
            Email_Address__c = 'jrogers@burlington.com',
            Company_Name__c = 'BurlingtonTextilesCorpofAmerica', 
            Reference_Id__c = '01a37a47-2ef4-485a-87ed-73578e92c011'
        );
        insert testContact;

        KTXero__Xero_Connection__c kt = TestUtil.createXeroConnection(true);
        System.assertNotEquals(null,kt.Id,'success');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorContact4());
        
        Test.startTest();
        try{

            InvoiceCreationWrapper.XeroConWrapper xw = XeroSyncController.xerocontactSync(testContact.Reference_Id__c, testContact.id);
            System.assertEquals(false,xw.successFlag,'success');
        }catch(Exception e){
            HandleCustomException.logException(e);

        }

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
    }//----------------testxerocontactSync to test XeroContactSync to cover Exception object---------------





    @isTest
    static void testxeroAccountsSync(){
        KTXero__Xero_Connection__c kt = TestUtil.createXeroConnection(true);
        System.assertNotEquals(null,kt.Id,'success');

        Xero_Metadata__c account1 = new Xero_Metadata__c(
            Name = 'Account 1', KTXero__Account_Code__c = '1001', Text__c = 'Account 1 description', Type__c = 'Accounts',
            Value__c = '1000', Code__c = 'ACCT1', Xero_Id__c = 'XERO001', Status__c = 'Active');
        insert account1;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorAccount());
        
        
        Test.startTest();
        XeroSyncController.XeroMetadataSyncWrapper result1 = XeroSyncController.xeroAccountsSync();
        Test.stopTest();
        
        System.assertEquals(true, result1.successFlag,'FLag should be true.');
    }
    
    private class MockHttpResponseGeneratorAccount implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
			response.setBody('{\"Id\":\"799da65e-f55e-4210-86a6-7af120f7657c\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"\\/Date(1685024335115)\\/\",\"Accounts\":[{\"AccountID\":\"562555f2-8cde-4ce9-8203-0363922537a4\",\"Code\":\"090\",\"Name\":\"BusinessBankAccount\",\"Status\":\"ACTIVE\",\"Type\":\"BANK\",\"TaxType\":\"NONE\",\"Class\":\"ASSET\",\"EnablePaymentsToAccount\":false,\"ShowInExpenseClaims\":false,\"BankAccountNumber\":\"0908007006543\",\"BankAccountType\":\"BANK\",\"CurrencyCode\":\"USD\",\"ReportingCode\":\"ASS\",\"ReportingCodeName\":\"Asset\",\"HasAttachments\":false,\"UpdatedDateUTC\":\"\\/Date(1683007643930+0000)\\/\",\"AddToWatchlist\":false},{\"AccountID\":\"72f1dcfe-5d7d-4239-bf9d-e12469309716\",\"Code\":\"091\",\"Name\":\"BusinessSavingsAccount\",\"Status\":\"ACTIVE\",\"Type\":\"BANK\",\"TaxType\":\"NONE\",\"Class\":\"ASSET\",\"EnablePaymentsToAccount\":false,\"ShowInExpenseClaims\":false,\"BankAccountNumber\":\"121314121314\",\"BankAccountType\":\"BANK\",\"CurrencyCode\":\"USD\",\"ReportingCode\":\"ASS\",\"ReportingCodeName\":\"Asset\",\"HasAttachments\":false,\"UpdatedDateUTC\":\"\\/Date(1683007643930+0000)\\/\",\"AddToWatchlist\":false},{\"AccountID\":\"d1ebb97b-d207-4ccb-9ab6-8a466a8b4d39\",\"Code\":\"200\",\"Name\":\"Sales\",\"Status\":\"ACTIVE\",\"Type\":\"REVENUE\",\"TaxType\":\"OUTPUT\",\"Description\":\"Incomefromanynormalbusinessactivity\",\"Class\":\"REVENUE\",\"SystemAccount\":\"\",\"EnablePaymentsToAccount\":false,\"ShowInExpenseClaims\":false,\"BankAccountType\":\"NONE\",\"ReportingCode\":\"REV.TRA.GOO\",\"ReportingCodeName\":\"Saleofgoods\",\"HasAttachments\":false,\"UpdatedDateUTC\":\"\\/Date(1683007643930+0000)\\/\",\"AddToWatchlist\":true}]}');
            response.setStatusCode(200);
            return response;
        }
    } //----------------testxeroAccountsSync---------------

    @isTest
    static void testxeroTrackingCategorySync(){
        KTXero__Xero_Connection__c kt = TestUtil.createXeroConnection(true);
        System.assertNotEquals(null,kt.Id,'success');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorTrackingCategory());
        Test.startTest();
        XeroSyncController.XeroMetadataSyncWrapper result1 = InvoiceConfigurationController.xeroTrackingCategorySync();
        Test.stopTest();
        
        System.assertEquals(true, result1.successFlag,'FLag should be true.');
    }

     /**
     * @description Mock Class to setup a test response
    */
    private class MockHttpResponseGeneratorTrackingCategory implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
			response.setBody('{\"Id\":\"2687d0d8-c13f-4a11-91b2-b384b069d0bc\",\"Status\":\"OK\",\"ProviderName\":\"Salesforce Application\",\"DateTimeUTC\":\"\\/Date(1692010248569)\\/\",\"TrackingCategories\":[{\"Name\":\"Region\",\"Status\":\"ACTIVE\",\"TrackingCategoryID\":\"fa437cfd-f005-4538-ae84-943857da5c8c\",\"Options\":[{\"TrackingOptionID\":\"7b354c1c-cf59-42fc-9449-a65c51988335\",\"Name\":\"Eastside\",\"Status\":\"ACTIVE\",\"HasValidationErrors\":false,\"IsDeleted\":false,\"IsArchived\":false,\"IsActive\":true},{\"TrackingOptionID\":\"5e2974a2-097d-4f3b-bfd5-605d78c4a282\",\"Name\":\"North\",\"Status\":\"ACTIVE\",\"HasValidationErrors\":false,\"IsDeleted\":false,\"IsArchived\":false,\"IsActive\":true},{\"TrackingOptionID\":\"e83ea9f2-de2c-44d8-b4f8-a5065bed339e\",\"Name\":\"South\",\"Status\":\"ACTIVE\",\"HasValidationErrors\":false,\"IsDeleted\":false,\"IsArchived\":false,\"IsActive\":true},{\"TrackingOptionID\":\"fc96efd9-b832-4b31-a93e-61f56158adad\",\"Name\":\"West Coast\",\"Status\":\"ACTIVE\",\"HasValidationErrors\":false,\"IsDeleted\":false,\"IsArchived\":false,\"IsActive\":true}]}]}');
            response.setStatusCode(200);
            return response;
        }
    } //----------------testxeroTrackingCategorySync---------------



    @IsTest
    static void testSyncXeroConSFToXero(){
        KTXero__Xero_Connection__c kt = TestUtil.createXeroConnection(true);
        Xero_Contact__c testContact = new Xero_Contact__c(
            First_Name__c = 'Jack', 
            Last_Name__c = 'Rogers',
            Email_Address__c = 'jrogers@burlington.com',
            Company_Name__c = 'BurlingtonTextilesCorpofAmerica', 
            Reference_Id__c = '01a37a47-2ef4-485a-87ed-73578e92c011',
            Street_Address__c = 'test',
            Town_City__c = 'test',
            State_Region__c = 'test',
            Postal_Zip_Code__c = 'test',
            Country__c = 'test',
            Contact_1_First_Name__c = 'test',
            Contact_1_Last_Name__c = 'test',
            Contact_1_Email__c = 'test@tst.com'
        );
        insert testContact;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForXeroConSync());
        
        Test.startTest();
        InvoiceCreationWrapper.XeroConWrapper xw = XeroSyncController.syncXeroConSFToXero('', testContact.Id);
        Test.stopTest();
        System.assertNotEquals(null, xw,'Successfull');
    }

    private class MockHttpResponseGeneratorForXeroConSync implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Id\":\"3476b5e2-8e9b-46d1-aa43-cb84691f5006\",\"Status\":\"OK\",\"ProviderName\":\"Salesforce Application\",\"DateTimeUTC\":\"/Date(1714628855772)/\",\"Contacts\":[{\"ContactID\":\"52ba712c-fd38-478f-8e3f-0afbac2caf31\",\"AccountNumber\":\"Config Acc Name 2 \",\"ContactStatus\":\"ACTIVE\",\"Name\":\"Burlington Textiles Corp of America 2\",\"FirstName\":\"Andy\",\"LastName\":\"Young\",\"EmailAddress\":\"a_young@dickenson.com\",\"BankAccountDetails\":\"\",\"Addresses\":[{\"AddressType\":\"STREET\",\"City\":\"\",\"Region\":\"\",\"PostalCode\":\"\",\"Country\":\"\"},{\"AddressType\":\"POBOX\",\"AddressLine1\":\"525 S. Lexington Ave\",\"City\":\"Burlington\",\"Region\":\"NC\",\"PostalCode\":\"27215\",\"Country\":\"USA\"}],\"Phones\":[{\"PhoneType\":\"DEFAULT\",\"PhoneNumber\":\"(336) 222-7000\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"DDI\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"FAX\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"MOBILE\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"}],\"UpdatedDateUTC\":\"/Date(1713352553397+0000)/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":true,\"SalesTrackingCategories\":[],\"PurchasesTrackingCategories\":[],\"ContactPersons\":[],\"HasValidationErrors\":false}]}');
            response.setStatusCode(200);
            return response;
        } 
    }



    @IsTest
    static void testsyncSFToXero1(){
        KTXero__Xero_Connection__c kt = TestUtil.createXeroConnection(true);

        Xero_Contact__c testContact = new Xero_Contact__c(
            First_Name__c = 'Jack', 
            Last_Name__c = 'Rogers',
            Email_Address__c = 'jrogers@burlington.com',
            Company_Name__c = 'BurlingtonTextilesCorpofAmerica', 
            Reference_Id__c = '01a37a47-2ef4-485a-87ed-73578e92c011',
            Street_Address__c = 'test',
            Town_City__c = 'test',
            State_Region__c = 'test',
            Postal_Zip_Code__c = 'test',
            Country__c = 'test',
            Contact_1_First_Name__c = 'test',
            Contact_1_Last_Name__c = 'test',
            Contact_1_Email__c = 'test@tst.com'
        );
        insert testContact;


        Invoice__c testInvoice = new Invoice__c( 
            Name = 'Test Invoice', 
            Invoice_Id__c = 'INV-001', 
            Status__c = 'Pending',
            Type__c = 'Pending',
            Xero_Contact__c = testContact.id,
            Branding_Theme_Id__c = 'Pending'
            // Reference__c = 'Pending',
        );
        insert testInvoice;

        
        List<Invoice_Line_Item__c> testLineItems = new List<Invoice_Line_Item__c>{
            new Invoice_Line_Item__c(Name = 'Line Item 1', Line_Item_Id__c = 'LI001', Invoice__c = testInvoice.Id, Account_Code__c = '123', Description__c = 'test'),
            new Invoice_Line_Item__c(Name = 'Line Item 2', Line_Item_Id__c = 'LI002', Invoice__c = testInvoice.Id, Account_Code__c = '123', Description__c = 'test')};
        insert testLineItems;
        
        List<Payment__c> testPayments = new List<Payment__c>{
            new Payment__c(Name = 'Payment 1', Payment_Id__c = 'PAY001', Invoice__c = testInvoice.Id),
            new Payment__c(Name = 'Payment 2', Payment_Id__c = 'PAY002', Invoice__c = testInvoice.Id)};
         insert testPayments;
        


        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForXeroConSync());
        
        Test.startTest();
        InvoiceCreationWrapper.XeroConWrapper xw = XeroSyncController.syncSFToXero('2332342342342343', testInvoice.Id);
        Test.stopTest();

        System.assertNotEquals(null, xw, 'Successful');

        XeroSyncController.XeroMetadataSyncWrapper obj = new XeroSyncController.XeroMetadataSyncWrapper();
        obj.successFlag = true;
        obj.message = 'tets';
        obj.metadataList = new List<InvoiceConfigurationController.XeroMetadataWrapper>();
    }

    private class MockHttpResponseGeneratorForInvoiceSync implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Id\":\"3476b5e2-8e9b-46d1-aa43-cb84691f5006\",\"Status\":\"OK\",\"ProviderName\":\"Salesforce Application\",\"DateTimeUTC\":\"/Date(1714628855772)/\",\"Contacts\":[{\"ContactID\":\"52ba712c-fd38-478f-8e3f-0afbac2caf31\",\"AccountNumber\":\"Config Acc Name 2 \",\"ContactStatus\":\"ACTIVE\",\"Name\":\"Burlington Textiles Corp of America 2\",\"FirstName\":\"Andy\",\"LastName\":\"Young\",\"EmailAddress\":\"a_young@dickenson.com\",\"BankAccountDetails\":\"\",\"Addresses\":[{\"AddressType\":\"STREET\",\"City\":\"\",\"Region\":\"\",\"PostalCode\":\"\",\"Country\":\"\"},{\"AddressType\":\"POBOX\",\"AddressLine1\":\"525 S. Lexington Ave\",\"City\":\"Burlington\",\"Region\":\"NC\",\"PostalCode\":\"27215\",\"Country\":\"USA\"}],\"Phones\":[{\"PhoneType\":\"DEFAULT\",\"PhoneNumber\":\"(336) 222-7000\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"DDI\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"FAX\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"MOBILE\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"}],\"UpdatedDateUTC\":\"/Date(1713352553397+0000)/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":true,\"SalesTrackingCategories\":[],\"PurchasesTrackingCategories\":[],\"ContactPersons\":[],\"HasValidationErrors\":false}]}');
            response.setStatusCode(200);
            return response;
        } 
    }





    @IsTest
    static void testinvoiceSync1(){
        Invoice__c testInvoice = new Invoice__c(Name = 'Test Invoice', Invoice_Id__c = '123', Status__c = 'Paid');
        insert testInvoice;
        
        List<Invoice_Line_Item__c> testLineItems = new List<Invoice_Line_Item__c>{
            new Invoice_Line_Item__c(Name = 'Line Item 1', Line_Item_Id__c = 'LI001', Invoice__c = testInvoice.Id),
            new Invoice_Line_Item__c(Name = 'Line Item 2', Line_Item_Id__c = 'LI002', Invoice__c = testInvoice.Id)};
        insert testLineItems;
        
        List<Payment__c> testPayments = new List<Payment__c>{
            new Payment__c(Name = 'Payment 1', Payment_Id__c = 'PAY001', Invoice__c = testInvoice.Id),
            new Payment__c(Name = 'Payment 2', Payment_Id__c = 'PAY002', Invoice__c = testInvoice.Id)};
         insert testPayments;
        
        KTXero__Xero_Connection__c kt = TestUtil.createXeroConnection(true);
        System.assertNotEquals(null,kt.Id,'success');

        KTXero__Invoice_Configuration_Options__c kt1 = TestUtil.createInvoiceConfigurationOptions(true);
        System.assertNotEquals(null,kt1.Id,'success');
     
        Opportunity opp1 = new Opportunity();

        Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Main St',
            BillingCity = 'Testville',
            BillingState = 'Teststate',
            BillingPostalCode = '12345',
            BillingCountry = 'Test Country',
            Phone = '1234567890'
        );
        insert acc;
        // accId = acc.Id;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today() + 30,
            AccountId = acc.Id,
            Amount = 50000
        );
        insert opp;

        opp1 = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'PMBr',
            IsActive = true,
            Description = 'This is a test product.',
            KTXero__Xero_ItemID__c = 'ec4362af-a038-4984-ab93-1bba3b6bd402'
        );
        Product2 testProduct1 = new Product2(
            Name = 'Test Product',
            ProductCode = 'TestCode',
            IsActive = true,
            Description = 'This is a test product.',
            KTXero__Xero_ItemID__c = ''
        ); 
        insert testProduct;
        insert testProduct1;

        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = test.getStandardPricebookId(),
            Product2Id = testProduct.id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert testPricebookEntry;
        
        OpportunityLineItem oli1 = new OpportunityLineItem(
            OpportunityId = opp1.Id,
            Quantity = 2,
            TotalPrice = 2000,
            Product2Id = testProduct.id,
            PricebookEntryId = testPricebookEntry.id
            // Line_Item_Id__c = 'a21423b7-c179-42f5-b2ec-17f9ce8f7804' 
        );
        insert oli1;
        
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = opp1.Id,
            Quantity = 1,
            TotalPrice = 1000,
            Product2Id = testProduct.id,
            PricebookEntryId = testPricebookEntry.id
        );
        insert oli2;
    
        Invoice__c inv1 = new Invoice__c(
            Opportunity__c = opp1.Id,
            KTXero__Invoice_Id__c = 'de2b30a2-afb2-4649-998f-4fd17554058a',
            Name = 'Test Invoice 1'
        );
        insert inv1;

        KTXero__Invoice_Line_Item__c xeroInv = new KTXero__Invoice_Line_Item__c();
        xeroInv.KTXero__Item_Code__c = 'Test205';
        xeroInv.KTXero__Product__c = testProduct.id;
        xeroInv.KTXero__Invoice__c = inv1.Id;
        xeroInv.KTXero__Line_Item_Id__c = 'test';
        insert xeroInv;
        

        Payment__c pay = new Payment__c();
        pay.Name = 'Payment 3';
        pay.Payment_Id__c = 'test';
        pay.Invoice__c = inv1.Id;
        insert pay;
        
        KTXero__Xero_Connection__c testObj = [SELECT Id, Name, KTXero__Webhook_Key__c, KTXero__Client_Id__c, KTXero__Client_Secret__c, KTXero__Access_Token__c 
                                                FROM KTXero__Xero_Connection__c ORDER BY CreatedDate DESC LIMIT 1];
        
        System.assertEquals('testkey',Utils.processDecryption(testObj.KTXero__Webhook_Key__c),'success');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorInvoice1());
        Test.startTest();
        InvoiceCreationWrapper.XeroConWrapper result = XeroSyncController.invoiceSync('de2b30a2-afb2-4649-998f-4fd17554058a', inv1.Id);
        system.assertNotEquals(null,result,'success');
        Test.stopTest();
    } 

     /**
     * @description Mock Class to setup a test response
    */
    private class MockHttpResponseGeneratorInvoice1 implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Id\":\"4a0b3db9-dd9a-4a5d-941b-58c6215d1134\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"/Date(1684831274579)/\",\"Invoices\":[{\"Type\":\"ACCREC\",\"InvoiceID\":\"de2b30a2-afb2-4649-998f-4fd17554058a\",\"InvoiceNumber\":\"INV-0051\",\"Reference\":\"001Dn00000Qc9GaIAJ\",\"Prepayments\":[],\"Payments\":[{\"Date\":\"Date(1684420182133+0000)\",\"PaymentID\":\"xeroPaymentId\",\"Amount\":100,\"CurrencyRate\":1.0000000000,\"HasAccount\":true,\"HasValidationErrors\":false}],\"Overpayments\":[],\"AmountDue\":0.00,\"AmountPaid\":0.00,\"SentToContact\":false,\"CurrencyRate\":1.0000000000,\"TotalDiscount\":0.00,\"IsDiscounted\":true,\"HasAttachments\":false,\"HasErrors\":false,\"Attachments\":[],\"InvoicePaymentServices\":[],\"Contact\":{\"ContactID\":\"37d78e0c-cd12-4dba-b518-8043c8b28480\",\"ContactStatus\":\"ACTIVE\",\"Name\":\"TestAccountBK6\",\"FirstName\":\"Test\",\"LastName\":\"Contact\",\"EmailAddress\":\"bhagyashree.k@kandisatech.com\",\"BankAccountDetails\":\"\",\"Addresses\":[{\"AddressType\":\"STREET\",\"City\":\"\",\"Region\":\"\",\"PostalCode\":\"\",\"Country\":\"\"},{\"AddressType\":\"POBOX\",\"AddressLine1\":\"test123\",\"City\":\"mum\",\"Region\":\"mh\",\"PostalCode\":\"852963\",\"Country\":\"in\"}],\"Phones\":[{\"PhoneType\":\"DEFAULT\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"DDI\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"FAX\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"MOBILE\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"}],\"UpdatedDateUTC\":\"/Date(1684420181097+0000)/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":true,\"SalesTrackingCategories\":[],\"PurchasesTrackingCategories\":[],\"ContactPersons\":[],\"HasValidationErrors\":false},\"DateString\":\"2023-04-18T00:00:00\",\"Date\":\"/Date(1681776000000+0000)/\",\"DueDateString\":\"2023-04-21T00:00:00\",\"DueDate\":\"/Date(1682035200000+0000)/\",\"BrandingThemeID\":\"f04ccf02-5a40-4ee2-a786-d6b97a34b8f4\",\"Status\":\"DRAFT\",\"LineAmountTypes\":\"Exclusive\",\"LineItems\":[{\"ItemCode\":\"PMBr\",\"Description\":\"Project management & implementation - branding workshop with your team - follow up session\",\"UnitAmount\":200,\"TaxType\":\"OUTPUT\",\"TaxAmount\":16.5,\"LineAmount\":200,\"AccountCode\":\"200\",\"Item\":{\"ItemID\":\"ec4362af-a038-4984-ab93-1bba3b6bd402\",\"Name\":\"Project management & implementation - branding\",\"Code\":\"PMBr\"},\"Tracking\":[{\"Name\":\"TR001\",\"Option\":\"Option1\",\"TrackingCategoryID\":\"TCID-001\",\"TrackingOptionID\":\"TO001\"}],\"Quantity\":15.0000,\"DiscountRate\":85.00,\"LineItemID\":\"a21423b7-c179-42f5-b2ec-17f9ce8f7804\",\"DiscountAmount\":0.0000,\"ValidationErrors\":[]},   {\"ItemCode\":\"TestCode\",\"Description\":\"Project management & implementation - branding workshop with your team - follow up session\",\"UnitAmount\":200,\"TaxType\":\"OUTPUT\",\"TaxAmount\":16.5,\"LineAmount\":200,\"AccountCode\":\"200\",\"Item\":{\"ItemID\":\"123456\",\"Name\":\"Project management & implementation - branding\",\"Code\":\"TestCode\"},\"Tracking\":[{\"Name\":\"TR001\",\"Option\":\"Option1\",\"TrackingCategoryID\":\"TCID-001\",\"TrackingOptionID\":\"TO001\"}],\"Quantity\":15.0000,\"DiscountRate\":90.00,\"LineItemID\":\"123456789\",\"DiscountAmount\":0.0000,\"ValidationErrors\":[]}   ],\"SubTotal\":0.00,\"TotalTax\":0.00,\"Total\":0.00,\"UpdatedDateUTC\":\"/Date(1684420182133+0000)/\",\"CurrencyCode\":\"USD\"}]}');
            response.setStatusCode(200);
            return response;
        } 
    }//----------------testinvoiceSync---------------
}