import {LightningElement, track} from "lwc";
import {NavigationMixin} from "lightning/navigation";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

import assignWebhhokPermission from "@salesforce/apex/SetupConfigController.assignWebhhokPermission";
import fetchPermissionSets from "@salesforce/apex/SetupConfigController.fetchPermissionSets";
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

export default class SetupConfigCmp extends NavigationMixin(LightningElement) {

    @track showLoading = false;

    @track iconName = "utility:chevronright";

    @track showXeroConnection = false;

    @track showXeroPermission = false;

    @track showWebhook = false;

    @track showOpportunity = false;

    @track progressPercent;

    @track progressWebhook;

    @track progressLayout;

    @track progressPermission;

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

    @track xeroConnection = [];

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

    @track redirectURL;

    @track sitesURL;

    @track siteOptions;

    @track showSiteCreation = false;

    @track siteVal;

    @track siteSecureURL;

    @track webhookKey;

    @track disableWebhookSave;

    @track disableWebhookInput;

    @track siteDetails;

    @track guestUserId;

    @track disableStepSave = true;

    connectedCallback () {

        this.progressPercent = 0;
        this.progressWebhook = 0;
        this.progressLayout = 0;
        this.progressPermission = 0;
        this.getConnections();

    }

    getRedirectURL () {

        this.showLoading = true;
        getSitesConfigURL({
            "entity": "VFURL"
        }).
            then((result) => {

                if (result) {

                    this.redirectURL = result;

                }
                this.showLoading = false;

            }).
            catch((error) => {

                this.error = error;
                
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
                    this.showLoading = false;

                }
            });

    }

    getSitesConfigURL () {

        this.showLoading = true;
        getSitesConfigURL({
            "entity": "Sites"
        }).
            then((result) => {

                if (result) {

                    this.sitesURL = result;

                }
                this.getRedirectURL();
                this.showLoading = false;

            }).
            catch((error) => {

                this.error = error;
                this.showLoading = false;
                this.showToast(
                    "Something Went Wrong",
                    error,
                    "error",
                    "dismissable"
                );

            });

    }

    getAllSites () {

        const num0 = 0;
        this.showLoading = true;
        getSites({}).
            then((result) => {

                if (result.length > num0) {

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
                this.getSitesConfigURL();
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

    handleWebhookSave () {

        if (this.xeroConnection.webhookKey) {

            this.showLoading = true;
            saveXeroConnection({
                "connectWrap": JSON.stringify(this.xeroConnection)
            }).
                then((result) => {

                    if (result) {

                        this.disableStepSave = false;
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

        } else {

            this.showToast(
                "Encypted Sync Key",
                "Enter valid value in Encypted Sync Key",
                "error",
                "dismissable"
            );

        }

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

    webhookStepSave () {

        this.showLoading = true;
        this.progressWebhook = 1;
        this.xeroConnection.completedSteps = 2;
        this.xeroConnection.progressValue = 50;
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
                    this.steps.threeStep = false;
                    this.disableWebhookInput = true;

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

    getConnections () {

        const num0 = 0,
            num1 = 1,
            num2 = 2,
            num3 = 3,
            num4 = 4;
        this.showLoading = true;
        this.xeroConnection.progressValue = 0;
        getXeroConnection({}).
            then((result) => {

                if (result) {

                    this.xeroConnection = result;
                    this.tabs = {};
                    if (result.completedConnectionSteps > num0 && result.totalConnectionSteps > num0) {

                        this.progressPercent = result.completedConnectionSteps / result.totalConnectionSteps;
                        if (result.completedConnectionSteps === num1) {

                            this.tabs.oneActive = true;
                            this.one = "active";

                            this.enableReset = true;
                            this.disableSave = true;
                            this.showNext = true;
                            this.resetLabel = "Reset";
                            this.disableInput = true;

                        } else if (result.completedConnectionSteps === num2) {

                            this.tabs.twoActive = true;
                            this.one = "active";
                            this.two = "active";

                            this.enableReset = true;
                            this.disableSave = true;
                            this.showNext = true;
                            this.resetLabel = "Reset";
                            this.disableInput = true;

                        }
                        this.fetchTenants();

                    } else {

                        this.tabs.oneActive = true;
                        this.progressPercent = 0;
                        this.disableSave = false;

                    }

                    if (result.completedSteps === num1) {

                        this.steps.twoStep = false;
                        this.progressWebhook = 0;

                    } else if (result.completedSteps === num2) {

                        this.steps.twoStep = false;
                        this.steps.threeStep = false;
                        this.progressWebhook = num1 / num1;
                        this.disableWebhookSave = true;
                        this.disableWebhookInput = true;

                    } else if (result.completedSteps === num3) {

                        this.steps.twoStep = false;
                        this.steps.threeStep = false;
                        this.steps.fourStep = false;
                        this.progressWebhook = num1 / num1;
                        this.progressPermission = num1 / num1;
                        this.disableWebhookSave = true;
                        this.disableWebhookInput = true;
                        this.disablePermissionSave = true;

                    } else if (result.completedSteps === num4) {

                        this.steps.twoStep = false;
                        this.steps.threeStep = false;
                        this.steps.fourStep = false;
                        this.progressWebhook = num1 / num1;
                        this.progressPermission = num1 / num1;
                        this.progressLayout = num1 / num1;
                        this.disableWebhookSave = true;
                        this.disableWebhookInput = true;
                        this.disablePermissionSave = true;
                        this.disableLayoutSave = true;

                    }


                    this.key = this.xeroConnection.clientId;
                    this.secret = this.xeroConnection.clientSecret;
                    this.getAllSites();

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
                this.disableSave = false;

            } else if (event.target.name === "Consumer Key") {

                this.xeroConnection.clientId = event.target.value;
                this.disableSave = false;

            } else if (event.target.name === "Encypted Sync Key") {

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

    changeView (event) {

        this.showLoading = true;
        const btName = event.target.dataset.id;
        if (btName === "xeroConnection") {

            const ele = this.template.querySelector("[data-id=\"xeroConnection\"]");
            if (ele.iconName === "utility:chevronright") {

                ele.iconName = "utility:chevrondown";
                this.showXeroConnection = true;

            } else {

                ele.iconName = "utility:chevronright";
                this.showXeroConnection = false;

            }

        } else if (btName === "webhookBtn") {

            const ele = this.template.querySelector("[data-id=\"webhookBtn\"]");
            if (ele.iconName === "utility:chevronright") {

                ele.iconName = "utility:chevrondown";
                this.showWebhook = true;

            } else {

                ele.iconName = "utility:chevronright";
                this.showWebhook = false;

            }

        } else if (btName === "permissionBtn") {

            const ele = this.template.querySelector("[data-id=\"permissionBtn\"]");
            if (ele.iconName === "utility:chevronright") {

                ele.iconName = "utility:chevrondown";
                this.showXeroPermission = true;

            } else {

                ele.iconName = "utility:chevronright";
                this.showXeroPermission = false;

            }

        } else if (btName === "opportunityBtn") {

            const ele = this.template.querySelector("[data-id=\"opportunityBtn\"]");
            if (ele.iconName === "utility:chevronright") {

                ele.iconName = "utility:chevrondown";
                this.showOpportunity = true;

            } else {

                ele.iconName = "utility:chevronright";
                this.showOpportunity = false;

            }

        }
        this.showLoading = false;

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

    saveConnection () {

        this.showLoading = true;
        if (this.xeroConnection.clientId !== "" && this.xeroConnection.clientSecret !== "") {

            this.xeroConnection.completedConnectionSteps = 1;
            this.xeroConnection.progressValue = 13;
            this.progressPercent = this.xeroConnection.completedConnectionSteps / this.xeroConnection.totalConnectionSteps;
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
                        // Window.open(this.xeroConnection.authURL,'_Blank');
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

    saveTenant () {

        this.showLoading = true;
        this.xeroConnection.completedConnectionSteps = 2;
        this.xeroConnection.progressValue = 25;
        this.progressPercent = this.xeroConnection.completedConnectionSteps / this.xeroConnection.totalConnectionSteps;
        this.xeroConnection.completedSteps = 1;
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

                    this.showToast("Something Went Wrong", errorMsg, "error", "dismissable");
                }

            });

    }

    fetchXeroTaxRate () {

        syncTaxRate({}).
            then((result) => {

                if (result.successFlag) {

                    this.fetchXeroTemplates();

                } else {

                    this.showToast(
                        `Something Went Wrong. ${result.message}`,
                        result.message,
                        "error",
                        "dismissable"
                    );

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
                    this.showToast(this.title, this.message, this.variant, "dismissable");
                    this.showLoading = false;

                }

            });

    }

    fetchXeroTemplates () {

        syncInvoiceTemplates({}).
            then((result) => {

                if (result) {

                    // This.fetchAccounts();
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
                    "Something Went Wrong. ",
                    error.body.message,
                    "error",
                    "dismissable"
                );

            });

    }

    fetchAccounts () {

        syncAccounts({}).
            then((result) => {

                if (result) {

                    // This.fetchTrackingCategories();
                    if (result.successFlag) {

                        this.fetchTrackingCategories();

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
                    "Something Went Wrong. ",
                    error.body.message,
                    "error",
                    "dismissable"
                );

            });

    }

    fetchTrackingCategories () {

        syncTrackingCategories({}).
            then((result) => {

                if (result) {

                    if (!result.successFlag) {

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
                this.getPermissionsets();
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

        this.showLoading = true;
        if (this.disableInput) {

            this.disableInput = false;
            this.resetLabel = "Cancel";
            this.showNext = false;

        } else {

            this.disableInput = true;
            this.resetLabel = "Reset";
            this.xeroConnection.consumerKey = this.key;
            this.xeroConnection.consumerSecret = this.secret;
            this.showNext = true;
            this.disableSave = true;

        }
        this.showLoading = false;

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

            this.xeroConnection.completedConnectionSteps = 1;
            this.xeroConnection.progressValue = 12;

            this.progressPercent = this.xeroConnection.completedConnectionSteps / this.xeroConnection.totalConnectionSteps;
            this.tabs.twoActive = true;
            this.showNext = false;
            this.two = "active";
            this.fetchTenants();

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

    getPermissionsets () {

        const num0 = 0;
        this.showLoading = true;
        fetchPermissionSets({}).
            then((result) => {

                if (result.length > num0) {

                    const pMap = new Map();
                    result.forEach((ele) => {

                        pMap.set(
                            ele.name,
                            ele.setupUrl
                        );

                    });
                    this.permissionSets = pMap;

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

    handlePermission (event) {

        const permission = event.target.value,
            url = this.permissionSets.get(permission);
        window.open(
            url,
            "_blank"
        );

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

    handleSavePermission () {

        this.showLoading = true;
        this.xeroConnection.completedSteps = 3;
        this.xeroConnection.progressValue = 75;

        saveXeroConnection({
            "connectWrap": JSON.stringify(this.xeroConnection)
        }).
            then((result) => {

                if (result.flag) {

                    this.xeroConnection = result.saveResult;
                    this.showToast(
                        "Completed successfully",
                        "Permission Step Completed Successfully",
                        "success",
                        "dismissable"
                    );
                    this.progressPermission = 1;
                    this.progressPercent = this.xeroConnection.completedConnectionSteps / this.xeroConnection.totalConnectionSteps;
                    this.steps.fourStep = false;
                    this.disablePermissionSave = true;

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

    layoutUpdated () {

        const num1 = 1;
        this.xeroConnection.completedSteps = 4;
        this.xeroConnection.progressValue = 100;
        this.progressLayout = num1 / num1;
        this.showLoading = true;

        saveXeroConnection({
            "connectWrap": JSON.stringify(this.xeroConnection)
        }).
            then((result) => {

                if (result.flag) {

                    this.xeroConnection = result.saveResult;
                    this.showToast(
                        "Completed successfully",
                        "Adding Page Layout Completed Successfully",
                        "success",
                        "dismissable"
                    );
                    this.disableLayoutSave = true;
                    this.dispatchEvent(new CustomEvent(
                        "enabletabs",
                        {
                            "detail": true
                        }
                    ));

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

    handleConnectionLink () {

        this.dispatchEvent(new CustomEvent(
            "connectiontab",
            {
                "detail": true
            }
        ));

    }

    handlePermissionLink () {

        this.dispatchEvent(new CustomEvent(
            "permissiontab",
            {
                "detail": true
            }
        ));

    }


    renderedCallback () {

        if (this.showXeroConnection) {

            const ele = this.template.querySelector("[data-id=\"xeroConnection\"]");
            if(ele){
                
                ele.iconName = "utility:chevrondown";
            }
            
        }
        if (this.showXeroPermission) {
            
            const ele = this.template.querySelector("[data-id=\"permissionBtn\"]");
            if(ele){

                ele.iconName = "utility:chevrondown";

            }
            
        }
        if (this.showOpportunity) {
            
            const ele = this.template.querySelector("[data-id=\"opportunityBtn\"]");
            if(ele){

                ele.iconName = "utility:chevrondown";

            }
            
        }
        if (this.showWebhook) {
            
            const ele = this.template.querySelector("[data-id=\"webhookBtn\"]");
            if(ele){

                ele.iconName = "utility:chevrondown";

            }

        }

    }

}