/**
 * @Author : Kandisa Technologies
 * @description : This class is used to Invoice data response receiving from Xero
*/
public class InvoiceCreationWrapper {
    

    /**
     * @description Wrapper Class to manage xeroCallout
    */
    public class CalloutWrapper{
        /**
         * @description Holds the Xero response 
        */ 
        @AuraEnabled public HttpResponse response {get; set;}
        /**
         * @description Holds the exception 
        */ 
        @AuraEnabled public KTXero__Log__c exc {get; set;}
    }
    
    /**
     * @description Class to manage Product configuration
    */
    public class ProductConfigWrapper{
         /**
         * @description Holds the boolean value if product should be created in Xero 
        */ 
        @AuraEnabled public boolean createProInXero {get;set;}
         /**
         * @description Holds the boolean value if product should be created in Salesforce
        */ 
        @AuraEnabled public boolean createProInSales {get;set;}
    } 

    /**
     * @description Class to manage Xero 
    */
    public class XeroWrapper{
         /**
         * @description Holds the success Flag value
        */ 
        @AuraEnabled public boolean successFlag {get;set;}
         /**
         * @description Holds the message value 
        */ 
        @AuraEnabled public String message {get;set;}
    }

    /**
     * @description Class to manage Invoice data
    */
    public class InvoiceOppMappingWrapper{
         /**
         * @description Holds the reference value 
        */ 
        @AuraEnabled public String reference;
         /**
         * @description Holds invoice duedate 
        */ 
        @AuraEnabled public Date dueDate;
         /**
         * @description Holds invoice date 
        */ 
        @AuraEnabled public Date invDate;
         /**
         * @description Holds currencyISOCode value 
        */ 
        @AuraEnabled public string currencyIsoCode;
    }

    /**
     * @description Class to manage Xero contact data
    */
    public class XeroContactWrapper{
         /**
         * @description Holds contactId 
        */ 
        @AuraEnabled public String id {get;set;}
         /**
         * @description Holds Contact Name 
        */ 
        @AuraEnabled public String name {get;set;}
         /**
         * @description Holds Contact first name 
        */ 
        @AuraEnabled public String firstName {get;set;}
         /**
         * @description Holds Contact last name 
        */ 
        @AuraEnabled public String lastName {get;set;}
         /**
         * @description Holds Contact email 
        */ 
        @AuraEnabled public String emailAddress {get;set;}
         /**
         * @description Holds company name 
        */ 
        @AuraEnabled public String companyName {get;set;}
         /**
         * @description Holds contact reference id of xero contact 
        */ 
        @AuraEnabled public String referenceId {get;set;}
         /**
         * @description Holds street address 
        */ 
        @AuraEnabled public String streetAddress {get;set;}
         /**
         * @description Holds towncity  
        */ 
        @AuraEnabled public String townCity {get;set;}
         /**
         * @description Holds state region 
        */ 
        @AuraEnabled public String stateRegion {get;set;}
         /**
         * @description Holds postalcode 
        */ 
        @AuraEnabled public String postalZipCode {get;set;}
         /**
         * @description Holds country value 
        */ 
        @AuraEnabled public String country {get;set;}
    }

    /**
     * @description Wrapper Class to manage Invoice data
    */
    public class InvoiceConfigWrapper{
         /**
         * @description Holds Invoice Id 
        */ 
        @AuraEnabled public String id {get;set;}
         /**
         * @description Holds boolean value for draft 
        */ 
        @AuraEnabled public boolean draft {get;set;}
         /**
         * @description Holds boolean value for submit 
        */ 
        @AuraEnabled public boolean submit {get;set;}
         /**
         * @description Holds boolean if invoice is approved or not 
        */ 
        @AuraEnabled public boolean approved {get;set;}
         /**
         * @description Holds boolean value if approved or not 
        */ 
        @AuraEnabled public boolean approvedEmail {get;set;}
         /**
         * @description Holds invoice tax type value 
        */ 
        @AuraEnabled public String invtaxType{get;set;}
         /**
         * @description Holds account code 
        */ 
        @AuraEnabled public String accCode{get;set;}
         /**
         * @description Holds invoice template type  
        */ 
        @AuraEnabled public String invTemplate{get;set;}
         /**
         * @description Holds tax rate value 
        */ 
        @AuraEnabled public String taxRate{get;set;}
        /**
        * @description Holds xero invoice reference 
       */ 
        @AuraEnabled public String invoiceReference {get;set;}
         /**
         * @description Holds invoice due date 
        */ 
        @AuraEnabled public String invoiceDueDate {get;set;}
         /**
         * @description Holds invoice date 
        */  
        @AuraEnabled public String invoiceDate {get;set;}
         /**
         * @description Holds lineItemDescription 
        */  
        @AuraEnabled public String lineItemDescription {get;set;}
    }
    
