@isTest
public with sharing class ReservedWordSerializerTest {

    @isTest
    static void testDataForMap() {
        String str =		'{'+
		'  "Id": "4a0b3db9-dd9a-4a5d-941b-58c6215d1134",'+
		'  "Status": "OK",'+
		'  "ProviderName": "Salesforce Application",'+
		'  "DateTimeUTC": "/Date(1684831274579)/",'+
		'  "Invoices": ['+
		'    {'+
		'      "Type": "ACCREC",'+
		'      "InvoiceID": "09ff256b-b252-4e00-ac96-abc2237ec47f",'+
		'      "InvoiceNumber": "INV-0051",'+
		'      "Reference": "001Dn00000Qc9GaIAJ",'+
		'      "Prepayments": [],'+
		'      "Overpayments": [],'+
		'      "AmountDue": 0.00,'+
		'      "AmountPaid": 0.00,'+
		'      "SentToContact": false,'+
		'      "CurrencyRate": 1.0000000000,'+
		'      "TotalDiscount": 0.00,'+
		'      "IsDiscounted": true,'+
		'      "HasAttachments": false,'+
		'      "HasErrors": false,'+
		'      "Attachments": [],'+
		'      "InvoicePaymentServices": [],'+
		'      "Contact": {'+
		'        "ContactID": "37d78e0c-cd12-4dba-b518-8043c8b28480",'+
		'        "ContactStatus": "ACTIVE",'+
		'        "Name": "Test Account BK6",'+
		'        "FirstName": "Test",'+
		'        "LastName": "Contact",'+
		'        "EmailAddress": "bhagyashree.k@kandisatech.com",'+
		'        "BankAccountDetails": "",'+
		'        "Addresses": ['+
		'          {'+
		'            "AddressType": "STREET",'+
		'            "City": "",'+
		'            "Region": "",'+
		'            "PostalCode": "",'+
		'            "Country": ""'+
		'          },'+
		'          {'+
		'            "AddressType": "POBOX",'+
		'            "AddressLine1": "test 123",'+
		'            "City": "mum",'+
		'            "Region": "mh",'+
		'            "PostalCode": "852963",'+
		'            "Country": "in"'+
		'          }'+
		'        ],'+
		'        "Phones": ['+
		'          {'+
		'            "PhoneType": "DEFAULT",'+
		'            "PhoneNumber": "",'+
		'            "PhoneAreaCode": "",'+
		'            "PhoneCountryCode": ""'+
		'          },'+
		'          {'+
		'            "PhoneType": "DDI",'+
		'            "PhoneNumber": "",'+
		'            "PhoneAreaCode": "",'+
		'            "PhoneCountryCode": ""'+
		'          },'+
		'          {'+
		'            "PhoneType": "FAX",'+
		'            "PhoneNumber": "",'+
		'            "PhoneAreaCode": "",'+
		'            "PhoneCountryCode": ""'+
		'          },'+
		'          {'+
		'            "PhoneType": "MOBILE",'+
		'            "PhoneNumber": "",'+
		'            "PhoneAreaCode": "",'+
		'            "PhoneCountryCode": ""'+
		'          }'+
		'        ],'+
		'        "UpdatedDateUTC": "/Date(1684420181097+0000)/",'+
		'        "ContactGroups": [],'+
		'        "IsSupplier": false,'+
		'        "IsCustomer": true,'+
		'        "SalesTrackingCategories": [],'+
		'        "PurchasesTrackingCategories": [],'+
		'        "ContactPersons": [],'+
		'        "HasValidationErrors": false'+
		'      },'+
		'      "DateString": "2023-04-18T00:00:00",'+
		'      "Date": "/Date(1681776000000+0000)/",'+
		'      "DueDateString": "2023-04-21T00:00:00",'+
		'      "DueDate": "/Date(1682035200000+0000)/",'+
		'      "BrandingThemeID": "f04ccf02-5a40-4ee2-a786-d6b97a34b8f4",'+
		'      "Status": "DRAFT",'+
		'      "LineAmountTypes": "Exclusive",'+
		'      "LineItems": ['+
		'        {'+
		'          "Description": "tst1234",'+
		'          "UnitAmount": 0.00,'+
		'          "TaxAmount": 0.00,'+
		'          "LineAmount": 0.00,'+
		'          "Tracking": [],'+
		'          "Quantity": 15.0000,'+
		'          "DiscountRate": 85.00,'+
		'          "LineItemID": "a21423b7-c179-42f5-b2ec-17f9ce8f7804",'+
		'          "DiscountAmount": 0.0000,'+
		'          "ValidationErrors": []'+
		'        }'+
		'      ],'+
		'      "SubTotal": 0.00,'+
		'      "TotalTax": 0.00,'+
		'      "Total": 0.00,'+
		'      "UpdatedDateUTC": "/Date(1684420182133+0000)/",'+
		'      "CurrencyCode": "USD"'+
		'    }'+
		'  ]'+
		'}';
        
        Object input = Json.deserializeUntyped(str);
        
        test.startTest();
        	ReservedWordSerializer ob = new ReservedWordSerializer(input);
        	ob.getAsString();
			System.assertNotEquals(null, ob,'Success');
        test.stopTest();
    }
    
    @isTest
    static void testDataForList() {
        String str =		'{'+
		'  "Id": "4a0b3db9-dd9a-4a5d-941b-58c6215d1134",'+
		'  "Status": "OK",'+
		'  "ProviderName": "Salesforce Application",'+
		'  "DateTimeUTC": "/Date(1684831274579)/",'+
		'  "Invoices": ['+
		'    {'+
		'      "Type": "ACCREC",'+
		'      "InvoiceID": "09ff256b-b252-4e00-ac96-abc2237ec47f",'+
		'      "InvoiceNumber": "INV-0051",'+
		'      "Reference": "001Dn00000Qc9GaIAJ",'+
		'      "Prepayments": [],'+
		'      "Overpayments": [],'+
		'      "AmountDue": 0.00,'+
		'      "AmountPaid": 0.00,'+
		'      "SentToContact": false,'+
		'      "CurrencyRate": 1.0000000000,'+
		'      "TotalDiscount": 0.00,'+
		'      "IsDiscounted": true,'+
		'      "HasAttachments": false,'+
		'      "HasErrors": false,'+
		'      "Attachments": [],'+
		'      "InvoicePaymentServices": [],'+
		'      "Contact": {'+
		'        "ContactID": "37d78e0c-cd12-4dba-b518-8043c8b28480",'+
		'        "ContactStatus": "ACTIVE",'+
		'        "Name": "Test Account BK6",'+
		'        "FirstName": "Test",'+
		'        "LastName": "Contact",'+
		'        "EmailAddress": "bhagyashree.k@kandisatech.com",'+
		'        "BankAccountDetails": "",'+
		'        "Addresses": ['+
		'          {'+
		'            "AddressType": "STREET",'+
		'            "City": "",'+
		'            "Region": "",'+
		'            "PostalCode": "",'+
		'            "Country": ""'+
		'          },'+
		'          {'+
		'            "AddressType": "POBOX",'+
		'            "AddressLine1": "test 123",'+
		'            "City": "mum",'+
		'            "Region": "mh",'+
		'            "PostalCode": "852963",'+
		'            "Country": "in"'+
		'          }'+
		'        ],'+
		'        "Phones": ['+
		'          {'+
		'            "PhoneType": "DEFAULT",'+
		'            "PhoneNumber": "",'+
		'            "PhoneAreaCode": "",'+
		'            "PhoneCountryCode": ""'+
		'          },'+
		'          {'+
		'            "PhoneType": "DDI",'+
		'            "PhoneNumber": "",'+
		'            "PhoneAreaCode": "",'+
		'            "PhoneCountryCode": ""'+
		'          },'+
		'          {'+
		'            "PhoneType": "FAX",'+
		'            "PhoneNumber": "",'+
		'            "PhoneAreaCode": "",'+
		'            "PhoneCountryCode": ""'+
		'          },'+
		'          {'+
		'            "PhoneType": "MOBILE",'+
		'            "PhoneNumber": "",'+
		'            "PhoneAreaCode": "",'+
		'            "PhoneCountryCode": ""'+
		'          }'+
		'        ],'+
		'        "UpdatedDateUTC": "/Date(1684420181097+0000)/",'+
		'        "ContactGroups": [],'+
		'        "IsSupplier": false,'+
		'        "IsCustomer": true,'+
		'        "SalesTrackingCategories": [],'+
		'        "PurchasesTrackingCategories": [],'+
		'        "ContactPersons": [],'+
		'        "HasValidationErrors": false'+
		'      },'+
		'      "DateString": "2023-04-18T00:00:00",'+
		'      "Date": "/Date(1681776000000+0000)/",'+
		'      "DueDateString": "2023-04-21T00:00:00",'+
		'      "DueDate": "/Date(1682035200000+0000)/",'+
		'      "BrandingThemeID": "f04ccf02-5a40-4ee2-a786-d6b97a34b8f4",'+
		'      "Status": "DRAFT",'+
		'      "LineAmountTypes": "Exclusive",'+
		'      "LineItems": ['+
		'        {'+
		'          "Description": "tst1234",'+
		'          "UnitAmount": 0.00,'+
		'          "TaxAmount": 0.00,'+
		'          "LineAmount": 0.00,'+
		'          "Tracking": [],'+
		'          "Quantity": 15.0000,'+
		'          "DiscountRate": 85.00,'+
		'          "LineItemID": "a21423b7-c179-42f5-b2ec-17f9ce8f7804",'+
		'          "DiscountAmount": 0.0000,'+
		'          "ValidationErrors": []'+
		'        }'+
		'      ],'+
		'      "SubTotal": 0.00,'+
		'      "TotalTax": 0.00,'+
		'      "Total": 0.00,'+
		'      "UpdatedDateUTC": "/Date(1684420182133+0000)/",'+
		'      "CurrencyCode": "USD"'+
		'    }'+
		'  ]'+
		'}';
        
        Object input = Json.deserializeUntyped(str);

        map<String,Object> mp = (map<String,Object>)input;
        List<Object> ls = mp.values();
        test.startTest();
        	ReservedWordSerializer ob = new ReservedWordSerializer(ls);
           ReservedWordSerializer ob1 = new ReservedWordSerializer(mp,str);
			System.assertNotEquals(null, ob1,'Success');
			System.assertNotEquals(null, ob,'Success');

        test.stopTest();
    }
    
    @isTest
    static void testDataForString(){
        test.startTest();
			Object input = 'Any String';
         	ReservedWordSerializer ob = new ReservedWordSerializer(input);
			 System.assertNotEquals(null, ob,'Success');

        test.stopTest();
    }
    
    @isTest
    static void testDataForNull(){
        Object input = NULL;
        test.startTest();
         	ReservedWordSerializer ob = new ReservedWordSerializer(input);
			 System.assertNotEquals(null, ob,'Success');

        test.stopTest();
    }
}