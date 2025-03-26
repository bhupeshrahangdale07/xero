import {LightningElement, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import fetchPermissionSets from "@salesforce/apex/PermissionSetController.fetchPermissionSets";
import fetchPermissions from "@salesforce/apex/SetupConfigController.fetchPermissionSets";
import insertLog from "@salesforce/apex/Utils.insertLog";

const columns = [
        {"fieldName": "name",
            "label": "Name",
            "sortable": true,
            "type": "text"},
        {"fieldName": "userName",
            "label": "User Name",
            "sortable": true,
            "type": "text"},
        {"fieldName": "email",
            "label": "Email",
            "sortable": true,
            "type": "Email"},
        {"fieldName": "isActive",
            "label": "Active",
            "type": "Checkbox"},
        {"fieldName": "profile",
            "label": "Profile",
            "sortable": true,
            "type": "text"}

    ],

    sortData = function sortData (fieldname, direction, data) {

        let isReverse = 0;
        const keyValue = (akey) => akey[fieldname],
            num1 = 1,
            numminus1 = -1,
            parseData = JSON.parse(JSON.stringify(data));

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

        return parseData;

    };

export default class PermissionSetCmp extends LightningElement {


    @track showLoading = false;

    @track sortBy;

    @track sortDirection;

    @track permissionSets;

    @track userList;

    @track readOnlyUser = [];

    @track opeartionalUser = [];

    @track adminUser = [];

    @track errorFlag = false;
    @track title = "";
    @track message = "";
    @track variant = "";

    columns = columns;

    connectedCallback () {

        this.getPermissionsets();

    }

    sortOprational (event) {

        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.opeartionalUser = sortData(
            this.sortBy,
            this.sortDirection,
            this.opeartionalUser
        );

    }

    sortAdmin (event) {

        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.adminUser = sortData(
            this.sortBy,
            this.sortDirection,
            this.adminUser
        );

    }


    sortReadOnly (event) {

        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.readOnlyUser = sortData(
            this.sortBy,
            this.sortDirection,
            this.readOnlyUser
        );

    }

    refreshPermissionSet(){
        this.readOnlyUser = [];
        this.opeartionalUser = [];
        this.adminUser = [];
        this.getPermissionsets();
    }

    getPermissionsets () {

        this.showLoading = true;
        const num0 = 0,
            num1 = 1;
        fetchPermissionSets({}).
            then((result) => {

                if (result.length > num0) {

                    for (let ind = 0; ind < result.length; ind += num1) {

                        if (result[ind].permissionSetName === "Xero_Integration_Operational") {

                            this.opeartionalUser.push(result[ind]);

                        } else if (result[ind].permissionSetName === "Xero_Integration_Admin") {

                            this.adminUser.push(result[ind]);

                        } else if (result[ind].permissionSetName === "Xero_Integration_User_Read_Only") {

                            this.readOnlyUser.push(result[ind]);

                        }

                    }

                }
                this.showLoading = false;

            }).
            catch((error) => {

                this.showLoading = false;
                
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


        // To get the URL
        fetchPermissions({}).
            then((result) => {

                if (result.length > num0) {

                    const pMap = new Map();
                    result.forEach((ele) => {

                        pMap.set(
                            ele.name,
                            ele.setupUrl
                        );

                    });
                    this.permissionSets = pMap;

                }

            }).
            catch((error) => {
                
                this.showLoading = false;
                
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

    handlePermission (event) {

        const permission = event.target.value,
            url = this.permissionSets.get(permission);
        window.open(
            url,
            "_blank"
        );

    }

    showToast (title, message, variant) {

        const evt = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(evt);

    }

    renderedCallback(){
        if(this.title !== '' && this.message !== '' && this.variant !== '' && this.errorFlag === true){

            this.showToast(this.title, this.message, this.variant);
            this.errorFlag = false;
        }
    }

}