    /**
     * @description wrapper Class to manage Opportunity data
    */
    public class OppWrapper{
         /**
         * @description Holds Opportunity Id 
        */ 
        @AuraEnabled public String oppId {get;set;}
         /**
         * @description Holds Opportunity Name           
        */ 
        @AuraEnabled public String name {get;set;}
         /**
         * @description Holds account id related to Opp 
        */ 
        @AuraEnabled public String accountId {get;set;}
         /**
         * @description Holds account name related to Opp 
        */ 
        @AuraEnabled public String accountName {get;set;}
         /**
         * @description Holds Opportunity object 
        */ 
        @AuraEnabled public Opportunity opp {get;set;}
         /**
         * @description Holds list of invoice related to Opp 
        */ 
        @AuraEnabled public List<InvoiceWrapper> invoices {get;set;}
         /**
         * @description Holds list of Opportunity line item related to Opportunity 
        */ 
        @AuraEnabled public List<OpplineWrapper> opplineItems {get;set;}
    }
    
    /**
     * @description wrapper Class to manage Opportunity line item
    */
    public class OpplineWrapper{
         /**
         * @description Holds If of Opportunity line item 
        */ 
        @AuraEnabled public String opplineid {get;set;}
         /**
         * @description Holds nname of OppLine item 
        */ 
        @AuraEnabled public String name {get;set;}
    }
    
    /**
     * @description wrapper Class to manage invoice detail
    */
    public class InvoiceWrapper{
         /**
         * @description Holds id of invoice
        */ 
        @AuraEnabled public String invoiceId {get;set;}
         /**
         * @description Holds the name of invoice  
        */ 
        @AuraEnabled public String name {get;set;}
    }
    
    /**
     * @description wrapper Class to manage Account data
    */
    public class AccWrapper{
         /**
         * @description Holds the id of account 
        */ 
        @AuraEnabled public String accId {get;set;}
         /**
         * @description Holds the name of account
        */ 
        @AuraEnabled public String accName {get;set;}
         /**
         * @description Holds the street value 
        */ 
        @AuraEnabled public String accStreet {get;set;}
         /**
         * @description Holds the city value 
        */ 
        @AuraEnabled public String accCity {get;set;}
         /**
         * @description Holds the state value 
        */ 
        @AuraEnabled public String accState {get;set;}
         /**
         * @description Holds the postalcode value 
        */ 
        @AuraEnabled public String accPostalCode {get;set;}
         /**
         * @description Holds the country value 
        */ 
        @AuraEnabled public String accCountry {get;set;}
         /**
         * @description Holds the phone 
        */ 
        @AuraEnabled public String accPhone {get;set;}
         /**
         * @description Holds the account number 
        */ 
        @AuraEnabled public String accNumber {get;set;}
         /**
         * @description Holds the shipping city value 
        */ 
        @AuraEnabled public String accShippingCity {get;set;}
         /**
         * @description Holds the shipping country 
        */ 
        @AuraEnabled public String accShippingCountry {get;set;}
         /**
         * @description Holds the shipping postalcode 
        */ 
        @AuraEnabled public String accShippingPostalCode {get;set;}
         /**
         * @description Holds the shipping state 
        */ 
        @AuraEnabled public String accShippingState {get;set;}
         /**
         * @description Holds the shipping street 
        */ 
        @AuraEnabled public String accShippingStreet {get;set;}
         /**
         * @description Holds the list of contact 
        */ 
        @AuraEnabled public List<ConWrapper> conList {get;set;}
    }
    
    /**
     * @description wrapper Class to manage Contact Data
    */
    public class ConWrapper{

        public ConWrapper(){
            this.conId = '';
            this.conFirstName = '';
            this.conLastName = '';
            this.conName = '';
            this.conEmail = '';
            this.includeinEmail = false;
        }
         /**
         * @description Holds the id of COntact 
        */ 
        @AuraEnabled public string conId {get;set;}
         /**
         * @description Holds the firstname 
        */ 
        @AuraEnabled public string conFirstName {get;set;}
         /**
         * @description Holds the lastname 
        */ 
        @AuraEnabled public string conLastName {get;set;}
         /**
         * @description Holds the name 
        */ 
        @AuraEnabled public string conName {get;set;}
         /**
         * @description Holds the email 
        */ 
        @AuraEnabled public string conEmail {get;set;}
         /**
         * @description Holds the email 
        */ 
        @AuraEnabled public Boolean includeinEmail {get;set;}
    }
    
