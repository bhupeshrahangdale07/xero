@isTest
public  class XeroBulkItemSyncBatchTest {
    @isTest
    static void testBatchExecution(){
        KTXero__Xero_Connection__c xc = TestUtil.createXeroConnection(true);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorItems());

        Test.startTest();
        XeroBulkItemSyncBatch batch = new XeroBulkItemSyncBatch();
        Database.executeBatch(batch, 10);
        Test.stopTest();

        List<Product2> prodList = [SELECT Id, Name FROM Product2];
        System.assertEquals(2, prodList.size(), '2 products');
    }
    
    @isTest
    static void testBatchExecution1(){
        KTXero__Xero_Connection__c xc = TestUtil.createXeroConnection(false);
        xc.KTXero__Last_Token_Refresh_Time__c = System.now().addDays(-2);
        insert xc;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorItems());

        Test.startTest();
        XeroBulkItemSyncBatch batch = new XeroBulkItemSyncBatch();
        Database.executeBatch(batch, 10);
        Test.stopTest();

        List<Product2> prodList = [SELECT Id, Name FROM Product2];
        System.assertEquals(2, prodList.size(), '2 products');
    }
    
    @isTest
    static void testBatchExecution2(){
        KTXero__Xero_Connection__c xc = TestUtil.createXeroConnection(true);

        Product2 pd = new Product2();
        pd.Name = 'ItemA1';
        pd.IsActive = true;
        pd.ProductCode = 'A1';
        insert pd;

        Product2 pd1 = new Product2();
        pd1.Name = 'T-Shirt Small Black';
        pd1.IsActive = true;
        pd1.KTXero__Xero_ItemID__c = 'd3687dce-a3c2-4d07-9364-0c540f73c4f8';
        pd1.ProductCode = 'TSS - Black';
        insert pd1;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorItems());

        Test.startTest();
        XeroBulkItemSyncBatch batch = new XeroBulkItemSyncBatch();
        Database.executeBatch(batch, 10);
        Test.stopTest();

        List<Product2> prodList = [SELECT Id, Name FROM Product2 WHERE KTXero__Xero_ItemID__c != null];
        System.assertEquals(2, prodList.size(), '2 products');
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
}