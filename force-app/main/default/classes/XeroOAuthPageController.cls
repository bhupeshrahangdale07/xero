/**
@Author : Kandisa Technologies
@description : This class is used in Vf Page XeroOAuthPage to do Authorization of Xero Account 
*/
public with sharing class XeroOAuthPageController {
    public static KTXero__Xero_Connection__c xeroConnection = [SELECT Id, KTXero__Client_Secret__c, KTXero__Access_Token__c, KTXero__Refresh_Token__c, KTXero__Tenant_Id__c, 
                                                                KTXero__Client_Id__c, KTXero__Last_Token_Refresh_Time__c FROM KTXero__Xero_Connection__c WITH SECURITY_ENFORCED LIMIT 1];

    public XeroConnectionWrapper xcwrap = new XeroConnectionWrapper();
    public String baseURL = System.URL.getOrgDomainUrl().toExternalForm();
    
    /**
     * @description Constuctor
     * @param stdController
    */
    public XeroOAuthPageController(ApexPages.StandardController stdController) {
        pageLoad();
    }

    /**
     * @description Constuctor with no parameter
    */
    public XeroOAuthPageController(){
        pageLoad();
    }

    /**
     * @description Method to set values on Page Load. Called from constuctor
    */
    public void pageLoad(){
        xcwrap.id = xeroConnection.Id;
        xcwrap.tokenURL = 'https://identity.xero.com/connect/token';
        xcwrap.authorizationURL = 'https://login.xero.com/identity/connect/authorize';
        xcwrap.clientId = Utils.processDecryption(xeroConnection.KTXero__Client_Id__c);
        xcwrap.clientSecret = Utils.processDecryption(xeroConnection.KTXero__Client_Secret__c);
        xcwrap.scope = 'offline_access openid profile email accounting.transactions accounting.settings accounting.contacts accounting.attachments files assets projects';
        xcwrap.redirectUri = baseURL+'/apex/KTXero__XeroOAuthPage';
        xcwrap.responseType = 'code';
        xcwrap.state = '123';
        xcwrap.authorizationCode = '';
        xcwrap.accessToken = String.isNotBlank(xeroConnection.KTXero__Access_Token__c) ? Utils.processDecryption(xeroConnection.KTXero__Access_Token__c) : '';
        xcwrap.refreshToken = String.isNotBlank(xeroConnection.KTXero__Refresh_Token__c) ? Utils.processDecryption(xeroConnection.KTXero__Refresh_Token__c) : '';
        // fetchAccessToken();
    }

    /**
     * @description Method to fetch authorization code from Xero URL 
     *              which will be used to get Access Token and Refersh Token from Xero API
     * @return Pagereference
    */
    public Pagereference fetchAuthorizationCode(){
        String thirdPartyUrl = 'https://login.xero.com/identity/connect/authorize';
        PageReference pageRef = new PageReference(thirdPartyUrl);
        pageRef.getParameters().put('response_type',xcwrap.responseType);
        pageRef.getParameters().put('client_id',xcwrap.clientId);
        pageRef.getParameters().put('redirect_uri',xcwrap.redirectUri);
        pageRef.getParameters().put('scope',xcwrap.scope);
        pageRef.getParameters().put('state',xcwrap.state);
        return pageRef;
    }

    /**
     * @description Method to fetch access token and refresh token from Xero API using 
     *              authorization code.
     *              Both token will be updated into the record of KTXero__Xero_Connection__c
     * @return Pagereference
    */
    public Pagereference fetchAccessToken(){
        String message = '';
        try{
            if(ApexPages.currentPage().getParameters().get('code') != null) {
                String code = Apexpages.currentPage().getParameters().get('code').escapeHtml4();
                Http h = new Http();
                HttpRequest req = new HttpRequest();

                String authHead = 'Basic '+EncodingUtil.base64Encode(Blob.valueOf(xcwrap.clientId+':'+xcwrap.clientSecret));
                req.setEndpoint(xcwrap.tokenURL); 
                req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                req.setHeader('authorization', authHead);
                
                String bodyRequest = '';
                bodyRequest += 'grant_type=authorization_code'; 
                bodyRequest += '&code='+code; 
                bodyRequest += '&redirect_uri='+xcwrap.redirectUri;
                req.setBody(bodyRequest);
                req.setMethod('POST');
                req.setTimeout(10000); 
                HttpResponse response = h.send(req);
                if(response.getStatusCode() == 200 && Schema.sObjectType.KTXero__Log__c.isUpdateable()){
                    AuthResponseWrap arWrap = (AuthResponseWrap)JSON.deserialize(response.getBody(),AuthResponseWrap.class);
                    xeroConnection.KTXero__Access_Token__c = Utils.processEncryption(arWrap.access_token);
                    xeroConnection.KTXero__Refresh_Token__c = Utils.processEncryption(arWrap.refresh_token);
                    xeroConnection.KTXero__Last_Token_Refresh_Time__c = System.now();

                    message = updateXeroConnection(xeroConnection);
                }

                // PageReference pg = new PageReference('/apex/KTXero__AuthorizationMessagePage');
                PageReference pg = Page.KTXero__AuthorizationMessagePage;
                pg.getParameters().put('Success',message);
                pg.setRedirect(true);
                return pg;
            } else {
                PageReference pg2 =  fetchAuthorizationCode();
                pg2.setRedirect(true);  
                return pg2;
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
            PageReference pg = Page.KTXero__AuthorizationMessagePage;
            message = 'false';
            pg.getParameters().put('Success',message);
            pg.setRedirect(true);
            return pg;
            
        }
    }

    /**
     * @description Method to Update Xero Connection Record
     * @return String
     * @param connection
    */
    public String updateXeroConnection(KTXero__Xero_Connection__c connection){
        String message = '';
        FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
        List<KTXero__Xero_Connection__c> xcList = new List<KTXero__Xero_Connection__c>();
        xcList.add(connection);

        flsWrap = FLSChecker.dmlUpdate(xcList);
        if(!flsWrap.isSuccess){
            message = 'False';
        }else{
            message = 'True';
        }
        return message;
    }

    /**
     * @description Wrapper Class for KTXero__Xero_Connection__c
    */
    public class XeroConnectionWrapper {
        public String id;
        public String tokenURL;
        public String clientId;
        public String clientSecret;
        public String scope;
        public String redirectUri;
        public String responseType;
        public String state;
        public String authorizationCode;
        public String accessToken;
        public String refreshToken;
        public String authorizationURL;

        /**
         * @description Constructor of XeroConnectionWrapper with no parameter
        */
        public XeroConnectionWrapper(){
            id = '';
            tokenURL = '';
            clientId = '';
            clientSecret = '';
            scope = '';
            redirectUri = '';
            responseType = '';
            state = '';
            authorizationCode = '';
            accessToken = '';
            refreshToken = '';
            authorizationURL = '';
        }
    }

    /**
     * @description Wrapper Class to store JSON response from Connection Callout Xero
    */
    public class AuthResponseWrap{
        public String id_token;
        public String access_token;
        public Integer expires_in;
        public String token_type;
        public String refresh_token;
        public String scope;
    }
}