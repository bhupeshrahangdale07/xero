import { LightningElement, track } from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getObjectFields from "@salesforce/apex/InvoiceObjMappingController.getObjectFields";
import getChildObjects from "@salesforce/apex/InvoiceObjMappingController.getChildObjects";
import getSelectedObj from "@salesforce/apex/InvoiceObjMappingController.getSelectedObjects";
import getinvMapping from "@salesforce/apex/InvoiceObjMappingController.getInvoiceMappingCS";
import saveinvMapping from "@salesforce/apex/InvoiceObjMappingController.saveInvoiceMappingCS";
import getinvLIMapping from "@salesforce/apex/InvoiceObjMappingController.getInvoiceLIMappingCS";
import saveinvLIMapping from "@salesforce/apex/InvoiceObjMappingController.saveInvoiceLIMappingCS";
import getinvPayMapping from "@salesforce/apex/InvoiceObjMappingController.getInvoicePayMappingCS";
import saveinvPayMapping from "@salesforce/apex/InvoiceObjMappingController.saveInvoicePayMappingCS";
import getxcMapping from "@salesforce/apex/InvoiceObjMappingController.getXeroConMappingCS";
import savexcMapping from "@salesforce/apex/InvoiceObjMappingController.saveXeroConMappingCS";
import getbillMapping from "@salesforce/apex/InvoiceObjMappingController.getBillMappingCS";
import savebillMapping from "@salesforce/apex/InvoiceObjMappingController.saveBillMappingCS";
import getbillLiMapping from "@salesforce/apex/InvoiceObjMappingController.getBillLiMappingCS";
import savebillLiMapping from "@salesforce/apex/InvoiceObjMappingController.saveBillLiMappingCS";
import getbillPayMapping from "@salesforce/apex/InvoiceObjMappingController.getBillPayMappingCS";
import savebillPayMapping from "@salesforce/apex/InvoiceObjMappingController.saveBillPayMappingCS";

export default class InvoiceObjMapping extends LightningElement {
    @track showLoading = false;

    @track xeroConMappingIcon = 'utility:right';
    @track invMappingIcon = 'utility:right';
    @track invLIMappingIcon = 'utility:right';
    @track invPayMappingIcon = 'utility:right';
    @track BillMappingIcon = 'utility:right';
    @track BillLiMappingIcon = 'utility:right';
    @track BillPayMappingIcon = 'utility:right';
    
    @track showXeroConFieldMapping = false;
    @track showINVFieldMapping = false;
    @track showINVLIFieldMapping = false;
    @track showINVPayFieldMapping = false;
    @track showBillFieldMapping = false;
    @track showBillLiFieldMapping = false;
    @track showBillPayFieldMapping = false;
    
    @track invOptions = [];
    @track selectedInvoiceValue;

    @track isObjectSelectionRO = false;
    
    @track xeroConObjMappingDisable = true;
    @track invObjMappingDisable = true;
    @track invLIObjMappingDisable = true;
    @track invPayObjMappingDisable = true;
    @track billObjMappingDisable = true;
    @track billLiObjMappingDisable = true;
    @track billPayObjMappingDisable = true;
    
    @track selectedObjs; // To store the api name of the selected objects

    @track xeroConobjectAPI = ''; // Stores the object api name for the Xero Contact mapping
    @track invobjectAPI = ''; // Stores the object api name for the invoice mapping
    @track invLiObjectAPI = ''; // Stores the object api name for the invoice line item mapping
    @track invPayObjectAPI = ''; // Stores the object api name for the invoice payment mapping
    @track billObjectAPI = ''; // Stores the object api name for the bill mapping
    @track billLiObjectAPI = ''; // Stores the object api name for the bill lineitem mapping
    @track billPayObjectAPI = ''; // Stores the object api name for the bill payment mapping

    @track xeroConMapping; // To store the Xero Contact Object Mapping
    @track originalXCMapping; // To store the Xero Contact Object Mapping
    @track xcfieldOption; // To store the Xero Contact Object fields

    @track invMapping; // To store the Invoice Object Mapping
    @track originalInvMapping; // To store the Invoice Object Mapping
    @track invfieldOption; // To store the Invoice Object fields
    
    @track invLIMapping; // To store the Invoice lineItem Object Mapping
    @track originalInvLIMapping; // To store the Invoice lineItem Object Mapping
    @track invLIfieldOption; // To store the Invoice lineItem Object fields
    
    @track invPayMapping; // To store the Invoice lineItem Object Mapping
    @track originalInvPayMapping; // To store the Invoice lineItem Object Mapping
    @track invPayfieldOption; // To store the Invoice lineItem Object fields
    
    @track billMapping; // To store the Bill Object Mapping
    @track originalBillMapping; // To store the Bill Object Mapping
    @track billfieldOption; // To store the Bill Object fields
    
