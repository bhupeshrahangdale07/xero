@isTest
public with sharing class NewInvoicePageControllerTest {
    @isTest
    static void testcreateInvoice(){

        PageReference testPage = Page.XeroOAuthPage;
        Test.setCurrentPage(testPage);
        
        // Create an opportunity record
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today();
        insert opp;

        // Create a standard controller for the opportunity
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);

        // Create an instance of the NewInvoicePageController class
        NewInvoicePageController controller = new NewInvoicePageController(sc);

        // Set the save_new_url parameter with the opportunity id
        ApexPages.currentPage().getParameters().put('save_new_url', 'id=' + opp.Id);

        // Call the createInvoice method and get the page reference
        Test.startTest();
        PageReference pr = controller.createInvoice();
        Test.stopTest();

        // Assert that the page reference is not null
        System.assertNotEquals(null, pr, 'Success');

        // Assert that the page reference has the correct url
        System.assertEquals('/lightning/n/KTXero__New_Inv/#/?type=opportunity&recid=' + opp.Id, pr.getUrl(), 'Success');
    }
}