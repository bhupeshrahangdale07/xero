import { LightningElement, track, wire } from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getsObjectFieldMap from "@salesforce/apex/InvoiceConfigurationController.getFieldMap";
import startSync from "@salesforce/apex/XeroBulkSyncController.startSync";
import checkBatchRunning from "@salesforce/apex/XeroBulkSyncController.checkBatchRunning";
import invoiceLoadingAnm from "@salesforce/resourceUrl/Invoice_loading_Animation";
import insertLog from "@salesforce/apex/Utils.insertLog";
export default class XeroBulkSyncCmp extends LightningElement {

    invoiceLoading = invoiceLoadingAnm;
    @track showfilters = false;
    @track showLoading = true;
    @track operatorVal = "equals";
    @track statusDisable = true;
    @track dateDisable = true;
    // @track fltLogicVal;
    @track startDate;
    @track endDate;

    @track linkProd;
    @track linkXC;
    @track showFirstOpt = false;
    @track showlinkXCOpt = false;
    @track createXC;
    @track showAccOpt = false;
    @track attchAcc;
    @track accMappingOpt = false;
    @track createAcc;

    @track acctextFieldOptions;
    @track emailFieldOptions;
    @track companyName;
    @track accNumber;
    @track personEmail;
    @track objValue = "Account";

    @track disableCompanyName = true;
    @track disableAccountNumber = true;
    @track disablePersonEmail = true;

    @track showSyncSetting = false;
    @track isInProgress;
    get options() {
        return [
            { label: 'Equals', value: 'equals' },
            { label: 'Not equal to', value: 'notEquals' },
        ];
    }

    @track statusValue;
    @track StatusOpts= [
        { label: 'DRAFT', value: 'DRAFT' },
        { label: 'SUBMITTED', value: 'SUBMITTED' },
        { label: 'DELETED', value: 'DELETED' },
        { label: 'AUTHORISED', value: 'AUTHORISED' },
        { label: 'PAID', value: 'PAID' },
        { label: 'VOIDED', value: 'VOIDED' },
    ];
    @track allValues=[];
    @track optionsMaster=[
        { label: 'DRAFT', value: 'DRAFT' },
        { label: 'SUBMITTED', value: 'SUBMITTED' },
        { label: 'DELETED', value: 'DELETED' },
        { label: 'AUTHORISED', value: 'AUTHORISED' },
        { label: 'PAID', value: 'PAID' },
        { label: 'VOIDED', value: 'VOIDED' },
    ];

    // @track filterlogicOption = [
    //     { label: 'AND', value: 'AND' },
    //     { label: 'OR', value: 'OR' },
    // ];

