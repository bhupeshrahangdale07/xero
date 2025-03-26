/**
@Author : Kandisa Technologies
@description : This class contains different methods for Invoice Configurations. Custom setting KTXero__Invoice_Configuration_Options__c is used.
*/
public with sharing class InvoiceConfigurationController {
    public static KTXero__Xero_Connection__c xeroConnect = [SELECT Id, KTXero__Access_Token__c, KTXero__Refresh_Token__c, KTXero__Tenant_Id__c, KTXero__Last_Token_Refresh_Time__c FROM KTXero__Xero_Connection__c WITH SECURITY_ENFORCED LIMIT 1];
    /**
     * @description Method to get values from KTXero__Invoice_Configuration_Options__c custom setting
     * @description Commenting KTXero__Default_Acc_code__c (Number) as it is replaced with new field KTXero__Account_code_default__c (String) || Yash Patel || 7 May 2024z
     * @return InvoiceConfigWrapper 
    */
    @AuraEnabled
    public static InvoiceConfigWrapper getInvoiceConfiguration(){
        InvoiceConfigWrapper icw = new InvoiceConfigWrapper();
        try{
            KTXero__Invoice_Configuration_Options__c config = [SELECT Id, Name, SetupOwnerId, KTXero__Default_Tax_rate__c, KTXero__Draft_Invoice__c, KTXero__Submit_for_approval__c, KTXero__Approved_invoice__c, 
                                                        KTXero__Approved_and_Email__c, KTXero__Account_code_default__c, KTXero__Invoice_Date__c, KTXero__Invoice_Due_Date__c, KTXero__Invoice_Reference__c, 
                                                        KTXero__Xero_Accounting_Tax_Type__c, KTXero__Invoice_Template__c, KTXero__Create_items_in_Xero__c, KTXero__Create_products_in_Salesforce__c, KTXero__Line_Item_Description__c
                                                        FROM KTXero__Invoice_Configuration_Options__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED];
            icw.id = Config.Id;
            icw.draft = config.KTXero__Draft_Invoice__c;
            icw.submit = config.KTXero__Submit_for_approval__c;
            icw.approved = config.KTXero__Approved_invoice__c;
            icw.approvedEmail = config.KTXero__Approved_and_Email__c;
            icw.taxRate = config.KTXero__Default_Tax_rate__c;
            //Commenting KTXero__Default_Acc_code__c (Number) as it is replaced with now with new KTXero__Account_code_default__c (String) field
            // icw.accCode = String.valueOf(config.KTXero__Default_Acc_code__c);
            icw.accCode = config.KTXero__Account_code_default__c;
            icw.invtaxType = config.KTXero__Xero_Accounting_Tax_Type__c;
            icw.invTemplate = config.KTXero__Invoice_Template__c;

            //INVOICE FIELDS FROM CUSTOM SETTINGS
            icw.invoiceReference = config.KTXero__Invoice_Reference__c != null ? config.KTXero__Invoice_Reference__c : '';
            icw.lineItemDescription = config.KTXero__Line_Item_Description__c != null ? config.KTXero__Line_Item_Description__c : '';
            icw.invoiceDueDate = config.KTXero__Invoice_Due_Date__c != null ? config.KTXero__Invoice_Due_Date__c : '';
            icw.invoiceDate = config.KTXero__Invoice_Date__c != null ? config.KTXero__Invoice_Date__c : '';
            
            // OPPORTUNITY FIELDS API NAME AND LABEL MAP
            icw.opportunityFieldMap = getFieldMap('Opportunity');

            // PRODUCT CONFIGURATION FIELD
            icw.createItem = config.KTXero__Create_items_in_Xero__c;
            icw.createProduct = config.KTXero__Create_products_in_Salesforce__c;
            
        }catch(Exception e){
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return icw;
    }

    /**
     * @description Method to get values from KTXero__Xero_Contact_Configurations__c custom setting
     * @return XeroConWrapper 
    */
    @AuraEnabled
    public static XeroConWrapper getxeroconConfiguration(){
        XeroConWrapper xcw = new XeroConWrapper();
        KTXero__Xero_Contact_Configurations__c xconfig = new KTXero__Xero_Contact_Configurations__c(); 
        try {
            xconfig = [SELECT Id, Name, SetupOwnerId, Xero_Contact_First_Name__c, Xero_Contact_Last_Name__c, Xero_Contact_Email__c, Xero_Contact_Account_Number__c,
                                                        Xero_Contact_Account_Name__c, Xero_Contact_Street_Address__c, Xero_Contact_City__c, Xero_Contact_State__c, KTXero__Create_Account_if_not_available__c,
                                                        Xero_Contact_ZipCode__c, Xero_Contact_Country__c, Xero_Contact_Account_Phone__c FROM KTXero__Xero_Contact_Configurations__c
                                                        WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED];
                   
            xcw.id = xconfig.Id;
            //Contact Configuration fields
            xcw.firstName = xconfig.Xero_Contact_First_Name__c;
            xcw.lastName = xconfig.Xero_Contact_Last_Name__c;
            xcw.email = xconfig.Xero_Contact_Email__c;
            xcw.accountNumber = xconfig.Xero_Contact_Account_Number__c;
            xcw.accountName = xconfig.Xero_Contact_Account_Name__c;
            xcw.accountStreet = xconfig.Xero_Contact_Street_Address__c;
            xcw.accountCity = xconfig.Xero_Contact_City__c;
            xcw.accountState = xconfig.Xero_Contact_State__c;
            xcw.accountzipCode = xconfig.Xero_Contact_ZipCode__c;
            xcw.accountCountry = xconfig.Xero_Contact_Country__c;
            xcw.accountPhone = xconfig.Xero_Contact_Account_Phone__c;
            xcw.accCreation = xconfig.KTXero__Create_Account_if_not_available__c;

        } catch (Exception e) {
            // HandleCustomException.logException(e);
            // throw new AuraHandledException(e.getMessage());
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }

        return xcw;
    }
    
    /**
     * @description Method to get values from Xero_Metadata__c object
     * @description Removing KTXero__Number_Code__c FROM SOQL and adding KTXero__Account_Code__c|| Yash Patel || 7 May 2024
     * @return List<XeroMetadataWrapper> 
    */
    @AuraEnabled
    public static List<XeroMetadataWrapper> taxRateAndAccFetchMethod(){
        List<Xero_Metadata__c> xeroMetadataList = new List<Xero_Metadata__c>();
        List<XeroMetadataWrapper> xeroMetadataWrapper = new List<XeroMetadataWrapper>();
        try{
            xeroMetadataList = [SELECT Id, Name, Code__c, KTXero__Account_Code__c, IsDeleted, Status__c, SystemModstamp, Text__c, Type__c, Value__c, Xero_Id__c, Xero_Org_ID__c FROM Xero_Metadata__c WITH SECURITY_ENFORCED];
            for(Xero_Metadata__c xm : xeroMetadataList){
                XeroMetadataWrapper xmw = new XeroMetadataWrapper();
                xmw.id = xm.Id;
                xmw.name = xm.Name;
                xmw.code = xm.Code__c;
                //Commenting Number_Code__c (Number) as it is replaced with now with new KTXero__Account_Code__c (String) field
                // xmw.numberCode = xm.Number_Code__c;
                xmw.numberCode = xm.KTXero__Account_Code__c;
                xmw.isDeleted = xm.IsDeleted;
                xmw.status = xm.Status__c;
                xmw.text = xm.Text__c;
                xmw.type = xm.Type__c;
                xmw.value = xm.Value__c;
                xmw.xeroId = xm.Xero_Id__c;
                xmw.xeroOrgID = xm.Xero_Org_ID__c;
                xeroMetadataWrapper.add(xmw);
            }
            
        }catch(Exception e){
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return xeroMetadataWrapper;
    }

    /**
     * @description Method to update values of KTXero__Invoice_Configuration_Options__c custom setting
     * @description Commenting KTXero__Default_Acc_code__c (Number) as it is replaced with new field KTXero__Account_code_default__c (String) || Yash Patel || 7 May 2024z
     * @return Boolean
     * @param configData
    */
    @AuraEnabled
    public static Boolean updateInvoiceConfig(String configData){
        boolean updated = false;
        InvoiceConfigWrapper icWrap = new InvoiceConfigWrapper();
        try {
            if(String.isNotBlank(configData)){
                icWrap = (InvoiceConfigWrapper)JSON.deserialize(configData,InvoiceConfigWrapper.class);
                
                KTXero__Invoice_Configuration_Options__c config = new KTXero__Invoice_Configuration_Options__c();
                config.Id = icWrap.id;
                config.KTXero__Draft_Invoice__c = icWrap.draft;
                config.KTXero__Submit_for_approval__c = icWrap.submit;
                config.KTXero__Approved_invoice__c = icWrap.approved;
                config.KTXero__Approved_and_Email__c = icWrap.approvedEmail;
                config.KTXero__Default_Tax_rate__c = icWrap.taxRate;
                if(String.isNotBlank(icWrap.accCode) || icWrap.accCode != null){
                    // config.KTXero__Default_Acc_code__c = Integer.ValueOf(icWrap.accCode);
                    config.KTXero__Account_code_default__c = icWrap.accCode;
                }
                config.KTXero__Xero_Accounting_Tax_Type__c = icWrap.invtaxType;
                config.KTXero__Invoice_Template__c = icWrap.invTemplate;

                config.KTXero__Invoice_Reference__c = icWrap.invoiceReference ;
                config.KTXero__Line_Item_Description__c = icWrap.lineItemDescription ;
                config.KTXero__Invoice_Due_Date__c = icWrap.invoiceDueDate;
                config.KTXero__Invoice_Date__c = icWrap.invoiceDate;
                
                config.KTXero__Create_items_in_Xero__c = icWrap.createItem;
                config.KTXero__Create_products_in_Salesforce__c = icWrap.createProduct;

                if(config.getSObjectType().getDescribe().isUpdateable() == true 
                && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.KTXero__Draft_Invoice__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.KTXero__Submit_for_approval__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.KTXero__Approved_invoice__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.KTXero__Approved_and_Email__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.KTXero__Default_Tax_rate__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.KTXero__Account_code_default__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.KTXero__Xero_Accounting_Tax_Type__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.KTXero__Invoice_Template__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.KTXero__Invoice_Reference__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.KTXero__Invoice_Due_Date__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.KTXero__Create_items_in_Xero__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.KTXero__Create_products_in_Salesforce__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.KTXero__Invoice_Date__c.isUpdateable() == true){
                    database.SaveResult sr = database.update(config);
                    if(sr.isSuccess()){
                        updated = true;
                    }else{
                        updated = false;
                    }
                }
            }
        } catch (Exception e) {
            // HandleCustomException.logException(e);
            // throw new AuraHandledException(e.getMessage());
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }

        return updated;
    }

    /**
     * @description Method to update values of KTXero__Xero_Contact_Configurations__c custom setting
     * @return Boolean
     * @param configData
    */
    @AuraEnabled
    public static Boolean updateContactConfig(String configData){
        boolean updated = false;
        XeroConWrapper cWrap = new XeroConWrapper();
        try {
            if(String.isNotBlank(configData)){
                cWrap = (XeroConWrapper)JSON.deserialize(configData,XeroConWrapper.class);
                
                KTXero__Xero_Contact_Configurations__c config = new KTXero__Xero_Contact_Configurations__c();
                config.Id = cWrap.id;
                config.Xero_Contact_First_Name__c = cWrap.firstName;
                config.Xero_Contact_Last_Name__c = cWrap.lastName;
                config.Xero_Contact_Email__c = cWrap.email;
                config.Xero_Contact_Account_Number__c = cWrap.accountNumber;
                config.Xero_Contact_Account_Name__c = cWrap.accountName;
                config.Xero_Contact_Street_Address__c = cWrap.accountStreet;
                config.Xero_Contact_City__c = cWrap.accountCity;
                config.Xero_Contact_State__c = cWrap.accountState;
                config.Xero_Contact_ZipCode__c = cWrap.accountzipCode;
                config.Xero_Contact_Country__c = cWrap.accountCountry;
                config.Xero_Contact_Account_Phone__c = cWrap.accountPhone;
                config.KTXero__Create_Account_if_not_available__c = cWrap.accCreation;

                if(config.getSObjectType().getDescribe().isUpdateable() == true 
                && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_First_Name__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_Last_Name__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_Email__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_Account_Number__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_Account_Name__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_Street_Address__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_City__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_State__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_ZipCode__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_Account_Phone__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_Country__c.isUpdateable() == true){
                    database.SaveResult sr = database.update(config);
                    if(sr.isSuccess()){
                        updated = true;
                    }else{
                        updated = false;
                    }
                }

            }
        } catch (Exception e) {
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return updated;
    }
    
    /**
     * @description Method to update record of KTXero__Xero_Metadata__c object
     * @return Boolean
     * @param metaId
     * @param selectedVal
    */
    @AuraEnabled
    public static Boolean saveMetadata(String metaId, String selectedVal, String selectedValLabel){
        Boolean updated = false;
        try {   
            KTXero__Xero_Metadata__c xm = new KTXero__Xero_Metadata__c();
            xm.Id = metaId.escapeHtml4();
            xm.KTXero__Code__c = selectedVal.escapeHtml4();
            xm.KTXero__Xero_Id__c = selectedValLabel.escapeHtml4();
            if(xm.getSObjectType().getDescribe().isUpdateable() == true && Schema.sObjectType.KTXero__Xero_Metadata__c.fields.KTXero__Xero_Id__c.isUpdateable() && Schema.sObjectType.KTXero__Xero_Metadata__c.fields.KTXero__Code__c.isUpdateable() == true){
                
                database.SaveResult sr = database.update(xm);
                if(sr.isSuccess()){
                    updated = true;
                }else{
                    updated = false;
                }
            }

        } catch (Exception e) {
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return updated;
    }

    /**
     * @description Method to get fields of passed sObject
     * @return List<Picklistwrapper>
     * @param sObjectType
    */
    @AuraEnabled
    public static List<Picklistwrapper> getFieldMap(String sObjectType) {
        List<Picklistwrapper> options = new List<Picklistwrapper>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType targetType = schemaMap.get(sObjectType);
        Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
        for(String fieldName : fieldMap.keySet()){
            String apiName = fieldMap.get(fieldName).getDescribe().getName();
            if(String.isNotBlank(apiName) ){
                options.add(new Picklistwrapper(fieldMap.get(fieldName).getDescribe().getLabel(), apiName, String.ValueOF(fieldMap.get(fieldName).getDescribe().getType()) ));
            }
        }
        return options;
    }

    /**
     * @description Wrapper class for KTXero__Invoice_Configuration_Options__c
    */
    public class InvoiceConfigWrapper{
        @AuraEnabled public String id;
        @AuraEnabled public boolean draft;
        @AuraEnabled public boolean submit;
        @AuraEnabled public boolean approved;
        @AuraEnabled public boolean approvedEmail;
        @AuraEnabled public String taxRate;
        @AuraEnabled public String accCode;
        @AuraEnabled public String invtaxType;
        @AuraEnabled public String invTemplate;

        //INVOICE FIELDS FROM THE OPPORTUNITY
        @AuraEnabled public String invoiceReference;
        @AuraEnabled public String invoiceDueDate;
        @AuraEnabled public String invoiceDate;
        @AuraEnabled public String lineItemDescription;
        @AuraEnabled public List<Picklistwrapper> opportunityFieldMap;
        
        //Product Creation fields
        @AuraEnabled public Boolean createItem;
        @AuraEnabled public Boolean createProduct;
        
    }
    
    /**
     * @description Wrapper Class for KTXero__Xero_Contact_Configurations__c custom setting
    */
    public class XeroConWrapper{
        /**
         * @description This variable will hold value of Id from Xero Metadata Record
        */
        @AuraEnabled public String id;
        /**
         * @description This variable will hold value of KTXero__Xero_Contact_First_Name__c from Xero Metadata Record
        */
        @AuraEnabled public String firstName;
        /**
         * @description This variable will hold value of KTXero__Xero_Contact_Last_Name__c from Xero Metadata Record
        */
        @AuraEnabled public String lastName;
        /**
         * @description This variable will hold value of KTXero__Xero_Contact_Email__c from Xero Metadata Record
        */
        @AuraEnabled public String email;
        /**
         * @description This variable will hold value of KTXero__Xero_Contact_Account_Number__c from Xero Metadata Record
        */
        @AuraEnabled public String accountNumber;        
        /**
         * @description This variable will hold value of KTXero__Xero_Contact_Account_Name__c from Xero Metadata Record
        */
        @AuraEnabled public String accountName;        
        /**
         * @description This variable will hold value of Xero_Contact_Street_Address__c from Xero Metadata Record
        */
        @AuraEnabled public String accountStreet;        
        /**
         * @description This variable will hold value of KTXero__Xero_Contact_City__ from Xero Metadata Record
        */
        @AuraEnabled public String accountCity;        
        /**
         * @description This variable will hold value of Xero_Contact_State__c from Xero Metadata Record
        */
        @AuraEnabled public String accountState;        
        /**
         * @description This variable will hold value of Xero_Contact_ZipCode__c from Xero Metadata Record
        */
        @AuraEnabled public String accountzipCode;        
        /**
         * @description This variable will hold value of Xero_Contact_Country__c from Xero Metadata Record
        */
        @AuraEnabled public String accountCountry;        
        /**
         * @description This variable will hold value of Xero_Contact_Account_Phone__c from Xero Metadata Record
        */
        @AuraEnabled public String accountPhone;       
        /**
         * @description This variable will hold value of KTXero__Create_Account_if_not_available__c from Custom setting
        */
        @AuraEnabled public Boolean accCreation;       
    }

    /**
     * @description Wrapper Class for Xero_Metadata__c Object
    */
    public class XeroMetadataWrapper{
        /**
         * @description This variable will hold value of Id from Xero Metadata Record
        */
        @AuraEnabled public String id {get;set;}
        /**
         * @description This variable will hold value of Name from Xero Metadata Record
        */
        @AuraEnabled public String name {get;set;}
        /**
         * @description This variable will hold value of KTXero__Code__c from Xero Metadata Record
        */
        @AuraEnabled public String code {get;set;}
        /**
         * @description This variable will hold value of KTXero__Number_Code__c from Xero Metadata Record
        */
        @AuraEnabled public String numberCode {get;set;}
        /**
         * @description This variable will hold value of IsDeleted from Xero Metadata Record
        */
        @AuraEnabled public Boolean isDeleted {get;set;}
        /**
         * @description This variable will hold value of KTXero__Status__c  from Xero Metadata Record
        */
        @AuraEnabled public String status {get;set;}
        /**
         * @description This variable will hold value of KTXero__Text__c from Xero Metadata Record
        */
        @AuraEnabled public String text {get;set;}
        /**
         * @description This variable will hold value of KTXero__Type__c from Xero Metadata Record
        */
        @AuraEnabled public String type {get;set;}
        /**
         * @description This variable will hold value of KTXero__Value__c from Xero Metadata Record
        */
        @AuraEnabled public String value {get;set;}
        /**
         * @description This variable will hold value of KTXero__Xero_Id__c from Xero Metadata Record
        */
        @AuraEnabled public String xeroId {get;set;}
        /**
         * @description This variable will hold value of KTXero__Xero_Org_ID__c from Xero Metadata Record
        */
        @AuraEnabled public String xeroOrgID {get;set;}
    }

    /**
     * @description Wrapper class for picklistValues
    */
    public class Picklistwrapper {
        /**
         * @description This variable will hold field label
        */
        @AuraEnabled public String label { get; set; }
        /**
         * @description This variable will hold field value
        */
        @AuraEnabled public String value { get; set; }
        /**
         * @description This variable will hold field Type
        */
        @AuraEnabled public String fieldType { get; set; }
        
        /**
         * @description Constructor of Picklistwrapper
         * @param label
         * @param value
         * @param fieldType
        */
        public Picklistwrapper(String label, String value, String fieldType) {
            this.label = label;
            this.value = value;
            this.fieldType = fieldType;
        }
    }

     /**
     * @description Method to keep tax rates in sync with Xero
     * @description Removing KTXero__Number_Code__c FROM SOQL and adding KTXero__Account_Code__c|| Yash Patel || 7 May 2024
     * @return XeroMetadataSyncWrapper
    */
    @AuraEnabled
    public static XeroSyncController.XeroMetadataSyncWrapper xeroTaxRateSync(){
        List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
        Boolean successFlag = false;
        List<Xero_Metadata__c> xmList = new List<Xero_Metadata__c>();
        List<Xero_Metadata__c> xmUpdateList = new List<Xero_Metadata__c>();
        Map<String, String> metadataMap = new Map<String, String>();
        XeroSyncController.XeroMetadataSyncWrapper xmWrap = new XeroSyncController.XeroMetadataSyncWrapper();
        try{
            // get Xero Tax Rate
            xmList = [SELECT Id, Value__c, Type__c, Text__c, Code__c, Xero_Id__c, Status__c, KTXero__Account_Code__c, Name FROM Xero_Metadata__c WHERE Type__c = 'TaxRate' WITH SECURITY_ENFORCED];
            if(xmList.size()>0){
                for(Xero_Metadata__c xm : xmList){
                    metadataMap.put(xm.Code__c,xm.Id);
                }
            }

            // fetch xero tax rate from Xero
            if(xeroConnect != null){
                Boolean flag = Utils.checkTokenExpiry(xeroConnect.KTXero__Last_Token_Refresh_Time__c);
                KTXero__Xero_Connection__c connection = new KTXero__Xero_Connection__c();
                Map<String, String> headerMap = new Map<String, String>();
                if(flag){
                    headerMap.put('xero-tenant-id',String.isNotBlank(Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c)) ? Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c) : '');
                    headerMap.put('authorization',String.isNotBlank(Utils.processDecryption(xeroConnect.KTXero__Access_Token__c)) ? 'Bearer '+Utils.processDecryption(xeroConnect.KTXero__Access_Token__c) : '');
                }else{
                    connection = Utils.refreshToken();
                    headerMap.put('xero-tenant-id',String.isNotBlank(Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c)) ? Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c) : '');
                    headerMap.put('authorization',String.isNotBlank(Utils.processDecryption(connection.KTXero__Access_Token__c)) ? 'Bearer '+Utils.processDecryption(connection.KTXero__Access_Token__c) : '');
                }
                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/TaxRates', headerMap, 'GET', '');
               
                HttpResponse response = callObj.response;
                logList.add(callObj.exc);
    
    
                if(response.getStatusCode() == 200){
                    InvoiceCreationWrapper.TaxrateWrapper taxwrap = (InvoiceCreationWrapper.TaxrateWrapper)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.TaxrateWrapper.class);
                    for(InvoiceCreationWrapper.TaxRates tr : taxwrap.TaxRates){
                        Xero_Metadata__c xm = new Xero_Metadata__c();
                        if(metadataMap.containsKey(tr.TaxType)){
                            xm.Id = metadataMap.get(tr.TaxType);
                            metadataMap.remove(tr.TaxType);
                        }
                        xm.Type__c = 'TaxRate';
                        xm.Value__c = String.ValueOf(tr.EffectiveRate);
                        xm.Text__c = tr.Name;
                        xm.Code__c = tr.TaxType;
                        xm.Status__c = tr.Status;
                        xmUpdateList.add(xm);
                    }
    
                    if(!flag && connection != null){
                        FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                        List<KTXero__Xero_Connection__c> xconnectionList = new List<KTXero__Xero_Connection__c>();
                        xconnectionList.add(connection);

                        flsWrap = FLSChecker.dmlUpdate(xconnectionList);
                        if(!flsWrap.isSuccess){
                            throw new AuraHandledException(flsWrap.message);
                        }
                    }

                    if(xmUpdateList.size() > 0){

                        FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                        flsWrap = FLSChecker.dmlUpsert(xmUpdateList);
                        if(!flsWrap.isSuccess){
                            throw new AuraHandledException(flsWrap.message);
                        }else{
                            successFlag = true;
                        }
                    }
    
                    // Delete Tax Rate Records if not identified in Xero and still present in Salesforce
                    if(metadataMap.keySet().size()>0){
                        List<Xero_Metadata__c> taxratedeleteList = new List<Xero_Metadata__c>(); 
                        for(String s : metadataMap.keySet()){
                            Xero_Metadata__c xm = new Xero_Metadata__c();
                            xm.Id = metadataMap.get(s);
                            taxratedeleteList.add(xm);
                        }
    
                        if(taxratedeleteList.size() > 0){

                            FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                            flsWrap = FLSChecker.dmlDelete(taxratedeleteList);
                            if(!flsWrap.isSuccess){
                                throw new AuraHandledException(flsWrap.message);
                            }else{
                                successFlag = true;
                            }
                        }
                    }
                }
    
                if(successFlag && xmUpdateList.size()>0){
                    xmWrap.successFlag = successFlag;
                    List<InvoiceConfigurationController.XeroMetadataWrapper> xeroMetadataWrapper = new List<InvoiceConfigurationController.XeroMetadataWrapper>();
                    for(Xero_Metadata__c xm : xmUpdateList){
                        InvoiceConfigurationController.XeroMetadataWrapper xmw = new InvoiceConfigurationController.XeroMetadataWrapper(); 
                        xmw.id = xm.Id;
                        xmw.name = xm.Name;
                        xmw.code = xm.Code__c;
                        //Commenting Number_Code__c (Number) as it is replaced with now with new KTXero__Account_Code__c (String) field
                        // xmw.numberCode = xm.Number_Code__c;
                        xmw.numberCode = xm.KTXero__Account_Code__c;
                        xmw.isDeleted = xm.IsDeleted;
                        xmw.status = xm.Status__c;
                        xmw.text = xm.Text__c;
                        xmw.type = xm.Type__c;
                        xmw.value = xm.Value__c;
                        xmw.xeroId = xm.Xero_Id__c;
                        xmw.xeroOrgID = xm.Xero_Org_ID__c;
                        xeroMetadataWrapper.add(xmw);
                    }
                    xmWrap.metadataList = xeroMetadataWrapper; 
                }
                if(logList.size() > 0 ){
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    flsWrap = FLSChecker.dmlInsert(logList);
                    if(!flsWrap.isSuccess){
                        throw new AuraHandledException(flsWrap.message);
                    }
                }
            }
        }catch(System.Exception e){
            if(logList.size() > 0 ){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    throw new AuraHandledException(flsWrap.message);
                }
            }
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return xmWrap;
    }

     /**
     * @description Method to keep Invoice templates in sync with Xero
     * @description Removing KTXero__Number_Code__c FROM SOQL and adding KTXero__Account_Code__c|| Yash Patel || 7 May 2024z
     * @return XeroSyncControllerXeroMetadataSyncWrapper
    */
    @AuraEnabled
    public static XeroSyncController.XeroMetadataSyncWrapper xeroInvoiceTemplateSync(){
        List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
        Boolean successFlag = false;
        List<Xero_Metadata__c> xmList = new List<Xero_Metadata__c>();
        List<Xero_Metadata__c> xmUpdateList = new List<Xero_Metadata__c>();
        Map<String, String> metadataMap = new Map<String, String>();
        XeroSyncController.XeroMetadataSyncWrapper xmWrap = new XeroSyncController.XeroMetadataSyncWrapper();
        try{
            // get Xero Invoice Templates
            xmList = [SELECT Id, Value__c, Type__c, Text__c, Code__c, Xero_Id__c, Status__c, KTXero__Account_Code__c, Name FROM Xero_Metadata__c WHERE Type__c = 'Invoice Template' WITH SECURITY_ENFORCED];
            if(xmList.size()>0){
                for(Xero_Metadata__c xm : xmList){
                    metadataMap.put(xm.Value__c,xm.Id);
                }
            }

            // fetch xero tax rate from Xero
            if(xeroConnect != null){
                Boolean flag = Utils.checkTokenExpiry(xeroConnect.KTXero__Last_Token_Refresh_Time__c);
                KTXero__Xero_Connection__c connection = new KTXero__Xero_Connection__c();
                Map<String, String> headerMap = new Map<String, String>();
                if(flag){
                    headerMap.put('xero-tenant-id',String.isNotBlank(Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c)) ? Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c) : '');
                    headerMap.put('authorization',String.isNotBlank(Utils.processDecryption(xeroConnect.KTXero__Access_Token__c)) ? 'Bearer '+Utils.processDecryption(xeroConnect.KTXero__Access_Token__c) : '');
                }else{
                    connection = Utils.refreshToken();
                    headerMap.put('xero-tenant-id',String.isNotBlank(Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c)) ? Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c) : '');
                    headerMap.put('authorization',String.isNotBlank(Utils.processDecryption(connection.KTXero__Access_Token__c)) ? 'Bearer '+Utils.processDecryption(connection.KTXero__Access_Token__c) : '');
                }
                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/BrandingThemes', headerMap, 'GET', '');
                
                HttpResponse response = callObj.response;
                logList.add(callObj.exc);
    
                if(response.getStatusCode() == 200){
                    InvoiceCreationWrapper.BrandingthemeWrapper templateswrap = (InvoiceCreationWrapper.BrandingthemeWrapper)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.BrandingthemeWrapper.class);
                    for(InvoiceCreationWrapper.BrandingThemes bt : templateswrap.BrandingThemes){
                        Xero_Metadata__c xm = new Xero_Metadata__c();
                        if(metadataMap.containsKey(bt.BrandingThemeID)){
                            xm.Id = metadataMap.get(bt.BrandingThemeID);
                            metadataMap.remove(bt.BrandingThemeID);
                        }
                        xm.Type__c = 'Invoice Template';
                        xm.Value__c = bt.BrandingThemeID;
                        xm.Text__c = bt.Name;
                        xmUpdateList.add(xm);
                    }

                    if(!flag && connection != null){
                        // Database.update(connection);
                        FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                        List<KTXero__Xero_Connection__c> xconnectionList = new List<KTXero__Xero_Connection__c>();
                        xconnectionList.add(connection);

                        flsWrap = FLSChecker.dmlUpdate(xconnectionList);
                        if(!flsWrap.isSuccess){
                            throw new AuraHandledException(flsWrap.message);
                        }
                    }
                    if(xmUpdateList.size() > 0){
                        
                        FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                        flsWrap = FLSChecker.dmlUpsert(xmUpdateList);
                        if(!flsWrap.isSuccess){
                            throw new AuraHandledException(flsWrap.message);
                        }else{
                            successFlag = true;
                        }
                    }

    
                    // Delete Invoice Templates Records if not identified in Xero and still present in Salesforce
                    if(metadataMap.keySet().size()>0){
                        List<Xero_Metadata__c> xmdeleteList = new List<Xero_Metadata__c>(); 
                        for(String s : metadataMap.keySet()){
                            Xero_Metadata__c xm = new Xero_Metadata__c();
                            xm.Id = metadataMap.get(s);
                            xmdeleteList.add(xm);
                        }
                        if(xmdeleteList.size() > 0){
                            FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                            flsWrap = FLSChecker.dmlDelete(xmdeleteList);
                            if(!flsWrap.isSuccess){
                                throw new AuraHandledException(flsWrap.message);
                            }else{
                                successFlag = true;
                            }
                        }

                    }
                }
    
                if(successFlag && xmUpdateList.size()>0){
                    xmWrap.successFlag = successFlag; 
                    List<InvoiceConfigurationController.XeroMetadataWrapper> xeroMetadataWrapper = new List<InvoiceConfigurationController.XeroMetadataWrapper>();
                    for(Xero_Metadata__c xm : xmUpdateList){
                        InvoiceConfigurationController.XeroMetadataWrapper xmw = new InvoiceConfigurationController.XeroMetadataWrapper(); 
                        xmw.id = xm.Id;
                        xmw.name = xm.Name;
                        xmw.code = xm.Code__c;
                        //Commenting Number_Code__c (Number) as it is replaced with now with new KTXero__Account_Code__c (String) field
                        // xmw.numberCode = xm.Number_Code__c;
                        xmw.numberCode = xm.KTXero__Account_Code__c;
                        xmw.isDeleted = xm.IsDeleted;
                        xmw.status = xm.Status__c;
                        xmw.text = xm.Text__c;
                        xmw.type = xm.Type__c;
                        xmw.value = xm.Value__c;
                        xmw.xeroId = xm.Xero_Id__c;
                        xmw.xeroOrgID = xm.Xero_Org_ID__c;
                        xeroMetadataWrapper.add(xmw);
                    }
                    xmWrap.metadataList = xeroMetadataWrapper; 
                }
                if(logList.size() > 0 ){
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    flsWrap = FLSChecker.dmlInsert(logList);
                    if(!flsWrap.isSuccess){
                        throw new AuraHandledException(flsWrap.message);
                    }
                }
            }
        }catch(System.Exception e){
            if(logList.size() > 0 ){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    throw new AuraHandledException(flsWrap.message);
                }
            }
          KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return xmWrap;
    }

     /**
     * @description Method to keep tracking category in sync with Xero
     * @description Removing KTXero__Number_Code__c FROM SOQL and adding KTXero__Account_Code__c|| Yash Patel || 7 May 2024z 
     * @return XeroSyncController.XeroMetadataSyncWrapper
    */
    @AuraEnabled
    public static XeroSyncController.XeroMetadataSyncWrapper xeroTrackingCategorySync(){
        List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
        Boolean successFlag = false;
        List<Xero_Metadata__c> xmList = new List<Xero_Metadata__c>();
        List<Xero_Metadata__c> xmUpdateList = new List<Xero_Metadata__c>();
        Map<String, String> metadataMap = new Map<String, String>();
        XeroSyncController.XeroMetadataSyncWrapper xmWrap = new XeroSyncController.XeroMetadataSyncWrapper();
        try{
            // get Xero Tracking Category
            xmList = [SELECT Id, Name, KTXero__Account_Code__c, Text__c, Type__c, Value__c, Code__c, Xero_Id__c, Status__c FROM Xero_Metadata__c WHERE Type__c = 'tracking_category' OR Type__c = 'tracking_category_option' WITH SECURITY_ENFORCED];
            if(xmList.size()>0){
                for(Xero_Metadata__c xm : xmList){
                    metadataMap.put(xm.KTXero__Value__c,xm.Id);
                }
            }

            // fetch xero tracking categories from Xero
            if(xeroConnect != null){
                Boolean flag = Utils.checkTokenExpiry(xeroConnect.KTXero__Last_Token_Refresh_Time__c);
                KTXero__Xero_Connection__c connection = new KTXero__Xero_Connection__c();
                Map<String, String> headerMap = new Map<String, String>();
                if(flag){
                    headerMap.put('xero-tenant-id',String.isNotBlank(Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c)) ? Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c) : '');
                    headerMap.put('authorization',String.isNotBlank(Utils.processDecryption(xeroConnect.KTXero__Access_Token__c)) ? 'Bearer '+Utils.processDecryption(xeroConnect.KTXero__Access_Token__c) : '');
                }else{
                    connection = Utils.refreshToken();
                    headerMap.put('xero-tenant-id',String.isNotBlank(Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c)) ? Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c) : '');
                    headerMap.put('authorization',String.isNotBlank(Utils.processDecryption(connection.KTXero__Access_Token__c)) ? 'Bearer '+Utils.processDecryption(connection.KTXero__Access_Token__c) : '');
                }
                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/TrackingCategories', headerMap, 'GET', '');
                
                HttpResponse response = callObj.response;
                logList.add(callObj.exc);
    
    
                if(response.getStatusCode() == 200){
                    InvoiceCreationWrapper.TrackingWrapper trackWrap = (InvoiceCreationWrapper.TrackingWrapper)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.TrackingWrapper.class);
                    if(trackWrap.TrackingCategories.size() > 0){
                        for(InvoiceCreationWrapper.TrackingCategories tc : trackWrap.TrackingCategories){
                            Xero_Metadata__c xmc = new Xero_Metadata__c();
                            if(metadataMap.containskey(tc.TrackingCategoryID)){
                                xmc.Id = metadataMap.get(tc.TrackingCategoryID);
                                metadataMap.remove(tc.TrackingCategoryID);
                            }
                            xmc.KTXero__Type__c = 'tracking_category';
                            xmc.KTXero__Value__c = tc.TrackingCategoryID;
                            xmc.KTXero__Text__c = tc.Name;
                            xmc.KTXero__Status__c = tc.Status;
                            xmUpdateList.add(xmc);
                            for(InvoiceCreationWrapper.Options opt : tc.Options){
                                Xero_Metadata__c xmcOpt = new Xero_Metadata__c();
                                if(metadataMap.containskey(opt.TrackingOptionID)){
                                    xmcOpt.Id = metadataMap.get(opt.TrackingOptionID);
                                    metadataMap.remove(opt.TrackingOptionID);
                                }
                                xmcOpt.KTXero__Text__c = opt.Name;
                                xmcOpt.KTXero__Type__c = 'tracking_category_option';
                                xmcOpt.KTXero__Value__c = opt.TrackingOptionID;
                                xmcOpt.KTXero__Code__c = tc.Name;
                                xmcOpt.KTXero__Xero_Id__c = tc.TrackingCategoryID;
                                xmcOpt.KTXero__Status__c = opt.Status;
                                xmUpdateList.add(xmcOpt);
                            }
                        }
        
                        if(!flag && connection != null){
                            // Database.update(connection);
                            FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                            List<KTXero__Xero_Connection__c> xconnectionList = new List<KTXero__Xero_Connection__c>();
                            xconnectionList.add(connection);

                            flsWrap = FLSChecker.dmlUpdate(xconnectionList);
                            if(!flsWrap.isSuccess){
                                throw new AuraHandledException(flsWrap.message);
                            }
                        }

                        // Upsert Tracking Categories
                        if(xmUpdateList.size() > 0){
                            FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                            flsWrap = FLSChecker.dmlUpsert(xmUpdateList);
                            if(!flsWrap.isSuccess){
                                throw new AuraHandledException(flsWrap.message);
                            }else{
                                successFlag = true;
                            }
                        }
                    }
    
                    // Delete accounts Records if not identified in Xero and still present in Salesforce
                    if(metadataMap.keySet().size()>0){
                        List<Xero_Metadata__c> xmdeleteList = new List<Xero_Metadata__c>(); 
                        for(String s : metadataMap.keySet()){
                            Xero_Metadata__c xm = new Xero_Metadata__c();
                            xm.Id = metadataMap.get(s);
                            xmdeleteList.add(xm);
                        }
    
                        if(Schema.sObjectType.Xero_Metadata__c.isDeletable()){

                            Database.DeleteResult[] drList = Database.delete(xmdeleteList);
                            for(Database.DeleteResult dr : drList) {
                                if (dr.isSuccess()) {
                                    successFlag = true;
                                    continue;
                                }else {
                                    successFlag = false;
                                    break;
                                }
                            }
                        }
                    }
                }
    
                if(successFlag && xmUpdateList.size()>0){
                    xmWrap.successFlag = successFlag; 
                    List<InvoiceConfigurationController.XeroMetadataWrapper> xeroMetadataWrapper = new List<InvoiceConfigurationController.XeroMetadataWrapper>();
                    List<Xero_Metadata__c> xeroMetadataList = [SELECT Id, Name, Code__c, KTXero__Account_Code__c, IsDeleted, Status__c, SystemModstamp, Text__c, Type__c, Value__c, Xero_Id__c, Xero_Org_ID__c FROM Xero_Metadata__c WHERE Id IN: xmUpdateList WITH SECURITY_ENFORCED];
                    for(Xero_Metadata__c xm : xeroMetadataList){
                        InvoiceConfigurationController.XeroMetadataWrapper xmw = new InvoiceConfigurationController.XeroMetadataWrapper(); 
                        xmw.id = xm.Id;
                        xmw.name = xm.Name;
                        xmw.code = xm.Code__c;
                        //Commenting Number_Code__c (Number) as it is replaced with now with new KTXero__Account_Code__c (String) field
                        // xmw.numberCode = xm.Number_Code__c;
                        xmw.numberCode = xm.KTXero__Account_Code__c;
                        xmw.isDeleted = xm.IsDeleted;
                        xmw.status = xm.Status__c;
                        xmw.text = xm.Text__c;
                        xmw.type = xm.Type__c;
                        xmw.value = xm.Value__c;
                        xmw.xeroId = xm.Xero_Id__c;
                        xmw.xeroOrgID = xm.Xero_Org_ID__c;
                        xeroMetadataWrapper.add(xmw);
                    }
                    xmWrap.metadataList = xeroMetadataWrapper; 
                }else{
                    xmWrap.message = 'Tracking Categories not found';
                }

                if(logList.size() > 0 ){
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    flsWrap = FLSChecker.dmlInsert(logList);
                    if(!flsWrap.isSuccess){
                        throw new AuraHandledException(flsWrap.message);
                    }
                }
            }
        }catch (Exception e) {
            if(logList.size() > 0 ){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    throw new AuraHandledException(flsWrap.message);
                }
            }
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return xmWrap;
    }

}