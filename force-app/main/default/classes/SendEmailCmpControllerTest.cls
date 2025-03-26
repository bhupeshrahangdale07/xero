@isTest
public class SendEmailCmpControllerTest {
    
    @isTest
    static void testsendEmailtoXC(){

        Account acc = TestUtil.createAccount(True);

        Opportunity opp = TestUtil.createOpportunity(True, acc.Id);

        TestUtil.createXeroConnection(true);

        Invoice__c testInvoice = new Invoice__c(Name = 'Test Invoice', Invoice_Id__c = '123', Status__c = 'Paid', KTXero__Opportunity__c = opp.Id, KTXero__Account__c = acc.Id);
        insert testInvoice;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForsendEmailtoXC());

        Test.startTest();
        InvoiceCreationWrapper.XeroWrapper inv = SendEmailCmpController.sendEmailtoXC(testInvoice.Id);
        System.assertEquals(true, inv.successFlag, 'Success');
        Test.stopTest();
    }

    @isTest
    static void testsendEmailtoXC1(){

        Account acc = TestUtil.createAccount(True);

        Opportunity opp = TestUtil.createOpportunity(True, acc.Id);

        TestUtil.createXeroConnection(true);

        Invoice__c testInvoice = new Invoice__c(Name = 'Test Invoice', Invoice_Id__c = '123', Status__c = 'Draft', KTXero__Opportunity__c = opp.Id, KTXero__Account__c = acc.Id);
        insert testInvoice;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForsendEmailtoXC());

        Test.startTest();
        InvoiceCreationWrapper.XeroWrapper inv = SendEmailCmpController.sendEmailtoXC(testInvoice.Id);
        System.assertEquals(false, inv.successFlag, 'Success');
        Test.stopTest();
    }

    @isTest
    static void testsendEmailtoXC2(){

        Account acc = TestUtil.createAccount(True);

        Opportunity opp = TestUtil.createOpportunity(True, acc.Id);

        TestUtil.createXeroConnection(true);

        Invoice__c testInvoice = new Invoice__c(Name = 'Test Invoice', Invoice_Id__c = '123', Status__c = 'Paid', KTXero__Opportunity__c = opp.Id, KTXero__Account__c = acc.Id);
        insert testInvoice;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForfailsendEmailtoXC());

        Test.startTest();
        InvoiceCreationWrapper.XeroWrapper inv = SendEmailCmpController.sendEmailtoXC(testInvoice.Id);
        System.assertEquals(false, inv.successFlag, 'Success');
        Test.stopTest();
    }

    @isTest
    static void testsendEmailtoXC3(){

        Account acc = TestUtil.createAccount(True);

        Opportunity opp = TestUtil.createOpportunity(True, acc.Id);

        TestUtil.createXeroConnection(true);

        Invoice__c testInvoice = new Invoice__c(Name = 'Test Invoice', Invoice_Id__c = '', Status__c = 'Draft', KTXero__Opportunity__c = opp.Id, KTXero__Account__c = acc.Id);
        insert testInvoice;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForsendEmailtoXC());

        Test.startTest();
        InvoiceCreationWrapper.XeroWrapper inv = SendEmailCmpController.sendEmailtoXC(testInvoice.Id);
        System.assertEquals(false, inv.successFlag, 'Success');
        Test.stopTest();
    }

    @isTest
    static void testsendEmailtoXC4(){

        Account acc = TestUtil.createAccount(True);

        Opportunity opp = TestUtil.createOpportunity(True, acc.Id);

        KTXero__Xero_Connection__c xc = TestUtil.createXeroConnection(false);
        xc.KTXero__Last_Token_Refresh_Time__c = System.now().addDays(-2);
        insert xc;

        Invoice__c testInvoice = new Invoice__c(Name = 'Test Invoice', Invoice_Id__c = '123', Status__c = 'PAid', KTXero__Opportunity__c = opp.Id, KTXero__Account__c = acc.Id);
        insert testInvoice;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForsendEmailtoXC());

        Test.startTest();
        InvoiceCreationWrapper.XeroWrapper inv = SendEmailCmpController.sendEmailtoXC(testInvoice.Id);
        System.assertEquals(true, inv.successFlag, 'Success');
        Test.stopTest();
    }

    @isTest
    static void testsendEmailtoXC5(){

        Account acc = TestUtil.createAccount(True);

        Opportunity opp = TestUtil.createOpportunity(True, acc.Id);

        TestUtil.createXeroConnection(true);

        // Invoice__c testInvoice = new Invoice__c(Name = 'Test Invoice', Invoice_Id__c = '', Status__c = 'Draft', KTXero__Opportunity__c = opp.Id, KTXero__Account__c = acc.Id);
        // insert testInvoice;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForsendEmailtoXC());

        Test.startTest();
        InvoiceCreationWrapper.XeroWrapper inv = SendEmailCmpController.sendEmailtoXC('123');
        System.assertEquals(false, inv.successFlag, 'Success');
        Test.stopTest();
    }

    private class MockHttpResponseGeneratorForsendEmailtoXC implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(204);
            return response;
        } 
    }

    private class MockHttpResponseGeneratorForfailsendEmailtoXC implements HttpCalloutMock {
        /**
         * @description Method to get Mock response
         * @param request
         * @return HttpResponse
        */
        String jsonResponse = '{' +
            '"errorNumber": 101,' +
            '"type": "Validation Error",' +
            '"message": "Invalid input data",' +
            '"elements": [{' +
                '"validationErrors": [' +
                    '{"message": "Field A cannot be empty"},' +
                    '{"message": "Field B must be a valid email address"}' +
                ']' +
            '}]' +
        '}';
        
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(400);
            response.setBody(jsonResponse);
            return response;
        } 
    }
}