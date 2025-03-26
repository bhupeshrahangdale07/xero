public with sharing class XeroBulkSyncBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    public Integer counter;
    public Decimal invCounter = 0;
    public Decimal xConCounter = 0;
    public Decimal productCounter = 0;
    public Decimal accountCounter = 0;
    public Set<Id> invoiceIdSet;
    public Set<Id> xConIdSet;
    public Set<Id> proIdSet;
    public Set<Id> accIdSet;
    public XeroBulkSyncBatch(Integer num, Set<Id> invSet, Set<Id> xConSet, Set<Id> proSet, Set<Id> accSet) {
        counter = num;
        invoiceIdSet = invSet;
        xConIdSet = xConSet;
        proIdSet = proSet;
        accIdSet = accSet;
    }

    public Iterable<SObject> start(Database.BatchableContext bc){
        List<KTXero__Xero_Bulk_Sync_Setting__c> bulkList = new List<KTXero__Xero_Bulk_Sync_Setting__c>();
        bulkList = [SELECT 
                    Id, Name, KTXero__Is_Filter_Sync__c, KTXero__Invoice_Statuses__c, KTXero__Create_Product_in_Salesforce__c,
                    KTXero__Invoice_Status_Operator__c, KTXero__Start_Date__c, KTXero__End_Date__c, KTXero__No_of_Accounts_Created__c,
                    KTXero__Link_Xero_Contact__c, KTXero__Create_Xero_Contact__c, KTXero__Map_Salesforce_Account__c, 
                    KTXero__Company_Name_mapping_field__c, KTXero__Account_Number_mapping_field__c, KTXero__Create_Account__c,
                    KTXero__Xero_Email_mapping_Object__c, KTXero__Xero_Email_mapping_field__c, KTXero__Is_InProgress__c,
                    KTXero__No_of_Invoices_Created__c, KTXero__No_of_XC_Created__c, KTXero__No_of_Products_Created__c
                    FROM KTXero__Xero_Bulk_Sync_Setting__c 
                    WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED];
        
        return bulkList;
    }

    public void execute(Database.BatchableContext bc, List<Sobject> scope){
        try{
            List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
            List<String> xeroConIdSet = new List<String>();
            Map<String,KTXero__Xero_Contact__c> xcIdMap = new Map<String,KTXero__Xero_Contact__c>();
            List<KTXero__Xero_Contact__c> newConList = new List<KTXero__Xero_Contact__c>();
            Map<String,KTXero__Invoice__c> invMap = new Map<String,KTXero__Invoice__c>();
            KTXero__Xero_Connection__c xeroConnect = [SELECT Id, Name, KTXero__Client_Id__c, KTXero__Client_Secret__c, KTXero__Access_Token__c, KTXero__Refresh_Token__c, KTXero__Tenant_Id__c, KTXero__Completed_Steps__c, KTXero__Completed_Xero_Connection_Steps__c, KTXero__Progress_Value__c, KTXero__Total_Xero_Connection_Steps__c, KTXero__Authenticated__c, KTXero__Webhook_Key__c, KTXero__Last_Token_Refresh_Time__c FROM KTXero__Xero_Connection__c WITH SECURITY_ENFORCED LIMIT 1];
            // Database.insert(scope);
            
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
                
                String request = 'https://api.xero.com/api.xro/2.0/Invoices?';
                
                if(!scope.isEmpty()){
                    Map<String,Product2> finalMap = new Map<String,Product2>();
                    // Get filters for endpoint generation and mapping
                    KTXero__Xero_Bulk_Sync_Setting__c bulkSetting = (KTXero__Xero_Bulk_Sync_Setting__c)scope[0];

                    invCounter = bulkSetting.KTXero__No_of_Invoices_Created__c !=null ? bulkSetting.KTXero__No_of_Invoices_Created__c : 0;
                    xConCounter = bulkSetting.KTXero__No_of_XC_Created__c !=null ? bulkSetting.KTXero__No_of_XC_Created__c : 0;
                    productCounter = bulkSetting.KTXero__No_of_Products_Created__c!= null ? bulkSetting.KTXero__No_of_Products_Created__c : 0;
                    accountCounter = bulkSetting.KTXero__No_of_Accounts_Created__c!= null ? bulkSetting.KTXero__No_of_Accounts_Created__c : 0;
    
                    // Endpoint generation starts here
                    if(bulkSetting.KTXero__Is_Filter_Sync__c){
                        Boolean dateFlag = false;
                        if(bulkSetting.KTXero__Start_Date__c != null && bulkSetting.KTXero__End_Date__c != null){
                            request += 'where=(Date>=DateTime('+bulkSetting.KTXero__Start_Date__c.year()+','+bulkSetting.KTXero__Start_Date__c.month()+','+bulkSetting.KTXero__Start_Date__c.day()+'))';
                            request += 'AND(Date<=DateTime('+bulkSetting.KTXero__End_Date__c.year()+','+bulkSetting.KTXero__End_Date__c.month()+','+bulkSetting.KTXero__End_Date__c.day()+'))';
                            dateFlag = true;
                        }
        
                        if(String.isNotBlank(bulkSetting.KTXero__Invoice_Statuses__c) && String.isNotEmpty(bulkSetting.KTXero__Invoice_Statuses__c)){
                            List<String> lstString = bulkSetting.KTXero__Invoice_Statuses__c.split(',');
                            if(dateFlag){
                                request += 'AND(';
                            }else{
                                request += 'where=(';
                            }
        
                            for(String str : lstString){
                                if(bulkSetting.KTXero__Invoice_Status_Operator__c == 'equals'){
                                    request += '(Status=="'+str+'")OR';
                                }else if(bulkSetting.KTXero__Invoice_Status_Operator__c == 'notEquals'){
                                    request += '(Status!="'+str+'")AND';
                                }
                            }
                            if(bulkSetting.KTXero__Invoice_Status_Operator__c == 'equals'){
                                request = request.removeEnd('OR');
                            }else if(bulkSetting.KTXero__Invoice_Status_Operator__c == 'notEquals'){
                                request = request.removeEnd('AND');
                            }
                            request+= ')';
                        }
                    }
                    request+='&page='+counter;
                    // End point generation stops here
    
                    // Callout to fetch the invoices
                    XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout(request, headerMap, 'GET', '');
                    HttpResponse response = callObj.response;
                    logList.add(callObj.exc);
                    if(response.getStatusCode() == 200){
                        Object input = JSON.deserializeUntyped(response.getBody());
                        String suffixed = new ReservedWordSerializer(input).getAsString();
                        XeroWebHookService.InvoiceWrapper maindata = (XeroWebHookService.InvoiceWrapper) JSON.deserialize(suffixed,XeroWebHookService.InvoiceWrapper.class);
    
                        if(maindata.Invoices_x.size() > 0){
                            // create map for Xero Items
                            Set<Id> productIds = new Set<Id>();
                            Map<String,String> productItemMap = new Map<String,String>();
                            Set<String> xeroInvIdSet = new Set<String>();
                            Set<String> existingInvIdSet = new Set<String>();
                            if(bulkSetting.KTXero__Create_Product_in_Salesforce__c != 'No'){
                                Set<String> itemIdSet = new Set<String>();
                                Set<String> itemCodeSet = new Set<String>();
        
                                for(XeroWebHookService.Invoices_x inv : maindata.Invoices_x){
                                    for(XeroWebHookService.LineItems_x li : inv.LineItems_x){
                                        if(li.Item_x != null){
                                            itemCodeSet.add(li.Item_x.Code_x);
                                            itemIdSet.add(li.Item_x.ItemID_x);
                                        }
                                    }

                                    // add invoice id into set
                                    xeroInvIdSet.add(inv.invoiceID_x);
                                }

                                if(xeroInvIdSet.size() > 0){
                                    //Check if invoice with same xero invoice id exist
                                    List<KTXero__Invoice__c> existingInvList = new List<KTXero__Invoice__c>();
                                    existingInvList = [SELECT Id, KTXero__Invoice_Id__c FROM KTXero__Invoice__c WHERE KTXero__Invoice_Id__c IN: xeroInvIdSet];
                                    if(existingInvList.size() > 0){
                                        for(KTXero__Invoice__c inv : existingInvList){
                                            if(xeroInvIdSet.contains(inv.KTXero__Invoice_Id__c)){
                                                xeroInvIdSet.remove(inv.KTXero__Invoice_Id__c);
                                            }
                                        }
                                    }
                                }
        
                                if(itemCodeSet.size() > 0){
                                    String whereCondition = 'where=';
                                    for(String str : itemCodeSet){
                                        String updatedStr = str.replace('-','%2D');
                                        updatedStr = updatedStr.replace(' ','%20');
                                        whereCondition += 'Code%3D%22'+updatedStr+'%22%20OR%20';
                                    }
        
                                    Integer lastIndex = whereCondition.lastIndexOf('%20OR%20');
        
                                    // If 'OR' is found, remove it along with any trailing whitespace
                                    if (lastIndex != -1) {
                                        whereCondition = whereCondition.substring(0, lastIndex);
                                    }
                                    
                                    if(flag){
                                        headerMap.put('xero-tenant-id',String.isNotBlank(xeroConnect.KTXero__Tenant_Id__c) ? Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c) : '');
                                        headerMap.put('authorization',String.isNotBlank(xeroConnect.KTXero__Access_Token__c) ? 'Bearer '+Utils.processDecryption(xeroConnect.KTXero__Access_Token__c) : '');
                                        headerMap.put('Content-Type','application/json');
        
                                    }else{
                                        connection = Utils.refreshToken();
                                        headerMap.put('xero-tenant-id',String.isNotBlank(xeroConnect.KTXero__Tenant_Id__c) ? Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c) : '');
                                        headerMap.put('authorization',String.isNotBlank(connection.KTXero__Access_Token__c) ? 'Bearer '+Utils.processDecryption(connection.KTXero__Access_Token__c) : '');
                                        headerMap.put('Content-Type','application/json');
        
                                    }
                        
                                    String productFetchReq = 'https://api.xero.com/api.xro/2.0/Items?'+whereCondition;
                                    
                                    XeroHttpCallout.CalloutWrapper prodCallObj = XeroHttpCallout.xeroCallout(productFetchReq, headerMap, 'GET', '');
                                    HttpResponse proResponse = prodCallObj.response;
                                    logList.add(prodCallObj.exc);
                                    
                                    Map<String,XeroBulkSyncController.cls_Items> codeMap = new Map<String,XeroBulkSyncController.cls_Items>();
                                    Map<String,XeroBulkSyncController.cls_Items> itemMap = new Map<String,XeroBulkSyncController.cls_Items>();
                                    
                                    if(proResponse.getStatusCode() == 200){
                                        XeroBulkSyncController.ItemWrapper ItemWrap = (XeroBulkSyncController.ItemWrapper) JSON.deserialize(proResponse.getBody(), XeroBulkSyncController.ItemWrapper.class);
                                        List<XeroBulkSyncController.cls_Items> itemList = ItemWrap.Items;
                                        for(XeroBulkSyncController.cls_Items cI : itemList){
                                            codeMap.put(cI.Code,cI);
                                            itemMap.put(cI.ItemID,cI);
                                        }
        
                                        List<Product2> upsertproductList = new List<Product2>();
                                        List<Product2> productList = new List<Product2>();
                                        Map<String,Product2> productMap = new Map<String,Product2>();
                                        Map<String,Product2> tmpProdMap = new Map<String,Product2>();
        
                                        if(codeMap.size() > 0 || itemMap.size() > 0){
                                            productList = [SELECT Id, Name, ProductCode, KTXero__Xero_Item_Sales_Account_Code__c, 
                                                            KTXero__Xero_Item_Purchase_Tax_Rate__c, KTXero__Xero_ItemID__c, KTXero__Xero_Item_Sales_Tax_Rate__c, 
                                                            KTXero__Xero_Item_Purchase_Account_Code__c, KTXero__Xero_Item_Sales_Description__c, KTXero__Xero_Item_Purchase_Description__c 
                                                            FROM Product2 WHERE KTXero__Xero_ItemID__c IN: itemMap.keySet() OR ProductCode IN : codeMap.keySet() 
                                                            WITH SECURITY_ENFORCED];
        
                                            
                                            if(productList.size() > 0 && (bulkSetting.KTXero__Create_Product_in_Salesforce__c == 'linkOnly' || bulkSetting.KTXero__Create_Product_in_Salesforce__c == 'linkandCreate')){
                                                Set<Integer> indexInteger = new Set<Integer>();
                                                for(Product2 prod : productList){
                                                    
                                                    if(String.isBlank(prod.KTXero__Xero_ItemID__c)){
                                                        if(String.isNotBlank(prod.ProductCode) && prod.ProductCode == codeMap.get(prod.ProductCode).Code){
        
                                                            XeroBulkSyncController.cls_Items item = codeMap.get(prod.ProductCode);
                                                            prod.KTXero__Xero_ItemID__c = item.ItemID;
                                                            // Add Sales Details
                                                            prod.KTXero__Xero_Item_Sales_Account_Code__c = item.SalesDetails.AccountCode;
                                                            prod.KTXero__Xero_Item_Sales_Tax_Rate__c = item.SalesDetails.TaxType;
                                                            prod.KTXero__Xero_Item_Sales_Description__c = item.Description;
                                                            //Add Purchase Details
                                                            if(item.PurchaseDetails.AccountCode != null){
                                                                prod.KTXero__Xero_Item_Purchase_Account_Code__c = item.PurchaseDetails.AccountCode;
                                                            } else if (item.PurchaseDetails.COGSAccountCode != null){
                                                                prod.KTXero__Xero_Item_Purchase_Account_Code__c = item.PurchaseDetails.COGSAccountCode;
                                                            }
                                                            prod.KTXero__Xero_Item_Purchase_Tax_Rate__c = item.PurchaseDetails.TaxType;
                                                            prod.KTXero__Xero_Item_Purchase_Description__c = item.PurchaseDescription;
                                                            upsertproductList.add(prod);
                                                            codeMap.remove(prod.ProductCode);
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
                                                                if(item.PurchaseDetails.AccountCode != null){
                                                                    if(prod.KTXero__Xero_Item_Purchase_Account_Code__c != item.PurchaseDetails.AccountCode){
                                                                        prod.KTXero__Xero_Item_Purchase_Account_Code__c = item.PurchaseDetails.AccountCode;
                                                                        flag1 = true;
                                                                    }
                                                                } else if(item.PurchaseDetails.COGSAccountCode != null){
                                                                    if(prod.KTXero__Xero_Item_Purchase_Account_Code__c != item.PurchaseDetails.COGSAccountCode){
                                                                        prod.KTXero__Xero_Item_Purchase_Account_Code__c = item.PurchaseDetails.COGSAccountCode;
                                                                        flag1 = true;
                                                                    }
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
                                                    productItemMap.put(prod.KTXero__Xero_ItemID__c, prod.Id);
                                                }
                        
                                            }
                                            
                                            if(bulkSetting.KTXero__Create_Product_in_Salesforce__c == 'linkandCreate'){
                                                for(XeroBulkSyncController.cls_Items item : codeMap.values()){
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
                                                        if(item.PurchaseDetails.AccountCode != null){
                                                            pro.KTXero__Xero_Item_Purchase_Account_Code__c = item.PurchaseDetails.AccountCode;
                                                        } else if (item.PurchaseDetails.COGSAccountCode != null){
                                                            pro.KTXero__Xero_Item_Purchase_Account_Code__c = item.PurchaseDetails.COGSAccountCode;
                                                        }
                                                        // pro.KTXero__Xero_Item_Purchase_Account_Code__c = item.PurchaseDetails.COGSAccountCode;
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
                                                            if(item.PurchaseDetails.AccountCode != null){
                                                                pro.KTXero__Xero_Item_Purchase_Account_Code__c = item.PurchaseDetails.AccountCode;
                                                            } else if (item.PurchaseDetails.COGSAccountCode != null){
                                                                pro.KTXero__Xero_Item_Purchase_Account_Code__c = item.PurchaseDetails.COGSAccountCode;
                                                            }
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
                                                            if(i.PurchaseDetails.AccountCode != null){
                                                                pro.KTXero__Xero_Item_Purchase_Account_Code__c = i.PurchaseDetails.AccountCode;
                                                            } else if (i.PurchaseDetails.COGSAccountCode != null){
                                                                pro.KTXero__Xero_Item_Purchase_Account_Code__c = i.PurchaseDetails.COGSAccountCode;
                                                            }
                                                            pro.KTXero__Xero_Item_Purchase_Account_Code__c = i.PurchaseDetails.COGSAccountCode;
                                                            pro.KTXero__Xero_Item_Purchase_Tax_Rate__c = i.PurchaseDetails.TaxType;
                                                            pro.KTXero__Xero_Item_Purchase_Description__c = i.PurchaseDescription;
                                                            tmpProdMap.put(pro.KTXero__Xero_ItemID__c, pro);
                                                            upsertproductList.add(pro);
                                                        }
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
                                }
        
                            }    
        
                            // Payment logic Starts Here
                            Map<String, PaymentWrapper> payWrap = new Map<String, PaymentWrapper>(); // Map of Xero Invoice ref Id and new payment wrapper
                            List<KTXero__Log__c> paylogList = new List<KTXero__Log__c>();
                            Set<String> currencySet = new Set<String>();
                            if(Utils.getIsMultiCurrencyOrg()){
                                List<SObject> currencyList = new List<SObject>();
                                String query = 'SELECT Id, IsoCode, ConversionRate, DecimalPlaces, IsActive, IsCorporate, CreatedDate FROM CurrencyType WHERE IsActive = true WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC';
                                currencyList = Database.query(query);
                                for(SObject curr: currencyList){
                                    currencySet.add((String)curr.get('IsoCode'));
                                }
                            }else{
                                currencySet.add(UserInfo.getDefaultCurrency());
                            }
                            for(XeroWebHookService.Invoices_x inv : maindata.Invoices_x){
                                if(inv.Payments_x!= null){
                                    Integer counter = 1;
                                    for(XeroWebHookService.Payments_x pay : inv.Payments_x){
                                        XeroWebHookService.PaymentDetailWrapper paymentDetailWrap = new XeroWebHookService.PaymentDetailWrapper();
                                        paymentDetailWrap = XeroWebHookService.getPaymentDetails(pay.PaymentID_x, headerMap);
                                        payWrap.put(pay.PaymentID_x, paymentDetailWrap.paymentWrap);
                                        paylogList.add(paymentDetailWrap.log);
                                    }
                                }
                            }
        
                            // Payment logic ends here


                            // create map for link xc
                            if(bulkSetting.KTXero__Link_Xero_Contact__c){
        
                                Set<String> cmpnyNameSet = new Set<String>();
                                Set<String> accNumberSet = new Set<String>();
                                Set<String> emailSet = new Set<String>();
                                for(XeroWebHookService.Invoices_x inv : maindata.Invoices_x){
                                    if(inv.Contact_x != null){
                                        xeroConIdSet.add(inv.Contact_x.ContactID_x); // add Xero Contact id
                                    }
                                }
        
                                if(xeroConIdSet.size() > 0){
                                    List<KTXero__Xero_Contact__c> xcList = new List<KTXero__Xero_Contact__c>();
                                    xcList = [SELECT Id, KTXero__Reference_Id__c FROM KTXero__Xero_Contact__c WHERE KTXero__Reference_Id__c IN: xeroConIdSet WITH SECURITY_ENFORCED];
                                    
                                    if(!xcList.isEmpty()){
                                        for(KTXero__Xero_Contact__c xc : xcList){
                                            xcIdMap.put(xc.KTXero__Reference_Id__c, xc);
                                        }
                                    }
                                }
        
                                if(bulkSetting.KTXero__Create_Xero_Contact__c){
                                    
                                    List<String> conIdList1 = new List<String>();
                                    List<String> conIdList2 = new List<String>();
                                    for(Integer i=0;i<xeroConIdSet.size();i++){
                                        if(i<=50){
                                            conIdList1.add(xeroConIdSet[i]);
                                        }else{
                                            conIdList2.add(xeroConIdSet[i]);
                                        }
                                    }
                                    
                                    ConWrapper conwrap = getContacts(conIdList1,headerMap,xcIdMap); 
                                    if(conwrap != null){
                                        newConList.addAll(conwrap.conList);
                                        logList.addAll(conwrap.logList);
                                    }
                                    
                                    if(conIdList2.size() > 0){
                                        ConWrapper conwrap2 = getContacts(conIdList2,headerMap,xcIdMap);
                                        if(conwrap2 != null){
                                            newConList.addAll(conwrap2.conList);
                                            logList.addAll(conwrap2.logList);
                                        }
                                    }

                                    Set<Id> newConIdSet = new Set<Id>();
                                    Boolean newXCflag = false;
                                    if(newConList.size() > 0 && Schema.sObjectType.KTXero__Xero_Contact__c.isCreateable()){
                                        Database.SaveResult[] contactResult = Database.insert(newConList);
                                        for (Database.SaveResult result : contactResult) {
                                            if (result.isSuccess()) {
                                                newConIdSet.add(result.getId());
                                                xConIdSet.add(result.getId());
                                                newXCflag = true;
                                                continue;
                                            }else {
                                                newXCflag = false;
                                                break;
                                            }
                                        }
        
                                        for(KTXero__Xero_Contact__c xc : newConList){
                                            xcIdMap.put(xc.KTXero__Reference_Id__c,xc);
                                        }

                                        xConCounter += newConIdSet.size();
                                    }
                                }
            
        
                                if(bulkSetting.KTXero__Map_Salesforce_Account__c){
                                    if(newConList.size() > 0){
        
                                        List<KTXero__Xero_Contact__c> updateXCList = new List<KTXero__Xero_Contact__c>();
                                        Set<Id> updatedXc = new Set<Id>();
        
                                        // Using Company Name mapping XC
                                        if(String.isNotBlank(bulkSetting.KTXero__Company_Name_mapping_field__c) && String.isNotEmpty(bulkSetting.KTXero__Company_Name_mapping_field__c)){
                                            Map<String,String> xcCompanyNameMap = new Map<String,String>();
                                            for(KTXero__Xero_Contact__c xc : newConList){
                                                xcCompanyNameMap.put(xc.KTXero__Company_Name__c,xc.Id);
                                            }

                                            if(xcCompanyNameMap.size() > 0){
                                                Set<String> companyNameSet = xcCompanyNameMap.keySet();
                                                String query = 'SELECT Id, '+bulkSetting.KTXero__Company_Name_mapping_field__c+' FROM Account WHERE '+bulkSetting.KTXero__Company_Name_mapping_field__c+' IN: companyNameSet WITH SECURITY_ENFORCED';
                                                List<Account> accList = Database.query(query);

                                                if(accList.size() > 0){
                                                    for(Account acc : accList){
                                                        String key = null;
                                                        key = (String) acc.get(bulkSetting.KTXero__Company_Name_mapping_field__c);
                                                        if(String.isNotBlank(key) && String.isNotEmpty(key)){
                                                            if(xcCompanyNameMap.containsKey(key)){
                                                                KTXero__Xero_Contact__c xc = new KTXero__Xero_Contact__c();
                                                                xc.Id = xcCompanyNameMap.get(key);
                                                                xc.KTXero__Salesforce_Account__c = acc.Id;
                                                                if(!updatedXc.contains(xcCompanyNameMap.get(key))){
                                                                    updateXCList.add(xc);
                                                                    updatedXc.add(xcCompanyNameMap.get(key));
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
        
                                        // Using Account Number mapping XC
                                        if(String.isNotBlank(bulkSetting.KTXero__Account_Number_mapping_field__c) && String.isNotEmpty(bulkSetting.KTXero__Account_Number_mapping_field__c)){
                                            Map<String,String> xcAccNumMap = new Map<String,String>();
                                            for(KTXero__Xero_Contact__c xc : newConList){
                                                if(!updatedXc.contains(xc.Id) && String.isNotBlank(xc.KTXero__Account_Number__c) && String.isNotEmpty(xc.KTXero__Account_Number__c)){
                                                    xcAccNumMap.put(xc.KTXero__Account_Number__c,xc.Id);
                                                }
                                            }
        
                                            if(xcAccNumMap.size() > 0){
                                                Set<String> accNumSet = xcAccNumMap.keySet();
                                                String query = 'SELECT Id, '+bulkSetting.KTXero__Account_Number_mapping_field__c+' FROM Account WHERE '+bulkSetting.KTXero__Account_Number_mapping_field__c+' IN: accNumSet WITH SECURITY_ENFORCED';
                                                List<Account> accList = Database.query(query);
        
                                                if(accList.size() > 0){
                                                    for(Account acc : accList){
                                                        String key = null;
                                                        key = (String) acc.get(bulkSetting.KTXero__Account_Number_mapping_field__c);
                                                        if(String.isNotBlank(key) && String.isNotEmpty(key)){
                                                            if(xcAccNumMap.containsKey(key)){
                                                                KTXero__Xero_Contact__c xc = new KTXero__Xero_Contact__c();
                                                                xc.Id = xcAccNumMap.get(key);
                                                                xc.KTXero__Salesforce_Account__c = acc.Id;
                                                                if(!updatedXc.contains(xcAccNumMap.get(key))){
                                                                    updateXCList.add(xc);
                                                                    updatedXc.add(xcAccNumMap.get(key));
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
        
                                        // Using Email mapping XC
                                        if(String.isNotBlank(bulkSetting.KTXero__Xero_Email_mapping_field__c) && String.isNotEmpty(bulkSetting.KTXero__Xero_Email_mapping_field__c)){
                                            Map<String,String> xcEmailMap = new Map<String,String>();
                                            for(KTXero__Xero_Contact__c xc : newConList){
                                                if((!updatedXc.contains(xc.Id)) && (String.isNotBlank(xc.KTXero__Email_Address__c) && String.isNotEmpty(xc.KTXero__Email_Address__c))){
                                                    xcEmailMap.put(xc.KTXero__Email_Address__c,xc.Id);
                                                }
                                            }
        
                                            if(xcEmailMap.size() > 0){
                                                Set<String> xcEmailSet = xcEmailMap.keySet();
                                                String query = 'SELECT Id, ';
                                                if(bulkSetting.KTXero__Xero_Email_mapping_Object__c == 'Contact'){
                                                    query += 'AccountId, ';
                                                }
                                                query += ''+bulkSetting.KTXero__Xero_Email_mapping_field__c+' FROM '+bulkSetting.KTXero__Xero_Email_mapping_Object__c+' WHERE '+bulkSetting.KTXero__Xero_Email_mapping_field__c+' IN: xcEmailSet WITH SECURITY_ENFORCED';
                                                List<SObject> accList = Database.query(query);

                                                if(accList.size() > 0){
                                                    for(SObject acc : accList){
                                                        String key = null;
                                                        key = (String) acc.get(bulkSetting.KTXero__Xero_Email_mapping_field__c);
                                                        if(String.isNotBlank(key) && String.isNotEmpty(key)){
                                                            if(xcEmailMap.containsKey(key)){
                                                                KTXero__Xero_Contact__c xc = new KTXero__Xero_Contact__c();
                                                                xc.Id = xcEmailMap.get(key);
                                                                if(bulkSetting.KTXero__Xero_Email_mapping_Object__c == 'Contact'){
                                                                    xc.KTXero__Salesforce_Account__c = (String) acc.get('AccountId');
                                                                }else{
                                                                    xc.KTXero__Salesforce_Account__c = (String) acc.Id;
                                                                }
                                                                if(!updatedXc.contains(xcEmailMap.get(key))){
                                                                    updateXCList.add(xc);
                                                                    updatedXc.add(xcEmailMap.get(key));
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        if(bulkSetting.KTXero__Create_Account__c){
                                            List<Account> accList = new List<Account>();
                                            Map<String,KTXero__Xero_Contact__c> accMap = new Map<String, KTXero__Xero_Contact__c>();
                                            for(KTXero__Xero_Contact__c xc : newConList){
                                                if(!updatedXc.contains(xc.Id)){
                                                    Account acc = new Account();
                                                    acc.Name = xc.KTXero__Company_Name__c;
                                                    accList.add(acc);
                                                    accMap.put(xc.KTXero__Company_Name__c,xc);
                                                }
                                            }

                                            if(accList.size() > 0){
                                                Database.SaveResult[] srList = Database.insert(accList, false);
                                                Boolean accflag = true;
                                                for(Database.SaveResult sr: srList){
                                                    if(!sr.isSuccess()){
                                                        accflag = false;
                                                    }else{
                                                        accIdSet.add(sr.getId());
                                                    }
                                                }

                                                if(accflag){
                                                    for(Account acc : accList){
                                                        KTXero__Xero_Contact__c xc = new KTXero__Xero_Contact__c();
                                                        xc.Id = accMap.get(acc.Name).Id;
                                                        xc.Salesforce_Account__c = acc.Id;
                                                        updateXCList.add(xc);
                                                    }
                                                    accountCounter += accList.size();
                                                }
                                            }
                                        }
        
                                        if(updateXCList.size() > 0){
                                            FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                                            flsWrap = FLSChecker.dmlUpdate(updateXCList);
                                            if(!flsWrap.isSuccess){
                                                throw new CustomException(flsWrap.message);
                                            }
                                        }

                                    }
                                }
                                
                            }


                            if(paylogList.size() > 0){
                                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                                flsWrap = FLSChecker.dmlInsert(paylogList);
                                if(!flsWrap.isSuccess){
                                    throw new CustomException(flsWrap.message);
                                }
                            }
        
                            // Creating Products based on setup in Xero Bulk Sync Setting 
                            if(finalMap.size() > 0){
                                Database.UpsertResult[] productResult = Database.upsert(finalMap.values(),false);
                                for (Database.UpsertResult result : productResult) {
                                    if (result.isSuccess()) {
                                        productIds.add(result.getId());
                                        proIdSet.add(result.getId());
                                        continue;
                                    }else {
                                        List<Database.Error> errors =  result.getErrors();
                                    }
                                }
        
                                List<Product2> prodList = [SELECT Id, KTXero__Xero_ItemID__c FROM Product2 WHERE Id IN: productIds WITH SECURITY_ENFORCED];
                                for(Product2 pro : prodList){
                                    if(!productItemMap.containsKey(pro.KTXero__Xero_ItemID__c)){
                                        productItemMap.put(pro.KTXero__Xero_ItemID__c,pro.Id);
                                    }
                                }

                                productCounter += prodList.size();
                            }
                            // End Products based on setup in Xero Bulk Sync Setting 
        
                            // Invoice Creation
                            List<KTXero__Invoice__c> newInvList = new List<KTXero__Invoice__c>();
                            Set<Id> invIdSet = new Set<Id>();
                            Map<String,List<KTXero__Payment__c>> paymentMap = new Map<String,List<KTXero__Payment__c>>();
                            Map<String,List<KTXero__Invoice_Line_Item__c>> lineItemsMap = new Map<String,List<KTXero__Invoice_Line_Item__c>>();
        
                            for(XeroWebHookService.Invoices_x ix : maindata.Invoices_x){
                                if(xeroInvIdSet.contains(ix.invoiceID_x)){
                                    KTXero__Invoice__c kInv = new KTXero__Invoice__c();
                                    kInv.Name = ix.InvoiceNumber_x;
                                    kInv.Branding_Theme_Id__c = ix.BrandingThemeID_x;
                                    kInv.Invoice_Id__c = ix.InvoiceID_x;
                                    kInv.Reference__c =  ix.Reference_x;
                                    kInv.Type__c = ix.Type_x;
                                    kInv.Amount_Due__c = ix.AmountDue_x;
                                    kInv.Amount_Paid__c = ix.AmountPaid_x;
                                    kInv.Sent_to_Contact__c = ix.SentToContact_x != null ? ix.SentToContact_x : false;
                                    kInv.Currency_Rate__c = ix.CurrencyRate_x;
                                    kInv.Currency_Code__c = ix.CurrencyCode_x;
                                    if(currencySet.contains(ix.CurrencyCode_x)){
                                        kInv.put('currencyIsoCode',ix.CurrencyCode_x);
                                    }
                                    kInv.Status__c = ix.Status_x;
                                    kInv.Invoice_Date__c = ix.DateString_x != null ? date.valueOf(ix.DateString_x) : null;
                                    kInv.Due_Date__c = ix.DueDateString_x != null ? date.valueOf(ix.DueDateString_x) : null;
                                    kInv.Total__c = ix.Total_x;
                                    kInv.Sub_Total__c = ix.SubTotal_x;
                                    kInv.Total_Tax__c = ix.TotalTax_x;
                                    kInv.Amounts_Are__c = ix.LineAmountTypes_x;
                                    if(xcIdMap.containsKey(ix.Contact_x.ContactID_x)){
                                        kInv.KTXero__Xero_Contact__c = xcIdMap.get(ix.Contact_x.ContactID_x).Id;
                                    }
                                    newInvList.add(kInv);
            
                                    if(ix.LineItems_x.size()>0){
                                        List<Invoice_Line_Item__c> liList = new List<Invoice_Line_Item__c>();
                                        List<XeroWebHookService.LineItems_x> lineItemsList = ix.LineItems_x;
            
                                        for(Integer i=0;i<lineItemsList.size();i++){
                                            Invoice_Line_Item__c newL = new Invoice_Line_Item__c();
                                            newL.Name = 'LineItem - '+(i+1) +' | '+ix.InvoiceNumber_x;
                                            newL.Account_Code__c = lineItemsList[i].AccountCode_x;
                                            newL.Description__c = lineItemsList[i].Description_x;
                                            newL.Discount_Rate__c = lineItemsList[i].DiscountRate_x;
                                            newL.Line_Amount__c = lineItemsList[i].LineAmount_x;
                                            newL.Line_Item_Id__c = lineItemsList[i].LineItemID_x;
                                            newL.Quantity__c = lineItemsList[i].Quantity_x;
                                            newL.Tax_Amount__c = lineItemsList[i].TaxAmount_x;
                                            newL.Tax_Type__c = lineItemsList[i].TaxType_x;
                                            newL.Unit_Price__c = lineItemsList[i].UnitAmount_x;
                                            newL.Discount_Amount__c = lineItemsList[i].DiscountAmount_x;
                                            if(lineItemsList[i].Item_x != null){
                                                if(productItemMap.containsKey(lineItemsList[i].Item_x.ItemID_x)){
                                                    newL.KTXero__Product__c = productItemMap.get(lineItemsList[i].Item_x.ItemID_x);
                                                }
                                            }
                                            liList.add(newL);
                                        }
                                        lineItemsMap.put(ix.InvoiceID_x,liList);
                                    }
            
                                    if(ix.Payments_x.size() > 0){
                                        List<XeroWebHookService.Payments_x> xeroPayList = ix.Payments_x;
                                        Integer counter = 0;
                                        List<KTXero__Payment__c> newPayList = new List<KTXero__Payment__c>();
                                        
                                        for(Integer i=0;i<xeroPayList.size();i++){
                                            PaymentWrapper pw = payWrap.get(xeroPayList[i].PaymentID_x);
                                            KTXero__Payment__c newPay = new KTXero__Payment__c();
                                            if(pw != null){
                                                counter++;
                                                newPay = XeroWebHookService.createPayment(pw,counter, currencySet);
                                                newPayList.add(newPay);
                                            }
                                        }
                                        
                                        paymentMap.put(ix.InvoiceID_x,newPayList);
                                    }
                                }
                            }
        
                            //Invoice Insert starts============================================
                            if(newInvList.size() > 0 && Schema.sObjectType.KTXero__Invoice__c.isCreateable() ){
                            
                                Database.UpsertResult[] srLI = Database.upsert(newInvList, false);
                                for (Database.UpsertResult result : srLI) {
                                    if (result.isSuccess()) {
                                        invIdSet.add(result.getId());
                                        invoiceIdSet.add(result.getId());
                                        continue;
                                    }else {
                                        break;
                                    }
                                }

                                invCounter += invIdSet.size();
                            }
        
                            if(invIdSet.size() > 0){
                                List<KTXero__Invoice__c> finalInvList = new List<KTXero__Invoice__c>();
                                finalInvList = [SELECT Id, Name, KTXero__Invoice_Id__c FROM KTXero__Invoice__c WHERE Id IN : invIdSet WITH SECURITY_ENFORCED];
                                
                                List<KTXero__Invoice_Line_Item__c> lineItmList = new List<KTXero__Invoice_Line_Item__c>();
                                List<KTXero__Payment__c> payList = new List<KTXero__Payment__c>();
                                
                                for(KTXero__Invoice__c inv : finalInvList){
                                    if(lineItemsMap.containsKey(inv.KTXero__Invoice_Id__c)){
                                        for(KTXero__Invoice_Line_Item__c li : lineItemsMap.get(inv.KTXero__Invoice_Id__c)){
                                            if(li.KTXero__Invoice__c == null){
                                                li.KTXero__Invoice__c = inv.Id;
                                            }
                                            lineItmList.add(li);
                                        }
                                    }
                                    if(paymentMap.containsKey(inv.KTXero__Invoice_Id__c)){
                                        for(KTXero__Payment__c p : paymentMap.get(inv.KTXero__Invoice_Id__c)){
                                            if(p.KTXero__Invoice__c == null){
                                                p.KTXero__Invoice__c = inv.Id;
                                            }
                                            payList.add(p);
                                        }
                                    }
                                }
            
                                // Upsert Line Items
                                if(lineItmList.size()>0 && Schema.sObjectType.KTXero__Invoice_Line_Item__c.isCreateable() ){
                                    Database.UpsertResult[] lineItemResult = Database.upsert(lineItmList, false);
                                    for (Database.UpsertResult result : lineItemResult) {
                                        if (result.isSuccess()) {
                                            continue;
                                        }else {
                                            break;
                                        }
                                    }
                                }
                                
                                // Insert Payments
                                if(payList.size() > 0 && Schema.sObjectType.KTXero__Payment__c.isCreateable()){
                                    Database.SaveResult[] paymentResult = Database.insert(payList);
                                    for (Database.SaveResult result : paymentResult) {
                                        if (result.isSuccess()) {
                                            continue;
                                        }else {
                                            break;
                                        }
                                    }
                                }
                            }
                            counter++;
                        }else{
                            counter = 0;
                        }
                        
                    }else{
                        String msg = '';
                    }
                }
            }
        }catch(Exception e){
            counter = 0;
        }
    }

    public void finish(Database.BatchableContext bc){
        KTXero__Xero_Bulk_Sync_Setting__c bulkSetting = KTXero__Xero_Bulk_Sync_Setting__c.getOrgDefaults();
        if(counter > 0 && !Test.isRunningTest()){
            bulkSetting.KTXero__No_of_Invoices_Created__c = invCounter;
            bulkSetting.KTXero__No_of_XC_Created__c = xConCounter;
            bulkSetting.KTXero__No_of_Products_Created__c = productCounter;
            bulkSetting.KTXero__No_of_Accounts_Created__c = accountCounter;
            
            Database.SaveResult sr = Database.update(bulkSetting);

            Database.executeBatch(new XeroBulkSyncBatch(counter, invoiceIdSet, xConIdSet, proIdSet, accIdSet),1);

        } else {

            // Create and insert CSV
            String domainURL = URL.getOrgDomainUrl().toExternalForm();
            String invContentDocumentId = '';
            String invContentDocumentName = '';
            String xCContentDocumentId = '';
            String xCContentDocumentName = '';
            String productContentDocumentId = '';
            String productContentDocumentName = '';
            String accountContentDocumentId = '';
            String accountContentDocumentName = '';
            
            if(invoiceIdSet.size() > 0){
                String csvString = '';
                List<KTXero__Invoice__c> invList = [SELECT Id, Name FROM KTXero__Invoice__c WHERE Id IN: invoiceIdSet];
                Map<String,String> invMap = new Map<String,String>();
                for(KTXero__Invoice__c inv : invList){
                    invMap.put(inv.Id,inv.Name);
                }
                for(Id i : invoiceIdSet){
                    String url = domainURL + '/'+i;
                    csvString += '\"=HYPERLINK(\"\"' + url + '\"\",\"\"' + invMap.get(i) + '\"\")\"\n';
                }
                blob csvBlob = Blob.valueOf(csvString);

                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = 'Bulk Sync - Invoice file '+System.now();
                contentVersion.PathOnClient = contentVersion.Title+'.csv';
                contentVersion.VersionData = csvBlob;
                // Omitting ContentDocumentId so Salesforce creates a new document
                insert contentVersion;

                // Get the ID of the newly created ContentDocument
                String invCD = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
                invContentDocumentId = domainURL+'/'+invCD;
                invContentDocumentName = contentVersion.Title;
            }
            
            if(xConIdSet.size() > 0){
                String csvString = '';
                List<KTXero__Xero_Contact__c> conList = [SELECT Id, Name FROM KTXero__Xero_Contact__c WHERE Id IN: xConIdSet];
                Map<String,String> conMap = new Map<String,String>();
                for(KTXero__Xero_Contact__c con : conList){
                    conMap.put(con.Id,con.Name);
                }
                for(Id i : xConIdSet){
                    String url = domainURL + '/'+i;
                    csvString += '\"=HYPERLINK(\"\"' + url + '\"\",\"\"' + conMap.get(i) + '\"\")\"\n';
                }
                blob csvBlob = Blob.valueOf(csvString);

                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = 'Bulk Sync - Xero Contact file '+System.now();
                contentVersion.PathOnClient = contentVersion.Title+'.csv';
                contentVersion.VersionData = csvBlob;
                // Omitting ContentDocumentId so Salesforce creates a new document
                insert contentVersion;

                // Get the ID of the newly created ContentDocument
                String xCCD = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
                xCContentDocumentId = domainURL+'/'+xCCD;
                xCContentDocumentName = contentVersion.Title;
            }
            
            if(proIdSet.size() > 0){
                String csvString = '';
                List<Product2> proList = [SELECT Id, Name FROM Product2 WHERE Id IN: proIdSet];
                Map<String,String> proMap = new Map<String,String>();
                for(Product2 pro : proList){
                    proMap.put(pro.Id,pro.Name);
                }
                for(Id i : proIdSet){
                    String url = domainURL + '/'+i;
                    csvString += '\"=HYPERLINK(\"\"' + url + '\"\",\"\"' + proMap.get(i) + '\"\")\"\n';
                }
                blob csvBlob = Blob.valueOf(csvString);

                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = 'Bulk Sync - Salesforce product file '+System.now();
                contentVersion.PathOnClient = contentVersion.Title+'.csv';
                contentVersion.VersionData = csvBlob;
                // Omitting ContentDocumentId so Salesforce creates a new document
                insert contentVersion;

                // Get the ID of the newly created ContentDocument
                String proCD = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
                productContentDocumentId = domainURL+'/'+proCD;
                productContentDocumentName = contentVersion.Title;
            }

            if(accIdSet.size() > 0){
                String csvString = '';
                List<Account> accList = [SELECT Id, Name FROM Account WHERE Id IN: accIdSet];
                Map<String,String> accMap = new Map<String,String>();
                for(Account acc : accList){
                    String url = domainURL + '/'+acc.Id;
                    csvString += '\"=HYPERLINK(\"\"' + url + '\"\",\"\"' + acc.Name + '\"\")\"\n';
                }
                blob csvBlob = Blob.valueOf(csvString);

                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = 'Bulk Sync - Salesforce Accounts file '+System.now();
                contentVersion.PathOnClient = contentVersion.Title+'.csv';
                contentVersion.VersionData = csvBlob;
                // Omitting ContentDocumentId so Salesforce creates a new document
                insert contentVersion;

                // Get the ID of the newly created ContentDocument
                String accCD = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
                accountContentDocumentId = domainURL+'/'+accCD;
                accountContentDocumentName = contentVersion.Title;
            }

            // Create an email message object
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {UserInfo.getUserEmail()};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Result of Xero Bulk Sync');
            
            String emailBody = '<!DOCTYPE html>'+
            '<html xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office" lang="en">'+
            '<head>'+
            '	<title></title>'+
            '	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">'+
            '	<meta name="viewport" content="width=device-width, initial-scale=1.0"><!--[if mso]><xml><o:OfficeDocumentSettings><o:PixelsPerInch>96</o:PixelsPerInch><o:AllowPNG/></o:OfficeDocumentSettings></xml><![endif]--><!--[if !mso]><!--><!--<![endif]-->'+
            '	<style>'+
            '		* {'+
            '			box-sizing: border-box;'+
            '		}'+
            '		body {'+
            '			margin: 0;'+
            '			padding: 0;'+
            '		}'+
            '		a[x-apple-data-detectors] {'+
            '			color: inherit !important;'+
            '			text-decoration: inherit !important;'+
            '		}'+
            '		#MessageViewBody a {'+
            '			color: inherit;'+
            '			text-decoration: none;'+
            '		}'+
            '		p {'+
            '			line-height: inherit'+
            '		}'+
            '		.desktop_hide,'+
            '		.desktop_hide table {'+
            '			mso-hide: all;'+
            '			display: none;'+
            '			max-height: 0px;'+
            '			overflow: hidden;'+
            '		}'+
            '		.img-responsive{'+
            '			display: block;'+
            '			max-width: 100%;'+
            '			height: auto;'+
            '		}'+
            '		.image_block img+div {'+
            '			display: none;'+
            '		}'+
            '		@media (max-width:670px) {'+
            '			.desktop_hide table.icons-inner,'+
            '			.social_block.desktop_hide .social-table {'+
            '				display: inline-block !important;'+
            '			}'+
            '			.icons-inner {'+
            '				text-align: center;'+
            '			}'+
            '			.icons-inner td {'+
            '				margin: 0 auto;'+
            '			}'+
            '			.mobile_hide {'+
            '				display: none;'+
            '			}'+
            '			.row-content {'+
            '				width: 100% !important;'+
            '			}'+
            '			.stack .column {'+
            '				width: 100%;'+
            '				display: block;'+
            '			}'+
            '			.mobile_hide {'+
            '				min-height: 0;'+
            '				max-height: 0;'+
            '				max-width: 0;'+
            '				overflow: hidden;'+
            '				font-size: 0px;'+
            '			}'+
            '			.desktop_hide,'+
            '			.desktop_hide table {'+
            '				display: table !important;'+
            '				max-height: none !important;'+
            '			}'+
            '		}'+
            '	</style>'+
            '</head>'+
            '<body class="body" style="background-color: #F5F5F5; margin: 0; padding: 0; -webkit-text-size-adjust: none; text-size-adjust: none;">'+
            '	<table class="nl-container" width="100%" border="0" cellpadding="0" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; background-color: #F5F5F5;">'+
            '		<tbody>'+
            '			<tr>'+
            '				<td>'+
            '					<table class="row row-1" align="center" width="100%" border="0" cellpadding="0" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt;">'+
            '						<tbody>'+
            '							<tr>'+
            '								<td>'+
            '									<table class="row-content stack" align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; color: #000000; width: 650px; margin: 0 auto;" width="650">'+
            '										<tbody>'+
            '											<tr>'+
            '												<td class="column column-1" width="100%" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; font-weight: 400; text-align: left; padding-bottom: 5px; padding-left: 15px; padding-right: 15px; padding-top: 5px; vertical-align: top; border-top: 0px; border-right: 0px; border-bottom: 0px; border-left: 0px;">'+
            '													<table class="image_block block-1" width="100%" border="0" cellpadding="0" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt;">'+
            '														<tr>'+
            '															<td class="pad" style="padding-left:10px;padding-right:15px;width:100%;">'+
            '																<div class="alignment" align="center" style="line-height:10px">'+
            '																	<div style="max-width: 217px;"><img src="https://fbd47f72a9.imgdist.com/pub/bfra/dd68854c/7b9/rvf/927/Logo_final_vertical.png" style="display: block; height: auto; border: 0; width: 100%; border-radius: 4px;" width="217" alt="Xero Integration By Kandisa" title="Xero Integration By Kandisa" height="auto"></div>'+
            '																</div>'+
            '															</td>'+
            '														</tr>'+
            '													</table>'+
            '													<div class="spacer_block block-2" style="height:30px;line-height:30px;font-size:1px;">&#8202;</div>'+
            '													<table class="paragraph_block block-3" width="100%" border="0" cellpadding="0" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; word-break: break-word;">'+
            '														<tr>'+
            '															<td class="pad" style="padding-bottom:10px;padding-left:10px;padding-right:10px;">'+
            '																<div style="color:#112b46;font-family:Tahoma, Verdana, Segoe, sans-serif;font-size:42px;line-height:120%;text-align:left;mso-line-height-alt:50.4px;">'+
            '																	<p style="margin: 0; word-break: break-word;"><span><strong><span>Hello, '+UserInfo.getFirstName()+' '+UserInfo.getLastName()+ '</span></strong></span></p>'+
            '																</div>'+
            '															</td>'+
            '														</tr>'+
            '													</table>'+
            '													<table class="paragraph_block block-4" width="100%" border="0" cellpadding="0" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; word-break: break-word;">'+
            '														<tr>'+
            '															<td class="pad" style="padding-bottom:30px;padding-left:10px;padding-right:10px;">'+
            '																<div style="color:#555555;font-family:Tahoma, Verdana, Segoe, sans-serif;font-size:22px;line-height:120%;text-align:left;mso-line-height-alt:26.4px;">'+
            '																	<p style="margin: 0; word-break: break-word;">Here is the result of Xero Bulk Sync Operation. If you have any query or issue please contact us on xero.support@kandisatech.com</p>'+
            '																</div>'+
            '															</td>'+
            '														</tr>'+
            '													</table>'+
            '												</td>'+
            '											</tr>'+
            '										</tbody>'+
            '									</table>'+
            '								</td>'+
            '							</tr>'+
            '						</tbody>'+
            '					</table>'+
            '                   <table class="row row-2" align="center" width="100%" border="0" cellpadding="0" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt;">'+
            '                       <tbody>'+
            '                           <tr>'+
            '                               <td>'+
            '                                   <table class="row-content stack" align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; color: #000000; width: 650px; margin: 0 auto;" width="650">'+
            '                                       <tbody>'+
            '                                           <tr>'+
            '                                               <td class="column column-1" width="100%" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; font-weight: 400; text-align: left; padding-top: 5px; vertical-align: top; border-top: 0px; border-right: 0px; border-bottom: 0px; border-left: 0px;">'+
            '                                                   <table class="table_block block-1" width="100%" border="0" cellpadding="10" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt;">'+
            '                                                       <tr>'+
            '                                                           <td class="pad">'+
            '                                                               <table style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse; width: 100%; table-layout: fixed; direction: ltr; background-color: transparent; font-family: Tahoma, Verdana, Segoe, sans-serif; font-weight: 400; color: #000000; text-align: left; letter-spacing: 0px; word-break: break-all;" width="100%">'+
            '                                                                   <thead style="vertical-align: top; background-color: #8c3b43; color: #112b46; font-size: 18px; line-height: 120%; text-align: left;">'+
            '                                                                       <tr>'+
            '                                                                           <th width="33.333333333333336%" style="padding: 10px; word-break: break-word; font-weight: 400; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;">&#8203;</th>'+
            '                                                                           <th width="33.333333333333336%" style="padding: 10px; word-break: break-word; font-weight: 400; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;color:white">No. of records created</th>'+
            '                                                                           <th width="33.333333333333336%" style="padding: 10px; word-break: break-word; font-weight: 400; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;color:white">File URL</th>'+
            '                                                                       </tr>'+
            '                                                                   </thead>'+
            '                                                                   <tbody style="vertical-align: top; font-size: 14px; line-height: 120%;">'+
            '                                                                       <tr>'+
            '                                                                           <td width="33.333333333333336%" style="padding: 10px; word-break: break-word; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;">Invoices</td>'+
            '                                                                           <td width="33.333333333333336%" style="padding: 10px; word-break: break-word; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;">'+invCounter+'</td>'+
            '                                                                           <td width="33.333333333333336%" style="padding: 10px; word-break: break-word; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;"><a href="'+invContentDocumentId+'">'+invContentDocumentName+'</a></td>'+
            '                                                                       </tr>'+
            '                                                                       <tr>'+
            '                                                                           <td width="33.333333333333336%" style="padding: 10px; word-break: break-word; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;">Xero Contacts</td>'+
            '                                                                           <td width="33.333333333333336%" style="padding: 10px; word-break: break-word; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;">'+xConCounter+'</td>'+
            '                                                                           <td width="33.333333333333336%" style="padding: 10px; word-break: break-word; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;"><a href="'+xCContentDocumentId+'">'+xCContentDocumentName+'</a></td>'+
            '                                                                       </tr>'+
            '                                                                       <tr>'+
            '                                                                           <td width="33.333333333333336%" style="padding: 10px; word-break: break-word; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;">Salesforce Products</td>'+
            '                                                                           <td width="33.333333333333336%" style="padding: 10px; word-break: break-word; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;">'+productCounter+'</td>'+
            '                                                                           <td width="33.333333333333336%" style="padding: 10px; word-break: break-word; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;"><a href="'+productContentDocumentId+'">'+productContentDocumentName+'</a></td>'+
            '                                                                       </tr>'+
            '                                                                       <tr>'+
            '                                                                           <td width="33.333333333333336%" style="padding: 10px; word-break: break-word; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;">Salesforce Accounts</td>'+
            '                                                                           <td width="33.333333333333336%" style="padding: 10px; word-break: break-word; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;">'+accountCounter+'</td>'+
            '                                                                           <td width="33.333333333333336%" style="padding: 10px; word-break: break-word; border-top: 2px solid #000000; border-right: 2px solid #000000; border-bottom: 2px solid #000000; border-left: 2px solid #000000;"><a href="'+accountContentDocumentId+'">'+accountContentDocumentName+'</a></td>'+
            '                                                                       </tr>'+
            '                                                                   </tbody>'+
            '                                                               </table>'+
            '                                                           </td>'+
            '                                                       </tr>'+
            '                                                   </table>'+
            '                                                   <div class="spacer_block block-2" style="height:20px;line-height:20px;font-size:1px;">&#8202;</div>'+
            '                                               </td>'+
            '                                           </tr>'+
            '                                       </tbody>'+
            '                                   </table>'+
            '                               </td>'+
            '                           </tr>'+
            '                       </tbody>'+
            '                   </table>'+
            '					<table class="row row-3" align="center" width="100%" border="0" cellpadding="0" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt;">'+
            '						<tbody>'+
            '							<tr>'+
            '								<td>'+
            '									<table class="row-content" align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; background-color: #E4E9ED; color: #333; width: 650px; margin: 0 auto;" width="650">'+
            '										<tbody>'+
            '											<tr>'+
            '												<td class="column column-1" width="25%" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; font-weight: 400; text-align: left; vertical-align: middle; border-top: 0px; border-right: 0px; border-bottom: 0px; border-left: 0px;">'+
            '													<table class="empty_block block-1" width="100%" border="0" cellpadding="0" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt;">'+
            '														<tr>'+
            '															<td class="pad">'+
            '																<div></div>'+
            '															</td>'+
            '														</tr>'+
            '													</table>'+
            '												</td>'+
            '												<td class="column column-2" width="75%" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; font-weight: 400; text-align: left; vertical-align: middle; border-top: 0px; border-right: 0px; border-bottom: 0px; border-left: 0px;">'+
            '													<table class="empty_block block-1" width="100%" border="0" cellpadding="0" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt;">'+
            '														<tr>'+
            '															<td class="pad">'+
            '																<div></div>'+
            '															</td>'+
            '														</tr>'+
            '													</table>'+
            '												</td>'+
            '											</tr>'+
            '										</tbody>'+
            '									</table>'+
            '								</td>'+
            '							</tr>'+
            '						</tbody>'+
            '					</table>'+
            '					<table class="row row-4" align="center" width="100%" border="0" cellpadding="0" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt;">'+
            '						<tbody>'+
            '							<tr>'+
            '								<td>'+
            '									<table class="row-content stack" align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; color: #000000; width: 650px; margin: 0 auto;" width="650">'+
            '										<tbody>'+
            '											<tr>'+
            '												<td class="column column-1" width="100%" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; font-weight: 400; text-align: left; padding-bottom: 5px; padding-top: 5px; vertical-align: top; border-top: 0px; border-right: 0px; border-bottom: 0px; border-left: 0px;">'+
            '													<div class="spacer_block block-1" style="height:60px;line-height:60px;font-size:1px;">&#8202;</div>'+
            '												</td>'+
            '											</tr>'+
            '										</tbody>'+
            '									</table>'+
            '								</td>'+
            '							</tr>'+
            '						</tbody>'+
            '					</table>'+
            '				</td>'+
            '			</tr>'+
            '		</tbody>'+
            '	</table>'+
            '</body>'+
            '</html>';

            mail.setHtmlBody(emailBody);

            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {mail};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

            bulkSetting.KTXero__No_of_Invoices_Created__c = 0;
            bulkSetting.KTXero__No_of_XC_Created__c = 0;
            bulkSetting.KTXero__No_of_Products_Created__c = 0;
            bulkSetting.KTXero__No_of_Accounts_Created__c = 0;
            
            Database.SaveResult sr = Database.update(bulkSetting);
        }
    }

    public ConWrapper getContacts(List<String> conIdList, Map<String,String> headerMap, Map<String,KTXero__Xero_Contact__c> xcIdMap){
        ConWrapper conwrap = new ConWrapper();
        List<KTXero__Xero_Contact__c> conList = new List<KTXero__Xero_Contact__c>();
        List<KTXero__Log__c> logList = new List<KTXero__Log__c>();

        String xcIds = String.join(conIdList, ',');
        String xcEndpoint = 'https://api.xero.com/api.xro/2.0/contacts?IDs='+xcIds;
        XeroHttpCallout.CalloutWrapper xccallObj = XeroHttpCallout.xeroCallout(xcEndpoint,headerMap,'GET','');
        HttpResponse xcresponse = xccallObj.response;
        logList.add(xccallObj.exc);

        if(xcresponse.getStatusCode() == 200){
            InvoiceCreationWrapper.Datawrap ct1 = (InvoiceCreationWrapper.Datawrap)JSON.deserialize(xcresponse.getBody(),InvoiceCreationWrapper.Datawrap.class);

            for(InvoiceCreationWrapper.Contacts con : ct1.Contacts){
                if(!xcIdMap.containsKey(con.contactID)){
                    KTXero__Xero_Contact__c xCon = new KTXero__Xero_Contact__c();
                    xCon.KTXero__Company_Name__c = con.name;
                    xCon.KTXero__Account_Number__c = con.accountNumber;
                    xCon.KTXero__First_Name__c = con.firstName;
                    xCon.KTXero__Last_Name__c = con.lastName;
                    xCon.KTXero__Email_Address__c = con.emailAddress;
                    xCon.KTXero__Reference_Id__c = con.contactID;
                    xCon.KTXero__Status__c = con.contactStatus;
                    for(Integer i=0;i<con.contactPersons.size();i++){
                        if(i == 0){
                            xCon.KTXero__Contact_1_First_Name__c = con.contactPersons[i].FirstName; 
                            xCon.KTXero__Contact_1_Last_Name__c = con.contactPersons[i].LastName; 
                            xCon.KTXero__Contact_1_Email__c = con.contactPersons[i].EmailAddress; 
                            xCon.KTXero__Contact_1_Include_in_Emails__c = con.contactPersons[i].IncludeInEmails; 
                        }else if(i == 1){
                            xCon.KTXero__Contact_2_First_Name__c = con.contactPersons[i].FirstName; 
                            xCon.KTXero__Contact_2_Last_Name__c = con.contactPersons[i].LastName; 
                            xCon.KTXero__Contact_2_Email__c = con.contactPersons[i].EmailAddress; 
                            xCon.KTXero__Contact_2_Include_in_Emails__c = con.contactPersons[i].IncludeInEmails; 
                        }else if(i == 2){
                            xCon.KTXero__Contact_3_First_Name__c = con.contactPersons[i].FirstName; 
                            xCon.KTXero__Contact_3_Last_Name__c = con.contactPersons[i].LastName; 
                            xCon.KTXero__Contact_3_Email__c = con.contactPersons[i].EmailAddress; 
                            xCon.KTXero__Contact_3_Include_in_Emails__c = con.contactPersons[i].IncludeInEmails; 
                        }else if(i == 3){
                            xCon.KTXero__Contact_4_First_Name__c = con.contactPersons[i].FirstName; 
                            xCon.KTXero__Contact_4_Last_Name__c = con.contactPersons[i].LastName; 
                            xCon.KTXero__Contact_4_Email__c = con.contactPersons[i].EmailAddress; 
                            xCon.KTXero__Contact_4_Include_in_Emails__c = con.contactPersons[i].IncludeInEmails;
                        }else if(i == 4){
                            xCon.KTXero__Contact_5_First_Name__c = con.contactPersons[i].FirstName; 
                            xCon.KTXero__Contact_5_Last_Name__c = con.contactPersons[i].LastName; 
                            xCon.KTXero__Contact_5_Email__c = con.contactPersons[i].EmailAddress; 
                            xCon.KTXero__Contact_5_Include_in_Emails__c = con.contactPersons[i].IncludeInEmails;
                        }
                    }
                    if(con.addresses.size()>0){
                        List<InvoiceCreationWrapper.Addresses> addressList = con.addresses;
                        for(InvoiceCreationWrapper.Addresses add : addressList){
                            if(add.AddressType == 'POBOX'){
                                xCon.KTXero__Street_Address__c = add.AddressLine1;
                                xCon.KTXero__Town_City__c = add.City;
                                xCon.KTXero__State_Region__c = add.Region;   
                                xCon.KTXero__Postal_Zip_Code__c = add.PostalCode;   
                                xCon.KTXero__Country__c = add.Country;   
                            }else if(add.AddressType == 'DELIVERY'){
                                xCon.KTXero__Shipping_Street_Address__c = add.AddressLine1;
                                xCon.KTXero__Shipping_Town_City__c = add.City;
                                xCon.KTXero__Shipping_State_Region__c = add.Region;   
                                xCon.KTXero__Shipping_Postal_Zip_Code__c = add.PostalCode;   
                                xCon.KTXero__Shipping_Country__c = add.Country;
                            }
                        }
                    }
                    conList.add(xCon);
                }
            }
        }
        conwrap.conList = conList;
        conwrap.logList = logList;

        return conwrap;
    }

    public class ConWrapper{
        public List<KTXero__Xero_Contact__c> conList;
        public List<KTXero__Log__c> logList;
    }
}