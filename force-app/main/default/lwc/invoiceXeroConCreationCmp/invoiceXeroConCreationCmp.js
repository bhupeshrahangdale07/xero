import {LightningElement, api, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import checkAccountName from "@salesforce/apex/InvoiceCreationController.checkAccountName";
import getAccountDetails from "@salesforce/apex/InvoiceCreationController.getAccountDetails";
import getAccountWrapper from "@salesforce/apex/InvoiceCreationController.getAccountWrapper";
import getXeroCons from "@salesforce/apex/InvoiceCreationController.getXeroCons";
import insertLog from "@salesforce/apex/Utils.insertLog";

function checkrequire (field) {

    if (typeof field === "string") {

        return field.trim() === "";

    }

    return field === null;

}
const requiredfieldCheck = function requiredfieldCheck (arr) {

        const atempStr = JSON.stringify(arr),
            bnewarr = JSON.parse(atempStr),
            cvaluearr = Object.values(bnewarr);
        let ret = false;

        ret = cvaluearr.some(checkrequire);

        return ret;

    },
    validateEmail = function validateEmail (email) {

        let flag = false;
        const validRegex = /^\w+(?:[\\.-]?\w+)*@\w+(?<temp1>[\\.-]?\w+)*(?<temp2>\.\w{2,3})+$/u;

        if (validRegex.test(email)) {

            flag = true;

        } else if (!validRegex.test(email)) {

            flag = false;

        }

        return flag;

    };



export default class InvoiceXeroConCreationCmp extends LightningElement {

    @api accountId;

    @api accountName;

    @api xeroContact;

    @api previousAccDetails;

    @api previousConDetails;

    @api previousConPersonDetails;

    @track contacts;

    @track conOptions;

    @track conoptionsValue = "";

    @track conValue;

    @track accountDetails;

    @track editaccountDetails;

    @track showLoading = false;

    @track xeroContacts = [];

    @track newContact;

    @track xeroContactPersons = [];

    @track contactPersonsCount;

    @track disableAddButton = false;

    @track secondaryconOptions;

    @track conOptionArray;

    @track nextEnabled = false;

    @track companyList = [];
    @track conOptions1 = [];
    @track conOptions2 = [];
    @track conOptions3 = [];

    @track error;

    connectedCallback () {

        this.contactPersonsCount = 0;
        this.showLoading = true;
        
        // this.fetchAccount();
        this.getXeroCons();
        
        this.updatePreviousDetails();
        this.showLoading = false;

    }

    getXeroCons () {

        const num0 = 0;

        try{

            if (this.accountId !== null && typeof this.accountId !== "undefined") {

                getXeroCons({
                    "accountId": this.accountId,
                    "accountName": this.accountName
                }).
                    then((result) => {

                        if (result.length !== num0) {

                            result.forEach((element) => {

                                this.companyList.push(element.KTXero__Company_Name__c.replaceAll(
                                    " ",
                                    ""
                                ));

                            });

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
        
                            this.showErrorToast("Something Went Wrong", errorMsg, "error","dismissable");
                        }


                    });

            }
        }catch(error){
            this.error = error;
        }

    }

    updatePreviousDetails () {

        const num0 = 0,
        num1 = 1,
        num16 = 16,
        num36 = 36,
        num7 = 7;
        
        try{
            this.showLoading = true;
            if (Object.keys(this.previousAccDetails).length !== num0) {
                const preDetails = JSON.stringify(this.previousAccDetails);
                this.accountDetails = JSON.parse(preDetails);
                this.editaccountDetails = JSON.parse(preDetails);
            } else {
                this.fetchAccount();
            }
    
            if (Object.keys(this.previousConDetails).length !== num0 || this.previousConDetails !== null) {
    
                if (typeof this.previousConDetails.conId === "string") {
    
                    this.conoptionsValue = this.previousConDetails.conId;
                    const conDetail = JSON.stringify(this.previousConDetails);
                    this.conValue = JSON.parse(conDetail);
                    this.newContact = JSON.parse(conDetail);
                    
                } else if(typeof this.previousConDetails.conId !== "undefined"){
    
                    const conDetail = JSON.parse(JSON.stringify(this.previousConDetails)),
                        a16 = 16,
                        myNewElement = {"conEmail": conDetail.conEmail,
                            "conFirstName": conDetail.conFirstName,
                            "conId": Math.random() * a16,
                            "conLastName": conDetail.conLastName,
                            "conName": conDetail.conName};
                    this.conValue = myNewElement;
                    this.conoptionsValue = "None";
                    this.newContact = myNewElement;
    
                }

                getAccountDetails({"accountId": this.accountId}).
                    then((result) => {
                        
                        let options = [];
                        options.push({"label": "Enter details manually",
                                "value": "None"});
                        if (result.conList.length !== num0) {
                            this.contacts = result.conList;
                            for (let ind = 0; ind < result.conList.length; ind += num1) {

                                options.push({"label": result.conList[ind].conName,
                                    "value": result.conList[ind].conId});

                            }

                        }
                        this.conOptions1 = options;
                        this.conOptions2 = options;
                        this.conOptions3 = options;

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
    
                        this.showErrorToast("Something Went Wrong", errorMsg, "error");
                    }

                });
    
            }
    
            if (Object.keys(this.previousConPersonDetails).length !== num0 || this.previousConPersonDetails !== null) {
    
                const conOptions1Copy = [...this.conOptions1],
                    conPerOp = [],
                    mainArr = [],
                    parr = [...this.previousConPersonDetails];
                parr.forEach((element) => {
    
                    const arandomId = `${Math.random() * num16}${(Math.random() + num1).toString(num36).substring(num7)}`,
                        conOpArr = [...element.conOptions],
                        newConOpArr = [],
                        myNewElement = {
                            "conEmail": element.conEmail,
                            "conFirstName": element.conFirstName,
                            "conId": arandomId,
                            "conLastName": element.conLastName,
                            "conOptions": [...newConOpArr],
                            "conoptionsValue": element.conoptionsValue,
                            "includeinEmail": element.includeinEmail,
                            "showfields": true
                        };
    
                    conOpArr.forEach((ele1) => {
    
                        newConOpArr.push({"label": ele1.label,
                            "value": ele1.value});
    
                    });
    
                    myNewElement.conOptions = [...newConOpArr];
    
                    mainArr.push(myNewElement);
    
    
                    conPerOp.push(element.conoptionsValue);
    
                });
    
    
                this.conOptions1 = [];
                conOptions1Copy.forEach((element) => {
    
                    if (element.value === "None") {
    
                        this.conOptions1.push({"label": "Enter details manually",
                            "value": "None"});
    
                    }
                    if (!conPerOp.includes(element.value) && element.value !== "None") {
    
                        this.conOptions1.push(element);
    
                    }
    
                });
    
    
                this.xeroContactPersons = [];
                this.xeroContactPersons = [...mainArr];
                this.contactPersonsCount = this.previousConPersonDetails.length;
                this.showLoading = false;
            }
        }catch(error){
            this.error = error;
            this.showLoading = false;
        }

    }

    fetchAccount () {

        const num1 = 1;

        try{
            
            if (this.accountId !== null && typeof this.accountId !== "undefined") {
                
    
                getAccountDetails({"accountId": this.accountId}).
                    then((result) => {
                        
                        if (result !== null) {
    
                            const num0 = 0,
                                options = [];
                            this.accountDetails = result;
                            this.conOptions1 = [];
                            this.conOptions2 = [];
                            this.conOptions3 = [];
                            options.push({"label": "Enter details manually",
                                "value": "None"});
    
                            if (Object.keys(this.previousAccDetails).length === 0 || this.previousAccDetails === null || this.previousAccDetails === '') {
    
                                const newarr = JSON.stringify( result );
                                this.editaccountDetails = JSON.parse(newarr);
                                delete this.editaccountDetails.conList;
    
                            }
    
                            if (result.conList.length !== num0) {
    
                                this.contacts = result.conList;
                                for (let ind = 0; ind < result.conList.length; ind += num1) {
    
                                    options.push({"label": result.conList[ind].conName,
                                        "value": result.conList[ind].conId});
    
                                }
    
                            }
                            this.conOptions1 = options;
                            this.conOptions2 = options;
                            this.conOptions3 = options;
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
        
                            this.showErrorToast("Something Went Wrong", errorMsg, "error");
                        }
    
                    });
    
            } else {
                
                
                // if(Object.keys(this.previousAccDetails).length === null){
                    
                    getAccountWrapper({}).
                    then((result) => {
                        
                        if (result !== null) {
                            this.accountDetails = result;
                            const newarr = JSON.stringify( result );
                            this.editaccountDetails = JSON.parse(newarr);
    
                            let options = [];
                            options.push({"label": "Enter details manually",
                                "value": "None"});
                            this.conOptions1 = options;
                            this.conOptions2 = options;
                            this.conOptions3 = options;
                        }
                    })
                    .catch((error) => {
    
                        this.error = error;
    
                    });
                    
                // }
            }
        }catch(error){
            this.error = error;
        }

    }


    handleChange(event){
        const selectedVal = event.detail.value;
        const targetName = event.target.name;
        
        if(targetName === 'contacts1'){

            // Old selected value update logic
            const oldVal = this.conoptionsValue; // Get Old Value
            if(typeof oldVal !== 'undefined' && oldVal !== 'None'){
                if(this.xeroContactPersons){
                    this.xeroContactPersons.forEach(xcp => {
                        if(xcp.conoptionsValue !== oldVal){
                            const xcpIndex = xcp.conOptions.findIndex((opt) => opt.value === oldVal);
                            if(xcpIndex === -1){
                                const sfCon = this.contacts.find((ele) => ele.conId === oldVal);
                                
                                xcp.conOptions.push({"label": sfCon.conName,
                                "value": sfCon.conId});
                            }
                        }

                    });
                }
            }
            // Old selected value update logic End

            // Value is None
            if(selectedVal === 'None'){
                this.showLoading = true;

                //Start -- To fill the contact value
                const arandomId = Math.random() * 16;
                const myNewElement = {"conEmail": "",
                        "conFirstName": "",
                        "conId": arandomId,
                        "conLastName": "",
                        "conName": ""};

                this.conValue = myNewElement;
                this.newContact = myNewElement;
                this.conoptionsValue = selectedVal;
                // End -- To fill the contact value

                this.showLoading = false;
            }else{ // Values is not None
                this.showLoading = true;
                // Fetch contact from Salesforce List and update the Value in Xero Contact1 fields
                const sfCon = this.contacts.find((ele) => ele.conId === selectedVal);

                if(sfCon){
                    this.conValue = sfCon;
                    this.newContact = sfCon;
                    this.conoptionsValue = selectedVal;

                    if(this.xeroContactPersons){
                        this.xeroContactPersons.forEach(xcp => {
                            
                            const xcpIndex = xcp.conOptions.findIndex((opt) => opt.value === selectedVal);
                            if(xcpIndex >= -1){
                                xcp.conOptions.splice(xcpIndex, 1);
                            }
                            
    
                        });
                    }                    
                }
                this.showLoading = false;
            }

        } else if(targetName === 'contacts2'){
            const datasetId = event.target.dataset.id;

            const foundContactPerson = this.xeroContactPersons.find((ele) => ele.conId === datasetId);
            
            const oldVal = foundContactPerson.conoptionsValue; // find old value of change xerocon person
            if(typeof oldVal !== 'undefined' && oldVal !== 'None' && oldVal !== ''){
                // Start Update XeroContact Persons Options
                if(this.xeroContactPersons){
                    this.xeroContactPersons.forEach(xcp => {
                        if(foundContactPerson.conId !== xcp.conId){ // Changed xeroconperson value should not be same from the whole xeroContactPersons
                            if(xcp.conoptionsValue !== oldVal){
                                const xcpIndex = xcp.conOptions.findIndex((opt) => opt.value === oldVal);
                                if(xcpIndex === -1){
                                    const sfCon = this.contacts.find((ele) => ele.conId === oldVal);
                                    
                                    xcp.conOptions.push({"label": sfCon.conName,
                                    "value": sfCon.conId});
                                }
                            }
                        }
                    });
                }
                // End Update XeroContact Persons Options

                // Start Update contact1 options
                const conOptionIndex = this.conOptions1.findIndex((opt) => opt.value === oldVal);
                if(conOptionIndex === -1){
                    const sfCon = this.contacts.find((ele) => ele.conId === oldVal);
                    this.conOptions1.push({"label": sfCon.conName,
                        "value": sfCon.conId});
                }
                // End Update contact1 options
            }

            if(selectedVal === 'None'){
                this.showLoading = true;
                foundContactPerson.conoptionsValue = selectedVal;
                foundContactPerson.conEmail = "";
                foundContactPerson.conFirstName = "";
                foundContactPerson.conLastName = "";
                foundContactPerson.includeinEmail = false;
                foundContactPerson.showfields = true;
                this.showLoading = false;
            }else{
                this.showLoading = true;
                const sfCon = this.contacts.find((ele) => ele.conId === selectedVal);
                foundContactPerson.conFirstName = sfCon.conFirstName;
                foundContactPerson.conLastName = sfCon.conLastName;
                foundContactPerson.conEmail = sfCon.conEmail;
                foundContactPerson.conoptionsValue = selectedVal;
                foundContactPerson.showfields = true;

                // remove selectedValue from contact1 option list
                const conOptionIndex = this.conOptions1.findIndex((opt) => opt.value === selectedVal);
                if(conOptionIndex >= -1){
                    this.conOptions1.splice(conOptionIndex, 1);
                }
                // remove selectedValue from contact1 option list End

                // remove selectedValue from contact2 option list
                this.xeroContactPersons.forEach(xcp => {
                    if(foundContactPerson.conId !== xcp.conId){
                        
                        const xcpIndex = xcp.conOptions.findIndex((opt) => opt.value === selectedVal);
                        if(xcpIndex >= -1){
                            xcp.conOptions.splice(xcpIndex, 1);
                        }
                    }
                });
                // remove selectedValue from contact2 option list End

                // Disable next button on change if data is saved already
                if (this.nextEnabled) {

                    this.disableNextButton();

                }
                this.showLoading = false;
            }

            if (this.contactPersonsCount !== 5) {

                this.disableAddButton = false;

            }
        }

    }

  
    // Update contact row values in list
    updateContactValues (event) {

        if (event.target.name === "conFirstName") {

            this.newContact.conFirstName = event.target.value;
            this.newContact.conName = `${this.newContact.conFirstName} ${this.newContact.conLastName}`;

        } else if (event.target.name === "conLastName") {

            this.newContact.conLastName = event.target.value;
            this.newContact.conName = `${this.newContact.conFirstName} ${this.newContact.conLastName}`;

        } else if (event.target.name === "conEmail") {

            this.newContact.conEmail = event.target.value;

        }

        // Disable next button on change if data is saved already
        if (this.nextEnabled) {

            this.disableNextButton();

        }

    }

    addcontact () {

        const num0 = 0,
            num1 = 1,
            num16 = 16,
            num1minus = -1,
            num36 = 36,
            num5 = 5,
            num7 = 7;
        if (this.contactPersonsCount < num5) {

            const arandomId = `${Math.random() * num16}${(Math.random() + num1).toString(num36).substring(num7)}`,
                con2Arr = [],
                myNewElement = {
                    "conEmail": "",
                    "conFirstName": "",
                    "conId": arandomId,
                    "conLastName": "",
                    "conOptions": [],
                    "conoptionsValue": "",
                    "includeinEmail": false,
                    "showfields": false
                },
                newAr = [],
                newOptionsArr = [];
            if (this.xeroContactPersons) {

                this.xeroContactPersons.forEach((element) => {

                    con2Arr.push(element.conoptionsValue);

                });

            }

            this.conOptions3.forEach((element) => {

                if (element.value !== this.conoptionsValue && (con2Arr.indexOf(element.value) === num1minus || element.value === "None")) {

                    newOptionsArr.push({"label": element.label,
                        "value": element.value});

                }
                newAr.push(element.value);

            });

            if (newOptionsArr.length === num0) {

                newOptionsArr.push({"label": "Enter details manually",
                    "value": "None"});

            }

            myNewElement.conOptions = newOptionsArr;

            let flag = false;
            myNewElement.conOptions.forEach((element) => {

                if (element.value === "None") {

                    flag = true;

                }

            });
            if (!flag) {

                myNewElement.conOptions.push({"label": "Enter details manually",
                    "value": "None"});

            }

            this.xeroContactPersons = [
                ...this.xeroContactPersons,
                myNewElement
            ];
            this.contactPersonsCount += 1;

            this.disableAddButton = true;

        }

        // Disable next button on change if data is saved already
        if (this.nextEnabled) {

            this.disableNextButton();

        }

    }



    removeClick (event) {

        this.showLoading = true;
        // fidning removed element from Xero contact persons
        const foundRemoved = this.xeroContactPersons.find((ele) => ele.conId === event.target.dataset.id);
        const oldVal = foundRemoved.conoptionsValue;

        if (oldVal !== "None" && oldVal !== "") {
            // Start Update contact1 options
            const conOptionIndex = this.conOptions1.findIndex((opt) => opt.value === oldVal);

            if(conOptionIndex === -1){
                const sfCon = this.contacts.find((ele) => ele.conId === oldVal);
                this.conOptions1.push({"label": sfCon.conName,
                    "value": sfCon.conId});
            }
            // End Update contact1 options


            //start updating Xero contact person
            this.xeroContactPersons.forEach(xcp => {
                if(foundRemoved.conId !== xcp.conId){ // Changed xeroconperson value should not be same from the whole xeroContactPersons
                    if(xcp.conoptionsValue !== oldVal){
                        const xcpIndex = xcp.conOptions.findIndex((opt) => opt.value === oldVal);
                        if(xcpIndex === -1){
                            const sfCon = this.contacts.find((ele) => ele.conId === oldVal);
                            
                            xcp.conOptions.push({"label": sfCon.conName,
                            "value": sfCon.conId});
                        }
                    }
                }
            });
            // End Update XeroContact Persons Options

        }
        if (this.contactPersonsCount < 5) {

            this.disableAddButton = false;

        }
        const ind = this.xeroContactPersons.findIndex((conp) => conp.conId === event.target.dataset.id)
        this.xeroContactPersons.splice(
            ind,
            1
        );
        this.contactPersonsCount -= 1;
        this.showLoading = false;

        // Disable next button on change if data is saved already
        if (this.nextEnabled) {

            this.disableNextButton();

        }
        
    }

    updateContactPersonValues (event) {

        const foundelement = this.xeroContactPersons.find((ele) => ele.conId === event.target.dataset.id);
        if (event.target.name === "conFirstName") {

            foundelement.conFirstName = event.target.value;

        } else if (event.target.name === "conLastName") {

            foundelement.conLastName = event.target.value;

        } else if (event.target.name === "conEmail") {

            foundelement.conEmail = event.target.value;

        } else if (event.target.name === "includeinEmail") {

            foundelement.includeinEmail = event.target.checked;

        }

        // Disable next button on change if data is saved already
        if (this.nextEnabled) {

            this.disableNextButton();

        }

    }

    updateAccountValues (event) {

        
        
        if (event.target.name === "Account Number") {

            this.editaccountDetails.accNumber = event.target.value;
            

        } else if (event.target.name === "Account Name") {

            this.editaccountDetails.accName = "";
            if (typeof this.xeroContact !== "undefined") {

                if (this.xeroContact.companyName === event.target.value) {

                    this.showErrorToast(
                        "Account Name Error",
                        "Xero Contact already exist with Same Account Name. Please provide different Name.",
                        "error",
                        "dismissable"
                    );

                }

            }
            this.editaccountDetails.accName = event.target.value;

        } else if (event.target.name === "Street Address") {

            this.editaccountDetails.accStreet = event.target.value;

        } else if (event.target.name === "City") {

            this.editaccountDetails.accCity = event.target.value;

        } else if (event.target.name === "State") {

            this.editaccountDetails.accState = event.target.value;

        } else if (event.target.name === "postal code") {

            this.editaccountDetails.accPostalCode = event.target.value;

        } else if (event.target.name === "Country") {

            this.editaccountDetails.accCountry = event.target.value;

        } else if (event.target.name === "Account Phone") {

            this.editaccountDetails.accPhone = event.target.value;

        } else if (event.target.name === "Shipping Street") {

            this.editaccountDetails.accShippingStreet = event.target.value;

        } else if (event.target.name === "Shipping City") {

            this.editaccountDetails.accShippingCity = event.target.value;

        } else if (event.target.name === "Shipping State") {

            this.editaccountDetails.accShippingState = event.target.value;

        } else if (event.target.name === "Shipping Postal/Zip Code") {

            this.editaccountDetails.accShippingPostalCode = event.target.value;

        } else if (event.target.name === "Shipping Country") {

            this.editaccountDetails.accShippingCountry = event.target.value;

        }

        // Disable next button on change if data is saved already
        if (this.nextEnabled) {

            this.disableNextButton();

        }

        
    }

   

    showErrorToast (title, message, variant, mode) {

        const evt = new ShowToastEvent({
            title,
            message,
            variant,
            mode
        });
        this.dispatchEvent(evt);

    }

    disableNextButton () {

        this.dispatchEvent(new CustomEvent(
            "disablebutton",
            {
                "detail": false
            }
        ));

    }

    @api checkAccountName () {

        let flag = false;
        checkAccountName({
            "accName": this.editaccountDetails.accName,
            "accNumber": this.editaccountDetails.accNumber
        }).
            then((result) => {

                if (result) {

                    if (result.isDuplicate) {

                        flag = result.isDuplicate;
                        this.showErrorToast(
                            `${result.fieldName} Error`,
                            `Xero Contact already exist with Same ${result.fieldName} . Please provide different values.`,
                            "error",
                            "dismissable"
                        );

                    } else {

                        this.saveClick();

                    }

                }

            }).
            catch((error) => {

                this.showLoading = true;
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

                    this.showErrorToast("Something Went Wrong", errorMsg, "error","dismissable");
                }
                this.showLoading = false;

            });

        return flag;

    }

    @api saveClick () {

        let emailFlag = false,
            emailPerFlag = false,
            eventFlag = true;

        if (typeof this.conoptionsValue === "undefined" || !this.conoptionsValue) {

            this.showErrorToast(
                "Contact is blank",
                "Contact is blank. Please choose valid option.",
                "error",
                "dismissable"
            );
            return;

        }

        const conEmail = this.template.querySelectorAll(".contactEmail"),
            conFlag = requiredfieldCheck(this.newContact),
            xeroConPerson = this.xeroContactPersons;
        if (conFlag) {

            this.showErrorToast(
                "Contact fields are blank",
                "Contact Fields are blank. Please fill values first.",
                "error",
                "dismissable"
            );
            eventFlag = false;
            return;

        }

        conEmail.forEach(
            function checkEmail (element) {

                if (element.name === "conEmail") {

                    if (!validateEmail(element.value)) {

                        emailFlag = true;

                    }

                }

            },
            this
        );

        if (this.xeroContactPersons) {

            let contpersonsFlag = false;
            const aarrStr = JSON.stringify(this.xeroContactPersons),
                arr = JSON.parse(aarrStr),
                num1 = 1;
            for (let ind = 0; ind < arr.length; ind += num1) {

                if (requiredfieldCheck(arr[ind])) {

                    contpersonsFlag = true;
                    break;

                }

            }

            if (contpersonsFlag) {

                this.showErrorToast(
                    "Contact Persons fields are blank",
                    "Contact Persons Fields are blank. Please fill values first.",
                    "error",
                    "dismissable"
                );
                eventFlag = false;
                return;

            }

        }

        xeroConPerson.forEach((element) => {

            if (!validateEmail(element.conEmail)) {

                emailPerFlag = true;

            }

        });

        if (emailFlag || emailPerFlag) {

            this.showErrorToast(
                "Email Error",
                "Please enter valid email.",
                "error",
                "dismissable"
            );
            eventFlag = false;
            return;

        }

        if(typeof this.editaccountDetails.accName === 'undefined'){
            this.showErrorToast(
                "Account Name is blank",
                "Account Name is blank. Please fill values first.",
                "error",
                "dismissable"
            );
            eventFlag = false;
            return;
        }

        if (!this.editaccountDetails.accName.replaceAll(
            " ",
            ""
        )) {

            this.showErrorToast(
                "Account Name is blank",
                "Account Name is blank. Please fill values first.",
                "error",
                "dismissable"
            );
            eventFlag = false;
            return;

        }

        if (eventFlag) {

            
            this.dispatchEvent(new CustomEvent(
                "success",
                {
                    "detail": true
                }
            ));

            this.dispatchEvent(new CustomEvent(
                "accountdetails",
                {
                    "detail": JSON.stringify(this.editaccountDetails)
                }
            ));

            this.dispatchEvent(new CustomEvent(
                "contactdetails",
                {
                    "detail": JSON.stringify(this.newContact)
                }
            ));

            this.dispatchEvent(new CustomEvent(
                "contactpersonsdetails",
                {
                    "detail": JSON.stringify(this.xeroContactPersons)
                }
            ));
            this.nextEnabled = true;
            this.showErrorToast(
                "Success",
                "Xero Contact values are saved. You can proceed further for Invoice Generation.",
                "success",
                "dismissable"
            );

        }

    }

    goBack () {

        this.disableNextButton();
        this.dispatchEvent(new CustomEvent(
            "backevent",
            {
                "detail": ""
            }
        ));

    }

}