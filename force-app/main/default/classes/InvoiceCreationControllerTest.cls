@isTest
public with sharing class InvoiceCreationControllerTest {
    
    // Create common test data for all test methods
    @testSetup
    static void setup() {

        // Create a test Xero connection record with a dummy webhook key
        // KTXero__Xero_Connection__c xeroConnect = new KTXero__Xero_Connection__c();
        // xeroConnect.KTXero__Webhook_Key__c = 'testkey';
        // xeroConnect.KTXero__Access_Token__c = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RT00Y2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTE1NzQ2MDAsImV4cCI6MTY5MTU3NjQwMCwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTQ4MjAwOSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6Ijg3Zjc5ZDE1ZThmYTQxZDg4OWU2MTc4MzBkNjY0YWUzIiwic2lkIjoiODdmNzlkMTVlOGZhNDFkODg5ZTYxNzgzMGQ2NjRhZTMiLCJqdGkiOiIzQkQ2M0E1MkE2RjRDRTQzNTdDRDM4NUQ2MkFDNjg4RiIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiODY3ZWQ0MDctZjg2MC00YTQ3LTkzY2UtNzY1ZDQ2ZjQ0YTVhIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.r9TWEy7q4n3rEKmgM_PTj1k2U-BSJNrZvSY3biHXPaQnn_R26TLhuV9qus0RIpDfs7XZ9P0bIadRkodXe_loYqOLRkRYo8bmquyq-IrPfx8cPx18qDxfpMK8nqr_n3CHF-JZpUw_4zV_JpiMUZ0zvEbTyMFjVT7W7AmAeeppL2QoC64EbSr_9E42bKoAn14q7KaLeWi6dQLSQJ6UowXgfiKoga9qrJ1CqznK-NMy7mkzwwT4nQDjieebBTo0KgKX7nCjX_cQKmUxOMzxkanZzprlGYkckIvyN88kkia_Vg-1T7jTAvIdPpb7qtF1DkhWxs4HiHI0Pk5zG65fGeqARA';
        // xeroConnect.KTXero__Refresh_Token__c = 'iMrWhs51ztFLOM9sxr6Ge5juXHXU3mszSbQo-b3d0_I';
        // xeroConnect.KTXero__Tenant_Id__c = '7ba1138a-ae87-411a-ae0a-ed5768f597d4';
        // insert xeroConnect;
        TestUtil.createXeroConnection(true);


        // Create an account
        Account acc = new Account(
            Name = 'Test Account',
            AccountNumber = '123456',
            Phone = '123-456-7890',
            BillingStreet = '123 Test Street',
            BillingCity = 'Test City',
            BillingState = 'Test State',
            BillingPostalCode = '12345',
            BillingCountry = 'Test Country',
            ShippingStreet = '456 Test Street',
            ShippingCity = 'Test City 2',
            ShippingState = 'Test State 2',
            ShippingPostalCode = '23456',
            ShippingCountry = 'Test Country 2'
        );
        insert acc;

        
        Contact con = new Contact();
        con.firstName = 'test';
        con.lastname = 'test';
        con.AccountId = acc.Id;
        insert con;



        
        KTXero__Xero_Contact__c con1 = new KTXero__Xero_Contact__c();
        con1.KTXero__first_Name__c = 'test';
        con1.KTXero__last_name__c = 'test';
        insert con1;


        opportunity oppr = new opportunity(Name='testing NONDIE 4/6/2015' ,  AccountId= acc.Id, StageName = 'Prospecting', CloseDate = date.today());
        insert oppr;

        Pricebook2 pb22 = new Pricebook2(Name='testNonDIE');
        insert pb22;


        List<Product2> prods = new List<Product2>();
        prods.add(new Product2( Name = 'Test Product', ProductCode = 'TEST001', KTXero__Xero_ItemID__c = '3644c19f-7c46-4e18-93fa-5550c307bcdd' ,IsActive = true));
        prods.add(new Product2(Name = 'Laptop', ProductCode = 'LAP-001',KTXero__Xero_ItemID__c = 'XID' + 2, IsActive = true));
        prods.add(new Product2(Name = 'Mouse', ProductCode = 'MOU-002', KTXero__Xero_ItemID__c = 'XID' + 3, IsActive = true));
        prods.add(new Product2(Name = 'Keyboard', ProductCode = 'KEY-003',KTXero__Xero_ItemID__c = 'XID' + 4, IsActive = false));
        prods.add(new Product2(Name = 'Monitor', ProductCode = 'MON-004',KTXero__Xero_ItemID__c = 'XID' + 5, IsActive = true));
        insert prods;
        // insert testProduct;

        PricebookEntry pbe2 =new PricebookEntry(unitprice=1,Product2Id=prods[0].Id,Pricebook2Id=Test.getStandardPricebookId(),
                                                isActive=true,UseStandardPrice = false);
        insert pbe2;

        List<OpportunityLineItem> testLineItems = new List<OpportunityLineItem>();
        
        for (Integer i = 0; i < 5; i++) {
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = oppr.Id,
                Product2Id = prods[i].Id,
                Quantity = i + 1,
                UnitPrice = 10 * (i + 1),
                Description = 'This is a test line item',
                PriceBookEntryId=pbe2.Id
            );
            testLineItems.add(oli);
        }
        insert testLineItems;
        
        // Create some invoices
        List<Invoice__c> invs = new List<Invoice__c>();
        invs.add(new Invoice__c(Opportunity__c = oppr.Id, Name = 'Invoice 1'));
        invs.add(new Invoice__c(Opportunity__c = oppr.Id, Name = 'Invoice 2'));
        insert invs;
    }
    
    @isTest static void testMethodForDeleteInvoice(){

        Test.setMock(HttpCalloutMock.class, new MockHttpGeneratorDeleteInvoice());

        Test.startTest();
        List<KTXero__Invoice__c> invSales = [SELECT Id, name FROM KTXero__Invoice__c LIMIT 1];
        String invoiceId = '6a298ba4-6d72-4f58-9b3f-f92e63521285';
        String recordId = invSales[0].Id;
        Boolean isSuccess = InvoiceCreationController.deleteInvoice(invoiceId, 'VOIDED', recordId);
        System.assertEquals(isSuccess, true, 'Result should be true');

        Test.stopTest();

    }

    @isTest static void testMethodgetAccountName(){

        Account acc = new Account();
        acc.Name = 'New Test Account';
        insert acc;

        Test.startTest();
        String accName = InvoiceCreationController.getAccountName(acc.Id);
        System.assertEquals(accName, 'New Test Account', 'Account Name matched');

        Test.stopTest();

    }

    // @isTest static void testMethodgetOppCurrency(){

    //     Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    //     opp.CurrencyISOCode = 'USD';
    //     update opp;
        
    //     Test.startTest();
    //     String oppCurrency = InvoiceCreationController.getOppCurrency(opp.Id);
    //     InvoiceCreationWrapper.AccWrapper accWrap = InvoiceCreationController.getAccountWrapper();
    //     Test.stopTest();
        
    //     System.assertEquals(oppCurrency, 'USD', 'Currency matched');
    // }


    private class MockHttpGeneratorDeleteInvoice implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
          
            // response.setBody('{\"Id\":\"d7335f67-3ced-4b5c-97a2-b89db9bf7cce\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"\\/Date(1685512514564)\\/\",\"Contacts\":[{\"ContactID\":\"36cc258f-3bc2-4447-9c8e-4c1529470c5f\",\"ContactStatus\":\"ACTIVE\",\"Name\":\"BurlingtonTextilesCorpofAmerica\",\"FirstName\":\"Andy\",\"LastName\":\"Young\",\"EmailAddress\":\"a_young@dickenson.com\",\"BankAccountDetails\":\"\",\"Addresses\":[{\"AddressType\":\"DELIVERY\",\"City\":\"\",\"Region\":\"\",\"PostalCode\":\"\",\"Country\":\"\"},{\"AddressType\":\"POBOX\",\"AddressLine1\":\"525S.LexingtonAve\",\"City\":\"Burlington\",\"Region\":\"NC\",\"PostalCode\":\"27215\",\"Country\":\"USA\"}],\"Phones\":[{\"PhoneType\":\"DEFAULT\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"DDI\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"FAX\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"MOBILE\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"}],\"UpdatedDateUTC\":\"\\/Date(1685512473177+0000)\\/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":false,\"SalesTrackingCategories\":[],\"PurchasesTrackingCategories\":[],\"ContactPersons\":[{\"FirstName\":\"John\",\"LastName\":\"Doe\",\"EmailAddress\":\"john.doe@example.com\",\"IncludeInEmails\":true},{\"FirstName\":\"Jane\",\"LastName\":\"Smith\",\"EmailAddress\":\"jane.smith@example.com\",\"IncludeInEmails\":false},{\"FirstName\":\"Michael\",\"LastName\":\"Johnson\",\"EmailAddress\":\"michael.johnson@example.com\",\"IncludeInEmails\":true},{\"FirstName\":\"Sarah\",\"LastName\":\"Williams\",\"EmailAddress\":\"sarah.williams@example.com\",\"IncludeInEmails\":true},{\"FirstName\":\"David\",\"LastName\":\"Brown\",\"EmailAddress\":\"david.brown@example.com\",\"IncludeInEmails\":false}],\"HasValidationErrors\":false}]}');
            response.setBody('{\"Id\":\"77e7cca1-e9d4-4679-b74a-037265cf906c\",\"Status\":\"OK\",\"ProviderName\":\"Salesforce Application\",\"DateTimeUTC\":\"\\/Date(1698775918471)\\/\",\"Invoices\":[{\"Type\":\"ACCREC\",\"InvoiceID\":\"6a298ba4-6d72-4f58-9b3f-f92e63521285\",\"InvoiceNumber\":\"INV-0040\",\"Reference\":\"\",\"Prepayments\":[],\"Overpayments\":[],\"AmountDue\":4500,\"AmountPaid\":0,\"SentToContact\":false,\"CurrencyRate\":1,\"IsDiscounted\":false,\"HasErrors\":false,\"InvoicePaymentServices\":[],\"Contact\":{\"ContactID\":\"a8654e7b-89a3-4ed4-802e-b1f79721a4d8\",\"AccountNumber\":\"CD656092ccccccccv \",\"ContactStatus\":\"ACTIVE\",\"Name\":\"Burlington Textiles Corp of America cvxvc\",\"FirstName\":\"t\",\"LastName\":\"t\",\"EmailAddress\":\"test12345@gmail.com\",\"BankAccountDetails\":\"\",\"Addresses\":[{\"AddressType\":\"STREET\",\"City\":\"\",\"Region\":\"\",\"PostalCode\":\"\",\"Country\":\"\"},{\"AddressType\":\"POBOX\",\"AddressLine1\":\"Config Acc Name\",\"City\":\"Burlington\",\"Region\":\"\",\"PostalCode\":\"27215\",\"Country\":\"USA\"}],\"Phones\":[{\"PhoneType\":\"DEFAULT\",\"PhoneNumber\":\"(336) 222-7000\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"DDI\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"FAX\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"MOBILE\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"}],\"UpdatedDateUTC\":\"\\/Date(1698648586653+0000)\\/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":true,\"SalesTrackingCategories\":[],\"PurchasesTrackingCategories\":[],\"ContactPersons\":[{\"FirstName\":\"Andy\",\"LastName\":\"Young\",\"EmailAddress\":\"a_young@dickenson.com\",\"IncludeInEmails\":false}],\"HasValidationErrors\":false},\"DateString\":\"2023-11-22T00:00:00\",\"Date\":\"\\/Date(1700611200000+0000)\\/\",\"DueDateString\":\"2023-11-02T00:00:00\",\"DueDate\":\"\\/Date(1698883200000+0000)\\/\",\"BrandingThemeID\":\"d613f7f9-8fcb-477f-97f0-31eb85b7e5cf\",\"Status\":\"VOIDED\",\"LineAmountTypes\":\"Inclusive\",\"LineItems\":[{\"ItemCode\":\"DevH\",\"Description\":\"Development work - per hour rate\",\"UnitAmount\":90,\"TaxType\":\"OUTPUT\",\"TaxAmount\":342.96,\"LineAmount\":4500,\"AccountCode\":\"200\",\"Item\":{\"ItemID\":\"b36131d5-f37e-4cb1-bb9c-320446c7b004\",\"Name\":\"Development work - per hour rate\",\"Code\":\"DevH\"},\"Tracking\":[],\"Quantity\":50,\"LineItemID\":\"00f528a2-d1cc-4bd0-89c4-c32c941af020\",\"AccountID\":\"d1ebb97b-d207-4ccb-9ab6-8a466a8b4d39\",\"DiscountEnteredAsPercent\":true,\"ValidationErrors\":[]}],\"SubTotal\":4157.04,\"TotalTax\":342.96,\"Total\":4500,\"UpdatedDateUTC\":\"\\/Date(1698775918393+0000)\\/\",\"CurrencyCode\":\"USD\"}]}');
          
            response.setStatusCode(200);
            return response;
        } 
    }

    @isTest
    static void testCheckAccountName() {
        // Use the Test.startTest and Test.stopTest methods
        Test.startTest();

        KTXero__Xero_Contact__c con = new KTXero__Xero_Contact__c();
        con.KTXero__Account_Number__c = '123456';
        con.KTXero__Company_Name__c = 'abc';
        insert con;

        String companyName = 'abc';
        String accNumber = '123456';
        List<Account> acc1 = [SELECT Id,Name, AccountNumber FROM Account];
        InvoiceCreationWrapper.CheckAccDetailWrapper result = InvoiceCreationController.checkAccountName(companyName, accNumber);
        System.assertNotEquals(null, result, 'Success');
        
        Test.stopTest();
    }

    // Test the getProducts method
    @isTest
    static void testGetProducts() {

  
        // Get the test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Define the setup fields
        List<String> setupFields = new List<String>();
        InvoiceCreationWrapper.OppWrapper result; 
        // Start the test
        Test.startTest();
            KTXero__Xero_Connection__c xeroConnectionObj = [SELECT Id, Name, KTXero__Webhook_Key__c FROM KTXero__Xero_Connection__c ORDER BY CreatedDate DESC LIMIT 1];
            System.assertEquals(Utils.processDecryption(xeroConnectionObj.KTXero__Webhook_Key__c), 'testkey', 'Webhook key should be testkey');
            // Call the getProducts method
            result = InvoiceCreationController.getProducts(opp.Id, setupFields);
        
        // Stop the test
        Test.stopTest();
        List<String> setupFields1 = new List<String>{'Name', 'AccountId'};
        result = InvoiceCreationController.getProducts(opp.Id, setupFields1);
    }

     // Test the getProductList method
     @isTest
     static void testGetProductList() {

        // Define some input values
        String inputVal1 = 'LAP';
        String inputVal2 = 'MOU';
        String inputVal3 = 'KEY';
        String inputVal4 = 'MON';
        String inputVal5 = 'LAP:Mouse';

        // Start the test
        Test.startTest();

        // Call the getProductList method with different input values
        List<InvoiceCreationWrapper.ProductSearchWrapper> result1 = InvoiceCreationController.getProductList(inputVal1);
        List<InvoiceCreationWrapper.ProductSearchWrapper> result2 = InvoiceCreationController.getProductList(inputVal2);
        List<InvoiceCreationWrapper.ProductSearchWrapper> result3 = InvoiceCreationController.getProductList(inputVal3);
        List<InvoiceCreationWrapper.ProductSearchWrapper> result4 = InvoiceCreationController.getProductList(inputVal4);
        List<InvoiceCreationWrapper.ProductSearchWrapper> result5 = InvoiceCreationController.getProductList(inputVal5);
    
        System.assertNotEquals(null, result1, 'Valid Result');
        System.assertNotEquals(null, result2, 'Valid Result');
        System.assertNotEquals(null, result3, 'Valid Result');
        System.assertNotEquals(null, result4, 'Valid Result');
        System.assertNotEquals(null, result5, 'Valid Result');

        // Stop the test
        Test.stopTest();
    }

    // A test method to verify the functionality of the method
    @isTest static void testGetXeroContacts() {
        // Create a test account and insert it into the database
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create some test Xero contacts and associate them with the test account
        List<Xero_Contact__c> testXeroContacts = new List<Xero_Contact__c>();
            for (Integer i = 0; i < 5; i++) {
            Xero_Contact__c xc = new Xero_Contact__c(
            // Name = 'Test Contact ' + i,
            First_Name__c = 'First ' + i,
            Last_Name__c = 'Test Contact ' + i,
            Email_Address__c = 'test' + i + '@example.com',
            Company_Name__c = 'Test Company ' + i,
            Reference_Id__c = 'REF' + i,
            Street_Address__c = 'Street ' + i,
            Town_City__c = 'Town ' + i,
            State_Region__c = 'State ' + i,
            Postal_Zip_Code__c = 'Zip ' + i,
            Country__c = 'Country ' + i,
            Salesforce_Account__c = testAccount.Id
            );
            testXeroContacts.add(xc);
        }
        insert testXeroContacts;

        // Set up the test context and invoke the method
        Test.startTest();
        InvoiceCreationWrapper.XeroContactWrapper result = InvoiceCreationController.getXeroContacts(null, testAccount.Id);
        Test.stopTest();

        // Assert that the result is not null and has the same size as the test data
        System.assertNotEquals(null, result, 'The result should not be null');
    }

    // A test method to verify the functionality of the method
    @isTest static void testGetAccountDetails() {
        // Create a test Xero contact configuration and insert it into the database
        KTXero__Xero_Contact_Configurations__c xconfig = new KTXero__Xero_Contact_Configurations__c(
            Name = 'Test Config',
            Xero_Contact_Account_Name__c = 'Name',
            Xero_Contact_Account_Number__c = 'AccountNumber',
            Xero_Contact_Account_Phone__c = 'Phone',
            Xero_Contact_City__c = 'BillingCity',
            Xero_Contact_Country__c = 'BillingCountry',
            Xero_Contact_Email__c = 'Email',
            Xero_Contact_First_Name__c = 'FirstName',
            Xero_Contact_Last_Name__c = 'LastName',
            Xero_Contact_State__c = 'BillingState',
            Xero_Contact_Street_Address__c = 'BillingStreet',
            Xero_Contact_ZipCode__c = 'BillingPostalCode'
        );
        insert xconfig;

        // Create a test account and some test contacts and insert them into the database
        Account testAccount = [SELECT Id,Name,AccountNumber,Phone,BillingStreet,BillingCity,
                                BillingState, BillingPostalCode, BillingCountry, ShippingStreet,
                                ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry   FROM Account ORDER BY CreatedDate DESC LIMIT 1];
        

        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            Contact con = new Contact(
            FirstName = 'Test First ' + i,
            LastName = 'Test Last ' + i,
            Email = 'test' + i + '@example.com',
            AccountId = testAccount.Id
            );
            testContacts.add(con);
        }
        insert testContacts;

        // Set up the test context and invoke the method
        Test.startTest();
        InvoiceCreationWrapper.AccWrapper result = InvoiceCreationController.getAccountDetails(testAccount.Id);
        Test.stopTest();

        // Assert that the result is not null and has the correct values from the test data
        System.assertNotEquals(null, result, 'The result should not be null');
        System.assertEquals(testAccount.Id, result.accId, 'The account id should match');
        System.assertEquals(testAccount.Name, result.accName, 'The account name should match');
        System.assertEquals(testAccount.AccountNumber, result.accNumber, 'The account number should match');
        System.assertEquals(testAccount.Phone, result.accPhone, 'The account phone should match');
        System.assertEquals(testAccount.BillingStreet, result.accStreet, 'The account street should match');
        System.assertEquals(testAccount.BillingCity, result.accCity, 'The account city should match');
        System.assertEquals(testAccount.BillingState, result.accState, 'The account state should match');
        System.assertEquals(testAccount.BillingPostalCode, result.accPostalCode, 'The account postal code should match');
        System.assertEquals(testAccount.BillingCountry, result.accCountry, 'The account country should match');
        // Assert that the result has the same size as the test contacts
        System.assertNotEquals(null, result.conList, 'The contact list should not be null');


        
        xconfig.Xero_Contact_Account_Name__c = '';
        xconfig.Xero_Contact_Account_Number__c = '';
        xconfig.Xero_Contact_Account_Phone__c = '';
        xconfig.Xero_Contact_City__c = '';
        xconfig.Xero_Contact_Country__c = '';
        xconfig.Xero_Contact_Email__c = '';
        xconfig.Xero_Contact_First_Name__c = '';
        xconfig.Xero_Contact_Last_Name__c = '';
        xconfig.Xero_Contact_State__c = '';
        xconfig.Xero_Contact_Street_Address__c = '';
        xconfig.Xero_Contact_ZipCode__c = '';
        update xconfig;
        InvoiceCreationWrapper.AccWrapper result1 = InvoiceCreationController.getAccountDetails(testAccount.Id);
        
        System.assertNotEquals(null, result1, 'The contact list should not be null');

    }

    // A test method to verify the functionality of the method
    @isTest static void testGetOpportunityProducts() {
        // Create a test opportunity and insert it into the database
        Opportunity testOpp = [SELECT Id,Name FROM Opportunity ORDER BY CreatedDate DESC LIMIT 1];


        // Create some test products and insert them into the database
        List<Product2> testProducts = new List<Product2>();
        testProducts = [SELECT Id,Name FROM Product2 ORDER BY CreatedDate DESC];

        // Create some test opportunity line items and associate them with the test opportunity and products
        List<OpportunityLineItem> testLineItems = new List<OpportunityLineItem>();
        testLineItems = [SELECT Id, Name, OpportunityId, Product2Id, Quantity, UnitPrice, Description FROM OpportunityLineItem];
     
        // Set up the test context and invoke the method
        Test.startTest();
        List<InvoiceCreationWrapper.OppproductWrapper> result = InvoiceCreationController.getOpportunityProducts(testOpp.Id);
        Test.stopTest();

        // Assert that the result is not null and has the same size as the test data
        System.assertNotEquals(null, result, 'The result should not be null');
        System.assertEquals(testLineItems.size(), result.size(), 'The result should have the same size as the test data');

        // Assert that each element in the result has the correct values from the corresponding test data
        for (Integer i = 0; i < result.size(); i++) {
            InvoiceCreationWrapper.OppproductWrapper opro = result[i];
            OpportunityLineItem oli = testLineItems[i];
            System.assertEquals(oli.Id, opro.id, 'The id should match');
        }
    }


    // A test method to verify the functionality of the method
    @isTest static void testGetCurrency() {
        // Create some test currency types and insert them into the database
        // List<CurrencyType> testCurrencies = new List<CurrencyType>();
        // testCurrencies = [SELECT Id,IsoCode, ConversionRate, DecimalPlaces, IsActive, IsCorporate FROM CurrencyType ORDER BY CreatedDate DESC];
      
        // Set up the test context and invoke the method
        Test.startTest();
        List<String> result = InvoiceCreationController.getCurrency();
        Test.stopTest();
        
        // Assert that the result is not null and has the same size as the test data
        System.assertNotEquals(null, result, 'The result should not be null');
        
        // // Assert that each element in the result has the correct value from the corresponding test data
        // for (Integer i = 0; i < result.size(); i++) {
        //     String isoCode = result[i];
        //     CurrencyType ct = testCurrencies[i];
        //     System.assertEquals(ct.IsoCode, isoCode, 'The iso code should match');
        // }
    }

    // A test method to verify the functionality of the method
    @isTest static void testGetinvoiceOppMapping() {
        // Create a test invoice configuration and insert it into the database
        KTXero__Invoice_Configuration_Options__c invConfig = new KTXero__Invoice_Configuration_Options__c(
            Invoice_Date__c = '2;Before;CloseDate',
            Invoice_Due_Date__c = '1;After;CloseDate',
            Invoice_Reference__c = 'Name'
        );
        insert invConfig;
        
        // Create a test opportunity and insert it into the database
        Opportunity testOpp = new Opportunity();
        testOpp = [SELECT Id,Name, stagename, CloseDate FROM Opportunity ORDER BY CreatedDate DESC LIMIT 1];
      
        // Set up the test context and invoke the method
        Test.startTest();
        InvoiceCreationWrapper.InvoiceOppMappingWrapper result = InvoiceCreationController.getinvoiceOppMapping(testOpp.Id);
        
        // Assert that the result is not null and has the correct values from the test data
        System.assertNotEquals(null, result, 'The result should not be null');
        System.assertEquals(Date.today().addDays(-2), result.invDate, 'The invoice date should be one day after the close date');
        System.assertEquals(Date.today().addDays(1), result.dueDate, 'The due date should be one day before the close date');
        
        invConfig.Invoice_Date__c = '1;After;CloseDate';
        update invConfig;
        InvoiceCreationWrapper.InvoiceOppMappingWrapper result1 = InvoiceCreationController.getinvoiceOppMapping(testOpp.Id);
        System.assertNotEquals(null, result1, 'The contact list should not be null');

        Test.stopTest();
        
    }


    // A test method to verify the functionality of the method
    @isTest static void testCreateXeroContact() {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        // Serialize the wrapper objects into JSON strings
        String accdetails= '{"accCity":"t","accCountry":"t","accId":"001Dn00000XpjjRIAR","accName":"Test 19th July 23","accNumber":"t","accPhone":"t","accPostalCode":"t","accShippingCity":"t","accShippingCountry":"t","accShippingPostalCode":"t","accShippingState":"t","accShippingStreet":"t","accState":"t","accStreet":"t"}';
        String condetails= '{"conEmail":"test@test.com","conFirstName":"Test","conId":1.7715377650476256,"conLastName":"test","conName":"Test test"}';
        String conPersonDetails= '[{"conEmail":"testr@gmail.com","conFirstName":"Test","conId":"6.511361920755569qxs6p","conLastName":"Test 19tth","includeinEmail":false,"conoptionsValue":"003Dn00000TuYkcIAF","showfields":true,"conOptions":[{"label":"Enter details Manually","value":"None"},{"label":"Test 19tth","value":"003Dn00000TuYkcIAF"}]},{"conEmail":"Test@test1.com","conFirstName":"Test 8th Aug","conId":"9.8813196217671839dq8g","conLastName":"Test","includeinEmail":false,"conoptionsValue":"003Dn00000VS0YXIA1","showfields":true,"conOptions":[{"label":"Enter details Manually","value":"None"},{"label":"Test 8th Aug Test","value":"003Dn00000VS0YXIA1"}]},{"conEmail":"Test@test4.com","conFirstName":"Test 7th Aug","conId":"11.615134058279155ue2k","conLastName":"Test","includeinEmail":false,"conoptionsValue":"003Dn00000VS0YhIAL","showfields":true,"conOptions":[{"label":"Enter details Manually","value":"None"},{"label":"Test 7th Aug Test","value":"003Dn00000VS0YhIAL"}]},{"conEmail":"test@test2.com","conFirstName":"t","conId":"5.23162641444932kip9mi","conLastName":"t","includeinEmail":false,"conoptionsValue":"None","showfields":true,"conOptions":[{"label":"Enter details Manually","value":"None"}]},{"conEmail":"test@test3.com","conFirstName":"t1t","conId":"13.951269340650144b04z","conLastName":"t1","includeinEmail":false,"conoptionsValue":"None","showfields":true,"conOptions":[{"label":"Enter details Manually","value":"None"}]}]';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorContact());
        
        
        // Set up the test context and invoke the method
        Test.startTest();
        InvoiceCreationWrapper.XeroConWrapper result = InvoiceCreationController.createXeroContact(accdetails, condetails, conPersonDetails,opp.Id);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorContact1());
        InvoiceCreationWrapper.XeroConWrapper result1 = InvoiceCreationController.createXeroContact(accdetails, condetails, conPersonDetails,opp.Id);
        
        System.assertNotEquals(null, result, 'Valid Result');
        System.assertNotEquals(null, result1, 'Valid Result');

        // Test.stopTest();
        Test.stopTest();
    }


    
    private class MockHttpResponseGeneratorContact implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Id\":\"d7335f67-3ced-4b5c-97a2-b89db9bf7cce\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"\\/Date(1685512514564)\\/\",\"Contacts\":[{\"ContactID\":\"36cc258f-3bc2-4447-9c8e-4c1529470c5f\",\"ContactStatus\":\"ACTIVE\",\"Name\":\"BurlingtonTextilesCorpofAmerica\",\"FirstName\":\"Andy\",\"LastName\":\"Young\",\"EmailAddress\":\"a_young@dickenson.com\",\"BankAccountDetails\":\"\",\"Addresses\":[{\"AddressType\":\"DELIVERY\",\"City\":\"\",\"Region\":\"\",\"PostalCode\":\"\",\"Country\":\"\"},{\"AddressType\":\"POBOX\",\"AddressLine1\":\"525S.LexingtonAve\",\"City\":\"Burlington\",\"Region\":\"NC\",\"PostalCode\":\"27215\",\"Country\":\"USA\"}],\"Phones\":[{\"PhoneType\":\"DEFAULT\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"DDI\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"FAX\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"MOBILE\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"}],\"UpdatedDateUTC\":\"\\/Date(1685512473177+0000)\\/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":false,\"SalesTrackingCategories\":[],\"PurchasesTrackingCategories\":[],\"ContactPersons\":[{\"FirstName\":\"John\",\"LastName\":\"Doe\",\"EmailAddress\":\"john.doe@example.com\",\"IncludeInEmails\":true},{\"FirstName\":\"Jane\",\"LastName\":\"Smith\",\"EmailAddress\":\"jane.smith@example.com\",\"IncludeInEmails\":false},{\"FirstName\":\"Michael\",\"LastName\":\"Johnson\",\"EmailAddress\":\"michael.johnson@example.com\",\"IncludeInEmails\":true},{\"FirstName\":\"Sarah\",\"LastName\":\"Williams\",\"EmailAddress\":\"sarah.williams@example.com\",\"IncludeInEmails\":true},{\"FirstName\":\"David\",\"LastName\":\"Brown\",\"EmailAddress\":\"david.brown@example.com\",\"IncludeInEmails\":false}],\"HasValidationErrors\":false}]}');
            response.setStatusCode(200);
            return response;
        } 
    }


    private class MockHttpResponseGeneratorContact1 implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');

            List<InvoiceCreationWrapper.ValidationErrors> validateList = new List<InvoiceCreationWrapper.ValidationErrors>();
            InvoiceCreationWrapper.ValidationErrors validate = new InvoiceCreationWrapper.ValidationErrors(); 
            validate.Message = 'Test';
            validateList.add(validate);

            List<InvoiceCreationWrapper.Elements> eleList = new List<InvoiceCreationWrapper.Elements>();
            InvoiceCreationWrapper.Elements ele = new InvoiceCreationWrapper.Elements();
            ele.ValidationErrors = validateList;
            eleList.add(ele);

            InvoiceCreationWrapper.ErrorWrapper errorWrap = new InvoiceCreationWrapper.ErrorWrapper();
            errorWrap.ErrorNumber = 52;
            errorWrap.Type = 'test';
            errorWrap.Message = 'test';
            errorWrap.Elements = eleList;

            

            response.setBody(JSON.serialize(errorWrap));

            response.setStatusCode(400);
            return response;
        } 
    }


    // A test method to verify the functionality of the method
    @isTest static void createXeroInvoice() {
        
        
        // Serialize the wrapper objects into JSON strings
        String currencyCode = 'JPY';
        String invoiceData= '{"recordId":"006Dn00000BKCAeIAP","accountId":"001Dn00000XpjjRIAR","template":"f04ccf02-5a40-4ee2-a786-d6b97a34b8f4","invoicedate":"2023-08-03","invoiceduedate":"2023-08-06","reference":"Test 11th July","amountTax":"Exclusive","lineItems":[{"account":"200","amount":90,"description":"10","discount":10,"id":"13.06816955533964ktp4j","name":"","productCode":"DevH","productId":"01tDn000007QDvgIAG","productName":"Development work - per hour rate","quantity":10,"taxRate":"OUTPUT","taxCount":7.425,"unitPrice":10,"trackingData":[{"value":{"defaultVal":"e83ea9f2-de2c-44d8-b4f8-a5065bed339e","options":[{"label":"Eastside","value":"7b354c1c-cf59-42fc-9449-a65c51988335"},{"label":"North","value":"5e2974a2-097d-4f3b-bfd5-605d78c4a282"},{"label":"South","value":"e83ea9f2-de2c-44d8-b4f8-a5065bed339e"},{"label":"West Coast","value":"fc96efd9-b832-4b31-a93e-61f56158adad"}],"optname":"South"},"key":"Region"}],"xeroItemID":"b36131d5-f37e-4cb1-bb9c-320446c7b004","showDropdown":false,"inputValue":"DevH: Development work - per hour rate"}],"currencyCode":"JPY"}';
        String state= 'ApprovedEmail';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorGetInvoice());
        
        KTXero__Xero_Contact__c con = new KTXero__Xero_Contact__c();
        con = [SELECT Id, Name, KTXero__Reference_Id__c FROM KTXero__Xero_Contact__c ORDER BY CreatedDate DESC LIMIT 1];
        // Set up the test context and invoke the method
        Test.startTest();
        InvoiceCreationWrapper.XeroWrapper result = InvoiceCreationController.createXeroInvoice(con.KTXero__Reference_Id__c, currencyCode, invoiceData, state, con.Id);
        
        Test.stopTest();
        
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorGetInvoice1());
        
        System.assertNotEquals(null, result, 'Valid Result');

    }


    private class MockHttpResponseGeneratorGetInvoice implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setStatusCode(200);
			response.setBody('{\"Id\":\"c0250320-6e57-44ea-9e76-86d32b996619\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"\\/Date(1685519608614)\\/\",\"Invoices\":[{\"Type\":\"ACCREC\",\"InvoiceID\":\"9e462223-b329-4be5-bc75-9ba38ee98d7d\",\"InvoiceNumber\":\"INV-0037\",\"Reference\":\"001Dn00000FNi7jIAD\",\"Prepayments\":[],\"Overpayments\":[],\"AmountDue\":54125.00,\"AmountPaid\":0.00,\"SentToContact\":false,\"CurrencyRate\":1.0000000000,\"TotalDiscount\":0.00,\"IsDiscounted\":true,\"HasErrors\":false,\"InvoicePaymentServices\":[],\"Contact\":{\"ContactID\":\"bfa77af2-d5f8-4631-84f1-9dacb85e67cf\",\"ContactStatus\":\"ACTIVE\",\"Name\":\"GenePoint\",\"FirstName\":\"Fn1\",\"LastName\":\"Ln1\",\"EmailAddress\":\"fn@ln.com\",\"BankAccountDetails\":\"\",\"Addresses\":[{\"AddressType\":\"STREET\",\"City\":\"\",\"Region\":\"\",\"PostalCode\":\"\",\"Country\":\"\"},{\"AddressType\":\"POBOX\",\"AddressLine1\":\"345ShorelinePark\\nMountainView,CA94043\\nUSA\",\"City\":\"MountainView\",\"Region\":\"CA\",\"PostalCode\":\"test\",\"Country\":\"test\"}],\"Phones\":[{\"PhoneType\":\"DEFAULT\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"DDI\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"FAX\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"MOBILE\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"}],\"UpdatedDateUTC\":\"\\/Date(1685514008533+0000)\\/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":true,\"SalesTrackingCategories\":[],\"PurchasesTrackingCategories\":[],\"ContactPersons\":[{\"FirstName\":\"Fn2\",\"LastName\":\"Ln2\",\"EmailAddress\":\"fn2@ln.com\",\"IncludeInEmails\":true},{\"FirstName\":\"Fn5\",\"LastName\":\"Ln5\",\"EmailAddress\":\"fn5@ln.com\",\"IncludeInEmails\":true},{\"FirstName\":\"Fn3\",\"LastName\":\"Ln3\",\"EmailAddress\":\"fn3@ln.com\",\"IncludeInEmails\":true},{\"FirstName\":\"Fn4\",\"LastName\":\"Ln4\",\"EmailAddress\":\"fn4@ln.com\",\"IncludeInEmails\":true}],\"HasValidationErrors\":false},\"DateString\":\"2023-06-08T00:00:00\",\"Date\":\"\\/Date(1686182400000+0000)\\/\",\"DueDateString\":\"2023-06-11T00:00:00\",\"DueDate\":\"\\/Date(1686441600000+0000)\\/\",\"BrandingThemeID\":\"f04ccf02-5a40-4ee2-a786-d6b97a34b8f4\",\"Status\":\"DRAFT\",\"LineAmountTypes\":\"Exclusive\",\"LineItems\":[{\"ItemCode\":\"GB1-White\",\"Description\":\"test\",\"UnitAmount\":100.00,\"TaxType\":\"OUTPUT\",\"TaxAmount\":4125.00,\"LineAmount\":50000.00,\"AccountCode\":\"200\",\"Item\": {\"ItemID\": \"3644c19f-7c46-4e18-93fa-5550c307bcdd\",\"Name\": \"Golf balls - white single\",\"Code\": \"GB1-White\"},\"Tracking\":[{\"Name\": \"Region\",\"Option\": \"South\",\"TrackingCategoryID\": \"fa437cfd-f005-4538-ae84-943857da5c8c\",\"TrackingOptionID\": \"e83ea9f2-de2c-44d8-b4f8-a5065bed339e\"}],\"Quantity\":500.0000,\"DiscountRate\":0.00,\"LineItemID\":\"7f7d2bd9-de18-4d7c-91fd-267081589881\",\"DiscountAmount\":0.0000,\"ValidationErrors\":[]}],\"SubTotal\":50000.00,\"TotalTax\":4125.00,\"Total\":54125.00,\"UpdatedDateUTC\":\"\\/Date(1685519608563+0000)\\/\",\"CurrencyCode\":\"USD\"}]}');            
            return response;
        }
    }

    private class MockHttpResponseGeneratorGetInvoice1 implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Id\":\"4a0b3db9-dd9a-4a5d-941b-58c6215d1134\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"/Date(1684831274579)/\",\"Invoices\":[{\"Type\":\"ACCREC\",\"InvoiceID\":\"de2b30a2-afb2-4649-998f-4fd17554058a\",\"InvoiceNumber\":\"INV-0051\",\"Reference\":\"001Dn00000Qc9GaIAJ\",\"Prepayments\":[],\"Payments\":[{\"Date\":\"Date(1684420182133+0000)\",\"PaymentID\":\"xeroPaymentId\",\"Amount\":100,\"CurrencyRate\":1.0000000000,\"HasAccount\":true,\"HasValidationErrors\":false}],\"Overpayments\":[],\"AmountDue\":0.00,\"AmountPaid\":0.00,\"SentToContact\":false,\"CurrencyRate\":1.0000000000,\"TotalDiscount\":0.00,\"IsDiscounted\":true,\"HasAttachments\":false,\"HasErrors\":false,\"Attachments\":[],\"InvoicePaymentServices\":[],\"Contact\":{\"ContactID\":\"37d78e0c-cd12-4dba-b518-8043c8b28480\",\"ContactStatus\":\"ACTIVE\",\"Name\":\"TestAccountBK6\",\"FirstName\":\"Test\",\"LastName\":\"Contact\",\"EmailAddress\":\"bhagyashree.k@kandisatech.com\",\"BankAccountDetails\":\"\",\"Addresses\":[{\"AddressType\":\"STREET\",\"City\":\"\",\"Region\":\"\",\"PostalCode\":\"\",\"Country\":\"\"},{\"AddressType\":\"POBOX\",\"AddressLine1\":\"test123\",\"City\":\"mum\",\"Region\":\"mh\",\"PostalCode\":\"852963\",\"Country\":\"in\"}],\"Phones\":[{\"PhoneType\":\"DEFAULT\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"DDI\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"FAX\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"MOBILE\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"}],\"UpdatedDateUTC\":\"/Date(1684420181097+0000)/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":true,\"SalesTrackingCategories\":[],\"PurchasesTrackingCategories\":[],\"ContactPersons\":[],\"HasValidationErrors\":false},\"DateString\":\"2023-04-18T00:00:00\",\"Date\":\"/Date(1681776000000+0000)/\",\"DueDateString\":\"2023-04-21T00:00:00\",\"DueDate\":\"/Date(1682035200000+0000)/\",\"BrandingThemeID\":\"f04ccf02-5a40-4ee2-a786-d6b97a34b8f4\",\"Status\":\"DRAFT\",\"LineAmountTypes\":\"Exclusive\",\"LineItems\":[{\"ItemCode\":\"PMBr\",\"Description\":\"Project management & implementation - branding workshop with your team - follow up session\",\"UnitAmount\":200,\"TaxType\":\"OUTPUT\",\"TaxAmount\":16.5,\"LineAmount\":200,\"AccountCode\":\"200\",\"Item\":{\"ItemID\":\"ec4362af-a038-4984-ab93-1bba3b6bd402\",\"Name\":\"Project management & implementation - branding\",\"Code\":\"PMBr\"},\"Tracking\":[{\"Name\":\"TR001\",\"Option\":\"Option1\",\"TrackingCategoryID\":\"TCID-001\",\"TrackingOptionID\":\"TO001\"},{\"Name\":\"TR002\",\"Option\":\"Option2\",\"TrackingCategoryID\":\"TCID-002\",\"TrackingOptionID\":\"TO002\"}],\"Quantity\":15.0000,\"DiscountRate\":85.00,\"LineItemID\":\"a21423b7-c179-42f5-b2ec-17f9ce8f7804\",\"DiscountAmount\":0.0000,\"ValidationErrors\":[]},   {\"ItemCode\":\"TestCode\",\"Description\":\"Project management & implementation - branding workshop with your team - follow up session\",\"UnitAmount\":200,\"TaxType\":\"OUTPUT\",\"TaxAmount\":16.5,\"LineAmount\":200,\"AccountCode\":\"200\",\"Item\":{\"ItemID\":\"123456\",\"Name\":\"Project management & implementation - branding\",\"Code\":\"TestCode\"},\"Tracking\":[{\"Name\":\"TR001\",\"Option\":\"Option1\",\"TrackingCategoryID\":\"TCID-001\",\"TrackingOptionID\":\"TO001\"}],\"Quantity\":15.0000,\"DiscountRate\":90.00,\"LineItemID\":\"123456789\",\"DiscountAmount\":0.0000,\"ValidationErrors\":[]}   ],\"SubTotal\":0.00,\"TotalTax\":0.00,\"Total\":0.00,\"UpdatedDateUTC\":\"/Date(1684420182133+0000)/\",\"CurrencyCode\":\"USD\"}]}');
            response.setStatusCode(200);
            return response;
        } 
    }

    // A test method to test the getInvoiceConfiguration method
    @isTest
    static void testGetInvoiceConfiguration() {

        // Create a custom setting record for invoice configuration options
        KTXero__Invoice_Configuration_Options__c config = new KTXero__Invoice_Configuration_Options__c();
        config.Name = 'Test Config';
        config.SetupOwnerId = UserInfo.getOrganizationId();
        config.Default_Tax_rate__c = '10';
        config.Draft_Invoice__c = true;
        config.Submit_for_approval__c = true;
        config.Approved_invoice__c = true;
        config.Approved_and_Email__c = true;
        config.KTXero__Account_code_default__c = '101';
        config.Invoice_Date__c = 'Today';
        config.Invoice_Due_Date__c = '30 Days After Invoice Date';
        config.Invoice_Reference__c = 'Invoice-{!Invoice_Number__c}';
        config.Xero_Accounting_Tax_Type__c = 'OUTPUT2';
        config.Invoice_Template__c = 'Standard Template';
        insert config;

        // Start the test context
        Test.startTest();

        // Call the method to be tested
        InvoiceCreationWrapper.InvoiceConfigWrapper icw = InvoiceCreationController.getInvoiceConfiguration();

        // Stop the test context
        Test.stopTest();

        // Verify the results
        System.assertNotEquals(null, icw, 'The invoice configuration wrapper should not be null');
        
    }

    @isTest
    static void testgetXeroCons(){
        
        Account acc = TestUtil.createAccount(True);
        Account acc1 = TestUtil.createAccount(False);
        acc1.Name = 'testgetXeroCons';
        insert acc1;

        KTXero__Xero_Contact__c xc = new KTXero__Xero_Contact__c();
        xc.KTXero__Salesforce_Account__c = acc.Id;
        insert xc;
        
        KTXero__Xero_Contact__c xc1 = new KTXero__Xero_Contact__c();
        xc1.KTXero__Company_Name__c = acc1.Name;
        insert xc1;

        List<KTXero__Xero_Contact__c> xcList = InvoiceCreationController.getXeroCons(acc.Id, acc1.Name);
        System.assertNotEquals(0, xcList.size(), 'Success');

    }

    @isTest
    static void testgetProductSyncConfig(){
        KTXero__Invoice_Configuration_Options__c configObj = new KTXero__Invoice_Configuration_Options__c();
        configObj.SetupOwnerId = UserInfo.getOrganizationId();
        configObj.KTXero__Create_items_in_Xero__c = true;
        configObj.KTXero__Create_products_in_Salesforce__c = true;
        insert configObj;

        Test.startTest();
        InvoiceCreationWrapper.ProductConfigWrapper pcw = InvoiceCreationController.getProductSyncConfig('');
        System.assertEquals(true, pcw.createProInSales, 'Create Product in Salesforce is true');
        Test.stopTest();
    }

    @isTest
    static void testcreateXeroItem(){
        String lineItem = '[{"account":"270","amount":9000,"description":"Description","discount":10,"id":"0.40376064219793760yex1","inputValue":"GC5060: GenWatt Gasoline 2000kW","name":"","productCode":"GC5060","productId":"01tDn000005AquQIAS","productName":"GenWatt Gasoline 2000kW","quantity":10,"showDropdown":false,"taxCount":0,"taxRate":"NONE","trackingData":[{"key":"Region","value":{"defaultVal":"5e2974a2-097d-4f3b-bfd5-605d78c4a282","id":"a02Dn00000C5aJGIAZ","options":[{"label":"Eastside","value":"7b354c1c-cf59-42fc-9449-a65c51988335"},{"label":"North","value":"5e2974a2-097d-4f3b-bfd5-605d78c4a282"},{"label":"South","value":"e83ea9f2-de2c-44d8-b4f8-a5065bed339e"},{"label":"West Coast","value":"fc96efd9-b832-4b31-a93e-61f56158adad"}],"optname":"North"}}],"unitPrice":1000}]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseCreateItem());

        Test.startTest();
        InvoiceCreationWrapper.XeroWrapper xw = InvoiceCreationController.createXeroItem(lineItem);
        System.assertNotEquals(null, xw, 'Result is not null');
        Test.stopTest();

    }

    private class MockHttpResponseCreateItem implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Id\": \"b6b36ff2-3689-4bf6-ad81-98c977b93787\",\"Status\": \"OK\",\"ProviderName\": \"Salesforce Application\",\"DateTimeUTC\": \"/Date(1722926655484)/\",\"Items\": [{\"ItemID\": \"a6c91c71-4e94-48d8-928d-d4ef41a56780\",\"Code\": \"GC5060\",\"UpdatedDateUTC\": \"/Date(1722926655462)/\",\"PurchaseDetails\": {},\"SalesDetails\": {},\"Name\": \"GenWatt Gasoline 2000kW\",\"IsTrackedAsInventory\": false,\"IsSold\": true,\"IsPurchased\": true,\"ValidationErrors\": []}]}');
            response.setStatusCode(200);
            return response;
        } 
    }
}