    /**
     * @description wrapper Class to manage Opp Products
    */
    public class OppproductWrapper{
         /**
         * @description Holds the id of OppLineItem 
        */ 
        @AuraEnabled public String id {get;set;}
         /**
         * @description Holds the name of OppLineItem 
        */ 
        @AuraEnabled public String name {get;set;}
         /**
         * @description Holds product Id
        */ 
        @AuraEnabled public String productId {get;set;}
         /**
         * @description Holds ProductName
        */ 
        @AuraEnabled public String productName {get;set;}
         /**
         * @description Holds description of OppLineItem 
        */ 
        @AuraEnabled public String description {get;set;}
         /**
         * @description Holds productcode 
        */ 
        @AuraEnabled public String productCode {get;set;}
         /**
         * @description Holds quantity 
        */ 
        @AuraEnabled public Double quantity {get;set;}
         /**
         * @description Holds unit price 
        */ 
        @AuraEnabled public Double unitPrice {get;set;}
         /**
         * @description Holds discount 
        */ 
        @AuraEnabled public Double discount {get;set;}
         /**
         * @description Holds account 
        */ 
        @AuraEnabled public String account {get;set;}
         /**
         * @description Holds taxrate 
        */ 
        @AuraEnabled public String taxRate {get;set;}
         /**
         * @description Holds taxcount 
        */ 
        @AuraEnabled public Double taxCount {get;set;}
         /**
         * @description Holds trackingdata 
        */ 
        @AuraEnabled public List<KeyValuePair> trackingData {get;set;}
         /**
         * @description Holds amount 
        */ 
        @AuraEnabled public Double amount {get;set;}
         /**
         * @description Holds xeroItem reference
        */ 
        @AuraEnabled public String xeroItemID {get;set;}
         /**
         * @description Holds inputValue
        */ 
        @AuraEnabled public String inputValue {get;set;}
         /**
         * @description Holds showDropdown value
        */ 
        @AuraEnabled public Boolean showDropdown {get;set;}
         /**
         * @description Holds wrapper class of single product 
        */ 
        @AuraEnabled public ItemWrapper item {get;set;}
    }

    /**
     * @description wrapper Class to manage invoice line items
    */
    public class ItemWrapper{
        /**
         * @description Holds Xero Product Id
        */ 
        @AuraEnabled public String itemId {get;set;}
        /**
         * @description Holds Xero Product name
        */ 
        @AuraEnabled public String name {get;set;}
        /**
         * @description Holds Xero Product code
        */ 
        @AuraEnabled public String code {get;set;}
    }
    
    /**
     * @description wrapper Class to manage Tracking data
    */
    public class KeyValuePair {
        /**
         * @description Holds  key
        */ 
        @AuraEnabled public String key { get; set; }
        /**
         * @description Holds value
        */ 
        @AuraEnabled public trackingValuesWrap value { get; set; }
    }
    

    /**
     * @description wrapper Class to manage tracking data
    */
    public class TrackingValuesWrap{
        /**
         * @description Holds default value of tracking
        */ 
        @AuraEnabled public String defaultVal;
        /**
         * @description Holds id of tracking
        */ 
        @AuraEnabled public String id;
        /**
         * @description Holds OptName of tracking
        */ 
        @AuraEnabled public String optname;
    }

    /**
     * @description wrapper Class to manage tax rate details
    */
    public class TaxrateWrapper{
        public String id;
        public String status;
        public String providerName;
        public String dateTimeUTC;
        public List<TaxRates> taxRates;
    }
    
    /**
     * @description wrapper Class to manage tax rates
    */
    public class TaxRates{
        public String name;
        public String taxType;
        public Boolean canApplyToAssets;
        public Boolean canApplyToEquity;
        public Boolean canApplyToExpenses;
        public Boolean canApplyToLiabilities;
        public Boolean canApplyToRevenue;
        public Decimal displayTaxRate;
        public Decimal effectiveRate;
        public String status;
        public List<TaxComponents> taxComponents;
    }
    
    /**
     * @description wrapper Class to manage tax values
    */
    public class TaxComponents{
        public String name;
        public Decimal rate;
        public Boolean isCompound;
        public Boolean isNonRecoverable;
    } 
    /**
     * @description wrapper Class to manage account details
    */
    public class XeroAccountWrapper{
        public String id;
        public String status;
        public String providerName;
        public String dateTimeUTC;
        public List<Accounts> accounts;
    }
    

