/**
* @description Class to manage invoices in Xero and Salesforce
* @Author : Kandisa Technologies
* @CreatedDate : 01 March 2023
*/
public with sharing class InvoiceCreationController {
    
    public static KTXero__Xero_Connection__c xeroConnect = [SELECT Id, Name, KTXero__Client_Id__c, KTXero__Client_Secret__c, KTXero__Access_Token__c, KTXero__Refresh_Token__c, KTXero__Tenant_Id__c, KTXero__Completed_Steps__c, KTXero__Completed_Xero_Connection_Steps__c, KTXero__Progress_Value__c, KTXero__Total_Xero_Connection_Steps__c, KTXero__Authenticated__c, KTXero__Webhook_Key__c, KTXero__Last_Token_Refresh_Time__c FROM KTXero__Xero_Connection__c WITH SECURITY_ENFORCED LIMIT 1];
    
    /**
* @description Method to fetch the list of Xero contacts based on company name
* @return List<KTXero__Xero_Contact__c>
* @param accountId
* @param accountName
*/
    @AuraEnabled
    public static List<KTXero__Xero_Contact__c> getXeroCons(String accountId, String accountName){
        List<KTXero__Xero_Contact__c> xeroConList = new List<KTXero__Xero_Contact__c>();
        try{
            xeroConList = [SELECT Id, Name, KTXero__First_Name__c, KTXero__Last_Name__c, KTXero__Email_Address__c, KTXero__Company_Name__c, KTXero__Reference_Id__c FROM KTXero__Xero_Contact__c WHERE KTXero__Salesforce_Account__c =: accountId OR KTXero__Company_Name__c =: accountName WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC ];
        }catch(Exception e){
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return xeroConList;
    }
    
    /**
* @description Method to fetch the account name based on accountId
* @return String
* @param accountId
*/
    @AuraEnabled
    public static String getAccountName(String accountId){
        String accName = '';
        try{
            accName = [SELECT Id, Name FROM Account WHERE Id =: accountId].Name;
        }catch(Exception e){
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return accName;
    }
    
    /**
* @description Method to check if account value is duplicate or not
* @return InvoiceCreationWrapper.CheckAccDetailWrapper
* @param  accName
* @param  accNumber
*/
    @AuraEnabled
    public static InvoiceCreationWrapper.CheckAccDetailWrapper checkAccountName(String accName, String accNumber){
        
        InvoiceCreationWrapper.CheckAccDetailWrapper cdw = new InvoiceCreationWrapper.CheckAccDetailWrapper();
        cdw.fieldName = '';
        cdw.isDuplicate = false;
        
        if(String.isNotBlank(accName)){
            accName = String.escapeSingleQuotes(accName);
        }else{
            return cdw;
        }
        
        if(String.isNotBlank(accNumber)){
            accNumber = String.escapeSingleQuotes(accNumber);
        }
        
        List<KTXero__Xero_Contact__c> xconList = new List<KTXero__Xero_Contact__c>();
        try {
            String query = 'SELECT Id, KTXero__Account_Number__c, KTXero__Company_Name__c FROM KTXero__Xero_Contact__c ';
            if(String.isNotBlank(accName)){
                query += 'WHERE KTXero__Company_Name__c =: accName ';
            }
            if(String.isNotBlank(accNumber)){
                query += 'OR KTXero__Account_Number__c =: accNumber ';
            }
            query += 'WITH SECURITY_ENFORCED';
            xconList = Database.query(String.escapeSingleQuotes(query));
            if(xconList.size() > 0){
                cdw.isDuplicate = true;
                Integer numCount = 0;
                Integer nameCount = 0;
                for(KTXero__Xero_Contact__c xc : xconList){
                    if(xc.KTXero__Account_Number__c == accNumber){
                        numCount++;
                    }
                    if(xc.KTXero__Company_Name__c == accName){
                        nameCount++;
                    }
                }
                if(numCount > 0){
                    cdw.fieldName += 'Account Number, ';
                }
                if(nameCount > 0){
                    cdw.fieldName += 'Account Name, ';
                }
                cdw.fieldName = cdw.fieldName.removeEnd(', ');
            }
        } catch (Exception e) {
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        
        return cdw;
    }
    
    
    
    /**
* @description Method to fetch the list of Salesforce products based on search criteria
* @return List<InvoiceCreationWrapper.ProductSearchWrapper>
* @param inputVal
*/
    @AuraEnabled
    public static List<InvoiceCreationWrapper.ProductSearchWrapper> getProductList(String inputVal){
        List<Product2> prodList = new List<Product2>();
        List<InvoiceCreationWrapper.ProductSearchWrapper> pswList = new List<InvoiceCreationWrapper.ProductSearchWrapper>();
        try {
            inputVal = inputVal.deleteWhitespace();
            String productCode = inputVal;
            String productName = inputVal;
            if(inputVal.contains(':')){
                productCode = inputVal.substringBefore(':');
                productName = inputVal.substringAfter(':');
            }
            productCode = '%'+productCode+'%';
            productName = '%'+productName+'%';
            
            prodList = [SELECT Id, Name, Description, KTXero__Xero_Item_Sales_Account_Code__c, KTXero__Xero_Item_Sales_Tax_Rate__c, KTXero__Xero_Item_Sales_Description__c, KTXero__Xero_ItemID__c, ProductCode, IsActive FROM Product2 WHERE (Name LIKE: productName OR ProductCode LIKE: productCode) AND IsActive = true WITH SECURITY_ENFORCED];
            if(prodList.size() > 0){
                for(Product2 pro : prodList){
                    InvoiceCreationWrapper.ProductSearchWrapper psw = new InvoiceCreationWrapper.ProductSearchWrapper();
                    psw.id = pro.Id;
                    psw.name = pro.Name;
                    psw.productCode = pro.ProductCode;
                    psw.xeroItemId = pro.KTXero__Xero_ItemID__c;
                    psw.salesAccountCode = pro.KTXero__Xero_Item_Sales_Account_Code__c != null ? pro.KTXero__Xero_Item_Sales_Account_Code__c : '';
                    psw.salesTaxRate = pro.KTXero__Xero_Item_Sales_Tax_Rate__c != null ? pro.KTXero__Xero_Item_Sales_Tax_Rate__c : '';
                    psw.salesDescription = pro.KTXero__Xero_Item_Sales_Description__c != null ? pro.KTXero__Xero_Item_Sales_Description__c : '';
                    psw.prodDescription = pro.Description != null ? pro.Description : '';
                    pswList.add(psw);
                }
            }
        } catch (Exception e) {
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return pswList;
    }
    
    /**
* @description Method to fetch the list of Salesforce products based on parameters
* @return InvoiceCreationWrapper.OppWrapper
* @param recordId
* @param setupFields
*/
    @AuraEnabled(cacheable=false)
    public static InvoiceCreationWrapper.OppWrapper getProducts(String recordId, List<String> setupFields){
        Opportunity opp = new Opportunity();
        InvoiceCreationWrapper.OppWrapper oppW = new InvoiceCreationWrapper.OppWrapper();
        try{
            if(Opportunity.getSObjectType().getDescribe().isAccessible() == true 
               && OpportunityLineItem.getSObjectType().getDescribe().isAccessible() == true
               && Account.getSObjectType().getDescribe().isAccessible() == true
               && KTXero__Invoice__c.getSObjectType().getDescribe().isAccessible() == true
               
               && Schema.sObjectType.Opportunity.fields.AccountId.isAccessible() == true 
               && Schema.sObjectType.Opportunity.fields.name.isAccessible() == true 
               
               && Schema.sObjectType.Account.fields.name.isAccessible() == true 
               && Schema.sObjectType.KTXero__Invoice__c.fields.name.isAccessible() == true 
               && Schema.sObjectType.KTXero__Invoice__c.fields.KTXero__Opportunity__c.isAccessible() == true 
               
              ){
                  if(recordId != null){
                      
                      opp = [SELECT Id, Name, AccountId, (SELECT Id FROM OpportunityLineItems) FROM Opportunity WHERE Id=: recordId WITH SECURITY_ENFORCED];
                      
                      Account acc = new Account();
                      List<KTXero__Invoice__c> invList = new List<KTXero__Invoice__c>();
                      if(opp != null){
                          if(opp.AccountId != null){
                              acc = [SELECT Id, Name FROM Account WHERE Id =: opp.AccountId];
                          }
                          if(opp.Id != null){
                              
                              invList = [SELECT Id, Name FROM  KTXero__Invoice__c WHERE KTXero__Opportunity__c =: opp.Id ORDER BY Name ASC];
                              
                              oppW.oppId = opp.Id;
                          }
                          oppW.name = opp.Name;
                          oppW.accountId = opp.AccountId;
                          if(acc != null){
                              oppW.accountName = acc.Name;
                          }
                          oppW.opp = opp;
                          
                          List<InvoiceCreationWrapper.OpplineWrapper> opplineWrapperList = new List<InvoiceCreationWrapper.OpplineWrapper>(); 
                          for(OpportunityLineItem oppLine : opp.OpportunityLineItems){
                              InvoiceCreationWrapper.OpplineWrapper opplineW = new InvoiceCreationWrapper.OpplineWrapper();
                              opplineW.opplineid = oppLine.Id;
                              opplineWrapperList.add(opplineW);
                          }
                          oppW.opplineItems = opplineWrapperList;
                          
                          List<InvoiceCreationWrapper.InvoiceWrapper> invoicewrapList = new List<InvoiceCreationWrapper.InvoiceWrapper>();
                          if(invList.size() > 0){
                              for(Invoice__c inv : invList){
                                  InvoiceCreationWrapper.InvoiceWrapper invwrap = new InvoiceCreationWrapper.InvoiceWrapper();
                                  invwrap.invoiceId = inv.Id;
                                  invwrap.name = inv.Name;
                                  invoicewrapList.add(invwrap);
                              }
                          }
                          oppW.invoices = invoicewrapList;
                      }
                  }
              }
            
        }catch(Exception e){
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return oppW;
    }
    
    /**
* @description Method to fetch the Opportunity cucrrency
* @return String
* @param recordId
*/
    @AuraEnabled
    public static string getOppCurrency(string recordId){
        String opp;
        try {
            if(Userinfo.isMultiCurrencyOrganization()){
                String query = 'SELECT Id,currencyIsoCode FROM Opportunity WHERE Id =: recordId WITH SECURITY_ENFORCED';
                List<SObject> oppList = Database.query(query);
                opp = (String)oppList[0].get('currencyIsoCode');
            }else{
                opp = UserInfo.getDefaultCurrency();
            }
        } catch (Exception e) {
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return opp;
    }
    
    /**
* @description Method to fetch the list of Xero_Contact__c 
* @return List<InvoiceCreationWrapper.XeroContactWrapper>
* @param recordId
* @param accountId
*/
    @AuraEnabled
    public static InvoiceCreationWrapper.XeroContactWrapper getXeroContacts(String recordId, String accountId){
        List<Xero_Contact__c> xeroConList = new List<Xero_Contact__c>();
        InvoiceCreationWrapper.XeroContactWrapper xconw = new InvoiceCreationWrapper.XeroContactWrapper();
        
        if(String.isNotBlank(recordId)){
            recordId = String.escapeSingleQuotes(recordId);
        }
        
        if(String.isNotBlank(accountId)){
            accountId = String.escapeSingleQuotes(accountId);
        }
        
        try {
            String query = 'SELECT Id, Name, KTXero__First_Name__c, KTXero__Last_Name__c, KTXero__Email_Address__c, KTXero__Company_Name__c, KTXero__Reference_Id__c, KTXero__Street_Address__c, KTXero__Town_City__c, KTXero__State_Region__c, KTXero__Postal_Zip_Code__c, KTXero__Country__c, KTXero__Salesforce_Account__c FROM KTXero__Xero_Contact__c';
            if(String.isNotBlank(accountId)){
                query += ' WHERE KTXero__Salesforce_Account__c =: accountId';
            }else{
                query += ' WHERE KTXero__Opportunity__c =: recordId';
            }
            
            query += ' WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 1';
            xeroConList = Database.query(String.escapeSingleQuotes(query));
            if(xeroConList.size() > 0){
                xconw.id = xeroConList[0].Id;
                xconw.name = xeroConList[0].Name;
                xconw.firstName = xeroConList[0].First_Name__c;
                xconw.lastName = xeroConList[0].Last_Name__c;
                xconw.emailAddress = xeroConList[0].Email_Address__c;
                xconw.companyName = xeroConList[0].Company_Name__c;
                xconw.referenceId = xeroConList[0].Reference_Id__c;
                xconw.streetAddress = xeroConList[0].Street_Address__c;
                xconw.townCity = xeroConList[0].Town_City__c;
                xconw.stateRegion = xeroConList[0].State_Region__c;
                xconw.postalZipCode = xeroConList[0].Postal_Zip_Code__c;
                xconw.country = xeroConList[0].Country__c;
            }
        }catch (Exception e) {
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return xconw;
    }
    
    /**
* @description Method to fetch blank AccWrapper 
* @return InvoiceCreationWrapper.AccWrapper
*/
    @AuraEnabled
    public static InvoiceCreationWrapper.AccWrapper getAccountWrapper(){
        return new InvoiceCreationWrapper.AccWrapper();
    }
    
    /**
* @description Method to fetch Accoun details 
* @return InvoiceCreationWrapper.AccWrapper
* @param accountId
*/
    @AuraEnabled
    public static InvoiceCreationWrapper.AccWrapper getAccountDetails(String accountId){
        Account acc = new Account();
        InvoiceCreationWrapper.AccWrapper accWrap = new InvoiceCreationWrapper.AccWrapper();
        KTXero__Xero_Contact_Configurations__c xconfig = new KTXero__Xero_Contact_Configurations__c();
        Map<String,List<String>> fieldMap = new Map<String,List<String>>();
        try {
            
            if(xconfig.getSObjectType().getDescribe().isAccessible() == true 
               && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.name.isAccessible() == true
               && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_First_Name__c.isAccessible() == true
               && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_Last_Name__c.isAccessible() == true
               && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_Email__c.isAccessible() == true
               && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_Account_Number__c.isAccessible() == true
               && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_Account_Name__c.isAccessible() == true
               && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_Street_Address__c.isAccessible() == true
               && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_City__c.isAccessible() == true
               && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_State__c.isAccessible() == true
               && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_ZipCode__c.isAccessible() == true
               && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_Account_Phone__c.isAccessible() == true
               && Schema.sObjectType.KTXero__Xero_Contact_Configurations__c.fields.Xero_Contact_Country__c.isAccessible() == true){
                   
                   
                   
                   xconfig = [SELECT Id, Name, Xero_Contact_Account_Name__c, Xero_Contact_Account_Number__c, Xero_Contact_Account_Phone__c,
                              Xero_Contact_City__c, Xero_Contact_Country__c, Xero_Contact_Email__c, Xero_Contact_First_Name__c,
                              Xero_Contact_Last_Name__c, Xero_Contact_State__c, Xero_Contact_Street_Address__c, Xero_Contact_ZipCode__c
                              FROM KTXero__Xero_Contact_Configurations__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED];
                   
                   Map<String, Schema.SObjectField> accAllFields = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();
                   Set<String> accFields = new Set<String>();
                   
                   for(Schema.SObjectField fieldRef : accAllFields.values()) {
                       Schema.DescribeFieldResult fieldResult = fieldRef.getDescribe();
                       if(fieldResult.isAccessible()) {
                           accFields.add(fieldResult.getname());
                       }
                   }
                   if(!accFields.contains('Name')){
                       accFields.add('Name');
                   }
                   
                   Map<String, Schema.SObjectField> conAllFields = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap();
                   Set<String> conFields = new Set<String>();
                   for(Schema.SObjectField fieldRef : conAllFields.values()) {
                       Schema.DescribeFieldResult fieldResult = fieldRef.getDescribe();
                       if(fieldResult.isAccessible() ) {
                           conFields.add(fieldResult.getname());
                       }
                   }
                   if(!conFields.contains('Name')){
                       conFields.add('Name');
                   }
                   
                   if(String.isNotBlank(accountId)){
                       accountId = String.escapeSingleQuotes(accountId);
                       
                       
                       String query = 'SELECT '+ String.join(new List<String>(accFields), ',') + ', (SELECT '+ String.join(new List<String>(conFields), ',')+' FROM Contacts) FROM Account WHERE Id =:accountId WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC';
                       
                       fieldMap.put('Account',new List<String>(accFields));
                       fieldMap.put('Contact',new List<String>(conFields));
                       
                       if(fieldMap.size() > 0){
                           FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                           flsWrap = FLSChecker.accessibleCheck(fieldMap);
                           if(flsWrap.isSuccess){
                               
                               acc = Database.query(String.escapeSingleQuotes(query));
                               
                               accWrap.accId = acc.Id;
                               if(xconfig.Xero_Contact_Account_Name__c != null && xconfig.Xero_Contact_Account_Name__c != ''){
                                   accWrap.accName = (String.ValueOf(acc.get(xconfig.Xero_Contact_Account_Name__c)) != null && String.ValueOf(acc.get(xconfig.Xero_Contact_Account_Name__c)) != '') ? String.ValueOf(acc.get(xconfig.Xero_Contact_Account_Name__c)) : '';
                               }else{
                                   accWrap.accName = String.isNotBlank(acc.Name) ? acc.Name : '';
                               }
                               
                               if(xconfig.Xero_Contact_Account_Number__c != null && xconfig.Xero_Contact_Account_Number__c != ''){
                                   accWrap.accNumber = (String.ValueOf(acc.get(xconfig.Xero_Contact_Account_Number__c)) != null && String.ValueOf(acc.get(xconfig.Xero_Contact_Account_Number__c)) != '') ? String.ValueOf(acc.get(xconfig.Xero_Contact_Account_Number__c)) : '';
                               }else{
                                   accWrap.accNumber = String.isNotBlank(acc.AccountNumber) ? acc.AccountNumber : '';
                               }
                               
                               if(xconfig.Xero_Contact_Street_Address__c != null && xconfig.Xero_Contact_Street_Address__c != ''){
                                   accWrap.accStreet = (String.ValueOf(acc.get(xconfig.Xero_Contact_Street_Address__c)) != null && String.ValueOf(acc.get(xconfig.Xero_Contact_Street_Address__c)) != '') ? String.ValueOf(acc.get(xconfig.Xero_Contact_Street_Address__c)) : '';
                               }else{
                                   accWrap.accStreet = String.isNotBlank(acc.BillingStreet) ? acc.BillingStreet : '';
                               }
                               
                               if(xconfig.Xero_Contact_City__c != null && xconfig.Xero_Contact_City__c != ''){
                                   accWrap.accCity = (String.ValueOf(acc.get(xconfig.Xero_Contact_City__c)) != null && String.ValueOf(acc.get(xconfig.Xero_Contact_City__c)) != '') ? String.ValueOf(acc.get(xconfig.Xero_Contact_City__c)) : '';
                               }else{
                                   accWrap.accCity = String.isNotBlank(acc.BillingCity) ? acc.BillingCity : '';
                               }
                               
                               if(xconfig.Xero_Contact_State__c != null && xconfig.Xero_Contact_State__c != ''){
                                   accWrap.accState = (String.ValueOf(acc.get(xconfig.Xero_Contact_State__c)) != null && String.ValueOf(acc.get(xconfig.Xero_Contact_State__c)) != '') ? String.ValueOf(acc.get(xconfig.Xero_Contact_State__c)) : '';
                               }else{
                                   accWrap.accState = String.isNotBlank(acc.BillingState) ? acc.BillingState : '';
                               }
                               
                               if(xconfig.Xero_Contact_ZipCode__c != null && xconfig.Xero_Contact_ZipCode__c != ''){
                                   accWrap.accPostalCode = (String.ValueOf(acc.get(xconfig.Xero_Contact_ZipCode__c)) != null && String.ValueOf(acc.get(xconfig.Xero_Contact_ZipCode__c)) != '') ? String.ValueOf(acc.get(xconfig.Xero_Contact_ZipCode__c)) : '';
                               }else{
                                   accWrap.accPostalCode = String.isNotBlank(acc.BillingPostalCode) ? acc.BillingPostalCode : '';
                               }
                               
                               if(xconfig.Xero_Contact_Country__c != null && xconfig.Xero_Contact_Country__c != ''){
                                   accWrap.accCountry = (String.ValueOf(acc.get(xconfig.Xero_Contact_Country__c)) != null && String.ValueOf(acc.get(xconfig.Xero_Contact_Country__c)) != '') ? String.ValueOf(acc.get(xconfig.Xero_Contact_Country__c)) : '';
                               }else{
                                   accWrap.accCountry = String.isNotBlank(acc.BillingCountry) ? acc.BillingCountry : '';
                               }
                               
                               if(xconfig.Xero_Contact_Account_Phone__c != null && xconfig.Xero_Contact_Account_Phone__c != ''){
                                   accWrap.accPhone = (String.ValueOf(acc.get(xconfig.Xero_Contact_Account_Phone__c)) != null && String.ValueOf(acc.get(xconfig.Xero_Contact_Account_Phone__c)) != '') ? String.ValueOf(acc.get(xconfig.Xero_Contact_Account_Phone__c)) : '';
                               }else{
                                   accWrap.accPhone = String.isNotBlank(acc.Phone) ? acc.Phone : '';
                               }
                               
                               List<InvoiceCreationWrapper.ConWrapper> conWrapList = new List<InvoiceCreationWrapper.ConWrapper>(); 
                               for(Contact con : acc.Contacts){
                                   InvoiceCreationWrapper.ConWrapper conw = new InvoiceCreationWrapper.ConWrapper();
                                   conw.conId = con.Id;
                                   conw.conFirstName = con.FirstName;
                                   conw.conLastName = con.LastName;
                                   conw.conName = con.Name;
                                   conw.conEmail = con.Email;
                                   conw.includeinEmail = false;
                                   conWrapList.add(conw);
                               }
                               accWrap.conList = conWrapList; 
                           }else{
                               throw new AuraHandledException(flsWrap.message);
                           }
                       }
                   }else{
                       
                       List<InvoiceCreationWrapper.ConWrapper> conWrapList = new List<InvoiceCreationWrapper.ConWrapper>(); 
                       accWrap.conList = conWrapList; 
                       
                   }
                   
                   
                   
               }
        } catch (Exception e) {
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return accWrap;
    }
    
    
    /**
* @description Method to fetch Opportunity Products 
* @return InvoiceCreationWrapper.OppproductWrapper
* @param oppId
*/
    @AuraEnabled
    public static List<InvoiceCreationWrapper.OppproductWrapper> getOpportunityProducts(String oppId){
        List<InvoiceCreationWrapper.OppproductWrapper> productwrapperList = new List<InvoiceCreationWrapper.OppproductWrapper>();
        List<OpportunityLineItem> lineitemList = new List<OpportunityLineItem>(); 
        try {
            if(oppId != null){
                
                if(OpportunityLineItem.getSObjectType().getDescribe().isAccessible() == true 
                   && Schema.sObjectType.OpportunityLineItem.fields.OpportunityId.isAccessible() == true
                   && Schema.sObjectType.OpportunityLineItem.fields.Product2Id.isAccessible() == true
                   && Schema.sObjectType.OpportunityLineItem.fields.ProductCode.isAccessible() == true
                   && Schema.sObjectType.OpportunityLineItem.fields.Name.isAccessible() == true
                   && Schema.sObjectType.OpportunityLineItem.fields.Quantity.isAccessible() == true
                   && Schema.sObjectType.OpportunityLineItem.fields.UnitPrice.isAccessible() == true
                   && Schema.sObjectType.OpportunityLineItem.fields.Description.isAccessible() == true 
                   && Product2.getSObjectType().getDescribe().isAccessible() == true 
                   && Schema.sObjectType.Product2.fields.name.isAccessible() == true
                   && Schema.sObjectType.Product2.fields.KTXero__Xero_ItemID__c.isAccessible() == true){
                       lineitemList = [SELECT Id, OpportunityId, Discount, Product2Id, ProductCode, Product2.Name, Product2.KTXero__Xero_ItemID__c, Product2.Description, Product2.KTXero__Xero_Item_Sales_Description__c, Product2.KTXero__Xero_Item_Sales_Account_Code__c, Product2.KTXero__Xero_Item_Sales_Tax_Rate__c, Name, Quantity, UnitPrice, Description FROM OpportunityLineItem WHERE OpportunityId =: oppId WITH SECURITY_ENFORCED];
                       KTXero__Invoice_Configuration_Options__c invConfig = KTXero__Invoice_Configuration_Options__c.getOrgDefaults();
                       for(OpportunityLineItem oppli : lineitemList){
                           InvoiceCreationWrapper.OppproductWrapper opro = new InvoiceCreationWrapper.OppproductWrapper();
                           opro.id = oppli.Id;
                           opro.name = oppli.Name;
                           opro.productId = oppli.Product2Id;
                           opro.productName = oppli.Product2.Name;
                           if (String.isNotBlank(invConfig.KTXero__Line_Item_Description__c)) {
                               if(invConfig.KTXero__Line_Item_Description__c == 'Line Item Description'){
                                   opro.description = String.isNotBlank(oppli.Description) ? oppli.Description : '';
                               } else if (invConfig.KTXero__Line_Item_Description__c == 'Xero Item Sales Description') {
                                   opro.description = String.isNotBlank(oppli.Product2.KTXero__Xero_Item_Sales_Description__c) ? oppli.Product2.KTXero__Xero_Item_Sales_Description__c : '';
                               } else if (invConfig.KTXero__Line_Item_Description__c == 'Product Description') {
                                   opro.description = String.isNotBlank(oppli.Product2.Description) ? oppli.Product2.Description : '';
                               }
                           }
                           opro.productCode = oppli.ProductCode;
                           opro.quantity = oppli.Quantity.intValue();
                           opro.unitPrice = oppli.UnitPrice.intValue();
                           opro.discount = oppli.Discount != null ? oppli.Discount : 0;
                           opro.account = String.isNotBlank(oppli.Product2.KTXero__Xero_Item_Sales_Account_Code__c) ? oppli.Product2.KTXero__Xero_Item_Sales_Account_Code__c : '';
                           opro.taxRate = String.isNotBlank(oppli.Product2.KTXero__Xero_Item_Sales_Tax_Rate__c) ? oppli.Product2.KTXero__Xero_Item_Sales_Tax_Rate__c : '';
                           opro.showDropdown = false;
                           opro.taxCount = 0;
                           opro.trackingData = null;
                           opro.amount = oppli.Quantity.intValue() * oppli.UnitPrice.intValue();
                           if(opro.discount != 0){
                               Double discountVal = opro.discount / 100;
                               Double total = opro.amount * discountVal;
                               opro.amount = opro.amount - total;
                           }
                           opro.xeroItemID = String.isNotBlank(oppli.Product2.KTXero__Xero_ItemID__c) ? oppli.Product2.KTXero__Xero_ItemID__c : '';
                           opro.inputValue = oppli.ProductCode+': '+oppli.Product2.Name;
                           productwrapperList.add(opro);
                       }
                   }
                
            }
        } catch (Exception e) {
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return productwrapperList;
    }
    
    
    /**
* @description Method to fetch Salesforce Currencies 
* @return List<String>
*/
    @AuraEnabled
    public static List<String> getCurrency(){
        List<String> currencyIsoCodeList = new List<String>();
        try {
            if(Userinfo.isMultiCurrencyOrganization()){
                List<SObject> salesforceCurrList = new List<SObject>();
                String query = 'SELECT Id, IsoCode, ConversionRate, DecimalPlaces, IsActive, IsCorporate, CreatedDate FROM CurrencyType WHERE IsActive = true WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC';
                salesforceCurrList = Database.query(query);
                for(SObject obj : salesforceCurrList){
                    currencyIsoCodeList.add((String)obj.get('IsoCode'));
                }
            } else {
                currencyIsoCodeList.add(UserInfo.getDefaultCurrency());
            }
        } catch (Exception e) {
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return currencyIsoCodeList;
    }
    
    
    /**
* @description Method to fetch Invoice details like DueDate, Invoice date, currency based on Opportunity
* @return InvoiceCreationWrapper.InvoiceOppMappingWrapper
* @param recordId
*/
    @AuraEnabled
    public static InvoiceCreationWrapper.InvoiceOppMappingWrapper getinvoiceOppMapping(String recordId){
        KTXero__Invoice_Configuration_Options__c invConfig = new KTXero__Invoice_Configuration_Options__c();
        Opportunity opp = new Opportunity();
        InvoiceCreationWrapper.InvoiceOppMappingWrapper invoppWrap = new InvoiceCreationWrapper.InvoiceOppMappingWrapper(); 
        Map<String,List<String>> fieldMap = new Map<String,List<String>>();
        
        try {
            if(KTXero__Invoice_Configuration_Options__c.getSObjectType().getDescribe().isAccessible()
               && Opportunity.getSObjectType().getDescribe().isAccessible() == true
               
               && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.Invoice_Date__c.isAccessible() == true 
               && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.Invoice_Due_Date__c.isAccessible() == true 
               && Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.Invoice_Reference__c.isAccessible() == true 
               
              ){
                  
                  List<String> oppfieldList = new List<String>();
                  Map<String, Schema.SObjectField> fieldMap1 = Opportunity.getSObjectType().getDescribe().fields.getMap();
                  
                  String oppQuery = '';
                  if(Userinfo.isMultiCurrencyOrganization()){
                      oppfieldList.add('CurrencyIsoCode');
                      oppQuery = 'SELECT CurrencyIsoCode,';
                  }else{
                      oppQuery = 'SELECT ';
                  }
                  
                  List<String> fieldList = new List<String>();
                  invConfig = [SELECT KTXero__Invoice_Date__c, KTXero__Invoice_Due_Date__c, KTXero__Invoice_Reference__c FROM KTXero__Invoice_Configuration_Options__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED];
                  
                  if(invConfig.Invoice_Date__c != null && invConfig.Invoice_Date__c != '' ){
                      string invDate = invConfig.Invoice_Date__c.substringAfterLast(';');
                      if(invDate != null && invDate != ''){
                          if(fieldMap1.get(invDate).getDescribe().isAccessible()){
                              fieldList.add(invDate);
                              oppfieldList.add(invDate);
                          }
                      }
                  }
                  if((invConfig.Invoice_Due_Date__c != null && invConfig.Invoice_Due_Date__c != '') && (invConfig.Invoice_Date__c.substringAfterLast(';') != invConfig.Invoice_Due_Date__c.substringAfterLast(';'))){
                      String invDue = invConfig.Invoice_Due_Date__c.substringAfterLast(';');
                      if(invDue != null && invDue != ''){
                          if(fieldMap1.get(invDue).getDescribe().isAccessible()){
                              fieldList.add(invDue);
                              oppfieldList.add(invDue);
                          }
                      }
                  }
                  if(invConfig.Invoice_Reference__c != null && invConfig.Invoice_Reference__c != ''){
                      String invRef = invConfig.Invoice_Reference__c;
                      if(invRef != null){
                          if(fieldMap1.get(invRef).getDescribe().isAccessible()){
                              fieldList.add(invRef);
                              oppfieldList.add(invRef);
                          }
                      }
                      
                  }
                  
                  if(fieldList.size() > 0){
                      oppQuery += String.join(fieldList, ',');
                  }
                  
                  if(String.isNotBlank(recordId)){
                      recordId = String.escapeSingleQuotes(recordId);
                  }
                  
                  oppQuery += ' FROM Opportunity WHERE Id =: recordId WITH SECURITY_ENFORCED';
                  
                  fieldMap.put('Opportunity',oppfieldList);
                  
                  if(fieldMap.size() > 0){
                      FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                      flsWrap = FLSChecker.accessibleCheck(fieldMap);
                      if(flsWrap.isSuccess){
                          opp = Database.query(String.escapeSingleQuotes(oppQuery));
                          
                          if(invConfig.Invoice_Date__c != null){
                              String invDate = invConfig.Invoice_Date__c.substringAfterLast(';');
                              if(invDate != null && invDate != ''){
                                  Date dt = date.valueOf(opp.get(invConfig.Invoice_Date__c.substringAfterLast(';'))) != null ? date.valueOf(opp.get(invConfig.Invoice_Date__c.substringAfterLast(';'))) : null;
                                  Integer days = Integer.valueOf(invConfig.Invoice_Date__c.substringBefore(';'));
                                  if(invConfig.Invoice_Date__c.contains('Before')){
                                      invoppWrap.invDate = dt.addDays(-(days));
                                  }else if(invConfig.Invoice_Date__c.contains('After')){
                                      invoppWrap.invDate = dt.addDays(days);
                                  }
                              }
                          }
                          
                          if(invConfig.Invoice_Due_Date__c != null){
                              String invDue = invConfig.Invoice_Due_Date__c.substringAfterLast(';');
                              if(invDue != null && invDue != ''){
                                  Date dt = date.valueOf(opp.get(invConfig.Invoice_Due_Date__c.substringAfterLast(';'))) != null ? date.valueOf(opp.get(invConfig.Invoice_Due_Date__c.substringAfterLast(';'))) : null;
                                  Integer days = Integer.valueOf(invConfig.Invoice_Due_Date__c.substringBefore(';'));
                                  if(invConfig.Invoice_Due_Date__c.contains('Before')){
                                      invoppWrap.dueDate = dt.addDays(-(days));
                                  }else if(invConfig.Invoice_Due_Date__c.contains('After')){
                                      invoppWrap.dueDate = dt.addDays(days);
                                  }
                              }
                          }
                          
                          if(invConfig.Invoice_Reference__c != null && invConfig.Invoice_Reference__c != ''){
                              invoppWrap.reference = (String.ValueOf(opp.get(invConfig.Invoice_Reference__c)) != null && String.ValueOf(opp.get(invConfig.Invoice_Reference__c)) != '') ? String.ValueOf(opp.get(invConfig.Invoice_Reference__c)) : '';
                          }
                          
                          if(UserInfo.isMultiCurrencyOrganization()){
                              if(opp.get('CurrencyIsoCode') != '' || opp.get('CurrencyIsoCode') != null){
                                  invoppWrap.CurrencyIsoCode = (String)opp.get('CurrencyIsoCode');
                              }
                          }else{
                              invoppWrap.CurrencyIsoCode = UserInfo.getDefaultCurrency();
                          }
                      }else{
                          throw new AuraHandledException(flsWrap.message);
                      }
                  }
              }
            
        } catch (Exception e) {
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return invoppWrap;
    }
    
    /**
* @description Method to create new contacts & contact persons in Xero if not exists 
* @return InvoiceCreationWrapper.XeroConWrapper
* @param accdetails
* @param condetails
* @param conPersonDetails
* @param oppId
*/
    @AuraEnabled
    public static InvoiceCreationWrapper.XeroConWrapper createXeroContact( String accdetails, String condetails, String conPersonDetails, string oppId){
        List<KTXero__Log__c> logList = new list<KTXero__Log__c>();
        
        InvoiceCreationWrapper.XeroConWrapper xcw = new InvoiceCreationWrapper.XeroConWrapper();
        Boolean successFlag = false;
        String msg = '';
        try {
            InvoiceCreationWrapper.AccWrapper accwrap = new InvoiceCreationWrapper.AccWrapper();
            InvoiceCreationWrapper.ConWrapper conwrap = new InvoiceCreationWrapper.ConWrapper();
            List<InvoiceCreationWrapper.ConWrapper> conPersonwrap = new List<InvoiceCreationWrapper.ConWrapper>();
            if(String.isNotBlank(accdetails)){
                accwrap = (InvoiceCreationWrapper.AccWrapper)JSON.deserialize(accdetails,InvoiceCreationWrapper.AccWrapper.class);
            }
            
            if(String.isNotBlank(condetails)){
                conwrap = (InvoiceCreationWrapper.ConWrapper)JSON.deserialize(condetails,InvoiceCreationWrapper.ConWrapper.class);
            }
            
            if(String.isNotBlank(conPersonDetails)){
                conPersonwrap = (List<InvoiceCreationWrapper.ConWrapper>)JSON.deserialize(conPersonDetails, List<InvoiceCreationWrapper.ConWrapper>.class);
            }
            system.debug('accwrap >'+accwrap);
            system.debug('conwrap >'+conwrap);
            system.debug('conwrap >'+conPersonwrap);
            String accNum = '';
            if(String.isNotBlank(accwrap.accNumber)){
                accNum = accwrap.accNumber;
            }
            
            String phoneNum = '';
            if(String.isNotBlank(accwrap.accPhone)){
                phoneNum = accwrap.accPhone;
            }
            
            String conJSON='{"Contacts": [{"Name": "'+accwrap.accName+'",'+' "FirstName": "'+conwrap.conFirstName+' ",'+' "LastName": "'+conwrap.conLastName+' ",'+'"EmailAddress": "'+conwrap.conEmail+' ",'+'"AccountNumber": "'+accNum+' ",'+'"Addresses": [{"AddressType": "POBOX","AddressLine1": "'+accwrap.accStreet+'","City": "'+accwrap.accCity+'","Region":"'+accwrap.accState+'","PostalCode": "'+accwrap.accPostalCode+'","Country":"'+accwrap.accCountry+'"}],'+'"Phones": [{"PhoneType": "DEFAULT","PhoneNumber": "'+phoneNum+'","PhoneAreaCode": "","PhoneCountryCode": ""}]';
            if(conPersonwrap.size()>0){
                conJSON+=',"ContactPersons": [';
                for(InvoiceCreationWrapper.ConWrapper con : conPersonwrap){
                    conJSON+='{"FirstName": "'+con.conFirstName+'",'+'"LastName": "'+con.conLastName+'",'+'"EmailAddress": "'+con.conEmail+'",'+'"IncludeInEmails": "'+String.valueof(con.includeinEmail)+'"},';
                }
                conJSON = conJSON.removeEnd(',');
                conJSON+=']';
            }
            conJSON+='}]}';
            
            
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
                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Contacts', headerMap, 'POST', conJSON);
                
                HttpResponse response = callObj.response;
                logList.add(callObj.exc);
                if(response.getStatusCode() == 200){
                    
                    InvoiceCreationWrapper.Datawrap ct1 = (InvoiceCreationWrapper.Datawrap)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.Datawrap.class);   
                    InvoiceCreationWrapper.Contacts con = ct1.Contacts[0];
                    //Dynamic logic starts here
                    //Get xero contact object mapping
                    KTXero__Invoice_Configuration_Options__c invoiceConfig = KTXero__Invoice_Configuration_Options__c.getOrgDefaults();
                    String sobjectApiName = invoiceConfig.KTXero__Xero_Contact_Mapping_Object__c;
                    // Get xero contact field mappings 
                    Map<String, String> conFieldMappings = new Map<String, String>();
                    for (KTXero__Xero_Contact_Object_Field_Mapping__c mapping : [SELECT KTXero__Xero_Field_Name__c, KTXero__Field_API_Name__c 
                                                                                 FROM KTXero__Xero_Contact_Object_Field_Mapping__c]) {
                                                                                     conFieldMappings.put(mapping.KTXero__Xero_Field_Name__c, mapping.KTXero__Field_API_Name__c);
                                                                                 }
                    
                    List<SObject> sobjectList = new List<SObject>();
                    SObject xeroConObj = Schema.getGlobalDescribe().get(sobjectApiName).newSObject();
                    //if(conFieldMappings.get('name')?.KTXero__Field_API_Name__c != null) 
                    xeroConObj.put(conFieldMappings.get('name'), con.Name);
                    xeroConObj.put(conFieldMappings.get('firstName'), con.FirstName);
                    xeroConObj.put(conFieldMappings.get('lastName'), con.LastName);
                    xeroConObj.put(conFieldMappings.get('emailAddress'), con.EmailAddress);
                    xeroConObj.put(conFieldMappings.get('accountNumber'), con.AccountNumber);
                    if(String.isNotBlank(accwrap.accId)){
                        xeroConObj.put(conFieldMappings.get('account'), accwrap.accId); 
                    }else{
                        xeroConObj.put(conFieldMappings.get('opportunity'), oppId);  
                        // Get Contact Configuration
                        KTXero__Xero_Contact_Configurations__c conConfig = KTXero__Xero_Contact_Configurations__c.getOrgDefaults();
                        if(conConfig.KTXero__Create_Account_if_not_available__c){
                            List<Account> accList = new List<Account>();
                            accList = [SELECT Id FROM Account WHERE Name =: con.Name WITH SECURITY_ENFORCED LIMIT 1];
                            if(accList.size() > 0){
                                xeroConObj.put(conFieldMappings.get('account'), accList[0].Id); 
                            }else{
                                Account newAcc = new Account();
                                newAcc.Name = con.Name;
                                Database.SaveResult sr = Database.insert(newAcc, false);
                                if(sr.isSuccess()){
                                    xeroConObj.put(conFieldMappings.get('account'), sr.getId()); 
                                }
                            }
                        }
                    }
                    xeroConObj.put(conFieldMappings.get('contactID'), con.ContactId); 
                    xeroConObj.put(conFieldMappings.get('contactStatus'), con.ContactStatus); 
                    for(Integer i=0;i<con.ContactPersons.size();i++){
                        if(i == 0){
                            xeroConObj.put(conFieldMappings.get('firstName1'), con.ContactPersons[i].FirstName); 
                            xeroConObj.put(conFieldMappings.get('lastName1'), con.ContactPersons[i].LastName);  
                            xeroConObj.put(conFieldMappings.get('emailAddress1'), con.ContactPersons[i].EmailAddress); 
                            xeroConObj.put(conFieldMappings.get('includeInEmails1'), con.ContactPersons[i].IncludeInEmails);
                        }else if(i == 1){
                            xeroConObj.put(conFieldMappings.get('firstName2'), con.ContactPersons[i].FirstName); 
                            xeroConObj.put(conFieldMappings.get('lastName2'), con.ContactPersons[i].LastName);  
                            xeroConObj.put(conFieldMappings.get('emailAddress2'), con.ContactPersons[i].EmailAddress); 
                            xeroConObj.put(conFieldMappings.get('includeInEmails2'), con.ContactPersons[i].IncludeInEmails);
                        }else if(i == 2){
                            xeroConObj.put(conFieldMappings.get('firstName3'), con.ContactPersons[i].FirstName); 
                            xeroConObj.put(conFieldMappings.get('lastName3'), con.ContactPersons[i].LastName);  
                            xeroConObj.put(conFieldMappings.get('emailAddress3'), con.ContactPersons[i].EmailAddress); 
                            xeroConObj.put(conFieldMappings.get('includeInEmails3'), con.ContactPersons[i].IncludeInEmails);
                        }else if(i == 3){
                            xeroConObj.put(conFieldMappings.get('firstName4'), con.ContactPersons[i].FirstName); 
                            xeroConObj.put(conFieldMappings.get('lastName4'), con.ContactPersons[i].LastName);  
                            xeroConObj.put(conFieldMappings.get('emailAddress4'), con.ContactPersons[i].EmailAddress); 
                            xeroConObj.put(conFieldMappings.get('includeInEmails4'), con.ContactPersons[i].IncludeInEmails); 
                        }else if(i == 4){
                            xeroConObj.put(conFieldMappings.get('firstName5'), con.ContactPersons[i].FirstName); 
                            xeroConObj.put(conFieldMappings.get('lastName5'), con.ContactPersons[i].LastName);  
                            xeroConObj.put(conFieldMappings.get('emailAddress5'), con.ContactPersons[i].EmailAddress); 
                            xeroConObj.put(conFieldMappings.get('includeInEmails5'), con.ContactPersons[i].IncludeInEmails); 
                        }
                    }
                    
                    if(con.Addresses.size()>0){
                        List<InvoiceCreationWrapper.Addresses> addressList = con.Addresses;
                        for(InvoiceCreationWrapper.Addresses add : addressList){
                            if(add.AddressType == 'POBOX'){
                                xeroConObj.put(conFieldMappings.get('addressLine1'), add.AddressLine1);
                                xeroConObj.put(conFieldMappings.get('city'), add.City); 
                                xeroConObj.put(conFieldMappings.get('region'), add.Region);   
                                xeroConObj.put(conFieldMappings.get('postalCode'), add.PostalCode);    
                                xeroConObj.put(conFieldMappings.get('country'), add.Country);    
                            }else if(add.AddressType == 'DELIVERY'){
                                xeroConObj.put(conFieldMappings.get('shippingAddressLine1'), add.AddressLine1);
                                xeroConObj.put(conFieldMappings.get('shippingCity'), add.City); 
                                xeroConObj.put(conFieldMappings.get('shippingRegion'), add.Region);   
                                xeroConObj.put(conFieldMappings.get('shippingPostalCode'), add.PostalCode);    
                                xeroConObj.put(conFieldMappings.get('shippingCountry'), add.Country);
                            }
                        }
                    }
                    sobjectList.add(xeroConObj);
                    //Dynamic Logic Ends here
                    
                    /*List<KTXero__Xero_Contact__c> xconList = new List<KTXero__Xero_Contact__c>();
KTXero__Xero_Contact__c xcon = new KTXero__Xero_Contact__c();
xcon.Company_Name__c = con.Name;
xcon.First_Name__c = con.FirstName;
xcon.Last_Name__c = con.LastName;
xcon.Email_Address__c = con.EmailAddress;
xcon.KTXero__Account_Number__c = con.AccountNumber;
if(String.isNotBlank(accwrap.accId)){
xcon.Salesforce_Account__c = accwrap.accId;
}else{
xcon.KTXero__Opportunity__c = oppId;
// Get Contact Configuration
KTXero__Xero_Contact_Configurations__c conConfig = KTXero__Xero_Contact_Configurations__c.getOrgDefaults();
if(conConfig.KTXero__Create_Account_if_not_available__c){
List<Account> accList = new List<Account>();
accList = [SELECT Id FROM Account WHERE Name =: con.Name WITH SECURITY_ENFORCED LIMIT 1];
if(accList.size() > 0){
xcon.Salesforce_Account__c = accList[0].Id;
}else{
Account newAcc = new Account();
newAcc.Name = con.Name;
Database.SaveResult sr = Database.insert(newAcc, false);
if(sr.isSuccess()){
xcon.Salesforce_Account__c = sr.getId();
}
}
}
}
xcon.Reference_Id__c = con.ContactId;
xcon.Status__c = con.ContactStatus;
for(Integer i=0;i<con.ContactPersons.size();i++){
if(i == 0){
xcon.Contact_1_First_Name__c = con.ContactPersons[i].FirstName; 
xcon.Contact_1_Last_Name__c = con.ContactPersons[i].LastName; 
xcon.Contact_1_Email__c = con.ContactPersons[i].EmailAddress; 
xcon.Contact_1_Include_in_Emails__c = con.ContactPersons[i].IncludeInEmails; 
}else if(i == 1){
xcon.Contact_2_First_Name__c = con.ContactPersons[i].FirstName; 
xcon.Contact_2_Last_Name__c = con.ContactPersons[i].LastName; 
xcon.Contact_2_Email__c = con.ContactPersons[i].EmailAddress; 
xcon.Contact_2_Include_in_Emails__c = con.ContactPersons[i].IncludeInEmails; 
}else if(i == 2){
xcon.Contact_3_First_Name__c = con.ContactPersons[i].FirstName; 
xcon.Contact_3_Last_Name__c = con.ContactPersons[i].LastName; 
xcon.Contact_3_Email__c = con.ContactPersons[i].EmailAddress; 
xcon.Contact_3_Include_in_Emails__c = con.ContactPersons[i].IncludeInEmails; 
}else if(i == 3){
xcon.Contact_4_First_Name__c = con.ContactPersons[i].FirstName; 
xcon.Contact_4_Last_Name__c = con.ContactPersons[i].LastName; 
xcon.Contact_4_Email__c = con.ContactPersons[i].EmailAddress; 
xcon.Contact_4_Include_in_Emails__c = con.ContactPersons[i].IncludeInEmails; 
}else if(i == 4){
xcon.Contact_5_First_Name__c = con.ContactPersons[i].FirstName; 
xcon.Contact_5_Last_Name__c = con.ContactPersons[i].LastName; 
xcon.Contact_5_Email__c = con.ContactPersons[i].EmailAddress; 
xcon.Contact_5_Include_in_Emails__c = con.ContactPersons[i].IncludeInEmails; 
}
}

if(con.Addresses.size()>0){
List<InvoiceCreationWrapper.Addresses> addressList = con.Addresses;
for(InvoiceCreationWrapper.Addresses add : addressList){
if(add.AddressType == 'POBOX'){
xcon.Street_Address__c = add.AddressLine1;
xcon.Town_City__c = add.City;
xcon.State_Region__c = add.Region;   
xcon.Postal_Zip_Code__c = add.PostalCode;   
xcon.Country__c = add.Country;   
}else if(add.AddressType == 'DELIVERY'){
xcon.Shipping_Street_Address__c = add.AddressLine1;
xcon.Shipping_Town_City__c = add.City;
xcon.Shipping_State_Region__c = add.Region;   
xcon.Shipping_Postal_Zip_Code__c = add.PostalCode;   
xcon.Shipping_Country__c = add.Country;
}
}
}
xconList.add(xcon);*/
                    // insert Xero Contact
                    FLSChecker.FLSCheckWrapper flsWrap = FLSChecker.dmlInsert(sobjectList);
                    successFlag = flsWrap.isSuccess;
                    
                    xcw.xeroContactId = con.ContactId;
                    xcw.xeroContactsfId = xeroConObj.Id;
                    system.debug('xeroConObj.Id > '+xeroConObj.Id);
                    
                }else{
                    InvoiceCreationWrapper.ErrorWrapper invoicewrap = (InvoiceCreationWrapper.ErrorWrapper)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.ErrorWrapper.class);
                    if(invoicewrap.Elements != null){
                        for(InvoiceCreationWrapper.Elements ele : invoicewrap.Elements){
                            for(InvoiceCreationWrapper.ValidationErrors vle : ele.ValidationErrors){
                                msg += vle.Message;
                                msg += ', ';
                            }
                        }
                        msg = msg.removeEnd(', ');
                    }else{
                        msg = invoicewrap.Message;
                    }
                    successFlag = false;
                }
                
                if( logList.size() > 0 && Schema.sObjectType.KTXero__Log__c.isCreateable()){
                    insert logList;
                }
                
                if(!flag && connection != null && Schema.sObjectType.KTXero__Xero_Connection__c.isUpdateable()){
                    Database.update(connection);
                }
            }
        } catch (Exception e) {
            successFlag = false;
            msg += e.getMessage();
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            logList.add(logObj);
            if(logList.size() > 0 && Schema.sObjectType.KTXero__Log__c.isCreateable()){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    throw new AuraHandledException(flsWrap.message);
                }
            }
            
        }
        xcw.successFlag = successFlag;
        xcw.message = msg;
        system.debug('xcw > '+xcw);
        return xcw;
    }
    
    /**
* @description Method to create new Xero Invoice if not exists 
* @return InvoiceCreationWrapper.XeroWrapper
* @param contactId
* @param currencyCode
* @param invoiceData
* @param state
* @param xeroContactId
*/
    @AuraEnabled
    public static InvoiceCreationWrapper.XeroWrapper createXeroInvoice(String contactId, String currencyCode, String invoiceData, String state, String xeroContactId){
        List<KTXero__Log__c> logList = new list<KTXero__Log__c>();
        
        
        InvoiceCreationWrapper.InvoiceDataWrapper invdataWrap = new InvoiceCreationWrapper.InvoiceDataWrapper();
        //List<Invoice_Line_Item__c> lineItemList = new List<Invoice_Line_Item__c>();
        List<SObject> invLnItmSobjectList = new List<SObject>();
        InvoiceCreationWrapper.XeroWrapper  xw = new InvoiceCreationWrapper.XeroWrapper();
        Boolean sendEmail = false;
        String msg = '';
        Boolean successFlag = false;
        
        try {
            if(String.isNotBlank(invoiceData)){
                invdataWrap = (InvoiceCreationWrapper.InvoiceDataWrapper)JSON.deserialize(invoiceData,InvoiceCreationWrapper.InvoiceDataWrapper.class);
                if(state == 'ApprovedEmail'){
                    state = 'AUTHORISED';
                    sendEmail = true;
                }
                
                String invJSON = '{"Type":"ACCREC"';
                if(invdataWrap.invoiceduedate == null){
                    invdataWrap.invoiceduedate = '';
                }
                if(invdataWrap.reference == null){
                    invdataWrap.reference = '';
                }
                invJSON += ',"Contact": {"ContactID":"'+xeroContactId+'"},"DateString":"'+String.valueOf(invdataWrap.invoicedate)+'","CurrencyCode":"'+currencyCode+'","Reference":"'+invdataWrap.reference+'","DueDateString":"'+invdataWrap.invoiceduedate+'","BrandingThemeID":"'+invdataWrap.template+'","Status":"'+state+'","LineAmountTypes": "'+invdataWrap.amountTax+'"';
                
                if(invdataWrap.lineItems.size()>0){
                    invJSON += ',"LineItems": [';
                    for(InvoiceCreationWrapper.OppproductWrapper opw : invdataWrap.lineItems){
                        if(opw.description == null || opw.description == ''){
                            invJSON += '{"Description": "-"';
                        }else{
                            invJSON += '{"Description": "'+opw.description+'"';
                        }
                        if(String.isNotBlank(opw.taxRate) && opw.taxRate != '' && opw.taxRate != null){
                            invJSON += ',"TaxType": "'+opw.taxRate+'"';
                        }
                        
                        invJSON += ',"Quantity": "'+opw.quantity+'","UnitAmount": "'+opw.unitPrice+'","DiscountRate" : "'+opw.discount+'"';
                        if(String.isNotBlank(opw.account) && opw.account != 'NaN' && opw.account != null){
                            // invJSON += ',"AccountCode": "'+Integer.ValueOf(opw.account)+'"';
                            invJSON += ',"AccountCode": "'+opw.account+'"';
                        }else{
                            invJSON += ',"AccountCode": ""';
                        }
                        if(String.isNotBlank(opw.productCode)){
                            invJSON +=',"ItemCode": "'+opw.productCode+'"';
                        }
                        
                        if(opw.trackingData != null){
                            invJSON += ',"Tracking": [';
                            for(InvoiceCreationWrapper.KeyValuePair kp : opw.trackingData){
                                if(kp.value != null){
                                    if(kp.value.defaultVal != null && kp.value.optname != null){
                                        invJSON += '{"TrackingCategoryID": "'+kp.value.defaultVal+'","Name": "'+kp.key+'","Option": "'+kp.value.optname+'"},';
                                    }
                                }
                            }
                            invJSON = invJSON.removeEnd(',');
                            invJSON += ']';
                        }
                        invJSON += '},';
                    }
                    invJSON = invJSON.removeEnd(',');
                    invJSON += ']}';
                    
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
                        XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Invoices', headerMap, 'POST', invJSON);
                        
                        HttpResponse response = callObj.response;
                        logList.add(callObj.exc);
                        if(response.getStatusCode() == 200){
                            InvoiceCreationWrapper.DataInvoiceWrap invoicewrap = (InvoiceCreationWrapper.DataInvoiceWrap)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.DataInvoiceWrap.class);
                            msg = invoicewrap.Invoices[0].InvoiceID;
                            InvoiceCreationWrapper.Invoices invoice = invoicewrap.Invoices[0];
                            if(sendEmail && String.isNotBlank(msg)){
                                
                                XeroHttpCallout.CalloutWrapper callObj1 = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Invoices/'+msg+'/Email', headerMap, 'POST', '');
                                logList.add(callObj1.exc);
                                
                            }
                            //Invoice Creation dynamic logic starts here
                            //Get Invoice object mapping
                            KTXero__Invoice_Configuration_Options__c invoiceConfig = KTXero__Invoice_Configuration_Options__c.getOrgDefaults();
                            String invSobjectApiName = invoiceConfig.KTXero__Invoice_Mapping_Obj__c;
                            // Get Invoice field mappings 
                            Map<String, String> invoiceFieldMappings = new Map<String, String>();
                            for (KTXero__Invoice_Object_Field_Mapping__c mapping : [SELECT KTXero__Xero_Field_Name__c, KTXero__Field_API_Name__c 
                                                                                    FROM KTXero__Invoice_Object_Field_Mapping__c]) {
                                                                                        invoiceFieldMappings.put(mapping.KTXero__Xero_Field_Name__c, mapping.KTXero__Field_API_Name__c);
                                                                                    }
                            
                            List<SObject> invoiceSobjectList = new List<SObject>();
                            
                            SObject invObj = Schema.getGlobalDescribe().get(invSobjectApiName).newSObject();
                            invObj.put(invoiceFieldMappings.get('invoiceNumber'), invoice.InvoiceNumber);
                            if(String.isNotBlank(invdataWrap.accountId)){
                                invObj.put(invoiceFieldMappings.get('account'), invdataWrap.accountId); //Account__c
                            }
                            invObj.put(invoiceFieldMappings.get('brandingThemeID'), invoice.BrandingThemeID); //Branding_Theme_Id__c
                            invObj.put(invoiceFieldMappings.get('contact'), contactId); //Xero_Contact__c
                            if(invdataWrap.recordId.startsWith('001')){
                                invObj.put(invoiceFieldMappings.get('account'), invdataWrap.recordId); //Need to discuss
                            }else{
                                invObj.put(invoiceFieldMappings.get('opportunity'), invdataWrap.recordId);
                            }
                            invObj.put(invoiceFieldMappings.get('invoiceID'), invoice.InvoiceID); //Invoice_Id__c
                            invObj.put(invoiceFieldMappings.get('reference'), invoice.Reference);
                            invObj.put(invoiceFieldMappings.get('type'), invoice.Type);
                            invObj.put(invoiceFieldMappings.get('amountDue'), invoice.AmountDue);
                            invObj.put(invoiceFieldMappings.get('amountPaid'), invoice.AmountPaid);
                            invObj.put(invoiceFieldMappings.get('sentToContact'), invoice.SentToContact);
                            invObj.put(invoiceFieldMappings.get('currencyRate'), invoice.CurrencyRate);
                            invObj.put(invoiceFieldMappings.get('currencyCode'), invoice.CurrencyCode);
                            if(Userinfo.isMultiCurrencyOrganization()){
                                invObj.put('CurrencyIsoCode',invoice.CurrencyCode); //Do we need to map this?
                            }
                            invObj.put(invoiceFieldMappings.get('status'), invoice.Status);
                            invObj.put(invoiceFieldMappings.get('dateString'), date.valueOf(invoice.DateString));
                            if(invoice.DueDateString != null){
                                invObj.put(invoiceFieldMappings.get('dueDateString'), date.valueOf(invoice.DueDateString));
                            }
                            invObj.put(invoiceFieldMappings.get('total'), invoice.Total);
                            invObj.put(invoiceFieldMappings.get('subTotal'), invoice.SubTotal);
                            invObj.put(invoiceFieldMappings.get('totalTax'), invoice.TotalTax);
                            invObj.put(invoiceFieldMappings.get('lineAmountTypes'), invoice.LineAmountTypes);
                            invoiceSobjectList.add(invObj);
                            
                            //Old logic
                            /*List<KTXero__Invoice__c> invList = new List<KTXero__Invoice__c>();
Invoice__c inv = new Invoice__c();
inv.Name = invoice.InvoiceNumber;
if(String.isNotBlank(invdataWrap.accountId)){
inv.Account__c = invdataWrap.accountId;
}
inv.Branding_Theme_Id__c = invoice.BrandingThemeID;
inv.Xero_Contact__c = contactId;
if(invdataWrap.recordId.startsWith('001')){
inv.Account__c = invdataWrap.recordId;
}else{
inv.Opportunity__c = invdataWrap.recordId;
}
inv.Invoice_Id__c = invoice.InvoiceID;
inv.Reference__c = invoice.Reference;
inv.Type__c = invoice.Type;
inv.Amount_Due__c = invoice.AmountDue;
inv.Amount_Paid__c = invoice.AmountPaid;
inv.Sent_to_Contact__c = invoice.SentToContact;
inv.Currency_Rate__c = invoice.CurrencyRate;
inv.Currency_Code__c = invoice.CurrencyCode;
if(Userinfo.isMultiCurrencyOrganization()){
inv.put('CurrencyIsoCode',invoice.CurrencyCode);
}
inv.Status__c = invoice.Status;
inv.Invoice_Date__c = date.valueOf(invoice.DateString);
if(invoice.DueDateString != null){
inv.Due_Date__c = date.valueOf(invoice.DueDateString);
}
inv.Total__c = invoice.Total;
inv.Sub_Total__c = invoice.SubTotal;
inv.Total_Tax__c = invoice.TotalTax;
inv.Amounts_Are__c = invoice.LineAmountTypes;
invList.add(inv); */
                            // Insert invoice
                            FLSChecker.FLSCheckWrapper flsWrap1 = FLSChecker.dmlInsert(invoiceSobjectList);
                            successFlag = flsWrap1.isSuccess;
                            
                            if(invoice.LineItems.size() > 0){
                                List<InvoiceCreationWrapper.LineItems> lineItemsList = invoice.LineItems;
                                Set<String> itemIdSet = new Set<String>();
                                for(InvoiceCreationWrapper.LineItems li : lineItemsList){
                                    if(li.Item?.ItemId != null){
                                        itemIdSet.add(li.Item.ItemId);
                                    }
                                }
                                
                                List<Product2> prodList = [SELECT Id, KTXero__Xero_ItemID__c FROM Product2 WHERE KTXero__Xero_ItemID__c IN: itemIdSet WITH SECURITY_ENFORCED];
                                Map<String,String> prodMap = new Map<String,String>();
                                for(Product2 pro : prodList){
                                    prodMap.put(pro.KTXero__Xero_ItemID__c,pro.Id);
                                }
                                //Invoice Line Item dynamic logic starts here
                                //Get Invoice Line object mapping
                                String invLnItmSobjtApiName = invoiceConfig.KTXero__Invoice_LineItem_Mapping_Obj__c;
                                // Get Invoice field mappings 
                                Map<String, String> invLnItmFieldMap = new Map<String, String>();
                                for (KTXero__Invoice_LineItem_Obj_Field_Mapping__c mapping : [SELECT KTXero__Xero_Field_Name__c, KTXero__Field_API_Name__c 
                                                                                              FROM KTXero__Invoice_LineItem_Obj_Field_Mapping__c]) {
                                                                                                  invLnItmFieldMap.put(mapping.KTXero__Xero_Field_Name__c, mapping.KTXero__Field_API_Name__c);
                                                                                              }
                                
                                SObjectType invLnItmsobjType = Schema.getGlobalDescribe().get(invLnItmSobjtApiName);
                                
                                for(Integer i=0;i<lineItemsList.size();i++){
                                    SObject invLnItemObj = invLnItmsobjType.newSObject();
                                    //invLnItemObj.put(invLnItmFieldMap.get('InvoiceNumber'), 'LineItem-'+(i+1)+' | '+invoice.InvoiceNumber);
                                    invLnItemObj.put('Name', 'LineItem-'+(i+1)+' | '+invoice.InvoiceNumber);
                                    invLnItemObj.put(invLnItmFieldMap.get('accountCode'), lineItemsList[i].AccountCode);
                                    invLnItemObj.put(invLnItmFieldMap.get('description'), lineItemsList[i].Description);
                                    invLnItemObj.put(invLnItmFieldMap.get('discountRate'), lineItemsList[i].DiscountRate);
                                    invLnItemObj.put(invLnItmFieldMap.get('InvoiceId'), invObj.Id);  //Newly Added
                                    invLnItemObj.put(invLnItmFieldMap.get('lineAmount'), lineItemsList[i].LineAmount);
                                    invLnItemObj.put(invLnItmFieldMap.get('lineItemID'), lineItemsList[i].LineItemID);
                                    invLnItemObj.put(invLnItmFieldMap.get('quantity'), lineItemsList[i].Quantity);
                                    invLnItemObj.put(invLnItmFieldMap.get('taxAmount'), lineItemsList[i].TaxAmount);
                                    invLnItemObj.put(invLnItmFieldMap.get('taxType'), lineItemsList[i].TaxType);
                                    invLnItemObj.put(invLnItmFieldMap.get('unitAmount'), lineItemsList[i].UnitAmount);
                                    if(Userinfo.isMultiCurrencyOrganization()){
                                        invLnItemObj.put('currencyIsoCode',invoice.CurrencyCode); //Need to discuss
                                    }
                                    invLnItemObj.put(invLnItmFieldMap.get('discountAmount'), lineItemsList[i].DiscountAmount);
                                    
                                    if(lineItemsList[i].Item?.ItemId != null){
                                        if(prodMap.containsKey(lineItemsList[i].Item.ItemId)){
                                            invLnItemObj.put(invLnItmFieldMap.get('productId'), prodMap.get(lineItemsList[i].Item.ItemId));
                                        }
                                    }
                                    if(lineItemsList[i].Tracking.size()>0){
                                        List<InvoiceCreationWrapper.Tracking> trackList = lineItemsList[i].Tracking;
                                        for(Integer j=0;j<trackList.size();j++){
                                            if(i == 0){
                                                invLnItemObj.put(invLnItmFieldMap.get('Option1'), trackList[j].Option); //Newly Added
                                                //l.Tracking_Category_1__c = trackList[j].Option;
                                            }else if(i == 1){
                                                invLnItemObj.put(invLnItmFieldMap.get('Option2'), trackList[j].Option); //Newly Added
                                                //l.Tracking_Category_2__c = trackList[j].Option;
                                            }
                                        }
                                    }
                                    invLnItmSobjectList.add(invLnItemObj);
                                }
                            }
                            
                            
                            /*for(Integer i=0;i<lineItemsList.size();i++){
Invoice_Line_Item__c l = new Invoice_Line_Item__c();
l.Name = 'LineItem-'+(i+1)+' | '+invoice.InvoiceNumber;
l.Account_Code__c = lineItemsList[i].AccountCode;
l.Description__c = lineItemsList[i].Description;
l.Discount_Rate__c = lineItemsList[i].DiscountRate;
l.Invoice__c = invObj.Id; //inv.Id; Old
l.Line_Amount__c = lineItemsList[i].LineAmount;
l.Line_Item_Id__c = lineItemsList[i].LineItemID;
l.Quantity__c = lineItemsList[i].Quantity;
l.Tax_Amount__c = lineItemsList[i].TaxAmount;
l.Tax_Type__c = lineItemsList[i].TaxType;
l.Unit_Price__c = lineItemsList[i].UnitAmount;
if(Userinfo.isMultiCurrencyOrganization()){
l.put('currencyIsoCode',invoice.CurrencyCode);
}

l.Discount_Amount__c = lineItemsList[i].DiscountAmount;
if(lineItemsList[i].Item?.ItemId != null){
if(prodMap.containsKey(lineItemsList[i].Item.ItemId)){
l.KTXero__Product__c = prodMap.get(lineItemsList[i].Item.ItemId);
}
}
if(lineItemsList[i].Tracking.size()>0){
List<InvoiceCreationWrapper.Tracking> trackList = lineItemsList[i].Tracking;
for(Integer j=0;j<trackList.size();j++){
if(i == 0){
l.Tracking_Category_1__c = trackList[j].Option;
}else if(i == 1){
l.Tracking_Category_2__c = trackList[j].Option;
}
}
}
lineItemList.add(l);
}
}*/
                            msg = invObj.Id; //inv.Id; Old
                            
                            if(invLnItmSobjectList.size() > 0){
                                
                                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                                flsWrap = FLSChecker.dmlInsert(invLnItmSobjectList);
                                if(!flsWrap.isSuccess){
                                    throw new AuraHandledException(flsWrap.message);
                                }else{
                                    successFlag = true;
                                }
                            }
                        }else{
                            InvoiceCreationWrapper.ErrorWrapper invoicewrap = (InvoiceCreationWrapper.ErrorWrapper)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.ErrorWrapper.class);
                            if(invoicewrap.Elements != null){
                                for(InvoiceCreationWrapper.Elements ele : invoicewrap.Elements){
                                    for(InvoiceCreationWrapper.ValidationErrors vle : ele.ValidationErrors){
                                        msg += vle.Message;
                                        msg += ', ';
                                    }
                                }
                                msg = msg.removeEnd(', ');
                            }else{
                                msg = invoicewrap.Message;
                            }
                            successFlag = false;
                            
                        }
                        
                        if(!flag && connection != null && Schema.sObjectType.KTXero__Xero_Connection__c.isUpdateable()){
                            Database.update(connection);
                        }
                    }
                }
            } 
            if(logList.size() > 0 && Schema.sObjectType.KTXero__Log__c.isCreateable()){
                Database.insert(logList);
            }
        } catch (Exception e) {
            successFlag = false;
            msg += e.getMessage();
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            logList.add(logObj);
            if(logList.size() > 0 && Schema.sObjectType.KTXero__Log__c.isCreateable()){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    throw new AuraHandledException(flsWrap.message);
                }
            }
        }
        xw.successFlag = successFlag;
        xw.message = msg;
        
        return xw;
    }
    
    
    /**
* @description Method to fetch KTXero__Invoice_Configuration_Options__c data
* @description Commenting KTXero__Default_Acc_code__c (Number) as it is replaced with new field KTXero__Account_code_default__c (String) || Yash Patel || 7 May 2024
* @return InvoiceCreationWrapper.InvoiceConfigWrapper
*/
    @AuraEnabled
    public static InvoiceCreationWrapper.InvoiceConfigWrapper getInvoiceConfiguration(){
        InvoiceCreationWrapper.InvoiceConfigWrapper icw = new InvoiceCreationWrapper.InvoiceConfigWrapper();
        try{
            KTXero__Invoice_Configuration_Options__c config = [SELECT 
                                                               Id, Name, SetupOwnerId, KTXero__Default_Tax_rate__c, 
                                                               KTXero__Draft_Invoice__c, KTXero__Submit_for_approval__c, 
                                                               KTXero__Approved_invoice__c, KTXero__Approved_and_Email__c, 
                                                               KTXero__Account_code_default__c, KTXero__Invoice_Template__c,
                                                               KTXero__Invoice_Date__c, KTXero__Invoice_Due_Date__c, KTXero__Line_Item_Description__c,
                                                               KTXero__Invoice_Reference__c, KTXero__Xero_Accounting_Tax_Type__c
                                                               FROM KTXero__Invoice_Configuration_Options__c 
                                                               WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED];
            icw.id = Config.Id;
            icw.draft = config.KTXero__Draft_Invoice__c;
            icw.submit = config.KTXero__Submit_for_approval__c;
            icw.approved = config.KTXero__Approved_invoice__c;
            icw.approvedEmail = config.KTXero__Approved_and_Email__c;
            icw.invtaxType = config.KTXero__Xero_Accounting_Tax_Type__c != null ? config.KTXero__Xero_Accounting_Tax_Type__c : '';
            //Commenting KTXero__Default_Acc_code__c (Number) as it is replaced with now with new KTXero__Account_code_default__c (String) field
            // icw.accCode = config.KTXero__Default_Acc_code__c;
            icw.accCode = config.KTXero__Account_code_default__c;
            icw.invTemplate = config.KTXero__Invoice_Template__c;
            icw.taxRate = config.KTXero__Default_Tax_rate__c;
            
            //INVOICE FIELDS FROM CUSTOM SETTINGS
            icw.invoiceReference = config.KTXero__Invoice_Reference__c != null ? config.KTXero__Invoice_Reference__c : '';
            icw.lineItemDescription = config.KTXero__Line_Item_Description__c != null ? config.KTXero__Line_Item_Description__c : '';
            icw.invoiceDueDate = config.KTXero__Invoice_Due_Date__c != null ? config.KTXero__Invoice_Due_Date__c : '';
            icw.invoiceDate = config.KTXero__Invoice_Date__c != null ? config.KTXero__Invoice_Date__c : '';
            
        }catch(Exception e){
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return icw;
    }
    
    
    /**
* @description Method to create new Xero Invoice if not exists 
* @return Boolean
* @param invoiceId
* @param invStatus
* @param recordId
*/
    @AuraEnabled
    public static Boolean deleteInvoice(String invoiceId, String invStatus, String recordId){
        List<KTXero__Log__c> logList = new list<KTXero__Log__c>();
        Boolean updated = false;
        try {
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
                String reqBody = '{"InvoiceID": "'+invoiceId+'","Status": "'+invStatus+'"}';
                
                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Invoices/'+invoiceId, headerMap, 'POST', reqBody);
                
                HttpResponse response = callObj.response;
                logList.add(callObj.exc);
                if(response.getStatusCode() == 200){
                    InvoiceCreationWrapper.DataInvoiceWrap invoicewrap = (InvoiceCreationWrapper.DataInvoiceWrap)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.DataInvoiceWrap.class);
                    String invresStatus = invoicewrap.Invoices[0].Status;
                    
                    KTXero__Invoice__c inv = new KTXero__Invoice__c();
                    inv.Id = recordId;
                    inv.Status__c = invresStatus;
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    List<KTXero__Invoice__c> invList = new List<KTXero__Invoice__c>();
                    invList.add(inv);
                    
                    flsWrap = FLSChecker.dmlUpdate(invList);
                    if(!flsWrap.isSuccess){
                        updated = flsWrap.isSuccess;
                    }else{
                        updated = flsWrap.isSuccess;             
                    }
                    
                }
                if(logList.size() > 0 && Schema.sObjectType.KTXero__Log__c.isCreateable()){
                    insert logList;
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
        } catch (Exception e) {
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        
        return updated;
    }
    
    /**
* @description Method to fetch KTXero__Invoice_Configuration_Options__c data
* @return InvoiceCreationWrapper.ProductConfigWrapper
* @param recId
*/
    @AuraEnabled
    public static InvoiceCreationWrapper.ProductConfigWrapper getProductSyncConfig(String recId){
        
        InvoiceCreationWrapper.ProductConfigWrapper pcw = new InvoiceCreationWrapper.ProductConfigWrapper();
        try {
            KTXero__Invoice_Configuration_Options__c configObj = KTXero__Invoice_Configuration_Options__c.getInstance();
            pcw.createProInXero = configObj.KTXero__Create_items_in_Xero__c;
            pcw.createProInSales = configObj.KTXero__Create_products_in_Salesforce__c;
            
        } catch (Exception e) {
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return pcw;
    }
    
    
    /**
* @description Method to create products in Xero if not exists and update back in salesforce 
* @return InvoiceCreationWrapper.XeroWrapper
* @param lineItemData
*/
    @AuraEnabled
    public static InvoiceCreationWrapper.XeroWrapper createXeroItem(String lineItemData){
        List<KTXero__Log__c> logList = new list<KTXero__Log__c>();
        Boolean successFlag = false;
        
        List<InvoiceCreationWrapper.OppproductWrapper> oppProducts =  new List<InvoiceCreationWrapper.OppproductWrapper>();
        List<Product2> productList = new List<Product2>();
        InvoiceCreationWrapper.XeroWrapper  xw = new InvoiceCreationWrapper.XeroWrapper();
        String msg = '';
        try {
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
                Map<String, String> oppProdMap = new Map<String, String>();
                oppProducts = (List<InvoiceCreationWrapper.OppproductWrapper>)JSON.deserialize(lineItemData,List<InvoiceCreationWrapper.OppproductWrapper>.class);
                
                Set<String> prodCodeSet = new Set<String>();
                String itemsJSON = '{"Items":[';
                for(InvoiceCreationWrapper.OppproductWrapper oppwrap : oppProducts){
                    if(!prodCodeSet.contains(oppwrap.productCode)){
                        itemsJSON += '{"Code": "'+oppwrap.productCode+'","Name": "'+oppwrap.productName+'"},';
                        oppProdMap.put(oppwrap.productCode,oppwrap.productId);
                        prodCodeSet.add(oppwrap.productCode);
                    }
                }
                itemsJSON = itemsJSON.removeEnd(',');
                itemsJSON += ']}';
                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Items', headerMap, 'POST', itemsJSON);
                HttpResponse response = callObj.response;
                logList.add(callObj.exc);
                
                if(response.getStatusCode() == 200){
                    InvoiceCreationWrapper.XeroItemWrapper xiw = (InvoiceCreationWrapper.XeroItemWrapper)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.XeroItemWrapper.class);
                    if(xiw.Items.size()>0){
                        for(InvoiceCreationWrapper.Items i : xiw.Items){
                            Product2 prd = new Product2();
                            prd.Id = oppProdMap.get(i.Code);
                            prd.Xero_ItemID__c = i.ItemID;
                            productList.add(prd);
                        }
                        if(productList.size()>0){
                            FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                            flsWrap = FLSChecker.dmlUpdate(productList);
                            if(!flsWrap.isSuccess){
                                successFlag = false;
                            }else{
                                successFlag = true;
                            }
                        }
                    }
                }else{
                    InvoiceCreationWrapper.ErrorWrapper ewrap = (InvoiceCreationWrapper.ErrorWrapper)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.ErrorWrapper.class);
                    for(InvoiceCreationWrapper.Elements ele : ewrap.Elements){
                        for(InvoiceCreationWrapper.ValidationErrors vle : ele.ValidationErrors){
                            msg += vle.Message;
                            msg += ', ';
                        }
                    }
                    msg = msg.removeEnd(', ');
                    successFlag = false;
                }
                
                if(logList.size() > 0 && Schema.sObjectType.KTXero__Log__c.isCreateable()){
                    insert logList;
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
        }catch (Exception e) {
            successFlag = false;
            msg += e.getMessage();
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            logList.add(logObj);
            if(logList.size() > 0 && Schema.sObjectType.KTXero__Log__c.isCreateable()){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    throw new AuraHandledException(flsWrap.message);
                }
            }
        }
        xw.successFlag = successFlag;
        xw.message = msg;
        
        return xw;
    }
    
}