    @track billLiMapping; // To store the Bill lineItem Object Mapping
    @track originalBillLiMapping; // To store the Bill lineItem Object Mapping
    @track billLifieldOption; // To store the Bill lineItem Object fields
    
    @track billPayMapping; // To store the Bill Payment Object Mapping
    @track originalBillPayMapping; // To store the Bill Payment Object Mapping
    @track billPayfieldOption; // To store the Bill Payment Object fields

    @track showXCBt = false; // To hide and show the save and cancel button
    @track showInvBt = false; // To hide and show the save and cancel button
    @track showInvLIBt = false; // To hide and show the save and cancel button
    @track showPayBt = false; // To hide and show the save and cancel button
    @track showBillBt = false; // To hide and show the save and cancel button
    @track showBillLiBt = false; // To hide and show the save and cancel button
    @track showBillPayBt = false; // To hide and show the save and cancel button

    @track disableInvLI = false; // To disable the input search box for Invoice LineItem Object
    @track disableInvPay = false; // To disable the input search box for Invoice Payment Object
    @track disableBillLI = false; // To disable the input search box for Bill LineItem Object
    @track disableBillPay = false; // To disable the input search box for Bill Payment Object

    connectedCallback(){
        this.getselectedObjects();
        // this.getInvoiceMapping();
        // this.getInvoiceLIMapping();
    }

    getselectedObjects(){
        getSelectedObj({}).then((result) => {
            console.log('getselectedObjects result-->',result);
            if(result){
                this.selectedObjs = JSON.parse(JSON.stringify(result));
                if(this.selectedObjs.invoiceObj){
                    this.invobjectAPI = this.selectedObjs.invoiceObj;
                    this.invObjMappingDisable = false;
                    this.getInvoiceMapping();
                }else{
                    this.disableInvLI = true;
                    this.disableInvPay = true;
                }

                if(this.selectedObjs.invoicelineItemObj){
                    this.invLiObjectAPI = this.selectedObjs.invoicelineItemObj;
                    this.invLIObjMappingDisable = false;
                    this.getInvoiceLIMapping();
                }

                if(this.selectedObjs.invoicePaymentObj){
                    this.invPayObjectAPI = this.selectedObjs.invoicePaymentObj;
                    this.invPayObjMappingDisable = false;
                    this.getInvoicePayMapping();
                }
                
                if(this.selectedObjs.xeroContactObj){
                    this.xeroConobjectAPI = this.selectedObjs.xeroContactObj;
                    this.xeroConObjMappingDisable = false;
                    this.getXeroContactMapping();
                }
                
                if(this.selectedObjs.billObj){
                    this.billObjectAPI = this.selectedObjs.billObj;
                    this.billObjMappingDisable = false;
                    this.getBillMapping();
                }else{
                    this.disableBillLI = true;
                    this.disableBillPay = true;
                }
                
                if(this.selectedObjs.billLiObj){
                    this.billLiObjectAPI = this.selectedObjs.billLiObj;
                    this.billLiObjMappingDisable = false;
                    this.getBillLiMapping();
                }
                
                if(this.selectedObjs.billPaymentObj){
                    this.billPayObjectAPI = this.selectedObjs.billPaymentObj;
                    this.billPayObjMappingDisable = false;
                    this.getBillPayMapping();
                }
            }
        }).catch((error) => {
            console.log('error-->',error);
        });
    }

    async getInvoiceMapping(){
        try {
            const result = await getinvMapping({});
            this.originalInvMapping = JSON.parse(JSON.stringify(result));
            this.originalInvMapping.sort((a,b) => a.sequence - b.sequence);
            
            this.invMapping = JSON.parse(JSON.stringify(result));
            this.invMapping.sort((a,b) => a.sequence - b.sequence);

            this.invfieldOption = await this.getSelectedObjFields(this.invobjectAPI);
            
            let newVar = JSON.parse(JSON.stringify(this.invfieldOption));

            this.invMapping.forEach(element => {
                let fieldArr = newVar[element.dataType];
                let fieldOpt = [];
                fieldArr.forEach(ele => {
                    if(element.dataType !== 'REFERENCE'){
                        fieldOpt.push({label: ele.label , value: ele.name});
                    } else {
                        if(element.referenceObjName === ele.referenceObj){
                            fieldOpt.push({label: ele.label , value: ele.name});
                        }
                    }
                });

                if(fieldOpt.length > 0){
                    element.fieldOption = fieldOpt;
                }else {
                    element.fieldOption = false;
                }
            });
        } catch (error) {
            console.log('Error in getInvoiceMapping:', error);
        }
    }
    
