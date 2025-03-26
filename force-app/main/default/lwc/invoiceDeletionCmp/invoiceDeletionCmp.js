import {LightningElement, api, track} from "lwc";
import {CloseActionScreenEvent} from "lightning/actions";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

import deleteInvoice from "@salesforce/apex/InvoiceCreationController.deleteInvoice";
import insertLog from "@salesforce/apex/Utils.insertLog";
import getInvoice from "@salesforce/apex/XeroSyncController.getInvoice";

export default class InvoiceDeletionCmp extends LightningElement {

    @track recId;

    @track actionName;

    @track invoiceId;

    @track Name;

    @track invStatus;

    @track deleteOption = true;

    @track isLoading = false;

    @track invPaid = false;

    @api set recordId (value) {

        this.recId = value;
        this.getInvoiceData();

    }

    get recordId () {

        return this.recId;

    }

    getInvoiceData () {

        this.isLoading = true;
        getInvoice({
            "recordId": this.recordId
        }).
            then((result) => {

                const xResult = result;
                this.invoiceId = xResult.invId;
                this.Name = xResult.invName;
                if (xResult.invStatus !== "") {

                    if (xResult.invStatus === "DRAFT" ||
                        xResult.invStatus === "SUBMITTED ") {

                        this.actionName = "DELETE";
                        this.invStatus = "DELETED";
                        this.deleteOption = true;

                    } else if (xResult.invStatus === "AUTHORISED") {

                        this.actionName = "VOID";
                        this.invStatus = "VOIDED";
                        this.deleteOption = true;

                    } else if (xResult.invStatus === "DELETED" ||
                               xResult.invStatus === "VOIDED" ||
                               xResult.invStatus === "PAID") {

                        this.invStatus = xResult.invStatus;
                        this.deleteOption = false;
                        this.invPaid = true;

                    }

                }
                this.isLoading = false;

            }).
            catch((error) => {

                this.error = error;
                this.isLoading = false;

            });

    }

    closeAction () {

        this.dispatchEvent(new CloseActionScreenEvent());

    }

    saveAction () {

        this.isLoading = true;
        deleteInvoice({
            "invStatus": this.invStatus,
            "invoiceId": this.invoiceId,
            "recordId": this.recordId
        }).
            then((result) => {

                if (result) {

                    this.showToast(
                        "Action Completed",
                        `${this.actionName} action for ${this.Name} completed Successfully`,
                        "success",
                        "dismissable"
                    );

                } else {

                    this.showToast(
                        "Action Completed",
                        "Something went wrong",
                        "error",
                        "dismissable"
                    );

                }
                this.isLoading = false;
                this.dispatchEvent(new CloseActionScreenEvent());

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