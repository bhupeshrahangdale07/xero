import {LightningElement, api, track} from "lwc";
import {NavigationMixin} from "lightning/navigation";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getXeroContacts from "@salesforce/apex/InvoiceCreationController.getXeroContacts";
import getAccountName from "@salesforce/apex/InvoiceCreationController.getAccountName";
import insertLog from "@salesforce/apex/Utils.insertLog";

export default class InvoiceContactCmp extends NavigationMixin(LightningElement) {

    @api recordId;

    @api accountId;

    @api accountName;

    @api contactOption;

    @api previousAccDetails;

    @track previousContactDetails;

    @track previousContactPersonDetails;

    @track optionSelection = true;

    @track newContact;

    @track sectionValue = "Options of Xero Contact for this Invoice";

    @track xeroContact;

    @track accdetails;

    @track condetails;
    @track error;

    @api get previousConDetails () {

        return this.previousContactDetails;

    }

    set previousConDetails (value) {

        this.previousContactDetails = value;

    }

    @api get previousConPersonDetails () {

        return this.previousContactPersonDetails;

    }

    set previousConPersonDetails (value) {

        this.previousContactPersonDetails = value;

    }

    connectedCallback () {

        if (this.recordId !== null || typeof this.recordId !== "undefined") {

            this.fetchXeroContacts();

            if (typeof this.accountName === "undefined") {
                this.fetchAccountName();
            }

        }


    }

    fetchAccountName () {
        getAccountName({
            "accountId": this.accountId
        }).then((result) => {
            if(result){
                this.accountName = result;
                this.dispatchEvent(new CustomEvent(
                    "accountname",
                    {
                        "detail": this.accountName
                    }
                ));
            }
        }).
        catch((error) => {
    
            if(error){
            
                let errorMsg;
                if (Array.isArray(error.body)) {
                    errorMsg = error.body.map((e) => e.message).join(", ");
                } else if (typeof error.body.message === "string") {
                    let err = JSON.parse(error.body.message);
                    if(err.hasOwnProperty('KTXero__Exception_Message__c')){
                        errorMsg = "Error: "+err.KTXero__Exception_Message__c;
                        insertLog({
                            exceptionLog: error.body.message
                        }).then(result => {
                            this.errorFlag = true;
                        });
                    }else{
                        errorMsg = "Error: "+JSON.stringify(error.body.message);
                    }

                } else{
                    errorMsg = "Error: "+JSON.stringify(error);
                }

                this.showToast("Something Went Wrong", errorMsg, "error");
            }

        });
    }

    fetchXeroContacts () {

        try{

            getXeroContacts({"accountId": this.accountId,
                "recordId": this.recordId}).
                then((result) => {
    
                    if (result.id) {
                        
                        const res = result;
                        res.URL = `/${res.id}`;
                        this.xeroContact = res;
    
                    } else {
    
                        const existingCon = this.template.querySelector("[data-id=\"existingContact\"]");
                        existingCon.disabled = true;
    
                    }
    
                    if (typeof this.contactOption !== "undefined") {
    
                        if (this.contactOption) {
    
                            const newCon = this.template.querySelector("[data-id=\"new\"]");
                            newCon.checked = true;
                            this.newContact = true;
                            this.dispatchEvent(new CustomEvent(
                                "enabledbutton",
                                {
                                    "detail": true
                                }
                            ));
    
    
                        } else {
    
                            const existingCon = this.template.querySelector("[data-id=\"existingContact\"]");
                            existingCon.checked = true;
    
                        }
    
                    }
    
                    if (typeof this.previousAccDetails !== "undefined" || this.previousAccDetails !== null ) {
    
                        this.accdetails = this.previousAccDetails;
    
                    }
    
                    if (typeof this.previousContactDetails !== "undefined") {
    
                        this.condetails = this.previousContactDetails;
    
                    }
    
                }).
                catch((error) => {
    
                    this.accounts = "undefined";
                    if(error){
                    
                        let errorMsg;
                        if (Array.isArray(error.body)) {
                            errorMsg = error.body.map((e) => e.message).join(", ");
                        } else if (typeof error.body.message === "string") {
                            let err = JSON.parse(error.body.message);
                            if(err.hasOwnProperty('KTXero__Exception_Message__c')){
                                errorMsg = "Error: "+err.KTXero__Exception_Message__c;
                                insertLog({
                                    exceptionLog: error.body.message
                                }).then(result => {
                                    this.errorFlag = true;
                                });
                            }else{
                                errorMsg = "Error: "+JSON.stringify(error.body.message);
                            }
    
                        } else{
                            errorMsg = "Error: "+JSON.stringify(error);
                        }
    
                        this.showToast("Something Went Wrong", errorMsg, "error");
                    }
    
                });
        }catch(error){
            this.error = error;
        }

    }

