import {LightningElement, api, track} from "lwc";
import {CloseActionScreenEvent} from "lightning/actions";
import {NavigationMixin} from "lightning/navigation";
import getInvoice from "@salesforce/apex/XeroSyncController.getInvoice";
import invoiceSync from "@salesforce/apex/XeroSyncController.invoiceSync";


export default class SFToXeroSyncCmp extends LightningElement {
    recId;

    @track displayMsg = "Fetching invoice data... Please wait";

    @track isLoading = true;

    @track invoiceId;

    @track invoiceName;

    @api set recordId (value) {

        this.recId = value;
        this.getInvoiceData();

    }

    get recordId () {

        return this.recId;

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

                    this.syncInvoice();

                }

            }).
            catch((error) => {

                this.error = error;

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

                this.error = error;
                this.displayMsg = `Something went wrong. ${this.invoiceName} is not Synced. ${this.error.body.message}`;
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


}