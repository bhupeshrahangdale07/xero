@isTest
public class AuthorizationMessageControllerTest {
    
    @isTest
    static void testAuthorizationTrueMessage(){
        PageReference testPage = Page.AuthorizationMessagePage;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Success', 'True');
        AuthorizationMessageController amc = new AuthorizationMessageController();
        System.assertEquals('True', amc.val,'Sucess');
    }
    
    @isTest
    static void testAuthorizationFalseMessage(){
        PageReference testPage = Page.AuthorizationMessagePage;
        Test.setCurrentPage(testPage);
        testPage.getParameters().put('Success', 'False');
        AuthorizationMessageController amc = new AuthorizationMessageController();
        System.assertEquals('False', amc.val,'Sucess');
    }
}