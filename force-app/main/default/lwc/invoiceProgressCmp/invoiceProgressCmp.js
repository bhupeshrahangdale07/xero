import {LightningElement, api, track} from "lwc";

export default class InvoiceProgressCmp extends LightningElement {

    @track isLoading = false;

    @api progressValue;

    @api isOpportunityInvoice;

}