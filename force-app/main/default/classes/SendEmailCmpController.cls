/**
     * @description Class to Downaload Invoice From Xero to salesforce
     * @Author : Kandisa Technologies
     * @CreatedDate : 07 May 2024
*/
public with sharing class SendEmailCmpController {
    
    public static KTXero__Xero_Connection__c xeroConnect = [SELECT Id, KTXero__Access_Token__c, KTXero__Refresh_Token__c, KTXero__Tenant_Id__c, KTXero__Last_Token_Refresh_Time__c FROM KTXero__Xero_Connection__c WITH SECURITY_ENFORCED LIMIT 1];

    /**
     * @description Method to Send Xero invoice to the associated XC
     * @return InvoiceCreationWrapper.XeroWrapper
     * @param  recordId
    */
    @AuraEnabled
    public static InvoiceCreationWrapper.XeroWrapper sendEmailtoXC(String recordId){
        String result;
        InvoiceCreationWrapper.XeroWrapper  xw = new InvoiceCreationWrapper.XeroWrapper();
        List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
        List<KTXero__Invoice__c> inv = new list<KTXero__Invoice__c>();
        try {
            if(recordId != null){

                inv = [SELECT Id, Name, KTXero__Invoice_Id__c, KTXero__Status__c FROM KTXero__Invoice__c WHERE Id =: recordId WITH SECURITY_ENFORCED];
                if(inv.size() > 0){

                    if(String.isNotBlank(inv[0].KTXero__Invoice_Id__c)){

                        if(inv[0].KTXero__Status__c != 'DRAFT' && inv[0].KTXero__Status__c != 'DELETED' && inv[0].KTXero__Status__c != 'VOIDED'){
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

                                XeroHttpCallout.CalloutWrapper callObj = XeroHttpCallout.xeroCallout('https://api.xero.com/api.xro/2.0/Invoices/'+inv[0].KTXero__Invoice_Id__c+'/Email', headerMap, 'POST', '');
                                HttpResponse response = callObj.response;
                                logList.add(callObj.exc);
                                if(response.getStatusCode() == 204){
                                    xw.successFlag = true;
                                    xw.message = 'Email sent succesfully';
                                }else{
                                    String msg = '';
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
                                    xw.successFlag = false;
                                    xw.message = msg;
                                }
                            }else{
                                xw.successFlag = false;
                                xw.message = 'Something went wrong';
                            }
                        }else{
                            xw.successFlag = false;
                            xw.message = 'Draft, voided or deleted invoices cannot be emailed';
                        }
                    }else{
                        xw.successFlag = false;
                        xw.message = 'Xero Invoice Id not found';
                    }
                }else{
                    xw.successFlag = false;
                    xw.message = 'Something went wrong';
                }
            }
            if(logList.size() > 0 && Schema.sObjectType.KTXero__Log__c.isCreateable()){
                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                flsWrap = FLSChecker.dmlInsert(logList);
                if(!flsWrap.isSuccess){
                    xw.successFlag = false;
                    xw.message = 'Something went wrong';
                    throw new AuraHandledException(flsWrap.message);
                }
            }
        } catch (Exception e) {
            xw.successFlag = false;
            xw.message = e.getMessage();
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
        return xw;
    }
}