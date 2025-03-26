/**
     * @description Class to Downaload Invoice From Xero to salesforce
     * @Author : Kandisa Technologies
     * @CreatedDate : 24 Jul 2023
*/
public with sharing class DownloadInvoiceController {

    public static KTXero__Xero_Connection__c xeroConnect = [SELECT Id, KTXero__Access_Token__c, KTXero__Refresh_Token__c, KTXero__Tenant_Id__c, KTXero__Last_Token_Refresh_Time__c FROM KTXero__Xero_Connection__c WITH SECURITY_ENFORCED LIMIT 1];


     /**
     * @description Method to fetch Xero invoice and save at salesforce
     * @return KTXero__Invoice__c
     * @param  recordId
    */
    @AuraEnabled
    public static ResultWrap downloadInvoice(String recordId){
        List<KTXero__Log__c> logList = new List<KTXero__Log__c>();
        List<KTXero__Invoice__c> inv = new list<KTXero__Invoice__c>();
        ResultWrap rw = new ResultWrap();
        try{
            if(recordId != null){

                inv = [SELECT Id, Name, KTXero__Invoice_Id__c, KTXero__Opportunity__c, KTXero__Account__c FROM KTXero__Invoice__c WHERE Id =: recordId WITH SECURITY_ENFORCED];
                if(inv.size() > 0){

                    List<ContentDocumentLink> conDocLinkList = new List<ContentDocumentLink>();
                    if(String.isNotBlank(inv[0].KTXero__Invoice_Id__c)){
                        
                        if(xeroConnect != null){
                            Boolean flag = Utils.checkTokenExpiry(xeroConnect.KTXero__Last_Token_Refresh_Time__c);
                            KTXero__Xero_Connection__c connection = new KTXero__Xero_Connection__c();
                            
                            Http http = new Http();
                            HttpRequest request = new HttpRequest();
                            request.setEndpoint('https://api.xero.com/api.xro/2.0/Invoices/'+inv[0].KTXero__Invoice_Id__c);
                            request.setMethod('GET');
                            request.setTimeout(120000);
                            request.setHeader('xero-tenant-id', String.isNotBlank(Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c)) ? Utils.processDecryption(xeroConnect.KTXero__Tenant_Id__c) : '');
                            if(flag){
                                request.setHeader('authorization', String.isNotBlank(Utils.processDecryption(xeroConnect.KTXero__Access_Token__c)) ? 'Bearer '+Utils.processDecryption(xeroConnect.KTXero__Access_Token__c) : '');
                            }else{
                                connection = Utils.refreshToken();
                                request.setHeader('authorization', String.isNotBlank(Utils.processDecryption(connection.KTXero__Access_Token__c)) ? 'Bearer '+Utils.processDecryption(connection.KTXero__Access_Token__c) : '');
                            }
                            request.setHeader('accept', 'application/pdf');
                            request.setHeader('Content-Type', 'application/pdf');
                            HttpResponse response = http.send(request);
                            KTXero__Log__c exc = HandleCustomException.logCallout(request,response);
                            logList.add(exc);
                
                            if(response.getStatusCode() == 200 && Schema.sObjectType.ContentVersion.isCreateable() && Schema.sObjectType.ContentDocumentLink.isCreateable()){
                                Blob b = response.getBodyAsBlob();
                
                                ContentVersion conVer = new ContentVersion();
                                conVer.ContentLocation = 'S';
                                conVer.PathOnClient = inv[0].Name+'.pdf';
                                conVer.Title = inv[0].Name;
                                conVer.VersionData = b;
                                
                                //Insert ContentVersion
                                List<ContentVersion> conVerList = new List<ContentVersion>();
                                conVerList.add(conVer);
                                FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                                flsWrap = FLSChecker.dmlInsert(conVerList);
                                if(!flsWrap.isSuccess){
                                    throw new AuraHandledException(flsWrap.message);
                                }
                
                                Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id WITH SECURITY_ENFORCED].ContentDocumentId;
                
                                ContentDocumentLink cdInv = New ContentDocumentLink();
                                cdInv.LinkedEntityId = recordId;
                                cdInv.ContentDocumentId = conDoc;
                                cdInv.shareType = 'V';
                                conDocLinkList.add(cdInv);
        
                                if(inv[0].KTXero__Opportunity__c != null){
                                    ContentDocumentLink cdOpp = New ContentDocumentLink();
                                    cdOpp.LinkedEntityId = inv[0].KTXero__Opportunity__c;
                                    cdOpp.ContentDocumentId = conDoc;
                                    cdOpp.shareType = 'V';
                                    conDocLinkList.add(cdOpp);
                                }
                                
                                if(inv[0].KTXero__Account__c != null){
                                    ContentDocumentLink cdAcc = New ContentDocumentLink();
                                    cdAcc.LinkedEntityId = inv[0].KTXero__Account__c;
                                    cdAcc.ContentDocumentId = conDoc;
                                    cdAcc.shareType = 'V';
                                    conDocLinkList.add(cdAcc);
                                }
        
                                FLSChecker.FLSCheckWrapper flsWrap1 = new FLSChecker.FLSCheckWrapper();
                                flsWrap1 = FLSChecker.dmlInsert(conDocLinkList);
                                if(!flsWrap1.isSuccess){
                                    throw new AuraHandledException(flsWrap1.message);
                                }else{
                                    rw.successFlag = flsWrap1.isSuccess;
                                }

                                rw.inv = inv[0];
                            }else if(response.getStatusCode() == 404){
                                rw.successFlag = false;
                                rw.message = inv[0].Name+' not found in Xero...';
                                rw.inv = inv[0];
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
                        if(logList.size() > 0){
                            FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                            flsWrap = FLSChecker.dmlInsert(logList);
                            if(!flsWrap.isSuccess){
                                throw new AuraHandledException(flsWrap.message);
                            }
                        }
        
                    }
                }
            }
        }catch(Exception e){
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
        return rw;
    }

    /**
     * @description wrapper Class of result
    */
    public class ResultWrap{
        /**
         * @description It holds success value
        */ 
        @AuraEnabled public Boolean successFlag {get;set;}
        /**
         * @description It holds message
        */ 
        @AuraEnabled public String message {get;set;}
        /**
         * @description It holds object of Current Invoice
        */ 
        @AuraEnabled public KTXero__Invoice__c inv {get;set;}
    }
}