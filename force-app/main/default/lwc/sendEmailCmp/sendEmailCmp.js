import {LightningElement, api, track} from "lwc";
import {CloseActionScreenEvent} from "lightning/actions";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import sendEmailtoXC from "@salesforce/apex/SendEmailCmpController.sendEmailtoXC";
import insertLog from "@salesforce/apex/Utils.insertLog";

export default class SendEmailCmp extends LightningElement {
    recId;

    @track displayMsg = "Emailing invoice... Please wait";

    @track isLoading = true;

    @track invoiceId;

    @track invoiceName;

    @api set recordId (value) {

        this.recId = value;
        this.sendEmail();

    }

    get recordId () {

        return this.recId;

    }

    sendEmail() {

        sendEmailtoXC({
            "recordId": this.recordId
        }).
        then((result) => {

            if (result.successFlag) {
                this.displayMsg = result.message;
                this.dispatchEvent(new CloseActionScreenEvent());
                this.showToast('Email Sent Succesfully','','success');
            }else{
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

    showToast (title, message, variant) {

        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);

    }
}