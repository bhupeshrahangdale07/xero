import {LightningElement, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

import getinvoiceConfiguration from "@salesforce/apex/InvoiceConfigurationController.getInvoiceConfiguration";
import getsObjectFieldMap from "@salesforce/apex/InvoiceConfigurationController.getFieldMap";
import getxeroMetadata from "@salesforce/apex/InvoiceConfigurationController.taxRateAndAccFetchMethod";
import saveTracking from "@salesforce/apex/InvoiceConfigurationController.saveMetadata";
import syncAccounts from "@salesforce/apex/XeroSyncController.xeroAccountsSync";
import syncInvoiceTemplates from "@salesforce/apex/InvoiceConfigurationController.xeroInvoiceTemplateSync";
import syncTaxRate from "@salesforce/apex/InvoiceConfigurationController.xeroTaxRateSync";
import syncTracking from "@salesforce/apex/InvoiceConfigurationController.xeroTrackingCategorySync";
import updateConfig from "@salesforce/apex/InvoiceConfigurationController.updateInvoiceConfig";
import insertLog from "@salesforce/apex/Utils.insertLog";

const createTrackingMap = function createTrackingMap (tcArr, tcOptArr) {

    const tcMap = new Map();
    tcArr.forEach((element) => {

        tcOptArr.forEach((ele) => {

            if (element.value === ele.xeroId) {

                if (tcMap.has(element.text)) {

                    const arrvalObj = tcMap.get(element.text),
                        nArr = arrvalObj.options;
                    nArr.push({"label": ele.text,
                        "value": ele.value});
                    arrvalObj.options = nArr;
                    tcMap.set(
                        element.text,
                        arrvalObj
                    );

                } else {

                    const arrOpt = [
                            {"label": ele.text,
                                "value": ele.value}
                        ],
                        newObj = {
                            "defaultVal": "",
                            "id": element.id,
                            "options": arrOpt
                        };
                        // ArrOpt.push();

                    if (element.code !== "" || element.code !== null) {

                        newObj.defaultVal = element.code;

                    } else {

                        newObj.defaultVal = "";

                    }
                    tcMap.set(
                        element.text,
                        newObj
                    );

                }

            }

        });

    });

    return tcMap;

};

export default class InvoiceConfigurationCmp extends LightningElement {

    @track showLoading = false;

    @track invoiceConfig;

    // Taxrate picklist
    @track taxOptions = [];

    // Accout code picklist
    @track accOptions = [];

    // Invoice template picklist
    @track templateOptions = [];

    @track accountCodeArr = [];

    @track trackmapOrg = [];

    @track trackmapData = [];

    @track savedisable = true;

    @track showHelpTextFlag = false;

    @track fields = {
        "dateFields": [],
        "textFields": []
    };

    @track invoiceDateOptions = {
        "invoiceDate": {
            "Days": "",
            "SelectedBeforeAfterFieldValue": "After",
            "options": [
                {
                    "label": "After",
                    "value": "After"
                },
                {
                    "label": "Before",
                    "value": "Before"
                }
            ],
            "value": ""
        },
        "invoiceDueDate": {
            "Days": "",
            "SelectedBeforeAfterFieldValue": "After",
            "options": [
                {
                    "label": "After",
                    "value": "After"
                },
                {
                    "label": "Before",
                    "value": "Before"
                }
            ],
            "value": ""

        }
    };


    @track amountTaxOptions = [
        {"label": "Tax Exclusive",
            "value": "Exclusive"},
        {"label": "Tax Inclusive",
            "value": "Inclusive"},
        {"label": "No Tax",
            "value": "NoTax"}
    ];

    @track productDescOptions = [
        {"label":"Xero Item Sales Description",
            "value": "Xero Item Sales Description"},
        {"label":"Line Item Description",
            "value": "Line Item Description"},
        {"label":"Product Description",
            "value": "Product Description"}
    ];

    @track errorFlag = false;
    @track message = '';
    @track variant = '';
    connectedCallback () {
        this.invoiceConfiguration();

    }

    invoiceConfiguration () {

        this.showLoading = true;
        getinvoiceConfiguration({}).
            then((result) => {

                this.invoiceConfig = result;
                this.xeroMetadata();
                this.prepareOpportunityFields(result);
                this.showLoading = false;

            }).
            catch((error) => {

                // this.error = error;
                
                // this.errorFlag = true;
                // this.message = "Something went wrong.";

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
                    this.showToastPopMessage(errorMsg, this.variant);
                    this.showLoading = false;

                }

            });

    }

    prepareOpportunityFields (data) {

        const allFields = data.opportunityFieldMap;
        this.fields.dateFields = [
            {
                "fieldType": "",
                "label": "Select",
                "value": ""
            }
        ];
        this.fields.textFields = [
            {
                "fieldType": "",
                "label": "Select",
                "value": ""
            }
        ];
        if (allFields) {

            allFields.forEach((element) => {

                if (element.fieldType && element.fieldType.toUpperCase() === "DATE") {

                    this.fields.dateFields.push(element);

                } else {

                    this.fields.textFields.push(element);

                }

            });

        }

        this.fields.textFields.sort((element1, element2) => {

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

        this.readInvoiceSetupData();

    }

    readInvoiceSetupData () {

        const fields = [
            "invoiceDate",
            "invoiceDueDate"
        ];
        if (this.invoiceConfig) {

            fields.forEach((field) => {

                if (this.invoiceConfig[field] && this.invoiceConfig[field] !== "" && this.invoiceConfig[field].includes(";")) {

                    const testLength = 3,
                        val = this.invoiceConfig[field].split(";");
                    if (val && val.length === testLength) {

                        const index0 = 0,
                            index1 = 1,
                            index2 = 2;
                        this.invoiceDateOptions[field].Days = val[index0];
                        this.invoiceDateOptions[field].SelectedBeforeAfterFieldValue = val[index1];
                        this.invoiceDateOptions[field].value = val[index2];

                    }

                }

            });

        }

    }

    prepareInvoiceSetupData () {

        // This.invoiceConfig;
        const fields = [
            "invoiceDate",
            "invoiceDueDate"
        ];
        if (this.invoiceConfig) {

            fields.forEach((field) => {

                let val = "";
                val += `${this.invoiceDateOptions[field].Days};`;
                val += `${this.invoiceDateOptions[field].SelectedBeforeAfterFieldValue};`;
                val += this.invoiceDateOptions[field].value;

                this.invoiceConfig[field] = val;

            });

        }

    }

    handleInvoiceChange (event) {
        this.showLoading = true;
        const targetVal = this.invoiceConfig[event.target.name];
        if (!(event.target.name.includes("_After_Or_Before") || event.target.name.includes("_Days")) && this.invoiceConfig && typeof targetVal !== "undefined" && this.invoiceConfig[event.target.name] !== event.target.value) {

            this.savedisable = false;
            if (event.target.name === "invoiceReference") {

                this.invoiceConfig[event.target.name] = event.target.value;

            } else {

                this.invoiceDateOptions[event.target.name].value = event.target.value;

            }
            this.showLoading = false;
        } else if (event.target.name.includes("_After_Or_Before") || event.target.name.includes("_Days")) {

            this.savedisable = false;
            if (event.target.name.includes("_After_Or_Before")) {

                const index = 0;
                let nm = "";
                if (event.target.name.split("_After_Or_Before").length > index) {

                    nm = event.target.name.split("_After_Or_Before")[index];

                } else {

                    nm = "";

                }
                this.invoiceDateOptions[nm].SelectedBeforeAfterFieldValue = event.target.value;
                this.showLoading = false;
            } else if (event.target.name.includes("_Days")) {

                let flag = false;
                let num = Number(event.target.value);
                const index = 0;
                let nm = "";
                if (event.target.name.split("_Days").length > index) {

                    nm = event.target.name.split("_Days")[index];

                } else {

                    nm = "";

                }
                
                if(num < 0){
                    this.showToastPopMessage("Please enter Positive Value","error");
                    flag = true;
                    this.invoiceDateOptions[nm].Days = 0;
                    this.savedisable = true;
                    this.showLoading = false;
                }

                if(num > 999){
                    this.showToastPopMessage("Please enter Value less than 1000","error");
                    flag = true;
                    this.invoiceDateOptions[nm].Days = 0;
                    this.savedisable = true;
                    this.showLoading = false;
                }

                if(event.target.value === ""){
                    this.showToastPopMessage("Please enter valid value","error");
                    flag = true;
                    this.invoiceDateOptions[nm].Days = 0;
                    this.savedisable = true;
                    this.showLoading = false;
                }
                
                if(!Number.isInteger(num)){
                    this.showToastPopMessage("Please enter the whole number","error");
                    flag = true;
                    this.invoiceDateOptions[nm].Days = 0;
                    this.savedisable = true;
                    this.showLoading = false;
                }

                if(!flag){

                    this.invoiceDateOptions[nm].Days = event.target.value;
                    this.savedisable = false
                    this.showLoading = false;
                }

            }

        }
    }

    handleProductDescription (event) {
        this.showLoading = true;
        this.invoiceConfig.lineItemDescription = event.target.value;
        this.savedisable = false;
        this.showLoading = false;
    }

    xeroMetadata () {
        this.showLoading = true;
        getxeroMetadata({}).
            then((result) => {

                const accOptionsArr = [],
                    accountCodeArr = [],
                    taxOptionsArr = [],
                    tcArr = [],
                    tcOptArr = [],
                    templatesOption = [];

                result.forEach((element) => {

                    if (element.type === "TaxRate") {

                        taxOptionsArr.push({"label": element.text,
                            "value": `${element.numberCode}`});

                    } else if (element.type === "Accounts") {

                        accOptionsArr.push({"label": element.text,
                            "value": `${element.numberCode}`});
                        accountCodeArr.push(element);

                    } else if (element.type === "Invoice Template") {

                        templatesOption.push({"label": element.text,
                            "value": element.value});

                    } else if (element.type === "tracking_category") {

                        tcArr.push(element);

                    } else if (element.type === "tracking_category_option") {

                        tcOptArr.push(element);

                    }

                });

                this.accountCodeArr = accountCodeArr;
                this.taxOptions = taxOptionsArr;
                this.accOptions = accOptionsArr;
                this.templateOptions = templatesOption;

                let tcMap = new Map();

                if (tcArr && tcOptArr) {

                    tcMap = createTrackingMap(
                        tcArr,
                        tcOptArr
                    );

                    this.trackmapOrg = tcMap;

                    let keys = [...tcMap.keys()];

                    keys.forEach(key => {
                        const value = tcMap.get(key);
                        this.trackmapData.push({key,
                            value});
                    });

                }
                this.showLoading = false;

            }).
            catch((error) => {

                this.error = error;
                // this.showLoading = false;
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
                    this.showToastPopMessage(errorMsg, this.variant);
                    this.showLoading = false;

                }

            });

    }


    handleTracking (event) {

        this.showLoading = true;
        const optLabel = event.target.options.find(opt => opt.value === event.detail.value).label;
        const metaId = event.target.dataset.id,
            {name} = event.target,
            valObj = this.trackmapOrg.get(name);
        valObj.defaultVal = event.target.value;
        this.trackmapOrg.set(
            name,
            valObj
        );
        this.trackmapData = [];

        let keys = [...this.trackmapOrg.keys()];

        keys.forEach(key => {
            const value = this.trackmapOrg.get(key);
            this.trackmapData.push({key,
                value});
        });
        
        saveTracking({
            metaId,
            "selectedVal": event.target.value,
            "selectedValLabel": optLabel
        }).
            then((result) => {

                if (result) {

                    this.errorFlag = true;
                    this.message = "Tracking Category Default Updated.";
                    this.variant = "success";

                } else {

                    this.errorFlag = true;
                    this.message = "Something went wrong.";
                    this.variant = "error";

                }
                this.showLoading = false;

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
                    this.variant = "error";
                    this.showToastPopMessage(errorMsg, this.variant);
                    this.showLoading = false;

                }
            });

    }

    handleChange (event) {

        this.savedisable = false;
        const {name} = event.target;
        if (name === "Draft") {

            this.invoiceConfig.draft = event.target.checked;

        } else if (name === "submit") {

            this.invoiceConfig.submit = event.target.checked;

        } else if (name === "approved") {

            this.invoiceConfig.approved = event.target.checked;

        } else if (name === "approveandEmail") {

            this.invoiceConfig.approvedEmail = event.target.checked;

        } else if (name === "Taxrate") {

            this.invoiceConfig.taxRate = event.target.value;

        } else if (name === "AccCodes") {

            this.invoiceConfig.accCode = event.target.value;
            // const accEle = this.accountCodeArr.find((ele) => ele.numberCode === Number(event.target.value));
            const accEle = this.accountCodeArr.find((ele) => ele.numberCode === event.target.value);
            this.invoiceConfig.taxRate = accEle.value;

        } else if (name === "taxType") {

            this.invoiceConfig.invtaxType = event.target.value;

        } else if (name === "Invoice Template") {

            this.invoiceConfig.invTemplate = event.target.value;

        }

    }

    refreshInvoiceFields () {

        getsObjectFieldMap({
            "sObjectType": "Opportunity"
        }).
            then((result) => {

                if (result) {

                    const obj = {};
                    obj.opportunityFieldMap = result;
                    this.errorFlag = true;
                    this.message = "Opportunity fields are refreshed.";
                    this.variant = "success";
                    this.prepareOpportunityFields(obj);

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
                    this.variant = "error";
                    // this.showToastPopMessage(errorMsg, this.variant);
                    this.message = errorMsg;

                    this.showLoading = false;

                }
                

            });

    }

    handleSave () {

        this.showLoading = true;
        const ar = [
                "draft",
                "submit",
                "approved",
                "approvedEmail",
                "taxRate",
                "accCode"
            ],
            counter = 1;
        let valid = false;
        // Const counter = 1;
        for (let ele = 0; ele < ar.length; ele += counter) {

            if (this.invoiceConfig[ar[ele]] && this.invoiceConfig[ar[ele]] === true) {

                valid = true;

            }

        }

        if (valid === false) {

            this.invoiceConfig.draft = true;

        }

        this.prepareInvoiceSetupData();
        updateConfig({
            "configData": JSON.stringify(this.invoiceConfig)
        }).then((result) => {

            if (result) {

                this.errorFlag = true;
                this.message = "Invoice Configuration is Updated.";
                this.variant = "success";

                this.savedisable = true;

            } else {

                this.errorFlag = true;
                this.message = "Something went wrong.";
                this.variant = "error";
            }
            this.showLoading = false;

        }).
            catch((error) => {

                // this.showLoading = false;
                // this.errorFlag = true;
                // this.message = "Something went wrong. "+error.body.message;
                // this.variant = "error";

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
                    this.showToastPopMessage(errorMsg, this.variant);
                    this.showLoading = false;

                }

            });

    }

    handleRefresh (event) {

        const {name} = event.target;
        if (name === "Invoice Template") {

            this.invoiceTemplatesSync();

        } else if (name === "AccCodes") {

            this.accountsSync();

        } else if (name === "Taxrate") {

            this.taxRateSync();

        } else if (name === "tracking") {

            this.trackingSync();

        }

    }

    invoiceTemplatesSync () {

        syncInvoiceTemplates({}).
            then((result) => {

                if (result.successFlag) {

                    const templatesOption = [];
                    result.metadataList.forEach((element) => {

                        templatesOption.push({"label": element.text,
                            "value": element.value});

                    });
                    this.templateOptions = templatesOption;
                   
                    this.errorFlag = true;
                    this.message = "Invoice templates updated succesfully.";
                    this.variant = "success";

                } else {

                    this.errorFlag = true;
                    this.message = "Something went wrong. "+result.message;
                    this.variant = "error";

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
                    this.variant = "error";
                    this.showToastPopMessage(errorMsg, this.variant);
                    this.showLoading = false;

                }

            });

    }

    accountsSync () {

        syncAccounts({}).
            then((result) => {

                if (result.successFlag) {

                    const accOptionsArr = [];
                    result.metadataList.forEach((element) => {

                        accOptionsArr.push({"label": element.text,
                            "value": `${element.numberCode}`});

                    });
                    this.accOptions = accOptionsArr;
                  
                    this.errorFlag = true;
                    this.message = "Accounting Codes updated succesfully.";
                    this.variant = "success";

                } else {

                    this.errorFlag = true;
                    this.message = "Something went wrong. "+result.message;
                    this.variant = "error";

                }

            }).
            catch((error) => {

                // this.errorFlag = true;
                // this.message = "Something went wrong. "+error.body.message;
                // this.variant = "error";
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
                    this.message = "Something went wrong. "+errorMsg;
                    this.variant = "error";
                    // this.showToastPopMessage(errorMsg, this.variant);
                    this.showLoading = false;

                }

            });

    }

    taxRateSync () {

        syncTaxRate({}).
            then((result) => {

                if (result.successFlag) {

                    const taxOptionsArr = [];
                    result.metadataList.forEach((element) => {

                        taxOptionsArr.push({"label": element.text,
                            "value": element.code});

                    });
                    this.taxOptions = taxOptionsArr;
                    this.errorFlag = true;
                    this.message = "TaxRates Updated Succesfully.";
                    this.variant = "success";

                } else {

                    this.errorFlag = true;
                    this.message = "Something went wrong. "+result.message;
                    this.variant = "error";

                }

            }).
            catch((error) => {

                // this.errorFlag = true;
                // this.message = "Something went wrong. "+error.body.message;
                // this.variant = "error";
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
                    this.showToastPopMessage(errorMsg, this.variant);
                    this.showLoading = false;

                } 

            });

    }

    trackingSync () {

        syncTracking({}).
            then((result) => {

                if (result.successFlag) {

                    const tcArr = [],
                        tcOptArr = [];
                    result.metadataList.forEach((element) => {

                        if (element.type === "tracking_category") {

                            tcArr.push(element);

                        } else if (element.type === "tracking_category_option") {

                            tcOptArr.push(element);

                        }

                    });
                    let tcMap = new Map();
                    tcMap = createTrackingMap(
                        tcArr,
                        tcOptArr
                    );

                    this.trackmapOrg = tcMap;
                    this.trackmapData = [];

                    let keys = [...tcMap.keys()];

                    keys.forEach(key => {
                        const value = tcMap.get(key);
                        this.trackmapData.push({key,
                            value});
                    });

                    this.errorFlag = true;
                    this.message = "Tracking Categories Updated Succesfully.";
                    this.variant = "success";

                    this.showLoading = false;

                } else {

                    this.errorFlag = true;
                    this.message = result.message;
                    this.variant = "error";
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

                    
                    this.variant = "error";
                    this.showToastPopMessage(errorMsg, this.variant);
                    this.showLoading = false;

                }

            });

    }

    

    displayHelpText () {

        this.showHelpTextFlag = true;

    }

    hideHelpText () {

        this.showHelpTextFlag = false;

    }
    
    showToastPopMessage (messageParam, variantParam) {

        const evt = new ShowToastEvent({
            "message": messageParam,
            "title": "Invoice Configuration",
            "variant": variantParam
        });
        this.dispatchEvent(evt);

    }

    renderedCallback(){
        if(this.message !== '' && this.variant !== '' && this.errorFlag === true){

            this.showToastPopMessage(this.message, this.variant);
            this.errorFlag = false;
        }
    }


}