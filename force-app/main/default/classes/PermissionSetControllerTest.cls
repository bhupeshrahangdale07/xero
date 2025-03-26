@isTest
public with sharing class PermissionSetControllerTest {

    @testSetup
    static void setupTestData() {
       
        Profile pf= [Select Id from profile where Name='System Administrator']; 
        
        String orgId = UserInfo.getOrganizationId(); 
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
        Integer randomId = Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName = orgId + dateString + randomId; 
        User uu = new User(firstname = 'ABC', 
                         lastName = 'XYZ', 
                         email = uniqueName + '@test' + orgId + '.org', 
                         Username = uniqueName + '@test' + orgId + '.org', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = uniqueName.substring(18, 23), 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pf.Id
                        ); 
        
        
        insert uu;

        List<PermissionSet> psList = [SELECT Id,Name FROM PermissionSet WHERE Name IN ('Xero_Integration_User_Read_Only','Xero_Integration_Operational','Xero_Integration_Admin')];
       	System.runAs(new User(Id = Userinfo.getUserId())) {
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = uu.Id;
            psa.PermissionSetId = psList[0].Id;
            insert psa;
            System.assertEquals(uu.Id, psa.AssigneeId,'Success');
        }
    }

    @isTest
    static void testfetchPermissionSets() {
        List<PermissionSetController.PermissionWrapper> permissionWrap =  PermissionSetController.fetchPermissionSets();
        System.assertNotEquals(null, permissionWrap,'Success');

    }
}