    async getInvoiceLIMapping(){
        try{
            const result = await getinvLIMapping({});
            this.originalInvLIMapping = JSON.parse(JSON.stringify(result));
            this.originalInvLIMapping.sort((a,b) => a.sequence - b.sequence);

            this.invLIMapping = JSON.parse(JSON.stringify(result));
            this.invLIMapping.sort((a,b) => a.sequence - b.sequence);

            this.invLIfieldOption = await this.getSelectedObjFields(this.invLiObjectAPI);
            
            let newVar = JSON.parse(JSON.stringify(this.invLIfieldOption));

            this.invLIMapping.forEach(element => {
                let fieldArr = newVar[element.dataType];
                let fieldOpt = [];
                fieldArr.forEach(ele => {
                    if(element.dataType !== 'REFERENCE'){
                        fieldOpt.push({label: ele.label , value: ele.name});
                    } else {
                        if(element.referenceObjName === ele.referenceObj){
                            fieldOpt.push({label: ele.label , value: ele.name});
                        }
                    }
                });

                if(fieldOpt.length > 0){
                    element.fieldOption = fieldOpt;
                }else {
                    element.fieldOption = false;
                }
            });
        } catch (error) {
            console.log('Error in getInvoiceLIMapping:', error);
        }
    }
    
    async getInvoicePayMapping(){
        try{
            const result = await getinvPayMapping({});
            this.originalInvPayMapping = JSON.parse(JSON.stringify(result));
            this.originalInvPayMapping.sort((a,b) => a.sequence - b.sequence);

            this.invPayMapping = JSON.parse(JSON.stringify(result));
            this.invPayMapping.sort((a,b) => a.sequence - b.sequence);

            this.invPayfieldOption = await this.getSelectedObjFields(this.invPayObjectAPI);
            
            let newVar = JSON.parse(JSON.stringify(this.invPayfieldOption));

            this.invPayMapping.forEach(element => {
                let fieldArr = newVar[element.dataType];
                let fieldOpt = [];
                fieldArr.forEach(ele => {
                    fieldOpt.push({label: ele.label , value: ele.name});
                });
                element.fieldOption = fieldOpt;
            });
        } catch (error) {
            console.log('Error in getInvoicePayMapping:', error);
        }
    }

    async getXeroContactMapping(){
        try{
            const result = await getxcMapping({});

            this.originalXCMapping = JSON.parse(JSON.stringify(result));
            this.originalXCMapping.sort((a,b) => a.sequence - b.sequence);
            
            this.xeroConMapping = JSON.parse(JSON.stringify(result));
            this.xeroConMapping.sort((a,b) => a.sequence - b.sequence);

            this.xcfieldOption = await this.getSelectedObjFields(this.xeroConobjectAPI);
            
            let newVar = JSON.parse(JSON.stringify(this.xcfieldOption));

            this.xeroConMapping.forEach(element => {
                let fieldArr = newVar[element.dataType];
                let fieldOpt = [];
                fieldArr.forEach(ele => {
                    if(element.dataType !== 'REFERENCE'){
                        fieldOpt.push({label: ele.label , value: ele.name});
                    } else {
                        if(element.referenceObjName === ele.referenceObj){
                            fieldOpt.push({label: ele.label , value: ele.name});
                        }
                    }
                });
                
                if(fieldOpt.length > 0){
                    element.fieldOption = fieldOpt;
                }else {
                    element.fieldOption = false;
                }
            });
        } catch (error) {
            console.log('Error in getInvoicePayMapping:', error);
        }
    }
    
    async getBillMapping(){
        try{
            const result = await getbillMapping({});

            this.originalBillMapping = JSON.parse(JSON.stringify(result));
            this.originalBillMapping.sort((a,b) => a.sequence - b.sequence);
            
            this.billMapping = JSON.parse(JSON.stringify(result));
            this.billMapping.sort((a,b) => a.sequence - b.sequence);

            this.billfieldOption = await this.getSelectedObjFields(this.billObjectAPI);
            
            let newVar = JSON.parse(JSON.stringify(this.billfieldOption));

            this.billMapping.forEach(element => {
                let fieldArr = newVar[element.dataType];
                let fieldOpt = [];
                fieldArr.forEach(ele => {
                    if(element.dataType !== 'REFERENCE'){
                        fieldOpt.push({label: ele.label , value: ele.name});
                    } else {
                        if(element.referenceObjName === ele.referenceObj){
                            fieldOpt.push({label: ele.label , value: ele.name});
                        }
                    }
                });
                
                if(fieldOpt.length > 0){
                    element.fieldOption = fieldOpt;
                }else {
                    element.fieldOption = false;
                }
            });
        } catch (error) {
            console.log('Error in getBillMapping:', error);
        }
    }
    
