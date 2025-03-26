import {LightningElement, api, track} from "lwc";
import {NavigationMixin} from "lightning/navigation";
import {RefreshEvent} from "lightning/refresh";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getInvoiceConfiguration from "@salesforce/apex/InvoiceCreationController.getInvoiceConfiguration";
import getProductSyncConfig from "@salesforce/apex/InvoiceCreationController.getProductSyncConfig";
import xeroConCreation from "@salesforce/apex/InvoiceCreationController.createXeroContact";
import xeroItemCreation from "@salesforce/apex/InvoiceCreationController.createXeroItem";
import xeroinvCreation from "@salesforce/apex/InvoiceCreationController.createXeroInvoice";
import insertLog from "@salesforce/apex/Utils.insertLog";



export default class InvoiceMainCmp extends NavigationMixin(LightningElement) {

    _recId;

    @api get recId () {

        return this._recId;

    }
    
    set recId (value) {

        this._recId = value;

    }

    @track currentStep = "Opp";

    @track contactOptionMain = "";

    @track isLoading = false;

    @track invoiceOppCmp = true;

    @track invoiceContactCmp = false;

    @track invoiceCmp = false;

    @track lineitemOption;

    @track accountId;

    @track accountName;

    @track cancelButtonLabel = "Cancel";

    @track nextButtonLabel = "Next";

    @track cancelDisable = false;

    @track nextDisable = false;

    @track accountDetails = [];

    @track contactDetails = [];

    @track contactPersonDetails = [];

    @track showModal = false;

    @track showNegativeButton = true;

    @track showPositiveButton = true;

    @track positiveButtonLabel = "Save";

    @track negativeButtonLabel = "Cancel";

    @track newContact;

    @track contactCreated = false;

    @track conXeroId;

    @track conXerosfId;

    @track invCreation = "";

    @track invoiceData = "";

    @track isLoaded = true;

    @track invcreationOptions;

    @track invoiceConfig;

    @track currencyCode;

    @track createProInXero = false;

    @track createProInSales = false;

    @track newProducts = [];

    @track showContactButton = true;

    @track success;

    @track newXeroContact = false;

    @track errorList = [];

    @track showLoading = false;

    @track oppInv = true;

    connectedCallback () {

        if (typeof this.recId === "undefined" || this.recId === "" || this.recId === null) {

            const strUrl = window.location.href,
                urlParamSearch = new URLSearchParams(strUrl);
                this._recId = urlParamSearch.get("recid");

            if(this._recId.startsWith("001")){
                this.invoiceOppCmp = false;
                this.invoiceContactCmp = true;
                this.oppInv = false;
                this.currentStep = 'Contact';
                this.accountId = this._recId;
                this.lineitemOption = 'blank';
            }

        }
    
        this.getProductSyncConfig();
        this.invoiceConfiguration();

    }

