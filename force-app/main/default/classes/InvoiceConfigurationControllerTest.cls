@isTest
public class InvoiceConfigurationControllerTest {
    
    /**
     * @description setup method to create test data 
    */
    @TestSetup
    static void setupDate(){
                
        //Insert KTXero__Invoice_Configuration_Options__c custom settings record
        insert new KTXero__Invoice_Configuration_Options__c(
            SetupOwnerId = UserInfo.getOrganizationId(), 
            Default_Tax_rate__c = '',
            Draft_Invoice__c = true, 
            Submit_for_approval__c = true, 
            Approved_invoice__c = true, 
            Approved_and_Email__c = true,
            KTXero__Account_code_default__c = '200', 
            Invoice_Date__c = '',  
            Invoice_Due_Date__c = '',
            Invoice_Reference__c = '',  
            Xero_Accounting_Tax_Type__c = '',  
            Invoice_Template__c = '', 
            Create_items_in_Xero__c = true, 
            Create_products_in_Salesforce__c = true
        );
        
        //Insert KTXero__Xero_Contact_Configurations__c custom settings record
        insert new KTXero__Xero_Contact_Configurations__c(
            SetupOwnerId = UserInfo.getOrganizationId(), 
            Xero_Contact_First_Name__c = 'FirstName',  
            Xero_Contact_Last_Name__c = 'LastName', 
            Xero_Contact_Email__c = 'xero@test.email',  
            Xero_Contact_Account_Number__c = '', 
            Xero_Contact_Account_Name__c = '', 
            Xero_Contact_Street_Address__c = '', 
            Xero_Contact_City__c = '', 
            Xero_Contact_State__c = '',  
            Xero_Contact_ZipCode__c = '', 
            Xero_Contact_Country__c = '', 
            Xero_Contact_Account_Phone__c = ''
        );
            
        List<Xero_Metadata__c> xeroMetadataList = new List<Xero_Metadata__c>();
            xeroMetadataList = [SELECT Id, Name, Code__c, KTXero__Account_Code__c, IsDeleted, Status__c, SystemModstamp, Text__c, Type__c, Value__c, Xero_Id__c, Xero_Org_ID__c FROM Xero_Metadata__c WITH SECURITY_ENFORCED];
        //Insert Xero_Metadata__c custom Object record
        insert new Xero_Metadata__c(
            Xero_Org_ID__c = UserInfo.getOrganizationId(), 
            Name = '',  
            Code__c = '',
            KTXero__Account_Code__c = null, 
            Status__c = '', 
            Text__c = '', 
            Type__c = '', 
            Value__c = '',
            Xero_Id__c = ''
        );
        
    }
    
    /**
     * @description Method to test getInvoiceConfiguration method 
    */
    @isTest
    public static void getInvoiceConfigurationTest(){
        // KTXero__Xero_Connection__c obj = new KTXero__Xero_Connection__c(KTXero__Access_Token__c = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTE1NzQ2MDAsImV4cCI6MTY5MTU3NjQwMCwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTQ4MjAwOSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6Ijg3Zjc5ZDE1ZThmYTQxZDg4OWU2MTc4MzBkNjY0YWUzIiwic2lkIjoiODdmNzlkMTVlOGZhNDFkODg5ZTYxNzgzMGQ2NjRhZTMiLCJqdGkiOiIzQkQ2M0E1MkE2RjRDRTQzNTdDRDM4NUQ2MkFDNjg4RiIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiODY3ZWQ0MDctZjg2MC00YTQ3LTkzY2UtNzY1ZDQ2ZjQ0YTVhIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.r9TWEy7q4n3rEKmgM_PTj1k2U-BSJNrZvSY3biHXPaQnn_R26TLhuV9qus0RIpDfs7XZ9P0bIadRkodXe_loYqOLRkRYo8bmquyq-IrPfx8cPx18qDxfpMK8nqr_n3CHF-JZpUw_4zV_JpiMUZ0zvEbTyMFjVT7W7AmAeeppL2QoC64EbSr_9E42bKoAn14q7KaLeWi6dQLSQJ6UowXgfiKoga9qrJ1CqznK-NMy7mkzwwT4nQDjieebBTo0KgKX7nCjX_cQKmUxOMzxkanZzprlGYkckIvyN88kkia_Vg-1T7jTAvIdPpb7qtF1DkhWxs4HiHI0Pk5zG65fGeqARA', KTXero__Refresh_Token__c = 'iMrWhs51ztFLOM9sxr6Ge5juXHXU3mszSbQo-b3d0_I', KTXero__Tenant_Id__c = '7ba1138a-ae87-411a-ae0a-ed5768f597d4');
        // insert obj;

        TestUtil.createXeroConnection(true);
        Test.startTest();
        InvoiceConfigurationController.InvoiceConfigWrapper result = InvoiceConfigurationController.getInvoiceConfiguration();
        System.assertNotEquals(null, result,'Success');
        Test.stopTest();
    }
    
