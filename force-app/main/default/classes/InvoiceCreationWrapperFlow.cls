public class InvoiceCreationWrapperFlow {
    @AuraEnabled @InvocableVariable (label='Opportunty Id' description='Enter the Id of the Opportunity')
    public String oppId;

    @AuraEnabled @InvocableVariable (label='Invoice Status' description='Enter the invoice you want to create with status. Values you can enter is DRAFT/SUBMITTED/AUTHORISED/ApprovedEmail')
    public String invStatus;
    
    @AuraEnabled @InvocableVariable (label='Xero Contact Id' description='Enter the Xero Contact Id with which you want to create invoice')
    public String contactId;
}