import {LightningElement, api, track} from "lwc";
import {CloseActionScreenEvent} from "lightning/actions";
import {NavigationMixin} from "lightning/navigation";
import getInvoice from "@salesforce/apex/XeroSyncController.getInvoice";
import invoiceSync from "@salesforce/apex/XeroSyncController.invoiceSync";
import syncSFToXero1 from "@salesforce/apex/XeroSyncController.syncSFToXero";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import insertLog from "@salesforce/apex/Utils.insertLog";
import XeroToSFIcon from "@salesforce/resourceUrl/SFToXeroINVImg";
import SFToXeroIcon from "@salesforce/resourceUrl/XeroToSFINVImg";


export default class InvoiceSyncCmp extends NavigationMixin(LightningElement) {
    recId;
    XeroToSFIconImg = XeroToSFIcon;
    SFToXeroIconImg = SFToXeroIcon;
    @track displayMsg = "";

    @track isLoading = true;

    @track invoiceId;

    @track invoiceName;

    @track invSyncOptions;

    @track showModal = false;
    @track invSync = "";
    @track headerText = "Choose Invoice Sync Option";
    
    @track showNegativeButton = true;

    @track showPositiveButton = true;

    @track positiveButtonLabel = "Save";

    @track negativeButtonLabel = "Cancel";
    @track errorFlag = false;
    @track title = '';
    @track message = '';
    @track variant = '';
    @track error;

    @api set recordId (value) {

        this.recId = value;

    }

    get recordId () {

        return this.recId;

    }

    saveModal () {
        if (this.invSync) {
            if(this.invSync === 'SFToXero'){
                this.headerText = "Sync Invoice with Salesforce";
                this.getInvoiceData();
            }else if(this.invSync === 'XeroToSF'){
                this.headerText = "Sync Invoice with Xero";
                this.displayMsg = "Fetching invoice data... Please wait";
                this.getInvoiceData();
                
            }

        }
      


    }

    connectedCallback(){
        this.creteOptions();

    }

    getInvoiceData () {

        getInvoice({
            "recordId": this.recordId
        }).
            then((result) => {
                const res = result;
                this.invoiceId = res.invId;
                this.invoiceName = res.invName;
                this.displayMsg = `Fetching ${res.invName} data... Please Wait`;
                if (this.invoiceId) {
                    if(this.headerText === 'Sync Invoice with Xero'){

                        this.syncInvoice();
                    }else if(this.headerText === 'Sync Invoice with Salesforce'){
                        this.syncSFToXero();
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

                    
                    this.errorFlag = true;
                    this.title = "Something Went Wrong";
                    this.message = errorMsg;
                    this.variant = "error";
                    this.showToast(this.title, this.message, this.variant);

                    this.isLoading = false;

                }

            });

    }

    syncSFToXero(){
        this.displayMsg = `Syncing ${this.invoiceName} with Salesforce... Please Wait...`;
        syncSFToXero1({
            "invoiceId": this.invoiceId,
            "recordId": this.recordId
        })
        
        .then((result)=>{
            if (result.successFlag) {

                this.displayMsg = `Updating ${this.invoiceName} values...`;
                this.refreshPage();

            } else {

                
                this.displayMsg = `Something went wrong. ${this.invoiceName} is not Synced. Please try again later. ${result.message}`;
                this.isLoading = false;

            }
        })
        .catch((error)=>{            
            var errorMsg;
            if(error){
                if (Array.isArray(error.body)) {
                    errorMsg = error.body.map((e) => e.message).join(", ");
                } else if (typeof error.body.message === "string") {
                    let err = JSON.parse(error.body.message);
                    if(err.hasOwnProperty('KTXero__Exception_Message__c')){
                        errorMsg = "Error: "+JSON.stringify(err.KTXero__Exception_Message__c);
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

            }
            this.displayMsg = `Something went wrong. ${this.invoiceName} is not Synced. ${errorMsg}`;
            this.isLoading = false;

        });
    }


    syncInvoice () {

        this.displayMsg = `Syncing ${this.invoiceName} with Xero... Please Wait...`;
        invoiceSync({
            "invoiceId": this.invoiceId,
            "recordId": this.recordId
        }).
            then((result) => {

                if (result.successFlag) {

                    this.displayMsg = `Updating ${this.invoiceName} values...`;
                    this.refreshPage();

                } else {

                    this.displayMsg = `Something went wrong. ${this.invoiceName} is not Synced. Please try again later. ${result.message}`;
                    this.isLoading = false;

                }

            }).
            catch((error) => {

                var errorMsg;
                if(error){
                    
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

                }


                this.displayMsg = `Something went wrong. ${this.invoiceName} is not Synced. ${errorMsg}`;
                this.isLoading = false;

            });

    }

    refreshPage () {

        this.displayMsg = `${this.invoiceName} Synced Successfully`;

        this.dispatchEvent(new CloseActionScreenEvent());
        this[NavigationMixin.GenerateUrl]({
            "attributes": {
                "actionName": "view",
                "recordId": this.recordId
            },
            "type": "standard__recordPage"
        }).then((url) => {

            window.open(
                url,
                "_self"
            );

        });

    }

    creteOptions(){
        this.invSyncOptions = [];
        this.invSyncOptions.push({"label": "Sync Invoice from Salesforce to Xero",
        "value": "SFToXero"});
        this.invSyncOptions.push({"label": "Sync Invoice from Xero to Salesforce",
        "value": "XeroToSF"});
        this.showModal = true;
    }

    invSynchandleChange(event){
        try{

            this.invSync = event.target.value;
        }catch(error){
            this.error = error;
        }
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