    /**
     * @description wrapper Class to manage Account 
    */
    public class Accounts {
        public String accountID;
        public String code;
        public String name;
        public String status;
        public String type;
        public String taxType;
        public boolean enablePaymentsToAccount;
        public boolean showInExpenseClaims;
        public String bankAccountNumber;
        public String bankAccountType;
        public String currencyCode;
        public String reportingCode;
        public String reportingCodeName;
        public boolean hasAttachments;
        public String updatedDateUTC;
        public boolean addToWatchlist;
    }
    
    /**
     * @description wrapper Class to manage tracking data
    */
    public class TrackingWrapper{
        public String id;
        public String status;
        public String providerName;
        public String dateTimeUTC;
        public List<TrackingCategories> trackingCategories;
    } 
    
    /**
     * @description wrapper Class to manage tracking categories
    */
    public class TrackingCategories {
        public String name;
        public String status;
        public String trackingCategoryID;
        public List<Options> options;
    }

    /**
     * @description wrapper Class to manage tracking options
    */
    public class Options {
        public String trackingOptionID;
        public String name;
        public String status;
        public boolean hasValidationErrors;
        public boolean isDeleted;
        public boolean isArchived;
        public boolean isActive;
    }
    
    /**
     * @description wrapper Class to manage COntacts
    */
    public class Datawrap{
        public String id;
        public String status;
        public String providerName;
        public String dateTimeUTC;
        public List<Contacts> contacts;
    }
    /**
     * @description wrapper Class to manage contact data
    */
    public class Contacts{
        public String contactID;
        public String accountNumber;
        public String contactStatus;
        public String name;
        public String firstName;
        public String lastName;
        public String emailAddress;
        public String bankAccountDetails;
        public List<Addresses> addresses;
        public List<Phones> phones;
        public String updatedDateUTC;
        public boolean isSupplier;
        public boolean isCustomer;
        public List<ContactPersons> contactPersons;
        public boolean hasValidationErrors;
    }
    
    /**
     * @description wrapper Class to manage contact addresses
    */
    public class Addresses {
        public String addressType;
        public String addressLine1;
        public String city;
        public String region;
        public String postalCode;
        public String country;
    }
    
    /**
     * @description wrapper Class to manage contact Phones
    */
    public class Phones {
        public String phoneType;
        public String phoneNumber;
        public String phoneAreaCode;
        public String phoneCountryCode;
    }
    
    /**
     * @description wrapper Class to manage contact persons
    */
    public class ContactPersons {
        public String firstName;
        public String lastName;
        public String emailAddress;
        public boolean includeInEmails;
    }
    /**
     * @description wrapper Class to manage Invoice response data
    */
    
    public class InvoiceDataWrapper{
        public String recordId;
        public String accountId;
        public String template;
        public String invoicedate;
        public String invoiceduedate;
        public String reference;
        public String amountTax;
        public String currencyCode;
        public List<OppproductWrapper> lineItems;
        /**
         * @description Constructor of Wrapper Class
        */
        public InvoiceDataWrapper(){
            recordId = '';
            accountId = '';
            template = '';
            invoicedate = '';
            invoiceduedate = '';
            reference = '';
            amountTax = '';
            currencyCode = '';
            lineItems = new List<OppproductWrapper>();
        }
    }
    
    /**
     * @description wrapper Class to manage Invoice data
    */
    public class DataInvoiceWrap{
        public String id;
        public String status;
        public String providerName;
        public String dateTimeUTC;
        public List<Invoices> invoices;
    }

    /**
     * @description wrapper Class to manage Invoice details
    */
    public class Invoices{
        public String type;
        public String invoiceID;
        public String invoiceNumber;
        public String reference;
        public Decimal amountDue;
        public Decimal amountPaid;
        public boolean sentToContact;
        public Decimal currencyRate;
        public Decimal cotalDiscount;
        public boolean isDiscounted;
        public boolean hasErrors;
        public String dateString;
        public String dueDateString;
        public String dueDate;
        public String brandingThemeID;
        public String status;
        public String lineAmountTypes;
        public List<LineItems> lineItems;
        public Double subTotal;
        public Double totalTax;
        public Decimal total;
        public String updatedDateUTC;
        public String currencyCode;
    }

    /**
     * @description wrapper Class to manage Error Object in response
    */
    public class ErrorWrapper{
        public Integer errorNumber;
        public String type;
        public String message;
        public List<Elements> elements;
    }

