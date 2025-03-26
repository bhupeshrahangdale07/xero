import {LightningElement, api, track} from "lwc";
import {CloseActionScreenEvent} from "lightning/actions";
import {NavigationMixin} from "lightning/navigation";
import downloadInvoice from "@salesforce/apex/DownloadInvoiceController.downloadInvoice";
import insertLog from "@salesforce/apex/Utils.insertLog";

export default class DownloadInvoiceCmp extends NavigationMixin(LightningElement) {

    recId;

    @track displayMsg = "Fetching invoice... Please wait";

    @track isLoading = true;

    @track invoiceId;

    @track invoiceName;

    @api set recordId (value) {

        this.recId = value;
        this.downloadInvoice();

    }

    get recordId () {

        return this.recId;

    }


    downloadInvoice () {

        downloadInvoice({
            "recordId": this.recordId
        }).
            then((result) => {

                if (result.successFlag) {

                    if (result.inv) {

                        this.invoiceId = result.inv.Id;
                        this.invoiceName = result.inv.Name;
                        this.displayMsg = `${this.invoiceName} fetched successfully.`;
                        this.refreshPage();

                    } else {

                        this.displayMsg = "Something went wrong...";

                    }

                } else if (result.message) {

                    this.displayMsg = result.message;

                }

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
                    this.displayMsg = `Something went wrong. ${errorMsg}`;
                    
                }


            });

    }


    refreshPage () {

        this.displayMsg = `${this.invoiceName} attached successfully. Please find Invoice in Files Section.`;
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

}