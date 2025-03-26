/**
@Author : Kandisa Technologies
@description : This class contains methods for Xero Bulk Sync.
*/
public with sharing class XeroBulkSyncController {
    
    /**
     * @description Method to start record syncing process from Xero to salesforce
     * @return Boolean
     * @param syncSetting            
    */
    @AuraEnabled
    public static Boolean startSync(String syncSetting){
        Boolean flag = false;
        SyncSettingWrap ssw = new SyncSettingWrap(); 
        try {
            ssw = (SyncSettingWrap)JSON.deserialize(syncSetting,SyncSettingWrap.class);

            KTXero__Xero_Bulk_Sync_Setting__c xbs = new KTXero__Xero_Bulk_Sync_Setting__c();
            xbs = [SELECT Id, Name, KTXero__Is_Filter_Sync__c, KTXero__Invoice_Statuses__c, KTXero__Invoice_Status_Operator__c, 
                    KTXero__Start_Date__c, KTXero__End_Date__c, KTXero__Link_Xero_Contact__c, KTXero__Create_Xero_Contact__c, 
                    KTXero__Map_Salesforce_Account__c, KTXero__Company_Name_mapping_field__c, KTXero__Account_Number_mapping_field__c, KTXero__Create_Account__c,
                    KTXero__Xero_Email_mapping_Object__c, KTXero__Xero_Email_mapping_field__c,KTXero__Is_InProgress__c, KTXero__Create_Product_in_Salesforce__c
                    FROM KTXero__Xero_Bulk_Sync_Setting__c
                    WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED];

            xbs.KTXero__Is_Filter_Sync__c = ssw.filterSync;
            xbs.KTXero__Invoice_Statuses__c = String.join(ssw.invoiceStatus, ',');
            xbs.KTXero__Invoice_Status_Operator__c = ssw.invStatusOperator;
            if(ssw.startDate != 'NaN/NaN/NaN'){
                xbs.KTXero__Start_Date__c = date.parse(ssw.startDate);
            }else{
                xbs.KTXero__Start_Date__c = null;
            }

            if(ssw.endDate != 'NaN/NaN/NaN'){
                xbs.KTXero__End_Date__c = date.parse(ssw.endDate);
            }else{
                xbs.KTXero__End_Date__c = null;
            }
            xbs.KTXero__Link_Xero_Contact__c = ssw.linkXC == 'Yes' ? true :false ;
            xbs.KTXero__Create_Xero_Contact__c = ssw.createCX == 'Yes' ? true :false ;
            xbs.KTXero__Map_Salesforce_Account__c = ssw.mapSfAcc == 'Yes' ? true :false ;
            xbs.KTXero__Create_Account__c = ssw.createAcc == 'Yes' ? true :false ;
            xbs.KTXero__Company_Name_mapping_field__c = ssw.xcCompanyNameMap;
            xbs.KTXero__Account_Number_mapping_field__c = ssw.xcAccNumberMap;
            xbs.KTXero__Xero_Email_mapping_Object__c = ssw.xcEmailMapRelatedTo;
            xbs.KTXero__Xero_Email_mapping_field__c = ssw.xcEmailMap;
            xbs.KTXero__Is_InProgress__c = true;
            xbs.KTXero__Create_Product_in_Salesforce__c = ssw.linkProd;

            List<KTXero__Xero_Bulk_Sync_Setting__c> xbsLilst = new List<KTXero__Xero_Bulk_Sync_Setting__c>();
            xbsLilst.add(xbs);

            FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
            flsWrap = FLSChecker.dmlUpsert(xbsLilst);

            if(!flsWrap.isSuccess){
                flag = false;
                throw new AuraHandledException(flsWrap.message);
            }else{
                String jobId = Database.executeBatch(new XeroBulkSyncBatch(1,new Set<Id>(),new Set<Id>(),new Set<Id>(),new Set<Id>()), 1);
                if(String.isNotBlank(jobId) && String.isNotEmpty(jobId)){
                    flag = true;
                }
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return flag;
    }

    @AuraEnabled
    public static KTXero__Xero_Bulk_Sync_Setting__c getCustomSettings(){
        KTXero__Xero_Bulk_Sync_Setting__c customSettingObj = new KTXero__Xero_Bulk_Sync_Setting__c();
        try {
            customSettingObj = KTXero__Xero_Bulk_Sync_Setting__c.getInstance();
        } catch (Exception e) {
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return customSettingObj;
    }

    /**
     * @description Method to check the batch status
     * @return String
     * @param batchName            
    */
    @AuraEnabled
    public static String checkBatchRunning(String batchName){
        String flag = 'false';
        try {
            List<AsyncApexJob> batchJob = [SELECT CreatedDate, JobItemsProcessed, Status, ExtendedStatus, 
                                           NumberOfErrors, CompletedDate, JobType, TotalJobItems, ApexClassId 
                                           FROM AsyncApexJob where ApexClass.Name=:batchName AND 
                                           Status IN ('Processing','Preparing','Queued') AND
                                           JobType='BatchApex' And CreatedDate = TODAY];
            
            flag = batchJob.size() > 0 ? 'true' : 'false';
            if(Test.isRunningTest()){
                throw new DMLException();
            }
        } catch (Exception e) {
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return flag;
    }

    /**
     * @description Method to execute the XeroBulkItemSyncBatch
     * @return Boolean           
    */
    @AuraEnabled
    public static Boolean startProductSync(){
        Boolean flag = false;
        try {
            ID batchprocessid = Database.executeBatch(new XeroBulkItemSyncBatch(),50);
            flag = batchprocessid != null ? true : false;
        } catch (Exception e) {
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return flag;
    }

    public class SyncSettingWrap{
        public boolean filterSync;
        public List<String> invoiceStatus;
        public String invStatusOperator;	//equals
        public String startDate;	//2024-04-10
        public String endDate;	//2024-04-24
        public String fltLogicVal;	//AND
        public String linkXC;	//Yes
        public String createCX;	//Yes
        public String createAcc;//Yes
        public String mapSfAcc;	//Yes
        public String xcCompanyNameMap;	//Name
        public String xcAccNumberMap;	//AccountNumber
        public String xcEmailMapRelatedTo;	//Contact
        public String xcEmailMap;	//Email
        public String linkProd;	//Email
    }

    public class ItemWrapper{
        public List<cls_Items> Items;
    }

    public class cls_Items {
		public String ItemID;	//8bbaf73c-5a32-4458-addf-bd30a36c8551
		public String Code;	//BOOK
		public String Description;	//'Fish out of Water: Finding Your Brand
		public String PurchaseDescription;	//'Fish out of Water: Finding Your Brand
		public String UpdatedDateUTC;	///Date(1716534642783+0000)/
		public cls_PurchaseDetails PurchaseDetails;
		public cls_SalesDetails SalesDetails;
		public String Name;	//Fish out of Water: Finding Your Brand
		// public boolean IsTrackedAsInventory;
		// public boolean IsSold;
		// public boolean IsPurchased;
	}
	
    public class cls_PurchaseDetails {
		// public Integer UnitPrice;	//0
		public String AccountCode;	//300
		public String COGSAccountCode;	//300
		public String TaxType;	//INPUT
	}

	public class cls_SalesDetails {
		// public Double UnitPrice;	//19.95
		public String AccountCode;	//200
		public String TaxType;	//OUTPUT
	}
}