    async getBillLiMapping(){
        try{
            const result = await getbillLiMapping({});

            this.originalBillLiMapping = JSON.parse(JSON.stringify(result));
            this.originalBillLiMapping.sort((a,b) => a.sequence - b.sequence);
            
            this.billLiMapping = JSON.parse(JSON.stringify(result));
            this.billLiMapping.sort((a,b) => a.sequence - b.sequence);

            this.billLifieldOption = await this.getSelectedObjFields(this.billLiObjectAPI);
            
            let newVar = JSON.parse(JSON.stringify(this.billLifieldOption));

            this.billLiMapping.forEach(element => {
                let fieldArr = newVar[element.dataType];
                let fieldOpt = [];
                fieldArr.forEach(ele => {
                    if(element.dataType !== 'REFERENCE'){
                        fieldOpt.push({label: ele.label , value: ele.name});
                    } else {
                        if(element.referenceObjName === ele.referenceObj){
                            fieldOpt.push({label: ele.label , value: ele.name});
                        }
                    }
                });
                
                if(fieldOpt.length > 0){
                    element.fieldOption = fieldOpt;
                }else {
                    element.fieldOption = false;
                }
            });
        } catch (error) {
            console.log('Error in getbillLiMapping:', error);
        }
    }

    async getBillPayMapping(){
        try{
            const result = await getbillPayMapping({});

            this.originalBillPayMapping = JSON.parse(JSON.stringify(result));
            this.originalBillPayMapping.sort((a,b) => a.sequence - b.sequence);
            
            this.billPayMapping = JSON.parse(JSON.stringify(result));
            this.billPayMapping.sort((a,b) => a.sequence - b.sequence);

            this.billPayfieldOption = await this.getSelectedObjFields(this.billPayObjectAPI);
            
            let newVar = JSON.parse(JSON.stringify(this.billPayfieldOption));

            this.billPayMapping.forEach(element => {
                let fieldArr = newVar[element.dataType];
                let fieldOpt = [];
                fieldArr.forEach(ele => {
                    if(element.dataType !== 'REFERENCE'){
                        fieldOpt.push({label: ele.label , value: ele.name});
                    } else {
                        if(element.referenceObjName === ele.referenceObj){
                            fieldOpt.push({label: ele.label , value: ele.name});
                        }
                    }
                });
                
                if(fieldOpt.length > 0){
                    element.fieldOption = fieldOpt;
                }else {
                    element.fieldOption = false;
                }
            });
        } catch (error) {
            console.log('Error in getBillPayMapping:', error);
        }
    }
    
    handleFieldMapping(event){
        const mappingName = event.target.name;
        console.log('handleFieldMapping mappingName-->',mappingName);

        if(mappingName === 'InvoiceObj'){
            if(!this.showINVFieldMapping){
                this.showINVFieldMapping = true;
                this.invMappingIcon = 'utility:down';
            }else if (this.showINVFieldMapping){
                this.showINVFieldMapping = false;
                this.invMappingIcon = 'utility:right';
            }
        } else if (mappingName === 'InvoiceLIObj') {
            if(!this.showINVLIFieldMapping){
                this.showINVLIFieldMapping = true;
                this.invLIMappingIcon = 'utility:down';
            }else if (this.showINVLIFieldMapping){
                this.showINVLIFieldMapping = false;
                this.invLIMappingIcon = 'utility:right';
            }
        } else if (mappingName === 'InvoicePayObj') {
            if(!this.showINVPayFieldMapping){
                this.showINVPayFieldMapping = true;
                this.invPayMappingIcon = 'utility:down';
            }else if (this.showINVPayFieldMapping){
                this.showINVPayFieldMapping = false;
                this.invPayMappingIcon = 'utility:right';
            }
        } else if (mappingName === 'XeroConObj') {
            if(!this.showXeroConFieldMapping){
                this.showXeroConFieldMapping = true;
                this.xeroConMappingIcon = 'utility:down';
            }else if (this.showXeroConFieldMapping){
                this.showXeroConFieldMapping = false;
                this.xeroConMappingIcon = 'utility:right';
            }
        } else if (mappingName === 'BillObj') {
            if(!this.showBillFieldMapping){
                this.showBillFieldMapping = true;
                this.BillMappingIcon = 'utility:down';
            }else if (this.showBillFieldMapping){
                this.showBillFieldMapping = false;
                this.BillMappingIcon = 'utility:right';
            }
        } else if (mappingName === 'BillLiObj') {
            if(!this.showBillLiFieldMapping){
                this.showBillLiFieldMapping = true;
                this.BillLiMappingIcon = 'utility:down';
            }else if (this.showBillLiFieldMapping){
                this.showBillLiFieldMapping = false;
                this.BillLiMappingIcon = 'utility:right';
            }
        } else if (mappingName === 'BillPayObj') {
            if(!this.showBillPayFieldMapping){
                this.showBillPayFieldMapping = true;
                this.BillPayMappingIcon = 'utility:down';
            }else if (this.showBillPayFieldMapping){
                this.showBillPayFieldMapping = false;
                this.BillPayMappingIcon = 'utility:right';
            }
        }
    }

