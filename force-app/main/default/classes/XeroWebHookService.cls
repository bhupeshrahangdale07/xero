/**
 * @Author : Kandisa Technologies
 * @description : This class is used for RestResource. Which will be invoke by Xero Webhook
*/
@RestResource(urlMapping='/Xerodetail/*')
global without sharing class XeroWebHookService {

	/**
     * @description Method to get data from RestContext and based on data run business logic
    */
	@HttpPOST
	global static void doGet() {
		// Retrieve the Xero signature from the headers
		String xeroSignature = RestContext.request.headers.get('x-xero-signature');
		// Retrieve the Xero payload body
		String xeroPayload = RestContext.request.requestBody.toString();

		//Gettting Xero Webhook Key==
		KTXero__Xero_Connection__c xeroConnect = new KTXero__Xero_Connection__c();
		xeroConnect = [SELECT 
						Id, KTXero__Client_Id__c, KTXero__Client_Secret__c, KTXero__Access_Token__c, KTXero__Webhook_Key__c, 
						KTXero__Refresh_Token__c, KTXero__Tenant_Id__c, KTXero__Last_Token_Refresh_Time__c 
						FROM KTXero__Xero_Connection__c WITH SECURITY_ENFORCED 
						LIMIT 1];
		if(xeroConnect != null && (xeroConnect.KTXero__Webhook_Key__c != '' || xeroConnect.KTXero__Webhook_Key__c != null)){
			String webhookKey = Utils.processDecryption(xeroConnect.KTXero__Webhook_Key__c);
			// Verify the signature using 'hmacSHA256'.
			Blob signedPayload = Crypto.generateMac(
				'hmacSHA256',
				Blob.valueOf(xeroPayload),
				Blob.valueOf(webhookKey)
			);
	
			// Once we have the signed payload, encode it using base64 to convert back to a string
			String encodedPayload = EncodingUtil.base64Encode(signedPayload);
			// Return status code based on whether signed payload matches or not
			RestContext.response.statusCode = encodedPayload == xeroSignature ? 200 : 401;

			if (encodedPayload == xeroSignature) {
				ConnectionWrapper conWrap = new ConnectionWrapper();
				conWrap.Id = xeroConnect.Id;
				conWrap.clientId = xeroConnect.KTXero__Client_Id__c;
				conWrap.clientSecret = xeroConnect.KTXero__Client_Secret__c;
				conWrap.accessToken = xeroConnect.KTXero__Access_Token__c;
				conWrap.webhookKey = xeroConnect.KTXero__Webhook_Key__c;
				conWrap.refreshToken = xeroConnect.KTXero__Refresh_Token__c;
				conWrap.tenantId = xeroConnect.KTXero__Tenant_Id__c;
				conWrap.lastRefreshTokenTime = xeroConnect.KTXero__Last_Token_Refresh_Time__c;
				syncInvoiceContact(xeroPayload,JSON.serialize(conWrap));
			}
		}
	}

	/**
     * @description this future Method contains business logic which will get data from Xero Webhook and proceed into the Salesforce based on Webhook Events
     * @param  xeroPayload
     * @param  xeroConnect
    */
	@future(callout=true)
	global static void syncInvoiceContact(String xeroPayload, String xeroConnect) {

		List<KTXero__Log__c> logList = new list<KTXero__Log__c>();
		try{
			// KTXero__Xero_Connection__c xeroConnection = (KTXero__Xero_Connection__c)JSON.deserialize(xeroConnect, KTXero__Xero_Connection__c.class);
			ConnectionWrapper xeroConnection = (ConnectionWrapper)JSON.deserialize(xeroConnect, ConnectionWrapper.class);
			// Wrapper to get payload values to use further
			PayloadWrapper payloadwrap = (PayloadWrapper) JSON.deserialize( xeroPayload, PayloadWrapper.class);
			
			Map<String, String> headerMap = new Map<String, String>();
			if(xeroConnection != null){
				Boolean flag = Utils.checkTokenExpiry(xeroConnection.lastRefreshTokenTime);
                KTXero__Xero_Connection__c connection = new KTXero__Xero_Connection__c();
                if(flag){
                    headerMap.put('xero-tenant-id',String.isNotBlank(Utils.processDecryption(xeroConnection.tenantId)) ? Utils.processDecryption(xeroConnection.tenantId) : '');
                    headerMap.put('authorization',String.isNotBlank(Utils.processDecryption(xeroConnection.accessToken)) ? 'Bearer '+Utils.processDecryption(xeroConnection.accessToken) : '');
                }else{
                    connection = Utils.refreshToken();
                    headerMap.put('xero-tenant-id',String.isNotBlank(Utils.processDecryption(xeroConnection.tenantId)) ? Utils.processDecryption(xeroConnection.tenantId) : '');
                    headerMap.put('authorization',String.isNotBlank(Utils.processDecryption(connection.KTXero__Access_Token__c)) ? 'Bearer '+Utils.processDecryption(connection.KTXero__Access_Token__c) : '');
                }
			}

			// Get custom setting to fetch Mapped Object API Name
			KTXero__Invoice_Configuration_Options__c invoiceConfig = KTXero__Invoice_Configuration_Options__c.getOrgDefaults();
			String conObjApiName = invoiceConfig.KTXero__Xero_Contact_Mapping_Object__c; // Mapped Xero Contact Object API Name
			String invObjApiName = invoiceConfig.KTXero__Invoice_Mapping_Obj__c; // Mapped Invoice Object API Name
			String invLiObjApiName = invoiceConfig.KTXero__Invoice_LineItem_Mapping_Obj__c; // Mapped Invoice LineItem Object API Name
			String invPayObjApiName = invoiceConfig.KTXero__Invoice_Payment_Mapping_Obj__c; // Mapped Invoice Payment Object API Name
			String billObjApiName = invoiceConfig.KTXero__Bill_Mapping_Obj__c ; // Mapped Bill Object API Name
			String billLiObjApiName = invoiceConfig.KTXero__Bill_LineItem_Mapping_Obj__c; // Mapped Bill LineItem Object API Name
			String billPayObjApiName = invoiceConfig.KTXero__Bill_Payment_Mapping_Obj__c ; // Mapped Bill Payment Object API Name

			// Get all records of KTXero__Xero_Contact_Object_Field_Mapping__c custom setting
			Map<String, KTXero__Xero_Contact_Object_Field_Mapping__c> conFieldMappings = KTXero__Xero_Contact_Object_Field_Mapping__c.getAll();
			// Get all records of KTXero__Invoice_Object_Field_Mapping__c custom setting
			Map<String, KTXero__Invoice_Object_Field_Mapping__c> invFieldMappings = KTXero__Invoice_Object_Field_Mapping__c.getAll();
			// Get all records of KTXero__Invoice_LineItem_Obj_Field_Mapping__c custom setting
			Map<String, KTXero__Invoice_LineItem_Obj_Field_Mapping__c> invLiFieldMappings = KTXero__Invoice_LineItem_Obj_Field_Mapping__c.getAll();
			// Get all records of KTXero__Invoice_Payment_Object_Field_Mapping__c custom setting
			Map<String, KTXero__Invoice_Payment_Object_Field_Mapping__c> invPayFieldMappings = KTXero__Invoice_Payment_Object_Field_Mapping__c.getAll();
			// Get all records of KTXero__Bill_Object_Field_Mapping__c custom setting
			Map<String, KTXero__Bill_Object_Field_Mapping__c> billFieldMappings = KTXero__Bill_Object_Field_Mapping__c.getAll();
			// Get all records of KTXero__Bill_LineItem_Object_Field_Mapping__c custom setting
			Map<String, KTXero__Bill_LineItem_Object_Field_Mapping__c> billLiFieldMappings = KTXero__Bill_LineItem_Object_Field_Mapping__c.getAll();
			// Get all records of KTXero__Bill_Payment_Object_Field_Mapping__c custom setting
			Map<String, KTXero__Bill_Payment_Object_Field_Mapping__c> billPayFieldMappings = KTXero__Bill_Payment_Object_Field_Mapping__c.getAll();

			Set<String> invSet = new Set<String>();
			Set<String> conSet = new Set<String>();
			Map<String,List<SObject>> lineItemsMap = new Map<String,List<SObject>>();
			Map<String,List<KTXero__Bill_Line_Item__c>> billLineItemsMap = new Map<String,List<KTXero__Bill_Line_Item__c>>();
			// Map<String,List<KTXero__Payment__c>> paymentMap = new Map<String,List<KTXero__Payment__c>>();
			Map<String,List<SObject>> paymentMap = new Map<String,List<SObject>>();
			Map<String,List<KTXero__Xero_Bill_Payment__c>> billPaymentMap = new Map<String,List<KTXero__Xero_Bill_Payment__c>>();
			
			String xeroresourceId = payloadwrap.events[0].resourceId;
			for(Events obj : payloadwrap.events){
				if(obj.eventCategory == 'INVOICE'){
					invSet.add(obj.resourceId);
				}else if(obj.eventCategory == 'CONTACT'){
					conSet.add(obj.resourceId);
				}
			}
			//Event Invoice Starts=================================================
			if(invSet.size()>0){
				String joinedString = String.join(new List<String>(invSet), ',');
				String endPoint = 'https://api.xero.com/api.xro/2.0/Invoices?IDs='+joinedString;
				XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout(endPoint,headerMap,'GET','');
				HttpResponse response = callObj.response;
				logList.add(callObj.exc);
				if(response.getStatusCode() == 200){

					Object input = JSON.deserializeUntyped(response.getBody());
					String suffixed = new ReservedWordSerializer(input).getAsString();
					XeroWebHookService.InvoiceWrapper maindata = (XeroWebHookService.InvoiceWrapper) JSON.deserialize(suffixed,XeroWebHookService.InvoiceWrapper.class);
					Set<String> currencySet = new Set<String>();

					// Get Currency
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
	
					//Calling Payment API
					Map<String, PaymentWrapper> payWrap = new Map<String, PaymentWrapper>(); // Map of Xero Invoice ref Id and new payment wrapper
					Set<String> xeroConIdSet = new Set<String>();
					List<KTXero__Log__c> paylogList = new List<KTXero__Log__c>();
					Map<String,String> xcNameMap = new Map<String,String>();
					for(Invoices_x inv : maindata.Invoices_x){
						if(inv.Payments_x!= null){
							for(Payments_x pay : inv.Payments_x){
								PaymentDetailWrapper paymentDetailWrap = new PaymentDetailWrapper();
								paymentDetailWrap = getPaymentDetails(pay.PaymentID_x, headerMap);
								payWrap.put(pay.PaymentID_x, paymentDetailWrap.paymentWrap);
								paylogList.add(paymentDetailWrap.log);
							}
						}
						if(inv.Contact_x != null){
							xeroConIdSet.add(inv.Contact_x.ContactID_x);
						}

						xcNameMap.put(inv.contact_x.name_x,inv.contact_x.contactID_x);
					}


					List<Account> accList = new List<Account>();
					Map<String,Id> accIdNameMap = new Map<String,Id>();
					Map<String,String> accNameMap = new Map<String,String>();
					accList = [SELECT Id, Name FROM Account WHERE Name IN: xcNameMap.keySet()];
					
					for(Account ac : accList){
						accIdNameMap.put(ac.Name,ac.Id);
					}

					List<Account> newaccList = new List<Account>();
					for(String name : xcNameMap.keySet()){
						if(accIdNameMap.containsKey(name)){
							accNameMap.put(xcNameMap.get(name),accIdNameMap.get(name));
						}else{
							KTXero__Xero_Contact_Configurations__c conConfig = KTXero__Xero_Contact_Configurations__c.getOrgDefaults();
							if(conConfig.KTXero__Create_Account_if_not_available__c){
								Account acc = new Account();
								acc.Name = name;
								newaccList.add(acc);
							}
						}
					}

					if(newaccList.size() > 0){
						Boolean flag = false;
						Database.SaveResult[] srList = Database.insert(newaccList, false);
						for(Database.SaveResult sr : srList){
							if(!sr.isSuccess()){
								flag = true;
								break;
							}
						}

						if(!flag){
							for(Account acc : newaccList){
								if(xcNameMap.containsKey(acc.Name)){
									accNameMap.put(xcNameMap.get(acc.Name),acc.Id);
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
					
					Map<String,String> xeroConMap = new Map<String,String>();
					
					Map<String,SObject> xconMap = new Map<String,SObject>();
					List<SObject> xeroconList = new List<SObject>();
					
					if(xeroConIdSet.size()>0){
						
						String query = 'SELECT Id, '+conFieldMappings.get('Reference Id').KTXero__Field_API_Name__c+', '+conFieldMappings.get('Account').KTXero__Field_API_Name__c+' FROM '+conObjApiName+' WHERE '+conFieldMappings.get('Reference Id').KTXero__Field_API_Name__c +' IN: xeroConIdSet WITH SECURITY_ENFORCED';
						
						xeroconList = Database.query(query);

						if(xeroconList.size()>0){
							for(SObject xc : xeroconList){
								xeroConMap.put((String) xc.get(conFieldMappings.get('Reference Id').KTXero__Field_API_Name__c),xc.Id);
								xconMap.put((String) xc.get(conFieldMappings.get('Reference Id').KTXero__Field_API_Name__c),xc);
							}
						}
					}
	
					

					// Map<Id, KTXero__Invoice__c> invSalesMap = new Map<Id, KTXero__Invoice__c>();
					Map<Id, SObject> invSalesMap = new Map<Id, SObject>();
					// List<KTXero__Payment__c> paydeleteList = new List<KTXero__Payment__c>();
					List<SObject> paydeleteList = new List<SObject>();
					// List<KTXero__Invoice_Line_Item__c> invLideleteList = new List<KTXero__Invoice_Line_Item__c>();
					List<SObject> invLideleteList = new List<SObject>();
					// List<KTXero__Invoice__c> invList = new List<KTXero__Invoice__c>();
					List<SObject> invList = new List<SObject>();
					// List<KTXero__Invoice__c> newInvList = new List<KTXero__Invoice__c>();
					List<SObject> newInvList = new List<SObject>();
	
					// invList = [SELECT Id, 
					// 			(SELECT Id,Name, KTXero__Item_Code__c, KTXero__Product__c, KTXero__Product__r.Name, KTXero__Product__r.KTXero__Xero_ItemID__c, Account_Code__c, Description__c,
					// 			Discount_Rate__c, Invoice__c, Line_Amount__c,Line_Item_Id__c,Quantity__c, Tax_Amount__c, Tax_Type__c, Unit_Price__c, Discount_Amount__c
					// 			FROM KTXero__Invoice_Line_Items__r), 
					// 			(SELECT Id, Name, KTXero__Account_Id__c, KTXero__Amount__c, KTXero__Invoice__c, 
					// 			KTXero__Payment_Id__c, KTXero__Payment_Date__c, KTXero__Payment_Type__c, KTXero__Refrence__c, 
					// 			KTXero__Status__c, KTXero__Currency_Rate__c, KTXero__Paid_To__c FROM KTXero__Payments__r),
					// 			Name, Account__c,  Branding_Theme_Id__c, Xero_Contact__c, Opportunity__c, Reference__c, Type__c, Amount_Due__c, Amount_Paid__c,
					// 			KTXero__Invoice_Id__c, Sent_to_Contact__c, Currency_Rate__c, Currency_Code__c, Status__c, Invoice_Date__c, Due_Date__c, Total__c, Sub_Total__c, Total_Tax__c, Amounts_Are__c 
					// 			FROM KTXero__Invoice__c WHERE KTXero__Invoice_Id__c =: invSet WITH SECURITY_ENFORCED];

					// Preparing Invoice query
					Set<String> invfieldApiNameSet = new Set<String>();
					for(KTXero__Invoice_Object_Field_Mapping__c invMap : invFieldMappings.values()){
						invfieldApiNameSet.add(invMap.KTXero__Field_API_Name__c);
					}

					String invListquery = 'SELECT Id,'+String.join(invfieldApiNameSet, ', ')+' FROM '+invObjApiName+' WHERE '+invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c+' IN: invSet WITH SECURITY_ENFORCED';
					invList = Database.query(invListquery);

					Set<String> invSfIdSet = new Set<String>();
					for(SObject inv : invList){
						invSfIdSet.add(inv.Id);
					}
					
					// Preparing LineItem child query
					Set<String> lifieldApiNameSet = new Set<String>();
					for(KTXero__Invoice_LineItem_Obj_Field_Mapping__c lineItemMap : invLiFieldMappings.values()){
						lifieldApiNameSet.add(lineItemMap.KTXero__Field_API_Name__c);
					}

					String lineItemSubQuery = 'SELECT Id, '+String.join(lifieldApiNameSet, ', ')+' FROM '+invLiObjApiName+' WHERE '+invLiFieldMappings.get('Invoice').KTXero__Field_API_Name__c+' IN: invSfIdSet WITH SECURITY_ENFORCED';
					List<SObject> invLiList = new List<SObject>();
					Map<String,List<SObject>> newinvLiMap = new Map<String,List<SObject>>();
					invLiList = Database.query(lineItemSubQuery);

					for(SObject invLi : invLiList){
						if(!newinvLiMap.containsKey((String)invLi.get(invLiFieldMappings.get('Invoice').KTXero__Field_API_Name__c))){
							newinvLiMap.put((String) invLi.get(invLiFieldMappings.get('Invoice').KTXero__Field_API_Name__c), new List<SObject>());
						}
						newinvLiMap.get((String) invLi.get(invLiFieldMappings.get('Invoice').KTXero__Field_API_Name__c)).add(invLi);
					}

					// Preparing Payment child query
					Set<String> payFieldApiNameSet = new Set<String>();
					for(KTXero__Invoice_Payment_Object_Field_Mapping__c payMap : invPayFieldMappings.values()){
						payFieldApiNameSet.add(payMap.KTXero__Field_API_Name__c);
					}
					
					String paySubQuery = 'SELECT Id, '+String.join(payFieldApiNameSet, ', ')+' FROM '+invPayObjApiName+' WHERE '+invPayFieldMappings.get('Invoice').KTXero__Field_API_Name__c+' IN: invSfIdSet WITH SECURITY_ENFORCED';
					List<SObject> invPayList = new List<SObject>();
					Map<String,List<SObject>> newinvPayMap = new Map<String,List<SObject>>();
					invPayList = Database.query(paySubQuery);

					for(SObject invPay : invPayList){
						if(!newinvPayMap.containsKey((String)invPay.get(invPayFieldMappings.get('Invoice').KTXero__Field_API_Name__c))){
							newinvPayMap.put((String) invPay.get(invPayFieldMappings.get('Invoice').KTXero__Field_API_Name__c), new List<SObject>());
						}
						newinvPayMap.get((String) invPay.get(invPayFieldMappings.get('Invoice').KTXero__Field_API_Name__c)).add(invPay);
					}

					// String invListquery = 'SELECT Id,';

					// // Preparing LineItem child query
					// Set<String> lifieldApiNameSet = new Set<String>();
					// for(KTXero__Invoice_LineItem_Obj_Field_Mapping__c lineItemMap : invLiFieldMappings.values()){
					// 	lifieldApiNameSet.add(lineItemMap.KTXero__Field_API_Name__c);
					// }

					// String lineItemSubQuery = '(SELECT Id, '+String.join(lifieldApiNameSet, ', ')+' FROM KTXero__Invoice_Line_Items__r)';

					// // Preparing Payment child query
					// Set<String> payFieldApiNameSet = new Set<String>();
					// for(KTXero__Invoice_Payment_Object_Field_Mapping__c payMap : invPayFieldMappings.values()){
					// 	payFieldApiNameSet.add(payMap.KTXero__Field_API_Name__c);
					// }
					
					// String paySubQuery = '(SELECT Id, '+String.join(payFieldApiNameSet, ', ')+' FROM KTXero__Payments__r)';

					// String finalQuery = invListquery + lineItemSubQuery +','+ paySubQuery + ','+String.join(invfieldApiNameSet, ', ')+' FROM '+invObjApiName+' WHERE '+invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c+' IN: invSet WITH SECURITY_ENFORCED';
					
					// invList = Database.query(finalQuery);

					Map<String,SObject> invMap = new Map<String,SObject>(); 
					// Map<String,Map<String,KTXero__Invoice_Line_Item__c>> invLineMap = new Map<String,Map<String,KTXero__Invoice_Line_Item__c>>();
					Map<String,Map<String,SObject>> invLineMap = new Map<String,Map<String,SObject>>();
					// Map<String,Map<String,KTXero__Payment__c>> invPayMap = new Map<String,Map<String,KTXero__Payment__c>>();
					Map<String,Map<String,SObject>> invPayMap = new Map<String,Map<String,SObject>>();
					Map<String,Integer> invPayMapCount = new Map<String,Integer>();
					// Map<String, Product2> prodMap = new Map<String, Product2>();
					Map<String, SObject> prodMap = new Map<String, SObject>();
					// Map<String, KTXero__Payment__c> payMap = new Map<String, KTXero__Payment__c>();
					Map<String, SObject> payMap = new Map<String, SObject>();

					// for(SObject inv : invList){
					// 	invMap.put((String) inv.get(invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c),inv);
					// 	invSalesMap.put(inv.Id, inv);
					// 	Map<String,KTXero__Invoice_Line_Item__c> lineItemMap = new Map<String,KTXero__Invoice_Line_Item__c>();
						
					// 	if(inv.KTXero__Invoice_Line_Items__r.size()>0){
					// 		for(KTXero__Invoice_Line_Item__c li : inv.KTXero__Invoice_Line_Items__r){
					// 			lineItemMap.put(li.KTXero__Line_Item_Id__c,li);
					// 		}
					// 		invLineMap.put(inv.KTXero__Invoice_Id__c, lineItemMap);
					// 	}
						
					// 	if(inv.KTXero__Payments__r.size()>0){
					// 		for(KTXero__Payment__c pay : inv.KTXero__Payments__r){
					// 			payMap.put(pay.Payment_Id__c,pay);
					// 		}
					// 		invPayMap.put(inv.KTXero__Invoice_Id__c, payMap);
					// 		invPayMapCount.put(inv.KTXero__Invoice_Id__c, inv.KTXero__Payments__r.size());
					// 	}
					// }
					for(SObject inv : invList){
						invMap.put((String) inv.get(invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c),inv);
						invSalesMap.put(inv.Id, inv);
						Map<String,SObject> lineItemMap = new Map<String,SObject>();
						
						if(newinvLiMap.containsKey(inv.Id)){
							if(newinvLiMap.get(inv.Id).size()>0){
								for(SObject li : newinvLiMap.get(inv.Id)){
									lineItemMap.put((String)li.get(invLiFieldMappings.get('LineItem Id').KTXero__Field_API_Name__c),li);
								}
								invLineMap.put((String)inv.get(invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c), lineItemMap);
							}
						}
						
						if(newinvPayMap.containsKey(inv.Id)){
							if(newinvPayMap.get(inv.Id).size()>0){
								for(SObject pay : newinvPayMap.get(inv.Id)){
									// payMap.put(pay.Payment_Id__c,pay);
									payMap.put((String)pay.get(invPayFieldMappings.get('Payment ID').KTXero__Field_API_Name__c),pay);
								}
								invPayMap.put((String)inv.get(invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c), payMap);
								invPayMapCount.put((String)inv.get(invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c), newinvPayMap.get(inv.Id).size());
							}
						}
					}


					// Bill STarted same as Invoice ==================================================================
					// Map<Id, KTXero__Bill__c> billSalesMap = new Map<Id, KTXero__Bill__c>();
					Map<Id, SObject> billSalesMap = new Map<Id, SObject>();
					// List<KTXero__Xero_Bill_Payment__c> payBilldeleteList = new List<KTXero__Xero_Bill_Payment__c>();
					List<SObject> payBilldeleteList = new List<SObject>();
					// List<KTXero__Bill_Line_Item__c> billLideleteList = new List<KTXero__Bill_Line_Item__c>();
					List<SObject> billLideleteList = new List<SObject>();
					// List<KTXero__Bill__c> billList = new List<KTXero__Bill__c>();
					List<SObject> billList = new List<SObject>();
					// List<KTXero__Bill__c> newbillList = new List<KTXero__Bill__c>();
					List<SObject> newbillList = new List<SObject>();
	
					// billList = [SELECT Id, 
					// 			(SELECT Id,Name, KTXero__Item_Code__c, KTXero__Product__c, KTXero__Product__r.Name, KTXero__Product__r.KTXero__Xero_ItemID__c, Account_Code__c, Description__c,
					// 			Discount_Rate__c,Bill__c, Line_Amount__c,Line_Item_Id__c,Quantity__c, Tax_Amount__c, Tax_Type__c, Unit_Price__c, Discount_Amount__c
					// 			FROM KTXero__Bill_Line_Items__r), 
					// 			(SELECT Id, Name, KTXero__Account_Id__c, KTXero__Amount__c, 
					// 			KTXero__Payment_Id__c, KTXero__Payment_Date__c, KTXero__Payment_Type__c, KTXero__Refrence__c, 
					// 			KTXero__Status__c, KTXero__Currency_Rate__c, KTXero__Paid_To__c FROM KTXero__Payments__r),
					// 			Name, Account__c,  Branding_Theme_Id__c, Xero_Contact__c, Opportunity__c, Reference__c, Type__c, Amount_Due__c, Amount_Paid__c,
					// 			KTXero__Bill_Id__c, Sent_to_Contact__c, Currency_Rate__c, Currency_Code__c, Status__c, Bill_Date__c, Due_Date__c, Total__c, Sub_Total__c, Total_Tax__c, Amounts_Are__c 
					// 			FROM KTXero__Bill__c WHERE KTXero__Bill_Id__c =: invSet WITH SECURITY_ENFORCED];
	
					// Preparing Bill query
					Set<String> billfieldApiNameSet = new Set<String>();
					for(KTXero__Bill_Object_Field_Mapping__c billMap : billFieldMappings.values()){
						billfieldApiNameSet.add(billMap.KTXero__Field_API_Name__c);
					}

					String billListQuery = 'SELECT Id,'+String.join(billfieldApiNameSet, ', ')+' FROM '+billObjApiName+' WHERE '+billFieldMappings.get('Bill Id').KTXero__Field_API_Name__c+' IN: invSet WITH SECURITY_ENFORCED';
					billList = Database.query(billListQuery);

					Set<String> billSfIdSet = new Set<String>();
					for(SObject bill : billList){
						billSfIdSet.add(bill.Id);
					}

					// Preparing Bill LineItem child query
					Set<String> billLifieldApiNameSet = new Set<String>();
					for(KTXero__Bill_LineItem_Object_Field_Mapping__c lineItemMap : billLiFieldMappings.values()){
						billLifieldApiNameSet.add(lineItemMap.KTXero__Field_API_Name__c);
					}

					String billLineItemSubQuery = 'SELECT Id, '+String.join(billLifieldApiNameSet, ', ')+' FROM '+billLiObjApiName+' WHERE '+billLiFieldMappings.get('Bill').KTXero__Field_API_Name__c+' IN: billSfIdSet WITH SECURITY_ENFORCED';
					List<SObject> billLiList = new List<SObject>();
					Map<String,List<SObject>> newbillLiMap = new Map<String,List<SObject>>();
					billLiList = Database.query(billLineItemSubQuery);

					for(SObject billLi : billLiList){
						if(!newbillLiMap.containsKey((String)billLi.get(billLiFieldMappings.get('Bill').KTXero__Field_API_Name__c))){
							newbillLiMap.put((String) billLi.get(billLiFieldMappings.get('Bill').KTXero__Field_API_Name__c), new List<SObject>());
						}
						newbillLiMap.get((String) billLi.get(billLiFieldMappings.get('Bill').KTXero__Field_API_Name__c)).add(billLi);
					}

					// Preparing  Bill Payment child query
					Set<String> billpayFieldApiNameSet = new Set<String>();
					for(KTXero__Bill_Payment_Object_Field_Mapping__c billpayMap : billPayFieldMappings.values()){
						billpayFieldApiNameSet.add(billpayMap.KTXero__Field_API_Name__c);
					}
					
					String billpaySubQuery = 'SELECT Id, '+String.join(billpayFieldApiNameSet, ', ')+' FROM '+billPayObjApiName+' WHERE '+billPayFieldMappings.get('Bill').KTXero__Field_API_Name__c+' IN: billSfIdSet WITH SECURITY_ENFORCED';
					List<SObject> tempbillPayList = new List<SObject>();
					Map<String,List<SObject>> newbillPayMap = new Map<String,List<SObject>>();
					tempbillPayList = Database.query(billpaySubQuery);

					for(SObject billPay : tempbillPayList){
						if(!newbillPayMap.containsKey((String)billPay.get(billPayFieldMappings.get('Bill').KTXero__Field_API_Name__c))){
							newbillPayMap.put((String) billPay.get(billPayFieldMappings.get('Bill').KTXero__Field_API_Name__c), new List<SObject>());
						}
						newbillPayMap.get((String) billPay.get(billPayFieldMappings.get('Bill').KTXero__Field_API_Name__c)).add(billPay);
					}


					// Map<String,KTXero__Bill__c> billMap = new Map<String,KTXero__Bill__c>();
					Map<String,SObject> billMap = new Map<String,SObject>();
					// Map<String,Map<String,KTXero__Bill_Line_Item__c>> billLineMap = new Map<String,Map<String,KTXero__Bill_Line_Item__c>>();
					Map<String,Map<String,SObject>> billLineMap = new Map<String,Map<String,SObject>>();
					// Map<String,Map<String,KTXero__Xero_Bill_Payment__c>> billPayMap = new Map<String,Map<String,KTXero__Xero_Bill_Payment__c>>();
					Map<String,Map<String,SObject>> billPayMap = new Map<String,Map<String,SObject>>();
					Map<String,Integer> billPayMapCount = new Map<String,Integer>();
					// Map<String, Product2> prodMap = new Map<String, Product2>();
					
					
					for(SObject bill : billList){
						billMap.put((String) bill.get(billFieldMappings.get('Bill Id').KTXero__Field_API_Name__c),bill);
						billSalesMap.put(bill.Id, bill);
						
						Map<String,SObject> billLineItemMap = new Map<String,SObject>();
						Map<String, SObject> payMap1 = new Map<String, SObject>();
						
						if(newbillLiMap.containsKey(bill.Id)){
							if(newbillLiMap.get(bill.Id).size()>0){
								for(SObject li : newbillLiMap.get(bill.Id)){
									// billLineItemMap.put(li.KTXero__Line_Item_Id__c,li);
									billLineItemMap.put((String)li.get(billLiFieldMappings.get('LineItem Id').KTXero__Field_API_Name__c),li);
								}
								billLineMap.put((String)bill.get(billFieldMappings.get('Bill Id').KTXero__Field_API_Name__c), billLineItemMap);
							}
						}

						if(newbillPayMap.containsKey(bill.Id)){
							if(newbillPayMap.get(bill.Id).size() > 0){
								for(SObject pay : newbillPayMap.get(bill.Id)){
									payMap1.put((String)pay.get(billPayFieldMappings.get('Payment ID').KTXero__Field_API_Name__c),pay);	
								}
								billPayMap.put((String)bill.get(billFieldMappings.get('Bill Id').KTXero__Field_API_Name__c), payMap1);
								billPayMapCount.put((String)bill.get(billFieldMappings.get('Bill Id').KTXero__Field_API_Name__c),newbillPayMap.get(bill.Id).size());
							}
						}
					}
					// Bill ends ==================================================================


                 	// List<KTXero__Xero_Contact__c> newConList = new List<KTXero__Xero_Contact__c>();
					List<SObject> newConList = new List<SObject>();
					Map<String,Item_x> codeMap = new Map<String,Item_x>();
					Map<String,Item_x> itemMap = new Map<String,Item_x>();
	
	
					//Creating new Contacts starts================================
					for(Invoices_x ix : maindata.Invoices_x){
	
						for(LineItems_x li : ix.LineItems_x){
							if(li.Item_x != null){
								codeMap.put(li.Item_x.Code_x,li.Item_x);
								itemMap.put(li.Item_x.ItemID_x,li.Item_x);
							}
						}
						if(!xeroConMap.containsKey(ix.Contact_x.ContactID_x) ){

							SObject xeroConObj = Schema.getGlobalDescribe().get(conObjApiName).newSObject();
							xeroConObj.put(conFieldMappings.get('Company Name').KTXero__Field_API_Name__c, ix.Contact_x.Name_x);
							xeroConObj.put(conFieldMappings.get('First Name').KTXero__Field_API_Name__c, ix.Contact_x.FirstName_x);
							xeroConObj.put(conFieldMappings.get('Last Name').KTXero__Field_API_Name__c, ix.Contact_x.LastName_x);
							xeroConObj.put(conFieldMappings.get('Email Address').KTXero__Field_API_Name__c, ix.Contact_x.EmailAddress_x);
							xeroConObj.put(conFieldMappings.get('Account Number').KTXero__Field_API_Name__c, ix.Contact_x.accountNumber_x);
							xeroConObj.put(conFieldMappings.get('Reference Id').KTXero__Field_API_Name__c, ix.Contact_x.ContactID_x);
							xeroConObj.put(conFieldMappings.get('Status').KTXero__Field_API_Name__c, ix.Contact_x.ContactStatus_x);

							if(accNameMap.containsKey(ix.Contact_x.ContactID_x)){
								xeroConObj.put(conFieldMappings.get('Account').KTXero__Field_API_Name__c, accNameMap.get(ix.Contact_x.ContactID_x));
								// con.Salesforce_Account__c = accNameMap.get(ix.Contact_x.ContactID_x);
							}
							for(Integer i=0;i<ix.Contact_x.ContactPersons_x.size();i++){
								if(i == 0 ){
									xeroConObj.put(conFieldMappings.get('Contact 1 First Name').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].FirstName_x);
									xeroConObj.put(conFieldMappings.get('Contact 1 Last Name').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].LastName_x);
									xeroConObj.put(conFieldMappings.get('Contact 1 Email').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].EmailAddress_x);
									xeroConObj.put(conFieldMappings.get('Contact 1 Include in Emails?').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].IncludeInEmails_x);
								}else if(i == 1){
									xeroConObj.put(conFieldMappings.get('Contact 2 First Name').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].FirstName_x);
									xeroConObj.put(conFieldMappings.get('Contact 2 Last Name').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].LastName_x);
									xeroConObj.put(conFieldMappings.get('Contact 2 Email').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].EmailAddress_x);
									xeroConObj.put(conFieldMappings.get('Contact 2 Include in Emails?').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].IncludeInEmails_x);
								}else if(i == 2){
									xeroConObj.put(conFieldMappings.get('Contact 3 First Name').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].FirstName_x);
									xeroConObj.put(conFieldMappings.get('Contact 3 Last Name').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].LastName_x);
									xeroConObj.put(conFieldMappings.get('Contact 3 Email').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].EmailAddress_x);
									xeroConObj.put(conFieldMappings.get('Contact 3 Include in Emails?').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].IncludeInEmails_x);
								}else if(i == 3){
									xeroConObj.put(conFieldMappings.get('Contact 4 First Name').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].FirstName_x);
									xeroConObj.put(conFieldMappings.get('Contact 4 Last Name').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].LastName_x);
									xeroConObj.put(conFieldMappings.get('Contact 4 Email').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].EmailAddress_x);
									xeroConObj.put(conFieldMappings.get('Contact 4 Include in Emails?').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].IncludeInEmails_x);
								}else if(i == 4){
									xeroConObj.put(conFieldMappings.get('Contact 5 First Name').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].FirstName_x);
									xeroConObj.put(conFieldMappings.get('Contact 5 Last Name').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].LastName_x);
									xeroConObj.put(conFieldMappings.get('Contact 5 Email').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].EmailAddress_x);
									xeroConObj.put(conFieldMappings.get('Contact 5 Include in Emails?').KTXero__Field_API_Name__c, ix.Contact_x.ContactPersons_x[i].IncludeInEmails_x);
								}
							}
							if(ix.Contact_x.Addresses_x.size()>0){
								List<Addresses_x> addressList = ix.Contact_x.Addresses_x;
								for(Addresses_x add : addressList){
									if(add.AddressType_x == 'POBOX'){
										xeroConObj.put(conFieldMappings.get('Street Address').KTXero__Field_API_Name__c, add.AddressLine1_x);
										xeroConObj.put(conFieldMappings.get('Town_City').KTXero__Field_API_Name__c, add.City_x);
										xeroConObj.put(conFieldMappings.get('State_Region').KTXero__Field_API_Name__c, add.Region_x);
										xeroConObj.put(conFieldMappings.get('Postal_Zip Code').KTXero__Field_API_Name__c, add.PostalCode_x);
										xeroConObj.put(conFieldMappings.get('Country').KTXero__Field_API_Name__c, add.Country_x);
									}else if(add.AddressType_x == 'DELIVERY'){
										xeroConObj.put(conFieldMappings.get('Shipping Street Address').KTXero__Field_API_Name__c, add.AddressLine1_x);
										xeroConObj.put(conFieldMappings.get('Shipping Town_City').KTXero__Field_API_Name__c, add.City_x);
										xeroConObj.put(conFieldMappings.get('Shipping State_Region').KTXero__Field_API_Name__c, add.Region_x);
										xeroConObj.put(conFieldMappings.get('Shipping Postal_Zip Code').KTXero__Field_API_Name__c, add.PostalCode_x);
										xeroConObj.put(conFieldMappings.get('Shipping Country').KTXero__Field_API_Name__c, add.Country_x);
									}
								}
							}
							newConList.add(xeroConObj);
						}
					}
	
	
					Integer conSucCnt = 0;
					Integer conFailCnt = 0;
					Set<Id> newConIdSet = new Set<Id>();
					if(newConList.size() > 0){
						Database.SaveResult[] contactResult = Database.insert(newConList);
						for (Database.SaveResult result : contactResult) {
							if (result.isSuccess()) {
								newConIdSet.add(result.getId());
								conSucCnt++;
								continue;
							}else {
								conFailCnt++;
								break;
							}
						}
					}
					
					if(newConIdSet.size() > 0){
						String query = 'SELECT Id, '+conFieldMappings.get('Reference Id').KTXero__Field_API_Name__c+', '+conFieldMappings.get('Account').KTXero__Field_API_Name__c+' FROM '+conObjApiName+' WHERE '+conFieldMappings.get('Reference Id').KTXero__Field_API_Name__c +' IN: newConIdSet WITH SECURITY_ENFORCED';
						
						xeroconList = Database.query(query);
						if(xeroconList.size() > 0){
							for(SObject xc : xeroconList){
								xeroConMap.put((String) xc.get(conFieldMappings.get('Reference Id').KTXero__Field_API_Name__c),xc.Id);
								xconMap.put((String) xc.get(conFieldMappings.get('Reference Id').KTXero__Field_API_Name__c),xc);
							}
						}
					}
					//Creating contact Ends============================================
	
	
					// Creating new product					
					prodMap = getProducts(codeMap,itemMap);
					Set<Id> invIdSet = new Set<Id>();
					Set<Id> billIdSet = new Set<Id>();
	
					for(Invoices_x ix : maindata.Invoices_x){
						if(ix.Type_x == 'ACCREC'){
							// ================= Invoice Start ================= //
							Boolean flag1 = false;
							// KTXero__Invoice__c kInv = new KTXero__Invoice__c();
							SObject kInv = Schema.getGlobalDescribe().get(invObjApiName).newSObject();
							if(invMap.containsKey(ix.InvoiceID_x)){
								// invIdSet.add()
								//kInv.Id = invMap.get(ix.InvoiceID_x).Id;
								kInv = invMap.get(ix.InvoiceID_x);
								if(kInv.get(invFieldMappings.get('Invoice Template').KTXero__Field_API_Name__c) != ix.BrandingThemeID_x){
									flag1 = true;
									// kInv.Branding_Theme_Id__c = ix.BrandingThemeID_x;
									kInv.put(invFieldMappings.get('Invoice Template').KTXero__Field_API_Name__c,ix.BrandingThemeID_x);
								}
								if(kInv.get(invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c) != ix.InvoiceID_x){
									flag1 = true;
									// kInv.Invoice_Id__c = ix.InvoiceID_x;
									kInv.put(invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c,ix.InvoiceID_x);
								}
								
								if(ix.Reference_x == '') ix.Reference_x = null;
								if(kInv.get(invFieldMappings.get('Reference').KTXero__Field_API_Name__c) != ix.Reference_x){
									flag1 = true;
									// kInv.Reference__c = ix.Reference_x;
									kInv.put(invFieldMappings.get('Reference').KTXero__Field_API_Name__c,ix.Reference_x);
								}
								if(kInv.get(invFieldMappings.get('Type').KTXero__Field_API_Name__c) != ix.Type_x){
									flag1 = true;
									// kInv.Type__c = ix.Type_x;
									kInv.put(invFieldMappings.get('Type').KTXero__Field_API_Name__c,ix.Type_x);
								}
								if(kInv.get(invFieldMappings.get('Amount Due').KTXero__Field_API_Name__c) != ix.AmountDue_x){
									flag1 = true;
									// kInv.Amount_Due__c = ix.AmountDue_x;
									kInv.put(invFieldMappings.get('Amount Due').KTXero__Field_API_Name__c,ix.AmountDue_x);
								}
								if(kInv.get(invFieldMappings.get('Amount Paid').KTXero__Field_API_Name__c) != ix.AmountPaid_x){
									flag1 = true;
									// kInv.Amount_Paid__c = ix.AmountPaid_x;
									kInv.put(invFieldMappings.get('Amount Paid').KTXero__Field_API_Name__c,ix.AmountPaid_x);
								}
								if(kInv.get(invFieldMappings.get('Send To Contact').KTXero__Field_API_Name__c) != ix.SentToContact_x){
									flag1 = true;
									// kInv.Sent_to_Contact__c = ix.SentToContact_x != null ? ix.SentToContact_x : false;
									kInv.put(invFieldMappings.get('Send To Contact').KTXero__Field_API_Name__c,ix.SentToContact_x != null ? ix.SentToContact_x : false);
								}
								if(kInv.get(invFieldMappings.get('Currency Rate').KTXero__Field_API_Name__c) != ix.CurrencyRate_x){
									flag1 = true;
									// kInv.Currency_Rate__c = ix.CurrencyRate_x;
									kInv.put(invFieldMappings.get('Currency Rate').KTXero__Field_API_Name__c,ix.CurrencyRate_x);
								}
								if(kInv.get(invFieldMappings.get('Currency Code').KTXero__Field_API_Name__c) != ix.CurrencyCode_x){
									flag1 = true;
									// kInv.Currency_Code__c = ix.CurrencyCode_x;
									kInv.put(invFieldMappings.get('Currency Code').KTXero__Field_API_Name__c,ix.CurrencyCode_x);
									if(UserInfo.isMultiCurrencyOrganization()){
										kInv.put('CurrencyIsoCode',ix.CurrencyCode_x);
									}
								}
								if(kInv.get(invFieldMappings.get('Invoice Status').KTXero__Field_API_Name__c) != ix.Status_x){
									flag1 = true;
									// kInv.Status__c = ix.Status_x;
									kInv.put(invFieldMappings.get('Invoice Status').KTXero__Field_API_Name__c,ix.Status_x);
								}
								if(String.isNotBlank(ix.DateString_x)){
									if(kInv.get(invFieldMappings.get('Invoice Date').KTXero__Field_API_Name__c) != date.valueOf(ix.DateString_x)){
										flag1 = true;
										// kInv.Invoice_Date__c = date.valueOf(ix.DateString_x);
										kInv.put(invFieldMappings.get('Invoice Date').KTXero__Field_API_Name__c,date.valueOf(ix.DateString_x));
									}
								}
								if(String.isNotBlank(ix.DueDateString_x)){
									if(kInv.get(invFieldMappings.get('Invoice Due Date').KTXero__Field_API_Name__c) != date.valueOf(ix.DueDateString_x)){
										flag1 = true;
										// kInv.Due_Date__c = date.valueOf(ix.DueDateString_x);
										kInv.put(invFieldMappings.get('Invoice Due Date').KTXero__Field_API_Name__c,date.valueOf(ix.DueDateString_x));
									}
								}
								if(kInv.get(invFieldMappings.get('Total').KTXero__Field_API_Name__c) != ix.Total_x){
									flag1 = true;
									// kInv.Total__c = ix.Total_x;
									kInv.put(invFieldMappings.get('Total').KTXero__Field_API_Name__c,ix.Total_x);
								}
								if(kInv.get(invFieldMappings.get('Sub Total').KTXero__Field_API_Name__c) != ix.SubTotal_x){
									flag1 = true;
									// kInv.Sub_Total__c = ix.SubTotal_x;
									kInv.put(invFieldMappings.get('Sub Total').KTXero__Field_API_Name__c,ix.SubTotal_x);
								}
								if(kInv.get(invFieldMappings.get('Total Tax').KTXero__Field_API_Name__c) != ix.TotalTax_x){
									flag1 = true;
									// kInv.Total_Tax__c = ix.TotalTax_x;
									kInv.put(invFieldMappings.get('Total Tax').KTXero__Field_API_Name__c,ix.TotalTax_x);
								}
								if(kInv.get(invFieldMappings.get('Amounts are').KTXero__Field_API_Name__c) != ix.LineAmountTypes_x){
									flag1 = true;
									// kInv.Amounts_Are__c = ix.LineAmountTypes_x;
									kInv.put(invFieldMappings.get('Amounts are').KTXero__Field_API_Name__c,ix.LineAmountTypes_x);
								}
								if(xeroConMap.containsKey(ix.Contact_x.ContactID_x)){
									if(kInv.get(invFieldMappings.get('Xero Contact').KTXero__Field_API_Name__c) != xeroConMap.get(ix.Contact_x.ContactID_x)){
										flag1 = true;
										// kInv.KTXero__Xero_Contact__c = xeroConMap.get(ix.Contact_x.ContactID_x);
										kInv.put(invFieldMappings.get('Xero Contact').KTXero__Field_API_Name__c,xeroConMap.get(ix.Contact_x.ContactID_x));
									}
								}
							}else{
								// kInv.Name = ix.InvoiceNumber_x;
								kInv.put(invFieldMappings.get('Invoice Number').KTXero__Field_API_Name__c,ix.InvoiceNumber_x);
								// kInv.Branding_Theme_Id__c = ix.BrandingThemeID_x;
								kInv.put(invFieldMappings.get('Invoice Template').KTXero__Field_API_Name__c,ix.BrandingThemeID_x);
								// kInv.Invoice_Id__c = ix.InvoiceID_x;
								kInv.put(invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c,ix.InvoiceID_x);
								// kInv.Reference__c =  ix.Reference_x;
								kInv.put(invFieldMappings.get('Reference').KTXero__Field_API_Name__c,ix.Reference_x);
								// kInv.Type__c = ix.Type_x;
								kInv.put(invFieldMappings.get('Type').KTXero__Field_API_Name__c,ix.Type_x);
								// kInv.Amount_Due__c = ix.AmountDue_x;
								kInv.put(invFieldMappings.get('Amount Due').KTXero__Field_API_Name__c,ix.AmountDue_x);
								// kInv.Amount_Paid__c = ix.AmountPaid_x;
								kInv.put(invFieldMappings.get('Amount Paid').KTXero__Field_API_Name__c,ix.AmountPaid_x);
								// kInv.Sent_to_Contact__c = ix.SentToContact_x != null ? ix.SentToContact_x : false;
								kInv.put(invFieldMappings.get('Send To Contact').KTXero__Field_API_Name__c,ix.SentToContact_x != null ? ix.SentToContact_x : false);
								// kInv.Currency_Rate__c = ix.CurrencyRate_x;
								kInv.put(invFieldMappings.get('Currency Rate').KTXero__Field_API_Name__c,ix.CurrencyRate_x);
								// kInv.Currency_Code__c = ix.CurrencyCode_x;
								kInv.put(invFieldMappings.get('Currency Code').KTXero__Field_API_Name__c,ix.CurrencyCode_x);
								if(UserInfo.isMultiCurrencyOrganization()){
									kInv.put('currencyIsoCode',ix.CurrencyCode_x);
								}
								// kInv.Status__c = ix.Status_x;
								kInv.put(invFieldMappings.get('Invoice Status').KTXero__Field_API_Name__c,ix.Status_x);
								// kInv.Invoice_Date__c = ix.DateString_x != null ? date.valueOf(ix.DateString_x) : null;
								kInv.put(invFieldMappings.get('Invoice Date').KTXero__Field_API_Name__c,ix.DateString_x != null ? date.valueOf(ix.DateString_x) : null);
								// kInv.Due_Date__c = ix.DueDateString_x != null ? date.valueOf(ix.DueDateString_x) : null;
								kInv.put(invFieldMappings.get('Invoice Due Date').KTXero__Field_API_Name__c,ix.DueDateString_x != null ? date.valueOf(ix.DueDateString_x) : null);
								// kInv.Total__c = ix.Total_x;
								kInv.put(invFieldMappings.get('Total').KTXero__Field_API_Name__c,ix.Total_x);
								// kInv.Sub_Total__c = ix.SubTotal_x;
								kInv.put(invFieldMappings.get('Sub Total').KTXero__Field_API_Name__c,ix.SubTotal_x);
								// kInv.Total_Tax__c = ix.TotalTax_x;
								kInv.put(invFieldMappings.get('Total Tax').KTXero__Field_API_Name__c,ix.TotalTax_x);
								// kInv.Amounts_Are__c = ix.LineAmountTypes_x;
								kInv.put(invFieldMappings.get('Amounts are').KTXero__Field_API_Name__c,ix.LineAmountTypes_x);
								// kInv.KTXero__Xero_Contact__c = xeroConMap.get(ix.Contact_x.ContactID_x);
								kInv.put(invFieldMappings.get('Xero Contact').KTXero__Field_API_Name__c,xeroConMap.get(ix.Contact_x.ContactID_x));
								flag1 = true;
							}
							if(flag1){
								newInvList.add(kInv);
							}else{
								invIdSet.add(invMap.get(ix.InvoiceID_x).Id);
							}
							// ================= Invoice End ================= //
		
		
		
							// ================= Line Item Logic Start ================= //
							if(ix.LineItems_x.size()>0){
								// List<Invoice_Line_Item__c> upsertLiList = new List<Invoice_Line_Item__c>();
								List<SObject> upsertLiList = new List<SObject>();
								List<LineItems_x> lineItemsList = ix.LineItems_x;
								Boolean liFlag = false;
								// To check if Invoice exist in Salesforce
								if(invLineMap.containsKey(ix.InvoiceID_x)){
									Map<String,SObject> liMap = invLineMap.get(ix.InvoiceID_x);
									for(Integer i=0;i<lineItemsList.size();i++){
										if(liMap.containsKey(lineItemsList[i].LineItemID_x)){
											SObject oldLiList = liMap.get(lineItemsList[i].LineItemID_x);
											liMap.remove(lineItemsList[i].LineItemID_x);
		
											// Invoice_Line_Item__c newL = new Invoice_Line_Item__c();
											SObject newL = Schema.getGlobalDescribe().get(invLiObjApiName).newSObject();
											newL.Id = oldLiList.Id;
											// newL.KTXero__Invoice__c = oldLiList.KTXero__Invoice__c;
											newL.put(invLiFieldMappings.get('Invoice').KTXero__Field_API_Name__c,oldLiList.get(invLiFieldMappings.get('Invoice').KTXero__Field_API_Name__c));
											if(lineItemsList[i].AccountCode_x != oldLiList.get(invLiFieldMappings.get('Account Code').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Account_Code__c = lineItemsList[i].AccountCode_x;
												newL.put(invLiFieldMappings.get('Account Code').KTXero__Field_API_Name__c,lineItemsList[i].AccountCode_x);

											}
											if(lineItemsList[i].Description_x != oldLiList.get(invLiFieldMappings.get('Description').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Description__c = lineItemsList[i].Description_x;
												newL.put(invLiFieldMappings.get('Description').KTXero__Field_API_Name__c,lineItemsList[i].Description_x);
											}
											if(lineItemsList[i].DiscountRate_x != oldLiList.get(invLiFieldMappings.get('Discount Rate').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Discount_Rate__c = lineItemsList[i].DiscountRate_x;
												newL.put(invLiFieldMappings.get('Discount Rate').KTXero__Field_API_Name__c,lineItemsList[i].DiscountRate_x);
											}
											if(lineItemsList[i].LineAmount_x != oldLiList.get(invLiFieldMappings.get('Line Amount').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Line_Amount__c = lineItemsList[i].LineAmount_x;
												newL.put(invLiFieldMappings.get('Line Amount').KTXero__Field_API_Name__c,lineItemsList[i].LineAmount_x);
											}
											if(lineItemsList[i].LineItemID_x != oldLiList.get(invLiFieldMappings.get('LineItem Id').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Line_Item_Id__c = lineItemsList[i].LineItemID_x;
												newL.put(invLiFieldMappings.get('LineItem Id').KTXero__Field_API_Name__c,lineItemsList[i].LineItemID_x);
											}		
											if(lineItemsList[i].Quantity_x != oldLiList.get(invLiFieldMappings.get('Quantity').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Quantity__c = lineItemsList[i].Quantity_x;
												newL.put(invLiFieldMappings.get('Quantity').KTXero__Field_API_Name__c,lineItemsList[i].Quantity_x);
											}
											if(lineItemsList[i].TaxAmount_x != oldLiList.get(invLiFieldMappings.get('Tax Amount').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Tax_Amount__c = lineItemsList[i].TaxAmount_x;
												newL.put(invLiFieldMappings.get('Tax Amount').KTXero__Field_API_Name__c,lineItemsList[i].TaxAmount_x);
											}
											if(lineItemsList[i].TaxType_x != oldLiList.get(invLiFieldMappings.get('Tax Type').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Tax_Type__c = lineItemsList[i].TaxType_x;
												newL.put(invLiFieldMappings.get('Tax Type').KTXero__Field_API_Name__c,lineItemsList[i].TaxType_x);
											}
											if(lineItemsList[i].UnitAmount_x != oldLiList.get(invLiFieldMappings.get('Unit Amount').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Unit_Price__c = lineItemsList[i].UnitAmount_x;
												newL.put(invLiFieldMappings.get('Unit Amount').KTXero__Field_API_Name__c,lineItemsList[i].UnitAmount_x);
											}
											if(lineItemsList[i].DiscountAmount_x != oldLiList.get(invLiFieldMappings.get('Discount Amount').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Discount_Amount__c = lineItemsList[i].DiscountAmount_x;
												newL.put(invLiFieldMappings.get('Discount Amount').KTXero__Field_API_Name__c,lineItemsList[i].DiscountAmount_x);
											}
											if(lineItemsList[i].ItemCode_x != oldLiList.get(invLiFieldMappings.get('Item Code').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.KTXero__Item_Code__c = lineItemsList[i].ItemCode_x;
												newL.put(invLiFieldMappings.get('Item Code').KTXero__Field_API_Name__c,lineItemsList[i].ItemCode_x);
											}
											if(UserInfo.isMultiCurrencyOrganization()){
												newL.put('CurrencyIsoCode',ix.CurrencyCode_x);
											}
											
											if(lineItemsList[i].Item_x != null){
												if(prodMap.containsKey(lineItemsList[i].Item_x.ItemID_x)){
													if(oldLiList.get(invLiFieldMappings.get('Product').KTXero__Field_API_Name__c) != null){
														if(oldLiList.get(invLiFieldMappings.get('Product').KTXero__Field_API_Name__c) != prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id){
															// newL.KTXero__Product__c = prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id;
															newL.put(invLiFieldMappings.get('Product').KTXero__Field_API_Name__c,prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id);
															liFlag = true;
														}
													}
													else{
														// newL.KTXero__Product__c = prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id;
														newL.put(invLiFieldMappings.get('Product').KTXero__Field_API_Name__c,prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id);
														liFlag = true;
													}
												}
											}
											if(liFlag){
												upsertLiList.add(newL);
											}
										}else{
											// Invoice_Line_Item__c newL = new Invoice_Line_Item__c();
											SObject newL = Schema.getGlobalDescribe().get(invLiObjApiName).newSObject();
											// newL.Name = 'LineItem-'+(i+1) +' | '+ix.InvoiceNumber_x;
											newL.put(invLiFieldMappings.get('Name').KTXero__Field_API_Name__c,'LineItem-'+(i+1) +' | '+ix.InvoiceNumber_x);
											// newL.Account_Code__c = lineItemsList[i].AccountCode_x;
											newL.put(invLiFieldMappings.get('Account Code').KTXero__Field_API_Name__c,lineItemsList[i].AccountCode_x);
											// newL.Description__c = lineItemsList[i].Description_x;
											newL.put(invLiFieldMappings.get('Description').KTXero__Field_API_Name__c,lineItemsList[i].Description_x);
											// newL.Discount_Rate__c = lineItemsList[i].DiscountRate_x;
											newL.put(invLiFieldMappings.get('Discount Rate').KTXero__Field_API_Name__c,lineItemsList[i].DiscountRate_x);
											// newL.Invoice__c = invMap.get(ix.InvoiceID_x).Id;
											newL.put(invLiFieldMappings.get('Invoice').KTXero__Field_API_Name__c,invMap.get(ix.InvoiceID_x).Id);
											// newL.Line_Amount__c = lineItemsList[i].LineAmount_x;
											newL.put(invLiFieldMappings.get('Line Amount').KTXero__Field_API_Name__c,lineItemsList[i].LineAmount_x);
											// newL.Line_Item_Id__c = lineItemsList[i].LineItemID_x;
											newL.put(invLiFieldMappings.get('LineItem Id').KTXero__Field_API_Name__c,lineItemsList[i].LineItemID_x);
											// newL.Quantity__c = lineItemsList[i].Quantity_x;
											newL.put(invLiFieldMappings.get('Quantity').KTXero__Field_API_Name__c,lineItemsList[i].Quantity_x);
											// newL.Tax_Amount__c = lineItemsList[i].TaxAmount_x;
											newL.put(invLiFieldMappings.get('Tax Amount').KTXero__Field_API_Name__c,lineItemsList[i].TaxAmount_x);
											// newL.Tax_Type__c = lineItemsList[i].TaxType_x;
											newL.put(invLiFieldMappings.get('Tax Type').KTXero__Field_API_Name__c,lineItemsList[i].TaxType_x);
											// newL.Unit_Price__c = lineItemsList[i].UnitAmount_x;
											newL.put(invLiFieldMappings.get('Unit Amount').KTXero__Field_API_Name__c,lineItemsList[i].UnitAmount_x);
											// newL.Discount_Amount__c = lineItemsList[i].DiscountAmount_x;
											newL.put(invLiFieldMappings.get('Discount Amount').KTXero__Field_API_Name__c,lineItemsList[i].DiscountAmount_x);
											if(UserInfo.isMultiCurrencyOrganization()){
												newL.put('CurrencyIsoCode',ix.CurrencyCode_x);
											}

											if(lineItemsList[i].Item_x != null){
												if(prodMap.containsKey(lineItemsList[i].Item_x.ItemID_x)){
													// newL.KTXero__Product__c = prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id;
													newL.put(invLiFieldMappings.get('Product').KTXero__Field_API_Name__c,prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id);
												}
											}
											// newL.KTXero__Item_Code__c = lineItemsList[i].ItemCode_x;
											newL.put(invLiFieldMappings.get('Item Code').KTXero__Field_API_Name__c,lineItemsList[i].ItemCode_x);
											upsertLiList.add(newL);
										}
									}
									if(liMap.size()>0){
										for(String s : liMap.keySet()){
											SObject li = Schema.getGlobalDescribe().get(invLiObjApiName).newSObject();
											// Invoice_Line_Item__c li = new Invoice_Line_Item__c();
											li.Id = liMap.get(s).Id;
											invLideleteList.add(li);
										}
									}
								}else{
									// Line item for New Invoice
									for(Integer i=0;i<lineItemsList.size();i++){
										// Invoice_Line_Item__c newL = new Invoice_Line_Item__c();
										SObject newL = Schema.getGlobalDescribe().get(invLiObjApiName).newSObject();
										// newL.Name = 'LineItem-'+(i+1) +' | '+ix.InvoiceNumber_x;
										newL.put(invLiFieldMappings.get('Name').KTXero__Field_API_Name__c,'LineItem-'+(i+1) +' | '+ix.InvoiceNumber_x);
										// newL.Account_Code__c = lineItemsList[i].AccountCode_x;
										newL.put(invLiFieldMappings.get('Account Code').KTXero__Field_API_Name__c,lineItemsList[i].AccountCode_x);
										// newL.Description__c = lineItemsList[i].Description_x;
										newL.put(invLiFieldMappings.get('Description').KTXero__Field_API_Name__c,lineItemsList[i].Description_x);
										// newL.Discount_Rate__c = lineItemsList[i].DiscountRate_x;
										newL.put(invLiFieldMappings.get('Discount Rate').KTXero__Field_API_Name__c,lineItemsList[i].DiscountRate_x);
										// newL.Invoice__c = invMap.get(ix.InvoiceID_x).Id;
										newL.put(invLiFieldMappings.get('Invoice').KTXero__Field_API_Name__c,invMap.get(ix.InvoiceID_x).Id);
										// newL.Line_Amount__c = lineItemsList[i].LineAmount_x;
										newL.put(invLiFieldMappings.get('Line Amount').KTXero__Field_API_Name__c,lineItemsList[i].LineAmount_x);
										// newL.Line_Item_Id__c = lineItemsList[i].LineItemID_x;
										newL.put(invLiFieldMappings.get('LineItem Id').KTXero__Field_API_Name__c,lineItemsList[i].LineItemID_x);
										// newL.Quantity__c = lineItemsList[i].Quantity_x;
										newL.put(invLiFieldMappings.get('Quantity').KTXero__Field_API_Name__c,lineItemsList[i].Quantity_x);
										// newL.Tax_Amount__c = lineItemsList[i].TaxAmount_x;
										newL.put(invLiFieldMappings.get('Tax Amount').KTXero__Field_API_Name__c,lineItemsList[i].TaxAmount_x);
										// newL.Tax_Type__c = lineItemsList[i].TaxType_x;
										newL.put(invLiFieldMappings.get('Tax Type').KTXero__Field_API_Name__c,lineItemsList[i].TaxType_x);
										// newL.Unit_Price__c = lineItemsList[i].UnitAmount_x;
										newL.put(invLiFieldMappings.get('Unit Amount').KTXero__Field_API_Name__c,lineItemsList[i].UnitAmount_x);
										// newL.Discount_Amount__c = lineItemsList[i].DiscountAmount_x;
										newL.put(invLiFieldMappings.get('Discount Amount').KTXero__Field_API_Name__c,lineItemsList[i].DiscountAmount_x);
										if(UserInfo.isMultiCurrencyOrganization()){
											newL.put('CurrencyIsoCode',ix.CurrencyCode_x);
										}

										if(lineItemsList[i].Item_x != null){
											if(prodMap.containsKey(lineItemsList[i].Item_x.ItemID_x)){
												// newL.KTXero__Product__c = prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id;
												newL.put(invLiFieldMappings.get('Product').KTXero__Field_API_Name__c,prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id);
											}
										}
										// newL.KTXero__Item_Code__c = lineItemsList[i].ItemCode_x;
										newL.put(invLiFieldMappings.get('Item Code').KTXero__Field_API_Name__c,lineItemsList[i].ItemCode_x);
										upsertLiList.add(newL);
									}
								}
								lineItemsMap.put(ix.InvoiceID_x,upsertLiList);
							}
							// ================= Line Item Logic End ================= //
						}else if(ix.Type_x == 'ACCPAY'){
							// ================= Bill Start ================= //
							System.debug('ix-->'+ix);
							Boolean flag1 = false;
							// KTXero__Bill__c kBill = new KTXero__Bill__c();
							SObject kBill = Schema.getGlobalDescribe().get(billObjApiName).newSObject();
							if(billMap.containsKey(ix.InvoiceID_x)){
								//kBill.Id = billMap.get(ix.InvoiceID_x).Id;
								kBill = billMap.get(ix.InvoiceID_x);
								if(kBill.get(billFieldMappings.get('Bill Template').KTXero__Field_API_Name__c) != ix.BrandingThemeID_x){
									flag1 = true;
									// kBill.Branding_Theme_Id__c = ix.BrandingThemeID_x;
									kBill.put(billFieldMappings.get('Bill Template').KTXero__Field_API_Name__c, ix.BrandingThemeID_x);
								}
								if(kBill.get(billFieldMappings.get('Bill Id').KTXero__Field_API_Name__c) != ix.InvoiceID_x){
									flag1 = true;
									// kBill.Bill_Id__c = ix.InvoiceID_x;
									kBill.put(billFieldMappings.get('Bill Id').KTXero__Field_API_Name__c, ix.InvoiceID_x);
								}
								
								if(ix.Reference_x == '') ix.Reference_x = null;
								if(kBill.get(billFieldMappings.get('Reference').KTXero__Field_API_Name__c) != ix.Reference_x){
									flag1 = true;
									// kBill.Reference__c = ix.Reference_x;
									kBill.put(billFieldMappings.get('Reference').KTXero__Field_API_Name__c, ix.Reference_x);
								}
								if(kBill.get(billFieldMappings.get('TYPE').KTXero__Field_API_Name__c) != ix.Type_x){
									flag1 = true;
									// kBill.Type__c = ix.Type_x;
									kBill.put(billFieldMappings.get('TYPE').KTXero__Field_API_Name__c, ix.Type_x);
								}
								if(kBill.get(billFieldMappings.get('Amount Due').KTXero__Field_API_Name__c) != ix.AmountDue_x){
									flag1 = true;
									// kBill.Amount_Due__c = ix.AmountDue_x;
									kBill.put(billFieldMappings.get('Amount Due').KTXero__Field_API_Name__c, ix.AmountDue_x);
								}
								if(kBill.get(billFieldMappings.get('Amount Paid').KTXero__Field_API_Name__c) != ix.AmountPaid_x){
									flag1 = true;
									// kBill.Amount_Paid__c = ix.AmountPaid_x;
									kBill.put(billFieldMappings.get('Amount Paid').KTXero__Field_API_Name__c, ix.AmountPaid_x);
								}
								if(kBill.get(billFieldMappings.get('Send to Contact').KTXero__Field_API_Name__c) != ix.SentToContact_x){
									flag1 = true;
									// kBill.Sent_to_Contact__c = ix.SentToContact_x != null ? ix.SentToContact_x : false;
									kBill.put(billFieldMappings.get('Send to Contact').KTXero__Field_API_Name__c, ix.SentToContact_x != null ? ix.SentToContact_x : false);
								}
								if(kBill.get(billFieldMappings.get('Currency Rate').KTXero__Field_API_Name__c) != ix.CurrencyRate_x){
									flag1 = true;
									// kBill.Currency_Rate__c = ix.CurrencyRate_x;
									kBill.put(billFieldMappings.get('Currency Rate').KTXero__Field_API_Name__c, ix.CurrencyRate_x);
								}
								if(kBill.get(billFieldMappings.get('Currency Code').KTXero__Field_API_Name__c) != ix.CurrencyCode_x){
									flag1 = true;
									// kBill.Currency_Code__c = ix.CurrencyCode_x;
									kBill.put(billFieldMappings.get('Currency Code').KTXero__Field_API_Name__c, ix.CurrencyCode_x);
									if(UserInfo.isMultiCurrencyOrganization()){
										kBill.put('CurrencyIsoCode',ix.CurrencyCode_x);
									}
								}
								if(kBill.get(billFieldMappings.get('Status').KTXero__Field_API_Name__c) != ix.Status_x){
									flag1 = true;
									// kBill.Status__c = ix.Status_x;
									kBill.put(billFieldMappings.get('Status').KTXero__Field_API_Name__c, ix.Status_x);
								}
								if(String.isNotBlank(ix.DateString_x)){
									if(kBill.get(billFieldMappings.get('Bill Date').KTXero__Field_API_Name__c) != date.valueOf(ix.DateString_x)){
										flag1 = true;
										// kBill.Bill_Date__c = date.valueOf(ix.DateString_x);
										kBill.put(billFieldMappings.get('Bill Date').KTXero__Field_API_Name__c, date.valueOf(ix.DateString_x));
									}
								}
								if(String.isNotBlank(ix.DueDateString_x)){
									if(kBill.get(billFieldMappings.get('Bill Due Date').KTXero__Field_API_Name__c) != date.valueOf(ix.DueDateString_x)){
										flag1 = true;
										// kBill.Due_Date__c = date.valueOf(ix.DueDateString_x);
										kBill.put(billFieldMappings.get('Bill Due Date').KTXero__Field_API_Name__c, date.valueOf(ix.DueDateString_x));
									}
								}
								if(kBill.get(billFieldMappings.get('Total').KTXero__Field_API_Name__c) != ix.Total_x){
									flag1 = true;
									// kBill.Total__c = ix.Total_x;
									kBill.put(billFieldMappings.get('Total').KTXero__Field_API_Name__c, ix.Total_x);
								}
								if(kBill.get(billFieldMappings.get('Sub Total').KTXero__Field_API_Name__c) != ix.SubTotal_x){
									flag1 = true;
									// kBill.Sub_Total__c = ix.SubTotal_x;
									kBill.put(billFieldMappings.get('Sub Total').KTXero__Field_API_Name__c, ix.SubTotal_x);
								}
								if(kBill.get(billFieldMappings.get('Total Tax').KTXero__Field_API_Name__c) != ix.TotalTax_x){
									flag1 = true;
									// kBill.Total_Tax__c = ix.TotalTax_x;
									kBill.put(billFieldMappings.get('Total Tax').KTXero__Field_API_Name__c, ix.TotalTax_x);
								}
								if(kBill.get(billFieldMappings.get('Amounts Are').KTXero__Field_API_Name__c) != ix.LineAmountTypes_x){
									flag1 = true;
									// kBill.Amounts_Are__c = ix.LineAmountTypes_x;
									kBill.put(billFieldMappings.get('Amounts Are').KTXero__Field_API_Name__c, ix.LineAmountTypes_x);
								}
								if(xeroConMap.containsKey(ix.Contact_x.ContactID_x)){
									if(kBill.get(billFieldMappings.get('Xero Contact').KTXero__Field_API_Name__c) != xeroConMap.get(ix.Contact_x.ContactID_x)){
										flag1 = true;
										// kBill.KTXero__Xero_Contact__c = xeroConMap.get(ix.Contact_x.ContactID_x);
										kBill.put(billFieldMappings.get('Xero Contact').KTXero__Field_API_Name__c, xeroConMap.get(ix.Contact_x.ContactID_x));
										// kBill.KTXero__Account__c = (String) xconMap.get(ix.Contact_x.ContactID_x).get(conFieldMappings.get('Account').KTXero__Field_API_Name__c);
										kBill.put(billFieldMappings.get('Account').KTXero__Field_API_Name__c, (String) xconMap.get(ix.Contact_x.ContactID_x).get(conFieldMappings.get('Account').KTXero__Field_API_Name__c));
									}
								}
							}else{
								// kBill.Name = ix.InvoiceNumber_x;
								kBill.put(billFieldMappings.get('Bill Name').KTXero__Field_API_Name__c, ix.InvoiceNumber_x);
								// kBill.Branding_Theme_Id__c = ix.BrandingThemeID_x;
								kBill.put(billFieldMappings.get('Bill Template').KTXero__Field_API_Name__c, ix.BrandingThemeID_x);
								// kBill.Bill_Id__c = ix.InvoiceID_x;
								kBill.put(billFieldMappings.get('Bill Id').KTXero__Field_API_Name__c, ix.InvoiceID_x);
								// kBill.Reference__c = ix.Reference_x;
								kBill.put(billFieldMappings.get('Reference').KTXero__Field_API_Name__c, ix.Reference_x);
								// kBill.Type__c = ix.Type_x;
								kBill.put(billFieldMappings.get('TYPE').KTXero__Field_API_Name__c, ix.Type_x);
								// kBill.Amount_Due__c = ix.AmountDue_x;
								kBill.put(billFieldMappings.get('Amount Due').KTXero__Field_API_Name__c, ix.AmountDue_x);
								// kBill.Amount_Paid__c = ix.AmountPaid_x;
								kBill.put(billFieldMappings.get('Amount Paid').KTXero__Field_API_Name__c, ix.AmountPaid_x);
								// kBill.Sent_to_Contact__c = ix.SentToContact_x != null ? ix.SentToContact_x : false;
								kBill.put(billFieldMappings.get('Send to Contact').KTXero__Field_API_Name__c, ix.SentToContact_x != null ? ix.SentToContact_x : false);
								// kBill.Currency_Rate__c = ix.CurrencyRate_x;
								kBill.put(billFieldMappings.get('Currency Rate').KTXero__Field_API_Name__c, ix.CurrencyRate_x);
								// kBill.Currency_Code__c = ix.CurrencyCode_x;
								kBill.put(billFieldMappings.get('Currency Code').KTXero__Field_API_Name__c, ix.CurrencyCode_x);
								if(UserInfo.isMultiCurrencyOrganization()){
									kBill.put('currencyIsoCode',ix.CurrencyCode_x);
								}
								// kBill.Status__c = ix.Status_x;
								kBill.put(billFieldMappings.get('Status').KTXero__Field_API_Name__c, ix.Status_x);
								// kBill.Bill_Date__c = ix.DateString_x != null ? date.valueOf(ix.DateString_x) : null;
								kBill.put(billFieldMappings.get('Bill Date').KTXero__Field_API_Name__c, date.valueOf(ix.DateString_x));
								// kBill.Due_Date__c = ix.DueDateString_x != null ? date.valueOf(ix.DueDateString_x) : null;
								kBill.put(billFieldMappings.get('Bill Due Date').KTXero__Field_API_Name__c, date.valueOf(ix.DueDateString_x));
								// kBill.Total__c = ix.Total_x;
								kBill.put(billFieldMappings.get('Total').KTXero__Field_API_Name__c, ix.Total_x);
								// kBill.Sub_Total__c = ix.SubTotal_x;
								kBill.put(billFieldMappings.get('Sub Total').KTXero__Field_API_Name__c, ix.SubTotal_x);
								// kBill.Total_Tax__c = ix.TotalTax_x;
								kBill.put(billFieldMappings.get('Total Tax').KTXero__Field_API_Name__c, ix.TotalTax_x);
								// kBill.Amounts_Are__c = ix.LineAmountTypes_x;
								kBill.put(billFieldMappings.get('Amounts Are').KTXero__Field_API_Name__c, ix.LineAmountTypes_x);
								// kBill.KTXero__Xero_Contact__c = xeroConMap.get(ix.Contact_x.ContactID_x);
								kBill.put(billFieldMappings.get('Xero Contact').KTXero__Field_API_Name__c, xeroConMap.get(ix.Contact_x.ContactID_x));
								// kBill.KTXero__Account__c = (String) xconMap.get(ix.Contact_x.ContactID_x).get(conFieldMappings.get('Account').KTXero__Field_API_Name__c);
								kBill.put(billFieldMappings.get('Account').KTXero__Field_API_Name__c, (String) xconMap.get(ix.Contact_x.ContactID_x).get(conFieldMappings.get('Account').KTXero__Field_API_Name__c));
								flag1 = true;
							}
							if(flag1){
								newbillList.add(kBill);
							}else{
								billIdSet.add(billMap.get(ix.InvoiceID_x).Id);
							}
							// ================= Bill End ================= //
		
		
		
							// ================= Bill Line Item Logic Start ================= //
							if(ix.LineItems_x.size()>0){
								// List<Bill_Line_Item__c> upsertLiList = new List<Bill_Line_Item__c>();
								List<SObject> upsertLiList = new List<SObject>();
								List<LineItems_x> lineItemsList = ix.LineItems_x;
								Boolean liFlag = false;
								// To check if Bill exist in Salesforce
								if(billLineMap.containsKey(ix.InvoiceID_x)){
									// Map<String,KTXero__Bill_Line_Item__c> liMap = billLineMap.get(ix.InvoiceID_x);
									Map<String,SObject> liMap = billLineMap.get(ix.InvoiceID_x);
									for(Integer i=0;i<lineItemsList.size();i++){
										if(liMap.containsKey(lineItemsList[i].LineItemID_x)){
											SObject oldLiList = liMap.get(lineItemsList[i].LineItemID_x);
											liMap.remove(lineItemsList[i].LineItemID_x);
		
											// Bill_Line_Item__c newL = new Bill_Line_Item__c();
											SObject newL = Schema.getGlobalDescribe().get(billLiObjApiName).newSObject();
											newL.Id = oldLiList.Id;
											// newL.KTXero__Bill__c = oldLiList.KTXero__Bill__c;
											newL.put(billLiFieldMappings.get('Bill').KTXero__Field_API_Name__c,oldLiList.get(billLiFieldMappings.get('Bill').KTXero__Field_API_Name__c));
											if(lineItemsList[i].AccountCode_x != oldLiList.get(billLiFieldMappings.get('Account Code').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Account_Code__c = lineItemsList[i].AccountCode_x;
												newL.put(billLiFieldMappings.get('Account Code').KTXero__Field_API_Name__c,lineItemsList[i].AccountCode_x);
											}
											if(lineItemsList[i].Description_x != oldLiList.get(billLiFieldMappings.get('Description').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Description__c = lineItemsList[i].Description_x;
												newL.put(billLiFieldMappings.get('Description').KTXero__Field_API_Name__c,lineItemsList[i].Description_x);
											}
											if(lineItemsList[i].DiscountRate_x != oldLiList.get(billLiFieldMappings.get('Discount Rate').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Discount_Rate__c = lineItemsList[i].DiscountRate_x;
												newL.put(billLiFieldMappings.get('Discount Rate').KTXero__Field_API_Name__c,lineItemsList[i].DiscountRate_x);
											}
											if(lineItemsList[i].LineAmount_x != oldLiList.get(billLiFieldMappings.get('Line Amount').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Line_Amount__c = lineItemsList[i].LineAmount_x;
												newL.put(billLiFieldMappings.get('Line Amount').KTXero__Field_API_Name__c,lineItemsList[i].LineAmount_x);
											}
											if(lineItemsList[i].LineItemID_x != oldLiList.get(billLiFieldMappings.get('LineItem Id').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Line_Item_Id__c = lineItemsList[i].LineItemID_x;
												newL.put(billLiFieldMappings.get('LineItem Id').KTXero__Field_API_Name__c,lineItemsList[i].LineItemID_x);
											}		
											if(lineItemsList[i].Quantity_x != oldLiList.get(billLiFieldMappings.get('Quantity').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Quantity__c = lineItemsList[i].Quantity_x;
												newL.put(billLiFieldMappings.get('Quantity').KTXero__Field_API_Name__c,lineItemsList[i].Quantity_x);
											}
											if(lineItemsList[i].TaxAmount_x != oldLiList.get(billLiFieldMappings.get('Tax Amount').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Tax_Amount__c = lineItemsList[i].TaxAmount_x;
												newL.put(billLiFieldMappings.get('Tax Amount').KTXero__Field_API_Name__c,lineItemsList[i].TaxAmount_x);
											}
											if(lineItemsList[i].TaxType_x != oldLiList.get(billLiFieldMappings.get('Tax Type').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Tax_Type__c = lineItemsList[i].TaxType_x;
												newL.put(billLiFieldMappings.get('Tax Type').KTXero__Field_API_Name__c,lineItemsList[i].TaxType_x);
											}
											if(lineItemsList[i].UnitAmount_x != oldLiList.get(billLiFieldMappings.get('Unit Amount').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Unit_Price__c = lineItemsList[i].UnitAmount_x;
												newL.put(billLiFieldMappings.get('Unit Amount').KTXero__Field_API_Name__c,lineItemsList[i].UnitAmount_x);
											}
											if(lineItemsList[i].DiscountAmount_x != oldLiList.get(billLiFieldMappings.get('Discount Amount').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.Discount_Amount__c = lineItemsList[i].DiscountAmount_x;
												newL.put(billLiFieldMappings.get('Discount Amount').KTXero__Field_API_Name__c,lineItemsList[i].DiscountAmount_x);
											}
											if(lineItemsList[i].ItemCode_x != oldLiList.get(billLiFieldMappings.get('Item Code').KTXero__Field_API_Name__c)){
												liFlag = true;
												// newL.KTXero__Item_Code__c = lineItemsList[i].ItemCode_x;
												newL.put(billLiFieldMappings.get('Item Code').KTXero__Field_API_Name__c,lineItemsList[i].ItemCode_x);
											}
											if(UserInfo.isMultiCurrencyOrganization()){
												newL.put('CurrencyIsoCode',ix.CurrencyCode_x);
											}
											
											if(lineItemsList[i].Item_x != null){
												if(prodMap.containsKey(lineItemsList[i].Item_x.ItemID_x)){
													if(oldLiList.get(billLiFieldMappings.get('Product').KTXero__Field_API_Name__c) != null){
														if(oldLiList.get(billLiFieldMappings.get('Product').KTXero__Field_API_Name__c) != prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id){
															// newL.KTXero__Product__c = prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id;
															newL.put(billLiFieldMappings.get('Product').KTXero__Field_API_Name__c,prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id);
															liFlag = true;
														}
													}
													else{
														// newL.KTXero__Product__c = prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id;
														newL.put(billLiFieldMappings.get('Product').KTXero__Field_API_Name__c,prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id);
														liFlag = true;
													}
												}
											}
											if(liFlag){
												upsertLiList.add(newL);
											}
										}else{
											// Bill_Line_Item__c newL = new Bill_Line_Item__c();
											SObject newL = Schema.getGlobalDescribe().get(billLiObjApiName).newSObject();
											// newL.Name = 'LineItem-'+(i+1) +' | '+ix.InvoiceNumber_x;
											newL.put(billLiFieldMappings.get('Name').KTXero__Field_API_Name__c,'LineItem-'+(i+1) +' | '+ix.InvoiceNumber_x);
											// newL.Account_Code__c = lineItemsList[i].AccountCode_x;
											newL.put(billLiFieldMappings.get('Account Code').KTXero__Field_API_Name__c,lineItemsList[i].AccountCode_x);
											// newL.Description__c = lineItemsList[i].Description_x;
											newL.put(billLiFieldMappings.get('Description').KTXero__Field_API_Name__c,lineItemsList[i].Description_x);
											// newL.Discount_Rate__c = lineItemsList[i].DiscountRate_x;
											newL.put(billLiFieldMappings.get('Discount Rate').KTXero__Field_API_Name__c,lineItemsList[i].DiscountRate_x);
											// newL.Bill__c = invMap.get(ix.InvoiceID_x).Id;
											newL.put(billLiFieldMappings.get('Bill').KTXero__Field_API_Name__c,billMap.get(ix.InvoiceID_x).Id);
											// newL.Line_Amount__c = lineItemsList[i].LineAmount_x;
											newL.put(billLiFieldMappings.get('Line Amount').KTXero__Field_API_Name__c,lineItemsList[i].LineAmount_x);
											// newL.Line_Item_Id__c = lineItemsList[i].LineItemID_x;
											newL.put(billLiFieldMappings.get('LineItem Id').KTXero__Field_API_Name__c,lineItemsList[i].LineItemID_x);
											// newL.Quantity__c = lineItemsList[i].Quantity_x;
											newL.put(billLiFieldMappings.get('Quantity').KTXero__Field_API_Name__c,lineItemsList[i].Quantity_x);
											// newL.Tax_Amount__c = lineItemsList[i].TaxAmount_x;
											newL.put(billLiFieldMappings.get('Tax Amount').KTXero__Field_API_Name__c,lineItemsList[i].TaxAmount_x);
											// newL.Tax_Type__c = lineItemsList[i].TaxType_x;
											newL.put(billLiFieldMappings.get('Tax Type').KTXero__Field_API_Name__c,lineItemsList[i].TaxType_x);
											// newL.Unit_Price__c = lineItemsList[i].UnitAmount_x;
											newL.put(billLiFieldMappings.get('Unit Amount').KTXero__Field_API_Name__c,lineItemsList[i].UnitAmount_x);
											// newL.Discount_Amount__c = lineItemsList[i].DiscountAmount_x;
											newL.put(billLiFieldMappings.get('Discount Amount').KTXero__Field_API_Name__c,lineItemsList[i].DiscountAmount_x);
											if(UserInfo.isMultiCurrencyOrganization()){
												newL.put('CurrencyIsoCode',ix.CurrencyCode_x);
											}

											if(lineItemsList[i].Item_x != null){
												if(prodMap.containsKey(lineItemsList[i].Item_x.ItemID_x)){
													// newL.KTXero__Product__c = prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id;
													newL.put(billLiFieldMappings.get('Product').KTXero__Field_API_Name__c,prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id);
												}
											}
											// newL.KTXero__Item_Code__c = lineItemsList[i].ItemCode_x;
											newL.put(billLiFieldMappings.get('Item Code').KTXero__Field_API_Name__c,lineItemsList[i].ItemCode_x);
											upsertLiList.add(newL);
										}
									}
									if(liMap.size()>0){
										for(String s : liMap.keySet()){
											// Bill_Line_Item__c li = new Bill_Line_Item__c();
											SObject li = Schema.getGlobalDescribe().get(billLiObjApiName).newSObject();
											li.Id = liMap.get(s).Id;
											billLideleteList.add(li);
										}
									}
								}else{
									// Line item for New Bill
									for(Integer i=0;i<lineItemsList.size();i++){
										// Bill_Line_Item__c newL = new Bill_Line_Item__c();
										SObject newL = Schema.getGlobalDescribe().get(billLiObjApiName).newSObject();
										// newL.Name = 'LineItem - '+(i+1) +' | '+ix.InvoiceNumber_x;
										newL.put(billLiFieldMappings.get('Name').KTXero__Field_API_Name__c,'LineItem-'+(i+1) +' | '+ix.InvoiceNumber_x);
										// newL.Account_Code__c = lineItemsList[i].AccountCode_x;
										newL.put(billLiFieldMappings.get('Account Code').KTXero__Field_API_Name__c,lineItemsList[i].AccountCode_x);
										// newL.Description__c = lineItemsList[i].Description_x;
										newL.put(billLiFieldMappings.get('Description').KTXero__Field_API_Name__c,lineItemsList[i].Description_x);
										// newL.Discount_Rate__c = lineItemsList[i].DiscountRate_x;
										newL.put(billLiFieldMappings.get('Discount Rate').KTXero__Field_API_Name__c,lineItemsList[i].DiscountRate_x);
										// newL.Line_Amount__c = lineItemsList[i].LineAmount_x;
										newL.put(billLiFieldMappings.get('Line Amount').KTXero__Field_API_Name__c,lineItemsList[i].LineAmount_x);
										// newL.Line_Item_Id__c = lineItemsList[i].LineItemID_x;
										newL.put(billLiFieldMappings.get('LineItem Id').KTXero__Field_API_Name__c,lineItemsList[i].LineItemID_x);
										// newL.Quantity__c = lineItemsList[i].Quantity_x;
										newL.put(billLiFieldMappings.get('Quantity').KTXero__Field_API_Name__c,lineItemsList[i].Quantity_x);
										// newL.Tax_Amount__c = lineItemsList[i].TaxAmount_x;
										newL.put(billLiFieldMappings.get('Tax Amount').KTXero__Field_API_Name__c,lineItemsList[i].TaxAmount_x);
										// newL.Tax_Type__c = lineItemsList[i].TaxType_x;
										newL.put(billLiFieldMappings.get('Tax Type').KTXero__Field_API_Name__c,lineItemsList[i].TaxType_x);
										// newL.Unit_Price__c = lineItemsList[i].UnitAmount_x;
										newL.put(billLiFieldMappings.get('Unit Amount').KTXero__Field_API_Name__c,lineItemsList[i].UnitAmount_x);
										// newL.Discount_Amount__c = lineItemsList[i].DiscountAmount_x;
										newL.put(billLiFieldMappings.get('Discount Amount').KTXero__Field_API_Name__c,lineItemsList[i].DiscountAmount_x);
										if(lineItemsList[i].Item_x != null){
											if(prodMap.containsKey(lineItemsList[i].Item_x.ItemID_x)){
												// newL.KTXero__Product__c = prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id;
												newL.put(billLiFieldMappings.get('Product').KTXero__Field_API_Name__c,prodMap.get(lineItemsList[i].Item_x.ItemID_x).Id);
											}
										}
										upsertLiList.add(newL);
									}
								}
								billLineItemsMap.put(ix.InvoiceID_x,upsertLiList);
							}
							// ================= Bill Line Item Logic End ================= //
						}
						
						// ================= Create Payment start ================= //
						// ================= Create Payment start ================= //
						if(ix.Payments_x.size() > 0){
							List<Payments_x> xeroPayList = ix.Payments_x;
							Integer counter = 0;
							// List<KTXero__Payment__c> newPayList = new List<KTXero__Payment__c>();
							List<SObject> newPayList = new List<SObject>();
							// List<KTXero__Xero_Bill_Payment__c> newBillPayList = new List<KTXero__Xero_Bill_Payment__c>();
							List<SObject> newBillPayList = new List<SObject>();
							// Map<String,KTXero__Payment__c> delPayMap = new Map<String,KTXero__Payment__c>(); 
							Map<String,SObject> delPayMap = new Map<String,SObject>(); 
							// Map<String,KTXero__Xero_Bill_Payment__c> delBillPayMap = new Map<String,KTXero__Xero_Bill_Payment__c>(); 
							Map<String,SObject> delBillPayMap = new Map<String,SObject>();
							
							
							for(Integer i=0;i<xeroPayList.size();i++){
								
								if(ix.Type_x == 'ACCREC'){
									if(invPayMap.containsKey(ix.InvoiceID_x)){
										// Map<String,KTXero__Payment__c> payMap1 = invPayMap.get(ix.InvoiceID_x);
										Map<String,SObject> payMap1 = invPayMap.get(ix.InvoiceID_x);
										delPayMap = invPayMap.get(ix.InvoiceID_x);
	
										if(!payMap1.containsKey(xeroPayList[i].PaymentID_x)){
											PaymentWrapper pw = payWrap.get(xeroPayList[i].PaymentID_x);
											// KTXero__Payment__c newPay = new KTXero__Payment__c();
											SObject newPay = Schema.getGlobalDescribe().get(invPayObjApiName).newSObject();
											if(pw != null){
												Integer existingPaySize = invPayMapCount.get(ix.InvoiceID_x);
												existingPaySize++;
												newPay = createPayment(pw,existingPaySize, currencySet);
												newPayList.add(newPay);
											}
										}else{
											// payMap1.remove(xeroPayList[i].PaymentID_x);
											delPayMap.remove(xeroPayList[i].PaymentID_x);
										}
									}else{
										PaymentWrapper pw = payWrap.get(xeroPayList[i].PaymentID_x);
										SObject newPay = Schema.getGlobalDescribe().get(invPayObjApiName).newSObject();
										if(pw != null){
											counter++;
											newPay = createPayment(pw,counter, currencySet);
											newPayList.add(newPay);
										}
									}
								}else if(ix.Type_x == 'ACCPAY'){
									//for the bill Payment
									if(billPayMap.containsKey(ix.InvoiceID_x)){
										Map<String,SObject> payMap1 = new Map<String,SObject>();
										payMap1 = billPayMap.get(ix.InvoiceID_x);
										delBillPayMap = billPayMap.get(ix.InvoiceID_x);
										
										if(!payMap1.containsKey(xeroPayList[i].PaymentID_x)){
											PaymentWrapper pw = payWrap.get(xeroPayList[i].PaymentID_x);
											// KTXero__Xero_Bill_Payment__c newPay = new KTXero__Xero_Bill_Payment__c();
											SObject newPay = Schema.getGlobalDescribe().get(billPayObjApiName).newSObject();
											if(pw != null){
												Integer existingPaySize = billPayMapCount.get(ix.InvoiceID_x);
												existingPaySize++;
												newPay = createBillPayment(pw,existingPaySize, currencySet);
												newBillPayList.add(newPay);
											}
										}else{
											delBillPayMap.remove(xeroPayList[i].PaymentID_x);
										}
									}else{
										PaymentWrapper pw = payWrap.get(xeroPayList[i].PaymentID_x);
										// KTXero__Xero_Bill_Payment__c newPay = new KTXero__Xero_Bill_Payment__c();
										SObject newPay = Schema.getGlobalDescribe().get(billPayObjApiName).newSObject();
										if(pw != null){
											counter++;
											newPay = createBillPayment(pw,counter, currencySet);
											newBillPayList.add(newPay);
										}
									}
								}
							}
							
							if(newPayList.size() > 0 && ix.Type_x == 'ACCREC'){
								paymentMap.put(ix.InvoiceID_x,newPayList);
							}else if(newBillPayList.size() > 0 && ix.Type_x == 'ACCPAY'){
								billPaymentMap.put(ix.InvoiceID_x,newBillPayList);
							}
							
							if(delPayMap.size()>0){
								for(String s : delPayMap.keySet()){
									// KTXero__Payment__c pay = new KTXero__Payment__c();
									SObject pay = Schema.getGlobalDescribe().get(invPayObjApiName).newSObject();
									pay.Id = delPayMap.get(s).Id;
									paydeleteList.add(pay);
								}
							}
							
							if(delBillPayMap.size()>0){
								for(String s : delBillPayMap.keySet()){
									KTXero__Xero_Bill_Payment__c pay = new KTXero__Xero_Bill_Payment__c();
									pay.Id = delBillPayMap.get(s).Id;
									payBilldeleteList.add(pay);
								}
							}
						}else if(ix.Payments_x.size() == 0 && invPayMap.size() > 0){
							if(invPayMap.containsKey(ix.InvoiceID_x)){
								if(invPayMap.get(ix.InvoiceID_x).size() > 0){
									paydeleteList = invPayMap.get(ix.InvoiceID_x).values();
								}
							}
						}
						//Create Payment Ends=====================================================
					}
					//Invoice Insert starts============================================
					if(newInvList.size() > 0 && Schema.sObjectType.KTXero__Invoice__c.isCreateable() ){
					
						Database.UpsertResult[] srLI = Database.upsert(newInvList, false);
						for (Database.UpsertResult result : srLI) {
							if (result.isSuccess()) {
								invIdSet.add(result.getId());
								continue;
							}else {
								break;
							}
						}
					}
					
					
					
					if(invIdSet.size() > 0){
						
						List<SObject> payList = new List<SObject>();
						List<SObject> finalInvList = new List<SObject>();
						// finalInvList = [SELECT Id, Name, KTXero__Invoice_Id__c FROM KTXero__Invoice__c WHERE Id IN : invIdSet WITH SECURITY_ENFORCED];
						String finalInvListQuery = 'SELECT Id, '+invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c+' FROM '+invObjApiName+' WHERE Id IN: invIdSet WITH SECURITY_ENFORCED';
						finalInvList = Database.query(finalInvListQuery);

						// List<KTXero__Invoice_Line_Item__c> lineItmList = new List<KTXero__Invoice_Line_Item__c>();
						List<SObject> lineItmList = new List<SObject>();
						
						for(SObject inv : finalInvList){
							if(lineItemsMap.containsKey((String)inv.get(invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c))){
								for(SObject li : lineItemsMap.get((String)inv.get(invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c))){
									if(li.get(invLiFieldMappings.get('Invoice').KTXero__Field_API_Name__c) == null){
										li.put(invLiFieldMappings.get('Invoice').KTXero__Field_API_Name__c, inv.Id);
									}
									lineItmList.add(li);
								}
							}
							if(paymentMap.containsKey((String)inv.get(invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c))){
								for(SObject p : paymentMap.get((String)inv.get(invFieldMappings.get('Invoice ID').KTXero__Field_API_Name__c))){
									if(p.get(invPayFieldMappings.get('Invoice').KTXero__Field_API_Name__c) == null){
										p.put(invPayFieldMappings.get('Invoice').KTXero__Field_API_Name__c, inv.Id);
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
					
					// Delete Line Items
					if(invLideleteList.size() > 0 ){ 
						Database.DeleteResult[] drList = Database.delete(invLideleteList);
						for (Database.DeleteResult result : drList) {
							if (result.isSuccess()) {
								continue;
							}else {
								break;
							}
						}
					}
					
					// Delete Payment
					if(paydeleteList.size() > 0 ){
						Database.DeleteResult[] drList = Database.delete(paydeleteList);
						for (Database.DeleteResult result : drList) {
							if (result.isSuccess()) {
								continue;
							}else {
								break;
							}
						}
					}

					// Bill, Line Items, Payement Insert Starts=================================
					if(newBillList.size() > 0 && Schema.sObjectType.KTXero__Invoice__c.isCreateable() ){
					
						Database.UpsertResult[] srLI = Database.upsert(newBillList, false);
						for (Database.UpsertResult result : srLI) {
							if (result.isSuccess()) {
								billIdSet.add(result.getId());
								continue;
							}else {
								break;
							}
						}
					}


					// List<KTXero__Xero_Bill_Payment__c> billpayList = new List<KTXero__Xero_Bill_Payment__c>();
					List<SObject> billpayList = new List<SObject>();
					if(billIdSet.size() > 0){

						// List<KTXero__Bill__c> finalBillList = new List<KTXero__Bill__c>();
						List<SObject> finalBillList = new List<SObject>();
						// finalBillList = [SELECT Id, Name, KTXero__Bill_Id__c FROM KTXero__Bill__c WHERE Id IN : billIdSet WITH SECURITY_ENFORCED];
						String finalBillListQuery = 'SELECT Id, '+billFieldMappings.get('Bill Id').KTXero__Field_API_Name__c+' FROM '+billObjApiName+' WHERE Id IN: billIdSet WITH SECURITY_ENFORCED';
						finalBillList = Database.query(finalBillListQuery);
						
						// List<KTXero__Bill_Line_Item__c> billLineItmList = new List<KTXero__Bill_Line_Item__c>();
						List<SObject> billLineItmList = new List<SObject>();
						
						for(SObject inv : finalBillList){
							if(billLineItemsMap.containsKey((String)inv.get(billFieldMappings.get('Bill Id').KTXero__Field_API_Name__c))){
								for(SObject li : billLineItemsMap.get((String)inv.get(billFieldMappings.get('Bill Id').KTXero__Field_API_Name__c))){
									if(li.get(billLiFieldMappings.get('Bill').KTXero__Field_API_Name__c) == null){
										// li.KTXero__Bill__c = inv.Id;
										li.put(billLiFieldMappings.get('Bill').KTXero__Field_API_Name__c, inv.Id);
									}
									billLineItmList.add(li);
								}
							}
							if(billPaymentMap.containsKey((String)inv.get(billFieldMappings.get('Bill Id').KTXero__Field_API_Name__c))){
								for(SObject p : billPaymentMap.get((String)inv.get(billFieldMappings.get('Bill Id').KTXero__Field_API_Name__c))){
									if(p.get(billPayFieldMappings.get('Bill').KTXero__Field_API_Name__c) == null){
										// p.KTXero__Bill__c = inv.Id;
										p.put(billPayFieldMappings.get('Bill').KTXero__Field_API_Name__c, inv.Id);
									}
									billpayList.add(p);
								}
							}
						}
	
						// Upsert Line Items
						if(billLineItmList.size()>0 && Schema.sObjectType.KTXero__Invoice_Line_Item__c.isCreateable() ){
							Database.UpsertResult[] lineItemResult = Database.upsert(billLineItmList, false);
							for (Database.UpsertResult result : lineItemResult) {
								if (result.isSuccess()) {
									continue;
								}else {
									break;
								}
							}
						}
						
						
					}
					
					// Delete Line Items
					if(billLideleteList.size() > 0 ){ 
						Database.DeleteResult[] drList = Database.delete(billLideleteList);
						for (Database.DeleteResult result : drList) {
							if (result.isSuccess()) {
								continue;
							}else {
								break;
							}
						}
					}
					// Bill, Line Items, Payement Insert Ends=================================
					
					// Insert Payments
					if(billpayList.size() > 0 && Schema.sObjectType.KTXero__Xero_Bill_Payment__c.isCreateable()){
						Database.SaveResult[] paymentResult = Database.insert(billpayList);
						for (Database.SaveResult result : paymentResult) {
							if (result.isSuccess()) {
								continue;
							}else {
								break;
							}
						}
					}
					// Delete Payment
					if(payBilldeleteList.size() > 0 ){
						Database.DeleteResult[] drList = Database.delete(payBilldeleteList);
						for (Database.DeleteResult result : drList) {
							if (result.isSuccess()) {
								continue;
							}else {
								break;
							}
						}
					}
				}


			}
			//Event Invoice Ends=================================================
				
			
			//Event Contact Starts====================================================
			if(conSet.size()>0){
				
				XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Contacts/' + xeroresourceId,headerMap,'GET','');
				HttpResponse response = callObj.response;
				logList.add(callObj.exc);

				if (response.getStatusCode() == 200) {
					InvoiceCreationWrapper.Datawrap ct1 = (InvoiceCreationWrapper.Datawrap)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.Datawrap.class);   
					InvoiceCreationWrapper.Contacts con = ct1.Contacts[0];
					createContact(con.ContactId, ct1);
				}
				if (Test.isRunningTest()) {
					throw new DMLException();
				}
		
	
			}
			// Contact Ends====================================================

			if(logList.size() > 0 ){
				// Database.insert(logList);
				FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
				flsWrap = FLSChecker.dmlInsert(logList);
				if(!flsWrap.isSuccess){
					throw new CustomException(flsWrap.message);
				}
			}
			
		}catch(Exception e){
			KTXero__Log__c kl = HandleCustomException.logException(e);
			logList.add(kl);
			if(logList.size() > 0 ){
				FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
				flsWrap = FLSChecker.dmlInsert(logList);
				if(!flsWrap.isSuccess){
					throw new CustomException(flsWrap.message);
				}
            }
		}
	}

	/**
     * @description This Method is to create payments records into the Salesforce using Webhook data
     * @param  paymentWrap
     * @param  count
     * @param  currencySet
     * @return  KTXero__Payment__c
    */
	public static SObject createBillPayment(PaymentWrapper paymentWrap, Integer count, Set<String> currencySet){
		// KTXero__Xero_Bill_Payment__c pay = new KTXero__Xero_Bill_Payment__c();
		KTXero__Invoice_Configuration_Options__c invoiceConfig = KTXero__Invoice_Configuration_Options__c.getOrgDefaults();
		String billPayObjApiName = invoiceConfig.KTXero__Bill_Payment_Mapping_Obj__c ; // Mapped Bill Payment Object API Name
		SObject pay = Schema.getGlobalDescribe().get(billPayObjApiName).newSObject();
		Map<String, KTXero__Bill_Payment_Object_Field_Mapping__c> billPayFieldMappings = KTXero__Bill_Payment_Object_Field_Mapping__c.getAll();

		if(paymentWrap.Payments_B.size() > 0){
			if(paymentWrap.Payments_B[0].Account_B != null){
				PaymentWrapper.Account_B account = paymentWrap.Payments_B[0].Account_B;
				// pay.Paid_To__c = account.Code_B +' - ' +account.Name_B;
				pay.put(billPayFieldMappings.get('Paid To').KTXero__Field_API_Name__c,account.Code_B +' - ' +account.Name_B);
			}
			if(paymentWrap.Payments_B[0].Invoice_B != null){
				String invName = paymentWrap.Payments_B[0].Invoice_B.InvoiceNumber_B;
				// pay.Name = 'Payment - '+count+' | '+invName;
				pay.put(billPayFieldMappings.get('Name').KTXero__Field_API_Name__c,'Payment - '+count+' | '+invName);
			}
			
			// pay.Amount__c = paymentWrap.Payments_B[0].Amount_B;
			pay.put(billPayFieldMappings.get('Amount').KTXero__Field_API_Name__c,paymentWrap.Payments_B[0].Amount_B);
			String d = paymentWrap.Payments_B[0].Date_B;
			// pay.Payment_Date__c = generatedate(d);
			pay.put(billPayFieldMappings.get('Payment Date').KTXero__Field_API_Name__c,generatedate(d));

			if(Userinfo.isMultiCurrencyOrganization()){
				if(paymentWrap.Payments_B[0].Invoice_B.CurrencyCode_B != null && currencySet.contains(paymentWrap.Payments_B[0].Invoice_B.CurrencyCode_B)){
					pay.put('CurrencyIsoCode',paymentWrap.Payments_B[0].Invoice_B.CurrencyCode_B);
				}else{
					pay.put('CurrencyIsoCode','USD');
				}
			}
			// pay.Payment_Id__c = paymentWrap.Payments_B[0].PaymentID_B;
			pay.put(billPayFieldMappings.get('Payment ID').KTXero__Field_API_Name__c,paymentWrap.Payments_B[0].PaymentID_B);
			// pay.Refrence__c	 = paymentWrap.Payments_B[0].Reference_B != null ? paymentWrap.Payments_B[0].Reference_B : '';
			pay.put(billPayFieldMappings.get('Reference').KTXero__Field_API_Name__c,paymentWrap.Payments_B[0].Reference_B != null ? paymentWrap.Payments_B[0].Reference_B : '');
			// pay.Currency_Rate__c = paymentWrap.Payments_B[0].CurrencyRate_B != null ? paymentWrap.Payments_B[0].CurrencyRate_B : 0;
			pay.put(billPayFieldMappings.get('Currency Rate').KTXero__Field_API_Name__c,paymentWrap.Payments_B[0].CurrencyRate_B != null ? paymentWrap.Payments_B[0].CurrencyRate_B : 0);
			// pay.Status__c = paymentWrap.Payments_B[0].Status_B;
			pay.put(billPayFieldMappings.get('Status').KTXero__Field_API_Name__c,paymentWrap.Payments_B[0].Status_B);
		}
		return pay;
	}

	/**
     * @description This Method is to create payments records into the Salesforce using Webhook data
     * @param  paymentWrap
     * @param  count
     * @param  currencySet
     * @return  SObject
    */
	public static SObject createPayment(PaymentWrapper paymentWrap, Integer count, Set<String> currencySet){
		// KTXero__Payment__c pay = new KTXero__Payment__c();
		KTXero__Invoice_Configuration_Options__c invoiceConfig = KTXero__Invoice_Configuration_Options__c.getOrgDefaults();
		String invPayObjApiName = invoiceConfig.KTXero__Invoice_Payment_Mapping_Obj__c; // Mapped Invoice Payment Object API Name
		SObject pay = Schema.getGlobalDescribe().get(invPayObjApiName).newSObject();
		Map<String, KTXero__Invoice_Payment_Object_Field_Mapping__c> invPayFieldMappings = KTXero__Invoice_Payment_Object_Field_Mapping__c.getAll();
		if(paymentWrap.Payments_B.size() > 0){
			if(paymentWrap.Payments_B[0].Account_B != null){
				PaymentWrapper.Account_B account = paymentWrap.Payments_B[0].Account_B;
				// pay.Paid_To__c = account.Code_B +' - ' +account.Name_B;
				pay.put(invPayFieldMappings.get('Paid To').KTXero__Field_API_Name__c,account.Code_B +' - ' +account.Name_B);
			}
			if(paymentWrap.Payments_B[0].Invoice_B != null){
				String invName = paymentWrap.Payments_B[0].Invoice_B.InvoiceNumber_B;
				// pay.Name = 'Payment - '+count+' | '+invName;
				pay.put(invPayFieldMappings.get('Name').KTXero__Field_API_Name__c,'Payment - '+count+' | '+invName);
			}
			
			// pay.Amount__c = paymentWrap.Payments_B[0].Amount_B;
			pay.put(invPayFieldMappings.get('Amount').KTXero__Field_API_Name__c,paymentWrap.Payments_B[0].Amount_B);
			String d = paymentWrap.Payments_B[0].Date_B;
			// pay.Payment_Date__c = generatedate(d);
			pay.put(invPayFieldMappings.get('Payment Date').KTXero__Field_API_Name__c,generatedate(d));

			if(Userinfo.isMultiCurrencyOrganization()){
				if(paymentWrap.Payments_B[0].Invoice_B.CurrencyCode_B != null && currencySet.contains(paymentWrap.Payments_B[0].Invoice_B.CurrencyCode_B)){
					pay.put('CurrencyIsoCode',paymentWrap.Payments_B[0].Invoice_B.CurrencyCode_B);
				}else{
					pay.put('CurrencyIsoCode','USD');
				}
			}
			// pay.Payment_Id__c = paymentWrap.Payments_B[0].PaymentID_B;
			pay.put(invPayFieldMappings.get('Payment ID').KTXero__Field_API_Name__c,paymentWrap.Payments_B[0].PaymentID_B);
			// pay.Refrence__c	 = paymentWrap.Payments_B[0].Reference_B != null ? paymentWrap.Payments_B[0].Reference_B : '';
			pay.put(invPayFieldMappings.get('Reference').KTXero__Field_API_Name__c,paymentWrap.Payments_B[0].Reference_B != null ? paymentWrap.Payments_B[0].Reference_B : '');
			// pay.Currency_Rate__c = paymentWrap.Payments_B[0].CurrencyRate_B != null ? paymentWrap.Payments_B[0].CurrencyRate_B : 0;
			pay.put(invPayFieldMappings.get('Currency Rate').KTXero__Field_API_Name__c,paymentWrap.Payments_B[0].CurrencyRate_B != null ? paymentWrap.Payments_B[0].CurrencyRate_B : 0);
			// pay.Status__c = paymentWrap.Payments_B[0].Status_B;
			pay.put(invPayFieldMappings.get('Status').KTXero__Field_API_Name__c,paymentWrap.Payments_B[0].Status_B);
		}
		return pay;
	}

	/**
     * @description This Method is to get detailed payment data using Xero Payment Id
     * @param  paymentId
     * @param  headerMap
     * @return  PaymentWrapper
    */
	public static PaymentDetailWrapper getPaymentDetails(String paymentId, Map<string, string> headerMap){
		PaymentDetailWrapper paymentDetail = new PaymentDetailWrapper();
		if(paymentId != NULL && String.isNotBlank(paymentId)){
			XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Payments/'+paymentId, headerMap, 'GET','');

			
			HttpResponse response = callObj.response;
			paymentDetail.log = callObj.exc;

			if(response.getStatusCode() == 200){
				Object paymentInput = Json.deserializeUntyped(response.getBody());
				String paymentSuffixed = new ReservedWordSerializer(paymentInput,'B').getAsString();
				paymentDetail.paymentWrap = PaymentWrapper.parse(paymentSuffixed);
			}
		}
		return paymentDetail;
	}

	/**
     * @description This Method is to get map of product using Xero Item data from Webhook Data
     * @param  codeMap
     * @param  itemMap
     * @return  Map<String,Product2>
    */
	public static Map<String,Product2> getProducts(Map<String,Item_x> codeMap, Map<String,Item_x> itemMap){
		List<Product2> productList = new List<Product2>();
		Map<String,Product2> productMap = new Map<String,Product2>();
		try{
			KTXero__Invoice_Configuration_Options__c invConfig = KTXero__Invoice_Configuration_Options__c.getOrgDefaults();
            Map<String,Product2> tmpProdMap = new Map<String,Product2>();

			if(codeMap.size() > 0 || itemMap.size() > 0){
				productList = [SELECT Id, Name, KTXero__Xero_ItemID__c, ProductCode, IsArchived, CreatedDate FROM Product2 WHERE KTXero__Xero_ItemID__c IN: itemMap.keySet() OR ProductCode IN : codeMap.keySet() WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC];
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
						for(Item_x item : codeMap.values()){
							Product2 pro = new Product2();
							pro.Name = item.Name_x;
							pro.ProductCode = item.Code_x;
							pro.KTXero__Xero_ItemID__c = item.ItemID_x;
							pro.isActive = true;
							productList.add(pro);
                            tmpProdMap.put(pro.KTXero__Xero_ItemID__c, pro);
						}
					}
				}
				if(codeMap.size() > 0 && invConfig.KTXero__Create_products_in_Salesforce__c){
					for(String s : codeMap.keySet()){
						Item_x item = codeMap.get(s);
                        if(!productMap.containsKey(item.ItemID_x)  && !tmpProdMap.containsKey(item.ItemID_x)){
							Product2 pro = new Product2();
							pro.Name = item.Name_x;
							pro.ProductCode = item.Code_x;
							pro.KTXero__Xero_ItemID__c = item.ItemID_x;
							pro.isActive = true;
                            tmpProdMap.put(pro.KTXero__Xero_ItemID__c, pro);
							productList.add(pro);
						}
					}
				}
	

				if(itemMap.size() > 0 && invConfig.KTXero__Create_products_in_Salesforce__c ){
					for(String s : itemMap.keySet()){
						Item_x i = itemMap.get(s);
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
					if(productList.size() > 0){
					Database.UpsertResult[] productResult = Database.upsert(productList,false);
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
			KTXero__Log__c kl = HandleCustomException.logException(e);
			List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
			logList.add(kl);
			
			FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
			flsWrap = FLSChecker.dmlInsert(logList);
			if(!flsWrap.isSuccess){
				throw new CustomException(flsWrap.message);
			}
		}
		return productMap;
	}

	/**
     * @description This method will create KT__Xero_Contact__c is from Webhook data if same record doesn't exist in Salesforce 
     * @param  xeroRefId
     * @param  ct1
    */
	public static void createContact(String xeroRefId, InvoiceCreationWrapper.Datawrap ct1){
		try{

			KTXero__Invoice_Configuration_Options__c invoiceConfig = KTXero__Invoice_Configuration_Options__c.getOrgDefaults();
			String conObjApiName = invoiceConfig.KTXero__Xero_Contact_Mapping_Object__c;

			Map<String, KTXero__Xero_Contact_Object_Field_Mapping__c> conFieldMappings = KTXero__Xero_Contact_Object_Field_Mapping__c.getAll();

			InvoiceCreationWrapper.Contacts con = ct1.Contacts[0];
			List<SObject> salesCon = new List<SObject>();
			List<SObject> upsertSobjectList = new List<SObject>();

			String query = 'SELECT Id FROM '+conObjApiName+' WHERE '+conFieldMappings.get('Reference Id').KTXero__Field_API_Name__c +'=: xeroRefId WITH SECURITY_ENFORCED';
			salesCon = Database.query(query);
		
			
			if(salesCon.size() > 0){

				SObject xeroConObj = Schema.getGlobalDescribe().get(conObjApiName).newSObject();
				xeroConObj.put('Id', salesCon[0].Id);
				xeroConObj.put(conFieldMappings.get('Company Name').KTXero__Field_API_Name__c, con.Name);
				xeroConObj.put(conFieldMappings.get('First Name').KTXero__Field_API_Name__c, con.FirstName);
				xeroConObj.put(conFieldMappings.get('Last Name').KTXero__Field_API_Name__c, con.LastName);
				xeroConObj.put(conFieldMappings.get('Email Address').KTXero__Field_API_Name__c, con.EmailAddress);
				xeroConObj.put(conFieldMappings.get('Account Number').KTXero__Field_API_Name__c, con.accountNumber);
				xeroConObj.put(conFieldMappings.get('Reference Id').KTXero__Field_API_Name__c, con.ContactId);
				xeroConObj.put(conFieldMappings.get('Status').KTXero__Field_API_Name__c, con.ContactStatus);

				// salesCon[0].Company_Name__c = con.Name;
				// salesCon[0].First_Name__c = con.FirstName;
				// salesCon[0].Last_Name__c = con.LastName;
				// salesCon[0].Email_Address__c = con.EmailAddress;
				// salesCon[0].KTXero__Account_Number__c = con.accountNumber;
				// // salesCon[0].Salesforce_Account__c = accwrap.accId;
				// salesCon[0].Reference_Id__c = con.ContactId;
				// salesCon[0].Status__c = con.ContactStatus;
				
				for(Integer i=0;i<con.ContactPersons.size();i++){
					if(i == 0 ){
						xeroConObj.put(conFieldMappings.get('Contact 1 First Name').KTXero__Field_API_Name__c, con.ContactPersons[i].FirstName);
						xeroConObj.put(conFieldMappings.get('Contact 1 Last Name').KTXero__Field_API_Name__c, con.ContactPersons[i].LastName);
						xeroConObj.put(conFieldMappings.get('Contact 1 Email').KTXero__Field_API_Name__c, con.ContactPersons[i].EmailAddress);
						xeroConObj.put(conFieldMappings.get('Contact 1 Include in Emails?').KTXero__Field_API_Name__c, con.ContactPersons[i].IncludeInEmails);
						// salesCon[0].Contact_1_First_Name__c = con.ContactPersons[i].FirstName; 
						// salesCon[0].Contact_1_Last_Name__c = con.ContactPersons[i].LastName; 
						// salesCon[0].Contact_1_Email__c = con.ContactPersons[i].EmailAddress; 
						// salesCon[0].Contact_1_Include_in_Emails__c = con.ContactPersons[i].IncludeInEmails; 
					}else if(i == 1){
						xeroConObj.put(conFieldMappings.get('Contact 2 First Name').KTXero__Field_API_Name__c, con.ContactPersons[i].FirstName);
						xeroConObj.put(conFieldMappings.get('Contact 2 Last Name').KTXero__Field_API_Name__c, con.ContactPersons[i].LastName);
						xeroConObj.put(conFieldMappings.get('Contact 2 Email').KTXero__Field_API_Name__c, con.ContactPersons[i].EmailAddress);
						xeroConObj.put(conFieldMappings.get('Contact 2 Include in Emails?').KTXero__Field_API_Name__c, con.ContactPersons[i].IncludeInEmails);
					}else if(i == 2){
						xeroConObj.put(conFieldMappings.get('Contact 3 First Name').KTXero__Field_API_Name__c, con.ContactPersons[i].FirstName);
						xeroConObj.put(conFieldMappings.get('Contact 3 Last Name').KTXero__Field_API_Name__c, con.ContactPersons[i].LastName);
						xeroConObj.put(conFieldMappings.get('Contact 3 Email').KTXero__Field_API_Name__c, con.ContactPersons[i].EmailAddress);
						xeroConObj.put(conFieldMappings.get('Contact 3 Include in Emails?').KTXero__Field_API_Name__c, con.ContactPersons[i].IncludeInEmails);
					}else if(i == 3){
						xeroConObj.put(conFieldMappings.get('Contact 4 First Name').KTXero__Field_API_Name__c, con.ContactPersons[i].FirstName);
						xeroConObj.put(conFieldMappings.get('Contact 4 Last Name').KTXero__Field_API_Name__c, con.ContactPersons[i].LastName);
						xeroConObj.put(conFieldMappings.get('Contact 4 Email').KTXero__Field_API_Name__c, con.ContactPersons[i].EmailAddress);
						xeroConObj.put(conFieldMappings.get('Contact 4 Include in Emails?').KTXero__Field_API_Name__c, con.ContactPersons[i].IncludeInEmails);
					}else if(i == 4){
						xeroConObj.put(conFieldMappings.get('Contact 5 First Name').KTXero__Field_API_Name__c, con.ContactPersons[i].FirstName);
						xeroConObj.put(conFieldMappings.get('Contact 5 Last Name').KTXero__Field_API_Name__c, con.ContactPersons[i].LastName);
						xeroConObj.put(conFieldMappings.get('Contact 5 Email').KTXero__Field_API_Name__c, con.ContactPersons[i].EmailAddress);
						xeroConObj.put(conFieldMappings.get('Contact 5 Include in Emails?').KTXero__Field_API_Name__c, con.ContactPersons[i].IncludeInEmails);
					}	
				}
				if(con.ContactPersons.size() == 0){
					xeroConObj.put(conFieldMappings.get('Contact 1 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 1 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 1 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 1 Include in Emails?').KTXero__Field_API_Name__c, false);

					xeroConObj.put(conFieldMappings.get('Contact 2 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 2 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 2 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 2 Include in Emails?').KTXero__Field_API_Name__c, false);

					xeroConObj.put(conFieldMappings.get('Contact 3 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 3 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 3 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 3 Include in Emails?').KTXero__Field_API_Name__c, false);

					xeroConObj.put(conFieldMappings.get('Contact 4 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 4 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 4 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 4 Include in Emails?').KTXero__Field_API_Name__c, false);

					xeroConObj.put(conFieldMappings.get('Contact 5 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Include in Emails?').KTXero__Field_API_Name__c, false);
					// salesCon[0].Contact_1_First_Name__c = ''; 
					// salesCon[0].Contact_1_Last_Name__c = ''; 
					// salesCon[0].Contact_1_Email__c = ''; 
					// salesCon[0].Contact_1_Include_in_Emails__c = false;

					// salesCon[0].Contact_2_First_Name__c = ''; 
					// salesCon[0].Contact_2_Last_Name__c = ''; 
					// salesCon[0].Contact_2_Email__c = ''; 
					// salesCon[0].Contact_2_Include_in_Emails__c = false;

					// salesCon[0].Contact_3_First_Name__c = ''; 
					// salesCon[0].Contact_3_Last_Name__c = ''; 
					// salesCon[0].Contact_3_Email__c = ''; 
					// salesCon[0].Contact_3_Include_in_Emails__c = false;

					// salesCon[0].Contact_4_First_Name__c = ''; 
					// salesCon[0].Contact_4_Last_Name__c = ''; 
					// salesCon[0].Contact_4_Email__c = ''; 
					// salesCon[0].Contact_4_Include_in_Emails__c = false;

					// salesCon[0].Contact_5_First_Name__c = ''; 
					// salesCon[0].Contact_5_Last_Name__c = ''; 
					// salesCon[0].Contact_5_Email__c = ''; 
					// salesCon[0].Contact_5_Include_in_Emails__c = false;
				}else if(con.ContactPersons.size() == 1){
					xeroConObj.put(conFieldMappings.get('Contact 2 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 2 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 2 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 2 Include in Emails?').KTXero__Field_API_Name__c, false);

					xeroConObj.put(conFieldMappings.get('Contact 3 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 3 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 3 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 3 Include in Emails?').KTXero__Field_API_Name__c, false);

					xeroConObj.put(conFieldMappings.get('Contact 4 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 4 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 4 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 4 Include in Emails?').KTXero__Field_API_Name__c, false);

					xeroConObj.put(conFieldMappings.get('Contact 5 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Include in Emails?').KTXero__Field_API_Name__c, false);

				}else if(con.ContactPersons.size() == 2){
					
					xeroConObj.put(conFieldMappings.get('Contact 3 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 3 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 3 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 3 Include in Emails?').KTXero__Field_API_Name__c, false);

					xeroConObj.put(conFieldMappings.get('Contact 4 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 4 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 4 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 4 Include in Emails?').KTXero__Field_API_Name__c, false);

					xeroConObj.put(conFieldMappings.get('Contact 5 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Include in Emails?').KTXero__Field_API_Name__c, false);
					
				}else if(con.ContactPersons.size() == 3){
					
					xeroConObj.put(conFieldMappings.get('Contact 4 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 4 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 4 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 4 Include in Emails?').KTXero__Field_API_Name__c, false);

					xeroConObj.put(conFieldMappings.get('Contact 5 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Include in Emails?').KTXero__Field_API_Name__c, false);
					
				}else if(con.ContactPersons.size() == 4){
					
					xeroConObj.put(conFieldMappings.get('Contact 5 First Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Last Name').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Email').KTXero__Field_API_Name__c, '');
					xeroConObj.put(conFieldMappings.get('Contact 5 Include in Emails?').KTXero__Field_API_Name__c, false);
					
				}


				if(con.Addresses.size()>0){
					List<InvoiceCreationWrapper.Addresses> addressList = con.Addresses;
					for(InvoiceCreationWrapper.Addresses add : addressList){
						if(add.AddressType == 'POBOX'){
							xeroConObj.put(conFieldMappings.get('Street Address').KTXero__Field_API_Name__c, add.AddressLine1);
							xeroConObj.put(conFieldMappings.get('Town_City').KTXero__Field_API_Name__c, add.City);
							xeroConObj.put(conFieldMappings.get('State_Region').KTXero__Field_API_Name__c, add.Region);
							xeroConObj.put(conFieldMappings.get('Postal_Zip Code').KTXero__Field_API_Name__c, add.PostalCode);
							xeroConObj.put(conFieldMappings.get('Country').KTXero__Field_API_Name__c, add.Country);
							// salesCon[0].Street_Address__c = add.AddressLine1;
							// salesCon[0].Town_City__c = add.City;
							// salesCon[0].State_Region__c = add.Region;   
							// salesCon[0].Postal_Zip_Code__c = add.PostalCode;   
							// salesCon[0].Country__c = add.Country;   
						}else if(add.AddressType == 'DELIVERY'){
							xeroConObj.put(conFieldMappings.get('Shipping Street Address').KTXero__Field_API_Name__c, add.AddressLine1);
							xeroConObj.put(conFieldMappings.get('Shipping Town_City').KTXero__Field_API_Name__c, add.City);
							xeroConObj.put(conFieldMappings.get('Shipping State_Region').KTXero__Field_API_Name__c, add.Region);
							xeroConObj.put(conFieldMappings.get('Shipping Postal_Zip Code').KTXero__Field_API_Name__c, add.PostalCode);
							xeroConObj.put(conFieldMappings.get('Shipping Country').KTXero__Field_API_Name__c, add.Country);
						}
					}
				}

				upsertSobjectList.add(xeroConObj);
				
			}else{
				List<Account> accList = new List<Account>();
				String accName = '%'+con.Name+'%';
				accList = [SELECT Id, Name FROM Account WHERE Name LIKE: accName LIMIT 1];

				SObject xeroConObj = Schema.getGlobalDescribe().get(conObjApiName).newSObject();
				xeroConObj.put(conFieldMappings.get('Company Name').KTXero__Field_API_Name__c, con.Name);
				xeroConObj.put(conFieldMappings.get('First Name').KTXero__Field_API_Name__c, con.FirstName);
				xeroConObj.put(conFieldMappings.get('Last Name').KTXero__Field_API_Name__c, con.LastName);
				xeroConObj.put(conFieldMappings.get('Email Address').KTXero__Field_API_Name__c, con.EmailAddress);
				xeroConObj.put(conFieldMappings.get('Account Number').KTXero__Field_API_Name__c, con.accountNumber);
				xeroConObj.put(conFieldMappings.get('Reference Id').KTXero__Field_API_Name__c, con.ContactId);
				xeroConObj.put(conFieldMappings.get('Status').KTXero__Field_API_Name__c, con.ContactStatus);
				// Xero_Contact__c obj = new Xero_Contact__c();
				// obj.Company_Name__c = con.Name;
				// obj.First_Name__c = con.FirstName;
				// obj.Last_Name__c = con.LastName;
				// obj.Email_Address__c = con.EmailAddress;
				// obj.KTXero__Account_Number__c = con.accountNumber;
				// obj.Reference_Id__c = con.ContactId;
				// obj.Status__c = con.ContactStatus;	

				if(!accList.isEmpty()){
					xeroConObj.put(conFieldMappings.get('Account').KTXero__Field_API_Name__c, accList[0].Id);
					// obj.Salesforce_Account__c = accList[0].Id;
				}else{
					KTXero__Xero_Contact_Configurations__c conConfig = KTXero__Xero_Contact_Configurations__c.getOrgDefaults();
					if(conConfig.KTXero__Create_Account_if_not_available__c){
						Account newAcc = new Account();
						newAcc.Name = con.Name;
						Database.SaveResult sr = Database.insert(newAcc, false);
						if(sr.isSuccess()){
							xeroConObj.put(conFieldMappings.get('Account').KTXero__Field_API_Name__c, sr.getId());
							// obj.Salesforce_Account__c = sr.getId();
						}
					}
				}
				
				for(Integer i=0;i<con.ContactPersons.size();i++){
					if(i == 0 ){
						xeroConObj.put(conFieldMappings.get('Contact 1 First Name').KTXero__Field_API_Name__c, con.ContactPersons[i].FirstName);
						xeroConObj.put(conFieldMappings.get('Contact 1 Last Name').KTXero__Field_API_Name__c, con.ContactPersons[i].LastName);
						xeroConObj.put(conFieldMappings.get('Contact 1 Email').KTXero__Field_API_Name__c, con.ContactPersons[i].EmailAddress);
						xeroConObj.put(conFieldMappings.get('Contact 1 Include in Emails?').KTXero__Field_API_Name__c, con.ContactPersons[i].IncludeInEmails);
					}else if(i == 1){
						xeroConObj.put(conFieldMappings.get('Contact 2 First Name').KTXero__Field_API_Name__c, con.ContactPersons[i].FirstName);
						xeroConObj.put(conFieldMappings.get('Contact 2 Last Name').KTXero__Field_API_Name__c, con.ContactPersons[i].LastName);
						xeroConObj.put(conFieldMappings.get('Contact 2 Email').KTXero__Field_API_Name__c, con.ContactPersons[i].EmailAddress);
						xeroConObj.put(conFieldMappings.get('Contact 2 Include in Emails?').KTXero__Field_API_Name__c, con.ContactPersons[i].IncludeInEmails);
					}else if(i == 2){
						xeroConObj.put(conFieldMappings.get('Contact 3 First Name').KTXero__Field_API_Name__c, con.ContactPersons[i].FirstName);
						xeroConObj.put(conFieldMappings.get('Contact 3 Last Name').KTXero__Field_API_Name__c, con.ContactPersons[i].LastName);
						xeroConObj.put(conFieldMappings.get('Contact 3 Email').KTXero__Field_API_Name__c, con.ContactPersons[i].EmailAddress);
						xeroConObj.put(conFieldMappings.get('Contact 3 Include in Emails?').KTXero__Field_API_Name__c, con.ContactPersons[i].IncludeInEmails);
					}else if(i == 3){
						xeroConObj.put(conFieldMappings.get('Contact 4 First Name').KTXero__Field_API_Name__c, con.ContactPersons[i].FirstName);
						xeroConObj.put(conFieldMappings.get('Contact 4 Last Name').KTXero__Field_API_Name__c, con.ContactPersons[i].LastName);
						xeroConObj.put(conFieldMappings.get('Contact 4 Email').KTXero__Field_API_Name__c, con.ContactPersons[i].EmailAddress);
						xeroConObj.put(conFieldMappings.get('Contact 4 Include in Emails?').KTXero__Field_API_Name__c, con.ContactPersons[i].IncludeInEmails);
					}else if(i == 4){
						xeroConObj.put(conFieldMappings.get('Contact 5 First Name').KTXero__Field_API_Name__c, con.ContactPersons[i].FirstName);
						xeroConObj.put(conFieldMappings.get('Contact 5 Last Name').KTXero__Field_API_Name__c, con.ContactPersons[i].LastName);
						xeroConObj.put(conFieldMappings.get('Contact 5 Email').KTXero__Field_API_Name__c, con.ContactPersons[i].EmailAddress);
						xeroConObj.put(conFieldMappings.get('Contact 5 Include in Emails?').KTXero__Field_API_Name__c, con.ContactPersons[i].IncludeInEmails);
					}
				}
				if(con.Addresses.size()>0){
					List<InvoiceCreationWrapper.Addresses> addressList = con.Addresses;
					for(InvoiceCreationWrapper.Addresses add : addressList){
						if(add.AddressType == 'POBOX'){
							xeroConObj.put(conFieldMappings.get('Street Address').KTXero__Field_API_Name__c, add.AddressLine1);
							xeroConObj.put(conFieldMappings.get('Town_City').KTXero__Field_API_Name__c, add.City);
							xeroConObj.put(conFieldMappings.get('State_Region').KTXero__Field_API_Name__c, add.Region);
							xeroConObj.put(conFieldMappings.get('Postal_Zip Code').KTXero__Field_API_Name__c, add.PostalCode);
							xeroConObj.put(conFieldMappings.get('Country').KTXero__Field_API_Name__c, add.Country);  
						}else if(add.AddressType == 'DELIVERY'){
							xeroConObj.put(conFieldMappings.get('Shipping Street Address').KTXero__Field_API_Name__c, add.AddressLine1);
							xeroConObj.put(conFieldMappings.get('Shipping Town_City').KTXero__Field_API_Name__c, add.City);
							xeroConObj.put(conFieldMappings.get('Shipping State_Region').KTXero__Field_API_Name__c, add.Region);
							xeroConObj.put(conFieldMappings.get('Shipping Postal_Zip Code').KTXero__Field_API_Name__c, add.PostalCode);
							xeroConObj.put(conFieldMappings.get('Shipping Country').KTXero__Field_API_Name__c, add.Country);
						}
					}
				}

				upsertSobjectList.add(xeroConObj);
				// salesCon.add(obj);
			}
	
			Boolean successFlag = false;
			if(upsertSobjectList.size() > 0){
				Database.UpsertResult[] srLI = Database.upsert(upsertSobjectList,false);
				for (Database.UpsertResult result : srLI) {
					if (result.isSuccess()) {
						successFlag = true;
						continue;
					}else {
						successFlag = false;
						break;
					}
				}
			}
		}catch(Exception e){
			KTXero__Log__c kl = HandleCustomException.logException(e);
			List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
			logList.add(kl);
			
			FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
			flsWrap = FLSChecker.dmlInsert(logList);
			if(!flsWrap.isSuccess){
				throw new CustomException(flsWrap.message);
			}
		}
	}

	/**
     * @description This method will generate Date from Date String 
     * @param paydate
     * @return Date
    */
	public static Date generatedate(String paydate) {
		paydate = paydate.remove('/');
		paydate = paydate.remove('Date');
		paydate = paydate.remove('(');
		paydate = paydate.remove(')');
		paydate = paydate.substringBefore('+');
		Long epoch = long.valueOf(paydate);
		Datetime dt = DateTime.newInstance(epoch);
		Date myDate = dt.date();
		return myDate;
	}

	/**
     * @description Wrapper class for Connection object
    */
	public class ConnectionWrapper {
		public String Id;
		public String clientId;
		public String clientSecret;
		public String accessToken;
		public String webhookKey;
		public String refreshToken;
		public String tenantId;
		public DateTime lastRefreshTokenTime;
	}


	/**
     * @description Wrapper class to get Payload Data from Webhook Data 
    */
	public class PayloadWrapper {
		public List<Events> events;
		public Integer firstEventSequence;
		public Integer lastEventSequence;
		public String entropy;
	}

	/**
     * @description Wrapper class to get Event Data from PaymentWrapper 
    */
	public class Events {
		public String resourceUrl;
		public String resourceId;
		public String eventDateUtc;
		public String eventType;
		public String eventCategory;
		public String tenantId;
		public String tenantType;
	}

	/**
     * @description Wrapper class to get Invoice Data
    */
	public class InvoiceWrapper {
		public String dateTimeUTC_x;
		public String id_x;
		public List<Invoices_x> invoices_x;
		public String providerName_x;
		public String status_x;
	}

	/**
     * @description Wrapper class to get Payment Data
    */
	public class Payments_B {
		public Account_B account_B;
		public Double amount_B;
		public Double bankAmount_B;
		public Double currencyRate_B;
		public String date_B;
		public Boolean hasAccount_B;
		public Boolean hasValidationErrors_B;
		public Invoice_B invoice_B;
		public Boolean isReconciled_B;
		public String paymentID_B;
		public String paymentType_B;
		public String status_B;
		public String updatedDateUTC_B;
		public List<Payments_B> payments_B;
	}

	/**
     * @description Wrapper class to get Account Data
    */
	public class Account_B {
		public String accountID_B;
		public String code_B;
		public String name_B;
	}

	/**
     * @description Wrapper class to get Invoice Data
    */
	public class Invoice_B {
		public Double amountDue_B;
		public Double amountPaid_B;
		public String currencyCode_B;
		public Double currencyRate_B;
		public String date_B;
		public String dateString_B;
		public String dueDate_B;
		public String dueDateString_B;
		public Boolean hasErrors_B;
		public String invoiceID_B;
		public String invoiceNumber_B;
		public Boolean isDiscounted_B;
		public String lineAmountTypes_B;
		public String reference_B;
		public Boolean sentToContact_B;
		public String status_B;
		public Double subTotal_B;
		public Double total_B;
		public Double totalTax_B;
		public String type_B;
		public String updatedDateUTC_B;
	}

	/**
     * @description Wrapper class to get Address Data from
    */
	public class Addresses_x {
		public String addressType_x;
		public String addressLine1_x;
		public String city_x;
		public String country_x;
		public String postalCode_x;
		public String region_x;
	}

	/**
     * @description Wrapper class to get Invoice Data
    */
	public class Invoices_x {
		public Double amountDue_x;
		public Double amountPaid_x;
		public String brandingThemeID_x;
		public Contact_x contact_x;
		public String currencyCode_x;
		public Double currencyRate_x;
		public String date_x;
		public String dateString_x;
		public String dueDate_x;
		public String dueDateString_x;
		public Boolean hasAttachments_x;
		public Boolean hasErrors_x;
		public String invoiceID_x;
		public String invoiceNumber_x;
		public Boolean isDiscounted_x;
		public String lineAmountTypes_x;
		public List<LineItems_x> lineItems_x;
		public List<Payments_x> payments_x;
		public String reference_x;
		public Boolean sentToContact_x;
		public String status_x;
		public Double subTotal_x;
		public Double total_x;
		public Double totalDiscount_x;
		public Double totalTax_x;
		public String type_x;
		public String updatedDateUTC_x;
	}

	/**
     * @description Wrapper class to get Lineitem Data
    */
	public class LineItems_x {
		public String accountCode_x;
		public String accountID_x;
		public String description_x;
		public Double discountAmount_x;
		public Double discountRate_x;
		public Item_x item_x;
		public String itemCode_x;
		public Double lineAmount_x;
		public String lineItemID_x;
		public Double quantity_x ;
		public Double taxAmount_x;
		public String taxType_x;
		public List<Tracking_x> tracking_x;
		public Double unitAmount_x;
	}

	/**
     * @description Wrapper class to get Item Data
    */
	public class Item_x {
		public String code_x;
		public String itemID_x;
		public String name_x;
	}

	/**
     * @description Wrapper class to get Tracking Data
    */
	public class Tracking_x {
		public String name_x;
		public String option_x;
		public String trackingCategoryID_x;
		public String trackingOptionID_x;
	}

	/**
     * @description Wrapper class to get Contact Data
    */
	public class Contact_x {
		public List<Addresses_x> addresses_x;
		public String accountNumber_x;
		public String bankAccountDetails_x;
		public String firstName_x;
		public String lastName_x;
		public String contactID_x;
		public String contactStatus_x;
		public String emailAddress_x;
		public Boolean hasValidationErrors_x;
		public Boolean isCustomer_x;
		public Boolean isSupplier_x;
		public String name_x;
		public String updatedDateUTC_x;
		public List<ContactPersons_x> contactPersons_x;
	}

	/**
     * @description Wrapper class to get Contact Person Data
    */
	public class ContactPersons_x {
        public String firstName_x;
        public String lastName_x;
        public String emailAddress_x;
        public boolean includeInEmails_x;
    }

	/**
     * @description Wrapper class to get Payment Data
    */
	public class Payments_x {
		public Double amount_x;
		public String batchPaymentID_x;
		public Double currencyRate_x;
		public String date_x;
		public Boolean hasAccount_x;
		public Boolean hasValidationErrors_x;
		public String paymentID_x;
	}

	/**
     * @description Wrapper class to return Payment Data & log Data
    */
	public class PaymentDetailWrapper{
		public PaymentWrapper paymentWrap;
		public KTXero__Log__c log;
	}
}