    onhandleChange (event) {

        const ele = {"conId": "",
                "consfId": "",
                "newContact": true},
            numZero = 0,
            option = event.target.value;
        this.optionSelection = false;
        try{

            if (option === "new") {
    
                this.previousContactDetails = [];
                this.previousContactPersonDetails = [];
                this.condetails = [];
                if (Object.keys(this.accdetails).length !== numZero) {
    
                    this.accdetails = [];
    
                }
                this.newContact = true;
                this.sectionValue = "Map Xero Contact Details and Salesforce Detail";
                ele.newContact = true;
                ele.conId = "";
                ele.consfId = "";
    
                this.dispatchEvent(new CustomEvent(
                    "enabledbutton",
                    {
                        "detail": true
                    }
                ));
    
                this.dispatchEvent(new CustomEvent(
                    "accountdetails",
                    {
                        "detail": this.previousAccDetails
                    }
                ));
    
                this.dispatchEvent(new CustomEvent(
                    "contactdetails",
                    {
                        "detail": this.previousContactDetails
                    }
                ));
    
                this.dispatchEvent(new CustomEvent(
                    "contactpersonsdetails",
                    {
                        "detail": this.previousContactPersonDetails
                    }
                ));
    
            } else if (option === "existingContact") {
    
                this.optionSelection = true;
                this.newContact = false;
                ele.newContact = false;
                ele.conId = this.xeroContact.referenceId;
                ele.consfId = this.xeroContact.id;
    
                const accNewElement = {"accCity": this.xeroContact.townCity,
                        "accCountry": this.xeroContact.country,
                        "accId": this.accountId,
                        "accName": this.xeroContact.companyName,
                        "accPostalCode": this.xeroContact.postalZipCode,
                        "accState": this.xeroContact.stateRegion,
                        "accStreet": this.xeroContact.streetAddress},
                    conNewElement = {"conEmail": this.xeroContact.emailAddress,
                        "conFirstName": this.xeroContact.firstName,
                        "conId": "",
                        "conLastName": this.xeroContact.lastName,
                        "conName": `${this.xeroContact.firstName} ${this.xeroContact.lastName}`};
    
                this.dispatchEvent(new CustomEvent(
                    "accountdetails",
                    {
                        "detail": JSON.stringify(accNewElement)
                    }
                ));
    
                this.dispatchEvent(new CustomEvent(
                    "contactdetails",
                    {
                        "detail": JSON.stringify(conNewElement)
                    }
                ));
    
            }
    
            this.dispatchEvent(new CustomEvent(
                "contactselection",
                {
                    "detail": ele
                }
            ));
    
            this.dispatchEvent(new CustomEvent(
                "disablebutton",
                {
                    "detail": false
                }
            ));
        }catch(error){
            this.error = error;
        }

    }

    handleSuccess (event) {

        try{

            this.dispatchEvent(new CustomEvent(
                "success",
                {
                    "detail": event.detail
                }
            ));
        }catch(error){
            this.error = error;
        }

    }


    handleaccountdetails (event) {

        try{
            this.dispatchEvent(new CustomEvent(
            "accountdetails",
            {
                "detail": event.detail
            }
        ));
        }catch(error){
            this.error = error;
        }
            
    }
        
    handlecontactdetails (event) {
            
        try{

            this.dispatchEvent(new CustomEvent(
                "contactdetails",
                {
                    "detail": event.detail
                }
            ));
        }catch(error){
            this.error = error;
        } 
            
    }
        
    handleconpersondetails (event) {
            
        try{

            this.dispatchEvent(new CustomEvent(
                "contactpersonsdetails",
                {
                    "detail": event.detail
                }
            ));
        }catch(error){
            this.error = error;
        }

    }

    xeroConClick () {

        try{

            this[NavigationMixin.Navigate]({
                "type": "standard__recordPage",
                "attributes": {
                    "actionName": "view",
                    "objectApiName": "Xero_Contact__c",
                    "recordId": this.xeroContact.id
                }
            });
        }catch(error){
            this.error = error;
        }

    }

    disableButtons (event) {

        try{

            this.dispatchEvent(new CustomEvent(
                "disablebutton",
                {
                    "detail": event.detail
                }
            ));
        }catch(error){
            this.error = error;
        }

    }

    backEvent () {

        this.fetchXeroContacts();
        this.newContact = false;
        this.optionSelection = true;
        this.sectionValue = "Options of Xero Contact for this Invoice";
        this.dispatchEvent(new CustomEvent(
            "enablebutton",
            {
                "detail": false
            }
        ));

    }

    @api
    checkData () {

        this.template.querySelector("c-invoice-xero-con-creation-cmp").checkAccountName();

    }

    showToast (title, message, variant) {

        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);

    }

}