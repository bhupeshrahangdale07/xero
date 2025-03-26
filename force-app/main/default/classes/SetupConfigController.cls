/**
     * @description Class to manage setup and configuration options for authentication wiith Salesforce, Page layouts, permission sets & webhook setup
     * @Author : Kandisa Technologies
     * @CreatedDate : 22 May 2023
*/
public with sharing class SetupConfigController {
    
    /**
     * @description Method to fetch Xero connection data
     * @return XeroConnectionWrap
    */
    @AuraEnabled
    public static XeroConnectionWrap getXeroConnection(){
        XeroConnectionWrap xcwrap = new XeroConnectionWrap();
        List<KTXero__Xero_Connection__c> xeroConnect = new List<KTXero__Xero_Connection__c>();
        try {
            xeroConnect = [SELECT Id, Name, KTXero__Client_Id__c, KTXero__Client_Secret__c,KTXero__Tenant_Id__c, 
                            KTXero__Completed_Steps__c, KTXero__Completed_Xero_Connection_Steps__c, 
                            KTXero__Progress_Value__c, KTXero__Total_Xero_Connection_Steps__c, 
                            KTXero__Authenticated__c, KTXero__Webhook_Key__c FROM KTXero__Xero_Connection__c WITH SECURITY_ENFORCED LIMIT 1];
            if(xeroConnect.size() > 0){
                xcwrap.id = xeroConnect[0].Id;
                xcwrap.clientId = Utils.processDecryption(xeroConnect[0].KTXero__Client_Id__c);
                xcwrap.clientSecret = Utils.processDecryption(xeroConnect[0].KTXero__Client_Secret__c);
                xcwrap.tenantId = Utils.processDecryption(xeroConnect[0].KTXero__Tenant_Id__c);
                xcwrap.completedSteps = xeroConnect[0].KTXero__Completed_Steps__c;
                xcwrap.progressValue = xeroConnect[0].KTXero__Progress_Value__c;
                xcwrap.totalConnectionSteps = xeroConnect[0].KTXero__Total_Xero_Connection_Steps__c;
                xcwrap.completedConnectionSteps = xeroConnect[0].KTXero__Completed_Xero_Connection_Steps__c;
                xcwrap.authenticated = xeroConnect[0].KTXero__Authenticated__c;
                xcwrap.webhookKey = Utils.processDecryption(xeroConnect[0].KTXero__Webhook_Key__c);
            }
        } catch (Exception e) {
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return xcwrap;
    }

    /**
     * @description Method to schedule refresh token
     * @return Boolean
    */
    @AuraEnabled
    public static Boolean scheduleRefreshToken(){
        Boolean flag = false;
        List<CronTrigger> cron = new List<CronTrigger>();
        Set<String> scheduleNames = new Set<String>{'TokenRefreshSchedule 1','TokenRefreshSchedule 2','TokenRefreshSchedule 3'};
        try {
            cron = [SELECT Id, CronJobDetailId, CronJobDetail.Name, CronJobDetail.JobType, 
                    NextFireTime, PreviousFireTime, State, StartTime, EndTime, CronExpression, CreatedDate,
                    TimesTriggered FROM CronTrigger WHERE CronJobDetail.Name IN: scheduleNames WITH SECURITY_ENFORCED];
            if(cron.size()>0){
                for(CronTrigger ct : cron){
                    System.abortJob(ct.Id);
                }
            }
            String jobID1 = System.schedule('TokenRefreshSchedule 1', '0 0 * * * ?', new TokenRefreshSchedule());
            String jobID2 = System.schedule('TokenRefreshSchedule 2', '0 20 * * * ?', new TokenRefreshSchedule());
            String jobID3 = System.schedule('TokenRefreshSchedule 3', '0 40 * * * ?', new TokenRefreshSchedule());
            if(String.isNotBlank(jobID1) && String.isNotBlank(jobID2) && String.isNotBlank(jobID3)){
                flag = true;
            }
        } catch (Exception e) {
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return flag;
    }
    /**
     * @description Method to fetch the list of Active Visualforce sites available in org 
     * @return List<SiteWrapper>
    */
    @AuraEnabled
    public static List<SiteWrapper> getSites(){
        List<Site> siteList = new List<Site>();
        List<SiteWrapper> siteWrapList = new List<SiteWrapper>();
        try{
            siteList = [SELECT Id, Name, Status, SiteType, GuestUserId, MasterLabel FROM Site WHERE Status = 'Active' AND SiteType = 'Visualforce' WITH SECURITY_ENFORCED];
            if(siteList.size()>0){
                for(Site s : siteList){
                    SiteWrapper sw = new SiteWrapper();
                    sw.id = s.Id;
                    sw.masterLabel = s.MasterLabel;
                    sw.guestUserId = s.GuestUserId;
                    siteWrapList.add(sw);
                }
            }
        }catch(Exception e){
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return siteWrapList;
    }

    /**
     * @description Method to fetch all the SecureSite URLs
     * @return String
     * @param siteId
    */
    @AuraEnabled
    public static string getSecureSiteURL(String siteId){
        String siteURL = '';
        SiteDetail sd = new SiteDetail();
        try {
            sd = [SELECT Id, DurableId, SecureUrl FROM SiteDetail WHERE DurableId =: siteId WITH SECURITY_ENFORCED];
            if(sd != null && String.isNotBlank(sd.SecureUrl)){
                siteURL = sd.SecureUrl;
                siteURL += 'services/apexrest/KTXero/Xerodetail';
            }
        } catch (Exception e) {
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return siteURL;
    }

    /**
     * @description Method to assign Xero Webhook Permission Set to Guest User
     * @return Boolean
     * @param guestId
    */
    @AuraEnabled
    public static Boolean assignWebhhokPermission(String guestId){
        
        Boolean flag = false;
        Set<Id> permissionSetIds = new Set<Id>();
        List<PermissionSet> pr = new List<PermissionSet>();
        try {
            
            pr = [SELECT Id, Label, Name FROM PermissionSet WHERE Name = 'Xero_Webhook_Permission_Set_for_Site_User' WITH SECURITY_ENFORCED LIMIT 1];
            
            if(pr.size() > 0){
                permissionSetIds.add(pr[0].Id);
                flag = true; 
            }else{
                List<PermissionSet> permList = new List<PermissionSet>();
                PermissionSet perm = new PermissionSet(Name='Xero_Webhook_Permission_Set_for_Site_User',Label='Xero Webhook Permission Set for Site User');
                permList.add(perm);

                FLSChecker.FLSCheckWrapper flsWrapPerm = FLSChecker.dmlInsert(permList);
                if(flsWrapPerm.isSuccess){
                    permissionSetIds.add(perm.Id);
                    flag = Utils.assignPermissions(perm.Id);
                }
            }
             
            if(flag && String.isNotBlank(guestId)){
                List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
                List<PermissionSetAssignment> psaNewList = new List<PermissionSetAssignment>();

                PermissionSet per = new PermissionSet();
                per = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Xero_Webhook_Guest_User_Permission_Set' WITH SECURITY_ENFORCED LIMIT 1];
                if(per != null){
                    permissionSetIds.add(per.Id);
                }

                if(permissionSetIds.size() > 0){
                    psaList = [SELECT Id, PermissionSetId, AssigneeId, IsActive FROM PermissionSetAssignment WHERE PermissionSetId =:permissionSetIds AND AssigneeId =: guestId WITH SECURITY_ENFORCED];
                    Set<Id> psaSet = new Set<Id>();
                    
                    for(PermissionSetAssignment psa : psaList){
                        psaSet.add(psa.PermissionSetId);
                    }
                    for(Id perId : permissionSetIds ){
                        if(!psaSet.contains(perId)){
                            PermissionSetAssignment psaNew = new PermissionSetAssignment();
                            psaNew.PermissionSetId = perId;
                            psaNew.AssigneeId = guestId;
                            psaNewList.add(psaNew);
                        }
                    }
                  
                }
                if(psaNewList.size() > 0){
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    flsWrap = FLSChecker.dmlInsert(psaNewList);
                    if(!flsWrap.isSuccess){
                        flag = false;
                        throw new AuraHandledException(flsWrap.message);
                    }else{
                        flag = true;
                    }
                
                }
            }
        } catch (Exception e) {
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return flag;
    }

    /**
     * @description Method to save Xero connection details
     * @return XeroConnectionResultWrap
     * @param connectWrap
    */
    @AuraEnabled
    public static XeroConnectionResultWrap saveXeroConnection(String connectWrap){
        XeroConnectionResultWrap xcr = new XeroConnectionResultWrap();
        XeroConnectionWrap xcwrap = new XeroConnectionWrap();
        KTXero__Xero_Connection__c xeroConnect = new KTXero__Xero_Connection__c();
        try {
            xcwrap = (XeroConnectionWrap)JSON.deserialize(connectWrap,XeroConnectionWrap.class);
            if(String.isNotBlank(xcwrap.id)){
                xeroConnect.Id = xcwrap.id;
            }
            xeroConnect.KTXero__Client_Id__c = Utils.processEncryption(xcwrap.clientId);
            xeroConnect.KTXero__Client_Secret__c = Utils.processEncryption(xcwrap.clientSecret);
            xeroConnect.KTXero__Tenant_Id__c = Utils.processEncryption(xcwrap.tenantId);
            xeroConnect.KTXero__Completed_Steps__c = xcwrap.completedSteps;
            xeroConnect.KTXero__Progress_Value__c = xcwrap.progressValue;
            xeroConnect.KTXero__Total_Xero_Connection_Steps__c = xcwrap.totalConnectionSteps;
            xeroConnect.KTXero__Completed_Xero_Connection_Steps__c = xcwrap.completedConnectionSteps;
            xeroConnect.KTXero__Authenticated__c = xcwrap.authenticated;
            xeroConnect.KTXero__Webhook_Key__c = Utils.processEncryption(xcwrap.webhookKey);
            // upsert Xero Connection
            if(KTXero__Xero_Connection__c.getSObjectType().getDescribe().isCreateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Client_Id__c.isCreateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Client_Secret__c.isCreateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Tenant_Id__c.isCreateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Completed_Steps__c.isCreateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Progress_Value__c.isCreateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Total_Xero_Connection_Steps__c.isCreateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Completed_Xero_Connection_Steps__c.isCreateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Authenticated__c.isCreateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Webhook_Key__c.isCreateable() == true
                
                && KTXero__Xero_Connection__c.getSObjectType().getDescribe().isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Client_Id__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Client_Secret__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Tenant_Id__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Completed_Steps__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Progress_Value__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Total_Xero_Connection_Steps__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Completed_Xero_Connection_Steps__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Authenticated__c.isUpdateable() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Webhook_Key__c.isUpdateable() == true){

                Database.UpsertResult sR = Database.upsert(xeroConnect);
                if(String.isBlank(xcwrap.id) && sR.isSuccess()){
                    xcwrap.id = sR.getId();
                }
                xcr.flag = sR.isSuccess();
                xcr.saveResult = xcwrap;
            }
        } catch (Exception e) {
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return xcr;
    }

    /**
     * @description Method to fetch Xero related PermissionSets
     * @return List<PermissionWrapper>
    */
    @AuraEnabled
    public static List<PermissionWrapper> fetchPermissionSets(){
        List<PermissionWrapper> permissionWrapList = new List<PermissionWrapper>();
        List<PermissionSet> permissionList = new List<PermissionSet>();
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        try{
            permissionList = [SELECT Id, Name, Label, Type, Description, CreatedDate FROM PermissionSet WHERE Name IN ('Xero_Integration_User_Read_Only','Xero_Integration_Operational','Xero_Integration_Admin') WITH SECURITY_ENFORCED];
            if(permissionList.size()>0){
                for(PermissionSet p : permissionList){
                    PermissionWrapper pw = new PermissionWrapper();
                    pw.id = p.Id;
                    pw.name = p.Name;
                    pw.setupUrl = baseUrl + '/lightning/setup/PermSets/'+p.Id+'/PermissionSetAssignment/home';
                    permissionWrapList.add(pw);
                }
            }
        } catch (Exception e) {
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return permissionWrapList;
    }


    /**
     * @description Method to fetch all the Tenants from Xero
     * @return List<TenantWrapper>
    */
    @AuraEnabled
    public static List<TenantWrapper> getTenants(){
        List<KTXero__Log__c> logList = new list<KTXero__Log__c>();

        List<TenantWrapper> twList = new List<TenantWrapper>();
        try {
            KTXero__Xero_Connection__c xeroConnect = [SELECT Id, KTXero__Access_Token__c, KTXero__Refresh_Token__c, KTXero__Tenant_Id__c, KTXero__Last_Token_Refresh_Time__c FROM KTXero__Xero_Connection__c WITH SECURITY_ENFORCED LIMIT 1];
            if(xeroConnect != null){
                Boolean flag = Utils.checkTokenExpiry(xeroConnect.KTXero__Last_Token_Refresh_Time__c);
                KTXero__Xero_Connection__c connection = new KTXero__Xero_Connection__c();
                Map<String, String> headerMap = new Map<String, String>();
                if(flag){
                    headerMap.put('xero-tenant-id',String.isNotBlank(xeroConnect.KTXero__Tenant_Id__c) ? Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c) : '');
                    headerMap.put('authorization',String.isNotBlank(xeroConnect.KTXero__Access_Token__c) ? 'Bearer '+Utils.processDecryption(xeroConnect.KTXero__Access_Token__c) : '');
                }else{
                    connection = Utils.refreshToken();
                    headerMap.put('xero-tenant-id',String.isNotBlank(xeroConnect.KTXero__Tenant_Id__c) ? Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c) : '');
                    headerMap.put('authorization',String.isNotBlank(connection.KTXero__Access_Token__c) ? 'Bearer '+Utils.processDecryption(connection.KTXero__Access_Token__c) : '');
                }
                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/connections', headerMap, 'GET', '');
                HttpResponse response = callObj.response;
                logList.add(callObj.exc);
    
                if(response.getStatusCode() == 200){
                    List<TenantResponseWrap> tList = (List<TenantResponseWrap>)JSON.deserialize(response.getBody(),List<TenantResponseWrap>.class);
                    for(TenantResponseWrap rw : tList){
                        TenantWrapper tw = new TenantWrapper();
                        tw.tenantName = rw.tenantName;
                        tw.tenantId = rw.tenantId;
                        twList.add(tw);
                    }
                }
                if(logList.size() > 0 ){
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    flsWrap = FLSChecker.dmlInsert(logList);
                    if(!flsWrap.isSuccess){
                        throw new AuraHandledException(flsWrap.message);
                    }
                }
                if(!flag && connection != null){
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    List<KTXero__Xero_Connection__c> xcList = new List<KTXero__Xero_Connection__c>();
                    xcList.add(connection);

                    flsWrap = FLSChecker.dmlUpdate(xcList);
                    if(!flsWrap.isSuccess){
                        throw new AuraHandledException(flsWrap.message);
                    }
                }
            }   
        }catch(Exception e) {
            
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return twList;
    }

    /**
     * @description Wrapper Class to manage permissionset data
     * @Author : Kandisa Technologies
    */
    public class PermissionWrapper{
        @AuraEnabled public String id ;
        @AuraEnabled public String name ;
        @AuraEnabled public String setupUrl ;
    }

    /**
     * @description Wrapper Class to manage Tenant data
     * @Author : Kandisa Technologies
    */
    public class TenantWrapper{
        @AuraEnabled public String tenantName ;
        @AuraEnabled public String tenantId ;
    }

    /**
     * @description Wrapper Class to manage Tenant details
     * @Author : Kandisa Technologies
    */
    public class TenantResponseWrap{
        public String id;
		public String authEventId;
		public String tenantId;
		public String tenantType;
		public String tenantName;
		public String createdDateUtc;
		public String updatedDateUtc;
    }

    /**
     * @description Wrapper Class to manage Xero Connection data
     * @Author : Kandisa Technologies
    */
    public class XeroConnectionWrap{
        @AuraEnabled public String id ;
        @AuraEnabled public String clientId ;
        @AuraEnabled public String clientSecret ;
        @AuraEnabled public String tenantId ;
        @AuraEnabled public String authURL ;
        @AuraEnabled public String webhookKey ;
        @AuraEnabled public Decimal completedSteps ;
        @AuraEnabled public Decimal progressValue ;
        @AuraEnabled public Decimal totalConnectionSteps ;
        @AuraEnabled public Decimal completedConnectionSteps ;
        @AuraEnabled public Boolean authenticated ;

        /**
         * @description Construtcor to initialize the variables
        */
        public XeroConnectionWrap(){
            id = '';
            clientId = '';
            clientSecret = '';
            tenantId = '';
            webhookKey = '';
            authURL = '/apex/KTXero__XeroOAuthPage';
            completedSteps = 0;
            progressValue = 0;
            totalConnectionSteps = 2;
            completedConnectionSteps = 0;
            authenticated = false;
        }
    }

    /**
     * @description Wrapper Class to manage Xero Connection results
     * @Author : Kandisa Technologies
    */
    public class XeroConnectionResultWrap{
        @AuraEnabled public Boolean flag ;
        @AuraEnabled public XeroConnectionWrap saveResult ;
    }

    /**
     * @description Wrapper Class to manage sites data
     * @Author : Kandisa Technologies
    */
    public class SiteWrapper{
        @AuraEnabled public String id;
        @AuraEnabled public String masterLabel;
        @AuraEnabled public String guestUserId;
    }
}