    getObjects () {

        getObjectList({

        }).then((result) => {

            if (result) {

                console.log('result-->',result);
                console.log('result-->',JSON.stringify(result));
                this.invOptions = JSON.parse(JSON.stringify(result));

            }

        }).catch((error) => {

                this.showToastPopMessage(
                    `Something went wrong. Error - ${error}`,
                    "error"
                );

        });

    }

    handleObjectSelected(event){
        console.log('handleObjectSelected -->',event.detail);
        this.invobjectAPI = event.detail;
        this.invObjMappingDisable = false;
        this.getChildObjects();
        this.getSelectedObjFields(this.invobjectAPI);
    }
    
    getSelectedObjFields(selectedObj){
        return new Promise((resolve, reject) => {
            getObjectFields({
                objectApiName: selectedObj
            })
            .then((result) => {
                console.log('fields of ' + selectedObj + '--> ' + JSON.stringify(result));
                resolve(result); // Resolve the promise with the result
            })
            .catch((error) => {
                console.log('Error in getSelectedObjFields:', error);
                reject(error); // Reject the promise if there's an error
            });
        });
    }

    getChildObjects(){
        getChildObjects({
            objectApiName: this.invobjectAPI
        })
        .then((result) => {
            console.log('fields of +selectedObj+ '+result);
        }).catch((error) => {
            console.log(error);
        })
    }

    handleInvFieldChange(event){

        let name = event.target.name;
        let id = event.target.dataset.id;
        let val = event.detail.value;

        if(name === 'Invoice field'){
            let record = this.invMapping.find((element) => element.id === id);
            record.fieldApiName = val;
            console.log('invMapping-->',JSON.stringify(this.invMapping));
            this.showInvBt = true;
        } else if (name === 'Invoice LI field') {
            let record = this.invLIMapping.find((element) => element.id === id);
            record.fieldApiName = val;
            console.log('invLIMapping-->',JSON.stringify(this.invLIMapping));
            this.showInvLIBt = true;
        } else if (name === 'Invoice Pay field') {
            let record = this.invPayMapping.find((element) => element.id === id);
            record.fieldApiName = val;
            console.log('invPayMapping-->',JSON.stringify(this.invPayMapping));
            this.showPayBt = true;
        } else if (name === 'Xero Contact field') {
            let record = this.xeroConMapping.find((element) => element.id === id);
            record.fieldApiName = val;
            console.log('xeroConMapping-->',JSON.stringify(this.xeroConMapping));
            this.showXCBt = true;
        } else if (name === 'Bill field') {
            let record = this.billMapping.find((element) => element.id === id);
            record.fieldApiName = val;
            console.log('billMapping-->',JSON.stringify(this.billMapping));
            this.showBillBt = true;
        } else if (name === 'Bill LineItem field') {
            let record = this.billLiMapping.find((element) => element.id === id);
            record.fieldApiName = val;
            console.log('billMapping-->',JSON.stringify(this.billLiMapping));
            this.showBillLiBt = true;
        } else if (name === 'Bill Payment field') {
            let record = this.billPayMapping.find((element) => element.id === id);
            record.fieldApiName = val;
            console.log('billPayMapping-->',JSON.stringify(this.billPayMapping));
            this.showBillPayBt = true;
        }


    }

