@isTest
public with sharing class TestUtil {
    /** 
     * @description This method is test data for create Account
     * @return Account
     * @param  doInsert
    */
    public static Account createAccount(Boolean doInsert){
        Account acc = new Account();
        acc.Name = 'Test Account';
        if(doInsert){
            insert acc;
        }
        return acc;
    }

    /**
     * @description This method is test data for create contact object
     * @return Contact
     * @param  doInsert
    */
    public static Contact createContact(Boolean doInsert){
        return createContact(doInsert, createAccount(true).Id);
    }
    
    /**
     * @description This method is test data for create contact object
     * @return Contact
     * @param  doInsert
     * @param  accId
    */
    public static Contact createContact(Boolean doInsert, Id accId){
        Contact con = new Contact();
        con.AccountId = accId;
        con.FirstName = 'FirstName';
        con.LastName = 'LastName';
        con.Email = 'FirstName@test.com' + Math.floor(Math.random() * 1000);
        if(doInsert){
            insert con;
        }
        return con;
    }

    /**
     * @description This method is test data for create Opportunity object
     * @return Opportunity
     * @param  doInsert
     * @param  accId
    */
    
    public static Opportunity createOpportunity(Boolean doInsert, Id accId){
        Opportunity oppt = new Opportunity(Name ='New mAWS Deal',
                            AccountID = accId,
                            StageName = 'Customer Won',
                            Amount = 3000,
                            CloseDate = System.today()
                            );
        if(doInsert){
            insert oppt;
        }
        return oppt;
    }

    /**
    * *************************************************************************
    * @description This method is to create test data for Setup Configuration Custom setting
     * @return KTXero__Setup_Configurations__c
     * @param  doInsert
    */
    public static KTXero__Setup_Configurations__c createSetupCOnfig(Boolean doInsert){
        KTXero__Setup_Configurations__c sc = new KTXero__Setup_Configurations__c(Name='Test SC',
                                    Delete_Logs__c = 'Daily');

        if(doInsert){
            insert sc;
        }
        return sc;
    }

    /**
    * *************************************************************************
    * @description This method is to create test data for Log Object
     * @return log__c
     * @param  doInsert
    */
    public static Log__c createLog(Boolean doInsert){
        Log__c log = new Log__c();
        log.Request_Endpoint__c = 'callout:KTXero/connections';
        log.Request_Method__c = 'POST';
        log.Request_Body__c = 'POST';
        log.Response_Status_Code__c = 200;
        log.Response_body__c = 'POST';
        log.Response_Status__c = 'POST';

        if(doInsert){
            insert log;
        }
        return log;
    }

    /**
    * *************************************************************************
    * @description This method is to create Encyrption Config Record
     * @return KTXero__Encryption_Configuration__c
    */
    public static KTXero__Encryption_Configuration__c createEncryptionConfig(){
        Blob cryptoKey = Crypto.generateAesKey(256); 
        String strKey = EncodingUtil.base64Encode(cryptoKey);

        KTXero__Encryption_Configuration__c cst = new KTXero__Encryption_Configuration__c();
        cst.KTXero__Encryption_Key__c = strKey;
        insert cst;
        return cst;
    }


    /**
    * *************************************************************************
    * @description This method is to create Xero Connection Record
     * @return KTXero__Xero_Connection__c
     * @param  doInsert
    */
    public static KTXero__Xero_Connection__c createXeroConnection(Boolean doInsert){
        TestUtil.createEncryptionConfig();

        KTXero__Xero_Connection__c xeroConnect = new KTXero__Xero_Connection__c();
        xeroConnect.KTXero__Webhook_Key__c = Utils.processEncryption('testkey');
        xeroConnect.KTXero__Access_Token__c = Utils.processEncryption('eyJhbGciOiJSUzI1NiIsImtpZCI6IjFDQUY4RT00Y2NzcyRDZEQzAyOEQ2NzI2RkQwMjYxNTgxNTcwRUZDMTkiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJISy1PWm5jdGJjQW8xbkp2MENZVmdWY09fQmsifQ.eyJuYmYiOjE2OTE1NzQ2MDAsImV4cCI6MTY5MTU3NjQwMCwiaXNzIjoiaHR0cHM6Ly9pZGVudGl0eS54ZXJvLmNvbSIsImF1ZCI6Imh0dHBzOi8vaWRlbnRpdHkueGVyby5jb20vcmVzb3VyY2VzIiwiY2xpZW50X2lkIjoiODU2QzY2RTNDMTZCNDFFQkIyRkY5OTM2RTJCMUMxRTAiLCJzdWIiOiIyOTU4Mzc4ZGQyNTk1MzJlYTdhZjRjNWYyM2NiZWJhMCIsImF1dGhfdGltZSI6MTY5MTQ4MjAwOSwieGVyb191c2VyaWQiOiIwZTE4MGIzZC0zMmZjLTQxZTUtYTEyNy04NjYxMzgwNGY0MzQiLCJnbG9iYWxfc2Vzc2lvbl9pZCI6Ijg3Zjc5ZDE1ZThmYTQxZDg4OWU2MTc4MzBkNjY0YWUzIiwic2lkIjoiODdmNzlkMTVlOGZhNDFkODg5ZTYxNzgzMGQ2NjRhZTMiLCJqdGkiOiIzQkQ2M0E1MkE2RjRDRTQzNTdDRDM4NUQ2MkFDNjg4RiIsImF1dGhlbnRpY2F0aW9uX2V2ZW50X2lkIjoiODY3ZWQ0MDctZjg2MC00YTQ3LTkzY2UtNzY1ZDQ2ZjQ0YTVhIiwic2NvcGUiOlsiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIiwiZmlsZXMiLCJwcm9qZWN0cyIsImFjY291bnRpbmcuc2V0dGluZ3MiLCJhY2NvdW50aW5nLmF0dGFjaG1lbnRzIiwiYWNjb3VudGluZy50cmFuc2FjdGlvbnMiLCJhc3NldHMiLCJhY2NvdW50aW5nLmNvbnRhY3RzIiwib2ZmbGluZV9hY2Nlc3MiXSwiYW1yIjpbInNzbyJdfQ.r9TWEy7q4n3rEKmgM_PTj1k2U-BSJNrZvSY3biHXPaQnn_R26TLhuV9qus0RIpDfs7XZ9P0bIadRkodXe_loYqOLRkRYo8bmquyq-IrPfx8cPx18qDxfpMK8nqr_n3CHF-JZpUw_4zV_JpiMUZ0zvEbTyMFjVT7W7AmAeeppL2QoC64EbSr_9E42bKoAn14q7KaLeWi6dQLSQJ6UowXgfiKoga9qrJ1CqznK-NMy7mkzwwT4nQDjieebBTo0KgKX7nCjX_cQKmUxOMzxkanZzprlGYkckIvyN88kkia_Vg-1T7jTAvIdPpb7qtF1DkhWxs4HiHI0Pk5zG65fGeqARA');
        xeroConnect.KTXero__Refresh_Token__c = Utils.processEncryption('iMrWhs51ztFLOM9sxr6Ge5juXHXU3mszSbQo-b3d0_I');
        xeroConnect.KTXero__Tenant_Id__c = Utils.processEncryption('7ba1138a-ae87-411a-ae0a-ed5768f597d4');
        xeroConnect.KTXero__Last_Token_Refresh_Time__c = System.now();
        if(doInsert){
            insert xeroConnect;
        }
        return xeroConnect;
    }

    /**
    * *************************************************************************
    * @description This method is to create Invoice Configuration Custom Setting Record
     * @return KTXero__Invoice_Configuration_Options__c
     * @param  doInsert
    */
    public static KTXero__Invoice_Configuration_Options__c createInvoiceConfigurationOptions(Boolean doInsert){
        KTXero__Invoice_Configuration_Options__c invConfig = new KTXero__Invoice_Configuration_Options__c();
        invConfig.Default_Tax_rate__c = 'OUTPUT';
        invConfig.KTXero__Draft_Invoice__c = true;
        invConfig.KTXero__Create_items_in_Xero__c = true;
        invConfig.KTXero__Create_products_in_Salesforce__c = true;
        invConfig.KTXero__Submit_for_approval__c = true;
        invConfig.KTXero__Approved_invoice__c = true;
        invConfig.KTXero__Approved_and_Email__c = true;
        invConfig.KTXero__Invoice_Reference__c = 'Name';
        invConfig.KTXero__Invoice_Due_Date__c = '1;After;CloseDate';
        invConfig.KTXero__Invoice_Date__c = '2;Before;CloseDate';
        invConfig.KTXero__Xero_Accounting_Tax_Type__c = 'Exclusive';
        invConfig.KTXero__Invoice_Template__c = 'f04ccf02-5a40-4ee2-a786-d6b97a34b8f4';
        invConfig.KTXero__Account_code_default__c = '200';
        if(doInsert){
            insert invConfig;
        }
        return invConfig;
    }
    
    @isTest
    static void testinsertLog(){
        KTXero__Log__c exc = new KTXero__Log__c();
        exc.KTXero__Govt_Limit_in_Executing_Code__c = 'Test';    
        exc.KTXero__Exception_Message__c = 'Test';
        exc.KTXero__Exception_Type__c = 'Test';
        exc.KTXero__Line_Number__c = 01;
        exc.KTXero__StackTrace__c = 'Test';
        exc.KTXero__MethodName__c = 'Test';
        exc.KTXero__ClassName__c = 'Test';
        exc.KTXero__Callout_Log__c = false;
        
        Test.startTest();
        Boolean flag = Utils.insertLog(JSON.serialize(exc));
        Test.stopTest();
    }
    
}