import {LightningElement, track, wire} from "lwc";
import {getRecord} from "lightning/uiRecordApi";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import deleteDocuments from "@salesforce/apex/HelpSupportController.deleteDocuments";
import getFilesSize from "@salesforce/apex/HelpSupportController.getFilesSize";
import id from "@salesforce/user/Id";
import submitCase from "@salesforce/apex/HelpSupportController.submitCase";
import userEmailFIELD from "@salesforce/schema/User.Email";
import userFirstNameField from "@salesforce/schema/User.FirstName";
import userLastNameField from "@salesforce/schema/User.LastName";
import docLink from '@salesforce/label/c.Xero_User_Guide';
import insertLog from "@salesforce/apex/Utils.insertLog";

export default class HelpSupportCmp extends LightningElement {

    @track showLoading = false;

    @track documentLink = docLink;

    @track error;

    @track userId = id;

    @track userFirstName;

    @track userLastName;

    @track userEmail;

    @track supportData = {
        "description": "",
        "email": "",
        "enquiryValue": "",
        "firstName": "",
        "lastName": ""
    };

    @track documentIdList = [];

    @track docVersionList = [];

    @track fileData = [];

    @track fileMsg = "(Keep total file size <= 2MB)";

    @track fontColour = "yellowfont";

    @track enquiryOptions = [
        {"label": "Technical",
            "value": "Technical"},
        {"label": "Suggestions",
            "value": "Suggestions"},
        {"label": "Functionality Understanding",
            "value": "Functionality Understanding"},
        {"label": "Sales or Demo",
            "value": "Sales or Demo"},
        {"label": "Subscription",
            "value": "Subscription"},
        {"label": "Other",
            "value": "Other"}
    ];

    @wire(getRecord, {
        "fields": [
            userFirstNameField,
            userLastNameField,
            userEmailFIELD
        ],
        "recordId": id
    })

    currentUserInfo ({data,
        error}) {

        if (data) {

            this.supportData.firstName = data.fields.FirstName.value;
            this.supportData.lastName = data.fields.LastName.value;
            this.supportData.email = data.fields.Email.value;

        } else if (error) {

            this.error = error;

        }

    }


    handleChange (event) {

        const {name} = event.target;
        if (name === "enquiryType") {

            this.supportData.enquiryValue = event.detail.value;

        } else if (name === "FirstName") {

            this.supportData.firstName = event.detail.value;

        } else if (name === "LastName") {

            this.supportData.lastName = event.detail.value;

        } else if (name === "email") {

            this.supportData.email = event.detail.value;

        } else if (name === "Description") {

            this.supportData.description = event.detail.value;

        }

    }

    handleUploadFinished (event) {

        // Get the list of uploaded files
        const docList = [],
            documentVersionList = [],
            filesData = event.detail.files;
        filesData.forEach((element) => {

            this.fileData.push(element);

        });
        this.fileData.forEach((element) => {

            documentVersionList.push(element.contentVersionId);
            docList.push(element.documentId);

        });
        
        this.showLoading = true;
        getFilesSize({
            "docIdList": docList
        }).
            then((result) => {

                if (result) {

                    const fileDLen = 1;
                    if (this.fileData.length > fileDLen) {

                        this.fileMsg = `${this.fileData.length} files attached`;

                    } else {

                        this.fileMsg = `${this.fileData.length} file attached`;

                    }
                    this.fontColour = "greenfont";
                    this.documentIdList = [...docList];
                    this.docVersionList = [...documentVersionList];

                } else {

                    this.fileMsg = '(Keep total file size <= 2MB)';
                    this.fontColour = "yellowfont";
                    this.showToast(
                        "Total file size is bigger than 2 MB",
                        "Keep files size <= 2MB",
                        "error",
                        "dismissable"
                    );
                    this.fileData = [];
                    this.documentIdList = [];
                    this.docVersionList = [];
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
                    this.showToast(this.title, this.message, this.variant, "dismissable");
                    this.showLoading = false;
                }

            });

    }

    handleSubmit () {

        this.showLoading = true;
        const descText = this.supportData.description.replaceAll(' ', '');
        if(!descText && descText.length <= 300){
            this.showToast(
                "Please add description",
                "Maximum 300 characters allowed",
                "error",
                "dismissable"
            );
            this.showLoading = false;
        }else{

            submitCase({
                "filesData": this.docVersionList,
                "supportData": JSON.stringify(this.supportData)
            }).
                then((result) => {
    
                    if (result) {
    
                        this.showToast(
                            "Case has been submitted",
                            "You will hear back from us soon",
                            "success",
                            "dismissable"
                        );
                        this.supportData.enquiryValue = "";
                        this.supportData.description = "";
                        this.showLoading = false;
                        const lengthTest = 0;
                        if (this.documentIdList.length > lengthTest) {
    
                            this.deleteFiles();
                            this.fileMsg = "(Keep total file size <= 2MB)";
                            this.fontColour = "yellowfont";
                            this.documentIdList = [];
                            this.docVersionList = [];
                            this.fileData = [];
    
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
                        this.showToast(this.title, this.message, this.variant, "dismissable");
                        this.showLoading = false;
                    }
    
                });
        }

    }

    deleteFiles () {

        this.showLoading = false;
        deleteDocuments({
            "deleteIds": this.documentIdList
        }).
            then((result) => {

                if (result) {

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
                    this.showToast(this.title, this.message, this.variant, "dismissable");
                    this.showLoading = false;
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