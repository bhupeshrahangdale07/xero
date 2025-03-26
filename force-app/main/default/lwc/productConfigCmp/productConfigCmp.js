import {LightningElement, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

import getInvoiceConfiguration from "@salesforce/apex/InvoiceConfigurationController.getInvoiceConfiguration";
import updateConfig from "@salesforce/apex/InvoiceConfigurationController.updateInvoiceConfig";
import insertLog from "@salesforce/apex/Utils.insertLog";
import checkBatchRunning from "@salesforce/apex/XeroBulkSyncController.checkBatchRunning";
import startProductSync from "@salesforce/apex/XeroBulkSyncController.startProductSync";
import invoiceLoadingAnm from "@salesforce/resourceUrl/Product_Sync";

export default class ProductConfigCmp extends LightningElement {

    // To load the spinner
    @track showLoading = false;

    // To store product/Item configuration from custom settings
    @track invoiceConfig;

    @track isInProgress = false;

    invoiceLoading = invoiceLoadingAnm;

    connectedCallback () {

        // this.invoiceConfiguration();
        this.handleRefresh();

    }

    invoiceConfiguration () {

        this.showLoading = true;
        getInvoiceConfiguration({}).
            then((result) => {

                this.invoiceConfig = result;
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
                    this.variant = "error";
                    this.showToastPopMessage(errorMsg, this.variant);
                    this.showLoading = false;

                }

            });

    }

    handleChange (event) {

        const {name} = event.target;
        if (name === "createItem") {

            this.invoiceConfig.createItem = event.target.checked;
            this.handleSave();

        } else if (name === "createProduct") {

            this.invoiceConfig.createProduct = event.target.checked;
            this.handleSave();

        }

    }

    handleSave () {

        this.showLoading = true;
        updateConfig({
            "configData": JSON.stringify(this.invoiceConfig)
        }).then((result) => {

            if (result) {

                this.showToastPopMessage(
                    "Product Configuration is Updated",
                    "success"
                );

            } else {

                this.showToastPopMessage(
                    "Something went wrong",
                    "error"
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

                    
                    this.errorFlag = true;
                    this.variant = "error";
                    this.showToastPopMessage(errorMsg, this.variant);
                    this.showLoading = false;

                }
           

            });

    }

    showToastPopMessage (messageParam, variantParam) {

        const evt = new ShowToastEvent({
            "title": "Product Configuration",
            "message": messageParam,
            "variant": variantParam
        });
        this.dispatchEvent(evt);

    }

    handleSync() {

        this.showLoading = true;
        startProductSync({
            
        })
        .then((result) => {
            if(result){
                this.isInProgress = true;
            }else{
                this.isInProgress = false;
            }
            this.showLoading = false;
        })
        .catch((error)=>{
            
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
                            //this.errorFlag = true;
                        });
                    }else{
                        errorMsg = "Error: "+JSON.stringify(error.body.message);
                    }

                } else{
                    errorMsg = "Error: "+JSON.stringify(error);
                }

                
                this.showToast(errorMsg,"","error","dismissable");
                this.showLoading = false;

            }
        })

    }

    handleRefresh(){
        this.showLoading = true;
        checkBatchRunning({
            batchName: 'XeroBulkItemSyncBatch'
        })
        .then((result) =>{
            
            if (result) {
                if (result == 'true') {
                    
                    this.isInProgress = true;
                    this.showLoading = false;

                } else {
                    
                    this.isInProgress = false;    
                    this.showLoading = false;

                }
                this.invoiceConfiguration();
            }else{
                
                this.invoiceConfiguration();
            }
            
        })
        .catch((error)=>{
            
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
                            //this.errorFlag = true;
                        });
                    }else{
                        errorMsg = "Error: "+JSON.stringify(error.body.message);
                    }

                } else{
                    errorMsg = "Error: "+JSON.stringify(error);
                }

                
                this.showToast(errorMsg,"","error","dismissable");
                this.showLoading = false;

            }
        })
    }
}