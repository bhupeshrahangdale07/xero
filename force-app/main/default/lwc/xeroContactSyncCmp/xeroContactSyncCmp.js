import {LightningElement, api, track} from "lwc";
import {CloseActionScreenEvent} from "lightning/actions";
import {NavigationMixin} from "lightning/navigation";

import contactSync from "@salesforce/apex/XeroSyncController.xerocontactSync";
import getContact from "@salesforce/apex/XeroSyncController.getxeroContact";
import syncXeroConSFToXero from "@salesforce/apex/XeroSyncController.syncXeroConSFToXero";
import XeroToSFIcon from "@salesforce/resourceUrl/XeroToSFIconImg";
import SFToXeroIcon from "@salesforce/resourceUrl/SFToXeroIconImg";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import insertLog from "@salesforce/apex/Utils.insertLog";

export default class XeroContactSyncCmp extends NavigationMixin(LightningElement) {

    recId;

    XeroToSFIconImg = XeroToSFIcon;
    SFToXeroIconImg = SFToXeroIcon;
    @track displayMsg = "";

    @track isLoading = true;

    @track conId;

    @track conName;

    @track conCompanyName;

    @track conSyncOptions;

    @track conSync = "";

    @track headerText = "Choose Contact Sync Option";
    
    @track errorFlag = false;
    @track title = '';
    @track message = '';
    @track variant = '';
    @track error;


    @api set recordId (value) {

        this.recId = value;
        // this.getXeroConData();

    }

    get recordId () {

        return this.recId;

    }

    connectedCallback(){
        this.creteOptions();

    }

    creteOptions(){
        this.conSyncOptions = [];
        this.conSyncOptions.push({"label": "Sync Contact from Salesforce to Xero",
        "value": "SFToXero"});
        this.conSyncOptions.push({"label": "Sync Contact from Xero to Salesforce",
        "value": "XeroToSF"});
        this.showModal = true;
    }
    conSynchandleChange(event){
        
        try{
            this.conSync = event.target.value;
        }catch(error){
            this.error = error;
        }
    }

    saveModal () {
        
        if (this.conSync) {
            if(this.conSync === 'SFToXero'){
                
                this.headerText = "Sync Contact with Salesforce";
                this.getXeroConData();
            }else if(this.conSync === 'XeroToSF'){
                
                // this.closeModal();
                this.headerText = "Sync Cntact with Xero";
                this.displayMsg = "Fetching Contact data... Please wait";
                this.getXeroConData();
                
            }

        }
    }

    getXeroConData () {

        getContact({
            "recordId": this.recordId
        }).
            then((result) => {

                if (result) {

                    const ele = result;
                    this.conId = ele.referenceId;
                    this.conName = ele.conName;
                    this.conCompanyName = ele.companyName;
                    this.displayMsg = `Fetching ${ele.conName} data... Please Wait`;
                    
                    
                    if (this.conId) {

                        // this.syncContact();
                        if(this.headerText === 'Sync Cntact with Xero'){

                            this.syncContact();
                        }else if(this.headerText === 'Sync Contact with Salesforce'){
                            this.syncSFToXero();
                        } 
                    }

                }

            }).
            catch((error) => {

                // this.error = error;
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
                    // this.showToast(this.title, this.message, this.variant);
                    this.displayMsg = `Something went wrong. Please try again later. ${errorMsg}`;
                }

            });

    }


    syncSFToXero(){
        
        this.displayMsg = `Syncing ${this.conName} with Salesforce... Please Wait...`;
        syncXeroConSFToXero({
            "contactId": this.conId,
            "recordId": this.recordId
        })
        .then((result)=>{
            
            if (result.successFlag) {

                this.displayMsg = `Updating ${this.conName} values...`;
                this.refreshPage();

            } else {

                
                this.displayMsg = `Something went wrong. ${this.conName} is not Synced. Please try again later. Please try again later. ${result.message}`;
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


            this.displayMsg = `Something went wrong. ${this.conName} is not Synced. ${errorMsg}`;
            this.isLoading = false;

        })
    }


    
    syncContact () {

        this.displayMsg =
      `Syncing ${this.conName} with Xero... Please Wait...`;
        contactSync({
            "recordId": this.recordId,
            "xeroConId": this.conId
        }).
            then((result) => {

                if (result.successFlag) {

                    this.displayMsg = `Updating ${this.conName} values...`;
                    this.refreshPage();

                } else {

                    this.displayMsg = `Something went wrong. ${this.conName} is not Synced. Please try again later. Please try again later. ${result.message}`;
                    this.isLoading = false;

                }

            }).
            catch((error) => {

                // this.error = error;
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

                this.displayMsg =`Something went wrong. ${this.conName} is not Synced. ${errorMsg}`;
                this.isLoading = false;

            });

    }

    refreshPage () {

        this.displayMsg = `${this.conName} Synced Successfully`;
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
    showToast (title, message, variant) {

        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);

    }
}