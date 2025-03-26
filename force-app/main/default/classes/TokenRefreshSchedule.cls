/**
@Author : Kandisa Technologies
@description : -> This schedule class is used to update the 
                  KTXero__Access_Token__c, KTXero__Refresh_Token__c
                  of KTXero__Xero_Connection__c from https://identity.xero.com/connect/token.
               -> This class will run every 20 minutes.
*/
public with sharing class TokenRefreshSchedule implements schedulable, Database.AllowsCallouts {
    
    /**
     * @description execute method of Schedule Class
     * @param sc
    */
    public void execute(SchedulableContext sc){
        tokenCallout();
    }

    /**
     * @description : future method to do callout to update the 
                     KTXero__Access_Token__c, KTXero__Refresh_Token__c
                     of KTXero__Xero_Connection__c 
                     from https://identity.xero.com/connect/token.
    */
    @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
    @future(Callout=true)
    public static void tokenCallout(){
        KTXero__Xero_Connection__c connection = Utils.refreshToken();
        if(connection != null){
            FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
            List<KTXero__Xero_Connection__c> xcList = new List<KTXero__Xero_Connection__c>();
            xcList.add(connection);

            flsWrap = FLSChecker.dmlUpdate(xcList);
            if(!flsWrap.isSuccess){
                throw new CustomException(flsWrap.message);
            }
        }
    }
}