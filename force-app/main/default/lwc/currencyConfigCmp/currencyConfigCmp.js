import {LightningElement, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import createXeroCurrencies from "@salesforce/apex/CurrencyConfigController.createXeroCurrencies";
import getCurrency from "@salesforce/apex/CurrencyConfigController.getCurrency";
import getCurrencyURL from "@salesforce/apex/Utils.getSFURL";
import getIsMultiCurrencyOrg from "@salesforce/apex/Utils.getIsMultiCurrencyOrg";
import insertLog from "@salesforce/apex/Utils.insertLog";

export default class CurrencyConfigCmp extends LightningElement {

    @track isMultiCurrencyOrg;

    @track XeroCurr = [];

    @track salesforceCurr = [];

    @track currencyURL = "";

    @track currencyObj = [];

    @track syncedCurr = [];

    @track notSyncedSales = [];

    @track notSyncedXero = [];

    @track showPositiveButton = true;

    @track showNegativeButton = false;

    @track positiveButtonLabel = "";

    @track showModal = false;

    @track showLoading = false;

    @track showCurr = false;

    @track errorFlag = false;
    @track title = '';
    @track message = '';
    @track variant = '';
    @track error;

    connectedCallback () {

        this.getIsMultiCurrencyOrg();

    }

    getCurrencyURL () {

        const minlength = 0;
        this.showLoading = true;
        getCurrencyURL({
            "entity": "Currency"
        }).
            then((result) => {

                if (result.length > minlength) {

                    this.currencyURL = result;
                    this.showLoading = false;

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
                    this.title = "Something Went Wrong";
                    this.message = errorMsg;
                    this.variant = "error";
                    this.showToast(this.title, this.message, this.variant);
                    this.showLoading = false;
                }
            });

    }

    OpenCurrencyLayout () {

        const url = this.currencyURL;
        window.open(
            url,
            "_blank"
        );

    }


    getCurrency () {

        const minlength = 0;
        this.showLoading = true;
        this.currencyObj = [];
        this.syncedCurr = [];
        this.notSyncedXero = [];
        this.notSyncedSales = [];
        getCurrency({}).
            then((result) => {
                if (result) {
                  
                    this.XeroCurr = result.xeroCurr;
                    
                    this.salesforceCurr = result.salesforceCurr;

                    this.salesforceCurr.forEach((element) => {

                        if (this.XeroCurr.includes(element)) {

                            this.currencyObj.push({"btnValue": `${element}-${element}`,
                                "salesCurr": element,
                                "syncBtn": true,
                                "xeroCurr": element});

                        } else {

                            this.currencyObj.push({"btnValue": `${element}-`,
                                "salesCurr": element,
                                "syncBtn": false,
                                "xeroCurr": "-"});

                        }

                    });

                    this.XeroCurr.forEach((element) => {

                        if (!this.salesforceCurr.includes(element)) {

                            this.currencyObj.push({"btnValue": `-${element}`,
                                "salesCurr": "-",
                                "syncBtn": false,
                                "xeroCurr": element});

                        }

                    });

                    if (this.currencyObj.length > minlength) {

                        this.showCurr = true;
                        this.currencyObj.forEach((element) => {

                            if (element.salesCurr !== "-" && element.xeroCurr !== "-") {

                                this.syncedCurr.push({"btnValue": `${element.btnValue}`,
                                    "salesCurr": element.salesCurr,
                                    "syncBtn": element.syncBtn,
                                    "xeroCurr": element.xeroCurr});

                            } else if (element.salesCurr === "-" && element.xeroCurr !== "-") {

                                this.notSyncedSales.push({"btnValue": `-${element.btnValue}`,
                                    "salesCurr": element.salesCurr,
                                    "syncBtn": element.syncBtn,
                                    "xeroCurr": element.xeroCurr});

                            } else if (element.salesCurr !== "-" && element.xeroCurr === "-") {

                                this.notSyncedXero.push({"btnValue": `${element.btnValue}-`,
                                    "salesCurr": element.salesCurr,
                                    "syncBtn": element.syncBtn,
                                    "xeroCurr": element.xeroCurr});

                            }

                        });

                        if (this.syncedCurr.length > minlength) {

                            this.syncedCurr.sort((item1, item2) => {

                                const curr1 = item1.salesCurr.toUpperCase(),
                                    curr2 = item2.salesCurr.toUpperCase(),
                                    minusNum = -1,
                                    plusNum = 1;
                                let returnVal = 1;
                                if (curr1 < curr2) {

                                    returnVal = minusNum;

                                }
                                if (curr1 > curr2) {

                                    returnVal = plusNum;

                                }
                                return returnVal;

                            });

                        }

                        if (this.notSyncedSales.length > minlength) {

                            this.notSyncedSales.sort((item1, item2) => {

                                const curr1 = item1.xeroCurr.toUpperCase(),
                                    curr2 = item2.xeroCurr.toUpperCase(),
                                    minusNum = -1,
                                    plusNum = 1;
                                let returnVal = 1;
                                if (curr1 < curr2) {

                                    returnVal = minusNum;

                                }
                                if (curr1 > curr2) {

                                    returnVal = plusNum;

                                }
                                return returnVal;

                            });

                        }

                        if (this.notSyncedXero.length > minlength) {

                            this.notSyncedXero.sort((item1, item2) => {

                                const curr1 = item1.salesCurr.toUpperCase(),
                                    curr2 = item2.salesCurr.toUpperCase(),
                                    minusNum = -1,
                                    plusNum = 1;
                                let returnVal = plusNum;
                                if (curr1 < curr2) {

                                    returnVal = minusNum;

                                }
                                if (curr1 > curr2) {

                                    returnVal = plusNum;

                                }
                                return returnVal;

                            });

                        }

                    } else {

                        this.showCurr = false;

                    }
                    if(this.isMultiCurrencyOrg){
                        this.getCurrencyURL();
                    }
                

                    this.showLoading = false;

                }

            }).
            catch((error) => {
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
                    this.title = "Something Went Wrong";
                    this.message = errorMsg;
                    this.variant = "error";
                    this.showToast(this.title, this.message, this.variant);
                    this.showLoading = false;
                }

            });

    }

    handleRefreshCurrency () {

        this.showLoading = true;
        this.getCurrency();
        this.showLoading = false;

    }

    handleSync (event) {

        const btnValue = event.target.value,
            // NewBtnValue1 = btnValue.replace("-",""),
            minlength = 0,
            newBtnValue = btnValue.replace(
                "-",
                ""
            ),
            position = btnValue.indexOf("-"),
            position0 = 0,
            position3 = 3;


        if (position === position0) {

            this.showInstruction();

        } else if (position === position3) {

            this.showLoading = true;
            const newBtnValue1 = btnValue.replace(
                    "-",
                    ""
                ),
                plusNum = 1;
            createXeroCurrencies({"xeroCurrTobeCreated": newBtnValue1}).
                then((result) => {

                    if (result === "Xero currency created succesfully.") {

                        if (this.notSyncedXero.length > minlength) {

                            let index = 0;
                            this.notSyncedXero.forEach((element) => {

                                if (element.salesCurr === newBtnValue) {

                                    index = this.notSyncedXero.indexOf(element);

                                }

                            });
                            this.notSyncedXero.splice(
                                index,
                                plusNum
                            );

                        }
                        this.getCurrency();

                        this.showCurr = true;
                        
                        this.errorFlag = true;
                        this.title = "Success";
                        this.message = result;
                        this.variant = "success";
                        this.showLoading = false;


                    } else {

                        this.showCurr = true;
                        this.errorFlag = true;
                        this.title = "Error";
                        this.message = result;
                        this.variant = "error";
                        this.showLoading = false;

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
                        this.title = "Something Went Wrong";
                        this.message = errorMsg;
                        this.variant = "error";
                        this.showToast(this.title, this.message, this.variant);
                        this.showLoading = false;

                    }

                    this.showLoading = false;
                    this.showCurr = false;

                });

        }

    }

    getIsMultiCurrencyOrg () {

        this.showLoading = true;
        getIsMultiCurrencyOrg({}).
            then((result) => {

                this.isMultiCurrencyOrg = result;
                this.getCurrency();
                // if(result){
                // }
                this.showLoading = false;

            }).
            catch((error) => {

                // this.error = error;
                // this.showLoading = false;
                // this.errorFlag = true;
                // this.title = "Something went wrong.";
                // this.message = error;
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
                    this.title = "Something Went Wrong";
                    this.message = errorMsg;
                    this.variant = "error";
                    this.showToast(this.title, this.message, this.variant);
                    this.showLoading = false;

                }

            });

    }


    showInstruction () {

        this.showModal = true;
        this.showPositiveButton = true;
        this.showNegativeButton = false;
        this.positiveButtonLabel = "Close";

    }

    closeModal () {

        this.showModal = false;

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