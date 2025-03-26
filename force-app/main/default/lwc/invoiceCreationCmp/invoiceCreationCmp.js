import {LightningElement, api, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getCurrency from "@salesforce/apex/InvoiceCreationController.getCurrency";
import getMetadata from "@salesforce/apex/InvoiceConfigurationController.taxRateAndAccFetchMethod";
import getOppCurrency from "@salesforce/apex/InvoiceCreationController.getOppCurrency";
import getOpportunityProducts from "@salesforce/apex/InvoiceCreationController.getOpportunityProducts";
import getProductList from "@salesforce/apex/InvoiceCreationController.getProductList";
import getinvoiceOppMapping from "@salesforce/apex/InvoiceCreationController.getinvoiceOppMapping";
import insertLog from "@salesforce/apex/Utils.insertLog";
const countlineItemTotal = function countlineItemTotal (quantity, price, discount) {

        const discountCheck = 0,
            num100 = 100,
            num2 = 2,
            qtyCal = price * quantity;

        let discountCal = 0,
            totalValue1 = 0,
            totalValue2 = 0;

        if (discount === discountCheck) {

            totalValue2 = qtyCal;

        } else {

            discountCal = discount / num100;
            totalValue1 = qtyCal * discountCal;
            totalValue2 = qtyCal - totalValue1;

        }

        return totalValue2.toFixed(num2);

    },

    createTrackingMap = function createTrackingMap (tcArr, tcOptArr) {

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
                            newObj.optname = element.xeroId;

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

export default class InvoiceCreationCmp extends LightningElement {

    @api recordId;

    @api accountDetails;

    @api contactDetails;

    @api lineItem;

    @api lineItemsData;

    @track showLoadingSpinner = false;

    @track templateOptions;

    @track taxOptions;

    @track accountOptions;

    @track regionOptions;

    @track templateValue;

    @track invoiceDate;

    @track invoicedueDate;

    @track lineitemsRecords = [];

    @track amountTaxValue = "Inclusive";

    @track invoiceSubtotal;

    @track taxRates;

    @track taxShow = false;

    @track taxMap = [];

    trackmapData = [];

    @track invoiceTotal;

    @track includes = "Includes";

    @track trackingCategoryArr = [];

    @track accountCodeArr = [];

    @track trackmapOrg = [];

    @track opportunity;

    @track invoiceCustomSettings;

    @track showProductCode = false;

    @track defaultAccount;

    @track defaultTaxRate;

    @track taxDisable = false;

    @track CurrencyIsoCode;

    @track currencyOptions = [];

    @track amountTaxOptions = [
        {"label": "Tax Exclusive",
            "value": "Exclusive"},
        {"label": "Tax Inclusive",
            "value": "Inclusive"},
        {"label": "No Tax",
            "value": "NoTax"}
    ];

    @track filteredProducts;

    @track inputValue = "";

    @track showDropdown = false;

    @track prodList = [];

    @track proVal;

    @track errorList = [];

    @track disableDelete = false;

    @api get invoiceConfig () {

        return this.invoiceConfig;

    }

    @track preventClosingOfSerachPanel = false;

    @track errorFlag = false;

    @track title = '';
    
    @track message = '';
    
    @track variant = '';

    @track lineItemDesc;

    @api isOpportunityInvoice;

    set invoiceConfig (value) {

        this.invoiceCustomSettings = value;
        
        if (value.invtaxType !== "") {

            this.amountTaxValue = value.invtaxType;

        }
        if (value.invTemplate !== "") {

            this.templateValue = value.invTemplate;

        }
        if (value.accCode !== null) {

            // this.defaultAccount = Math.floor(value.accCode);
            this.defaultAccount = value.accCode;

        }
        if (value.taxRate) {

            this.defaultTaxRate = value.taxRate;

        } else {

            this.defaultTaxRate = "";

        }
        if (value.lineItemDescription != null) {

            this.lineItemDesc = value.lineItemDescription;

        } else {

            this.lineItemDesc = "";

        }

    }

    @api get showLoading () {

        return this.showLoadingSpinner;

    }

    set showLoading (value) {

        this.showLoadingSpinner = value;

    }

    handleBlur (event) {

        const li = this.lineitemsRecords.find((element) => element.id === event.target.dataset.id);
        li.showDropdown = false;
        this.preventClosingOfSerachPanel = false;

    }

    // Handle the click inside the search panel to prevent it getting closed
    handleDivClick () {

        this.preventClosingOfSerachPanel = true;

    }

    handleMouseOut (event) {

        const li = this.lineitemsRecords.find((element) => element.id === event.target.dataset.id);
        li.showDropdown = false;

    }

    handleMouseIn (event) {

        const li = this.lineitemsRecords.find((element) => element.id === event.target.dataset.id);
        li.showDropdown = true;

    }

    handleInputBlur (event) {

        const eventId = event.target.dataset.id;

        if (!this.preventClosingOfSerachPanel) {

            const li = this.lineitemsRecords.find((element) => element.id === eventId);
            li.showDropdown = false;

            this.preventClosingOfSerachPanel = false;

        }

    }

    selectItem (event) {
        this.showLoadingSpinner = false;
        const liId = event.target.dataset.id,
            selectedVal = event.target.dataset.item;
        if (selectedVal) {

            // Get product info
            const ele = this.filteredProducts.find((element) => element.id === selectedVal),
                li = this.lineitemsRecords.find((element) => element.id === liId);
            
            li.inputValue = `${ele.productCode}: ${ele.name}`;
            li.xeroItemID = ele.xeroItemId;
            li.productCode = ele.productCode;
            li.productName = ele.name;
            li.productId = ele.id;

            if (this.lineItemDesc === "Product Description") {

                li.description = ele.prodDescription;

            } else if (this.lineItemDesc === "Xero Item Sales Description") {

                li.description = ele.salesDescription;

            }

            li.account = ele.salesAccountCode != '' ? ele.salesAccountCode : this.defaultAccount;
            li.taxRate = ele.salesTaxRate != '' ? ele.salesTaxRate : this.defaultTaxRate;
            li.showDropdown = false;

        }
        this.showLoadingSpinner = true;
    }

    connectedCallback () {

        
        if (this.isOpportunityInvoice) {
            
            this.getOppCurrency();
            this.getOpportunityMapping();
            
        }
        
        this.getCurrency();
        this.getXeroMetadata();

    }

    filterOptions (event) {

        this.lineitemsRecords.forEach((element) => {

            if (element.id !== event.target.dataset.id) {

                element.showDropdown = false;

            }

        });

        const li = this.lineitemsRecords.find((ele) => ele.id === event.target.dataset.id);
        li.inputValue = event.target.value;
        this.filterProducts(li);


    }

    filterProducts (li) {

        this.showLoadingSpinner = false;
        getProductList({
            "inputVal": li.inputValue
        }).
            then((result) => {

                if (result) {
                    
                    const prodList1 = [];
                    result.forEach((element) => {

                        prodList1.push({"label": element.Name,
                            "value": element.id});

                    });
                    this.prodList = [...prodList1];
                    this.filteredProducts = result;
                    li.showDropdown = true;

                }
                this.showLoadingSpinner = true;

            }).
            catch((error) => {

                this.showLoadingSpinner = true;
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
                }

            });

    }


    getOppCurrency () {

        getOppCurrency({"recordId": this.recordId}).
            then((result) => {

                if (result !== "" ||
                    result !== null || typeof result !== "undefined") {

                    const test = result;
                    this.currencyIsoCode = test;

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
                }

            });

    }

    getCurrency () {

        const currecyArr = [];
        getCurrency({}).
            then((result) => {

                result.forEach((element) => {

                    currecyArr.push({"label": element,
                        "value": element});

                });
                this.currencyOptions = currecyArr;

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
                }

            });

    }

    currencyhandleChange (event) {

        this.currencyIsoCode = event.target.value;

    }

    getOpportunityMapping () {

        getinvoiceOppMapping({
            "recordId": this.recordId
        }).
            then((result) => {

                if (result) {

                    if (result.dueDate !== null) {

                        this.invoicedueDate = result.dueDate;

                    }

                    if (result.invDate !== null) {

                        this.invoiceDate = result.invDate;

                    }

                    if (result.reference !== "") {

                        this.refValue = result.reference;

                    }

                    if (result.currencyIsoCode !== "") {

                        const test = result.currencyIsoCode;
                        this.CurrencyIsoCode = test;

                    }

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
                }

            });

    }

    getXeroMetadata () {

        this.showLoadingSpinner = false;
        const num1 = 1,
            num16 = 16,
            num36 = 36,
            num7 = 7;
        getMetadata({}).
            then((result) => {

                const
                    accountArr = [],
                    accountCodeArr = [],
                    regionArr = [],
                    taxOptions = [],
                    taxRatesArr = [],
                    tcArr = [],
                    tcOptArr = [],
                    templatesOption = [],
                    trackingArr = [];

                result.forEach((element) => {

                    if (element.type === "Invoice Template") {

                        templatesOption.push({"label": element.text,
                            "value": element.value});

                    } else if (element.type === "TaxRate") {

                        taxOptions.push({"label": element.text,
                            "value": element.code});
                        taxRatesArr.push(element);

                    } else if (element.type === "Accounts") {

                        accountArr.push({"label": element.text,
                            "value": `${element.numberCode}`});
                        accountCodeArr.push(element);

                    } else if (element.type === "tracking_category") {

                        tcArr.push(element);

                    } else if (element.type === "tracking_category_option") {

                        tcOptArr.push(element);

                    }

                });

                this.templateOptions = templatesOption;
                this.taxOptions = taxOptions;
                this.taxRates = taxRatesArr;
                this.accountOptions = accountArr;
                this.regionOptions = regionArr;
                this.trackingCategoryArr = trackingArr;
                this.accountCodeArr = accountCodeArr;

                let tcMap = new Map();
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

                if (this.lineItem === "prepopulate") {

                    this.showProductCode = true;
                    if(!this.lineItemsData){
                        // this.lineitemsRecords.push(myNewElement);
                        this.getProducts(this.trackmapData);
                    }else{
                        let lineItemsRecs = JSON.parse(JSON.stringify(this.lineItemsData));
                        this.lineitemsRecords = lineItemsRecs.lineItems;
                    }

                } else if (this.lineItem === "blank") {

                    const arandomId = `${Math.random() * num16}${(Math.random() + num1).toString(num36).substring(num7)}`,
                        myNewElement = {"account": `${this.defaultAccount}`,
                            "amount": 0,
                            "description": "",
                            "discount": 0,
                            "id": arandomId.toString(num36),
                            "inputValue": "",
                            "name": "",
                            "productCode": "",
                            "productId": "",
                            "productName": "",
                            "quantity": 0,
                            "showDropdown": false,
                            "taxCount": 0,
                            "taxRate": this.defaultTaxRate,
                            "trackingData": [...this.trackmapData],
                            "unitPrice": 0,
                            "xeroItemID": ""};
                    
                    if (this.amountTaxValue === "NoTax") {

                        myNewElement.taxRate = "NONE";
                        this.taxDisable = true;
                    }
                    
                    if(!this.lineItemsData){
                        this.lineitemsRecords.push(myNewElement);
                    }else{
                        let lineItemsRecs = JSON.parse(JSON.stringify(this.lineItemsData));
                        this.lineitemsRecords = lineItemsRecs.lineItems;
                    }
                    this.showProductCode = false;
                    this.countValues();

                }
                this.disableDelete = true;
                this.showLoadingSpinner = true;

            }).
            catch((error) => {

                this.error = error;
                this.showLoadingSpinner = true;
                
                this.errorFlag = true;
                this.title = "Something Went Wrong";
                this.message = error.body.message;
                this.variant = "error";

            });

    }

    handleTracking (event) {

        const deepCopy = new Map(JSON.parse(JSON.stringify(Array.from(this.trackmapOrg)))),
            foundElement = this.lineitemsRecords.find((ele) => ele.id === event.target.dataset.id),
            keyName = event.target.name,
            newMap = new Map(foundElement.trackingData.map((obj) => [
                obj.key,
                obj.value
            ]));
        foundElement.trackingData = [];

        let keys = [...deepCopy.keys()];

        keys.forEach(key => {
            let value = deepCopy.get(key);

            if (key === keyName) {

                value.defaultVal = event.target.value;
                value.optname = event.target.options.find((opt) => opt.value === event.target.value).label;

            } else {

                const val = newMap.get(key);
                value.defaultVal = val.defaultVal;
                value.optname = val.optname;

            }
            foundElement.trackingData.push({value,key});

        });

    }

    getProducts (trackmapInfo) {

        const num1 = 1;
        getOpportunityProducts({
            "oppId": this.recordId
        }).
            then((result) => {

                if (result) {

                    result.forEach((element) => {

                        if (this.defaultAccount !== null && typeof this.defaultAccount !== "undefined") {

                            if (!element.account) {

                                element.account = `${this.defaultAccount}`;
                                
                            }


                        }
                        if (this.defaultTaxRate !== null && typeof this.defaultTaxRate !== "undefined") {

                            if (!element.taxRate) {

                                element.taxRate = this.defaultTaxRate;

                            }

                        }
                        element.trackingData = [...trackmapInfo];

                    });
                    this.lineitemsRecords = result;
                    if (this.lineitemsRecords.length === num1) {

                        this.disableDelete = true;

                    } else {

                        this.disableDelete = false;

                    }
                    this.countValues();

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
                }

            });

    }

    countValues () {

        this.countsubTotal();
        this.countTax();
        this.countInvoiceTotal();

    }

    removeClick (event) {

        const num1 = 1;
        if (this.lineitemsRecords.length > num1) {

            this.disableDelete = false;
            this.lineitemsRecords.splice(
                this.lineitemsRecords.findIndex((row) => row.id === event.target.dataset.id),
                num1
            );
            this.countValues();

        }
        if (this.lineitemsRecords.length === num1) {

            this.disableDelete = true;

        }

    }


    updateDecimalPlaces (event) {


        const format = /[ `!@#$%^&*()_+\-=\\[\]{};':"\\|,<>\\/?~]/u,
            foundelement = this.lineitemsRecords.find((ele) => ele.id === event.target.dataset.id),
            num100 = 100,
            num1000 = 1000;

        if (event.target.name === "Quantity") {


            if (format.test(event.target.value)) {

                this.errorFlag = true;
                this.title = "Error";
                this.message = "Please enter valid value in Quantity";
                this.variant = "error";

                foundelement.quantity = String(event.target.value);

            } else if (isNaN(event.target.value)) {

                this.errorFlag = true;
                this.title = "Error";
                this.message = "Please enter valid value in Quantity";
                this.variant = "error";

                foundelement.quantity = String(event.target.value);

            } else {

                const targetVal = event.target.value;
                if (!targetVal) {

                    foundelement.quantity = 0;
                    event.target.value = 0;

                }
                foundelement.quantity = Number(Math.round(Number(event.target.value) * num1000)) /
                                     num1000;
                foundelement.amount = Number(countlineItemTotal(
                    foundelement.quantity,
                    foundelement.unitPrice,
                    foundelement.discount
                ));
                this.countsubTotal();
                this.countTax();
                this.countInvoiceTotal();


            }


        } else if (event.target.name === "Unit Price") {

            if (format.test(event.target.value)) {

                this.errorFlag = true;
                this.title = "Error";
                this.message = "Please enter valid Unit Price";
                this.variant = "error";

                foundelement.unitPrice = String(event.target.value);

            } else if (isNaN(event.target.value)) {

                this.errorFlag = true;
                this.title = "Error";
                this.message = "Please enter valid Unit Price";
                this.variant = "error";

                foundelement.quantity = String(event.target.value);

            } else {

                const targetVal = event.target.value,
                    uPrice = Number(event.target.value);

                if (!targetVal) {

                    foundelement.unitPrice = 0;
                    event.target.value = 0;

                }

                foundelement.unitPrice = Number(Math.round(uPrice * num1000)) / num1000;
                foundelement.amount = Number(countlineItemTotal(
                    foundelement.quantity,
                    foundelement.unitPrice,
                    foundelement.discount
                ));
                this.countsubTotal();
                this.countTax();
                this.countInvoiceTotal();


            }

        } else if (event.target.name === "Discount") {

            if (format.test(event.target.value)) {

                this.errorFlag = true;
                this.title = "Error";
                this.message = "Please enter valid Discount.";
                this.variant = "error";

                foundelement.discount = String(event.target.value);

            } else if (isNaN(event.target.value)) {

                this.errorFlag = true;
                this.title = "Error";
                this.message = "Please enter valid Discount.";
                this.variant = "error";

                foundelement.quantity = String(event.target.value);

            } else {

                const targetVal = event.target.value;
                if (!targetVal) {

                    foundelement.discount = 0;
                    event.target.value = 0;

                }
                foundelement.discount = Number(Math.round(Number(event.target.value) * num100)) / num100;
                foundelement.amount = Number(countlineItemTotal(
                    foundelement.quantity,
                    foundelement.unitPrice,
                    foundelement.discount
                ));
                this.countsubTotal();
                this.countTax();
                this.countInvoiceTotal();

            }

        }

    }

    updateValues (event) {

        const foundelement = this.lineitemsRecords.find((ele) => ele.id === event.target.dataset.id);

        if (event.target.name === "TaxRate") {

            foundelement.taxRate = event.target.value;
            this.countTax();
            this.countInvoiceTotal();
            this.taxShow = true;

        } else if (event.target.name === "Account") {

            const accEle = this.accountCodeArr.find((ele) => ele.numberCode === event.target.value),
                test = event.target.value;
            foundelement.account = test;
            if (this.amountTaxValue !== "NoTax") {

                foundelement.taxRate = accEle.value;
                this.countTax();
                this.countInvoiceTotal();
                this.taxShow = true;

            } else {

                foundelement.taxRate = "NONE";

            }

        } else if (event.target.name === "Region") {

            foundelement.region = event.target.value;
            const trackele = this.trackingCategoryArr.find((ele) => ele.value === event.target.value);
            foundelement.trackingName = trackele.code;
            foundelement.trackingOption = trackele.text;

        } else if (event.target.name === "Description") {

            foundelement.description = event.target.value;

        }

    }

    countTax () {

        this.showLoadingSpinner = false;
        const lineitemarr = this.lineitemsRecords,
            num0 = 0,
            num1 = 1,
            num100 = 100,
            taxM = [];
        for (let ind = 0; ind < lineitemarr.length; ind += num1) {

            let taxAmount = 0,
                taxelement = {};
            if (lineitemarr[ind].taxRate) {

                taxelement = this.taxRates.find((ele) => ele.code === lineitemarr[ind].taxRate);
                if (this.amountTaxValue === "Exclusive") {

                    const t1 = lineitemarr[ind].amount *
                        Number(taxelement.value);
                    taxAmount = t1 / num100;

                } else if (this.amountTaxValue === "Inclusive") {

                    const t1 = lineitemarr[ind].amount *
                        Number(taxelement.value),
                        t2 = num100 + Number(taxelement.value);
                    taxAmount = t1 / t2;

                } else if (this.amountTaxValue === "NoTax") {

                    break;

                }
                lineitemarr[ind].taxCount = taxAmount;

                if (taxM.length > num0) {

                    const tIndex = taxM.findIndex((ele) => ele.key === taxelement.text);
                    if (tIndex >= num0) {

                        const newVal = taxM[tIndex].value + taxAmount;
                        taxM[tIndex].value = newVal;

                    } else {

                        taxM.push({"key": `${taxelement.text} ${taxelement.value} %`,
                            "value": taxAmount});

                    }

                } else {

                    taxM.push({"key": `${taxelement.text} ${taxelement.value} %`,
                        "value": taxAmount});

                }

            }

        }
        this.taxMap = taxM;
        this.taxShow = true;
        this.lineitemsRecords = lineitemarr;
        this.showLoadingSpinner = true;

    }

    countInvoiceTotal () {

        let total = 0;
        const lineitemarr = this.lineitemsRecords,
            num1 = 1;
        for (let ind = 0; ind < lineitemarr.length; ind += num1) {

            total += Number(lineitemarr[ind].amount);
            if (this.amountTaxValue === "Exclusive" &&
                    lineitemarr[ind].taxCount !== null) {

                total += Number(lineitemarr[ind].taxCount);

            }

        }
        this.invoiceTotal = total;

    }

    countsubTotal () {

        const num1 = 1,
            temparr = this.lineitemsRecords;
        let subTotal = 0;
        for (let ind = 0; ind < temparr.length; ind += num1) {

            subTotal += Number(temparr[ind].amount);

        }
        this.invoiceSubtotal = subTotal;

    }

    addlineitemClick () {

        const a1 = 1,
            a16 = 16,
            a36 = 36,
            a7 = 7,
            arandomId = `${Math.random() * a16}${(Math.random() + a1).toString(a36).substring(a7)}`,
            arrtrackMap = this.trackmapData,
            myNewElement = {"account": `${this.defaultAccount}`,
                "amount": 0,
                "description": "",
                "discount": 0,
                "id": arandomId.toString(a36),
                "name": "",
                "productCode": "",
                "productId": "",
                "productName": "",
                "quantity": 0,
                "taxCount": 0,
                "taxRate": this.defaultTaxRate,
                "trackingData": [...arrtrackMap],
                "unitPrice": 0};

        if (this.amountTaxValue === "NoTax") {

            myNewElement.taxRate = "NONE";

        }

        this.lineitemsRecords = [
            ...this.lineitemsRecords,
            myNewElement
        ];
        if (this.lineitemsRecords === a1) {

            this.disableDelete = true;

        } else {

            this.disableDelete = false;

        }
        this.countValues();

    }

    amounttaxhandleChange (event) {

        this.amountTaxValue = event.detail.value;
        if (event.detail.value === "Exclusive") {

            this.includes = "";
            this.taxDisable = false;
            this.lineitemsRecords.forEach((element) => {

                const accEle = this.accountCodeArr.find((ele) => ele.numberCode === Number(element.account));
                element.taxRate = accEle.value;

            });

        } else if (event.detail.value === "Inclusive") {

            this.includes = "Includes";
            this.taxDisable = false;
            this.lineitemsRecords.forEach((element) => {

                const accEle = this.accountCodeArr.find((ele) => ele.numberCode === Number(element.account));
                element.taxRate = accEle.value;

            });

        } else if (event.detail.value === "NoTax") {

            this.includes = "";
            this.taxDisable = true;
            this.lineitemsRecords.forEach((element) => {

                element.taxRate = "NONE";

            });

        }
        this.countTax();
        this.countInvoiceTotal();

    }

    fieldshandleChange (event) {

        if (event.target.name === "Invoice Template") {

            this.templateValue = event.target.value;

        } else if (event.target.name === "Invoice Due Date") {

            this.invoicedueDate = event.target.value;

        } else if (event.target.name === "Invoice Date") {

            this.invoiceDate = event.target.value;

        } else if (event.target.name === "Reference") {

            this.refValue = event.target.value;

        }

    }

    @api handledraftSave () {

        const err = [],
            field = [],
            format = /[ `!@#$%^&*()_+\-=\\[\]{};':"\\|,<>\\/?~]/u,
            loopVal = 1,
            minVal = 0,
            newEle = {"errors": [],
                "fields": field,
                "save": true};

        if (typeof this.templateValue === "undefined" ||
                this.templateValue === null ||
                this.templateValue === "") {

            newEle.save = false;
            newEle.fields.push("Invoice template");

        }

        if (typeof this.invoiceDate === "undefined" ||
                this.invoiceDate === null ||
                this.invoiceDate === "") {

            newEle.save = false;
            newEle.fields.push("Invoice Date");

        }

        // To show error message for invalid Quantity, Price and Discount
        if (this.lineitemsRecords.length > minVal) {

            const lineitemarr = this.lineitemsRecords;
            for (let ind = 0; ind < lineitemarr.length; ind += loopVal) {

                if (lineitemarr[ind].quantity !== null && typeof lineitemarr[ind].quantity !== "undefined" && lineitemarr[ind].quantity !== "") {

                    if (format.test(lineitemarr[ind].quantity) || typeof lineitemarr[ind].quantity === "string") {

                        if (!err.includes("Quantity")) {

                            err.push("Quantity");

                        }

                        newEle.save = false;

                    }

                } else {

                    lineitemarr[ind].quantity = 0;

                }

                if (lineitemarr[ind].unitPrice !== null && typeof lineitemarr[ind].unitPrice !== "undefined" && lineitemarr[ind].unitPrice !== "") {

                    if (format.test(lineitemarr[ind].unitPrice) || typeof lineitemarr[ind].unitPrice === "string") {

                        if (!err.includes("Unit Price")) {

                            err.push("Unit Price");

                        }

                        newEle.save = false;

                    }

                } else {

                    lineitemarr[ind].unitPrice = 0;

                }

                if (lineitemarr[ind].discount !== null && typeof lineitemarr[ind].discount !== "undefined" && lineitemarr[ind].discount !== "") {

                    if (format.test(lineitemarr[ind].discount) || typeof lineitemarr[ind].discount === "string") {

                        if (!err.includes("Discount")) {

                            err.push("Discount");

                        }

                        newEle.save = false;

                    }

                } else {

                    lineitemarr[ind].discount = 0;

                }

            }


        }

        if (err.length > minVal) {

            newEle.errors = [...err];

        } else {

            newEle.errors = [];

        }


        this.dispatchEvent(new CustomEvent(
            "draftsave",
            {
                "detail": newEle
            }
        ));

    }

    @api handleApprovedSave () {

        const err = [],
            format = /[ `!@#$%^&*()_+\-=\\[\]{};':"\\|,<>\\/?~]/u,
            field = [],
            loopVal = 1,
            minVal = 0,
            newEle = {"errors": [],
                "fields": field,
                "save": true};

        if (typeof this.templateValue === "undefined" ||
                this.templateValue === null ||
                this.templateValue === "") {

            newEle.save = false;
            newEle.fields.push("Invoice template");

        }

        if (typeof this.invoiceDate === "undefined" ||
                this.invoiceDate === null ||
                this.invoiceDate === "") {

            newEle.save = false;
            newEle.fields.push("Invoice Date");

        }

        if (typeof this.invoicedueDate === "undefined" ||
                this.invoicedueDate === null ||
                this.invoicedueDate === "") {

            newEle.save = false;
            newEle.fields.push("Invoice Due Date");

        }

        if (this.lineitemsRecords.length > minVal) {

            const lineitemarr = this.lineitemsRecords;
            for (let ind = 0; ind < lineitemarr.length; ind += loopVal) {

                if (lineitemarr[ind].account === "" || (typeof lineitemarr[ind].account === "undefined" || lineitemarr[ind].account === "NaN")) {

                    if (!err.includes("Account")) {

                        err.push("Account");

                    }

                    newEle.save = false;

                }
                if (lineitemarr[ind].taxRate === "" || typeof lineitemarr[ind].taxRate === "undefined") {

                    if (!err.includes("TaxRate")) {

                        err.push("TaxRate");

                    }

                    newEle.save = false;

                }
                if (format.test(lineitemarr[ind].quantity) || typeof lineitemarr[ind].quantity === "string") {

                    if (!err.includes("Quantity")) {

                        err.push("Quantity");

                    }

                    newEle.save = false;

                }

                if (format.test(lineitemarr[ind].unitPrice) || typeof lineitemarr[ind].unitPrice === "string") {

                    if (!err.includes("Unit Price")) {

                        err.push("Unit Price");

                    }

                    newEle.save = false;

                }

                if (format.test(lineitemarr[ind].discount) || typeof lineitemarr[ind].discount === "string") {

                    if (!err.includes("Discount")) {

                        err.push("Discount");

                    }

                    newEle.save = false;

                }
                if (lineitemarr[ind].description.trim() === "" ||
                    typeof lineitemarr[ind].description === "undefined") {

                    newEle.save = false;
                    if (!newEle.fields.includes("Lineitem Description")) {

                        newEle.fields.push("Lineitem Description");

                    }
                    // Break;

                }


            }


        } else {

            newEle.save = false;
            if (!newEle.fields.includes("Lineitem Description")) {

                newEle.fields.push("Lineitem Description");

            }

        }

        if (err.length > minVal) {

            newEle.errors = [...err];

        }

        this.dispatchEvent(new CustomEvent(
            "approvedsave",
            {
                "detail": newEle
            }
        ));

    }

    @api invoiceData () {

        const curr = this.currencyIsoCode,
            ele = {"accountId": this.accountDetails.accId,
                "amountTax": this.amountTaxValue,
                "currencyCode": curr,
                "invoicedate": this.invoiceDate,
                "invoiceduedate": this.invoicedueDate,
                "lineItems": this.lineitemsRecords,
                "recordId": this.recordId,
                "reference": this.refValue,
                "template": this.templateValue};
        this.dispatchEvent(new CustomEvent(
            "invoicedata",
            {
                "detail": ele
            }
        ));

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