    handleClick(event){

        let name = event.target.name;

        if(name === 'invSave'){
            this.showLoading = true;
            saveinvMapping({
                invString: JSON.stringify(this.invMapping)
            }).
            then((result) => {
                console.log('saveinvMapping result-->',result);
                if(result){
                    this.showToast("Invoice Mapping Updated Succesfully", "", "success","dismissable");
                    this.showLoading = false;
                    this.showInvBt = false;
                }else{
                    this.showToast("Something Went Wrong", "", "error","dismissable");
                    this.showLoading = false;
                }
            }).catch((error) => {
                console.log(error);
                this.showToast("Something Went Wrong", "", "error","dismissable");
                this.showLoading = false;
            })
        } else if (name === 'invCancel') {
            this.invMapping = this.originalInvMapping;
            this.showInvBt = false;
        } else if (name === 'invLISave') {
            this.showLoading = true;
            saveinvLIMapping({
                invString: JSON.stringify(this.invLIMapping)
            }).
            then((result) => {
                console.log('saveinvMapping result-->',result);
                if(result){
                    this.showToast("Invoice LineItem Mapping Updated Succesfully", "", "success","dismissable");
                    this.showLoading = false;
                    this.showInvLIBt = false;
                }else{
                    this.showToast("Something Went Wrong", "", "error","dismissable");
                    this.showLoading = false;
                }
            }).catch((error) => {
                console.log(error);
                this.showToast("Something Went Wrong", "", "error","dismissable");
                this.showLoading = false;
            })
        } else if (name === 'invLICancel') {
            this.invLIMapping = this.originalInvLIMapping;
            this.showInvLIBt = false;
        } else if (name === 'invPaySave') {
            this.showLoading = true;
            saveinvPayMapping({
                invString: JSON.stringify(this.invPayMapping)
            }).
            then((result) => {
                console.log('saveinvMapping result-->',result);
                if(result){
                    this.showToast("Invoice LineItem Mapping Updated Succesfully", "", "success","dismissable");
                    this.showLoading = false;
                    this.showInvLIBt = false;
                }else{
                    this.showToast("Something Went Wrong", "", "error","dismissable");
                    this.showLoading = false;
                }
            }).catch((error) => {
                console.log(error);
                this.showToast("Something Went Wrong", "", "error","dismissable");
                this.showLoading = false;
            })
        } else if (name === 'invPayCancel') {
            this.invPayMapping = this.originalInvPayMapping;
            this.showPayBt = false;
        } else if (name === 'xcSave') {
            this.showLoading = true;
            savexcMapping({
                invString: JSON.stringify(this.xeroConMapping),
                mappedObj: this.xeroConobjectAPI
            }).
            then((result) => {
                console.log('saveinvMapping result-->',result);
                if(result){
                    this.showToast("Xero Contact Mapping Updated Succesfully", "", "success","dismissable");
                    this.showLoading = false;
                    this.showPayBt = false;
                }else{
                    this.showToast("Something Went Wrong", "", "error","dismissable");
                    this.showLoading = false;
                }
            }).catch((error) => {
                console.log(error);
                this.showToast("Something Went Wrong", "", "error","dismissable");
                this.showLoading = false;
            })
        } else if (name === 'xcCancel') {
            this.xeroConMapping = this.originalXCMapping;
            this.showXCBt = false;
        } else if (name === 'billSave') {
            this.showLoading = true;
            savebillMapping({
                invString: JSON.stringify(this.billMapping)
            }).
            then((result) => {
                console.log('savebillMapping result-->',result);
                if(result){
                    this.showToast("Bill Mapping Updated Succesfully", "", "success","dismissable");
                    this.showLoading = false;
                    this.showBillBt = false;
                }else{
                    this.showToast("Something Went Wrong", "", "error","dismissable");
                    this.showLoading = false;
                }
            }).catch((error) => {
                console.log(error);
                this.showToast("Something Went Wrong", "", "error","dismissable");
                this.showLoading = false;
            })
        } else if (name === 'billCancel') {
            this.billMapping = this.originalBillMapping;
            this.showBillBt = false;
        } else if (name === 'billLiSave') {
            this.showLoading = true;
            savebillLiMapping({
                invString: JSON.stringify(this.billLiMapping)
            }).
            then((result) => {
                console.log('savebillMapping result-->',result);
                if(result){
                    this.showToast("Bill LineItem Mapping Updated Succesfully", "", "success","dismissable");
                    this.showLoading = false;
                    this.showBillLiBt = false;
                }else{
                    this.showToast("Something Went Wrong", "", "error","dismissable");
                    this.showLoading = false;
                }
            }).catch((error) => {
                console.log(error);
                this.showToast("Something Went Wrong", "", "error","dismissable");
                this.showLoading = false;
            })
        } else if (name === 'billLiCancel') {
            this.billLiMapping = this.originalBillLiMapping;
            this.showBillLiBt = false;
        } else if (name === 'billPaySave') {
            this.showLoading = true;
            savebillPayMapping({
                invString: JSON.stringify(this.billPayMapping)
            }).
            then((result) => {
                console.log('savebillMapping result-->',result);
                if(result){
                    this.showToast("Bill Payment Mapping Updated Succesfully", "", "success","dismissable");
                    this.showLoading = false;
                    this.showBillPayBt = false;
                }else{
                    this.showToast("Something Went Wrong", "", "error","dismissable");
                    this.showLoading = false;
                }
            }).catch((error) => {
                console.log(error);
                this.showToast("Something Went Wrong", "", "error","dismissable");
                this.showLoading = false;
            })
        } else if (name === 'billPayCancel') {
            this.billPayMapping = this.originalBillPayMapping;
            this.showBillPayBt = false;
        }

    }

    async handleXCObjSelected(event){
        console.log('handleXCObjSelected -->',event.detail);
        this.xeroConObjMappingDisable = false;
        if(this.xeroConobjectAPI === event.detail){
            
        } else {
            this.xeroConobjectAPI = event.detail;

            this.xcfieldOption = await this.getSelectedObjFields(this.xeroConobjectAPI);
            
            let newVar = JSON.parse(JSON.stringify(this.xcfieldOption));

            this.xeroConMapping.forEach(element => {
                
                // blank the value of fieldApiName
                element.fieldApiName === '';

                let fieldArr = newVar[element.dataType];
                let fieldOpt = [];
                fieldArr.forEach(ele => {
                    if(element.dataType !== 'REFERENCE'){
                        fieldOpt.push({label: ele.label , value: ele.name});
                    } else {
                        if(element.referenceObjName === ele.referenceObj){
                            fieldOpt.push({label: ele.label , value: ele.name});
                        }
                    }
                });
                
                if(fieldOpt.length > 0){
                    element.fieldOption = fieldOpt;
                }else {
                    element.fieldOption = false;
                }
            });
        }
        // this.getChildObjects();
    }