    @track linkXCOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' },
    ];

    @track linkProdOptions = [
        { label: 'link product only', value: 'linkOnly' },
        { label: 'link and create product', value: 'linkandCreate' },
        { label: 'Do not link or create', value: 'No' },
    ];

    @track objOption = [
        { label: 'Account', value: 'Account' },
        { label: 'Contact', value: 'Contact' }
    ];

    // handleConditionChange(event){
    //     this.fltLogicVal = event.target.value;
    // }

    @track showHelpTextFlag = false;
    @track showHelpTextFlag1 = false;

    connectedCallback () {
        this.handleRefresh();
    }

    handleRefresh(){
        this.showLoading = true;
        checkBatchRunning({
            batchName: 'XeroBulkSyncBatch'
        })
        .then((result) =>{
            if(result){
                if(result == 'true'){
                    this.isInProgress = true;
                    this.showLoading = false;
                }else{
                    this.isInProgress = false;    
                    this.showLoading = false;
                    this.showfilters = false;
                    this.statusDisable = true;
                    this.dateDisable = true;
                    this.startDate = '';
                    this.endDate = '';
                    this.showFirstOpt = false;
                    this.showlinkXCOpt = false;
                    this.showAccOpt = false;
                    this.accMappingOpt = false;
                    this.disableCompanyName = true;
                    this.disableAccountNumber = true;
                    this.disablePersonEmail = true;
                    this.showSyncSetting = false;
                    this.objValue = "Account";
                    this.statusValue = '';
                    this.allValues = [];
                    this.linkProd = '';
                    this.linkXC = '';
                    this.createXC = '';
                    this.attchAcc = '';
                    this.createAcc = '';
                    this.companyName = '';
                    this.accNumber = '';
                    this.personEmail = '';
                    this.StatusOpts= [
                        { label: 'DRAFT', value: 'DRAFT' },
                        { label: 'SUBMITTED', value: 'SUBMITTED' },
                        { label: 'DELETED', value: 'DELETED' },
                        { label: 'AUTHORISED', value: 'AUTHORISED' },
                        { label: 'PAID', value: 'PAID' },
                        { label: 'VOIDED', value: 'VOIDED' },
                    ];
                    this.optionsMaster=[
                        { label: 'DRAFT', value: 'DRAFT' },
                        { label: 'SUBMITTED', value: 'SUBMITTED' },
                        { label: 'DELETED', value: 'DELETED' },
                        { label: 'AUTHORISED', value: 'AUTHORISED' },
                        { label: 'PAID', value: 'PAID' },
                        { label: 'VOIDED', value: 'VOIDED' },
                    ];
                }
            }   
        })
        .catch((error)=>{
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
                            //this.errorFlag = true;
                        });
                    }else{
                        errorMsg = "Error: "+JSON.stringify(error.body.message);
                    }

                } else{
                    errorMsg = "Error: "+JSON.stringify(error);
                }

                
                this.showToast(errorMsg,"","error","dismissable");
                this.showLoading = false;

            }
        })
    }
    
    handleChange(event){
        this.statusValue = event.target.value;
        if(!this.allValues.includes(this.statusValue))
        this.allValues.push(this.statusValue);
        this.modifyOptions();
    }

    opthandleChange(event){
        this.operatorVal = event.target.value;
    }

    handleRemove(event){
        this.statusValue='';
        const valueRemoved=event.target.name;
        this.allValues.splice(this.allValues.indexOf(valueRemoved),1);
        this.modifyOptions();
    }

    modifyOptions(){
        this.StatusOpts=this.optionsMaster.filter(elem=>{
        if(!this.allValues.includes(elem.value))
            return elem;
        })
    }

    onhandleChange(event){
        const selectedOption = event.target.value;
        if (selectedOption === "all") {
            
            this.showfilters = false;

        } else if (selectedOption === "filters") {
            
            this.showfilters = true;

        }
        this.showSyncSetting = true;

    }

    handleCheckBoxChange(event){
        
        if(event.target.name === "status"){

            if (event.target.checked) {
                this.statusDisable = false;
            } else {
                this.statusDisable = true;
            }

        } else if (event.target.name === "Invoice Date") {

            if (event.target.checked) {
                this.dateDisable = false;
            } else {
                this.dateDisable = true;
            }

        } else if (event.target.name === "CompanyName") {

            if (event.target.checked) {
                this.disableCompanyName = false;
            } else {
                this.disableCompanyName = true;
            }

        } else if (event.target.name === "AccountNumber") {

            if (event.target.checked) {
                this.disableAccountNumber = false;
            } else {
                this.disableAccountNumber = true;
            }

        } else if (event.target.name === "PersonEmail") {

            if (event.target.checked) {
                this.disablePersonEmail = false;
            } else {
                this.disablePersonEmail = true;
            }

        }
    }

    handleDateChange(event){
        if(event.target.name === "Start Date"){
            this.startDate = event.target.value;
        } else if (event.target.name === "End Date") {
            this.endDate = event.target.value;
        }
    }

    syncClick(event){

        let flag = true;
        
        if (this.showfilters) {
            
            if (this.statusDisable && this.dateDisable) {

                this.showToast("Please select atleast one filter","","error","dismissable");
                flag = false;

            } else {

                if (!this.statusDisable) {
                    
                    if(this.allValues.length < 1){
                        flag = false;
                        this.showToast("Please select status value for filter","","error","dismissable");
                    }

                }

                if (!this.dateDisable && flag) {
                    
                    if(!this.startDate){
                        this.showToast("Please select valid Date","","error","dismissable");
                        flag = false;
                    } else if(this.endDate && this.startDate){
                        let start = new Date(this.startDate);
                        let end = new Date(this.endDate);

                        if(end < start){
                            this.showToast("End date should be greater than start date","","error","dismissable");
                            flag = false;
                        }
                    }
                }

                // if(!this.statusDisable && !this.dateDisable && flag){
                //     if(!this.fltLogicVal){
                //         this.showToast("Please apply filter logic between filters","","error","dismissable");
                //         flag = false;
                //     }
                // }
            }
        }

        if(!this.linkProd && flag){
            this.showToast("Please select value for create/link product while syncing Invoice in Salesforce","","error","dismissable");
            flag = false;
        }

        if(!this.linkXC && flag){
            this.showToast("Please select value for link Xero Contact while syncing Invoice in Salesforce","","error","dismissable");
            flag = false;
        }else if(this.linkXC === "Yes" && flag){
            if(!this.createXC){
                this.showToast("Please select value for Create a new Xero Contact","","error","dismissable");
                flag = false;
            }else if(this.createXC === "Yes"){
                if(!this.attchAcc){
                    this.showToast("Please select value for map Salesforce Account","","error","dismissable");
                    flag = false;
                }else if(this.attchAcc === "Yes"){

                    if(this.disableCompanyName && this.disableAccountNumber && this.disablePersonEmail){
                        this.showToast("Please provide atleaset one mapping","","error","dismissable");
                        flag = false;
                        return;
                    }

                    if(flag && !this.disableCompanyName && !this.companyName){
                        this.showToast("Please select value for Mapping Xero Contact Company Name","","error","dismissable");
                        flag = false;
                        return;
                    }
                    
                    if(flag && !this.disableAccountNumber && !this.accNumber){
                        this.showToast("Please select value for Mapping Xero Contact Company Name","","error","dismissable");
                        flag = false;
                        return;
                    }

                    if(flag && !this.disablePersonEmail && !this.personEmail){
                        this.showToast("Please select value for Mapping Xero Contact Primary Person Email","","error","dismissable");
                        flag = false;
                        return;
                    }

                    if(flag && !this.createAcc){
                        this.showToast("Please select value for Salesforce Account Creation","","error","dismissable");
                        flag = false;
                        return;
                    }

                }
            }
        }

        if(flag) {
            
            this.showLoading = true;
            
            let stdate = new Date(this.startDate);
            let enDate = new Date(this.endDate);
            var newObj = {
                "filterSync": this.showfilters,
                "invoiceStatus": this.allValues,
                "invStatusOperator": this.operatorVal,
                "startDate": (stdate.getMonth()+1)+'/'+stdate.getDate()+'/'+stdate.getFullYear(),
                "endDate": (enDate.getMonth()+1)+'/'+enDate.getDate()+'/'+enDate.getFullYear(),
                // "fltLogicVal": this.fltLogicVal,
                "linkXC": this.linkXC,
                "createCX": this.createXC,
                "mapSfAcc": this.attchAcc,
                "xcCompanyNameMap": this.companyName,
                "xcAccNumberMap": this.accNumber,
                "xcEmailMapRelatedTo": this.objValue,
                "xcEmailMap": this.personEmail,
                "linkProd":this.linkProd,
                "createAcc": this.createAcc
            };

            startSync({
                "syncSetting": JSON.stringify(newObj) 
            }).then((result) => {
                
                this.showLoading = false;
                this.isInProgress = true;
            }).catch((error) => {
                
                this.showLoading = false;
            })
        }
    }

    linkXCChange(event){
        
        if(event.target.name === 'linkXC'){

            this.linkXC = event.target.value;
            

            if(event.target.value === 'Yes'){
                this.showlinkXCOpt = true;
            } else if (event.target.value === 'No'){
                this.showlinkXCOpt = false;
                this.createXC = '';
                this.showAccOpt = false;
                this.attchAcc = '';
                this.accMappingOpt = false;
            }

        } else if (event.target.name === 'createXC') {
            
            this.createXC = event.target.value;
            
            
            if(event.target.value === 'Yes'){
                this.showAccOpt = true;
            } else if (event.target.value === 'No'){
                this.showAccOpt = false;
                this.attchAcc = '';
                this.accMappingOpt = false;
            }

        } else if (event.target.name === 'attchAcc') {

            this.attchAcc = event.target.value;
            
            if(event.target.value === 'Yes'){
                this.accMappingOpt = true;
                this.getAccObjFieldData();
            } else if (event.target.value === 'No'){
                this.accMappingOpt = false;
            }
        } else if (event.target.name === 'linkProd') {

            this.showFirstOpt = true;
            this.linkProd = event.target.value;
        } else if (event.target.name === 'createAcc') {
            this.createAcc = event.target.value;
        }

    }

    getAccObjFieldData () {

        this.showLoading = true;
        getsObjectFieldMap({
            "sObjectType": "Account"
        }).
        then((result) => {

            let textFieldArr = [];
            let emailFieldArr = [];
            
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
                
                
                this.acctextFieldOptions = textFieldArr;
                this.emailFieldOptions = emailFieldArr;
            }
            
            this.showLoading = false;
            
        }).
        catch((error) => {

            this.error = error;
            this.showLoading = false;

        });
    }

    handlemapfieldChange(event){

        if(event.target.name === 'Company Name'){
            this.companyName = event.target.value;
        } else if (event.target.name === 'Account Number') {
            this.accNumber = event.target.value;
        } else if (event.target.name === 'Person Email'){
            this.personEmail = event.target.value;
        }

    }

    handleObjOptionChange(event){
        this.personEmail = '';
        this.objValue = event.target.value;
        // this.showLoading = true;
        getsObjectFieldMap({
            "sObjectType": this.objValue
        }).
        then((result) => {
            let emailFieldArr = [];
            if (result) {

                result.forEach((element) => {
                    
                    if (element.fieldType === "EMAIL") {

                        emailFieldArr.push({"label": element.label,
                        "value": element.value});

                    }
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

                this.emailFieldOptions = emailFieldArr;
            }
            // this.showLoading = false;
        }).catch((error => {
            this.error = error;
            // this.showLoading = false;
        }))
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