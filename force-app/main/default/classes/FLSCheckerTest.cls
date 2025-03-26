@isTest
public class FLSCheckerTest {
    
    @isTest
    static void testnulldmlInsert() {

        Test.startTest();

        List<Account> accList = new List<Account>();
        FLSChecker.FLSCheckWrapper fl = FLSChecker.dmlInsert(accList);
        
        Test.stopTest();

        system.assertNotEquals(null, fl, 'Successfull');

    }
    
    @isTest
    static void testnullUpdate() {

        Test.startTest();

        List<Account> accList = new List<Account>();
        FLSChecker.FLSCheckWrapper fl = FLSChecker.dmlUpdate(accList);
        
        Test.stopTest();

        system.assertNotEquals(null, fl, 'Successfull');

    }
    
    @isTest
    static void testnulldmlUpsert() {

        Test.startTest();

        List<Account> accList = new List<Account>();
        FLSChecker.FLSCheckWrapper fl = FLSChecker.dmlUpsert(accList);
        
        Test.stopTest();

        system.assertNotEquals(null, fl, 'Successfull');

    }

    @isTest
    static void testnulldmlDelete() {

        Test.startTest();

        List<Account> accList = new List<Account>();
        FLSChecker.FLSCheckWrapper fl = FLSChecker.dmlDelete(accList);
        
        Test.stopTest();

        system.assertNotEquals(null, fl, 'Successfull');

    }

    @isTest
    static void testNoAccess(){
        
        Account acc = TestUtil.createAccount(true);
        Test.startTest();
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce'];
        User u = new User(Alias = 'standt', Email='minmumAcc@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='minimumAcc@testorg.com');

        System.runAs(u) {
            
            acc.Name = 'New Test Acc Change';
            List<Account> accList = new List<Account>();
            accList.add(acc);

            FLSChecker.dmlUpdate(accList);

            Account newAcc = TestUtil.createAccount(false);
            List<Account> newaccList = new List<Account>();
            newaccList.add(newAcc);
            
            FLSChecker.dmlInsert(newaccList);
            
            newaccList.add(acc);
            FLSChecker.dmlUpsert(newaccList);

            FLSChecker.FLSCheckWrapper fl = FLSChecker.dmlDelete(accList);
            system.assertNotEquals(null, fl, 'Successfull');
        }

        Test.stopTest();

    }

    @isTest
    static void testFieldAccess() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce'];
        User u = new User(Alias = 'standt', Email='minmumAcc@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='minimumAcc@testorg.com');

        insert u;
        
        // Create a permission set
        PermissionSet ps = new PermissionSet(Name = 'TestPermissionSet',Label = 'Test Permission Set');
        insert ps;

        ObjectPermissions objPermission = new ObjectPermissions();
        objPermission.ParentId = ps.Id;
        objPermission.SobjectType = 'KTXero__Xero_Connection__c';
        objPermission.PermissionsRead = True;
        objPermission.PermissionsCreate = True;
        objPermission.PermissionsEdit = True;
        objPermission.PermissionsDelete = True;

        insert objPermission;

        PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps.Id,AssigneeId = u.Id);
        insert psa;

        Test.startTest();

        System.runAs(u) {

            KTXero__Xero_Connection__c obj = new KTXero__Xero_Connection__c(KTXero__Access_Token__c = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RTY2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTE1NzQ2MDAsImV4cCI6MTY5MTU3NjQwMCwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTQ4MjAwOSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6Ijg3Zjc5ZDE1ZThmYTQxZDg4OWU2MTc4MzBkNjY0YWUzIiwic2lkIjoiODdmNzlkMTVlOGZhNDFkODg5ZTYxNzgzMGQ2NjRhZTMiLCJqdGkiOiIzQkQ2M0E1MkE2RjRDRTQzNTdDRDM4NUQ2MkFDNjg4RiIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiODY3ZWQ0MDctZjg2MC00YTQ3LTkzY2UtNzY1ZDQ2ZjQ0YTVhIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.r9TWEy7q4n3rEKmgM_PTj1k2U-BSJNrZvSY3biHXPaQnn_R26TLhuV9qus0RIpDfs7XZ9P0bIadRkodXe_loYqOLRkRYo8bmquyq-IrPfx8cPx18qDxfpMK8nqr_n3CHF-JZpUw_4zV_JpiMUZ0zvEbTyMFjVT7W7AmAeeppL2QoC64EbSr_9E42bKoAn14q7KaLeWi6dQLSQJ6UowXgfiKoga9qrJ1CqznK-NMy7mkzwwT4nQDjieebBTo0KgKX7nCjX_cQKmUxOMzxkanZzprlGYkckIvyN88kkia_Vg-1T7jTAvIdPpb7qtF1DkhWxs4HiHI0Pk5zG65fGeqARA', KTXero__Refresh_Token__c = 'iMrWhs51ztFLOM9sxr6Ge5juXHXU3mszSbQo-b3d0_I', KTXero__Tenant_Id__c = '7ba1138a-ae87-411a-ae0a-ed5768f597d4', KTXero__Last_Token_Refresh_Time__c = System.now());
            List<KTXero__Xero_Connection__c> xcList = new List<KTXero__Xero_Connection__c>();
            xcList.add(obj);
            
            FLSChecker.dmlInsert(xcList);
            
            obj.KTXero__Access_Token__c= 'adadad';
            List<KTXero__Xero_Connection__c> updatexcList = new List<KTXero__Xero_Connection__c>();
            updatexcList.add(obj);

            FLSChecker.FLSCheckWrapper fl = FLSChecker.dmlUpdate(xcList);
            system.assertNotEquals(null, fl, 'Successfull');

        }

        Test.stopTest();

    }
}