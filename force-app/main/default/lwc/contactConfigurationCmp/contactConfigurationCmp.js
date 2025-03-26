import {LightningElement, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

import getsObjectFieldMap from "@salesforce/apex/InvoiceConfigurationController.getFieldMap";
import getxconConfiguration from "@salesforce/apex/InvoiceConfigurationController.getxeroconConfiguration";
import updateConfig from "@salesforce/apex/InvoiceConfigurationController.updateContactConfig";
import insertLog from "@salesforce/apex/Utils.insertLog";

export default class ContactConfigurationCmp extends LightningElement {

    @track showLoading = false;

    @track objFieldData;

    @track invoiceConfig;

    @track contextFieldOptions;

    @track conemailFieldOptions;

    @track acctextFieldOptions;

    @track accphoneFieldOptions;

    @track savedisable = true;

    @track errorFlag = false;
    @track title = '';
    @track message = '';
    @track variant = '';

    connectedCallback () {

        this.invoiceConfig = {};
        this.invoiceConfiguration();

    }

    getConObjFieldData (IsCalledFromMethod) {

        this.showLoading = true;
        getsObjectFieldMap({
            "sObjectType": "Contact"
        }).
            then((result) => {

                const emailFieldArr = [],
                    textFieldArr = [];
                if (result) {

                    result.forEach((element) => {

                        if (element.fieldType === "STRING") {

                            textFieldArr.push({"label": element.label,
                                "value": element.value});

                        } else if (element.fieldType === "EMAIL") {

                            emailFieldArr.push({"label": element.label,
                                "value": element.value});

                        }

                    });

                    textFieldArr.sort((element1, element2) => {

                        if (element1.label < element2.label) {

                            const res = -1;
                            return res;

                        } else if (element1.label > element2.label) {

                            const res = 1;
                            return res;

                        }
                        const res = 0;
                        return res;

                    });

                    emailFieldArr.sort((element1, element2) => {

                        if (element1.label < element2.label) {

                            const res = -1;
                            return res;

                        } else if (element1.label > element2.label) {

                            const res = 1;
                            return res;

                        }

                        const res = 0;
                        return res;

                    });

                    this.contextFieldOptions = textFieldArr;
                    this.conemailFieldOptions = emailFieldArr;

                }
                this.showLoading = false;
                if(IsCalledFromMethod == true){

                    this.errorFlag = true;
                    this.title = 'Contact Configuration';
                    this.message = 'Contact fields are refreshed';
                    this.variant = 'success';
                }
            }).
            catch((error) => {

                this.error = error;
                this.showLoading = false;

            });

    }

    getAccObjFieldData (IsCalledFromMethod) {

        this.showLoading = true;
        getsObjectFieldMap({
            "sObjectType": "Account"
        }).
            then((result) => {

                const phoneFieldArr = [],
                    textFieldArr = [];
                if (result) {

                    result.forEach((element) => {

                        if (element.fieldType === "STRING" || element.fieldType === "TEXTAREA") {

                            textFieldArr.push({"label": element.label,
                                "value": element.value});

                        } else if (element.fieldType === "PHONE") {

                            phoneFieldArr.push({"label": element.label,
                                "value": element.value});

                        }

                    });
                    textFieldArr.sort((element1, element2) => {

                        if (element1.label < element2.label) {

                            const res = -1;
                            return res;

                        } else if (element1.label > element2.label) {

                            const res = 1;
                            return res;

                        }

                        const res = 0;
                        return res;

                    });

                    phoneFieldArr.sort((element1, element2) => {

                        if (element1.label < element2.label) {

                            const res = -1;
                            return res;

                        } else if (element1.label > element2.label) {

                            const res = 1;
                            return res;

                        }

                        const res = 0;
                        return res;

                    });

                    this.acctextFieldOptions = textFieldArr;
                    this.accphoneFieldOptions = phoneFieldArr;

                }
                this.showLoading = false;
                if(IsCalledFromMethod == true){

                    this.errorFlag = true;
                    this.title = 'Contact Configuration';
                    this.message = 'Account fields are refreshed';
                    this.variant = 'success';

                }

                
            }).
            catch((error) => {

                this.error = error;
                this.showLoading = false;

            });

    }

    invoiceConfiguration () {
        this.showLoading = true;
        getxconConfiguration({}).
            then((result) => {
                if(result){
                    
                    this.invoiceConfig = result;
                    this.showLoading = false;
                    this.getConObjFieldData(false);
                    this.getAccObjFieldData(false);
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
                    this.variant = "error";
                    this.showToast('Contact Configuration', errorMsg, this.variant);
                    this.showLoading = false;

                }
            });

    }

    refreshFields () {

        this.getConObjFieldData(true);

    }

    refreshAccFields () {

        this.getAccObjFieldData(true);

    }

    handlefieldChange (event) {

        this.savedisable = false;
        const {name} = event.target;
        if (name === "Account Number") {

            this.invoiceConfig.accountNumber = event.target.value;

        } else if (name === "First Name") {

            this.invoiceConfig.firstName = event.target.value;

        } else if (name === "Last Name") {

            this.invoiceConfig.lastName = event.target.value;

        } else if (name === "Email") {

            this.invoiceConfig.email = event.target.value;

        } else if (name === "Account Name") {

            this.invoiceConfig.accountName = event.target.value;

        } else if (name === "Street Address") {

            this.invoiceConfig.accountStreet = event.target.value;

        } else if (name === "City") {

            this.invoiceConfig.accountCity = event.target.value;

        } else if (name === "State") {

            this.invoiceConfig.accountState = event.target.value;

        } else if (name === "Postal/Zip Code") {

            this.invoiceConfig.accountzipCode = event.target.value;

        } else if (name === "Country") {

            this.invoiceConfig.accountCountry = event.target.value;

        } else if (name === "Account Phone") {

            this.invoiceConfig.accountPhone = event.target.value;
            
        } else if (name === "xcAccCreation") {
            
            this.invoiceConfig.accCreation = event.target.checked;

        }

    }

    handleSave () {

        this.showLoading = true;
        updateConfig({
            "configData": JSON.stringify(this.invoiceConfig)
        }).then((result) => {

            if (result) {

                this.errorFlag = true;
                this.title = 'Contact Configuration';
                this.message = 'Contact Configuration is Updated';
                this.variant = 'success';
                this.savedisable = true;

            } else {

                this.errorFlag = true;
                this.title = 'Contact Configuration';
                this.message = 'Something went wrong';
                this.variant = 'error';
            }
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

                    
                    // this.errorFlag = true;
                    this.variant = "error";
                    this.showToast("Contact Configuration", errorMsg, this.variant);
                    this.showLoading = false;

                }
            });

    }

    renderedCallback(){
        if(this.title !== '' && this.message !== '' && this.variant !== '' && this.errorFlag === true){

            this.showToast(this.title, this.message, this.variant);
            this.errorFlag = false;
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