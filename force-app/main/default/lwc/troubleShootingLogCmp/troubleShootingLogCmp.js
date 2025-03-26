import {LightningElement, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

import deleteLogs from "@salesforce/apex/TroubleshootingController.deleteAllLogs";
import getLogConfig from "@salesforce/apex/TroubleshootingController.getSetupConfiguration";
import getLogData from "@salesforce/apex/TroubleshootingController.getLogData";
import getScheduleData from "@salesforce/apex/TroubleshootingController.getScheduleData";
import updateLogConfig from "@salesforce/apex/TroubleshootingController.updateLogConfig";
import insertLog from "@salesforce/apex/Utils.insertLog";

// Datatable columns with row actions. Set sortable = true
const columns = [
    {"fieldName": "nameUrl",
        "label": "Log Id",
        "sortable": true,
        "type": "url",
        "typeAttributes": {"label": {"fieldName": "name"},
            "target": "_blank"}},
    {"fieldName": "requestMethod",
        "label": "Type",
        "sortable": "true"},
    {"fieldName": "requestEndpoint",
        "label": "Xero Entity",
        "sortable": "true"},
    {"fieldName": "responseStatusCode",
        "label": "Response",
        "sortable": "true"},
    {"fieldName": "responseStatus",
        "label": "Response Status",
        "sortable": "true"},
    {"fieldName": "createdDate",
        "label": "Date",
        "sortable": "true",
        "type": "date"}
];

export default class TroubleShootingLogCmp extends LightningElement {

    @track isLoading = false;

    @track records;

    @track tableData;

    @track columns = columns;

    @track sortBy;

    @track sortDirection;

    @track showPagination = false;

    totalRecords;

    pageSize;

    @track maxDate;

    @track maxMonth;

    @track maxYear;

    @track minDate;

    @track minMonth;

    @track minYear;

    @track daysValue;

    @track savedisable = true;

    @track logConfig;

    @track scheduleData;

    @track showTime = true;

    @track deleteDisable = false;

    @track deleteMessage;

    @track daysOptions = [
        {"label": "Daily",
            "value": "Daily"},
        {"label": "Weekly",
            "value": "Weekly"},
        {"label": "Monthly",
            "value": "Monthly"},
        {"label": "Every 6 Months",
            "value": "6 Months"},
        {"label": "Yearly",
            "value": "Yearly"},
        {"label": "I will do it Manually",
            "value": "None"}
    ];

    connectedCallback () {

        this.totalRecords = 0;
        this.pageSize = 10;
        this.logConfig = {};
        this.getLogs();
        // this.getLogConfiguration();

    }

    getLogs () {

        this.isLoading = true;
        const month1 = 1,
            testLen = 0;

        getLogData({}).
            then((result) => {
             
                if (result.length > testLen) {
                    
                    this.totalRecords = result.length;
                    this.deleteMessage = `Delete Logs`;
                    this.tableData = result;

                    const maxDate = new Date(Math.max(...result.map((element) => new Date(element.createdDate)))),
                        minDate = new Date(Math.min(...result.map((element) => new Date(element.createdDate))));
                    this.maxDate = maxDate.getDate();
                    this.maxMonth = maxDate.getMonth() + month1;
                    this.maxYear = maxDate.getFullYear();

                    this.minDate = minDate.getDate();
                    this.minMonth = minDate.getMonth() + month1;
                    this.minYear = minDate.getFullYear();

                    if (result.length > this.pageSize) {

                        this.showPagination = true;
                        this.records = this.tableData.slice(
                            testLen,
                            this.pageSize
                        );

                    } else {

                        this.showPagination = false;
                        this.records = result;

                    }


                } else {

                    this.deleteDisable = true;
                    this.deleteMessage = "No log data found";
                    this.tableData = null;

                }
             

                this.isLoading = false;

                this.getLogConfiguration();
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
                    this.showToast(this.title, this.message, this.variant, "dismissable");
                    this.isLoading = false;
                    this.getLogConfiguration();
                }

            });


    }

    getSchedule (doGetLogs) {

        
        const num0 = 0;
        this.isLoading = true;
        getScheduleData({
            "scheduleName": "LogBatchDeleteSchedule"
        }).
        then((result) => {
            
            
                
                const schedule = JSON.stringify(result);
                this.scheduleData = JSON.parse(schedule);
                if (doGetLogs) {

                    if (this.records.length !== num0) {

                        // this.getLogs();

                    }
                    this.isLoading = false;

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
                    this.showToast(this.title, this.message, this.variant, "dismissable");
                    this.isLoading = false;
                }
              

            });

    }

    getLogConfiguration () {

        
        this.isLoading = true;
        getLogConfig({}).
            then((result) => {

                if(result){

                    const logConfigData = JSON.stringify(result);
                    this.logConfig = JSON.parse(logConfigData);
                    if (this.logConfig.deleteLog === "None") {
    
                        this.showTime = false;
    
                    }
                    this.isLoading = false;
                    
                    this.getSchedule(true);
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
                    this.showToast(this.title, this.message, this.variant, "dismissable");
                    this.isLoading = false;
                    this.getSchedule(true);
                    
                }

            });

    }

    doSorting (event) {

        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(
            this.sortBy,
            this.sortDirection
        );

    }

    sortData (fieldname, direction) {

        let isReverse = 0;
        const keyValue = (akey) => akey[fieldname],
            num1 = 1,
            numminus1 = -1,
            parseData = JSON.parse(JSON.stringify(this.records));

        if (direction === "asc") {

            isReverse = num1;

        } else {

            isReverse = numminus1;

        }
        // Sorting data
        parseData.sort((xEle, yEle) => {

            let aEle = "",
                bEle = "";
            if (keyValue(xEle)) {

                aEle = keyValue(xEle);

            } else {

                aEle = "";

            }

            if (keyValue(yEle)) {

                bEle = keyValue(yEle);

            } else {

                bEle = "";

            }

            // Sorting values based on direction
            return isReverse * ((aEle > bEle) - (bEle > aEle));

        });

        this.records = parseData;

    }

    handlePagination (event) {

        const counter = 1,
            end = this.pageSize * event.detail,
            start = (event.detail - counter) * this.pageSize;
        this.records = this.tableData.slice(
            start,
            end
        );

    }

    handledayChange (event) {

        this.savedisable = false;
        this.logConfig.deleteLog = event.detail.value;
        if (event.detail.value === "None") {

            this.showTime = false;

        } else {

            this.showTime = true;

        }

    }

    handleSave () {

        this.isLoading = true;
        updateLogConfig({
            "configData": JSON.stringify(this.logConfig),
            "scheduleJobId": this.scheduleData.id
        }).
            then((result) => {

                if (result) {

                    this.showToast(
                        "Logs Configuration",
                        "Logs Configuration is Updated",
                        "success",
                        "dismissable"
                    );
                    this.savedisable = true;
                    this.getSchedule(false);

                } else {

                    this.showToast(
                        "Logs Configuration",
                        "Something went wrong",
                        "error",
                        "dismissable"
                    );

                }
                this.isLoading = false;
                this.activeTab = "log";

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
                    this.showToast(this.title, this.message, this.variant, "dismissable");
                    this.isLoading = false;
                    
                }


            });

    }

    handleDeleteLogs () {

        this.isLoading = true;
        const tobeDeleted = [];
        this.tableData.forEach((element) => {

            tobeDeleted.push(element.id);

        });
        deleteLogs({
            "deleteList": tobeDeleted
        }).
            then((result) => {

                if (result) {

                    this.showToast(
                        "Logs Configuration",
                        "All logs are deleted",
                        "success",
                        "dismissable"
                    );
                    this.getLogs();

                } else {

                    this.showToast(
                        "Logs Configuration",
                        "Something went wrong",
                        "error",
                        "dismissable"
                    );

                }
                this.isLoading = false;
                this.activeTab = "log";

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
                    this.showToast(this.title, this.message, this.variant, "dismissable");
                    this.isLoading = false;
                    
                }

            });

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