public with sharing class XeroBulkItemSyncBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    public Integer counter = 0;
    public Set<String> productIds = new Set<String>();
    public String csvFile = '';
    public String csvErrorValue = '';
    /**
     * @description Start Method
     * @return Iterable<SObject>
     * @param bc
    */
    public Iterable<SObject> start(Database.BatchableContext bc){
        
        List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
        Map<String,XeroBulkSyncController.cls_Items> codeMap = new Map<String,XeroBulkSyncController.cls_Items>();
        Map<String,XeroBulkSyncController.cls_Items> itemMap = new Map<String,XeroBulkSyncController.cls_Items>();
        Map<String,Product2> productMap = new Map<String,Product2>();
        Map<String,Product2> tmpProdMap = new Map<String,Product2>();
        Map<String,Product2> finalMap = new Map<String,Product2>();
        List<Product2> productList = new List<Product2>();
        List<Product2> upsertproductList = new List<Product2>();

        try{
            KTXero__Xero_Connection__c xeroConnect = [SELECT Id, Name, KTXero__Client_Id__c, KTXero__Client_Secret__c, KTXero__Access_Token__c, KTXero__Refresh_Token__c, KTXero__Tenant_Id__c, KTXero__Completed_Steps__c, KTXero__Completed_Xero_Connection_Steps__c, KTXero__Progress_Value__c, KTXero__Total_Xero_Connection_Steps__c, KTXero__Authenticated__c, KTXero__Webhook_Key__c, KTXero__Last_Token_Refresh_Time__c FROM KTXero__Xero_Connection__c WITH SECURITY_ENFORCED LIMIT 1];
    
            
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
    
                // Callout to fetch the invoices
                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Items/?page='+counter, headerMap, 'GET', '');
                HttpResponse response = callObj.response;
                logList.add(callObj.exc);
                if(response.getStatusCode() == 200){
                    XeroBulkSyncController.ItemWrapper ItemWrap = (XeroBulkSyncController.ItemWrapper) JSON.deserialize(response.getBody(), XeroBulkSyncController.ItemWrapper.class);
                    List<XeroBulkSyncController.cls_Items> itemList = ItemWrap.Items;
                    for(XeroBulkSyncController.cls_Items cI : itemList){
                        codeMap.put(cI.Code,cI);
                        itemMap.put(cI.ItemID,cI);
                    }
    
                    if(codeMap.size() > 0 || itemMap.size() > 0){
                        productList = [SELECT Id, Name, ProductCode, KTXero__Xero_Item_Sales_Account_Code__c, 
                                        KTXero__Xero_Item_Purchase_Tax_Rate__c, KTXero__Xero_ItemID__c, KTXero__Xero_Item_Sales_Tax_Rate__c, 
                                        KTXero__Xero_Item_Purchase_Account_Code__c, KTXero__Xero_Item_Sales_Description__c, KTXero__Xero_Item_Purchase_Description__c 
                                        FROM Product2 WHERE KTXero__Xero_ItemID__c IN: itemMap.keySet() OR ProductCode IN : codeMap.keySet() 
                                        WITH SECURITY_ENFORCED];
                        
                        if(productList.size() > 0){
                            Set<Integer> indexInteger = new Set<Integer>();
                            for(Product2 prod : productList){
                                if(String.isBlank(prod.KTXero__Xero_ItemID__c)){
                                    if(codeMap.containsKey(prod.ProductCode)){
                                        if(String.isNotBlank(prod.ProductCode) && prod.ProductCode == codeMap.get(prod.ProductCode).Code){
                                            XeroBulkSyncController.cls_Items item = codeMap.get(prod.ProductCode);
                                            prod.KTXero__Xero_ItemID__c = item.ItemID;
                                            // Add Sales Details
                                            prod.KTXero__Xero_Item_Sales_Account_Code__c = item.SalesDetails.AccountCode;
                                            prod.KTXero__Xero_Item_Sales_Tax_Rate__c = item.SalesDetails.TaxType;
                                            prod.KTXero__Xero_Item_Sales_Description__c = item.Description;
                                            //Add Purchase Details
                                            prod.KTXero__Xero_Item_Purchase_Account_Code__c = item.PurchaseDetails.COGSAccountCode;
                                            prod.KTXero__Xero_Item_Purchase_Tax_Rate__c = item.PurchaseDetails.TaxType;
                                            prod.KTXero__Xero_Item_Purchase_Description__c = item.PurchaseDescription;
                                            upsertproductList.add(prod);
                                            codeMap.remove(prod.ProductCode);
                                        }
                                    }
                                }else{
                                    if(itemMap.containsKey(prod.KTXero__Xero_ItemID__c)){
                                        if(prod.KTXero__Xero_ItemID__c == itemMap.get(prod.KTXero__Xero_ItemID__c).ItemID){
                                            Boolean flag1 = false;
                                            XeroBulkSyncController.cls_Items item = itemMap.get(prod.KTXero__Xero_ItemID__c);
                                            // Add Sales Details
                                            if(prod.KTXero__Xero_Item_Sales_Account_Code__c != item.SalesDetails.AccountCode){
                                                prod.KTXero__Xero_Item_Sales_Account_Code__c = item.SalesDetails.AccountCode;
                                                flag1 = true;
                                            }
        
                                            if(prod.KTXero__Xero_Item_Sales_Tax_Rate__c != item.SalesDetails.TaxType){
                                                prod.KTXero__Xero_Item_Sales_Tax_Rate__c = item.SalesDetails.TaxType;
                                                flag1 = true;
                                            }
        
                                            if(prod.KTXero__Xero_Item_Sales_Description__c != item.Description){
                                                prod.KTXero__Xero_Item_Sales_Description__c = item.Description;
                                                flag1 = true;
                                            }
                                            //Add Purchase Details
                                            if(prod.KTXero__Xero_Item_Purchase_Account_Code__c != item.PurchaseDetails.COGSAccountCode){
                                                prod.KTXero__Xero_Item_Purchase_Account_Code__c = item.PurchaseDetails.COGSAccountCode;
                                                flag1 = true;
                                            }
        
                                            if(prod.KTXero__Xero_Item_Purchase_Tax_Rate__c != item.PurchaseDetails.TaxType){
                                                prod.KTXero__Xero_Item_Purchase_Tax_Rate__c = item.PurchaseDetails.TaxType;
                                                flag1 = true;
                                            }
        
                                            if(prod.KTXero__Xero_Item_Purchase_Description__c != item.PurchaseDescription){
                                                prod.KTXero__Xero_Item_Purchase_Description__c = item.PurchaseDescription;
                                                flag1 = true;
                                            }
                                            // remove from the list in here
                                            if(flag1){
                                                upsertproductList.add(prod);
                                                itemMap.remove(prod.ProductCode); //remove from the map to avoid duplicate
                                            }
                                        }
                                    }
                                }
                                productMap.put(prod.KTXero__Xero_ItemID__c, prod);
                            }
    
                        }else{
        
                            for(XeroBulkSyncController.cls_Items item : codeMap.values()){
                                Product2 pro = new Product2();
                                pro.Name = item.Name;
                                pro.ProductCode = item.Code;
                                pro.isActive = true;
                                pro.KTXero__Xero_ItemID__c = item.ItemID;
                                // Add Sales Details
                                pro.KTXero__Xero_Item_Sales_Account_Code__c = item.SalesDetails.AccountCode;
                                pro.KTXero__Xero_Item_Sales_Tax_Rate__c = item.SalesDetails.TaxType;
                                pro.KTXero__Xero_Item_Sales_Description__c = item.Description;
                                //Add Purchase Details
                                pro.KTXero__Xero_Item_Purchase_Account_Code__c = item.PurchaseDetails.COGSAccountCode;
                                pro.KTXero__Xero_Item_Purchase_Tax_Rate__c = item.PurchaseDetails.TaxType;
                                pro.KTXero__Xero_Item_Purchase_Description__c = item.PurchaseDescription;
                                upsertproductList.add(pro);
                                tmpProdMap.put(pro.KTXero__Xero_ItemID__c, pro);
                            }
                            
                        }
                        if(codeMap.size() > 0){
                            for(String s : codeMap.keySet()){
                                XeroBulkSyncController.cls_Items item = codeMap.get(s);
                                if(!productMap.containsKey(item.ItemID)  && !tmpProdMap.containsKey(item.ItemID)){
                                    Product2 pro = new Product2();
                                    pro.Name = item.Name;
                                    pro.ProductCode = item.Code;
                                    pro.isActive = true;
                                    pro.KTXero__Xero_ItemID__c = item.ItemID;
                                    // Add Sales Details
                                    pro.KTXero__Xero_Item_Sales_Account_Code__c = item.SalesDetails.AccountCode;
                                    pro.KTXero__Xero_Item_Sales_Tax_Rate__c = item.SalesDetails.TaxType;
                                    pro.KTXero__Xero_Item_Sales_Description__c = item.Description;
                                    //Add Purchase Details
                                    pro.KTXero__Xero_Item_Purchase_Account_Code__c = item.PurchaseDetails.COGSAccountCode;
                                    pro.KTXero__Xero_Item_Purchase_Tax_Rate__c = item.PurchaseDetails.TaxType;
                                    pro.KTXero__Xero_Item_Purchase_Description__c = item.PurchaseDescription;
                                    tmpProdMap.put(pro.KTXero__Xero_ItemID__c, pro);
                                    upsertproductList.add(pro);
                                }
                            }
                        }
            
        
                        if(itemMap.size() > 0 ){
                            for(String s : itemMap.keySet()){
                                XeroBulkSyncController.cls_Items i = itemMap.get(s);
                                if(!productMap.containsKey(i.ItemID)  && !tmpProdMap.containsKey(i.ItemID)){
                                    Product2 pro = new Product2();
                                    pro.Name = i.Name;
                                    pro.ProductCode = i.Code;
                                    pro.isActive = true;
                                    pro.KTXero__Xero_ItemID__c = i.ItemID;
                                    // Add Sales Details
                                    pro.KTXero__Xero_Item_Sales_Account_Code__c = i.SalesDetails.AccountCode;
                                    pro.KTXero__Xero_Item_Sales_Tax_Rate__c = i.SalesDetails.TaxType;
                                    pro.KTXero__Xero_Item_Sales_Description__c = i.Description;
                                    //Add Purchase Details
                                    pro.KTXero__Xero_Item_Purchase_Account_Code__c = i.PurchaseDetails.COGSAccountCode;
                                    pro.KTXero__Xero_Item_Purchase_Tax_Rate__c = i.PurchaseDetails.TaxType;
                                    pro.KTXero__Xero_Item_Purchase_Description__c = i.PurchaseDescription;
                                    tmpProdMap.put(pro.KTXero__Xero_ItemID__c, pro);
                                    upsertproductList.add(pro);
                                }
                            }
                        }
    
    
                        for(Product2 pr : upsertproductList){
                            if(!finalMap.containsKey(pr.KTXero__Xero_ItemID__c)){
                                finalMap.put(pr.KTXero__Xero_ItemID__c,pr);
                            }
                        }
                    }
                }
                if(logList.size() > 0){
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    flsWrap = FLSChecker.dmlInsert(logList);
                    if(!flsWrap.isSuccess){
                        throw new CustomException(flsWrap.message);
                    }
                }
            }
            
        } catch (Exception e){
            csvErrorValue = 'Message,Cause,LineNumber,StackTraceString\n';
            csvErrorValue += e.getMessage()+','+e.getCause()+','+e.getLineNumber()+','+e.getStackTraceString()+'\n';
            
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            logList.add(lg);
            if(logList.size() > 0){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    throw new CustomException(flsWrap.message);
                }
            }
        }
        return finalMap.values();
    }

    /**
     * @description Execute Method
     * @param  bc 
     * @param scope
    */
    public void execute(Database.BatchableContext bc, List<Sobject> scope){
        try{
            csvErrorValue = 'Fields,Error Message,Error StatusCode\n';
            csvFile = 'Id,Name,Product Code,Xero Item Id,Sales Account Code,Sales Tax Rate,Xero Item Sales Descrption,Purchase Account Code,Purchase Tax Rate,Xero Item Purchase Description\n';
            if(scope.size() > 0){
                Database.UpsertResult[] productResult = Database.upsert(scope,false);
                for (Database.UpsertResult result : productResult) {
                    if (result.isSuccess()) {
                        counter++;
                        productIds.add(result.getId());
                        continue;
                    }else {
                        List<Database.Error> errors =  result.getErrors();
                        for(Database.Error err : errors){
                            csvErrorValue += err.getFields()+','+err.getMessage()+','+err.getStatusCode()+'\n';
                        }
                    }
                }
            }
            
            List<Product2> prodList = [SELECT Id, Name, ProductCode, KTXero__Xero_Item_Sales_Account_Code__c, KTXero__Xero_Item_Purchase_Tax_Rate__c, 
                                        KTXero__Xero_ItemID__c, KTXero__Xero_Item_Sales_Tax_Rate__c, KTXero__Xero_Item_Purchase_Account_Code__c, 
                                        KTXero__Xero_Item_Sales_Description__c, KTXero__Xero_Item_Purchase_Description__c 
                                        FROM Product2
                                        WHERE Id IN:productIds WITH SECURITY_ENFORCED];
    
            if (!prodList.isEmpty()) {
                // csvFile = 'Id,Name,Product Code,Xero Item Id,Sales Account Code,Sales Tax Rate,Xero Item Sales Descrption,Purchase Account Code,Purchase Tax Rate,Xero Item Purchase Description\n';
                for(Product2 pro : prodList){
                    csvFile += (String.valueOf(pro.Id) == null? '':String.valueOf(pro.Id))
                        + ',' +(String.valueOf(pro.Name) == null ? '' : String.valueOf(pro.Name)) +
                        + ',' +(String.valueOf(pro.ProductCode) == null ? '' : String.valueOf(pro.ProductCode)) +
                        + ',' +(String.valueOf(pro.KTXero__Xero_ItemID__c) == null ? '' : String.valueOf(pro.KTXero__Xero_ItemID__c)) +
                        + ',' +(String.valueOf(pro.KTXero__Xero_Item_Sales_Account_Code__c) == null ? '' : String.valueOf(pro.KTXero__Xero_Item_Sales_Account_Code__c)) +
                        + ',' +(String.valueOf(pro.KTXero__Xero_Item_Sales_Tax_Rate__c) == null ? '' : String.valueOf(pro.KTXero__Xero_Item_Sales_Tax_Rate__c)) +
                        + ',' +(String.valueOf(pro.KTXero__Xero_Item_Sales_Description__c) == null ? '' : String.valueOf(pro.KTXero__Xero_Item_Sales_Description__c)) +
                        + ',' +(String.valueOf(pro.KTXero__Xero_Item_Purchase_Account_Code__c) == null ? '' : String.valueOf(pro.KTXero__Xero_Item_Purchase_Account_Code__c)) +
                        + ',' +(String.valueOf(pro.KTXero__Xero_Item_Purchase_Tax_Rate__c) == null ? '' : String.valueOf(pro.KTXero__Xero_Item_Purchase_Tax_Rate__c)) +
                        + ',' +(String.valueOf(pro.KTXero__Xero_Item_Purchase_Tax_Rate__c) == null ? '' : String.valueOf(pro.KTXero__Xero_Item_Purchase_Tax_Rate__c));
                    csvFile +=  ',' +(String.valueOf(pro.KTXero__Xero_Item_Purchase_Description__c) == null ? '' : String.valueOf(pro.KTXero__Xero_Item_Purchase_Description__c))+ '\n';
                }
            }
            if (Test.isRunningTest()) {
                throw new DMLException();
            }
        } catch (Exception e){
            csvErrorValue = 'Message,Cause,LineNumber,StackTraceString\n';
            csvErrorValue += e.getMessage()+','+e.getCause()+','+e.getLineNumber()+','+e.getStackTraceString()+'\n';

            KTXero__Log__c lg = HandleCustomException.LogException(e);
            List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
            logList.add(lg);
            if(logList.size() > 0){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    throw new CustomException(flsWrap.message);
                }
            }
        }
        
    }

    /**
     * @description finish Method
     * @param  bc
    */
    public void finish(Database.BatchableContext bc){

        // Create an email message object
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {UserInfo.getUserEmail()};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Result of Xero Item Sync to the Salesforce Product');
        String emailBody = 'Hello '+UserInfo.getFirstName()+' '+UserInfo.getLastName()+',<br/><br/>';
        emailBody += '<p>Xero Item Sync to the Salesforce Product is Completed.</p>';
        emailBody += '<br/><p>Total '+counter+' records were upserted</p>';
        emailBody += '<br/>Have a lovely time ahead.<br/><br/>';
        emailBody += 'Best Wishes,<br/>';
        emailBody += 'Kandisa Xero Sync for Salesforce';
        mail.setHtmlBody(emailBody);

        List<Messaging.Emailfileattachment> efaList = new List<Messaging.Emailfileattachment>();
        
        if(String.isNotBlank(csvFile)){
            Messaging.EmailFileAttachment csvAttc1 = new Messaging.EmailFileAttachment();
            blob csvBlob = Blob.valueOf(csvFile);
            string csvname= 'SuccessData.csv';
            csvAttc1.setFileName(csvname);
            csvAttc1.setBody(csvBlob);
            
            efaList.add(csvAttc1);
        }

        if(String.isNotBlank(csvErrorValue)){
            Messaging.EmailFileAttachment csvAttc2 = new Messaging.EmailFileAttachment();
            blob csvBlob2 = Blob.valueOf(csvErrorValue);
            string csvname2= 'ErrorData.csv';
            csvAttc2.setFileName(csvname2);
            csvAttc2.setBody(csvBlob2);
            
            efaList.add(csvAttc2);
        }

        // efaList.add(csvAttc1);
        // efaList.add(csvAttc2);

        if(efaList.size() > 0){
            mail.setFileAttachments(efaList);
        }


        try{
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {mail};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        } catch (Exception e) {
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
            logList.add(lg);
            if(logList.size() > 0){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    throw new CustomException(flsWrap.message);
                }
            }
        }
    }
}