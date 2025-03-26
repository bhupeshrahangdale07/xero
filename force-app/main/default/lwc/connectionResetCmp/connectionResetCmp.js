import {LightningElement, track} from "lwc";
import {NavigationMixin} from "lightning/navigation";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import assignWebhhokPermission from "@salesforce/apex/SetupConfigController.assignWebhhokPermission";
import getSecureSiteURL from "@salesforce/apex/SetupConfigController.getSecureSiteURL";
import getSites from "@salesforce/apex/SetupConfigController.getSites";
import getSitesConfigURL from "@salesforce/apex/Utils.getSFURL";
import getTenants from "@salesforce/apex/SetupConfigController.getTenants";
import getXeroConnection from "@salesforce/apex/SetupConfigController.getXeroConnection";
import saveXeroConnection from "@salesforce/apex/SetupConfigController.saveXeroConnection";
import scheduleRefreshToken from "@salesforce/apex/SetupConfigController.scheduleRefreshToken";
import syncAccounts from "@salesforce/apex/XeroSyncController.xeroAccountsSync";
import syncInvoiceTemplates from "@salesforce/apex/InvoiceConfigurationController.xeroInvoiceTemplateSync";
import syncTaxRate from "@salesforce/apex/InvoiceConfigurationController.xeroTaxRateSync";
import syncTrackingCategories from "@salesforce/apex/InvoiceConfigurationController.xeroTrackingCategorySync";
import insertLog from "@salesforce/apex/Utils.insertLog";

export default class ConnectionResetCmp extends NavigationMixin(LightningElement) {

    @track showLoading = false;

    @track showXeroConnection = false;

    @track showXeroPermission = false;

    @track showWebhook = false;

    @track disableSave = true;

    @track disableAuth = false;

    @track showNext = false;

    @track showNext2 = false;

    @track nameCredentialURL;

    @track tenantOptions;

    @track permissionSets;

    @track two;

    @track three;

    @track tabs = {
        "oneActive": false,
        "twoActive": false
    };

    key;

    secret;

    @track xeroConnection;

    @track authURL;

    @track steps = {
        "fourStep": true,
        "oneStep": false,
        "threeStep": true,
        "twoStep": true
    };


    @track showModal = false;

    @track layoutData = [];

    @track value = [];

    @track disablePermissionSave = false;

    @track disableLayoutSave = false;

    @track sitesURL;

    @track siteOptions;

    @track showSiteCreation = false;

    @track siteVal;

    @track siteSecureURL;

    @track webhookKey;

    @track disableWebhookSave;

    @track disableWebhookInput = false;

    @track redirectURL = "";

    @track siteDetails;

    @track guestUserId;

    @track showWebhookSteps = false;

    connectedCallback () {

        this.getRedirectURL();
        this.getConnections();
        this.getAllSites();

    }

    getRedirectURL () {

        getSitesConfigURL({
            "entity": "VFURL"
        }).
            then((result) => {

                if (result) {

                    this.redirectURL = result;

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

                    
                    this.errorFlag = true;
                    this.title = "Something Went Wrong";
                    this.message = errorMsg;
                    this.variant = "error";
                    this.showToast(this.title, this.message, this.variant,"dismissable");
                    this.showLoading = false;
                }

            });

    }

