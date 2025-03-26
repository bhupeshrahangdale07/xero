import {LightningElement, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getXeroConnection from "@salesforce/apex/SetupConfigController.getXeroConnection";
import xeroLogo from "@salesforce/resourceUrl/New_Logo_Vertical";
import insertLog from "@salesforce/apex/Utils.insertLog";
import FORM_FACTOR from '@salesforce/client/formFactor';


export default class SetupPageCmp extends LightningElement {

    @track xeroLogo = xeroLogo;

    @track diableTab = false;

    newTab = {
        "contactConfigCmp": false,
        "xeroBulkSync": false,
        "currencyConfigCmp": false,
        "helpSupportCmp": false,
        "invoiceConfigCmp": false,
        "orgDetailCmp": false,
        "permissionSetCmp": false,
        "productConfigCmp": false,
        "setupConfigCmp": true,
        "troubleshootingCmp": false
    };


    
    connectedCallback () {
    
        this.getXeroConnect();

    }


    get isDesktop() {
        return FORM_FACTOR === "Large";
    }
    get isMobile() {
        return FORM_FACTOR === "Small";
    }
    get isTablet() {
        return FORM_FACTOR === "Medium";
    }

    getXeroConnect () {

        const num4 = 4;
        getXeroConnection({}).
            then((result) => {

                if (result) {

                    if (result.completedSteps === num4) {

                        this.diableTab = true;

                    }

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

                    this.showErrorMessage("Something Went Wrong. Error: "+errorMsg);
                }

            });

    }
  

    handleSelect (event) {

        if (event.detail.name === "setupConfigCmp") {

            this.newTab = {};
            this.newTab.setupConfigCmp = true;

        } else if (event.detail.name === "xerosync") {

            if (this.diableTab === true) {

                this.newTab = {};
                this.newTab.xeroBulkSync = true;
                this.newTab.setupConfigCmp = false;

            } else {

                this.showErrorMessage("Xero Bulk Sync is diabled");

            }

        } else if (event.detail.name === "permissionSetCmp") {

            if (this.diableTab === true) {

                this.newTab = {};
                this.newTab.permissionSetCmp = true;
                this.newTab.setupConfigCmp = false;

            } else {

                this.showErrorMessage("Permission Set Assignment is diabled");

            }

        } else if (event.detail.name === "currencyConfigCmp") {

            if (this.diableTab === true) {

                this.newTab = {};
                this.newTab.currencyConfigCmp = true;
                this.newTab.setupConfigCmp = false;

            } else {

                this.showErrorMessage("Currency Configuration is disabled");

            }


        } else if (event.detail.name === "troubleshootingCmp") {

            if (this.diableTab === true) {

                this.newTab = {};
                this.newTab.troubleshootingCmp = true;
                this.newTab.setupConfigCmp = false;

            } else {

                this.showErrorMessage("Troubleshooting is disabled.");

            }

        } else if (event.detail.name === "helpSupportCmp") {

            this.newTab = {};
            this.newTab.helpSupportCmp = true;
            this.newTab.setupConfigCmp = false;

        } else if (event.detail.name === "invoiceConfigCmp") {

            if (this.diableTab === true) {

                this.newTab = {};
                this.newTab.invoiceConfigCmp = true;
                this.newTab.setupConfigCmp = false;

            } else {

                this.showErrorMessage("Invoice Configuration is disabled.");

            }

        } else if (event.detail.name === "contactConfigCmp") {

            if (this.diableTab === true) {

                this.newTab = {};                
                this.newTab.contactConfigCmp = true;
                this.newTab.setupConfigCmp = false;

            } else {

                this.showErrorMessage("Contact Configuration is disabled.");

            }

        } else if (event.detail.name === "orgDetailCmp") {

            if (this.diableTab === true) {

                this.newTab = {};
                this.newTab.orgDetailCmp = true;
                this.newTab.setupConfigCmp = false;

            } else {

                this.showErrorMessage("");

            }

        } else if (event.detail.name === "productConfigCmp") {

            if (this.diableTab === true) {

                this.newTab = {};
                this.newTab.productConfigCmp = true;
                this.newTab.setupConfigCmp = false;

            } else {

                this.showErrorMessage("Products/Xero Items Configuration is diabled.");

            }

        }

    }

    showErrorMessage (title) {

        const avariant = "error",
            bmessage = "Please complete all setup and configuration steps first.",
            cmode = "dismissable",
            evt = new ShowToastEvent({
                title,
                bmessage,
                avariant,
                cmode
            });
        this.dispatchEvent(evt);

    }

    handleEnabledTabs (event) {

        this.diableTab = event.detail;

    }

    handleConnectionTab (event) {

        if (event.detail) {
            
            this.newTab = {};
            this.newTab.troubleshootingCmp = true;
            this.newTab.setupConfigCmp = false;
            
        }

    }

    handlePermissionTab (event) {

        if (event.detail) {

            this.newTab = {};
            this.newTab.permissionSetCmp = true;
            this.newTab.setupConfigCmp = false;

        }

    }
    renderedCallback(){
        document.title = "Xero Setup | Salesforce";
    }

}