    clearXCObj(event){
        this.xeroConObjMappingDisable = true;
        this.xeroConMappingIcon = 'utility:right';
        this.showXeroConFieldMapping = false;
    }

    async handleInvObjectSelected(event){
        debugger;
        console.log('handleInvObjectSelected -->',event.detail);

        this.invObjMappingDisable = false;

        if(this.invobjectAPI !== event.detail){
            this.invobjectAPI = event.detail;

            this.invfieldOption = await this.getSelectedObjFields(this.invobjectAPI);
            
            let newVar = JSON.parse(JSON.stringify(this.invfieldOption));

            this.invMapping.forEach(element => {
                
                // blank the value of fieldApiName
                element.fieldApiName === '';

                let fieldArr = newVar[element.dataType];
                let fieldOpt = [];
                fieldArr.forEach(ele => {
                    if(element.dataType !== 'REFERENCE'){
                        fieldOpt.push({label: ele.label , value: ele.name});
                    } else {
                        if(element.referenceObjName === ele.referenceObj){
                            fieldOpt.push({label: ele.label , value: ele.name});
                        }
                    }
                });
                
                if(fieldOpt.length > 0){
                    element.fieldOption = fieldOpt;
                }else {
                    element.fieldOption = false;
                }
            });
        }
        // this.invobjectAPI = event.detail;
        // this.getChildObjects();
        // this.getSelectedObjFields(this.invobjectAPI);
    }
    
    clearInvObj(event){
        this.invObjMappingDisable = true;
        this.invMappingIcon = 'utility:right';
        this.showINVFieldMapping = false;
    }

    async handleInvLIObjectSelected(event){
        console.log('handleInvLIObjectSelected -->',event.detail);
        this.invLIObjMappingDisable = false;

        if(this.invLiObjectAPI !== event.detail){
            this.invLiObjectAPI = event.detail;

            this.invLIfieldOption = await this.getSelectedObjFields(this.invLiObjectAPI);
            
            let newVar = JSON.parse(JSON.stringify(this.invLIfieldOption));

            this.invLIMapping.forEach(element => {
                
                // blank the value of fieldApiName
                element.fieldApiName === '';

                let fieldArr = newVar[element.dataType];
                let fieldOpt = [];
                fieldArr.forEach(ele => {
                    if(element.dataType !== 'REFERENCE'){
                        fieldOpt.push({label: ele.label , value: ele.name});
                    } else {
                        if(element.referenceObjName === ele.referenceObj){
                            fieldOpt.push({label: ele.label , value: ele.name});
                        }
                    }
                });
                
                if(fieldOpt.length > 0){
                    element.fieldOption = fieldOpt;
                }else {
                    element.fieldOption = false;
                }
            });
        }

        // this.invobjectAPI = event.detail;
        // this.getChildObjects();
        // this.getSelectedObjFields(this.invobjectAPI);
    }
    
    clearInvLIObj(event){
        this.invLIObjMappingDisable = true;
        this.invLIMappingIcon = 'utility:right';
        this.showINVLIFieldMapping = false;
    }

    async handleInvPayObjectSelected(event){
        console.log('handleInvPayObjectSelected -->',event.detail);
        this.invPayObjMappingDisable = false;

        if(this.invPayObjectAPI !== event.detail){
            this.invPayObjectAPI = event.detail;

            this.invPayfieldOption = await this.getSelectedObjFields(this.invPayObjectAPI);
            
            let newVar = JSON.parse(JSON.stringify(this.invPayfieldOption));

            this.invPayMapping.forEach(element => {
                
                // blank the value of fieldApiName
                element.fieldApiName === '';

                let fieldArr = newVar[element.dataType];
                let fieldOpt = [];
                fieldArr.forEach(ele => {
                    if(element.dataType !== 'REFERENCE'){
                        fieldOpt.push({label: ele.label , value: ele.name});
                    } else {
                        if(element.referenceObjName === ele.referenceObj){
                            fieldOpt.push({label: ele.label , value: ele.name});
                        }
                    }
                });
                
                if(fieldOpt.length > 0){
                    element.fieldOption = fieldOpt;
                }else {
                    element.fieldOption = false;
                }
            });
        }
        // this.invobjectAPI = event.detail;
        // this.getChildObjects();
        // this.getSelectedObjFields(this.invobjectAPI);
    }
    
    clearInvPayObj(event){
        this.invPayObjMappingDisable = true;
        this.invPayMappingIcon = 'utility:right';
        this.showINVPayFieldMapping = false;
    }