    getConnections () {

        this.showLoading = true;
        this.showXeroConnection = true;
        this.tabs = {};

        getXeroConnection({}).
            then((result) => {

                if (result) {

                    this.xeroConnection = result;

                    if (this.xeroConnection.webhookKey === null ||
                            this.xeroConnection.webhookKey === "" ||
                            typeof this.xeroConnection.webhookKey ===
                            "undefined") {

                        this.showWebhook = false;

                    } else {

                        this.showWebhook = true;

                    }
                    this.tabs = {};

                    this.tabs.oneActive = true;
                    this.one = "active";
                    this.disableSave = false;
                    this.showLoading = false;
                    this.fetchTenants();

                    this.key = this.xeroConnection.clientId;
                    this.secret = this.xeroConnection.clientSecret;

                }
                this.showLoading = false;

            }).
            catch((error) => {

                this.showLoading = false;
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

                    this.showToast("Something Went Wrong", errorMsg, "error","dismissable");
                }

            });

    }


    getAllSites () {

        this.showLoading = true;
        const minLength = 0;
        getSites({}).
            then((result) => {

                if (result.length > minLength) {

                    this.siteDetails = result;
                    const siteOptions = [];
                    result.forEach((element) => {

                        siteOptions.push({"label": element.masterLabel,
                            "value": element.id});

                    });
                    this.siteOptions = siteOptions;

                } else {

                    this.showSiteCreation = true;


                }
                this.showLoading = false;

            }).
            catch((error) => {

                this.showLoading = false;
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

                    this.showToast("Something Went Wrong",errorMsg,"error","dismissable");
                }

            });

    }


    fetchSecureURL (event) {

        this.showLoading = true;
        this.siteVal = event.target.value;
        this.guestUserId = this.siteDetails.find((element) => element.id === event.target.value).guestUserId;
        getSecureSiteURL({
            "siteId": event.target.value
        }).
            then((result) => {

                if (result) {

                    this.siteSecureURL = result;

                } else {

                    this.showToast(
                        "Something Went Wrong",
                        "",
                        "error",
                        "dismissable"
                    );

                }
                this.showLoading = false;

            }).
            catch((error) => {

                this.showLoading = false;
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

                    this.showToast("Something Went Wrong",errorMsg,"error","dismissable");
                }

            });

    }


    updateValue (event) {

        if (event.target.value.trim()) {

            if (event.target.name === "Consumer Secret") {

                this.xeroConnection.clientSecret = event.target.value;

            } else if (event.target.name === "Consumer Key") {

                this.xeroConnection.clientId = event.target.value;

            } else if (event.target.name === "Webhook Key") {

                this.xeroConnection.webhookKey = event.target.value;

            }

        } else {

            this.showToast(
                event.target.name,
                `Enter valid value in ${event.target.name}`,
                "error",
                "dismissable"
            );

        }

    }


    handleWebReset () {

        this.showWebhookSteps = true;
        this.showWebhook = false;

    }


    showInstruction () {

        this.showModal = true;
        this.showPositiveButton = true;
        this.showNegativeButton = false;
        this.positiveButtonLabel = "Close";

    }

    closeModal () {

        this.showModal = false;

    }


    saveTenant () {

        this.showLoading = true;
        this.xeroConnection.authenticated = true;
        this.steps.twoStep = false;
        saveXeroConnection({
            "connectWrap": JSON.stringify(this.xeroConnection)
        }).
            then((result) => {

                if (result.flag) {

                    this.xeroConnection = result.saveResult;
                    this.showToast(
                        "Completed successfully",
                        "Tenant Data Saved Successfully",
                        "success",
                        "dismissable"
                    );
                    this.disableTenantSave = true;
                    this.scheduleRefreshToken();

                    this.fetchXeroTaxRate();

                }
                this.showLoading = false;
                
            }).
            catch((error) => {
                
                this.showLoading = false;
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

                    this.showToast("Something Went Wrong", errorMsg, "error","dismissable");
                }

            });

    }


    scheduleRefreshToken () {

        scheduleRefreshToken({}).
            then((result) => {

                if (result) {

                    this.fetchXeroTaxRate();

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

                    this.showToast("Something Went Wrong", errorMsg, "error","dismissable");
                }

            });

    }

    fetchXeroTaxRate () {

        syncTaxRate({}).
            then((result) => {

                if (result) {

                    if (result.successFlag) {

                        this.fetchXeroTemplates();

                    } else {

                        this.showToast(
                            "Something Went Wrong. ",
                            result.message,
                            "error",
                            "dismissable"
                        );

                    }


                }

            }).
            catch((error) => {

                this.error = error;
                this.showToast(
                    `Something Went Wrong. ${error.body.message}`,
                    error,
                    "error",
                    "dismissable"
                );

            });

    }


    fetchXeroTemplates () {

        syncInvoiceTemplates({}).
            then((result) => {

                if (result) {

                    if (result.successFlag) {

                        this.fetchAccounts();

                    } else {

                        this.showToast(
                            "Something Went Wrong. ",
                            result.message,
                            "error",
                            "dismissable"
                        );

                    }

                }

            }).
            catch((error) => {

                this.error = error;
                this.showToast(
                    `Something Went Wrong. ${error.body.message}`,
                    error,
                    "error",
                    "dismissable"
                );

            });

    }

    fetchAccounts () {

        syncAccounts({}).
            then((result) => {

                if (result) {

                    this.fetchTrackingCategories();

                }

            }).
            catch((error) => {

                // this.error = error;
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

                
                this.errorFlag = true;
                this.title = "Something Went Wrong";
                this.message = errorMsg;
                this.variant = "error";
                this.showToast(this.title, this.message, this.variant, "dismissable");

            });

    }

    fetchTrackingCategories () {

        syncTrackingCategories({}).
            then().
            catch((error) => {

                // this.error = error;
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

                    
                    this.errorFlag = true;
                    this.title = "Something Went Wrong";
                    this.message = errorMsg;
                    this.variant = "error";
                    this.showToast(this.title, this.message, this.variant, "dismissable");
                }
            });

    }

    fetchTenants () {

        this.showLoading = true;
        getTenants({}).
            then((result) => {

                if (result) {

                    const tenantArr = [];
                    result.forEach((element) => {

                        tenantArr.push({"label": element.tenantName,
                            "value": element.tenantId});

                    });
                    this.tenantOptions = tenantArr;

                }
                this.showLoading = false;

            }).
            catch((error) => {

                this.showLoading = false;
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

                    this.showToast("Something Went Wrong", errorMsg, "error","dismissable");
                }

            });

    }


    handleTenantChange (event) {

        this.xeroConnection.tenantId = event.target.value;

    }

    handleReset () {

        this.xeroConnection.consumerKey = this.key;
        this.xeroConnection.consumerSecret = this.secret;
        if (this.xeroConnection.clientId !== "" && this.xeroConnection.clientSecret !== "") {

            saveXeroConnection({
                "connectWrap": JSON.stringify(this.xeroConnection)
            }).
                then((result) => {

                    if (result.flag) {

                        this.xeroConnection = result.saveResult;
                        this.enableReset = true;
                        this.resetLabel = "Reset";
                        this.disableInput = true;
                        this.showNext = true;
                        this.disableSave = true;
                        this.showLoading = false;
                        this.navigateToVFPage();

                    } else {

                        this.showToast(
                            "Something Went Wrong",
                            "",
                            "error",
                            "dismissable"
                        );
                        this.showLoading = false;

                    }

                }).
                catch((error) => {

                    this.showLoading = false;
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
    
                        this.showToast("Something Went Wrong", errorMsg, "error","dismissable");
                    }

                });

        } else {

            this.showToast(
                "Invalid Input",
                "Enter valid value in consumer key and secret",
                "error",
                "dismissable"
            );
            this.showLoading = false;

        }
        this.showLoading = false;

    }

    navigateToVFPage () {

        this[NavigationMixin.GenerateUrl]({

            "attributes": {
                "url": "/apex/KTXero__XeroOAuthPage"
            },
            "type": "standard__webPage"
        }).then((generatedUrl) => {

            window.open(generatedUrl);

        });

    }


    goBack (event) {

        this.tabs = {};
        if (event.target.value === "2") {

            this.tabs.oneActive = true;
            this.showNext = true;
            this.two = "";
            this.three = "";

        }

    }

    goNext (event) {

        this.showLoading = true;
        this.tabs = {};

        if (event.target.value === "1") {

            this.fetchTenants();

            saveXeroConnection({
                "connectWrap": JSON.stringify(this.xeroConnection)
            }).
                then((result) => {

                    if (result.flag) {

                        this.xeroConnection = result.saveResult;
                        this.two = "active";
                        this.tabs.twoActive = true;
                        this.showNext = false;
                        this.showLoading = false;

                    } else {

                        this.showToast(
                            "Something Went Wrong",
                            "",
                            "error",
                            "dismissable"
                        );
                        this.showLoading = false;

                    }

                }).
                catch((error) => {

                    this.showLoading = false;
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
    
                        this.showToast("Something Went Wrong", errorMsg, "error","dismissable");
                    }

                });

        }

        this.showLoading = false;

    }

    openSites () {

        const url = this.sitesURL;
        window.open(
            url,
            "_blank"
        );

    }


    handleWebhookSave () {

        this.showLoading = true;
        saveXeroConnection({
            "connectWrap": JSON.stringify(this.xeroConnection)
        }).
            then((result) => {

                if (result) {

                    this.assignPermission();

                }
                this.showLoading = false;

            }).
            catch((error) => {

                this.showLoading = false;
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

                    this.showToast("Something Went Wrong", errorMsg, "error","dismissable");
                }

            });

    }

    assignPermission () {

        this.showLoading = true;
        assignWebhhokPermission({
            "guestId": this.guestUserId
        }).
            then((result) => {

                if (result) {

                    this.disableWebhookSave = true;

                } else {

                    this.showToast(
                        "Something Went Wrong",
                        result.message,
                        "error",
                        "dismissable"
                    );

                }
                this.showLoading = false;

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

                    this.showToast("Something Went Wrong",errorMsg,"error","dismissable");
                }

            });

    }


    webhookStepSave () {

        this.showLoading = true;
        saveXeroConnection({
            "connectWrap": JSON.stringify(this.xeroConnection)
        }).
            then((result) => {

                if (result) {

                    this.showToast(
                        "Completed successfully",
                        "Xero - Salesforce Sync Completed",
                        "success",
                        "dismissable"
                    );
                    this.showWebhook = true;
                    this.showWebhookSteps = false;
                    this.disableWebhookInput = false;

                }
                this.showLoading = false;

            }).
            catch((error) => {

                this.showLoading = false;
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

                    this.showToast("Something Went Wrong", errorMsg, "error","dismissable");
                }

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