    /**
     * @description wrapper Class to manage Error object elements
    */
    public class Elements {
		public List<ValidationErrors> validationErrors;
	}
    
    /**
     * @description wrapper Class to manage validation Errors
    */
    public class ValidationErrors{
		public String message;
	}

    /**
     * @description wrapper Class to manage Xero Invoice Line Items details
    */
    public class LineItems {
        public String description;
        public Decimal unitAmount;
        public String taxType;
        public Decimal taxAmount;
        public Decimal lineAmount;
        public String accountCode;
        public List<Tracking> tracking;
        public Decimal quantity;
        public Decimal discountRate;
        public String lineItemID;
        public boolean discountEnteredAsPercent;
        public Double discountAmount;
        public Item item;
        /**
         * @description constructor of the Wrapper Class
        */
        public LineItems(){
            description = '';
            unitAmount = 0;
            taxType = '';
            taxAmount= 0;
            lineAmount = 0;
            accountCode = '';
            accountCode = '';
            quantity = 0;
            quantity = 0;
            lineItemID = '';
            discountEnteredAsPercent = false;
            discountAmount = 0;

        }
        
    }
    
    /**
     * @description wrapper Class to manage Xero Product details
    */
    public class Item {
		public String code;
		public String itemId;
		public String name;
	}

    /**
     * @description wrapper Class to manage Tracking details
    */
    public class Tracking {
        public String name;
        public String option;
        public String trackingCategoryID;
        public String trackingOptionID;
    }
    
    /**
     * @description wrapper Class to manage Xero contact details
    */
    public class XeroConWrapper{
        @AuraEnabled public Boolean successFlag;
        @AuraEnabled public String xeroContactId;
        @AuraEnabled public String xeroContactsfId;
        @AuraEnabled public String message;
    }
    
    /**
     * @description wrapper Class to manage Currency data
    */
    public class CurrencyWrapper{
        public String id;
        public String status;
        public String providerName;
        public String dateTimeUTC;
        public List<Currencies> currencies;
    }
    
    /**
     * @description wrapper Class to manage Currencies
    */
    public class Currencies {
        public String code;
        public String description;
    }

    /**
     * @description wrapper Class to manage Xero items
    */
    public class XeroItemWrapper{
        public String id;
	    public String status;
	    public String providerName;
	    public String dateTimeUTC;
        public List<Items> items;
    }

    /**
     * @description wrapper Class to manage Xero product details
    */
    public class Items{
        public String itemID;
		public String code;
		public String name;	
    }


    /**
     * @description wrapper Class to manage Branding theme data for Invoice template
    */
    public class BrandingthemeWrapper{
        public String id;
        public String status;
        public String providerName;
        public String dateTimeUTC;
        public List<BrandingThemes> brandingThemes;
    }
    
    /**
     * @description wrapper Class to manage Branding theme data for Invoice template
    */
	public class BrandingThemes {
		public String brandingThemeID;
		public String name;
		public String logoUrl;
		public String type;
		public Integer sortOrder;
		public String createdDateUTC;
	}

     /**
     * @description wrapper Class to manage Xero items
    */
    public class CheckAccDetailWrapper{
        /**
         * @description Holds value is Account Name or Number is duplicate or not 
        */
        @AuraEnabled public Boolean isDuplicate {get;set;}
        /**
         * @description Holds value which field is duplicate 
        */
	    @AuraEnabled public String fieldName {get;set;}
    }

    /**
     * @description wrapper Class to store searched product data
    */
    public class ProductSearchWrapper{
        /**
         * @description Holds product Id
        */ 
        @AuraEnabled public String id {get;set;}
        /**
         * @description Holds product Name
        */ 
        @AuraEnabled public String name {get;set;}
        /**
         * @description Holds product ProductCode
        */ 
        @AuraEnabled public String productCode {get;set;}
        /**
         * @description Holds product Xero reference Id
        */ 
        @AuraEnabled public String xeroItemId {get;set;}
        /**
         * @description Holds Xero Item Sales Account Code
        */ 
        @AuraEnabled public String salesAccountCode {get;set;}
        /**
         * @description Holds Xero Item Sales Tax Rate
        */ 
        @AuraEnabled public String salesTaxRate {get;set;}
        /**
         * @description Holds Xero Item Sales Description
        */ 
        @AuraEnabled public String salesDescription {get;set;}
        /**
         * @description Holds Product Description
        */ 
        @AuraEnabled public String prodDescription {get;set;}
    }
    
}