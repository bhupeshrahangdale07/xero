import {LightningElement, api, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getproducts from "@salesforce/apex/InvoiceCreationController.getProducts";
import insertLog from "@salesforce/apex/Utils.insertLog";

export default class InvoiceOppCmp extends LightningElement {

    @api recordId;
    
    @track invoiceOpt;

    @track invoicesList;

    @track isLoading = false;

    @track productList;

    @track error;

    @track accountId;

    @track accountName;

    @api
    get invoiceOption () {

        return this.invoiceOpt;

    }

    set invoiceOption (value) {

        this.invoiceOpt = value;

    }

    connectedCallback () {

        const recId = this.recordId;
        if (recId !== null || typeof recId !== "undefined") {

            this.getOpportunityProducts();

        }

    }

    getOpportunityProducts () {

        this.isLoading = true;
        getproducts({"recordId": this.recordId}).
            then((result) => {

                let prepopulate = "";
                const testLen = 0;
                if (result.opplineItems.length > testLen) {

                    prepopulate = this.template.querySelector("[data-id=\"prepopulate\"]");
                    prepopulate.checked = true;
                    this.invoiceOpt = "prepopulate";

                } else {

                    const blank = this.template.querySelector("[data-id=\"blank\"]");
                    blank.checked = true;
                    this.invoiceOpt = "blank";
                    prepopulate = this.template.querySelector("[data-id=\"prepopulate\"]");
                    prepopulate.disabled = true;

                }

                if (result.invoices.length > testLen) {

                    const invList = result.invoices;
                    invList.forEach((element) => {

                        element.URL = `/${element.invoiceId}`;

                    });
                    this.invoicesList = invList;

                }
                this.accountId = result.accountId;
                this.accountName = result.accountName;
                this.error = "undefined";
                this.isLoading = false;

            }).
            catch((error) => {

                this.accounts = "undefined";
                this.isLoading = false;

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

    onhandleChange (event) {

        this.isLoading = true;
        this.invoiceOpt = event.target.value;
        this.dispatchEvent(new CustomEvent(
            "invoiceoption",
            {
                "detail": this.invoiceOpt
            }
        ));
        this.isLoading = false;

    }

    renderedCallback(){
        this.dispatchEvent(new CustomEvent(
            "accountid",
            {
                "detail": this.accountId
            }
        ));

        this.dispatchEvent(new CustomEvent(
            "accountname",
            {
                "detail": this.accountName
            }
        ));

        this.dispatchEvent(new CustomEvent(
            "invoiceoption",
            {
                "detail": this.invoiceOpt
            }
        ));
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