/**
     * @description Class to manage currency related operations
     * @Author : Kandisa Technologies
     * @CreatedDate : 16 Aug 2023
    */
public with sharing class CurrencyConfigController {

    public static KTXero__Xero_Connection__c xeroConnect = [SELECT Id, KTXero__Access_Token__c, KTXero__Refresh_Token__c, KTXero__Tenant_Id__c, KTXero__Last_Token_Refresh_Time__c FROM KTXero__Xero_Connection__c WITH SECURITY_ENFORCED LIMIT 1];

    /**
     * @description Method to fetch all the currencies from Salesforce as well as Xero
     * @return CurrecnyWrapper
    */
    @AuraEnabled
    public static CurrecnyWrapper getCurrency(){
        List<KTXero__Log__c> logList = new list<KTXero__Log__c>();
        
        CurrecnyWrapper currWrap = new CurrecnyWrapper();
        try {
            //Fetching Salesforce Currencies
            if(Utils.getIsMultiCurrencyOrg()){
                List<SObject> salesforceCurrList = new List<SObject>();
                String query = 'SELECT Id, IsoCode, ConversionRate, DecimalPlaces, IsActive, IsCorporate, CreatedDate FROM CurrencyType WHERE IsActive = true WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC';
                salesforceCurrList = Database.query(query);
                List<String> salesforceCurr = new list<String>();
                for(SObject obj : salesforceCurrList){
                    salesforceCurr.add((String)obj.get('IsoCode'));
                }
                currWrap.salesforceCurr = salesforceCurr;
            } else {
                String curr = UserInfo.getDefaultCurrency();
                List<String> salesforceCurr = new list<String>();
                salesforceCurr.add(curr);
                currWrap.salesforceCurr = salesforceCurr;
            }
            
            //Fetching Xero Currencies
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
                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Currencies', headerMap, 'GET', '');
                HttpResponse response = callObj.response;
                logList.add(callObj.exc);
                if(response.getStatusCode() == 200){
                  
                    XeroCurrWrapper xeroWrapper1 = new  XeroCurrWrapper();
                    XeroCurrWrapper xeroWrap = new  XeroCurrWrapper();
                    xeroWrap = xeroWrapper1.parse(response.getBody());
                    List<String> xeroCurr = new list<String>();
                    for(CurrencyConfigController.Currencies obj : xeroWrap.Currencies){
                        xeroCurr.add(obj.Code);
                    }
                    currWrap.xeroCurr = xeroCurr;
                }
                List<KTXero__Xero_Connection__c> connectList = new List<KTXero__Xero_Connection__c>();
                connectList.add(connection);
                if(!flag && connectList.size() > 0){
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    flsWrap = FLSChecker.dmlUpdate(connectList);
                    if(!flsWrap.isSuccess){
                        throw new AuraHandledException(flsWrap.message);
                    }
                }

                if(logList.size() > 0){
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    flsWrap = FLSChecker.dmlInsert(logList);
                    if(!flsWrap.isSuccess){
                        throw new AuraHandledException(flsWrap.message);
                    }
                }
            }

        } catch (Exception e) {
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
        return currWrap;
    }



    /**
     * @description Method to create currency in Xero 
     * @return String
     * @param  xeroCurrTobeCreated
    */
    @AuraEnabled
    public static string createXeroCurrencies(String xeroCurrTobeCreated){

        List<KTXero__Log__c> logList = new list<KTXero__Log__c>();

        String responseString = '';
        String xeroCurrency = xeroCurrTobeCreated.removeEnd('-');
        try {
            string currJSON = '';
            
            currJSON += '{"Code":"' + xeroCurrency + '", "Description":"' + xeroCurrency + '"}';
            currJSON = currJSON.removeEnd(',');

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
                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Currencies', headerMap, 'PUT', currJSON);
                HttpResponse response = callObj.response;
                logList.add(callObj.exc);
    
                if(response.getStatusCode() == 200){
                    responseString = 'Xero currency created succesfully.';
                }else{
                    InvoiceCreationWrapper.ErrorWrapper invoicewrap = (InvoiceCreationWrapper.ErrorWrapper)JSON.deserialize(response.getBody(),InvoiceCreationWrapper.ErrorWrapper.class);
                    if(invoicewrap.Elements != null){
                        for(InvoiceCreationWrapper.Elements ele : invoicewrap.Elements){
                            for(InvoiceCreationWrapper.ValidationErrors vle : ele.ValidationErrors){
                                responseString += vle.Message;
                                responseString += ', ';
                            }
                        }
                        responseString = responseString.removeEnd(', ');
                    }else{
                        responseString = invoicewrap.Message;
                    }
                }
                List<KTXero__Xero_Connection__c> connectList = new List<KTXero__Xero_Connection__c>();
                connectList.add(connection);
                if(!flag && connectList.size() > 0){
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    flsWrap = FLSChecker.dmlUpdate(connectList);
                    if(!flsWrap.isSuccess){
                        throw new AuraHandledException(flsWrap.message);
                    }
                }

                if(logList.size() > 0){
                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    flsWrap = FLSChecker.dmlInsert(logList);
                    if(!flsWrap.isSuccess){
                        throw new AuraHandledException(flsWrap.message);
                    }
                }

            }
        } catch (Exception e) {
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
        return responseString;
    }

    /**
     * @description Wrapper Class to manage Salesforce and Xero currencies
     * @Author : Kandisa Technologies
     * @CreatedDate : 16 Aug 2023
    */
    public class CurrecnyWrapper{
        /**
         * @description Holds the salesforce currency 
        */ 
        @AuraEnabled public list<String> salesforceCurr {get;set;}
        
        /**
         * @description Holds the Xero currency 
        */ 
        @AuraEnabled public list<String> xeroCurr {get;set;}
    }

     /**
     * @description Wrapper Class to hold the response from Xero for single currency
     * @Author : Kandisa Technologies
     * @CreatedDate : 16 Aug 2023
    */
    public class XeroCurrWrapper {
        public String id;
        public String status;
        public String providerName;
        public String dateTimeUTC;
        public List<Currencies> currencies;
    


        /**
         * @description Method to parse JSON string into Wrapper class 
         * @return XeroCurrWrapper
         * @param  json
        */
        public XeroCurrWrapper parse(String json) {
            return (XeroCurrWrapper) System.JSON.deserialize(json, XeroCurrWrapper.class);
        }
    }

    /**
     * @description Wrapper Class to holds the currency code and description coming from response
     * @Author : Kandisa Technologies
     * @CreatedDate : 16 Aug 2023
    */
   
    public class Currencies {
        public String code;
        public String description;
    }
}