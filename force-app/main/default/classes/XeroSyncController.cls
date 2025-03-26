/**
     * @description Class to keep Invoice, Payment, COntacts, products in sync with Salesforce
     * @Author : Kandisa Technologies
     * @CreatedDate : 29 March 2023
*/

public with Sharing class XeroSyncController {
    public static KTXero__Xero_Connection__c xeroConnect = [SELECT Id, KTXero__Access_Token__c, KTXero__Refresh_Token__c, KTXero__Tenant_Id__c, KTXero__Last_Token_Refresh_Time__c FROM KTXero__Xero_Connection__c WITH SECURITY_ENFORCED LIMIT 1];
    /**
     * @description Class to fetch the invoice from salesforce
     * @param recordId
     * @return InvoiceWrapper
    */
    @AuraEnabled
    public static InvoiceWrapper getInvoice(String recordId){
        InvoiceWrapper invWrap = new InvoiceWrapper();

        Invoice__c inv = new Invoice__c();
        try {
            inv = [SELECT Id, Name, Invoice_Id__c, Status__c FROM Invoice__c WHERE Id =: recordId WITH SECURITY_ENFORCED];
            invWrap.invId = inv.Invoice_Id__c;
            invWrap.invName = inv.Name;
            invWrap.invStatus = String.isNotBlank(inv.Status__c) ? inv.Status__c : '';
            
        } catch (Exception e) {
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return invWrap;
    }

    /**
     * @description Class to fetch the products from salesforce
     * @param codeMap
     * @param itemMap
     * @return Map<String,Product2>
    */
    public static Map<String,Product2> getProducts(Map<String,Item> codeMap, Map<String,Item> itemMap){
		List<Product2> productList = new List<Product2>();
		Map<String,Product2> productMap = new Map<String,Product2>();
        List<KTXero__Log__c> logList = new List<KTXero__Log__c>();

		try{

			Map<String,Product2> tmpProdMap = new Map<String,Product2>();
            KTXero__Invoice_Configuration_Options__c invConfig = KTXero__Invoice_Configuration_Options__c.getOrgDefaults();
			if(codeMap.size() > 0 || itemMap.size() > 0){
				productList = [SELECT Id, Name, KTXero__Xero_ItemID__c, ProductCode, IsArchived, CreatedDate FROM Product2 WHERE KTXero__Xero_ItemID__c IN: itemMap.keySet() OR ProductCode IN : codeMap.keySet() WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC ];
				if(productList.size() > 0){
					for(Product2 prod : productList){
						if(String.isBlank(prod.KTXero__Xero_ItemID__c)){
							if(String.isNotBlank(prod.ProductCode) && prod.ProductCode == codeMap.get(prod.ProductCode).Code_x){
								prod.KTXero__Xero_ItemID__c = codeMap.get(prod.ProductCode).ItemID_x;
								codeMap.remove(prod.ProductCode);
							}
						}
						productMap.put(prod.KTXero__Xero_ItemID__c, prod);
					}
				}else{
					if(invConfig.KTXero__Create_products_in_Salesforce__c){
						for(Item i : codeMap.values()){
							Product2 pro = new Product2();
							pro.Name = i.Name_x;
							pro.ProductCode = i.Code_x;
							pro.KTXero__Xero_ItemID__c = i.ItemID_x;
							pro.isActive = true;
							productList.add(pro);
                            tmpProdMap.put(pro.KTXero__Xero_ItemID__c, pro);
						}
					}
				}
           
				if(codeMap.size() > 0 && invConfig.KTXero__Create_products_in_Salesforce__c){
					for(String s : codeMap.keySet()){
						Item i = codeMap.get(s);
                        if(!productMap.containsKey(i.ItemID_x)  && !tmpProdMap.containsKey(i.ItemID_x)){
                            Product2 pro = new Product2();
                            pro.Name = i.Name_x;
                            pro.ProductCode = i.Code_x;
                            pro.KTXero__Xero_ItemID__c = i.ItemID_x;
                            pro.isActive = true;
                            tmpProdMap.put(pro.KTXero__Xero_ItemID__c, pro);
                            productList.add(pro);
                        }
					}
				}

                if(itemMap.size() > 0 && invConfig.KTXero__Create_products_in_Salesforce__c){
					for(String s : itemMap.keySet()){
						Item i = itemMap.get(s);
                        if(!productMap.containsKey(i.ItemID_x)  && !tmpProdMap.containsKey(i.ItemID_x)){
                            Product2 pro = new Product2();
                            pro.Name = i.Name_x;
                            pro.ProductCode = i.Code_x;
                            pro.KTXero__Xero_ItemID__c = i.ItemID_x;
                            pro.isActive = true;
                            tmpProdMap.put(pro.KTXero__Xero_ItemID__c, pro);
                            productList.add(pro);
                        }
					}
				}
	
				Integer prodSucCnt = 0;
				Integer prodFailCnt = 0;
				Set<Id> newProIdSet = new Set<Id>();
				if(productList.size() > 0 
                    && Product2.getSObjectType().getDescribe().isCreateable() 
                    && Schema.sObjectType.Product2.fields.Name.isCreateable() == true
                    && Schema.sObjectType.Product2.fields.ProductCode.isCreateable() == true
                    && Schema.sObjectType.Product2.fields.KTXero__Xero_ItemID__c.isCreateable() == true
                    && Schema.sObjectType.Product2.fields.isActive.isCreateable() == true
                  
                    && Product2.getSObjectType().getDescribe().isUpdateable()
                    && Schema.sObjectType.Product2.fields.Name.isUpdateable() == true
                    && Schema.sObjectType.Product2.fields.ProductCode.isUpdateable() == true
                    && Schema.sObjectType.Product2.fields.KTXero__Xero_ItemID__c.isUpdateable() == true
                    && Schema.sObjectType.Product2.fields.isActive.isUpdateable() == true
                    ){
					Database.UpsertResult[] productResult = Database.upsert(productList);
					for (Database.UpsertResult result : productResult) {
						if (result.isSuccess()) {
							newProIdSet.add(result.getId());
							prodSucCnt++;
							continue;
						}else {
							prodFailCnt++;
							break;
						}
					}
                  	productList = [SELECT Id, Name, KTXero__Xero_ItemID__c, ProductCode, IsArchived, CreatedDate FROM Product2 WHERE Id IN: newProIdSet WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC];
	
					for(Product2 prod : productList){
						productMap.put(prod.KTXero__Xero_ItemID__c, prod);
					}	
				}
			}
		}catch(Exception e){
			// HandleCustomException.logException(e);
            KTXero__Log__c kl = HandleCustomException.logException(e);
			logList.add(kl);
			if(logList.size() > 0 ){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
				flsWrap = FLSChecker.dmlInsert(logList);
				if(!flsWrap.isSuccess){
                    throw new CustomException(flsWrap.message);
				}
            }
            throw new AuraHandledException(JSON.serialize(kl));

		}
		return productMap;
	}
    /**
     * @description method to keep invoices, invoicelineItems, products in sync with salesforce
     * @return InvoiceCreationWrapper.XeroConWrapper
     * @param invoiceId
     * @param recordId
    */
    @AuraEnabled
    public static InvoiceCreationWrapper.XeroConWrapper invoiceSync(String invoiceId, String recordId){
        List<Invoice__c> updateinvList = new List<Invoice__c>(); 
        List<KTXero__Log__c> logList = new List<KTXero__Log__c>();

        List<Invoice_Line_Item__c> itemList = new List<Invoice_Line_Item__c>();
        Map<String, Invoice_Line_Item__c> invlMap = new Map<String, Invoice_Line_Item__c>();
        List<Invoice_Line_Item__c> lineItemList = new List<Invoice_Line_Item__c>();
        
        List<Payment__c> paymentsfList = new List<Payment__c>();
        Map<String, String> payMap = new Map<String, String>();
        List<Payment__c> updatepaymentList = new List<Payment__c>();

        Boolean successFlag = false;
        InvoiceCreationWrapper.XeroConWrapper xcw = new InvoiceCreationWrapper.XeroConWrapper();
        String msg = '';
        Set<String> itemSet = new Set<String>();
        try {
            itemList = [SELECT Id, Name, Line_Item_Id__c,KTXero__Product__c, KTXero__Product_Code__c FROM Invoice_Line_Item__c WHERE Invoice__c =: recordId WITH SECURITY_ENFORCED];
            if(itemList.size()>0){
                for(Invoice_Line_Item__c invl : itemList){
                    invlMap.put(invl.Line_Item_Id__c,invl);
                    itemSet.add(invl.Line_Item_Id__c);
                }
            }
            
            paymentsfList = [SELECT Id, Name, Payment_Id__c FROM Payment__c WHERE Invoice__c =: recordId WITH SECURITY_ENFORCED];
            if(paymentsfList.size()>0){
                for(Payment__c pay : paymentsfList){
                    payMap.put(pay.Payment_Id__c,pay.Id);
                }
            }

            KTXero__Invoice_Configuration_Options__c invConfig = KTXero__Invoice_Configuration_Options__c.getInstance();
            
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
                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Invoices/'+invoiceId, headerMap, 'GET', '');
               
                HttpResponse response = callObj.response;
                logList.add(callObj.exc);
    
                if(response.getStatusCode() == 200){
                    Object input = Json.deserializeUntyped(response.getBody());
                    Map<String, Product2> prodMap = new Map<String, Product2>();
    
                    String suffixed = new ReservedWordSerializer(input).getAsString();
                    DataInvoiceWrap invoicewrap = (DataInvoiceWrap)Json.deserialize(suffixed, DataInvoiceWrap.class);
                   
                    if(invoicewrap.Invoices_x.size()>0){
    
                        Map<String,Item> codeMap = new Map<String,Item>();
                        Map<String,Item> itemMap = new Map<String,Item>();
                        for(Invoices invoice : invoicewrap.Invoices_x){
                            Invoice__c inv = new Invoice__c();
                            inv.Id = recordId;
                            inv.Name = invoice.InvoiceNumber_x;
                            inv.Branding_Theme_Id__c = invoice.BrandingThemeID_x;
                            inv.Invoice_Id__c = invoice.InvoiceID_x;
                            inv.Reference__c = invoice.Reference_x;
                            inv.Type__c = invoice.Type_x;
                            inv.Amount_Due__c = invoice.AmountDue_x;
                            inv.Amount_Paid__c = invoice.AmountPaid_x;
                            inv.Sent_to_Contact__c = invoice.SentToContact_x;
                            inv.Currency_Rate__c = invoice.CurrencyRate_x;
                            inv.Currency_Code__c = invoice.CurrencyCode_x;
                            if(UserInfo.isMultiCurrencyOrganization()){
                                inv.put('CurrencyIsoCode',invoice.CurrencyCode_x);
                            }
                            inv.Status__c = invoice.Status_x;
                            if(String.isNotBlank(invoice.DateString_x)){
                                inv.Invoice_Date__c = date.valueOf(invoice.DateString_x);
                            }
                            if(String.isNotBlank(invoice.DueDateString_x)){
                                inv.Due_Date__c = date.valueOf(invoice.DueDateString_x);
                            }
                            inv.Total__c = invoice.Total_x;
                            inv.Sub_Total__c = invoice.SubTotal_x;
                            inv.Total_Tax__c = invoice.TotalTax_x;
                            inv.Amounts_Are__c = invoice.LineAmountTypes_x;
                            updateinvList.add(inv);
                            
                            
                           
                        
                            if(invoice.LineItems_x.size()>0){
                                List<LineItems> lineItemsList = invoice.LineItems_x; 
                                
                                                            
                                
                                for(LineItems li : lineItemsList){
                                    if(li.Item_x != null){
                                        if(li.Item_x?.Code_x != null){
                                            codeMap.put(li.Item_x.Code_x,li.Item_x);
                                        }

                                        if(li.Item_x?.ItemID_x != null){
                                            itemMap.put(li.Item_x.ItemID_x,li.Item_x);
                                        }
                                    }
                                }
                            }
                        }
                    
                        if(invConfig.KTXero__Create_products_in_Salesforce__c == true ){
                            // Creating new product					
                            prodMap = getProducts(codeMap,itemMap);
                        }
                            
                        for(Invoices invoice : invoicewrap.Invoices_x){
                            
                            if(invoice.LineItems_x.size()>0){

                                List<LineItems> lineItemsList = invoice.LineItems_x; 
                                for(Integer i=0;i<lineItemsList.size();i++){
                                    Invoice_Line_Item__c l = new Invoice_Line_Item__c();
                                    if(invlMap.containsKey(lineItemsList[i].LineItemID_x)){
                                        l.Id = invlMap.get(lineItemsList[i].LineItemID_x).Id;
                                        
                                        invlMap.remove(lineItemsList[i].LineItemID_x);
                                    }else{
                                        l.Name = 'LineItem-'+(i+1)+' | '+invoice.InvoiceNumber_x;
                                        l.Invoice__c = recordId;
                                    }
                                    l.Account_Code__c = lineItemsList[i].AccountCode_x;
                                    l.Description__c = lineItemsList[i].Description_x;
                                    l.Discount_Rate__c = lineItemsList[i].DiscountRate_x;
                                    l.Line_Amount__c = lineItemsList[i].LineAmount_x;
                                    l.Line_Item_Id__c = lineItemsList[i].LineItemID_x;
                                    l.Quantity__c = lineItemsList[i].Quantity_x;
                                    l.Tax_Amount__c = lineItemsList[i].TaxAmount_x;
                                    l.Tax_Type__c = lineItemsList[i].TaxType_x;
                                    l.Unit_Price__c = lineItemsList[i].UnitAmount_x;
                                    l.Discount_Amount__c = lineItemsList[i].DiscountAmount_x;
                                    if(UserInfo.isMultiCurrencyOrganization()){
                                        l.put('CurrencyIsoCode',invoice.CurrencyCode_x);
                                    }
                                    if(lineItemsList[i].Tracking_x.size()>0){
                                        List<Tracking> trackList = lineItemsList[i].Tracking_x;
                                        for(Integer j=0;j<trackList.size();j++){
                                            if(i == 0){
                                                l.Tracking_Category_1__c = trackList[j].Option_x;
                                            }else if(i == 1){
                                                l.Tracking_Category_2__c = trackList[j].Option_x;
                                            }
                                        }
                                    }
    
                                    if(lineItemsList[i].Item_x?.ItemID_x != null){
                                        if(prodMap.containsKey(lineItemsList[i].Item_x.ItemID_x)){
                                            if(invlMap.containsKey(lineItemsList[i].LineItemID_x) && invlMap.get(lineItemsList[i].LineItemID_x).KTXero__Product__c != null){
                                                if(invlMap.get(lineItemsList[i].LineItemID_x).KTXero__Product__c != prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id){
                                                    l.KTXero__Product__c = prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id;
                                                }
                                            }
                                            else{
                                                l.KTXero__Product__c = prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id;
                                            }
                                        }
                                    }
                                    lineItemList.add(l);
                                }
                            }
                            
                            if(invoice.Payments_x != null){
                                if(invoice.Payments_x.size()>0){
                                    List<Payments> paymentList = invoice.Payments_x; 
                                    for(Integer i=0;i<paymentList.size();i++){
                                        Payment__c pay = new Payment__c();
                                        if(payMap.containsKey(paymentList[i].PaymentID_x)){
                                            pay.Id = payMap.get(paymentList[i].PaymentID_x);
                                            payMap.remove(paymentList[i].PaymentID_x);
                                        }else{
                                            pay.Name = 'Payment-'+(i+1)+' | '+invoice.InvoiceNumber_x;
                                            pay.Invoice__c = recordId;
                                        }
                                        pay.Amount__c = paymentList[i].Amount_x;
        
                                        String d = paymentList[i].Date_x;
                                        d = d.remove('/');
                                        d = d.remove('Date');
                                        d = d.remove('(');
                                        d = d.remove(')');
                                        d = d.substringBefore('+');
                                        Long epoch = long.valueOf(d);
                                        Datetime dt = DateTime.newInstance(epoch);
        
                                        pay.Payment_Date__c = dt.date();
                                        pay.Payment_Id__c = paymentList[i].PaymentID_x;
                                        pay.Refrence__c	 = paymentList[i].Reference_x;
                                        pay.Currency_Rate__c = paymentList[i].CurrencyRate_x;
                                        updatepaymentList.add(pay);
                                    }
                                }
                            }
                        }
            
                        
                        // update invoice
                        if(updateinvList.size() > 0){
                            FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                            flsWrap = FLSChecker.dmlUpdate(updateinvList);
                            if(!flsWrap.isSuccess){
                                throw new AuraHandledException(flsWrap.message);
                            }else{
                                successFlag = true;
                            }
                        }
                    
                        // Upsert Line Items
                        if(lineItemList.size() > 0){

                            FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                            flsWrap = FLSChecker.dmlUpsert(lineItemList);
                            if(!flsWrap.isSuccess){
                                throw new AuraHandledException(flsWrap.message);
                            }else{
                                successFlag = true;
                            }

                        }
    
                        if(invlMap.size()>0){
                            List<Invoice_Line_Item__c> invdeleteList = new List<Invoice_Line_Item__c>(); 
                            for(String s : invlMap.keySet()){
                                Invoice_Line_Item__c li = new Invoice_Line_Item__c();
                                li.Id = invlMap.get(s).Id;
                                invdeleteList.add(li);
                            }
    
                            if(Schema.sObjectType.Invoice_Line_Item__c.isDeletable()){

                                Database.DeleteResult[] drList = Database.delete(invdeleteList);
        
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
    
                        // Upsert Payments
                        if(updatepaymentList.size() > 0){
                            FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                            flsWrap = FLSChecker.dmlUpsert(updatepaymentList);
                            if(!flsWrap.isSuccess){
                                throw new AuraHandledException(flsWrap.message);
                            }else{
                                successFlag = true;
                            }
                        }
                       
    
                        if(payMap.keySet().size()>0){
                            List<KTXero__Payment__c> paydeleteList = new List<KTXero__Payment__c>(); 
                            for(String s : payMap.keySet()){
                                KTXero__Payment__c p = new KTXero__Payment__c();
                                p.Id = payMap.get(s);
                                paydeleteList.add(p);
                            }
    
                            if(Schema.sObjectType.KTXero__Payment__c.isDeletable()){

                                Database.DeleteResult[] drList = Database.delete(paydeleteList);
        
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
                }else{
                    InvoiceCreationWrapper.ErrorWrapper invoicewrap = (InvoiceCreationWrapper.ErrorWrapper)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.ErrorWrapper.class);
                    for(InvoiceCreationWrapper.Elements ele : invoicewrap.Elements){
                        for(InvoiceCreationWrapper.ValidationErrors vle : ele.ValidationErrors){
                            msg += vle.Message;
                            msg += ', ';
                        }
                    }
                    msg = msg.removeEnd(', ');
                    successFlag = false;
                }
              
                if(logList.size() > 0){
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    flsWrap = FLSChecker.dmlInsert(logList);
                    if(!flsWrap.isSuccess){
                        throw new AuraHandledException(flsWrap.message);
                    }else{
                        successFlag = true;
                    }
                }
            }
        } catch (Exception e) {
            // throw new AuraHandledException(e.getMessage());
             successFlag = false;
            msg += e.getMessage();
            if(logList.size() > 0){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    throw new AuraHandledException(flsWrap.message);
                }
            }
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));

        }
        xcw.successFlag = successFlag;
        xcw.message = msg;
        return xcw;
    }
    /**
     * @description Method to fetch the xero contact from salesforce
     * @param recordId
     * @return XeroContactWrapper
    */
    @AuraEnabled
    public static XeroContactWrapper getxeroContact(String recordId){
        Xero_Contact__c xc = new Xero_Contact__c();
        XeroContactWrapper xcw = new XeroContactWrapper();
        try {
            xc = [SELECT Id, Name, KTXero__Company_Name__c, KTXero__Reference_Id__c FROM KTXero__Xero_Contact__c  WHERE Id =: recordId WITH SECURITY_ENFORCED];
            xcw.conId = xc.Id;
            xcw.conName = xc.Name;
            xcw.companyName = xc.KTXero__Company_Name__c;
            xcw.referenceId = xc.KTXero__Reference_Id__c;

        } catch (Exception e) {
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        return xcw;
    }
    /**
     * @description Method to keep Salesfoce contact in sync with Xero
     * @return InvoiceCreationWrapper.XeroConWrapper
     * @param xeroConId
     * @param recordId
    */
    @AuraEnabled
    public static InvoiceCreationWrapper.XeroConWrapper xerocontactSync(String xeroConId, String recordId){
        List<Xero_Contact__c> xconList = new List<Xero_Contact__c>();
        List<KTXero__Log__c> logList = new List<KTXero__Log__c>();

        Boolean successFlag = false;
        InvoiceCreationWrapper.XeroConWrapper xcw = new InvoiceCreationWrapper.XeroConWrapper();
        String msg = '';
        try {
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
                // xeroConId = 'abc';
                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/contacts/'+xeroConId, headerMap, 'GET', '');
                HttpResponse response = callObj.response;
                logList.add(callObj.exc);
    
                if(response.getStatusCode() == 200){
                    InvoiceCreationWrapper.Datawrap ct1 = (InvoiceCreationWrapper.Datawrap)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.Datawrap.class);
                  
                    for(InvoiceCreationWrapper.Contacts con : ct1.Contacts){
                        Xero_Contact__c xcon = new Xero_Contact__c();
                        xcon.Id = recordId;
                        xcon.Company_Name__c = con.Name;
                        xcon.First_Name__c = con.FirstName;
                        xcon.Last_Name__c = con.LastName;
                        xcon.Email_Address__c = con.EmailAddress;
                        xcon.Reference_Id__c = con.ContactId;
                        xcon.Status__c = con.ContactStatus;
                        if(con.ContactPersons.size()>0){
                            for(Integer i=0;i<con.ContactPersons.size();i++){
                                InvoiceCreationWrapper.ContactPersons cp = new InvoiceCreationWrapper.ContactPersons();
                                cp = con.ContactPersons[i];
                                if(i == 0){
                                    xcon.Contact_1_First_Name__c = cp.FirstName; 
                                    xcon.Contact_1_Last_Name__c = cp.LastName; 
                                    xcon.Contact_1_Email__c = cp.EmailAddress; 
                                    xcon.Contact_1_Include_in_Emails__c = cp.IncludeInEmails; 
                                }else if(i == 1){
                                    xcon.Contact_2_First_Name__c = cp.FirstName; 
                                    xcon.Contact_2_Last_Name__c = cp.LastName; 
                                    xcon.Contact_2_Email__c = cp.EmailAddress; 
                                    xcon.Contact_2_Include_in_Emails__c = cp.IncludeInEmails; 
                                }else if(i == 2){
                                    xcon.Contact_3_First_Name__c = cp.FirstName; 
                                    xcon.Contact_3_Last_Name__c = cp.LastName; 
                                    xcon.Contact_3_Email__c = cp.EmailAddress; 
                                    xcon.Contact_3_Include_in_Emails__c = cp.IncludeInEmails; 
                                }else if(i == 3){
                                    xcon.Contact_4_First_Name__c = cp.FirstName; 
                                    xcon.Contact_4_Last_Name__c = cp.LastName; 
                                    xcon.Contact_4_Email__c = cp.EmailAddress; 
                                    xcon.Contact_4_Include_in_Emails__c = cp.IncludeInEmails; 
                                }else if(i == 4){
                                    xcon.Contact_5_First_Name__c = cp.FirstName; 
                                    xcon.Contact_5_Last_Name__c = cp.LastName; 
                                    xcon.Contact_5_Email__c = cp.EmailAddress; 
                                    xcon.Contact_5_Include_in_Emails__c = cp.IncludeInEmails; 
                                }
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
                        xconList.add(xcon);
                    }
                    
                    if(xconList.size() > 0 ){
                        FLSChecker.FLSCheckWrapper flWrap = new FLSChecker.FLSCheckWrapper();
                        flWrap = FLSChecker.dmlUpdate(xconList);

                        if(!flWrap.isSuccess){
                            throw new AuraHandledException(flWrap.message);
                        }else{
                            successFlag = true;
                        }
                    }
                 
                }else{
                    InvoiceCreationWrapper.ErrorWrapper conwrap = (InvoiceCreationWrapper.ErrorWrapper)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.ErrorWrapper.class);
                    for(InvoiceCreationWrapper.Elements ele : conwrap.Elements){
                        for(InvoiceCreationWrapper.ValidationErrors vle : ele.ValidationErrors){
                            msg += vle.Message;
                            msg += ', ';
                        }
                    }
                    msg = msg.removeEnd(', ');
                    successFlag = false;
                }

                if(logList.size() > 0 ){
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    flsWrap = FLSChecker.dmlInsert(logList);
                    if(!flsWrap.isSuccess){
                        throw new AuraHandledException(flsWrap.message);
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
                    }else{
                        successFlag = true;
                    }
                 }
            }
            
        } catch (Exception e) {
            successFlag = false;
            msg += e.getMessage();
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
       
        xcw.successFlag = successFlag;
        xcw.message = msg;
        return xcw;

    }
 

    /**
     * @description Method to keep Salesfoce Account in sync with Xero
     * @description Removing KTXero__Number_Code__c FROM SOQL and adding KTXero__Account_Code__c|| Yash Patel || 7 May 2024z 
     * @return XeroMetadataSyncWrapper
    */
    @AuraEnabled
    public static XeroMetadataSyncWrapper xeroAccountsSync(){
        List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
        Boolean successFlag = false;
        List<Xero_Metadata__c> xmList = new List<Xero_Metadata__c>();
        List<Xero_Metadata__c> xmUpdateList = new List<Xero_Metadata__c>();
        Map<String, String> metadataMap = new Map<String, String>();
        XeroMetadataSyncWrapper xmWrap = new XeroMetadataSyncWrapper();
        try{
            // get Xero Accounts
            xmList = [SELECT Id, Name, KTXero__Account_Code__c, Text__c, Type__c, Value__c, Code__c, Xero_Id__c, Status__c FROM Xero_Metadata__c WHERE Type__c = 'Accounts' WITH SECURITY_ENFORCED];
            if(xmList.size()>0){
                for(Xero_Metadata__c xm : xmList){
                    metadataMap.put(xm.Xero_Id__c,xm.Id);
                }
            }

            // fetch xero accounts from Xero
            if(xeroConnect != null){
                Boolean flag = Utils.checkTokenExpiry(xeroConnect.KTXero__Last_Token_Refresh_Time__c);
                KTXero__Xero_Connection__c connection = new KTXero__Xero_Connection__c();
                Map<String, String> headerMap = new Map<String, String>();

                if(flag){
                    headerMap.put('xero-tenant-id',String.isNotBlank(Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c)) ? Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c) : '');
                    headerMap.put('authorization',String.isNotBlank(Utils.processDecryption(xeroConnect.KTXero__Access_Token__c)) ? 'Bearer '+Utils.processDecryption(xeroConnect.KTXero__Access_Token__c) : '');
                    // headerMap.put('Accept','application/json');
                }else{
                    connection = Utils.refreshToken();
                    headerMap.put('xero-tenant-id',String.isNotBlank(Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c)) ? Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c) : '');
                    headerMap.put('authorization',String.isNotBlank(Utils.processDecryption(connection.KTXero__Access_Token__c)) ? 'Bearer '+Utils.processDecryption(connection.KTXero__Access_Token__c) : '');
                    // headerMap.put('Accept','application/json');
                }
                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Accounts', headerMap, 'GET', '');
                
                HttpResponse response = callObj.response;
                logList.add(callObj.exc);
    
    
                if(response.getStatusCode() == 200){
                    System.debug('response.getBody()-->'+response.getBody());
                    InvoiceCreationWrapper.XeroAccountWrapper templateswrap = (InvoiceCreationWrapper.XeroAccountWrapper)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.XeroAccountWrapper.class);
                    System.debug('templateswrap-->'+templateswrap);
                    for(InvoiceCreationWrapper.Accounts acct : templateswrap.Accounts){
                        if(acct.Type != 'BANK'){
                            Xero_Metadata__c xm = new Xero_Metadata__c();
                            if(metadataMap.containsKey(acct.AccountID)){
                                xm.Id = metadataMap.get(acct.AccountID);
                                metadataMap.remove(acct.AccountID);
                            }
                            xm.Type__c = 'Accounts';
                            //Commenting Number_Code__c (Number) as it is replaced with now with new KTXero__Account_Code__c (String) field 
                            // xm.Number_Code__c = Decimal.ValueOf(acct.Code);
                            xm.KTXero__Account_Code__c = acct.Code;
                            xm.Text__c = acct.Code+' - '+acct.Name;
                            xm.Value__c = acct.TaxType;
                            xm.Code__c = acct.Type;
                            xm.Xero_Id__c = acct.AccountID;
                            xm.Status__c  = acct.Status;
                            xmUpdateList.add(xm);
                        }
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

                    // Upsert Accounts
                    if(xmUpdateList.size() > 0){
                        FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                        flsWrap = FLSChecker.dmlUpsert(xmUpdateList);
                        if(!flsWrap.isSuccess){
                            throw new AuraHandledException(flsWrap.message);
                        }else{
                            successFlag = true;   
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

    @AuraEnabled
    public static InvoiceCreationWrapper.XeroConWrapper syncXeroConSFToXero(String contactId, String recordId){
        List<KTXero__Log__c> logList = new list<KTXero__Log__c>();
        InvoiceCreationWrapper.XeroConWrapper xcw = new InvoiceCreationWrapper.XeroConWrapper(); 
        Boolean successFlag = false;
        String msg = '';
        try{

            List<Xero_Contact__c> salesCon = new List<Xero_Contact__c>();
			salesCon = [SELECT 
                            Id,KTXero__Company_Name__c, KTXero__First_Name__c,KTXero__Last_Name__c, KTXero__Email_Address__c, 
                            KTXero__Account_Number__c, KTXero__Salesforce_Account__c, KTXero__Salesforce_Account__r.name, KTXero__Opportunity__c,  KTXero__Status__c, 
                            KTXero__Reference_Id__c, 
                            KTXero__Contact_1_First_Name__c,KTXero__Contact_1_Last_Name__c,
                            KTXero__Contact_1_Email__c, KTXero__Contact_1_Include_in_Emails__c,KTXero__Contact_2_First_Name__c,
                            KTXero__Contact_2_Last_Name__c,KTXero__Contact_2_Email__c, KTXero__Contact_2_Include_in_Emails__c, 
                            KTXero__Contact_3_First_Name__c,KTXero__Contact_3_Last_Name__c,KTXero__Contact_3_Email__c, 
                            KTXero__Contact_3_Include_in_Emails__c, KTXero__Contact_4_First_Name__c,KTXero__Contact_4_Last_Name__c,
                            KTXero__Contact_4_Email__c, KTXero__Contact_4_Include_in_Emails__c,KTXero__Contact_5_First_Name__c,
                            KTXero__Contact_5_Last_Name__c,KTXero__Contact_5_Email__c, KTXero__Contact_5_Include_in_Emails__c, 
                            KTXero__Street_Address__c,KTXero__Town_City__c, KTXero__State_Region__c, KTXero__Postal_Zip_Code__c,
                            KTXero__Country__c, KTXero__Shipping_Street_Address__c,KTXero__Shipping_Town_City__c,
                            KTXero__Shipping_State_Region__c, KTXero__Shipping_Postal_Zip_Code__c, 
                            KTXero__Shipping_Country__c 
                        FROM KTXero__Xero_Contact__c 
                        WHERE Id =: recordId WITH SECURITY_ENFORCED];
            
            if(salesCon.size() > 0){
                Xero_Contact__c con = salesCon[0];
                String conJSON='{"Contacts": [{"Name": "'+con.KTXero__Company_Name__c+'",'+' "FirstName": "'+con.KTXero__First_Name__c+' ",'+' "LastName": "'+con.KTXero__Last_Name__c+' ",'+'"EmailAddress": "'+con.KTXero__Email_Address__c+' ",'+'"AccountNumber": "'+con.KTXero__Account_Number__c+' "';
                String streetAdd = '';
                String city = '';
                String region = '';
                String postal = '';
                String country = '';

                if(String.isNotBlank(con.KTXero__Street_Address__c)){
                    streetAdd = con.KTXero__Street_Address__c;
                }
                
                if(String.isNotBlank(con.Town_City__c)){
                    city = con.Town_City__c;
                }
                if(String.isNotBlank(con.State_Region__c)){
                    region = con.State_Region__c;
                }
                if(String.isNotBlank(con.Postal_Zip_Code__c)){
                    postal = con.Postal_Zip_Code__c;
                }
                if(String.isNotBlank(con.Country__c)){
                    country = con.Country__c;
                }
                if(String.isNotBlank(con.State_Region__c) || String.isNotBlank(con.Postal_Zip_Code__c) || String.isNotBlank(con.Country__c)){

                    conJSON += ',"Addresses": [{"AddressType": "POBOX","AddressLine1": "'+streetAdd+'","City": "'+city+'","Region":"'+region+'","PostalCode": "'+postal+'","Country":"'+country+'"}]';
                    
                }

                if(String.isNotBlank(con.KTXero__Contact_1_First_Name__c) && String.isNotBlank(con.KTXero__Contact_1_Last_Name__c) && String.isNotBlank(con.KTXero__Contact_1_Email__c) ){
                    conJSON+=',"ContactPersons": [';
                    conJSON+='{"FirstName": "'+con.KTXero__Contact_1_First_Name__c+'",'+'"LastName": "'+con.KTXero__Contact_1_Last_Name__c+'",'+'"EmailAddress": "'+con.KTXero__Contact_1_Email__c+'",'+'"IncludeInEmails": "'+String.valueof(con.KTXero__Contact_1_Include_in_Emails__c)+'"}';
                    conJSON+=']';
                }
                if(String.isNotBlank(con.KTXero__Contact_2_First_Name__c) && String.isNotBlank(con.KTXero__Contact_2_Last_Name__c) && String.isNotBlank(con.KTXero__Contact_2_Email__c) ){
                    conJSON = conJSON.removeEnd(']');
                    conJSON+=',{"FirstName": "'+con.KTXero__Contact_2_First_Name__c+'",'+'"LastName": "'+con.KTXero__Contact_2_Last_Name__c+'",'+'"EmailAddress": "'+con.KTXero__Contact_2_Email__c+'",'+'"IncludeInEmails": "'+String.valueof(con.KTXero__Contact_2_Include_in_Emails__c)+'"}';
                    conJSON+=']';
                }
                if(String.isNotBlank(con.KTXero__Contact_3_First_Name__c) && String.isNotBlank(con.KTXero__Contact_3_Last_Name__c) && String.isNotBlank(con.KTXero__Contact_3_Email__c) ){
                    conJSON = conJSON.removeEnd(']');
                    conJSON+=',{"FirstName": "'+con.KTXero__Contact_3_First_Name__c+'",'+'"LastName": "'+con.KTXero__Contact_3_Last_Name__c+'",'+'"EmailAddress": "'+con.KTXero__Contact_3_Email__c+'",'+'"IncludeInEmails": "'+String.valueof(con.KTXero__Contact_3_Include_in_Emails__c)+'"}';
                    conJSON+=']';
                }
                if(String.isNotBlank(con.KTXero__Contact_4_First_Name__c) && String.isNotBlank(con.KTXero__Contact_4_Last_Name__c) && String.isNotBlank(con.KTXero__Contact_4_Email__c) ){
                    conJSON = conJSON.removeEnd(']');
                    conJSON+=',{"FirstName": "'+con.KTXero__Contact_4_First_Name__c+'",'+'"LastName": "'+con.KTXero__Contact_4_Last_Name__c+'",'+'"EmailAddress": "'+con.KTXero__Contact_4_Email__c+'",'+'"IncludeInEmails": "'+String.valueof(con.KTXero__Contact_4_Include_in_Emails__c)+'"}';
                    conJSON+=']';
                }
                if(String.isNotBlank(con.KTXero__Contact_5_First_Name__c) && String.isNotBlank(con.KTXero__Contact_5_Last_Name__c) && String.isNotBlank(con.KTXero__Contact_5_Email__c) ){
                    conJSON = conJSON.removeEnd(']');
                    conJSON+=',{"FirstName": "'+con.KTXero__Contact_5_First_Name__c+'",'+'"LastName": "'+con.KTXero__Contact_5_Last_Name__c+'",'+'"EmailAddress": "'+con.KTXero__Contact_5_Email__c+'",'+'"IncludeInEmails": "'+String.valueof(con.KTXero__Contact_5_Include_in_Emails__c)+'"}';
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
                        msg = con.Id;
                        successFlag = true;
                    }else{
                        InvoiceCreationWrapper.ErrorWrapper invoicewrap = (InvoiceCreationWrapper.ErrorWrapper)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.ErrorWrapper.class);
                        for(InvoiceCreationWrapper.Elements ele : invoicewrap.Elements){
                            for(InvoiceCreationWrapper.ValidationErrors vle : ele.ValidationErrors){
                                msg += vle.Message;
                                msg += ', ';
                            }
                        }
                        msg = msg.removeEnd(', ');
                        successFlag = false;
                    }
                }    

                if(logList.size() > 0){
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    flsWrap = FLSChecker.dmlInsert(logList);
                    if(!flsWrap.isSuccess){
                        throw new AuraHandledException(flsWrap.message);
                    }else{
                        successFlag = true;
                    }
                }
            }
        } catch (Exception e) {

            successFlag = false;
            msg += e.getMessage();
            if(logList.size() > 0){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    throw new AuraHandledException(flsWrap.message);
                }
            }
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));

        }
        xcw.successFlag = successFlag;
        xcw.message = msg;
        return xcw;
        
    }

    @AuraEnabled
    public static InvoiceCreationWrapper.XeroConWrapper syncSFToXero(String invoiceId, String recordId){
        InvoiceCreationWrapper invWrap = new InvoiceCreationWrapper();
        Invoice__c inv = new Invoice__c();   
        InvoiceCreationWrapper.XeroConWrapper xcw = new InvoiceCreationWrapper.XeroConWrapper();
        String msg = '';
        Boolean successFlag = false;

        List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
        try{
            String qry = 'SELECT Id, Name, Invoice_Id__c, Status__c , Type__c, Account__c, Xero_Contact__c, Xero_Contact__r.KTXero__Company_Name__c,Xero_Contact__r.KTXero__Reference_Id__c,Opportunity__c,Branding_Theme_Id__c,Reference__c,Amount_Due__c,Amount_Paid__c,Sent_to_Contact__c,Currency_Rate__c,Currency_Code__c,Invoice_Date__c, Due_Date__c, Total__c,Sub_Total__c, Total_Tax__c, Amounts_Are__c,(SELECT Id, Name, KTXero__Invoice__c, KTXero__Account_Code__c, KTXero__Description__c, KTXero__Discount_Rate__c, KTXero__Item_Code__c, KTXero__Line_Amount__c, KTXero__Line_Item_Id__c, KTXero__Product__c, KTXero__Quantity__c, KTXero__Tax_Amount__c, KTXero__Tax_Type__c, KTXero__Tracking_Category_1__c, KTXero__Product_Code__c, KTXero__Discount_Amount__c, KTXero__Tracking_Category_2__c, KTXero__Unit_Price__c,KTXero__Product__r.Name,KTXero__Product__r.KTXero__Xero_ItemID__c,KTXero__Product__r.ProductCode, CreatedDate FROM KTXero__Invoice_Line_Items__r),(SELECT Id, Name, KTXero__Account_Id__c, KTXero__Amount__c, KTXero__Invoice__c, KTXero__Payment_Id__c, KTXero__Payment_Date__c, KTXero__Payment_Type__c, KTXero__Refrence__c, KTXero__Status__c, KTXero__Currency_Rate__c, KTXero__Paid_To__c FROM KTXero__Payments__r)FROM Invoice__c WHERE Id =: recordId WITH SECURITY_ENFORCED';
            inv = Database.query(qry);
            if(inv != null){
                String state = '';
                if(String.isNotBlank(inv.Status__c)){
                    state = inv.Status__c;
                }

                String invJSON = '{"Type":"'+inv.Type__c+'","InvoiceId":"'+inv.Invoice_Id__c+'"';
                string dueDateString = '';
                if(inv.Due_Date__c != null){
                    dueDateString = String.valueOf(inv.Due_Date__c);
                }
                if(inv.Reference__c == null){
                    inv.Reference__c = '';
                }
                invJSON += ',"Contact": {"ContactID":"'+inv.Xero_Contact__r.KTXero__Reference_Id__c+'"},"DateString":"'+String.valueOf(inv.Invoice_Date__c)+'","CurrencyCode":"'+inv.Currency_Code__c+'","Reference":"'+inv.Reference__c+'","DueDateString":"'+dueDateString+'","BrandingThemeID":"'+inv.Branding_Theme_Id__c+'","Status":"'+state+'","LineAmountTypes": "'+inv.Amounts_Are__c+'"';
                
                if(inv.KTXero__Invoice_Line_Items__r.size() > 0){
                    invJSON += ',"LineItems": [';
                    
                    // for(KTXero__Invoice_Line_Item__c li : inv.KTXero__Invoice_Line_Items__r){
                    //     if(String.isNotBlank(Tracking_Category_1__c) )
                    // }

                    for(KTXero__Invoice_Line_Item__c li : inv.KTXero__Invoice_Line_Items__r){
                        if(String.isNotBlank(li.Description__c)){
                            invJSON += '{"Description": "'+li.Description__c+'"';
                        }else{
                            invJSON += '{"Description": "-"';   
                        }
                        if(String.isNotBlank(li.Tax_Type__c) && li.Tax_Type__c != '' && li.Tax_Type__c != null){
                            invJSON += ',"TaxType": "'+li.Tax_Type__c+'"';
                        }

                        
                        invJSON += ',"Quantity": "'+li.Quantity__c+'","UnitAmount": "'+li.Unit_Price__c+'","DiscountRate" : "'+li.Discount_Rate__c+'"';
                        if(String.isNotBlank(li.Account_Code__c) && li.Account_Code__c != 'NaN' && li.Account_Code__c != null){
                            invJSON += ',"AccountCode": "'+li.Account_Code__c+'"';
                        }else{
                            invJSON += ',"AccountCode": ""';
                        }
                        // if(String.isNotBlank(li.KTXero__Item_Code__c)){
                        //     invJSON +=',"ItemCode": "'+li.KTXero__Item_Code__c+'"';
                        // }
                        if(String.isNotBlank(li.KTXero__Line_Item_Id__c)){
                            invJSON +=',"LineItemID": "'+li.KTXero__Line_Item_Id__c+'"';
                        }
                        if(String.isNotBlank(li.KTXero__Product__c)){
                            if(String.isNotBlank(li.KTXero__Product__r.KTXero__Xero_ItemID__c)){
                                invJSON +=',"ItemCode": "'+li.KTXero__Product__r.ProductCode+'"';
                                invJSON +=',"Item": {"ItemId":"'+li.KTXero__Product__r.KTXero__Xero_ItemID__c+'","Name":"'+li.KTXero__Product__r.name+'","Code":"'+li.KTXero__Product__r.ProductCode+'"}';
                            }
                        }
                        
                        
                        /*if(li.Tracking_Category_1__c != null || li.Tracking_Category_2__c != null){
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
                        }*/
                        
                        invJSON += '},';
                    }
                }
                
                invJSON = invJSON.removeEnd(',');
                
                invJSON += ']';
                if(inv.KTXero__Payments__r.size() > 0){
                    invJSON += ',"Payments": [';
                    for(KTXero__Payment__c pay : inv.KTXero__Payments__r){
                        String accId = '';
                        if(pay.Account_Id__c != null){
                            accId = pay.Account_Id__c;
                        }
                        String paymentDate = '';
                        if(pay.Payment_Date__c != null){
                            paymentDate = String.valueOf(pay.Payment_Date__c);
                        }
                        invJSON += '{"PaymentID": "'+pay.KTXero__Payment_Id__c+'","Account": "'+accId+'","Date" : "'+paymentDate+'","Amount" : "'+pay.Amount__c+'","Reference" : "'+pay.KTXero__Refrence__c+'","CurrencyRate" : "'+pay.KTXero__Currency_Rate__c+'"';
                        // invJSON += '{"Invoice": "'+inv.Invoice_Id__c+'","Account": "'+accId+'","Date" : "'+paymentDate+'","Amount" : "'+pay.Amount__c+'"';
                        // invJSON = invJSON.removeEnd(',');
                        invJSON += '},';
                    }
                    invJSON = invJSON.removeEnd(',');
                    invJSON += ']';
                }
                invJSON += '}';

                //Making Callout
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

                    XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Invoices/'+inv.Invoice_Id__c, headerMap, 'POST', invJSON);

                    HttpResponse response = callObj.response;
                    logList.add(callObj.exc);
                    
                    if(response.getStatusCode() == 200){
                        msg = inv.Id;
                        successFlag = true;
                    }else{
                        InvoiceCreationWrapper.ErrorWrapper invoicewrap = (InvoiceCreationWrapper.ErrorWrapper)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.ErrorWrapper.class);
                        for(InvoiceCreationWrapper.Elements ele : invoicewrap.Elements){
                            for(InvoiceCreationWrapper.ValidationErrors vle : ele.ValidationErrors){
                                msg += vle.Message;
                                msg += ', ';
                            }
                        }
                        msg = msg.removeEnd(', ');
                        successFlag = false;
                    }
                }
            }
            
        }catch(Exception e){
            successFlag = false;
            msg += e.getMessage();
            if(logList.size() > 0){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    throw new AuraHandledException(flsWrap.message);
                }
            }
            KTXero__Log__c lg = HandleCustomException.LogException(e);
            throw new AuraHandledException(JSON.serialize(lg));
        }
        xcw.successFlag = successFlag;
        xcw.message = msg;
        return xcw;
        // return invWrap;
    }
    /**
     * @description Class to manage Xero meta information
    */
    public class XeroMetadataSyncWrapper{
        @AuraEnabled public boolean successFlag ;
        @AuraEnabled public String message ;
        @AuraEnabled public List<InvoiceConfigurationController.XeroMetadataWrapper> metadataList ;
    }
    /**
     * @description Class to manage invoice data
    */
    public class DataInvoiceWrap{
        public String id_x;
        public String status_x;
        public String providerName_x;
        public String dateTimeUTC_x;
        public List<Invoices> invoices_x;
    }
    /**
     * @description Class to manage invoice details
    */
    public class Invoices{
        public String type_x;
        public String invoiceID_x;
        public String invoiceNumber_x;
        public String reference_x;
        public Decimal amountDue_x;
        public Decimal amountPaid_x;
        public boolean sentToContact_x;
        public Decimal currencyRate_x;
        public Decimal totalDiscount_x;
        public boolean isDiscounted_x;
        public boolean hasErrors_x;
        public String dateString_x;
        public String dueDateString_x;
        public String dueDate_x;
        public String brandingThemeID_x;
        public String status_x;
        public String lineAmountTypes_x;
        public List<LineItems> lineItems_x;
        public Double subTotal_x;
        public Double totalTax_x;
        public Decimal total_x;
        public String updatedDateUTC_x;
        public String currencyCode_x;
        public List<Payments> payments_x;
    }
    /**
     * @description Class to manage Invoice line items
    */
    public class LineItems {
        public String description_x;
        public Decimal unitAmount_x;
        public String taxType_x;
        public Decimal taxAmount_x;
        public Decimal lineAmount_x;
        public String accountCode_x;
        public List<Tracking> tracking_x;
        public Decimal quantity_x;
        public Decimal discountRate_x;
        public String lineItemID_x;
        public boolean discountEnteredAsPercent_x;
        public Double discountAmount_x;
		public Item item_x; 
    }
    /**
     * @description Class to manage Product details
    */
    public class Item {
		public String code_x;
		public String itemID_x;
		public String name_x;
	}
    /**
     * @description Class to manage tracking details
    */
    public class Tracking {
        public String name_x;
        public String option_x;
        public String trackingCategoryID_x;
        public String trackingOptionID_x;
    }
    /**
     * @description Class to manage Payment details
    */
    public class Payments {
		public String paymentID_x;
		public String date_x;
		public Decimal amount_x;
		public String reference_x;
		public Decimal currencyRate_x;
		public boolean hasAccount_x;
		public boolean hasValidationErrors_x;
	}
    /**
     * @description Class to manage Invoice details
    */
    public class InvoiceWrapper{
        @AuraEnabled public String invId ;
        @AuraEnabled public String invName ;
        @AuraEnabled public String invStatus ;
    }
    /**
     * @description Class to manage Xero contact details
    */
    public class XeroContactWrapper{
        @AuraEnabled public String conId ;
        @AuraEnabled public String conName ;
        @AuraEnabled public String companyName ;
        @AuraEnabled public String referenceId ;
    }
}