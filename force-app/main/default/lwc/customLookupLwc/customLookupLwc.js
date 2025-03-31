import { LightningElement, api, track, wire } from 'lwc';

import getObjectList from '@salesforce/apex/InvoiceObjMappingController.getObjectList';
import getChildObjects from "@salesforce/apex/InvoiceObjMappingController.getChildObjects";

export default class CustomLookupLwc extends LightningElement {

    isLoading = true; 

    @track autoCompleteOptions = []; // filtered list of options based on search string
    @track objectsList = []; // complete list of objects returned by the apex method
    @track objectsMap = {}; // useful to get a map
    @track objectsListOfChild = [];
    @track objectsMapOfChild = {};

    @api selectedObjectAPIName = '';
    @api isObjectSelectionRO = false;
    @api isRequired = false;
    @api parentObject;
    @api parentObjectBill;
    @api fieldName;
    @api optionToHideInv;
    @api optionToHideBill;

    @api validate() {
        // to be called from parent LWC if for example the search box is present
        // on a form and needs to be validated before submission.
        this.template.querySelector('lightning-input').reportValidity();
    }

    /**
     * Getter and setters
     */
    get selectedObjectReference() {
        return this.objectsMap[this.selectedObjectAPIName]?.reference;
    }

    /**
     * Wired Methods
     */
    @wire(getObjectList, {})
    wiredObjectsList({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.objectsMap = JSON.parse(JSON.stringify(data)); // Deep copy of object
            this.objectsList = Object.values(this.objectsMap); // used for the auto-complete functionality
        }
        error && console.error("ExampleObjectSearch", "wiredObjectsList", error);
    }


    /**
     * Handlers
     */
    async handleInputChange(event) {
        this.selectedObjectAPIName = ''; // resets the selected object whenever the search box is changed
        const inputVal = event.target.value; // gets search input value
        console.log('inputVal-->', inputVal);
        console.log('this.fieldName-->',this.fieldName);

        if (inputVal) {
            if ((this.fieldName == 'field1' || this.fieldName == 'field2') && this.parentObject != undefined) {

                await getChildObjects({
                    objectApiName: this.parentObject
                })
                    .then((result) => {
                        console.log('Result- ' + JSON.stringify(result));
                        this.objectsMapOfChild = JSON.parse(JSON.stringify(result));
                        this.objectsListOfChild = Object.values(this.objectsMapOfChild);
                        //console.log('fields of +selectedObj+ '+result);
                    }).catch((error) => {
                        console.log(error);
                    })
                this.autoCompleteOptions = this.objectsListOfChild.filter(item => item.name !== this.optionToHideInv && item.reference.toLowerCase().includes(inputVal.toLowerCase()));
                // makes visible the combobox, expanding it.
                if (this.autoCompleteOptions.length && inputVal) {
                    this.template.querySelector('.slds-combobox.slds-dropdown-trigger.slds-dropdown-trigger_click')?.classList.add('slds-is-open');
                    this.template.querySelector('.slds-combobox.slds-dropdown-trigger.slds-dropdown-trigger_click')?.focus();
                }

            } else if((this.fieldName == 'field3' || this.fieldName == 'field4') && this.parentObjectBill != undefined){

                await getChildObjects({
                    objectApiName: this.parentObjectBill
                })
                    .then((result) => {
                        console.log('Result- ' + JSON.stringify(result));
                        this.objectsMapOfChild = JSON.parse(JSON.stringify(result));
                        this.objectsListOfChild = Object.values(this.objectsMapOfChild);
                        //console.log('fields of +selectedObj+ '+result);
                    }).catch((error) => {
                        console.log(error);
                    })
                    this.autoCompleteOptions = this.objectsListOfChild.filter(item => item.name !== this.optionToHideBill && item.reference.toLowerCase().includes(inputVal.toLowerCase()));

                // makes visible the combobox, expanding it.
                if (this.autoCompleteOptions.length && inputVal) {
                    this.template.querySelector('.slds-combobox.slds-dropdown-trigger.slds-dropdown-trigger_click')?.classList.add('slds-is-open');
                    this.template.querySelector('.slds-combobox.slds-dropdown-trigger.slds-dropdown-trigger_click')?.focus();
                }

            }else {
                // filters in real time the list received from the wired Apex method
                this.autoCompleteOptions = this.objectsList.filter(item => item.reference.toLowerCase().includes(inputVal.toLowerCase()));

                // makes visible the combobox, expanding it.
                if (this.autoCompleteOptions.length && inputVal) {
                    this.template.querySelector('.slds-combobox.slds-dropdown-trigger.slds-dropdown-trigger_click')?.classList.add('slds-is-open');
                    this.template.querySelector('.slds-combobox.slds-dropdown-trigger.slds-dropdown-trigger_click')?.focus();
                }
            }
        } else {
            const selectedEvent = new CustomEvent('objclear', { detail: '' });
            this.dispatchEvent(selectedEvent);
        }

    }

    handleOnBlur(event) {
        // Trickiest detail of this LWC.
        // the setTimeout is a workaround required to ensure the user click selects the record.
        setTimeout(() => {
            if (!this.selectedObjectAPIName) {
                this.template.querySelector('.slds-combobox.slds-dropdown-trigger.slds-dropdown-trigger_click')?.classList.remove('slds-is-open');
            }
        }, 300);
    }

    handleOptionClick(event) {
        // Stores the selected objected and hides the combobox
        this.selectedObjectAPIName = event.currentTarget?.dataset?.name;
        this.template.querySelector('.slds-combobox.slds-dropdown-trigger.slds-dropdown-trigger_click')?.classList.remove('slds-is-open');
        // throw custom event to be caught by parent LWC
        const selectedEvent = new CustomEvent('objectselected', { detail: this.selectedObjectAPIName });
        this.dispatchEvent(selectedEvent);
    }
}