    @isTest
    static void testxeroTaxRateSync(){
        KTXero__Xero_Connection__c kt = TestUtil.createXeroConnection(true);
        System.assertNotEquals(null,kt.Id,'success');

        List<Xero_Metadata__c> xmList = new List<Xero_Metadata__c>();
        Xero_Metadata__c taxRate1 = new Xero_Metadata__c(
            Value__c = '0.05', Type__c = 'TaxRate', Text__c = '5% Tax Rate', Code__c = 'TAX001', Xero_Id__c = 'XERO001',
            Status__c = 'Active', KTXero__Account_Code__c = '1001', Name = 'Tax Rate 1');
        xmList.add(taxRate1);
        
        Xero_Metadata__c taxRate2 = new Xero_Metadata__c(
            Value__c = '0.1', Type__c = 'TaxRate', Text__c = '10% Tax Rate', Code__c = 'TAX002', Xero_Id__c = 'XERO002',
            Status__c = 'Active', KTXero__Account_Code__c = '1002', Name = 'Tax Rate 2');
        xmList.add(taxRate2);
        insert xmList;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorTaxRate());
        
        Test.startTest();
        XeroSyncController.XeroMetadataSyncWrapper xmw = InvoiceConfigurationController.xeroTaxRateSync();
        System.assertEquals(true, xmw.successFlag, 'Success');
        Test.stopTest();
    }
      /**
     * @description Mock Class to setup a test response
    */
    private class MockHttpResponseGeneratorTaxRate implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
			//response.setBody('{\"Id\":\"9cac4ddb-86e5-4c7a-a9aa-e4d0b90e5747\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"\\/Date(1685082457265)\\/\",\"TaxRates\":[{\"Name\":\"ExemptSales\",\"TaxType\":\"CAN030\",\"ReportTaxType\":\"NONEOUTPUT\",\"CanApplyToAssets\":true,\"CanApplyToEquity\":true,\"CanApplyToExpenses\":false,\"CanApplyToLiabilities\":true,\"CanApplyToRevenue\":true,\"DisplayTaxRate\":0.0000,\"EffectiveRate\":0.0000,\"Status\":\"ACTIVE\",\"TaxComponents\":[{\"Name\":\"NoTax\",\"Rate\":0.0000,\"IsCompound\":false,\"IsNonRecoverable\":false}]},{\"Name\":\"MB-GST/RSTonPurchases\",\"TaxType\":\"CAN029\",\"ReportTaxType\":\"PURCHASESINPUT\",\"CanApplyToAssets\":true,\"CanApplyToEquity\":true,\"CanApplyToExpenses\":true,\"CanApplyToLiabilities\":true,\"CanApplyToRevenue\":false,\"DisplayTaxRate\":12.0000,\"EffectiveRate\":12.0000,\"Status\":\"ACTIVE\",\"TaxComponents\":[{\"Name\":\"RST\",\"Rate\":7.0000,\"IsCompound\":false,\"IsNonRecoverable\":false},{\"Name\":\"GST\",\"Rate\":5.0000,\"IsCompound\":false,\"IsNonRecoverable\":false}]},{\"Name\":\"MB-GST/RSTonSales\",\"TaxType\":\"CAN028\",\"ReportTaxType\":\"SALESOUTPUT\",\"CanApplyToAssets\":true,\"CanApplyToEquity\":true,\"CanApplyToExpenses\":false,\"CanApplyToLiabilities\":true,\"CanApplyToRevenue\":true,\"DisplayTaxRate\":12.0000,\"EffectiveRate\":12.0000,\"Status\":\"ACTIVE\",\"TaxComponents\":[{\"Name\":\"RST\",\"Rate\":7.0000,\"IsCompound\":false,\"IsNonRecoverable\":false},{\"Name\":\"GST\",\"Rate\":5.0000,\"IsCompound\":false,\"IsNonRecoverable\":false}]},{\"Name\":\"SalesTaxonImports\",\"TaxType\":\"GSTONIMPORTS\",\"ReportTaxType\":\"GSTONIMPORTS\",\"CanApplyToAssets\":false,\"CanApplyToEquity\":false,\"CanApplyToExpenses\":false,\"CanApplyToLiabilities\":true,\"CanApplyToRevenue\":false,\"DisplayTaxRate\":0.0000,\"EffectiveRate\":0.0000,\"Status\":\"ACTIVE\",\"TaxComponents\":[{\"Name\":\"TAX\",\"Rate\":0.0000,\"IsCompound\":false,\"IsNonRecoverable\":false}]},{\"Name\":\"TaxExempt\",\"TaxType\":\"NONE\",\"ReportTaxType\":\"NONE\",\"CanApplyToAssets\":true,\"CanApplyToEquity\":true,\"CanApplyToExpenses\":true,\"CanApplyToLiabilities\":true,\"CanApplyToRevenue\":true,\"DisplayTaxRate\":0.0000,\"EffectiveRate\":0.0000,\"Status\":\"ACTIVE\",\"TaxComponents\":[{\"Name\":\"NoTax\",\"Rate\":0.0000,\"IsCompound\":false,\"IsNonRecoverable\":false}]},{\"Name\":\"TaxonConsulting\",\"TaxType\":\"OUTPUT\",\"ReportTaxType\":\"OUTPUT\",\"CanApplyToAssets\":true,\"CanApplyToEquity\":true,\"CanApplyToExpenses\":true,\"CanApplyToLiabilities\":true,\"CanApplyToRevenue\":true,\"DisplayTaxRate\":8.2500,\"EffectiveRate\":8.2500,\"Status\":\"ACTIVE\",\"TaxComponents\":[{\"Name\":\"CityTax\",\"Rate\":4.0000,\"IsCompound\":false,\"IsNonRecoverable\":false},{\"Name\":\"StateTax\",\"Rate\":4.2500,\"IsCompound\":false,\"IsNonRecoverable\":false}]},{\"Name\":\"TaxonGoods\",\"TaxType\":\"TAX001\",\"CanApplyToAssets\":true,\"CanApplyToEquity\":true,\"CanApplyToExpenses\":true,\"CanApplyToLiabilities\":true,\"CanApplyToRevenue\":true,\"DisplayTaxRate\":8.7500,\"EffectiveRate\":8.7500,\"Status\":\"ACTIVE\",\"TaxComponents\":[{\"Name\":\"StateTax\",\"Rate\":4.5000,\"IsCompound\":false,\"IsNonRecoverable\":false},{\"Name\":\"CityTax\",\"Rate\":4.2500,\"IsCompound\":false,\"IsNonRecoverable\":false}]},{\"Name\":\"TaxonPurchases\",\"TaxType\":\"INPUT\",\"ReportTaxType\":\"INPUT\",\"CanApplyToAssets\":true,\"CanApplyToEquity\":true,\"CanApplyToExpenses\":true,\"CanApplyToLiabilities\":true,\"CanApplyToRevenue\":true,\"DisplayTaxRate\":8.2500,\"EffectiveRate\":8.2500,\"Status\":\"ACTIVE\",\"TaxComponents\":[{\"Name\":\"StateTax\",\"Rate\":4.2500,\"IsCompound\":false,\"IsNonRecoverable\":false},{\"Name\":\"CityTax\",\"Rate\":4.0000,\"IsCompound\":false,\"IsNonRecoverable\":false}]}]}');
            response.setBody('{\"Id\":\"3a3708a1-4938-4335-ae85-4abcba160277\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"\\/Date(1685081353198)\\/\",\"TaxRates\":[{\"Name\":\"ExemptSales\",\"TaxType\":\"CAN030\",\"ReportTaxType\":\"NONEOUTPUT\",\"CanApplyToAssets\":true,\"CanApplyToEquity\":true,\"CanApplyToExpenses\":false,\"CanApplyToLiabilities\":true,\"CanApplyToRevenue\":true,\"DisplayTaxRate\":0.0000,\"EffectiveRate\":0.0000,\"Status\":\"ACTIVE\",\"TaxComponents\":[{\"Name\":\"NoTax\",\"Rate\":0.0000,\"IsCompound\":false,\"IsNonRecoverable\":false}]},{\"Name\":\"MB-GST/RSTonPurchases\",\"TaxType\":\"CAN029\",\"ReportTaxType\":\"PURCHASESINPUT\",\"CanApplyToAssets\":true,\"CanApplyToEquity\":true,\"CanApplyToExpenses\":true,\"CanApplyToLiabilities\":true,\"CanApplyToRevenue\":false,\"DisplayTaxRate\":12.0000,\"EffectiveRate\":12.0000,\"Status\":\"ACTIVE\",\"TaxComponents\":[{\"Name\":\"RST\",\"Rate\":7.0000,\"IsCompound\":false,\"IsNonRecoverable\":false},{\"Name\":\"GST\",\"Rate\":5.0000,\"IsCompound\":false,\"IsNonRecoverable\":false}]}]}');
            response.setStatusCode(200);
            return response;
        }
    }//----------------testxeroTaxRateSync---------------
    
    @isTest
    static void testxeroInvoiceTemplateSync(){
        KTXero__Xero_Connection__c kt = TestUtil.createXeroConnection(true);
        System.assertNotEquals(null,kt.Id,'success');

        List<Xero_Metadata__c> xmList = new List<Xero_Metadata__c>();
        Xero_Metadata__c template1 = new Xero_Metadata__c(
            Value__c = 'Template 1', Type__c = 'Invoice Template', Text__c = 'Template 1 description',
            Code__c = 'TMPL1', Xero_Id__c = 'XERO001', Status__c = 'Active', KTXero__Account_Code__c = '1001', Name = 'Template 1');
        xmList.add(template1);
        
        Xero_Metadata__c template2 = new Xero_Metadata__c(
            Value__c = 'Template 2', Type__c = 'Invoice Template', Text__c = 'Template 2 description',
            Code__c = 'TMPL2', Xero_Id__c = 'XERO002', Status__c = 'Active', KTXero__Account_Code__c = '1002', Name = 'Template 2');
        xmList.add(template2);
        
        Xero_Metadata__c template3 = new Xero_Metadata__c(
            Value__c = 'Template 3', Type__c = 'Invoice Template', Text__c = 'Template 3 description',
            Code__c = 'TMPL3', Xero_Id__c = 'XERO003', Status__c = 'Active', KTXero__Account_Code__c = '1003', Name = 'Template 3');
        xmList.add(template3);
        insert xmList;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorInvoiceTemplate());

        
        Test.startTest();
        XeroSyncController.XeroMetadataSyncWrapper result1 =  InvoiceConfigurationController.xeroInvoiceTemplateSync();
        Test.stopTest();
        
        System.assertEquals(true, result1.successFlag,'FLag should be true.');            
    }
    
     /**
     * @description Mock Class to setup a test response
    */
    private class MockHttpResponseGeneratorInvoiceTemplate implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{\"Id\":\"ffb9ca9a-60d4-4fff-9a8c-1e837ed3c09c\",\"Status\":\"OK\",\"ProviderName\":\"SalesforceApplication\",\"DateTimeUTC\":\"\\/Date(1685025489907)\\/\",\"BrandingThemes\":[{\"BrandingThemeID\":\"d613f7f9-8fcb-477f-97f0-31eb85b7e5cf\",\"Name\":\"Standard\",\"LogoUrl\":\"https://in.xero.com/logo?id=ZXcwS0lDQWlieUk2SUNJeFl6SXpOVFV6TkMwd05XRmlMVFJoWTJFdE9UQTNZeTA1TXpRek5XSmpOVGMxWlRjaUxBMEtJQ0FpWmlJNklDSTNZVFptT1RFMk1pMDBaamhsTFRRNE16Z3RZams1WVMwNVltWTVPRE0zT0RjM09UWWlEUXA5LUQ1UXA1bEM4UCtFPQ\",\"Type\":\"INVOICE\",\"SortOrder\":0,\"CreatedDateUTC\":\"\\/Date(1277835396270+0000)\\/\"},{\"BrandingThemeID\":\"f04ccf02-5a40-4ee2-a786-d6b97a34b8f4\",\"Name\":\"SpecialProjects\",\"LogoUrl\":\"https://in.xero.com/logo?id=ZXcwS0lDQWlieUk2SUNJeFl6SXpOVFV6TkMwd05XRmlMVFJoWTJFdE9UQTNZeTA1TXpRek5XSmpOVGMxWlRjaUxBMEtJQ0FpWmlJNklDSmtPR1ZtTjJSak9TMWxZVGd5TFRReE0ySXRPV05tTVMwME1tVmlOR05rWlRFNFl6UWlEUXA5LUh6dnZZdkhMdHpJPQ\",\"Type\":\"INVOICE\",\"SortOrder\":1,\"CreatedDateUTC\":\"\\/Date(946684800000+0000)\\/\"},{\"BrandingThemeID\":\"92f08561-bd65-469b-93fb-65dd1552c678\",\"Name\":\"Veryorangeinvoice!\",\"LogoUrl\":\"\",\"Type\":\"INVOICE\",\"SortOrder\":2,\"CreatedDateUTC\":\"\\/Date(1357339751907+0000)\\/\"}]}');
            response.setStatusCode(200);
            return response;
        }
    }//----------------testinvoiceSyncEnd---------------
    
    /**
     * @description Method to test updateInvoiceConfig method 
    */
    @isTest
    public static void updateInvoiceConfigTest(){
        // KTXero__Xero_Connection__c obj = new KTXero__Xero_Connection__c(KTXero__Access_Token__c = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTE1NzQ2MDAsImV4cCI6MTY5MTU3NjQwMCwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTQ4MjAwOSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6Ijg3Zjc5ZDE1ZThmYTQxZDg4OWU2MTc4MzBkNjY0YWUzIiwic2lkIjoiODdmNzlkMTVlOGZhNDFkODg5ZTYxNzgzMGQ2NjRhZTMiLCJqdGkiOiIzQkQ2M0E1MkE2RjRDRTQzNTdDRDM4NUQ2MkFDNjg4RiIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiODY3ZWQ0MDctZjg2MC00YTQ3LTkzY2UtNzY1ZDQ2ZjQ0YTVhIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.r9TWEy7q4n3rEKmgM_PTj1k2U-BSJNrZvSY3biHXPaQnn_R26TLhuV9qus0RIpDfs7XZ9P0bIadRkodXe_loYqOLRkRYo8bmquyq-IrPfx8cPx18qDxfpMK8nqr_n3CHF-JZpUw_4zV_JpiMUZ0zvEbTyMFjVT7W7AmAeeppL2QoC64EbSr_9E42bKoAn14q7KaLeWi6dQLSQJ6UowXgfiKoga9qrJ1CqznK-NMy7mkzwwT4nQDjieebBTo0KgKX7nCjX_cQKmUxOMzxkanZzprlGYkckIvyN88kkia_Vg-1T7jTAvIdPpb7qtF1DkhWxs4HiHI0Pk5zG65fGeqARA', KTXero__Refresh_Token__c = 'iMrWhs51ztFLOM9sxr6Ge5juXHXU3mszSbQo-b3d0_I', KTXero__Tenant_Id__c = '7ba1138a-ae87-411a-ae0a-ed5768f597d4');
        // insert obj;
        TestUtil.createXeroConnection(true);

        Test.startTest();
        	Boolean result = InvoiceConfigurationController.updateInvoiceConfig(JSON.serialize(InvoiceConfigurationController.getInvoiceConfiguration()));
            System.assertNotEquals(null, result,'Success');

        Test.stopTest();
    }
    

    /**
     * @description Method to test getxeroconConfiguration method 
    */
    @isTest
    public static void getxeroconConfigurationTest(){
        // KTXero__Xero_Connection__c obj = new KTXero__Xero_Connection__c(KTXero__Access_Token__c = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTE1NzQ2MDAsImV4cCI6MTY5MTU3NjQwMCwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTQ4MjAwOSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6Ijg3Zjc5ZDE1ZThmYTQxZDg4OWU2MTc4MzBkNjY0YWUzIiwic2lkIjoiODdmNzlkMTVlOGZhNDFkODg5ZTYxNzgzMGQ2NjRhZTMiLCJqdGkiOiIzQkQ2M0E1MkE2RjRDRTQzNTdDRDM4NUQ2MkFDNjg4RiIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiODY3ZWQ0MDctZjg2MC00YTQ3LTkzY2UtNzY1ZDQ2ZjQ0YTVhIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.r9TWEy7q4n3rEKmgM_PTj1k2U-BSJNrZvSY3biHXPaQnn_R26TLhuV9qus0RIpDfs7XZ9P0bIadRkodXe_loYqOLRkRYo8bmquyq-IrPfx8cPx18qDxfpMK8nqr_n3CHF-JZpUw_4zV_JpiMUZ0zvEbTyMFjVT7W7AmAeeppL2QoC64EbSr_9E42bKoAn14q7KaLeWi6dQLSQJ6UowXgfiKoga9qrJ1CqznK-NMy7mkzwwT4nQDjieebBTo0KgKX7nCjX_cQKmUxOMzxkanZzprlGYkckIvyN88kkia_Vg-1T7jTAvIdPpb7qtF1DkhWxs4HiHI0Pk5zG65fGeqARA', KTXero__Refresh_Token__c = 'iMrWhs51ztFLOM9sxr6Ge5juXHXU3mszSbQo-b3d0_I', KTXero__Tenant_Id__c = '7ba1138a-ae87-411a-ae0a-ed5768f597d4');
        // insert obj;

        TestUtil.createXeroConnection(true);

        Test.startTest();
        	InvoiceConfigurationController.XeroConWrapper result = InvoiceConfigurationController.getxeroconConfiguration();
            System.assertNotEquals(null, result,'Success');
        Test.stopTest();
    }
    

    /**
     * @description Method to test updateContactConfig method 
    */
    @isTest
    public static void updateContactConfigTest(){
        // KTXero__Xero_Connection__c obj = new KTXero__Xero_Connection__c(KTXero__Access_Token__c = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTE1NzQ2MDAsImV4cCI6MTY5MTU3NjQwMCwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTQ4MjAwOSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6Ijg3Zjc5ZDE1ZThmYTQxZDg4OWU2MTc4MzBkNjY0YWUzIiwic2lkIjoiODdmNzlkMTVlOGZhNDFkODg5ZTYxNzgzMGQ2NjRhZTMiLCJqdGkiOiIzQkQ2M0E1MkE2RjRDRTQzNTdDRDM4NUQ2MkFDNjg4RiIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiODY3ZWQ0MDctZjg2MC00YTQ3LTkzY2UtNzY1ZDQ2ZjQ0YTVhIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.r9TWEy7q4n3rEKmgM_PTj1k2U-BSJNrZvSY3biHXPaQnn_R26TLhuV9qus0RIpDfs7XZ9P0bIadRkodXe_loYqOLRkRYo8bmquyq-IrPfx8cPx18qDxfpMK8nqr_n3CHF-JZpUw_4zV_JpiMUZ0zvEbTyMFjVT7W7AmAeeppL2QoC64EbSr_9E42bKoAn14q7KaLeWi6dQLSQJ6UowXgfiKoga9qrJ1CqznK-NMy7mkzwwT4nQDjieebBTo0KgKX7nCjX_cQKmUxOMzxkanZzprlGYkckIvyN88kkia_Vg-1T7jTAvIdPpb7qtF1DkhWxs4HiHI0Pk5zG65fGeqARA', KTXero__Refresh_Token__c = 'iMrWhs51ztFLOM9sxr6Ge5juXHXU3mszSbQo-b3d0_I', KTXero__Tenant_Id__c = '7ba1138a-ae87-411a-ae0a-ed5768f597d4');
        // insert obj;
        TestUtil.createXeroConnection(true);

        Test.startTest();
        	Boolean result = InvoiceConfigurationController.updateContactConfig(JSON.serialize(InvoiceConfigurationController.getxeroconConfiguration()));
            System.assertNotEquals(null, result,'Success');

        Test.stopTest();
    }
    

    /**
     * @description Method to test taxRateAndAccFetchMethodTest method 
    */
    @isTest
    public static void taxRateAndAccFetchMethodTest(){
        // KTXero__Xero_Connection__c obj = new KTXero__Xero_Connection__c(KTXero__Access_Token__c = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTE1NzQ2MDAsImV4cCI6MTY5MTU3NjQwMCwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTQ4MjAwOSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6Ijg3Zjc5ZDE1ZThmYTQxZDg4OWU2MTc4MzBkNjY0YWUzIiwic2lkIjoiODdmNzlkMTVlOGZhNDFkODg5ZTYxNzgzMGQ2NjRhZTMiLCJqdGkiOiIzQkQ2M0E1MkE2RjRDRTQzNTdDRDM4NUQ2MkFDNjg4RiIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiODY3ZWQ0MDctZjg2MC00YTQ3LTkzY2UtNzY1ZDQ2ZjQ0YTVhIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.r9TWEy7q4n3rEKmgM_PTj1k2U-BSJNrZvSY3biHXPaQnn_R26TLhuV9qus0RIpDfs7XZ9P0bIadRkodXe_loYqOLRkRYo8bmquyq-IrPfx8cPx18qDxfpMK8nqr_n3CHF-JZpUw_4zV_JpiMUZ0zvEbTyMFjVT7W7AmAeeppL2QoC64EbSr_9E42bKoAn14q7KaLeWi6dQLSQJ6UowXgfiKoga9qrJ1CqznK-NMy7mkzwwT4nQDjieebBTo0KgKX7nCjX_cQKmUxOMzxkanZzprlGYkckIvyN88kkia_Vg-1T7jTAvIdPpb7qtF1DkhWxs4HiHI0Pk5zG65fGeqARA', KTXero__Refresh_Token__c = 'iMrWhs51ztFLOM9sxr6Ge5juXHXU3mszSbQo-b3d0_I', KTXero__Tenant_Id__c = '7ba1138a-ae87-411a-ae0a-ed5768f597d4');
        // insert obj;
        TestUtil.createXeroConnection(true);

        Test.startTest();
        	List<InvoiceConfigurationController.XeroMetadataWrapper> result = InvoiceConfigurationController.taxRateAndAccFetchMethod();
            System.assertNotEquals(null, result,'Success');

        Test.stopTest();
    }

    /**
     * @description Mock Class to setup a test response
    */
    private class MockHttpResponsetrackingCategorySync implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"TrackingCategories":[{"Name":"Region","Status":"ACTIVE","TrackingCategoryID":"351953c4-8127-4009-88c3-f9cd8c9cbe9f","Options":[{"TrackingOptionID":"ce205173-7387-4651-9726-2cf4c5405ba2","Name":"Eastside","Status":"ACTIVE"},{"TrackingOptionID":"6eb12fdf-63de-4033-98df-be679d84e3c2","Name":"North","Status":"ACTIVE"},{"TrackingOptionID":"6159bdd4-b634-4338-a664-e929aa73f70f","Name":"South","Status":"ACTIVE"},{"TrackingOptionID":"161ad543-97ab-4436-8213-e0d794b1ea90","Name":"West Coast","Status":"ACTIVE"}]}]}');
            response.setStatusCode(200);
            return response;
        }
    }

    /**
     * @description Method to test taxRateAndAccFetchMethodTest method 
    */
    @isTest
    public static void xeroTrackingCategorySyncTest(){
        // KTXero__Xero_Connection__c obj = new KTXero__Xero_Connection__c(KTXero__Access_Token__c = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTE1NzQ2MDAsImV4cCI6MTY5MTU3NjQwMCwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTQ4MjAwOSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6Ijg3Zjc5ZDE1ZThmYTQxZDg4OWU2MTc4MzBkNjY0YWUzIiwic2lkIjoiODdmNzlkMTVlOGZhNDFkODg5ZTYxNzgzMGQ2NjRhZTMiLCJqdGkiOiIzQkQ2M0E1MkE2RjRDRTQzNTdDRDM4NUQ2MkFDNjg4RiIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiODY3ZWQ0MDctZjg2MC00YTQ3LTkzY2UtNzY1ZDQ2ZjQ0YTVhIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.r9TWEy7q4n3rEKmgM_PTj1k2U-BSJNrZvSY3biHXPaQnn_R26TLhuV9qus0RIpDfs7XZ9P0bIadRkodXe_loYqOLRkRYo8bmquyq-IrPfx8cPx18qDxfpMK8nqr_n3CHF-JZpUw_4zV_JpiMUZ0zvEbTyMFjVT7W7AmAeeppL2QoC64EbSr_9E42bKoAn14q7KaLeWi6dQLSQJ6UowXgfiKoga9qrJ1CqznK-NMy7mkzwwT4nQDjieebBTo0KgKX7nCjX_cQKmUxOMzxkanZzprlGYkckIvyN88kkia_Vg-1T7jTAvIdPpb7qtF1DkhWxs4HiHI0Pk5zG65fGeqARA', KTXero__Refresh_Token__c = 'iMrWhs51ztFLOM9sxr6Ge5juXHXU3mszSbQo-b3d0_I', KTXero__Tenant_Id__c = '7ba1138a-ae87-411a-ae0a-ed5768f597d4');
        // insert obj;
        TestUtil.createXeroConnection(true);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponsetrackingCategorySync());

        Test.startTest();
        
        XeroSyncController.XeroMetadataSyncWrapper result = InvoiceConfigurationController.xeroTrackingCategorySync();
        System.assertNotEquals(null, result,'Success');

        Test.stopTest();
    }

}