    getProductSyncConfig () {

        getProductSyncConfig({"recId": this._recId}).
            then((result) => {

                this.createProInXero = result.createProInXero;
                this.createProInSales = result.createProInSales;

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


    invoiceConfiguration () {

        getInvoiceConfiguration({}).
            then((result) => {

                this.invoiceConfig = result;
                const options = [];

                if (this.invoiceConfig.draft) {

                    options.push({"label": "Create Draft Invoice in Xero",
                        "value": "DRAFT"});

                }

                if (this.invoiceConfig.submit) {

                    options.push({"label": "Create Invoice & Submit for Approval",
                        "value": "SUBMITTED"});

                }

                if (this.invoiceConfig.approved) {

                    options.push({"label": "Create Approved Invoice in Xero",
                        "value": "AUTHORISED"});

                }

                if (this.invoiceConfig.approvedEmail) {

                    options.push({"label": "Create Approved Invoice & Email via Xero",
                        "value": "ApprovedEmail"});

                }

                this.invcreationOptions = options;

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

    closeModal () {

        this.showModal = false;

    }

    saveModal () {

        if (this.invCreation) {

            if (this.invCreation === "DRAFT") {

                this.template.querySelector("c-invoice-creation-cmp").handledraftSave();

            } else if (this.invCreation === "SUBMITTED") {

                this.template.querySelector("c-invoice-creation-cmp").handleApprovedSave();

            } else if (this.invCreation === "AUTHORISED") {

                this.template.querySelector("c-invoice-creation-cmp").handleApprovedSave();

            } else if (this.invCreation === "ApprovedEmail") {

                this.template.querySelector("c-invoice-creation-cmp").handleApprovedSave();

            }

        } else {

            this.showToast(
                "Error",
                "Please select value first to proceed further",
                "error",
                "dismissable"
            );

        }

    }

    nextClick () {

        if (this.currentStep === "Opp") {

            this.isLoading = true;
            this.invoiceOppCmp = false;
            this.invoiceContactCmp = true;
            this.currentStep = "Contact";
            this.isLoading = false;
            this.cancelButtonLabel = "Previous";
            this.showContactButton = true;
            if (typeof this.newContact === "undefined") {

                this.nextDisable = true;

            } else {

                this.nextDisable = false;

            }

        } else if (this.currentStep === "Contact") {

            if (this.newContact) {

                this.template.querySelector("c-invoice-contact-cmp").checkData();

            } else {

                this.isLoading = true;
                this.invoiceContactCmp = false;
                this.invoiceCmp = true;
                this.currentStep = "Invoice";
                this.isLoading = false;
                this.cancelButtonLabel = "Previous";
                this.nextButtonLabel = "Save";
                this.showContactButton = true;

            }


        } else if (this.currentStep === "Invoice") {

            this.showModal = true;

        }

    }

    handleSuccess (event) {

        try{
            this.success = event.detail;
            if (this.success) {

                this.isLoading = true;
                this.invoiceContactCmp = false;
                this.invoiceCmp = true;
                this.currentStep = "Invoice";
                this.isLoading = false;
                this.cancelButtonLabel = "Previous";
                this.nextButtonLabel = "Save";
                this.showContactButton = true;

            }
        }catch(error){
            this.error = error;
        }

    }

    CancelClick () {

        if (this.currentStep === "Invoice") {

            this.isLoading = true;
            this.currentStep = "Contact";
            this.invoiceCmp = false;
            this.invoiceContactCmp = true;
            this.nextButtonLabel = "Next";
            this.isLoading = false;
            this.showContactButton = true;
            if(!this.oppInv){
                this.cancelButtonLabel = "Cancel";
            }

        } else if (this.currentStep === "Contact") {

            if(!this.oppInv){
                this[NavigationMixin.GenerateUrl]({
                    "attributes": {
                        "actionName": "view",
                        "recordId": this.recId
                    },
                    "type": "standard__recordPage"
                }).then((url) => {
    
                    window.open(
                        url,
                        "_self"
                    );
    
                });
            }else{
                this.isLoading = true;
                this.contactPersonDetails = [];
                this.contactDetails = [];
                this.accountDetails = [];
                this.currentStep = "Opp";
                this.invoiceContactCmp = false;
                this.invoiceOppCmp = true;
                this.isLoading = false;
                this.nextDisable = false;
                this.nextButtonLabel = "Next";
                this.cancelButtonLabel = "Cancel";
                this.showContactButton = true;
            }

        } else if (this.currentStep === "Opp") {

            this[NavigationMixin.GenerateUrl]({
                "attributes": {
                    "actionName": "view",
                    "recordId": this.recId
                },
                "type": "standard__recordPage"
            }).then((url) => {

                window.open(
                    url,
                    "_self"
                );

            });

        }

    }

    handleErrorMessage (event) {

        try{
            this.errorList = event.detail;
        }catch(error){
            this.error = error;
        }
    }

    handleenablebutton (event) {

        try{
            this.showContactButton = event.detail;
        }catch(error){
            this.error = error;
        }
    }

    disableshowContact (event) {

        try{
            this.showContactButton = event.detail;
        }catch(error){
            this.error = error;
        }
    }

    // To get the invoice option for line items
    handleinvoiceoptionChange (event) {

        try{
            
            this.lineitemOption = event.detail;
        }catch(error){
            this.error = error;
        }

    }

    handleaccountId (event) {

        try{
            this.accountId = event.detail;
            
        }catch(error){
            this.error = error;
        }

    }

    handleaccountName (event) {

        try{

            this.accountName = event.detail;
        }catch(error){
            this.error = error;
        }

    }

  

    handleaccountdetails (event) {

        try{
            this.accountDetails = JSON.parse(event.detail);

        }catch(error){
            this.error = error;
        }
        
    }
    
    handlecontactdetails (event) {
        
        try{
            
            if (event.detail !== null || event.detail.length !== 0) {
            
                this.contactDetails = JSON.parse(event.detail);

            }else {

                this.contactDetails = [];

            }
        }catch(error){
            this.error = error;
        }
        
    }
    
    handleconpersondetails (event) {
        
        try{
            
            if (event.detail !== null || event.detail.length !== 0) {
    
                this.contactPersonDetails = JSON.parse(event.detail);
    
            }else {
    
                this.contactPersonDetails = [];
    
            }
        }catch(error){
            this.error = error;
        }

    }

    invCreationhandleChange (event) {

        try{

            this.invCreation = event.target.value;
        }catch(error){
            this.error = error;
        }

    }

    handledraftSave (event) {

        const ele = event.detail,
            num0 = 0,
            num1 = 1;
        if (!ele.save) {

            if (ele.errors.length > num0) {

                let err = "";

                ele.errors.forEach((element) => {

                    if (err.length === num0) {

                        err += element;

                    } else {

                        err += `, ${element}`;

                    }

                });
                this.showToast(
                    "Error",
                    `Please enter valid value in ${err}`,
                    "error",
                    "dismissable"
                );

            } else if (ele.fields.length > num0) {

                let msg = "";
                for (let ind = 0; ind < ele.fields.length; ind += num1) {

                    msg += ele.fields[ind];
                    if (ind !== ele.fields.length - num1) {

                        msg += ", ";

                    }

                }
                this.showToast(
                    "Error",
                    `Please fill required fields ${msg}`,
                    "error",
                    "dismissable"
                );

            }

        } else if (ele.save) {

            this.showModal = false;
            this.getInvoiceData();

        }

    }

    disableButtons (event) {

        try{

            this.nextDisable = event.detail;
        }catch(error){
            this.error = error;
        }

    }

    handlecontactOption (event) {

        try{
            this.contactOptionMain = event.detail;

        }catch(error){
            this.error = error;
        }

    }

    handleapprovedSave (event) {

        const ele = event.detail,
            num0 = 0,
            num1 = 1;

        try{

            if (!ele.save) {
    
                if (ele.errors.length > num0) {
    
                    let err = "";
    
                    ele.errors.forEach((element) => {
    
                        if (err.length === num0) {
    
                            err += element;
    
                        } else {
    
                            err += `, ${element}`;
    
                        }
    
                    });
                    this.showToast(
                        "Error",
                        `Please enter valid value in ${err}`,
                        "error",
                        "dismissable"
                    );
    
                } else if (ele.fields.length > num0) {
    
                    let msg = "\n";
                    for (let ind = 0; ind < ele.fields.length; ind += num1) {
    
                        msg += ele.fields[ind];
                        if (ind !== ele.fields.length - num1) {
    
                            msg += ", ";
    
                        }
    
                    }
                    this.showToast(
                        "Error",
                        `Please fill required fields ${msg}`,
                        "error",
                        "dismissable"
                    );
    
                }
    
            } else if (ele.save) {
    
                this.showModal = false;
                this.getInvoiceData();
    
            }
        }catch(error){
            this.error = error;
        }

    }

    getInvoiceData () {

        this.template.querySelector("c-invoice-creation-cmp").invoiceData();

    }


    handleinvoiceData (event) {

        this.invoiceData = event.detail;
        this.currencyCode = this.invoiceData.currencyCode;
        const itemArr = [],
            num0 = 0,
            test = [],
            xlineItem = this.invoiceData.lineItems;
        try {

            xlineItem.forEach((element) => {

                if (!element.xeroItemID && element.productCode) {

                    itemArr.push(element);
                    test.push(element.productCode);

                }

            });

            if (itemArr.length > num0) {

                if (this.createProInXero) {

                    this.createItems(itemArr);

                } else {

                    this.invoiceData.lineItems.forEach((ele) => {

                        if (test.includes(ele.productCode)) {

                            ele.productCode = "";

                        }

                    });
                    // });
                    if (this.newContact && !this.contactCreated) {

                        this.createXeroContact();

                    } else {

                        this.createXeroInvoice();

                    }

                }

            } else if (this.newContact && !this.contactCreated) {

                this.createXeroContact();

            } else {

                this.createXeroInvoice();

            }

        } catch (error) {

            this.error = error;

        }

    }

    handlecontactSelection (event) {

        const ele = event.detail;
        this.newContact = ele.newContact;
        this.conXeroId = ele.conId;
        this.conXerosfId = ele.consfId;

    }

    createItems (itemArr) {

        this.isLoaded = false;
        this.showLoading = true;
        xeroItemCreation({
            "lineItemData": JSON.stringify(itemArr)
        }).
            then((result) => {

                if (result.successFlag) {

                    if (this.newContact && !this.contactCreated) {

                        this.createXeroContact();

                    } else {

                        this.createXeroInvoice();

                    }

                } else {

                    this.showToast(
                        "Error while Creating Products in Xero",
                        result.message,
                        "error",
                        "dismissable"
                    );

                }
                this.isLoaded = true;
                this.showLoading = false;

            }).
            catch((error) => {

                this.error = error;
                this.isLoaded = true;
                this.showLoading = false;

            });

    }

    createXeroContact () {

        // Debugger;

        this.isLoaded = false;
        this.showLoading = true;
        try{

            xeroConCreation({
                "accdetails": JSON.stringify(this.accountDetails),
                "conPersonDetails": JSON.stringify(this.contactPersonDetails),
                "condetails": JSON.stringify(this.contactDetails),
                "oppId": this.recId
            }).
                then((result) => {
    
                    if (result.successFlag) {
    
                        this.conXeroId = result.xeroContactId;
                        this.conXerosfId = result.xeroContactsfId;
                        this.contactCreated = true;
                        this.createXeroInvoice();
    
                    } else {
    
                        this.showToast(
                            "Error while Creating Contact in Xero",
                            result.message,
                            "error",
                            "dismissable"
                        );
    
                    }
                    this.isLoaded = true;
                    this.showLoading = false;
    
                }).
                catch((error) => {
    
                    this.error = error;
                    this.isLoaded = true;
                    this.showLoading = false;
    
                });
        }catch(error){
            this.error = error;
        }

    }

    createXeroInvoice () {

        // this.isLoaded = false;
        this.showLoading = true;
        xeroinvCreation({"contactId": this.conXerosfId,
            "currencyCode": this.currencyCode,
            "invoiceData": JSON.stringify(this.invoiceData),
            "state": this.invCreation,
            "xeroContactId": this.conXeroId}).
            then((result) => {

                if (result.successFlag) {

                    this[NavigationMixin.Navigate]({
                        "attributes": {
                            "actionName": "view",
                            "objectApiName": "Invoice__c",
                            "recordId": result.message
                        },
                        "type": "standard__recordPage"
                    });
                    // RefreshViews();
                    this.dispatchEvent(new RefreshEvent());


                } else {

                    this.showToast(
                        "Error while Creating Invoice in Xero",
                        result.message,
                        "error",
                        "dismissable"
                    );
                }
                // this.isLoaded = true;
                this.showLoading = false;

            }).
            catch((error) => {

                this.error = error;
                this.isLoaded = true;
                this.showLoading = false;
                this.showToast(
                    "Error while Creating Invoice in Xero",
                    error.body.message,
                    "error",
                    "dismissable"
                );

            });

    }

    showToast (title, message, variant, mode) {

        const evt = new ShowToastEvent({
            title,
            message,
            variant,
            mode
        });
        this.dispatchEvent(evt);

    }

}