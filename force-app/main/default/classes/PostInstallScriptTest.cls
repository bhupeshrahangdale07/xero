@isTest
public with sharing class PostInstallScriptTest {
    @isTest
    static void testInstallScript() {
        PostInstallScript postinstall = new PostInstallScript();
        Test.testInstall(postinstall, null);
        // Test.testInstall(postinstall, new Version(1,0), true);
        List<KTXero__Xero_Connection__c> con = [SELECT Id,Name FROM KTXero__Xero_Connection__c LIMIT 1];
        System.assertequals(1,con.size(),'Size is 1');
    }
}