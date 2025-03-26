/**
     * @description Class is used to update the configurations once after uninstalling package
     * @Author : Kandisa Technologies
     * @CreatedDate : 02 June 2023
*/
public with sharing class PostInstallScript implements InstallHandler {

    /**
     * @description Method is used to update the configurations 
     * @param  context
    */
    public void onInstall(InstallContext context) {
        if(context.previousVersion() == null){
            

            // Create Xero Contact Configuration
            KTXero__Xero_Contact_Configurations__c xcc = new KTXero__Xero_Contact_Configurations__c();
            xcc.SetupOwnerId = context.organizationId();
            xcc.KTXero__Xero_Contact_Account_Number__c = 'AccountNumber';
            xcc.KTXero__Xero_Contact_Account_Name__c = 'Name';
            xcc.KTXero__Xero_Contact_Street_Address__c = 'BillingStreet';
            xcc.KTXero__Xero_Contact_City__c = 'BillingCity';
            xcc.KTXero__Xero_Contact_State__c = 'BillingState';
            xcc.KTXero__Xero_Contact_ZipCode__c = 'BillingPostalCode';
            xcc.KTXero__Xero_Contact_Country__c = 'BillingCountry';
            xcc.KTXero__Xero_Contact_Account_Phone__c = 'Phone';
            xcc.KTXero__Xero_Contact_First_Name__c = 'FirstName';
            xcc.KTXero__Xero_Contact_Last_Name__c = 'LastName';
            xcc.KTXero__Xero_Contact_Email__c = 'Email';
            
            FLSChecker.FLSCheckWrapper flsWrap2 = new FLSChecker.FLSCheckWrapper();
            List<KTXero__Xero_Contact_Configurations__c> xcList = new List<KTXero__Xero_Contact_Configurations__c>();
            xcList.add(xcc);

            flsWrap2 = FLSChecker.dmlInsert(xcList);
            if(!flsWrap2.isSuccess){
                throw new CustomException(flsWrap2.message);
            }

            // Create Xero Setup Configuration
            KTXero__Setup_Configurations__c xsetup = new KTXero__Setup_Configurations__c();
            xsetup.SetupOwnerId = context.organizationId();
            xsetup.KTXero__Delete_Logs__c = 'Daily';
            List<KTXero__Setup_Configurations__c> scList = new List<KTXero__Setup_Configurations__c>();
            scList.add(xsetup);

            FLSChecker.FLSCheckWrapper flsWrap3 = new FLSChecker.FLSCheckWrapper();
            flsWrap3 = FLSChecker.dmlInsert(scList);
            if(!flsWrap3.isSuccess){
                throw new CustomException(flsWrap3.message);
            }

            // Create Xero Invoice Configuration
            KTXero__Invoice_Configuration_Options__c xinv = new KTXero__Invoice_Configuration_Options__c();
            xinv.SetupOwnerId = context.organizationId();
            xinv.KTXero__Approved_and_Email__c = false;
            xinv.KTXero__Approved_invoice__c = false;
            xinv.KTXero__Create_items_in_Xero__c = false;
            xinv.KTXero__Create_products_in_Salesforce__c = false;
            xinv.KTXero__Default_Tax_rate__c = '';
            xinv.KTXero__Draft_Invoice__c = true;
            xinv.KTXero__Account_code_default__c = '';
            xinv.KTXero__Invoice_Date__c = '';
            xinv.KTXero__Invoice_Due_Date__c = '';
            xinv.KTXero__Invoice_Reference__c = 'Name';
            xinv.KTXero__Invoice_Template__c = '';
            xinv.KTXero__Submit_for_approval__c = false;
            xinv.KTXero__Line_Item_Description__c = 'Line Item Description';
            xinv.KTXero__Xero_Accounting_Tax_Type__c = '';
            
            FLSChecker.FLSCheckWrapper flsWrap4 = new FLSChecker.FLSCheckWrapper();
            List<KTXero__Invoice_Configuration_Options__c> incList = new List<KTXero__Invoice_Configuration_Options__c>();
            incList.add(xinv);

            flsWrap4 = FLSChecker.dmlInsert(incList);
            if(!flsWrap4.isSuccess){
                throw new CustomException(flsWrap4.message);
            }

            // Create Xero Connection Record
            KTXero__Xero_Connection__c xc = new KTXero__Xero_Connection__c();
            xc.KTXero__Client_Id__c = Utils.processEncryption('');
            xc.KTXero__Client_Secret__c = Utils.processEncryption('');
            xc.KTXero__Access_Token__c = Utils.processEncryption('');
            xc.KTXero__Refresh_Token__c = Utils.processEncryption('');
            xc.KTXero__Tenant_Id__c = Utils.processEncryption('');
            xc.KTXero__Webhook_Key__c = Utils.processEncryption('');
            xc.KTXero__Completed_Steps__c = 0;
            xc.KTXero__Progress_Value__c = 0;
            xc.KTXero__Total_Xero_Connection_Steps__c = 2;
            xc.KTXero__Completed_Xero_Connection_Steps__c = 0;
            xc.KTXero__Authenticated__c = false;
            
            FLSChecker.FLSCheckWrapper flsWrap5 = new FLSChecker.FLSCheckWrapper();
            List<KTXero__Xero_Connection__c> xconList = new List<KTXero__Xero_Connection__c>();
            xconList.add(xc);

            flsWrap5 = FLSChecker.dmlInsert(xconList);
            if(!flsWrap5.isSuccess){
                throw new CustomException(flsWrap5.message);
            }

            // Create Encyption Key
            KTXero__Encryption_Configuration__c setting = KTXero__Encryption_Configuration__c.getOrgDefaults();
            Blob cryptoKey = Crypto.generateAesKey(256);
            setting.KTXero__Encryption_Key__c = EncodingUtil.base64Encode(cryptoKey);

            FLSChecker.FLSCheckWrapper flsWrap6 = new FLSChecker.FLSCheckWrapper();
            List<KTXero__Encryption_Configuration__c> encyList = new List<KTXero__Encryption_Configuration__c>();
            encyList.add(setting);

            flsWrap6 = FLSChecker.dmlInsert(encyList);
            if(!flsWrap6.isSuccess){
                throw new CustomException(flsWrap6.message);
            }

            // Create Bulk Sync Setting
            KTXero__Xero_Bulk_Sync_Setting__c sc = new KTXero__Xero_Bulk_Sync_Setting__c();
            sc.SetupOwnerId = context.organizationId();

            FLSChecker.FLSCheckWrapper flsWrap7 = new FLSChecker.FLSCheckWrapper();
            List<KTXero__Xero_Bulk_Sync_Setting__c> bss = new List<KTXero__Xero_Bulk_Sync_Setting__c>();
            bss.add(sc);

            flsWrap7 = FLSChecker.dmlInsert(bss);
            if(!flsWrap7.isSuccess){
                throw new CustomException(flsWrap7.message);
            }

        } else {
            // if(context.previousVersion().compareTo(new Version(1,13)) < 0){
            //     // Create Bulk Sync Setting
            //     KTXero__Xero_Bulk_Sync_Setting__c sc = new KTXero__Xero_Bulk_Sync_Setting__c();
            //     sc.SetupOwnerId = context.organizationId();

            //     FLSChecker.FLSCheckWrapper flsWrap7 = new FLSChecker.FLSCheckWrapper();
            //     List<KTXero__Xero_Bulk_Sync_Setting__c> bss = new List<KTXero__Xero_Bulk_Sync_Setting__c>();
            //     bss.add(sc);

            //     flsWrap7 = FLSChecker.dmlUpsert(bss);
            //     if(!flsWrap7.isSuccess){
            //         throw new CustomException(flsWrap7.message);
            //     }
            // }
            if(context.isPush()) {

                if(context.previousVersion().compareTo(new Version(1,13)) < 0){
                    // Create Bulk Sync Setting
                    KTXero__Xero_Bulk_Sync_Setting__c sc = new KTXero__Xero_Bulk_Sync_Setting__c();
                    sc.SetupOwnerId = context.organizationId();
    
                    FLSChecker.FLSCheckWrapper flsWrap7 = new FLSChecker.FLSCheckWrapper();
                    List<KTXero__Xero_Bulk_Sync_Setting__c> bss = new List<KTXero__Xero_Bulk_Sync_Setting__c>();
                    bss.add(sc);
    
                    flsWrap7 = FLSChecker.dmlUpsert(bss);
                    if(!flsWrap7.isSuccess){
                        throw new CustomException(flsWrap7.message);
                    }
                }
            }
        }
    }
}