    async handleBillObjectSelected(event){
        console.log('handleBillObjectSelected -->',event.detail);
        this.billObjMappingDisable = false;

        if(this.billObjectAPI !== event.detail){
            this.billObjectAPI = event.detail;

            this.billfieldOption = await this.getSelectedObjFields(this.billObjectAPI);
            
            let newVar = JSON.parse(JSON.stringify(this.billfieldOption));

            this.billMapping.forEach(element => {
                
                // blank the value of fieldApiName
                element.fieldApiName === '';

                let fieldArr = newVar[element.dataType];
                let fieldOpt = [];
                fieldArr.forEach(ele => {
                    if(element.dataType !== 'REFERENCE'){
                        fieldOpt.push({label: ele.label , value: ele.name});
                    } else {
                        if(element.referenceObjName === ele.referenceObj){
                            fieldOpt.push({label: ele.label , value: ele.name});
                        }
                    }
                });
                
                if(fieldOpt.length > 0){
                    element.fieldOption = fieldOpt;
                }else {
                    element.fieldOption = false;
                }
            });
        }
    }

    clearBillObj(event){
        this.billObjMappingDisable = true;
        this.BillMappingIcon = 'utility:right';
        this.showBillFieldMapping = false;
    }

    async handleBillLiObjectSelected(event){
        console.log('handleBillLiObjectSelected -->',event.detail);
        this.billLiObjMappingDisable = false;

        if(this.billLiObjectAPI !== event.detail){
            this.billLiObjectAPI = event.detail;

            this.billLifieldOption = await this.getSelectedObjFields(this.billLiObjectAPI);
            
            let newVar = JSON.parse(JSON.stringify(this.billLifieldOption));

            this.billLiMapping.forEach(element => {
                
                // blank the value of fieldApiName
                element.fieldApiName === '';

                let fieldArr = newVar[element.dataType];
                let fieldOpt = [];
                fieldArr.forEach(ele => {
                    if(element.dataType !== 'REFERENCE'){
                        fieldOpt.push({label: ele.label , value: ele.name});
                    } else {
                        if(element.referenceObjName === ele.referenceObj){
                            fieldOpt.push({label: ele.label , value: ele.name});
                        }
                    }
                });
                
                if(fieldOpt.length > 0){
                    element.fieldOption = fieldOpt;
                }else {
                    element.fieldOption = false;
                }
            });
        }
    }
    
    clearBillLiObj(event){
        this.billLiObjMappingDisable = true;
        this.BillPayMappingIcon = 'utility:right';
        this.showBillLiFieldMapping = false;
    }

    async handleBillPayObjectSelected(event){
        console.log('handleBillPayObjectSelected -->',event.detail);
        this.billPayObjMappingDisable = false;

        if(this.billPayObjectAPI !== event.detail){
            this.billPayObjectAPI = event.detail;

            this.billPayfieldOption = await this.getSelectedObjFields(this.billPayObjectAPI);
            
            let newVar = JSON.parse(JSON.stringify(this.billPayfieldOption));

            this.billPayMapping.forEach(element => {
                
                // blank the value of fieldApiName
                element.fieldApiName === '';

                let fieldArr = newVar[element.dataType];
                let fieldOpt = [];
                fieldArr.forEach(ele => {
                    if(element.dataType !== 'REFERENCE'){
                        fieldOpt.push({label: ele.label , value: ele.name});
                    } else {
                        if(element.referenceObjName === ele.referenceObj){
                            fieldOpt.push({label: ele.label , value: ele.name});
                        }
                    }
                });
                
                if(fieldOpt.length > 0){
                    element.fieldOption = fieldOpt;
                }else {
                    element.fieldOption = false;
                }
            });
        }
    }
    
    clearBillPayObj(event){
        this.billPayObjMappingDisable = true;
        this.BillMappingIcon = 'utility:right';
        this.showBillPayFieldMapping = false;
    }

    handleRefresh(event){
        
        let name = event.target.name;
        console.log('handleRefresh -->',name);

        if(name === 'XC') {
            this.getXeroContactMapping();
        } else if (name === 'Invoice Obj') {
            this.getInvoiceMapping();
        } else if (name === 'Invoice LineItem Obj') {
            this.getInvoiceLIMapping();
        } else if (name === 'Invoice Payment Obj') {
            this.getInvoicePayMapping();
        } else if (name === 'Bill Obj') {
            this.getBillMapping();
        } else if (name === 'Bill line Item Obj') {
            this.getBillLiMapping();
        } else if (name === 'Bill Payment Obj'){
            this.getBillPayMapping();
        }
    }

    showToast (title, message, variant, mode) {

        const evt = new ShowToastEvent({
            title,
            message,
            variant,
            mode
        });
        this.dispatchEvent(evt);
    }
}