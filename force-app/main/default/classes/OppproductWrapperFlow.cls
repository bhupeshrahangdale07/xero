public class OppproductWrapperFlow {
     /**
         * @description Holds the id of OppLineItem 
         @AuraEnabled @InvocableVariable public String id; 
         */ 
         /**
         * @description Holds the name of OppLineItem 
         @AuraEnabled @InvocableVariable public String name; 
         */ 
         /**
         * @description Holds product Id
        */ 
        @AuraEnabled @InvocableVariable public String productId; 
         /**
         * @description Holds ProductName
        */ 
        @AuraEnabled @InvocableVariable public String productName; 
         /**
         * @description Holds description of OppLineItem 
        */ 
        @AuraEnabled @InvocableVariable public String description; 
         /**
         * @description Holds productcode 
        */ 
        @AuraEnabled @InvocableVariable public String productCode; 
         /**
         * @description Holds quantity 
        */ 
        @AuraEnabled @InvocableVariable public Double quantity; 
         /**
         * @description Holds unit price 
        */ 
        @AuraEnabled @InvocableVariable public Double unitPrice; 
         /**
         * @description Holds discount 
        */ 
        @AuraEnabled @InvocableVariable public Double discount; 
         /**
         * @description Holds account 
        */ 
        @AuraEnabled @InvocableVariable public String account; 
         /**
         * @description Holds taxrate 
        */ 
        @AuraEnabled @InvocableVariable public String taxRate; 
         /**
         * @description Holds taxcount 
         @AuraEnabled @InvocableVariable public Double taxCount; 
         */ 
         /**
         * @description Holds trackingdata 
       
        @AuraEnabled @InvocableVariable public List<KeyValuePair> trackingData; 
        */ 
        /**
         * @description Holds amount 
         @AuraEnabled @InvocableVariable public Double amount; 
         */ 
         /**
         * @description Holds xeroItem reference
         @AuraEnabled @InvocableVariable public String xeroItemID; 
         */ 
         /**
         * @description Holds inputValue
         @AuraEnabled @InvocableVariable public String inputValue; 
         */ 
         /**
         * @description Holds showDropdown value
         @AuraEnabled @InvocableVariable public Boolean showDropdown; 
         */ 
         /**
         * @description Holds wrapper class of single product 
        
        @AuraEnabled @InvocableVariable public ItemWrapper item; 
        */ 
}