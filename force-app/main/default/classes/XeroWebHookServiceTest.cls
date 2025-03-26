@isTest
public with sharing class XeroWebHookServiceTest {
    
    /**
     * @description Helper method to create a mock Xero payload
     * @return String
    */
    public static String createMockPayload() {
        // Create a JSON object with some dummy data
        Map<String, Object> payload = new Map<String, Object>();

        payload.put('events', new List<Object>{new Map<String, Object>{
            'resourceUrl' => 'https://api.xero.com/api.xro/2.0/Invoices/de2b30a2-afb2-4649-998f-4fd17554058a',
            'resourceId' => 'de2b30a2-afb2-4649-998f-4fd17554058a',
            'eventDateUtc' => '2021-08-10T05:32:49',
            'eventType' => 'UPDATE',
            'eventCategory' => 'INVOICE'
        }});
        payload.put('firstEventSequence', 1);
        payload.put('lastEventSequence', 1);
        payload.put('entropy', 'abcd');

        return JSON.serialize(payload);
    }
    
    /**
     * @description Helper method to create a mock Xero payload
     * @return String
    */
    public static String createBillMockPayload() {
        // Create a JSON object with some dummy data
        Map<String, Object> payload = new Map<String, Object>();

        payload.put('events', new List<Object>{new Map<String, Object>{
            'resourceUrl' => 'https://api.xero.com/api.xro/2.0/Invoices/ea3290c4-d8ef-4029-b41f-aecfcee8e4a3',
            'resourceId' => 'ea3290c4-d8ef-4029-b41f-aecfcee8e4a3',
            'eventDateUtc' => '2021-08-10T05:32:49',
            'eventType' => 'UPDATE',
            'eventCategory' => 'INVOICE'
        }});
        payload.put('firstEventSequence', 1);
        payload.put('lastEventSequence', 1);
        payload.put('entropy', 'abcd');

        return JSON.serialize(payload);
    }
    
    /**
     * @description Helper method to create a mock Xero signature
     * @param payload
     * @return String
    */
    public static String createMockSignature(String payload) {
        // Retrieve the webhook key from the Xero connection record
        KTXero__Xero_Connection__c xeroConnectionObj = [SELECT
                                                        Id, Name, KTXero__Webhook_Key__c, KTXero__Client_Id__c, KTXero__Client_Secret__c, KTXero__Access_Token__c
                                                        FROM
                                                        KTXero__Xero_Connection__c ORDER BY CreatedDate DESC LIMIT 1];
        String webhookKey = Utils.processDecryption(xeroConnectionObj.KTXero__Webhook_Key__c);
        
        // Generate the signature using hmacSHA256 and base64 encoding
        Blob signedPayload = Crypto.generateMac(
        'hmacSHA256',
        Blob.valueOf(payload),
        Blob.valueOf(webhookKey)
        );
        return EncodingUtil.base64Encode(signedPayload);
    }
    
    // Test method for doPost method
    @isTest
    public static void testDoPost() {
        // Create a test Xero connection record with a dummy webhook key
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);
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
        // Create a mock Xero payload and signature
        String mockPayload = createMockPayload();
        String mockSignature = createMockSignature(mockPayload);
        
        // Set up the REST request and response objects
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(mockPayload);
        req.headers.put('x-xero-signature', mockSignature);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        // Test the method with valid input and signature
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorPayment());
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorInvoice());
        XeroWebHookService.doGet();
        System.assertEquals('testkey',Utils.processDecryption(testObj.KTXero__Webhook_Key__c) ,'testkey');
        Test.stopTest();
        
        // Verify the response status code and assert that the SyncInvoiceContact method was called
        System.assertEquals(200, res.statusCode, 'The response status code should be 200 for valid input and signature');
    
    }

    // Test method for doPost method
    @isTest
    public static void testDoPostwithExpireToken() {
        // Create a test Xero connection record with a dummy webhook key
        KTXero__Xero_Connection__c xc = TestUtil.createXeroConnection(false);
        xc.KTXero__Last_Token_Refresh_Time__c = System.now().addDays(-2);
        insert xc;

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
        
        
        KTXero__Bill__c bill = new KTXero__Bill__c();
        bill.KTXero__Bill_Id__c = 'ea3290c4-d8ef-4029-b41f-aecfcee8e4a3';
        bill.Name  = 'New Bill';
        insert bill;

        KTXero__Xero_Connection__c testObj = [SELECT Id, Name, KTXero__Webhook_Key__c, KTXero__Client_Id__c, KTXero__Client_Secret__c, KTXero__Access_Token__c 
                                                FROM KTXero__Xero_Connection__c ORDER BY CreatedDate DESC LIMIT 1];
        // Create a mock Xero payload and signature
        String mockPayload = createMockPayload();
        String mockSignature = createMockSignature(mockPayload);
        
        // Set up the REST request and response objects
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(mockPayload);
        req.headers.put('x-xero-signature', mockSignature);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        // Test the method with valid input and signature
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorPayment());
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorInvoice());
        XeroWebHookService.doGet();
        System.assertEquals('testkey',Utils.processDecryption(testObj.KTXero__Webhook_Key__c) ,'testkey');
        Test.stopTest();
        
        // Verify the response status code and assert that the SyncInvoiceContact method was called
        System.assertEquals(200, res.statusCode, 'The response status code should be 200 for valid input and signature');
    
    }

    
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
    }
    
    @isTest
    public static void testDoPostBill() {
        // Create a test Xero connection record with a dummy webhook key
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);
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
    
        KTXero__Bill__c bill = new KTXero__Bill__c();
        bill.KTXero__Bill_Id__c = 'ea3290c4-d8ef-4029-b41f-aecfcee8e4a3';
        bill.Name  = 'New Bill';
        insert bill;

        KTXero__Bill_Line_Item__c xeroInv = new KTXero__Bill_Line_Item__c();
        xeroInv.KTXero__Item_Code__c = 'Test205';
        xeroInv.KTXero__Product__c = testProduct.id;
        xeroInv.KTXero__Bill__c = bill.Id;
        xeroInv.KTXero__Line_Item_Id__c = 'a21423b7-c179-42f5-b2ec-17f9ce8f7804';
        insert xeroInv;
        
        
        KTXero__Xero_Connection__c testObj = [SELECT Id, Name, KTXero__Webhook_Key__c, KTXero__Client_Id__c, KTXero__Client_Secret__c, KTXero__Access_Token__c 
                                                FROM KTXero__Xero_Connection__c ORDER BY CreatedDate DESC LIMIT 1];
        // Create a mock Xero payload and signature
        String mockPayload = createBillMockPayload();
        String mockSignature = createMockSignature(mockPayload);
        
        // Set up the REST request and response objects
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(mockPayload);
        req.headers.put('x-xero-signature', mockSignature);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        // Test the method with valid input and signature
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorPayment());
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorInvoice());
        XeroWebHookService.doGet();
        System.assertEquals('testkey',Utils.processDecryption(testObj.KTXero__Webhook_Key__c) ,'testkey');
        Test.stopTest();
        
        // Verify the response status code and assert that the SyncInvoiceContact method was called
        System.assertEquals(200, res.statusCode, 'The response status code should be 200 for valid input and signature');
    
    }

    private class MockHttpResponseGeneratorBill implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Id\":\"4a0b3db9-dd9a-4a5d-941b-58c6215d1134\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"/Date(1684831274579)/\",\"Invoices\":[{\"Type\":\"ACCPAY\",\"InvoiceID\":\"ea3290c4-d8ef-4029-b41f-aecfcee8e4a3\",\"InvoiceNumber\":\"INV-0051\",\"Reference\":\"001Dn00000Qc9GaIAJ\",\"Prepayments\":[],\"Payments\":[{\"Date\":\"Date(1684420182133+0000)\",\"PaymentID\":\"xeroPaymentId\",\"Amount\":100,\"CurrencyRate\":1.0000000000,\"HasAccount\":true,\"HasValidationErrors\":false}],\"Overpayments\":[],\"AmountDue\":0.00,\"AmountPaid\":0.00,\"SentToContact\":false,\"CurrencyRate\":1.0000000000,\"TotalDiscount\":0.00,\"IsDiscounted\":true,\"HasAttachments\":false,\"HasErrors\":false,\"Attachments\":[],\"InvoicePaymentServices\":[],\"Contact\":{\"ContactID\":\"37d78e0c-cd12-4dba-b518-8043c8b28480\",\"ContactStatus\":\"ACTIVE\",\"Name\":\"TestAccountBK6\",\"FirstName\":\"Test\",\"LastName\":\"Contact\",\"EmailAddress\":\"bhagyashree.k@kandisatech.com\",\"BankAccountDetails\":\"\",\"Addresses\":[{\"AddressType\":\"STREET\",\"City\":\"\",\"Region\":\"\",\"PostalCode\":\"\",\"Country\":\"\"},{\"AddressType\":\"POBOX\",\"AddressLine1\":\"test123\",\"City\":\"mum\",\"Region\":\"mh\",\"PostalCode\":\"852963\",\"Country\":\"in\"}],\"Phones\":[{\"PhoneType\":\"DEFAULT\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"DDI\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"FAX\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"MOBILE\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"}],\"UpdatedDateUTC\":\"/Date(1684420181097+0000)/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":true,\"SalesTrackingCategories\":[],\"PurchasesTrackingCategories\":[],\"ContactPersons\":[],\"HasValidationErrors\":false},\"DateString\":\"2023-04-18T00:00:00\",\"Date\":\"/Date(1681776000000+0000)/\",\"DueDateString\":\"2023-04-21T00:00:00\",\"DueDate\":\"/Date(1682035200000+0000)/\",\"BrandingThemeID\":\"f04ccf02-5a40-4ee2-a786-d6b97a34b8f4\",\"Status\":\"DRAFT\",\"LineAmountTypes\":\"Exclusive\",\"LineItems\":[{\"ItemCode\":\"PMBr\",\"Description\":\"Project management & implementation - branding workshop with your team - follow up session\",\"UnitAmount\":200,\"TaxType\":\"OUTPUT\",\"TaxAmount\":16.5,\"LineAmount\":200,\"AccountCode\":\"200\",\"Item\":{\"ItemID\":\"ec4362af-a038-4984-ab93-1bba3b6bd402\",\"Name\":\"Project management & implementation - branding\",\"Code\":\"PMBr\"},\"Tracking\":[{\"Name\":\"TR001\",\"Option\":\"Option1\",\"TrackingCategoryID\":\"TCID-001\",\"TrackingOptionID\":\"TO001\"}],\"Quantity\":15.0000,\"DiscountRate\":85.00,\"LineItemID\":\"a21423b7-c179-42f5-b2ec-17f9ce8f7804\",\"DiscountAmount\":0.0000,\"ValidationErrors\":[]},   {\"ItemCode\":\"TestCode\",\"Description\":\"Project management & implementation - branding workshop with your team - follow up session\",\"UnitAmount\":200,\"TaxType\":\"OUTPUT\",\"TaxAmount\":16.5,\"LineAmount\":200,\"AccountCode\":\"200\",\"Item\":{\"ItemID\":\"123456\",\"Name\":\"Project management & implementation - branding\",\"Code\":\"TestCode\"},\"Tracking\":[{\"Name\":\"TR001\",\"Option\":\"Option1\",\"TrackingCategoryID\":\"TCID-001\",\"TrackingOptionID\":\"TO001\"}],\"Quantity\":15.0000,\"DiscountRate\":90.00,\"LineItemID\":\"123456789\",\"DiscountAmount\":0.0000,\"ValidationErrors\":[]}   ],\"SubTotal\":0.00,\"TotalTax\":0.00,\"Total\":0.00,\"UpdatedDateUTC\":\"/Date(1684420182133+0000)/\",\"CurrencyCode\":\"USD\"}]}');

        
            response.setStatusCode(200);
            return response;
        } 
    }


    private class MockHttpResponseGeneratorPayment implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Payments\":[{\"PaymentID\":\"b26fd49a-cbae-470a-a8f8-bcbc119e0379\",\"BatchPaymentID\":\"b54aa50c-794c-461b-89d1-846e1b84d9c0\",\"BatchPayment\":{\"Account\":{\"AccountID\":\"ac993f75-035b-433c-82e0-7b7a2d40802c\"},\"BatchPaymentID\":\"b54aa50c-794c-461b-89d1-846e1b84d9c0\",\"Type\":\"RECBATCH\",\"Status\":\"AUTHORISED\",\"TotalAmount\":\"600.00\"},\"BankAmount\":500,\"Amount\":500,\"Reference\":\"INV-0001\",\"CurrencyRate\":1,\"PaymentType\":\"ACCRECPAYMENT\",\"Status\":\"AUTHORISED\",\"HasAccount\":true,\"IsReconciled\":true,\"Account\":{\"AccountID\":\"ac993f75-035b-433c-82e0-7b7a2d40802c\",\"Code\":\"090\"},\"Invoice\":{\"Type\":\"ACCREC\",\"InvoiceID\":\"b0875d8b-ff26-4ce8-8aea-6955492ead48\",\"InvoiceNumber\":\"INV-0001\",\"Contact\":{\"ContactID\":\"fef6755f-549b-4617-b1e9-60bdffb517d8\",\"Name\":\"Ridgeway University\"}}}]}');
            response.setStatusCode(200);
            return response;
        } 
    }
    
    @isTest
    public static void testDoPost1() {
        // Create a test Xero connection record with a dummy webhook key
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);

        
        KTXero__Invoice_Configuration_Options__c objConfig = new KTXero__Invoice_Configuration_Options__c(
            KTXero__Default_Tax_rate__c = 'OUTPUT',
            KTXero__Draft_Invoice__c = true,
            KTXero__Create_products_in_Salesforce__c = true,
            KTXero__Create_items_in_Xero__c = true
        );
        insert objConfig;

        KTXero__Xero_Connection__c testObj = [SELECT Id, Name, KTXero__Webhook_Key__c, KTXero__Client_Id__c, KTXero__Client_Secret__c, KTXero__Access_Token__c 
                                                FROM KTXero__Xero_Connection__c ORDER BY CreatedDate DESC LIMIT 1];
        // Create a mock Xero payload and signature
        String mockPayload = createMockPayload();
        String mockSignature = createMockSignature(mockPayload);
        
        // Set up the REST request and response objects
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(mockPayload);
        req.headers.put('x-xero-signature', mockSignature);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        // Test the method with valid input and signature
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorInvoice());
        System.assertEquals('testkey',Utils.processDecryption(testObj.KTXero__Webhook_Key__c) ,'testkey');
        XeroWebHookService.doGet();
        Test.stopTest();
        
        // Verify the response status code and assert that the SyncInvoiceContact method was called
        System.assertEquals(200, res.statusCode, 'The response status code should be 200 for valid input and signature');
    
    }

    
    @isTest
    public static void testCreateContact() {

        // Create a test Xero connection record with a dummy webhook key
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);


        List<InvoiceCreationWrapper.Addresses> addList = new List<InvoiceCreationWrapper.Addresses>();
        InvoiceCreationWrapper.Addresses addObj = new InvoiceCreationWrapper.Addresses();
        addObj.AddressType = 'POBOX';
        addObj.AddressLine1 = 'test';
        addObj.City = 'test';
        addObj.Region = 'test';
        addObj.PostalCode = '123455';
        addObj.Country = 'test';
        addList.add(addObj);
        
        InvoiceCreationWrapper.Addresses addObj1 = new InvoiceCreationWrapper.Addresses();
        addObj1.AddressType = 'DELIVERY';
        addObj1.AddressLine1 = 'test';
        addObj1.City = 'test';
        addObj1.Region = 'test';
        addObj1.PostalCode = '8523';
        addObj1.Country = 'test';
        addList.add(addObj1);

        List<InvoiceCreationWrapper.ContactPersons> conPerList = new List<InvoiceCreationWrapper.ContactPersons>();
        InvoiceCreationWrapper.ContactPersons conPerObj = new InvoiceCreationWrapper.ContactPersons();
        conPerObj.FirstName = 'test';
        conPerObj.LastName = 'test';
        conPerObj.EmailAddress = 'test@test.com';
        conPerObj.IncludeInEmails = true;
        conPerList.add(conPerObj);

        InvoiceCreationWrapper.ContactPersons conPerObj1 = new InvoiceCreationWrapper.ContactPersons();
        conPerObj1.FirstName = 'test';
        conPerObj1.LastName = 'test';
        conPerObj1.EmailAddress = 'test@test.com';
        conPerObj1.IncludeInEmails = true;
        conPerList.add(conPerObj1);


        InvoiceCreationWrapper.ContactPersons conPerObj2 = new InvoiceCreationWrapper.ContactPersons();
        conPerObj2.FirstName = 'test';
        conPerObj2.LastName = 'test';
        conPerObj2.EmailAddress = 'test@test.com';
        conPerObj2.IncludeInEmails = true;
        conPerList.add(conPerObj2);

        InvoiceCreationWrapper.ContactPersons conPerObj3 = new InvoiceCreationWrapper.ContactPersons();
        conPerObj3.FirstName = 'test';
        conPerObj3.LastName = 'test';
        conPerObj3.EmailAddress = 'test@test.com';
        conPerObj3.IncludeInEmails = true;
        conPerList.add(conPerObj3);

        InvoiceCreationWrapper.ContactPersons conPerObj4 = new InvoiceCreationWrapper.ContactPersons();
        conPerObj4.FirstName = 'test';
        conPerObj4.LastName = 'test';
        conPerObj4.EmailAddress = 'test@test.com';
        conPerObj4.IncludeInEmails = true;
        conPerList.add(conPerObj4);



        List<InvoiceCreationWrapper.Contacts> conList = new List<InvoiceCreationWrapper.Contacts>();
        InvoiceCreationWrapper.Contacts conObj = new InvoiceCreationWrapper.Contacts();
        conObj.ContactID = 'TestContactId';
        conObj.AccountNumber = 'TestContactId';
        conObj.ContactStatus = 'TestContactId';
        conObj.Name = 'TestContactId';
        conObj.FirstName = 'TestContactId';
        conObj.LastName = 'TestContactId';
        conObj.EmailAddress = 'TestContactId';
        conObj.ContactID = 'TestContactId';
        conObj.Addresses = addList;
        conObj.ContactPersons = conPerList;
        conList.add(conObj);


        InvoiceCreationWrapper.Datawrap dWrap = new InvoiceCreationWrapper.Datawrap();
        dWrap.Id = 'TestDwrapId';
        dWrap.Status = 'test';
        dWrap.ProviderName = 'TestDwrapId';
        dWrap.DateTimeUTC = '';
        dWrap.Contacts = conList;

        XeroWebHookService.createContact('123456', dWrap);


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

        KTXero__Xero_Contact__c xeroCon = new KTXero__Xero_Contact__c();
        xeroCon.KTXero__First_Name__c = 'test';
        xeroCon.KTXero__Last_Name__c = 'test';
        xeroCon.KTXero__Email_Address__c = 'test@test.com';
        xeroCon.KTXero__Salesforce_Account__c = acc.Id;
        xeroCon.KTXero__Status__c = 'test';
        xeroCon.KTXero__Reference_Id__c = '123456';
        insert xeroCon;
        
        XeroWebHookService.createContact(xeroCon.KTXero__Reference_Id__c, dWrap);
        System.assertEquals('Test Account',acc.Name, 'Success');
    }

    @isTest
    public static void testCreateContact0() {

        // Create a test Xero connection record with a dummy webhook key
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);


        List<InvoiceCreationWrapper.Addresses> addList = new List<InvoiceCreationWrapper.Addresses>();
        InvoiceCreationWrapper.Addresses addObj = new InvoiceCreationWrapper.Addresses();
        addObj.AddressType = 'POBOX';
        addObj.AddressLine1 = 'test';
        addObj.City = 'test';
        addObj.Region = 'test';
        addObj.PostalCode = '123455';
        addObj.Country = 'test';
        addList.add(addObj);
        
        InvoiceCreationWrapper.Addresses addObj1 = new InvoiceCreationWrapper.Addresses();
        addObj1.AddressType = 'DELIVERY';
        addObj1.AddressLine1 = 'test';
        addObj1.City = 'test';
        addObj1.Region = 'test';
        addObj1.PostalCode = '8523';
        addObj1.Country = 'test';
        addList.add(addObj1);

        List<InvoiceCreationWrapper.ContactPersons> conPerList = new List<InvoiceCreationWrapper.ContactPersons>();
        // InvoiceCreationWrapper.ContactPersons conPerObj = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj.FirstName = 'test';
        // conPerObj.LastName = 'test';
        // conPerObj.EmailAddress = 'test@test.com';
        // conPerObj.IncludeInEmails = true;
        // conPerList.add(conPerObj);

        // InvoiceCreationWrapper.ContactPersons conPerObj1 = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj1.FirstName = 'test';
        // conPerObj1.LastName = 'test';
        // conPerObj1.EmailAddress = 'test@test.com';
        // conPerObj1.IncludeInEmails = true;
        // conPerList.add(conPerObj1);


        // InvoiceCreationWrapper.ContactPersons conPerObj2 = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj2.FirstName = 'test';
        // conPerObj2.LastName = 'test';
        // conPerObj2.EmailAddress = 'test@test.com';
        // conPerObj2.IncludeInEmails = true;
        // conPerList.add(conPerObj2);

        // InvoiceCreationWrapper.ContactPersons conPerObj3 = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj3.FirstName = 'test';
        // conPerObj3.LastName = 'test';
        // conPerObj3.EmailAddress = 'test@test.com';
        // conPerObj3.IncludeInEmails = true;
        // conPerList.add(conPerObj3);

        // InvoiceCreationWrapper.ContactPersons conPerObj4 = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj4.FirstName = 'test';
        // conPerObj4.LastName = 'test';
        // conPerObj4.EmailAddress = 'test@test.com';
        // conPerObj4.IncludeInEmails = true;
        // conPerList.add(conPerObj4);



        List<InvoiceCreationWrapper.Contacts> conList = new List<InvoiceCreationWrapper.Contacts>();
        InvoiceCreationWrapper.Contacts conObj = new InvoiceCreationWrapper.Contacts();
        conObj.ContactID = 'TestContactId';
        conObj.AccountNumber = 'TestContactId';
        conObj.ContactStatus = 'TestContactId';
        conObj.Name = 'TestContactId';
        conObj.FirstName = 'TestContactId';
        conObj.LastName = 'TestContactId';
        conObj.EmailAddress = 'TestContactId';
        conObj.ContactID = 'TestContactId';
        conObj.Addresses = addList;
        conObj.ContactPersons = conPerList;
        conList.add(conObj);


        InvoiceCreationWrapper.Datawrap dWrap = new InvoiceCreationWrapper.Datawrap();
        dWrap.Id = 'TestDwrapId';
        dWrap.Status = 'test';
        dWrap.ProviderName = 'TestDwrapId';
        dWrap.DateTimeUTC = '';
        dWrap.Contacts = conList;

        XeroWebHookService.createContact('123456', dWrap);


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

        KTXero__Xero_Contact__c xeroCon = new KTXero__Xero_Contact__c();
        xeroCon.KTXero__First_Name__c = 'test';
        xeroCon.KTXero__Last_Name__c = 'test';
        xeroCon.KTXero__Email_Address__c = 'test@test.com';
        xeroCon.KTXero__Salesforce_Account__c = acc.Id;
        xeroCon.KTXero__Status__c = 'test';
        xeroCon.KTXero__Reference_Id__c = '123456';
        insert xeroCon;
        
        XeroWebHookService.createContact(xeroCon.KTXero__Reference_Id__c, dWrap);
        System.assertEquals('Test Account',acc.Name, 'Success');
    }

    @isTest
    public static void testCreateContact1() {

        // Create a test Xero connection record with a dummy webhook key
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);


        List<InvoiceCreationWrapper.Addresses> addList = new List<InvoiceCreationWrapper.Addresses>();
        InvoiceCreationWrapper.Addresses addObj = new InvoiceCreationWrapper.Addresses();
        addObj.AddressType = 'POBOX';
        addObj.AddressLine1 = 'test';
        addObj.City = 'test';
        addObj.Region = 'test';
        addObj.PostalCode = '123455';
        addObj.Country = 'test';
        addList.add(addObj);
        
        InvoiceCreationWrapper.Addresses addObj1 = new InvoiceCreationWrapper.Addresses();
        addObj1.AddressType = 'DELIVERY';
        addObj1.AddressLine1 = 'test';
        addObj1.City = 'test';
        addObj1.Region = 'test';
        addObj1.PostalCode = '8523';
        addObj1.Country = 'test';
        addList.add(addObj1);

        List<InvoiceCreationWrapper.ContactPersons> conPerList = new List<InvoiceCreationWrapper.ContactPersons>();
        InvoiceCreationWrapper.ContactPersons conPerObj = new InvoiceCreationWrapper.ContactPersons();
        conPerObj.FirstName = 'test';
        conPerObj.LastName = 'test';
        conPerObj.EmailAddress = 'test@test.com';
        conPerObj.IncludeInEmails = true;
        conPerList.add(conPerObj);

        // InvoiceCreationWrapper.ContactPersons conPerObj1 = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj1.FirstName = 'test';
        // conPerObj1.LastName = 'test';
        // conPerObj1.EmailAddress = 'test@test.com';
        // conPerObj1.IncludeInEmails = true;
        // conPerList.add(conPerObj1);


        // InvoiceCreationWrapper.ContactPersons conPerObj2 = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj2.FirstName = 'test';
        // conPerObj2.LastName = 'test';
        // conPerObj2.EmailAddress = 'test@test.com';
        // conPerObj2.IncludeInEmails = true;
        // conPerList.add(conPerObj2);

        // InvoiceCreationWrapper.ContactPersons conPerObj3 = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj3.FirstName = 'test';
        // conPerObj3.LastName = 'test';
        // conPerObj3.EmailAddress = 'test@test.com';
        // conPerObj3.IncludeInEmails = true;
        // conPerList.add(conPerObj3);

        // InvoiceCreationWrapper.ContactPersons conPerObj4 = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj4.FirstName = 'test';
        // conPerObj4.LastName = 'test';
        // conPerObj4.EmailAddress = 'test@test.com';
        // conPerObj4.IncludeInEmails = true;
        // conPerList.add(conPerObj4);



        List<InvoiceCreationWrapper.Contacts> conList = new List<InvoiceCreationWrapper.Contacts>();
        InvoiceCreationWrapper.Contacts conObj = new InvoiceCreationWrapper.Contacts();
        conObj.ContactID = 'TestContactId';
        conObj.AccountNumber = 'TestContactId';
        conObj.ContactStatus = 'TestContactId';
        conObj.Name = 'TestContactId';
        conObj.FirstName = 'TestContactId';
        conObj.LastName = 'TestContactId';
        conObj.EmailAddress = 'TestContactId';
        conObj.ContactID = 'TestContactId';
        conObj.Addresses = addList;
        conObj.ContactPersons = conPerList;
        conList.add(conObj);


        InvoiceCreationWrapper.Datawrap dWrap = new InvoiceCreationWrapper.Datawrap();
        dWrap.Id = 'TestDwrapId';
        dWrap.Status = 'test';
        dWrap.ProviderName = 'TestDwrapId';
        dWrap.DateTimeUTC = '';
        dWrap.Contacts = conList;

        XeroWebHookService.createContact('123456', dWrap);


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

        KTXero__Xero_Contact__c xeroCon = new KTXero__Xero_Contact__c();
        xeroCon.KTXero__First_Name__c = 'test';
        xeroCon.KTXero__Last_Name__c = 'test';
        xeroCon.KTXero__Email_Address__c = 'test@test.com';
        xeroCon.KTXero__Salesforce_Account__c = acc.Id;
        xeroCon.KTXero__Status__c = 'test';
        xeroCon.KTXero__Reference_Id__c = '123456';
        insert xeroCon;
        
        XeroWebHookService.createContact(xeroCon.KTXero__Reference_Id__c, dWrap);
        System.assertEquals('Test Account',acc.Name, 'Success');
    }

    @isTest
    public static void testCreateContact2() {

        // Create a test Xero connection record with a dummy webhook key
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);


        List<InvoiceCreationWrapper.Addresses> addList = new List<InvoiceCreationWrapper.Addresses>();
        InvoiceCreationWrapper.Addresses addObj = new InvoiceCreationWrapper.Addresses();
        addObj.AddressType = 'POBOX';
        addObj.AddressLine1 = 'test';
        addObj.City = 'test';
        addObj.Region = 'test';
        addObj.PostalCode = '123455';
        addObj.Country = 'test';
        addList.add(addObj);
        
        InvoiceCreationWrapper.Addresses addObj1 = new InvoiceCreationWrapper.Addresses();
        addObj1.AddressType = 'DELIVERY';
        addObj1.AddressLine1 = 'test';
        addObj1.City = 'test';
        addObj1.Region = 'test';
        addObj1.PostalCode = '8523';
        addObj1.Country = 'test';
        addList.add(addObj1);

        List<InvoiceCreationWrapper.ContactPersons> conPerList = new List<InvoiceCreationWrapper.ContactPersons>();
        InvoiceCreationWrapper.ContactPersons conPerObj = new InvoiceCreationWrapper.ContactPersons();
        conPerObj.FirstName = 'test';
        conPerObj.LastName = 'test';
        conPerObj.EmailAddress = 'test@test.com';
        conPerObj.IncludeInEmails = true;
        conPerList.add(conPerObj);

        InvoiceCreationWrapper.ContactPersons conPerObj1 = new InvoiceCreationWrapper.ContactPersons();
        conPerObj1.FirstName = 'test';
        conPerObj1.LastName = 'test';
        conPerObj1.EmailAddress = 'test@test.com';
        conPerObj1.IncludeInEmails = true;
        conPerList.add(conPerObj1);


        // InvoiceCreationWrapper.ContactPersons conPerObj2 = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj2.FirstName = 'test';
        // conPerObj2.LastName = 'test';
        // conPerObj2.EmailAddress = 'test@test.com';
        // conPerObj2.IncludeInEmails = true;
        // conPerList.add(conPerObj2);

        // InvoiceCreationWrapper.ContactPersons conPerObj3 = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj3.FirstName = 'test';
        // conPerObj3.LastName = 'test';
        // conPerObj3.EmailAddress = 'test@test.com';
        // conPerObj3.IncludeInEmails = true;
        // conPerList.add(conPerObj3);

        // InvoiceCreationWrapper.ContactPersons conPerObj4 = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj4.FirstName = 'test';
        // conPerObj4.LastName = 'test';
        // conPerObj4.EmailAddress = 'test@test.com';
        // conPerObj4.IncludeInEmails = true;
        // conPerList.add(conPerObj4);



        List<InvoiceCreationWrapper.Contacts> conList = new List<InvoiceCreationWrapper.Contacts>();
        InvoiceCreationWrapper.Contacts conObj = new InvoiceCreationWrapper.Contacts();
        conObj.ContactID = 'TestContactId';
        conObj.AccountNumber = 'TestContactId';
        conObj.ContactStatus = 'TestContactId';
        conObj.Name = 'TestContactId';
        conObj.FirstName = 'TestContactId';
        conObj.LastName = 'TestContactId';
        conObj.EmailAddress = 'TestContactId';
        conObj.ContactID = 'TestContactId';
        conObj.Addresses = addList;
        conObj.ContactPersons = conPerList;
        conList.add(conObj);


        InvoiceCreationWrapper.Datawrap dWrap = new InvoiceCreationWrapper.Datawrap();
        dWrap.Id = 'TestDwrapId';
        dWrap.Status = 'test';
        dWrap.ProviderName = 'TestDwrapId';
        dWrap.DateTimeUTC = '';
        dWrap.Contacts = conList;

        XeroWebHookService.createContact('123456', dWrap);


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

        KTXero__Xero_Contact__c xeroCon = new KTXero__Xero_Contact__c();
        xeroCon.KTXero__First_Name__c = 'test';
        xeroCon.KTXero__Last_Name__c = 'test';
        xeroCon.KTXero__Email_Address__c = 'test@test.com';
        xeroCon.KTXero__Salesforce_Account__c = acc.Id;
        xeroCon.KTXero__Status__c = 'test';
        xeroCon.KTXero__Reference_Id__c = '123456';
        insert xeroCon;
        
        XeroWebHookService.createContact(xeroCon.KTXero__Reference_Id__c, dWrap);
        System.assertEquals('Test Account',acc.Name, 'Success');
    }

    @isTest
    public static void testCreateContact3() {

        // Create a test Xero connection record with a dummy webhook key
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);


        List<InvoiceCreationWrapper.Addresses> addList = new List<InvoiceCreationWrapper.Addresses>();
        InvoiceCreationWrapper.Addresses addObj = new InvoiceCreationWrapper.Addresses();
        addObj.AddressType = 'POBOX';
        addObj.AddressLine1 = 'test';
        addObj.City = 'test';
        addObj.Region = 'test';
        addObj.PostalCode = '123455';
        addObj.Country = 'test';
        addList.add(addObj);
        
        InvoiceCreationWrapper.Addresses addObj1 = new InvoiceCreationWrapper.Addresses();
        addObj1.AddressType = 'DELIVERY';
        addObj1.AddressLine1 = 'test';
        addObj1.City = 'test';
        addObj1.Region = 'test';
        addObj1.PostalCode = '8523';
        addObj1.Country = 'test';
        addList.add(addObj1);

        List<InvoiceCreationWrapper.ContactPersons> conPerList = new List<InvoiceCreationWrapper.ContactPersons>();
        InvoiceCreationWrapper.ContactPersons conPerObj = new InvoiceCreationWrapper.ContactPersons();
        conPerObj.FirstName = 'test';
        conPerObj.LastName = 'test';
        conPerObj.EmailAddress = 'test@test.com';
        conPerObj.IncludeInEmails = true;
        conPerList.add(conPerObj);

        InvoiceCreationWrapper.ContactPersons conPerObj1 = new InvoiceCreationWrapper.ContactPersons();
        conPerObj1.FirstName = 'test';
        conPerObj1.LastName = 'test';
        conPerObj1.EmailAddress = 'test@test.com';
        conPerObj1.IncludeInEmails = true;
        conPerList.add(conPerObj1);


        InvoiceCreationWrapper.ContactPersons conPerObj2 = new InvoiceCreationWrapper.ContactPersons();
        conPerObj2.FirstName = 'test';
        conPerObj2.LastName = 'test';
        conPerObj2.EmailAddress = 'test@test.com';
        conPerObj2.IncludeInEmails = true;
        conPerList.add(conPerObj2);

        // InvoiceCreationWrapper.ContactPersons conPerObj3 = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj3.FirstName = 'test';
        // conPerObj3.LastName = 'test';
        // conPerObj3.EmailAddress = 'test@test.com';
        // conPerObj3.IncludeInEmails = true;
        // conPerList.add(conPerObj3);

        // InvoiceCreationWrapper.ContactPersons conPerObj4 = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj4.FirstName = 'test';
        // conPerObj4.LastName = 'test';
        // conPerObj4.EmailAddress = 'test@test.com';
        // conPerObj4.IncludeInEmails = true;
        // conPerList.add(conPerObj4);



        List<InvoiceCreationWrapper.Contacts> conList = new List<InvoiceCreationWrapper.Contacts>();
        InvoiceCreationWrapper.Contacts conObj = new InvoiceCreationWrapper.Contacts();
        conObj.ContactID = 'TestContactId';
        conObj.AccountNumber = 'TestContactId';
        conObj.ContactStatus = 'TestContactId';
        conObj.Name = 'TestContactId';
        conObj.FirstName = 'TestContactId';
        conObj.LastName = 'TestContactId';
        conObj.EmailAddress = 'TestContactId';
        conObj.ContactID = 'TestContactId';
        conObj.Addresses = addList;
        conObj.ContactPersons = conPerList;
        conList.add(conObj);


        InvoiceCreationWrapper.Datawrap dWrap = new InvoiceCreationWrapper.Datawrap();
        dWrap.Id = 'TestDwrapId';
        dWrap.Status = 'test';
        dWrap.ProviderName = 'TestDwrapId';
        dWrap.DateTimeUTC = '';
        dWrap.Contacts = conList;

        XeroWebHookService.createContact('123456', dWrap);


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

        KTXero__Xero_Contact__c xeroCon = new KTXero__Xero_Contact__c();
        xeroCon.KTXero__First_Name__c = 'test';
        xeroCon.KTXero__Last_Name__c = 'test';
        xeroCon.KTXero__Email_Address__c = 'test@test.com';
        xeroCon.KTXero__Salesforce_Account__c = acc.Id;
        xeroCon.KTXero__Status__c = 'test';
        xeroCon.KTXero__Reference_Id__c = '123456';
        insert xeroCon;
        
        XeroWebHookService.createContact(xeroCon.KTXero__Reference_Id__c, dWrap);
        System.assertEquals('Test Account',acc.Name, 'Success');
    }

    @isTest
    public static void testCreateContact4() {

        // Create a test Xero connection record with a dummy webhook key
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);


        List<InvoiceCreationWrapper.Addresses> addList = new List<InvoiceCreationWrapper.Addresses>();
        InvoiceCreationWrapper.Addresses addObj = new InvoiceCreationWrapper.Addresses();
        addObj.AddressType = 'POBOX';
        addObj.AddressLine1 = 'test';
        addObj.City = 'test';
        addObj.Region = 'test';
        addObj.PostalCode = '123455';
        addObj.Country = 'test';
        addList.add(addObj);
        
        InvoiceCreationWrapper.Addresses addObj1 = new InvoiceCreationWrapper.Addresses();
        addObj1.AddressType = 'DELIVERY';
        addObj1.AddressLine1 = 'test';
        addObj1.City = 'test';
        addObj1.Region = 'test';
        addObj1.PostalCode = '8523';
        addObj1.Country = 'test';
        addList.add(addObj1);

        List<InvoiceCreationWrapper.ContactPersons> conPerList = new List<InvoiceCreationWrapper.ContactPersons>();
        InvoiceCreationWrapper.ContactPersons conPerObj = new InvoiceCreationWrapper.ContactPersons();
        conPerObj.FirstName = 'test';
        conPerObj.LastName = 'test';
        conPerObj.EmailAddress = 'test@test.com';
        conPerObj.IncludeInEmails = true;
        conPerList.add(conPerObj);

        InvoiceCreationWrapper.ContactPersons conPerObj1 = new InvoiceCreationWrapper.ContactPersons();
        conPerObj1.FirstName = 'test';
        conPerObj1.LastName = 'test';
        conPerObj1.EmailAddress = 'test@test.com';
        conPerObj1.IncludeInEmails = true;
        conPerList.add(conPerObj1);


        InvoiceCreationWrapper.ContactPersons conPerObj2 = new InvoiceCreationWrapper.ContactPersons();
        conPerObj2.FirstName = 'test';
        conPerObj2.LastName = 'test';
        conPerObj2.EmailAddress = 'test@test.com';
        conPerObj2.IncludeInEmails = true;
        conPerList.add(conPerObj2);

        InvoiceCreationWrapper.ContactPersons conPerObj3 = new InvoiceCreationWrapper.ContactPersons();
        conPerObj3.FirstName = 'test';
        conPerObj3.LastName = 'test';
        conPerObj3.EmailAddress = 'test@test.com';
        conPerObj3.IncludeInEmails = true;
        conPerList.add(conPerObj3);

        // InvoiceCreationWrapper.ContactPersons conPerObj4 = new InvoiceCreationWrapper.ContactPersons();
        // conPerObj4.FirstName = 'test';
        // conPerObj4.LastName = 'test';
        // conPerObj4.EmailAddress = 'test@test.com';
        // conPerObj4.IncludeInEmails = true;
        // conPerList.add(conPerObj4);



        List<InvoiceCreationWrapper.Contacts> conList = new List<InvoiceCreationWrapper.Contacts>();
        InvoiceCreationWrapper.Contacts conObj = new InvoiceCreationWrapper.Contacts();
        conObj.ContactID = 'TestContactId';
        conObj.AccountNumber = 'TestContactId';
        conObj.ContactStatus = 'TestContactId';
        conObj.Name = 'TestContactId';
        conObj.FirstName = 'TestContactId';
        conObj.LastName = 'TestContactId';
        conObj.EmailAddress = 'TestContactId';
        conObj.ContactID = 'TestContactId';
        conObj.Addresses = addList;
        conObj.ContactPersons = conPerList;
        conList.add(conObj);


        InvoiceCreationWrapper.Datawrap dWrap = new InvoiceCreationWrapper.Datawrap();
        dWrap.Id = 'TestDwrapId';
        dWrap.Status = 'test';
        dWrap.ProviderName = 'TestDwrapId';
        dWrap.DateTimeUTC = '';
        dWrap.Contacts = conList;

        XeroWebHookService.createContact('123456', dWrap);


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

        KTXero__Xero_Contact__c xeroCon = new KTXero__Xero_Contact__c();
        xeroCon.KTXero__First_Name__c = 'test';
        xeroCon.KTXero__Last_Name__c = 'test';
        xeroCon.KTXero__Email_Address__c = 'test@test.com';
        xeroCon.KTXero__Salesforce_Account__c = acc.Id;
        xeroCon.KTXero__Status__c = 'test';
        xeroCon.KTXero__Reference_Id__c = '123456';
        insert xeroCon;
        
        XeroWebHookService.createContact(xeroCon.KTXero__Reference_Id__c, dWrap);
        System.assertEquals('Test Account',acc.Name, 'Success');
    }

    @isTest
    public static void testGenerateDate(){
        // Create a test Xero connection record with a dummy webhook key
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);
        System.assertEquals('testkey',Utils.processDecryption(xeroConnect.KTXero__Webhook_Key__c),'Success');
        XeroWebHookService.generatedate('1691712000000');
    }

   
    // A test method to test the createPayment() method
    @isTest
    public static void testCreatePayment() {
        // Create some mock data
        
        XeroWebHookService.Payments_B payObj = new XeroWebHookService.Payments_B();
        payObj.Account_B = new XeroWebHookService.Account_B();
        payObj.Amount_B = 200;
        payObj.BankAmount_B = 50;
        payObj.CurrencyRate_B = 200;
        payObj.Date_B = 'test';
        payObj.HasAccount_B = true;
        payObj.HasValidationErrors_B = true;
        payObj.PaymentID_B = 'test';
        payObj.IsReconciled_B = true;
        payObj.Status_B = 'test';
        payObj.UpdatedDateUTC_B = 'test';
      
        XeroWebHookService.Payments_x payX = new XeroWebHookService.Payments_x();
        payX.Amount_x = 205;
        payX.CurrencyRate_x = 205;
        payX.BatchPaymentID_x = 'test';
        payX.Date_x = 'test';
        payX.PaymentID_x = 'test';
        payX.HasAccount_x = true;
        payX.HasValidationErrors_x = true;

        XeroWebHookService.Contact_x conObj = new XeroWebHookService.Contact_x();
        conObj.HasValidationErrors_x = true;
        conObj.IsCustomer_x = true;
        conObj.IsSupplier_x = true;
        conObj.BankAccountDetails_x = 'test';
        conObj.UpdatedDateUTC_x = 'test';
        conObj.UpdatedDateUTC_x = 'test';
        conObj.UpdatedDateUTC_x = 'test';


        XeroWebHookService.Invoices_x invObj = new XeroWebHookService.Invoices_x();
        invObj.Date_x = 'Test';
        invObj.DueDate_x = 'Test';
        invObj.UpdatedDateUTC_x = 'Test';
        invObj.HasAttachments_x = true;
        invObj.HasErrors_x = true;
        invObj.IsDiscounted_x = true;
        invObj.TotalDiscount_x = 20;

        XeroWebHookService.Invoice_B invObj1 = new XeroWebHookService.Invoice_B();
        invObj1.AmountDue_B = 20;
        invObj1.AmountPaid_B = 20;
        invObj1.SubTotal_B = 20;
        invObj1.Total_B = 20;
        invObj1.TotalTax_B = 20;
        invObj1.CurrencyRate_B = 20;
        invObj1.CurrencyCode_B = 'test';
        invObj1.Date_B = 'test';
        invObj1.DateString_B = 'test';
        invObj1.DueDate_B = 'test';
        invObj1.DueDateString_B = 'test';
        invObj1.InvoiceID_B = 'test';
        invObj1.InvoiceNumber_B = 'test';
        invObj1.LineAmountTypes_B = 'test';
        invObj1.Reference_B = 'test';
        invObj1.Status_B = 'test';
        invObj1.Type_B = 'test';
        invObj1.UpdatedDateUTC_B = 'test';
        invObj1.IsDiscounted_B = true;
        invObj1.HasErrors_B = true;
        invObj1.SentToContact_B = true;

        System.assertEquals(true,invObj1.SentToContact_B ,'Success');
    }

    @isTest
    public static void testcreateBillPayment(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseBillPayment());

        // KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(false);
        Map<String, String> headerMap = new Map<String, String>();
        headerMap.put('xero-tenant-id','7ba1138a-ae87-411a-ae0a-ed5768f597d4');
        headerMap.put('authorization','eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RT00Y2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTE1NzQ2MDAsImV4cCI6MTY5MTU3NjQwMCwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTQ4MjAwOSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6Ijg3Zjc5ZDE1ZThmYTQxZDg4OWU2MTc4MzBkNjY0YWUzIiwic2lkIjoiODdmNzlkMTVlOGZhNDFkODg5ZTYxNzgzMGQ2NjRhZTMiLCJqdGkiOiIzQkQ2M0E1MkE2RjRDRTQzNTdDRDM4NUQ2MkFDNjg4RiIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiODY3ZWQ0MDctZjg2MC00YTQ3LTkzY2UtNzY1ZDQ2ZjQ0YTVhIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.r9TWEy7q4n3rEKmgM_PTj1k2U-BSJNrZvSY3biHXPaQnn_R26TLhuV9qus0RIpDfs7XZ9P0bIadRkodXe_loYqOLRkRYo8bmquyq-IrPfx8cPx18qDxfpMK8nqr_n3CHF-JZpUw_4zV_JpiMUZ0zvEbTyMFjVT7W7AmAeeppL2QoC64EbSr_9E42bKoAn14q7KaLeWi6dQLSQJ6UowXgfiKoga9qrJ1CqznK-NMy7mkzwwT4nQDjieebBTo0KgKX7nCjX_cQKmUxOMzxkanZzprlGYkckIvyN88kkia_Vg-1T7jTAvIdPpb7qtF1DkhWxs4HiHI0Pk5zG65fGeqARA');
        XeroWebHookService.PaymentDetailWrapper paymentDetailWrap = XeroWebHookService.getPaymentDetails('1b936bbe-3d82-44de-8291-c8f0aec025b1',headerMap);

        Test.startTest();
        KTXero__Xero_Bill_Payment__c newPay = XeroWebHookService.createBillPayment(paymentDetailWrap.paymentWrap,1,new Set<String>{'USD'});
        KTXero__Payment__c newPay1 = XeroWebHookService.createPayment(paymentDetailWrap.paymentWrap,1,new Set<String>{'USD'});
        System.assertNotEquals(null, newPay, 'Result is not null');
        Test.stopTest();
    }

    private class MockHttpResponseBillPayment implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{ \"Id\": \"6af88604-b0b9-4fe8-838b-32d2f61894ca\", \"Status\": \"OK\", \"ProviderName\": \"Salesforce Application\", \"DateTimeUTC\": \"/Date(1722936241075)/\", \"Payments\": [ { \"PaymentID\": \"1b936bbe-3d82-44de-8291-c8f0aec025b1\", \"Date\": \"/Date(1724112000000+0000)/\", \"BankAmount\": 10.00, \"Amount\": 10.00, \"Reference\": \"Refrence\", \"CurrencyRate\": 1.0000000000, \"PaymentType\": \"ACCPAYPAYMENT\", \"Status\": \"AUTHORISED\", \"UpdatedDateUTC\": \"/Date(1722936234263+0000)/\", \"HasAccount\": true, \"IsReconciled\": false, \"Account\": { \"AccountID\": \"72f1dcfe-5d7d-4239-bf9d-e12469309716\", \"Code\": \"091\", \"Name\": \"Business Savings Account\" }, \"Invoice\": { \"Type\": \"ACCPAY\", \"InvoiceID\": \"ea3290c4-d8ef-4029-b41f-aecfcee8e4a3\", \"InvoiceNumber\": \"Zain Bakery\", \"Reference\": \"\", \"Payments\": [ { \"PaymentID\": \"1b936bbe-3d82-44de-8291-c8f0aec025b1\", \"Date\": \"/Date(1724112000000+0000)/\", \"Amount\": 10.00, \"Reference\": \"Refrence\", \"CurrencyRate\": 1.0000000000, \"HasAccount\": false, \"HasValidationErrors\": false } ], \"Prepayments\": [], \"Overpayments\": [], \"AmountDue\": 9990.00, \"AmountPaid\": 10.00, \"SentToContact\": false, \"CurrencyRate\": 1.0000000000, \"IsDiscounted\": false, \"HasErrors\": false, \"InvoicePaymentServices\": [], \"Contact\": { \"ContactID\": \"c9065ec7-a55d-472d-84db-7082ae1ede77\", \"Name\": \"Zain Bakery\", \"ContactPersons\": [], \"HasValidationErrors\": false }, \"DateString\": \"2024-08-05T00:00:00\", \"Date\": \"/Date(1722816000000+0000)/\", \"DueDateString\": \"2024-08-27T00:00:00\", \"DueDate\": \"/Date(1724716800000+0000)/\", \"Status\": \"AUTHORISED\", \"LineAmountTypes\": \"Inclusive\", \"LineItems\": [ { \"Description\": \"Bakery\", \"UnitAmount\": 1000.00, \"TaxType\": \"INPUT\", \"TaxAmount\": 762.12, \"LineAmount\": 10000.00, \"AccountCode\": \"429\", \"Tracking\": [ { \"Name\": \"Region\", \"Option\": \"North\", \"TrackingCategoryID\": \"fa437cfd-f005-4538-ae84-943857da5c8c\", \"TrackingOptionID\": \"5e2974a2-097d-4f3b-bfd5-605d78c4a282\" } ], \"Quantity\": 10.0000, \"LineItemID\": \"a994c3a1-7215-4275-b346-d5d6948a7944\", \"AccountID\": \"4281c446-efb4-445d-b32d-c441a4ef5678\", \"DiscountEnteredAsPercent\": true, \"ValidationErrors\": [] } ], \"SubTotal\": 9237.88, \"TotalTax\": 762.12, \"Total\": 10000.00, \"UpdatedDateUTC\": \"/Date(1722936234263+0000)/\", \"CurrencyCode\": \"USD\" }, \"HasValidationErrors\": false } ] }');
            response.setStatusCode(200);
            return response;
        } 
    }
}