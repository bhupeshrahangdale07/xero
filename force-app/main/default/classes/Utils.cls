/**
     * @description Util class to manage common methods
     * @Author : Kandisa Technologies
     * @CreatedDate : 01 March 2023 
*/
public with sharing class Utils {
 
    /**
     * @description Method to Incrypt a data
     * @param decryptedData
     * @return String
    */
    public static String processEncryption(String decryptedData){ 

        String b64Data = '';
        String expMsg = '';
        try{
            
            if(String.isNotBlank(decryptedData)){
                KTXero__Encryption_Configuration__c setting = KTXero__Encryption_Configuration__c.getOrgDefaults();
                String strKey = setting.KTXero__Encryption_Key__c;
                Blob cryptoKey = EncodingUtil.base64Decode(strKey);
        
        
                Blob data = Blob.valueOf(decryptedData); 
        
                Blob encryptedData = Crypto.encryptWithManagedIV('AES256', cryptoKey, data ); 
        
                b64Data = EncodingUtil.base64Encode (encryptedData);  
            }

        }catch(Exception e){
            expMsg = e.getMessage();
            List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            logList.add(lg);
            if(logList.size() > 0 ){
				FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
				flsWrap = FLSChecker.dmlInsert(logList);
				if(!flsWrap.isSuccess){
					throw new CustomException(flsWrap.message);
				}
            }
        }
        
        return (String.isEmpty(expMsg) ?  b64Data :  null);
    } 

    /**
     * @description Method to decrypt a data
     * @param encryptedData
     * @return String
    */
    public static String processDecryption(string encryptedData){ 

        String decryptedData = ''; 
        String expMsg = '';
        
        try{ 

            if(String.isNotBlank(encryptedData)){
                Blob data = EncodingUtil.base64Decode (encryptedData); 
                
                // Get the hex key from the encrypted field
                KTXero__Encryption_Configuration__c setting = KTXero__Encryption_Configuration__c.getOrgDefaults();
                Blob cryptoKey = EncodingUtil.base64Decode(setting.KTXero__Encryption_Key__c);
    
                Blob dataToDecrypt = Crypto.decryptWithManagedIV ('AES256', cryptoKey, data); 
    
                decryptedData = dataToDecrypt.toString(); 
            }

        }catch(Exception e){ 

            expMsg = e.getMessage();
            List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            logList.add(lg);
            if(logList.size() > 0 ){
				FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
				flsWrap = FLSChecker.dmlInsert(logList);
				if(!flsWrap.isSuccess){
					throw new CustomException(flsWrap.message);
				}
            }
        } 

        return (String.isEmpty(expMsg) ?  decryptedData :  null);  

    }
    
    /**
     * @description Method to check if org has multiCurrency enabled or not
     * @return Boolean
    */
	@AuraEnabled
	public static boolean getIsMultiCurrencyOrg() {
		boolean isMultiCurrecyOrg = false;
		try {
			isMultiCurrecyOrg = UserInfo.isMultiCurrencyOrganization();

		} catch (Exception e) {
			KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
		}
		return isMultiCurrecyOrg;
	}

    /**
     * @description Method to get Salesforce URL of Current Domain
     * @return String
     * @param entity
    */
	@AuraEnabled
	public static string getSFURL(String entity){
		String sfURL = System.URL.getSalesforceBaseUrl().toExternalForm();
		try {
			if(entity == 'Currency'){
				sfURL +='/lightning/setup/CompanyCurrency/page?address=%2Fsetup%2Fcur%2Fcurrencylist.jsp';
			}else if(entity == 'Sites'){
				sfURL +='/lightning/setup/CustomDomain/home';
			}else if(entity == 'VFURL'){
				sfURL = System.URL.getOrgDomainUrl().toExternalForm()+'/apex/KTXero__XeroOAuthPage';
			}else if(entity == ''){
				sfURL = sfURL;
			}
		} catch (Exception e) {
			KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
		}
		return sfURL;
	}

    /**
     * @description Method to refresh access token
     * @return KTXero__Xero_Connection__c
    */
  	public static KTXero__Xero_Connection__c refreshToken(){
		List<KTXero__Xero_Connection__c> xeroConnect = new List<KTXero__Xero_Connection__c>();
        try{
            if(xeroConnect.getSObjectType().getDescribe().isAccessible() == true
            && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Client_Id__c.isAccessible() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Client_Secret__c.isAccessible() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Access_Token__c.isAccessible() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Refresh_Token__c.isAccessible() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Tenant_Id__c.isAccessible() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Completed_Steps__c.isAccessible() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Completed_Xero_Connection_Steps__c.isAccessible() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Progress_Value__c.isAccessible() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Total_Xero_Connection_Steps__c.isAccessible() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Authenticated__c.isAccessible() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Last_Token_Refresh_Time__c.isAccessible() == true
                && Schema.sObjectType.KTXero__Xero_Connection__c.fields.KTXero__Webhook_Key__c.isAccessible() == true){

                xeroConnect = [SELECT 
                                Id, KTXero__Client_Id__c, 
                                KTXero__Client_Secret__c, KTXero__Access_Token__c, 
                                KTXero__Refresh_Token__c, KTXero__Tenant_Id__c, KTXero__Completed_Steps__c, 
                                KTXero__Completed_Xero_Connection_Steps__c, 
                                KTXero__Progress_Value__c, KTXero__Total_Xero_Connection_Steps__c, 
                                KTXero__Authenticated__c, KTXero__Webhook_Key__c, KTXero__Last_Token_Refresh_Time__c
                                FROM KTXero__Xero_Connection__c WITH SECURITY_ENFORCED];
        
    
                if(xeroConnect.size() > 0){
                    Http h = new Http();
                    HttpRequest req = new HttpRequest();
                    String authHead = 'Basic '+EncodingUtil.base64Encode(Blob.valueOf(Utils.processDecryption(xeroConnect[0].KTXero__Client_Id__c)+':'+Utils.processDecryption(xeroConnect[0].KTXero__Client_Secret__c)));
                    req.setEndpoint('https://identity.xero.com/connect/token'); 
                    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                    req.setHeader('authorization', authHead);
                    String bodyRequest = '';
                    bodyRequest += 'grant_type=refresh_token'; 
                    bodyRequest += '&refresh_token='+Utils.processDecryption(xeroConnect[0].KTXero__Refresh_Token__c); 
                    req.setBody(bodyRequest);
                    req.setMethod('POST');
                    req.setTimeout(10000); 
                    HttpResponse response = h.send(req);
                    if(response.getStatusCode() == 200){
                        XeroOAuthPageController.AuthResponseWrap arWrap = (XeroOAuthPageController.AuthResponseWrap)JSON.deserialize(response.getBody(),XeroOAuthPageController.AuthResponseWrap.class);
                        xeroConnect[0].KTXero__Access_Token__c = Utils.processEncryption(arWrap.access_token);
                        xeroConnect[0].KTXero__Refresh_Token__c = Utils.processEncryption(arWrap.refresh_token);
                        xeroConnect[0].KTXero__Last_Token_Refresh_Time__c = System.now();
                    }

                }
            }
        }catch(Exception e){
            List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            logList.add(lg);
            if(logList.size() > 0 ){
				FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
				flsWrap = FLSChecker.dmlInsert(logList);
				if(!flsWrap.isSuccess){
					throw new CustomException(flsWrap.message);
				}
            }
            // throw new AuraHandledException(JSON.serialize(lg));
        }

		return xeroConnect[0];
	}

    /**
     * @description Method to check if Refresh Token is expired or not
     * @return Boolean
     * @param lastRefreshDate
    */
	public static Boolean checkTokenExpiry(DateTime lastRefreshDate){
		Boolean flag = false;
		try{
            DateTime currDt = System.now();
            Long previousDate = lastRefreshDate.getTime();
            Long currentDate = currDt.getTime();
            if(currDt.isSameDay(lastRefreshDate)){
                Long milliseconds = currentDate - previousDate;
                Long hours = (milliseconds / 60000) / 60;
                if(hours <= 0){
                    Long mins = milliseconds / 60000;
                    if(mins <= 25){
                        flag = true;
                    }
                }
            }
		}catch(Exception e){
		    flag = false;
            List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            logList.add(lg);
            if(logList.size() > 0 ){
				FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
				flsWrap = FLSChecker.dmlInsert(logList);
				if(!flsWrap.isSuccess){
					throw new CustomException(flsWrap.message);
				}
            }
		}
		return flag;
	}

    /**
     * @description Method to update permissions in Permission Set
     * @return Boolean
     * @param permId
    */
	public static Boolean assignPermissions(String permId){
		Boolean flag = false;
		// Object Permissions Setup
        List<ObjectPermissions> op = new List<ObjectPermissions>();
        op = [SELECT ID, SObjectType, ParentID FROM ObjectPermissions WHERE ParentId = :permId WITH SECURITY_ENFORCED];
        Map<String, String> existOP = new Map<String, String>();
        //existOP is utilized so we can work on profiles if needed as well as permission sets. 
        for (ObjectPermissions eop : op){
            String objname = eop.SobjectType;
            String objid = eop.Id;
            existOp.put(objname, objid);
        }
        List<ObjectPermissions> objPerms = new List<ObjectPermissions>();
        Map<String, List<Boolean>> objectsAndCRUD = new Map<String, List<Boolean>>();
        List<Map<String, List<Boolean>>> objectsAndCRUDcollection = new List <Map<String, List<Boolean>>>();
        
        //Field Permissions Setup
        List<FieldPermissions> fp = new List<FieldPermissions>();
        fp = [SELECT ID, SObjectType, Field, ParentID FROM FieldPermissions WHERE ParentId = :permId WITH SECURITY_ENFORCED];
        Map<String, String> existFP = new Map<String, String>();
        for (FieldPermissions efp : fp){
            String fldname = efp.Field;
            String fldid = efp.Id;
            existFp.put(fldname, fldid);
        }
        List<FieldPermissions> fieldPerms = new List<FieldPermissions>();
        Map<String, List<Boolean>> fieldsAndCRUD = new Map<String, List<Boolean>>();
        List<Map<String, List<Boolean>>> fieldsAndFSLcollection = new List <Map<String, List<Boolean>>>();
        
        
        //========================================================
        //ENTER YOUR OBJECTS and CRUD ACCESS BELOW
        //========================================================   
        
        //READ - CREATE - EDIT - DELETE
        //Grant read and edit access to account
        objectsAndCRUD.put('Account', new List<Boolean>{True, True, False, False});
        //Grant read and edit access to Opportunity
        objectsAndCRUD.put('Opportunity', new List<Boolean>{True, True, False, False});
        //Grant read access to Product
        objectsAndCRUD.put('Product2', new List<Boolean>{True, False, False, False});
        
        
        objectsAndCRUDcollection.add(objectsAndCRUD);
        
        //========================================================
        //ACCOUNT FIELD AND READ/EDIT ACCESS BELOW
        //========================================================   
        
        fieldsAndCRUD.put('Account.AccountNumber', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.Site', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.AccountSource', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.AnnualRevenue', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.BillingAddress', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.Description', new List<Boolean>{True, False});
        fieldsAndCRUD.put('Account.NumberOfEmployees', new List<Boolean>{True, False});
        fieldsAndCRUD.put('Account.Fax', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.Industry', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.ParentId', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.Phone', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.Rating', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.ShippingAddress', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.Sic', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.SicDesc', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.TickerSymbol', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.Type', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Account.Website', new List<Boolean>{True, True});

        //========================================================
        //Opportunity FIELD AND READ/EDIT ACCESS BELOW
        //========================================================   

        fieldsAndCRUD.put('Opportunity.AccountId', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.Amount', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.ContractId', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.ContractId', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.KTXero__CurrentGenerators__c', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.KTXero__DeliveryInstallationStatus__c', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.Description', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.LeadSource', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.KTXero__MainCompetitors__c', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.NextStep', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.KTXero__OrderNumber__c', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.Probability', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.TotalOpportunityQuantity', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.KTXero__TrackingNumber__c', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.Type', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Opportunity.IsPrivate', new List<Boolean>{True, True});

        //========================================================
        //Product2 FIELD AND READ/EDIT ACCESS BELOW
        //========================================================   

        fieldsAndCRUD.put('Product2.DisplayUrl', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Product2.ExternalDataSourceId', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Product2.ExternalId', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Product2.ProductCode', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Product2.Description', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Product2.Family', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Product2.StockKeepingUnit', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Product2.QuantityUnitOfMeasure', new List<Boolean>{True, True});
        fieldsAndCRUD.put('Product2.KTXero__Xero_ItemID__c', new List<Boolean>{True, True});

        fieldsAndFSLcollection.add(fieldsAndCRUD);
        
        //Call the method to preform the logic of inserting the permissions based on the above object and field level declarations
        PermissionWrapper perWrap = new PermissionWrapper();
        perWrap.objectsAndCRUD = objectsAndCRUD;
        perWrap.permissionId = permId;
        perWrap.existOP = existOP;
        perWrap.objPerms = objPerms;
        perWrap.existFP = existFP;
        perWrap.fieldsAndCRUD = fieldsAndCRUD;
        perWrap.fieldPerms = fieldPerms;
        flag = logicForPermissionSet(perWrap);

		return flag;
	}

	/*******************************************************************************************************
    * @description Method that is used to do the logic of assigning the correct permissions on the permission
    * set. This method is used by every other method in this class.
    *  
    * @param objectsAndCRUD Used to hold the objects that we will be assigning permissions to
    * @param permId The permission set Id that we are altering
    * @param existOP Used for future use cases. This is needed in case we are not inserting, but instead updating. However we will always be inserting with this class
    * @param objPerms List used to hold all of the correct object CRUD permissions that we upsert 
    * @param existFP Used for future use cases. This is needed in case we are not inserting, but instead updating. However we will always be inserting with this class
    * @param fieldsAndCRUD Used to hold the Fields that we will be assigning permissions to
    * @param fieldPerms List used to hold all of the correct field Read Edit permissions that we upsert 
    * @return dmlWrapper.  always null.
    ********************************************************************************************************/
    public static Boolean logicForPermissionSet(PermissionWrapper perWrap)
    {
		Boolean flag = false;
        for(String objectName : perWrap.objectsAndCRUD.keySet()) {
            ObjectPermissions objPermission = new ObjectPermissions();
            objPermission.ParentId = perWrap.permissionId;
            objPermission.SobjectType = objectName;
            objPermission.PermissionsRead = False;
            objPermission.PermissionsCreate = False;
            objPermission.PermissionsEdit = False;
            objPermission.PermissionsDelete = False;
            if (perWrap.existOP.get(objectName) != null){
                objPermission.Id = perWrap.existOP.get(objectName);
            }
            
            if (perWrap.objectsAndCRUD.get(objectName)[0] == True){
                objPermission.PermissionsRead = true;
            }

            if (perWrap.objectsAndCRUD.get(objectName)[1] == True){
                objPermission.PermissionsCreate = true;
            }

            if (perWrap.objectsAndCRUD.get(objectName)[2] == True){
                objPermission.PermissionsEdit = true;
            }

            if (perWrap.objectsAndCRUD.get(objectName)[3] == True){
                objPermission.PermissionsDelete = true;
            }

            perWrap.objPerms.add(objPermission);	
        }
        
        for(String fieldName : perWrap.fieldsAndCRUD.keySet()) {
            FieldPermissions fldPermission = new FieldPermissions();
            fldPermission.ParentId = perWrap.permissionId;
            fldPermission.SobjectType = fieldName.substringBefore('.');
            fldPermission.Field = fieldName;
            fldPermission.PermissionsRead = False;
            fldPermission.PermissionsEdit = False;
            if (perWrap.existFP.get(fieldName) != null){
                fldPermission.Id = perWrap.existFP.get(fieldName);
            }
            
            if (perWrap.fieldsAndCRUD.get(fieldName)[0] == True){
                fldPermission.PermissionsRead = true;
            }
            
            if (perWrap.fieldsAndCRUD.get(fieldName)[1] == True){
                fldPermission.PermissionsEdit = true;
            }
            
            perWrap.fieldPerms.add(fldPermission);	
        }
        

        if(perWrap.objPerms.size() > 0){
            FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
            flsWrap = FLSChecker.dmlUpsert(perWrap.objPerms);
            if(!flsWrap.isSuccess){
                flag = false;
            }else{
                flag = true;
            }
        }

		if(flag){
            if(perWrap.fieldPerms.size() > 0){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlUpsert(perWrap.fieldPerms);
                if(!flsWrap.isSuccess){
                    flag = false;
                }else{
                    flag = true;
                }
            }
		}
		
		return flag;
    }

    @AuraEnabled
    public static Boolean insertLog(String exceptionLog){
        Boolean flag = false;
        KTXero__Log__c kl = new KTXero__Log__c();
        try {
            kl = (KTXero__Log__c)JSON.deserialize(exceptionLog,KTXero__Log__c.class);
            
            List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
            logList.add(kl);

            FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
            flsWrap = FLSChecker.dmlInsert(logList);
            if(!flsWrap.isSuccess){
                throw new AuraHandledException(flsWrap.message);
            }else{
                flag = flsWrap.isSuccess;
            }
        } catch (Exception e) {
        
            List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            logList.add(lg);
            if(logList.size() > 0 ){
				FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
				flsWrap = FLSChecker.dmlInsert(logList);
				if(!flsWrap.isSuccess){
					throw new CustomException(flsWrap.message);
				}
            }
        }
        
        return flag;
    }

    /**
     * @description Wrapper for Permission Set Creation and assignment
    */
    public class PermissionWrapper {
        public Map<String, List<Boolean>> objectsAndCRUD;
        public String permissionId;
        public Map<String, String> existOP;
        public List<ObjectPermissions> objPerms;
        public Map<String, String> existFP;
        public Map<String, List<Boolean>> fieldsAndCRUD;
        public List<FieldPermissions> fieldPerms;
    }

    public class Mapping {
        public String name;
        public String data_Type;
        public String field_API_Name;
        public String field_Value;
        public String quickBook_Field_Api_Name;
        public Boolean required;
   }

}