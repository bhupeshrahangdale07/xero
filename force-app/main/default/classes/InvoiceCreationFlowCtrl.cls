public class InvoiceCreationFlowCtrl {
    
    @InvocableMethod(label='Create Xero Invoice' description='Create Xero Invoice')
    public static void createXeroInvoiceFuture(List<InvoiceCreationWrapperFlow> invoiceData){
        System.debug('invoiceData==='+invoiceData);
        createXeroInvoice(JSON.serialize(invoiceData[0]));
    }

    @future(callout=true)
    public static void createXeroInvoice(String invoiceData){
        Boolean sendEmail = false;
        String msg = '';
        Boolean successFlag = false;
        InvoiceCreationWrapperFlow invFlow = (InvoiceCreationWrapperFlow) JSON.deserialize(invoiceData, InvoiceCreationWrapperFlow.class);
        System.debug('invFlow-->'+invFlow);

        if(invFlow.invStatus == 'ApprovedEmail'){
            invFlow.invStatus = 'AUTHORISED';
            sendEmail = true;
        }

        InvoiceCreationWrapper.InvoiceOppMappingWrapper invoppWrap = new InvoiceCreationWrapper.InvoiceOppMappingWrapper();
        List<InvoiceCreationWrapper.OppproductWrapper> productwrapperList = new List<InvoiceCreationWrapper.OppproductWrapper>();
        List<KTXero__Xero_Metadata__c> xmList = new List<KTXero__Xero_Metadata__c>();
        List<KTXero__Log__c> logList = new list<KTXero__Log__c>();
        List<Invoice_Line_Item__c> lineItemList = new List<Invoice_Line_Item__c>();
        Opportunity opp = new Opportunity();
        KTXero__Xero_Contact__c xc = new KTXero__Xero_Contact__c();
        try{
            opp = [SELECT Id, Name, AccountId FROM Opportunity WHERE Id =: invFlow.oppId];
            xc = [SELECT Id FROM KTXero__Xero_Contact__c WHERE KTXero__Reference_Id__c =: invFlow.contactId];
            invoppWrap = InvoiceCreationController.getinvoiceOppMapping(invFlow.oppId);
            productwrapperList = InvoiceCreationController.getOpportunityProducts(invFlow.oppId);
            
            KTXero__Invoice_Configuration_Options__c invConfig = KTXero__Invoice_Configuration_Options__c.getOrgDefaults();

            String dueDate = '';
            if(invoppWrap.dueDate != null){
                dueDate = String.valueOf(invoppWrap.dueDate);
            }else{
                dueDate = '';
            }

            String invDate = '';
            if(invoppWrap.invDate != null){
                invDate = String.valueOf(invoppWrap.invDate);
            }else{
                invDate = '';
            }

            String invJSON = '';
            invJSON+=
            '{'+
                '"Type": "ACCREC",'+
                '"CurrencyCode": "'+invoppWrap.currencyIsoCode+'",'+
                '"Status": "'+invFlow.invStatus+'",'+
                '"Contact": {'+
                '  "ContactID": "'+invFlow.contactId+'"'+
                '},'+
                '"DateString": "'+invDate+'",'+
                '"DueDateString": "'+dueDate+'",'+
                '"Reference": "'+invoppWrap.reference+'",'+
                '"BrandingThemeID": "'+invConfig.KTXero__Invoice_Template__c+'",'+
                '"LineAmountTypes": "'+invConfig.KTXero__Xero_Accounting_Tax_Type__c+'"';

            
            if(productwrapperList.size() > 0){

                invJSON+=',"LineItems": [';

                for(InvoiceCreationWrapper.OppproductWrapper opw : productwrapperList){
                    if(opw.description == null || opw.description == ''){
                        invJSON += '{"Description": "-"';
                    }else{
                        invJSON += '{"Description": "'+opw.description+'"';
                    }

                    if(String.isNotBlank(opw.taxRate) && opw.taxRate != '' && opw.taxRate != null){
                        invJSON += ',"TaxType": "'+opw.taxRate+'"';
                    }else{
                        invJSON += ',"TaxType": "'+invConfig.KTXero__Default_Tax_rate__c+'"';
                    }

                    invJSON += ',"Quantity": "'+opw.quantity+'","UnitAmount": "'+opw.unitPrice+'","DiscountRate" : '+opw.discount+'';
                    if(String.isNotBlank(opw.account) && opw.account != 'NaN' && opw.account != null){
                        // invJSON += ',"AccountCode": "'+Integer.ValueOf(opw.account)+'"';
                        invJSON += ',"AccountCode": "'+opw.account+'"';
                    }else{
                        invJSON += ',"AccountCode": "'+invConfig.KTXero__Account_code_default__c+'"';
                    }

                    if(String.isNotBlank(opw.productCode)){
                        invJSON +=',"ItemCode": "'+opw.productCode+'"';
                    }
                    
                    xmList = [SELECT Id, Name, KTXero__Account_Code__c, KTXero__Number_Code__c, KTXero__Text__c, KTXero__Type__c, KTXero__Value__c, KTXero__Xero_Org_ID__c, KTXero__Code__c, KTXero__Xero_Id__c, KTXero__Status__c FROM KTXero__Xero_Metadata__c WHERE KTXero__Type__c = 'tracking_category' WITH SECURITY_ENFORCED];
                    if(xmList.size() > 0){
                        invJSON += ',"Tracking": [';
                        for(KTXero__Xero_Metadata__c xm : xmList){
                            if(xm.KTXero__Xero_Id__c != '' && String.isNotBlank(xm.KTXero__Xero_Id__c)){
                                invJSON += '{"TrackingCategoryID": "'+xm.KTXero__Value__c+'","Name": "'+xm.KTXero__Text__c+'","Option": "'+xm.KTXero__Xero_Id__c+'"},';
                            }
                        }
                        invJSON = invJSON.removeEnd(',');
                        invJSON += ']';
                    }
                    invJSON += '},';
                }
                invJSON = invJSON.removeEnd(',');
                invJSON+=']';
            }
            invJSON+='}';

            System.debug('invJSON-->'+invJSON);
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
                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Invoices', headerMap, 'POST', invJSON);
                System.debug('callObj-->'+callObj);
                HttpResponse response = callObj.response;
                logList.add(callObj.exc);
                if(response.getStatusCode() == 200){
                    InvoiceCreationWrapper.DataInvoiceWrap invoicewrap = (InvoiceCreationWrapper.DataInvoiceWrap)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.DataInvoiceWrap.class);
                    System.debug('invoicewrap-->'+invoicewrap);
                    msg = invoicewrap.Invoices[0].InvoiceID;
                    InvoiceCreationWrapper.Invoices invoice = invoicewrap.Invoices[0];
                    if(sendEmail && String.isNotBlank(msg)){
                        
                        XeroHttpCallout.CalloutWrapper callObj1 = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Invoices/'+msg+'/Email', headerMap, 'POST', '');
                        logList.add(callObj1.exc);
                              
                    }
                    List<KTXero__Invoice__c> invList = new List<KTXero__Invoice__c>();
                    Invoice__c inv = new Invoice__c();
                    inv.Name = invoice.InvoiceNumber;
                    if(String.isNotBlank(opp.accountId)){
                        inv.Account__c = opp.accountId;
                    }
                    inv.Branding_Theme_Id__c = invoice.BrandingThemeID;
                    inv.Xero_Contact__c = xc.Id;
                    inv.Opportunity__c = invFlow.oppId;
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
                    invList.add(inv);
                    // Insert invoice
                    System.debug('invList-->'+invList);
                    FLSChecker.FLSCheckWrapper flsWrap1 = FLSChecker.dmlInsert(invList);
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

                        for(Integer i=0;i<lineItemsList.size();i++){
                            Invoice_Line_Item__c l = new Invoice_Line_Item__c();
                            l.Name = 'LineItem-'+(i+1)+' | '+invoice.InvoiceNumber;
                            l.Account_Code__c = lineItemsList[i].AccountCode;
                            l.Description__c = lineItemsList[i].Description;
                            l.Discount_Rate__c = lineItemsList[i].DiscountRate;
                            l.Invoice__c = inv.Id;
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
                    }
                    msg = inv.Id;
                    System.debug('lineItemList-->'+lineItemList);
                    
                    if(lineItemList.size() > 0){

                        FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                        flsWrap = FLSChecker.dmlInsert(lineItemList);
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
        }catch(Exception e){
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            logList.add(logObj);
            if(logList.size() > 0 && Schema.sObjectType.KTXero__Log__c.isCreateable()){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    throw new CustomException(flsWrap.message);
                }
            }
        }
    }
}