@isTest
public class XeroBulkSyncControllerTest {
    @isTest
    static void teststartProductSync(){
        KTXero__Xero_Connection__c xc = TestUtil.createXeroConnection(true);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorItems());

        Test.startTest();
        Boolean flag = XeroBulkSyncController.startProductSync();
        Test.stopTest();

        System.assertEquals(true, flag, 'Success');
    }

    @isTest
    static void testcheckBatchRunning(){
        KTXero__Xero_Connection__c xc = TestUtil.createXeroConnection(true);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorItems());

        Test.startTest();
        XeroBulkItemSyncBatch batch = new XeroBulkItemSyncBatch();
        Database.executeBatch(batch, 10);
        String batchResult = '';
        try{
            batchResult = XeroBulkSyncController.checkBatchRunning('XeroBulkItemSyncBatch');
        }catch(Exception e){
            System.debug(LoggingLevel.ERROR, e);
        }
        Test.stopTest();

        System.assertEquals('', batchResult, 'Success');
    }

    private class MockHttpResponseGeneratorItems implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Id\":\"cd1567ac-7846-4a3a-977e-6b0d91036eaa\",\"Status\":\"OK\",\"ProviderName\":\"Salesforce Application\",\"DateTimeUTC\":\"/Date(1717062721552)/\",\"Items\":[{\"ItemID\":\"8d953f74-20c3-42a8-b0b7-db47213e7f76\",\"Code\":\"A1\",\"UpdatedDateUTC\":\"/Date(1716881087630+0000)/\",\"PurchaseDetails\":{},\"SalesDetails\":{},\"Name\":\"ItemA1\",\"IsTrackedAsInventory\":false,\"IsSold\":false,\"IsPurchased\":false},{\"ItemID\":\"d3687dce-a3c2-4d07-9364-0c540f73c4f8\",\"Code\":\"TSS - Black\",\"Description\":\"Company Branded T-Shirt Small Black.  Check out our website for other offers!\",\"PurchaseDescription\":\"Company Branded T-Shirt Small Black.  Order code #2308\",\"UpdatedDateUTC\":\"/Date(1715769260347+0000)/\",\"PurchaseDetails\":{\"UnitPrice\":20,\"COGSAccountCode\":\"310\",\"TaxType\":\"NONE\"},\"SalesDetails\":{\"UnitPrice\":40,\"AccountCode\":\"200\",\"TaxType\":\"OUTPUT\"},\"Name\":\"T-Shirt Small Black\",\"IsTrackedAsInventory\":true,\"InventoryAssetAccountCode\":\"630\",\"TotalCostPool\":140,\"QuantityOnHand\":7,\"IsSold\":true,\"IsPurchased\":true}]}');
            response.setStatusCode(200);
            return response;
        } 
    }

    @isTest
    static void testgetCustomSettings(){
        KTXero__Xero_Bulk_Sync_Setting__c customSettingObj = new KTXero__Xero_Bulk_Sync_Setting__c();
        customSettingObj.SetupOwnerId = UserInfo.getOrganizationId();
        insert customSettingObj;

        Test.startTest();
        KTXero__Xero_Bulk_Sync_Setting__c bs = XeroBulkSyncController.getCustomSettings();
        System.assertEquals(UserInfo.getOrganizationId(), customSettingObj.SetupOwnerId, 'Successfull Result');
        Test.stopTest();
    }

    @isTest
    static void teststartSync(){
        KTXero__Xero_Bulk_Sync_Setting__c customSettingObj = new KTXero__Xero_Bulk_Sync_Setting__c();
        customSettingObj.SetupOwnerId = UserInfo.getOrganizationId();
        insert customSettingObj;

        String syncSetting = '{"filterSync":false,"invoiceStatus":[],"invStatusOperator":"equals","startDate":"NaN/NaN/NaN","endDate":"NaN/NaN/NaN","linkXC":"Yes","createCX":"Yes","mapSfAcc":"Yes","xcCompanyNameMap":"Name","xcEmailMapRelatedTo":"Account","linkProd":"No"}';
        
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorInvoice());
        // Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorContact());

        Boolean flag = XeroBulkSyncController.startSync(syncSetting);
        System.assertEquals(true, flag, 'Success');
        Test.stopTest();
    }

    @isTest
    static void teststartSync1(){
        KTXero__Xero_Bulk_Sync_Setting__c customSettingObj = new KTXero__Xero_Bulk_Sync_Setting__c();
        customSettingObj.SetupOwnerId = UserInfo.getOrganizationId();
        insert customSettingObj;

        String syncSetting = '{"filterSync":true,"invoiceStatus":["DRAFT"],"invStatusOperator":"equals","startDate":"8/23/2024","endDate":"8/31/2024","linkXC":"Yes","createCX":"Yes","mapSfAcc":"Yes","xcCompanyNameMap":"Name","xcEmailMapRelatedTo":"Account","linkProd":"No"}';
        
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorInvoice());
        // Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorContact());

        Boolean flag = XeroBulkSyncController.startSync(syncSetting);
        System.assertEquals(true, flag, 'Success');
        Test.stopTest();
    }
    
    @isTest
    static void teststartSync2(){
        KTXero__Xero_Bulk_Sync_Setting__c customSettingObj = new KTXero__Xero_Bulk_Sync_Setting__c();
        customSettingObj.SetupOwnerId = UserInfo.getOrganizationId();
        insert customSettingObj;

        Account acc = new Account();
        acc.Name = 'BurlingtonTextilesCorpofAmerica';
        insert acc;

        String syncSetting = '{"filterSync":true,"invoiceStatus":["DRAFT"],"invStatusOperator":"notEquals","startDate":"8/23/2024","endDate":"8/31/2024","linkXC":"Yes","createCX":"Yes","mapSfAcc":"Yes","xcCompanyNameMap":"Name","xcAccNumberMap":"AccountNumber","xcEmailMapRelatedTo":"Contact","xcEmailMap":"Email","linkProd":"linkandCreate"}';
        
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorInvoice());
        // Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorContact());

        Boolean flag = XeroBulkSyncController.startSync(syncSetting);
        System.assertEquals(true, flag, 'Success');
        Test.stopTest();
    }

    @isTest
    static void teststartSync3(){
        KTXero__Xero_Bulk_Sync_Setting__c customSettingObj = new KTXero__Xero_Bulk_Sync_Setting__c();
        customSettingObj.SetupOwnerId = UserInfo.getOrganizationId();
        insert customSettingObj;

        Account acc = new Account();
        acc.Name = 'test1';
        acc.AccountNumber = '123456';
        insert acc;

        String syncSetting = '{"filterSync":true,"invoiceStatus":["DRAFT"],"invStatusOperator":"notEquals","startDate":"8/23/2024","endDate":"8/31/2024","linkXC":"Yes","createCX":"Yes","mapSfAcc":"Yes","xcCompanyNameMap":"Name","xcAccNumberMap":"AccountNumber","xcEmailMapRelatedTo":"Contact","xcEmailMap":"Email","linkProd":"linkandCreate"}';
        
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorInvoice());

        Boolean flag = XeroBulkSyncController.startSync(syncSetting);
        System.assertEquals(true, flag, 'Success');
        Test.stopTest();
    }

    @isTest
    static void teststartSync4(){
        KTXero__Xero_Bulk_Sync_Setting__c customSettingObj = new KTXero__Xero_Bulk_Sync_Setting__c();
        customSettingObj.SetupOwnerId = UserInfo.getOrganizationId();
        insert customSettingObj;

        Account acc = new Account();
        acc.Name = 'test1';
        insert acc;

        Contact con = new Contact();
        con.LastName = 'Test';
        con.Email = 'a_young@dickenson.com';
        con.AccountId = acc.Id;
        insert con;

        String syncSetting = '{"filterSync":true,"invoiceStatus":["DRAFT"],"invStatusOperator":"notEquals","startDate":"8/23/2024","endDate":"8/31/2024","linkXC":"Yes","createCX":"Yes","mapSfAcc":"Yes","xcCompanyNameMap":"Name","xcAccNumberMap":"AccountNumber","xcEmailMapRelatedTo":"Contact","xcEmailMap":"Email","linkProd":"linkandCreate"}';
        
        KTXero__Xero_Connection__c xeroConnect = TestUtil.createXeroConnection(true);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorInvoice());

        Boolean flag = XeroBulkSyncController.startSync(syncSetting);
        System.assertEquals(true, flag, 'Success');
        Test.stopTest();
    }

    private class MockHttpResponseGeneratorInvoice implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            
            HttpResponse response = new HttpResponse();
            if (request.getEndpoint().contains('Invoices')){
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{\"Id\":\"4a0b3db9-dd9a-4a5d-941b-58c6215d1134\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"/Date(1684831274579)/\",\"Invoices\":[{\"Type\":\"ACCREC\",\"InvoiceID\":\"de2b30a2-afb2-4649-998f-4fd17554058a\",\"InvoiceNumber\":\"INV-0051\",\"Reference\":\"001Dn00000Qc9GaIAJ\",\"Prepayments\":[],\"Payments\":[{\"Date\":\"Date(1684420182133+0000)\",\"PaymentID\":\"xeroPaymentId\",\"Amount\":100,\"CurrencyRate\":1.0000000000,\"HasAccount\":true,\"HasValidationErrors\":false}],\"Overpayments\":[],\"AmountDue\":0.00,\"AmountPaid\":0.00,\"SentToContact\":false,\"CurrencyRate\":1.0000000000,\"TotalDiscount\":0.00,\"IsDiscounted\":true,\"HasAttachments\":false,\"HasErrors\":false,\"Attachments\":[],\"InvoicePaymentServices\":[],\"Contact\":{\"ContactID\":\"37d78e0c-cd12-4dba-b518-8043c8b28480\",\"ContactStatus\":\"ACTIVE\",\"Name\":\"TestAccountBK6\",\"FirstName\":\"Test\",\"LastName\":\"Contact\",\"EmailAddress\":\"bhagyashree.k@kandisatech.com\",\"BankAccountDetails\":\"\",\"Addresses\":[{\"AddressType\":\"STREET\",\"City\":\"\",\"Region\":\"\",\"PostalCode\":\"\",\"Country\":\"\"},{\"AddressType\":\"POBOX\",\"AddressLine1\":\"test123\",\"City\":\"mum\",\"Region\":\"mh\",\"PostalCode\":\"852963\",\"Country\":\"in\"}],\"Phones\":[{\"PhoneType\":\"DEFAULT\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"DDI\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"FAX\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"MOBILE\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"}],\"UpdatedDateUTC\":\"/Date(1684420181097+0000)/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":true,\"SalesTrackingCategories\":[],\"PurchasesTrackingCategories\":[],\"ContactPersons\":[],\"HasValidationErrors\":false},\"DateString\":\"2023-04-18T00:00:00\",\"Date\":\"/Date(1681776000000+0000)/\",\"DueDateString\":\"2023-04-21T00:00:00\",\"DueDate\":\"/Date(1682035200000+0000)/\",\"BrandingThemeID\":\"f04ccf02-5a40-4ee2-a786-d6b97a34b8f4\",\"Status\":\"DRAFT\",\"LineAmountTypes\":\"Exclusive\",\"LineItems\":[{\"ItemCode\":\"PMBr\",\"Description\":\"Project management & implementation - branding workshop with your team - follow up session\",\"UnitAmount\":200,\"TaxType\":\"OUTPUT\",\"TaxAmount\":16.5,\"LineAmount\":200,\"AccountCode\":\"200\",\"Item\":{\"ItemID\":\"ec4362af-a038-4984-ab93-1bba3b6bd402\",\"Name\":\"Project management & implementation - branding\",\"Code\":\"PMBr\"},\"Tracking\":[{\"Name\":\"TR001\",\"Option\":\"Option1\",\"TrackingCategoryID\":\"TCID-001\",\"TrackingOptionID\":\"TO001\"}],\"Quantity\":15.0000,\"DiscountRate\":85.00,\"LineItemID\":\"a21423b7-c179-42f5-b2ec-17f9ce8f7804\",\"DiscountAmount\":0.0000,\"ValidationErrors\":[]},   {\"ItemCode\":\"TestCode\",\"Description\":\"Project management & implementation - branding workshop with your team - follow up session\",\"UnitAmount\":200,\"TaxType\":\"OUTPUT\",\"TaxAmount\":16.5,\"LineAmount\":200,\"AccountCode\":\"200\",\"Item\":{\"ItemID\":\"123456\",\"Name\":\"Project management & implementation - branding\",\"Code\":\"TestCode\"},\"Tracking\":[{\"Name\":\"TR001\",\"Option\":\"Option1\",\"TrackingCategoryID\":\"TCID-001\",\"TrackingOptionID\":\"TO001\"}],\"Quantity\":15.0000,\"DiscountRate\":90.00,\"LineItemID\":\"123456789\",\"DiscountAmount\":0.0000,\"ValidationErrors\":[]}   ],\"SubTotal\":0.00,\"TotalTax\":0.00,\"Total\":0.00,\"UpdatedDateUTC\":\"/Date(1684420182133+0000)/\",\"CurrencyCode\":\"USD\"}]}');
                response.setStatusCode(200);
                return response;
            }else if (request.getEndpoint().contains('contacts')){
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{\"Id\":\"d7335f67-3ced-4b5c-97a2-b89db9bf7cce\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"\\/Date(1685512514564)\\/\",\"Contacts\":[{\"ContactID\":\"37d78e0c-cd12-4dba-b518-8043c8b28480\",\"ContactStatus\":\"ACTIVE\",\"AccountNumber\":\"123456\",\"Name\":\"BurlingtonTextilesCorpofAmerica\",\"FirstName\":\"Andy\",\"LastName\":\"Young\",\"EmailAddress\":\"a_young@dickenson.com\",\"BankAccountDetails\":\"\",\"Addresses\":[{\"AddressType\":\"DELIVERY\",\"City\":\"\",\"Region\":\"\",\"PostalCode\":\"\",\"Country\":\"\"},{\"AddressType\":\"POBOX\",\"AddressLine1\":\"525S.LexingtonAve\",\"City\":\"Burlington\",\"Region\":\"NC\",\"PostalCode\":\"27215\",\"Country\":\"USA\"}],\"Phones\":[{\"PhoneType\":\"DEFAULT\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"DDI\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"FAX\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"},{\"PhoneType\":\"MOBILE\",\"PhoneNumber\":\"\",\"PhoneAreaCode\":\"\",\"PhoneCountryCode\":\"\"}],\"UpdatedDateUTC\":\"\\/Date(1685512473177+0000)\\/\",\"ContactGroups\":[],\"IsSupplier\":false,\"IsCustomer\":false,\"SalesTrackingCategories\":[],\"PurchasesTrackingCategories\":[],\"ContactPersons\":[{\"FirstName\":\"John\",\"LastName\":\"Doe\",\"EmailAddress\":\"john.doe@example.com\",\"IncludeInEmails\":true},{\"FirstName\":\"Jane\",\"LastName\":\"Smith\",\"EmailAddress\":\"jane.smith@example.com\",\"IncludeInEmails\":false},{\"FirstName\":\"Michael\",\"LastName\":\"Johnson\",\"EmailAddress\":\"michael.johnson@example.com\",\"IncludeInEmails\":true},{\"FirstName\":\"Sarah\",\"LastName\":\"Williams\",\"EmailAddress\":\"sarah.williams@example.com\",\"IncludeInEmails\":true},{\"FirstName\":\"David\",\"LastName\":\"Brown\",\"EmailAddress\":\"david.brown@example.com\",\"IncludeInEmails\":false}],\"HasValidationErrors\":false}]}');
                response.setStatusCode(200);
            }else if(request.getEndpoint().contains('Items')){
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{\"Id\": \"b6b36ff2-3689-4bf6-ad81-98c977b93787\",\"Status\": \"OK\",\"ProviderName\": \"Salesforce Application\",\"DateTimeUTC\": \"/Date(1722926655484)/\",\"Items\": [{\"ItemID\": \"ec4362af-a038-4984-ab93-1bba3b6bd402\",\"Code\": \"GC5060\",\"UpdatedDateUTC\": \"/Date(1722926655462)/\",\"PurchaseDetails\": {},\"SalesDetails\": {},\"Name\": \"GenWatt Gasoline 2000kW\",\"IsTrackedAsInventory\": false,\"IsSold\": true,\"IsPurchased\": true,\"ValidationErrors\": []}]}');
                response.setStatusCode(200);
                return response;
            }
            return response;
        } 
    }
}