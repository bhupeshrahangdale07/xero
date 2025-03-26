/**
 * @Author : Kandisa Technologies
 * @description : This class is used to manage payment response receiving from Xero
*/
public class PaymentWrapper {

	public String DateTimeUTC_B;
	public String Id_B;
	public List<Payments_B_Z> Payments_B;
	public String ProviderName_B;
	public String Status_B;
	
    /**
     * @description Wrapper Class to manage COntact person data
    */
	public class ContactPersons_B {
	}

	/**
     * @description Wrapper Class to manage Line Item data
    */
	public class LineItems_B {
		public String AccountCode_B;
		public String AccountID_B;
		public String Description_B;
		public Double DiscountAmount_B;
		public Double DiscountRate_B;
		public Item_B Item_B;
		public String ItemCode_B;
		public Double LineAmount_B;
		public String LineItemID_B;
		public Double Quantity_B;
		public Double TaxAmount_B;
		public String TaxType_B;
		public List<Tracking_B> Tracking_B;
		public Double UnitAmount_B;
		public List<ContactPersons_B> ValidationErrors_B;
	}

	/**
     * @description Wrapper Class to manage COntact 
    */
	public class Contact_B {
		public String ContactID_B;
		public List<ContactPersons_B> ContactPersons_B;
		public Boolean HasValidationErrors_B;
		public String Name_B;
	}

	/**
     * @description Wrapper Class to manage Payment data
    */
	public class Payments_B {
		public Double Amount_B;
		public Double CurrencyRate_B;
		public String Date_B;
		public String Status_B;
		public String Reference_B;
		public Boolean HasAccount_B;
		public Boolean HasValidationErrors_B;
		public String PaymentID_B;
	}

	/**
     * @description Wrapper Class to manage Invoice data
    */
	public class Invoice_B {
		public Double AmountDue_B;
		public Double AmountPaid_B;
		public String BrandingThemeID_B;
		public Contact_B Contact_B;
		public String CurrencyCode_B;
		public Double CurrencyRate_B;
		public String Date_B;
		public String DateString_B;
		public String DueDate_B;
		public String DueDateString_B;
		public Boolean HasErrors_B;
		public String InvoiceID_B;
		public String InvoiceNumber_B;
		public List<ContactPersons_B> InvoicePaymentServices_B;
		public Boolean IsDiscounted_B;
		public String LineAmountTypes_B;
		public List<LineItems_B> LineItems_B;
		public List<ContactPersons_B> Overpayments_B;
		public List<Payments_B> Payments_B;
		public List<ContactPersons_B> Prepayments_B;
		public String Reference_B;
		public Boolean SentToContact_B;
		public String Status_B;
		public Double SubTotal_B;
		public Double Total_B;
		public Double TotalDiscount_B;
		public Double TotalTax_B;
		public String Type_B;
		public String UpdatedDateUTC_B;
	}

	/**
     * @description Wrapper Class to manage Product data
    */
	public class Item_B {
		public String Code_B;
		public String ItemID_B;
		public String Name_B;
	}

	/**
     * @description Wrapper Class to manage tracking data
    */
	public class Tracking_B {
		public String Name_B;
		public String Option_B;
		public String TrackingCategoryID_B;
		public String TrackingOptionID_B;
	}

	/**
     * @description Wrapper Class to manage Payment data
    */
	public class Payments_B_Z {
		public Account_B Account_B;
		public Double Amount_B;
		public Double BankAmount_B;
		public Double CurrencyRate_B;
		public String Date_B;
		public String Reference_B;
		public Boolean HasAccount_B;
		public Boolean HasValidationErrors_B;
		public Invoice_B Invoice_B;
		public Boolean IsReconciled_B;
		public String PaymentID_B;
		public String PaymentType_B;
		public String Status_B;
		public String UpdatedDateUTC_B;
	}

	/**
     * @description Wrapper Class to manage Account data
    */
	public class Account_B {
		public String AccountID_B;
		public String Code_B;
		public String Name_B;
	}

	/**
     * @description Method to parsse the JSON response received from Xero 
     * @return PaymentWrapper
     * @param  json
    */
	public static PaymentWrapper parse(String json) {
		return (PaymentWrapper) System.JSON.deserialize(json, PaymentWrapper.class);
	}
}