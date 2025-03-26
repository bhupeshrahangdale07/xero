import {LightningElement, api, track} from "lwc";

export default class GenerateInvoice extends LightningElement {

    @api recId;

    @track showCmp = false;

    connectedCallback () {


        const aurlStr = window.location.href,
            searchParams = new URLSearchParams(aurlStr);
        this.recId = searchParams.get("recid");

        if (typeof this.recId !== "undefined" || this.recId !== "" || this.recId !== null) {

            this.showCmp = true;

        }

    }

}