// We are not using this class we merged this methods to InvoiceConfigurationController.apx so we are commented this
public class TaxRateFetchController {
    // @AuraEnabled(cacheable=true)
    // public static List<Xero_Metadata__c> TaxRateFetchController(){
    //     List<Xero_Metadata__c> lstXeroMetadataTax = new List<Xero_Metadata__c>([
    //         SELECT
    //         Id, Name, Code__c, IsDeleted, Status__c, SystemModstamp, Text__c, Type__c, Value__c, Xero_Id__c, Xero_Org_ID__c
    //         FROM Xero_Metadata__c
    //         WHERE Type__c = 'TaxRate'
    //     ]);
    //     System.debug('lstXeroMetadataTax:'+lstXeroMetadataTax);
    //     return lstXeroMetadataTax;
    // }
    
    // @AuraEnabled(cacheable=true) 
    // public static KTXero__Invoice_Configuration_Options__c getCustomSettings(){
    //     return KTXero__Invoice_Configuration_Options__c.getOrgDefaults();
    // }
    
    // @AuraEnabled(cacheable=true) 
    // public static void updateCustomSettings(String tRate){
    //     KTXero__Invoice_Configuration_Options__c settInvConfig = new KTXero__Invoice_Configuration_Options__c();
    //     settInvConfig.Default_Tax_rate__c = tRate;
    //     Upsert settInvConfig;
    // }
}