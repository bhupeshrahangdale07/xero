import {LightningElement, track} from "lwc";

export default class InvoiceConfigCmp extends LightningElement {

    @track activeTab = "invConfig";

    tabSet = {
        "invConfig": true,
        "objMapping": false,
        "objMapping2": false
    };

    handleActive (event) {

        const tabName = event.target.value;
        if (tabName === "invConfig") {

            this.tabSet = {};
            this.tabSet.invConfig = true;
            this.tabSet.objMapping = false;

        } else if (tabName === "objMapping") {

            this.tabSet = {};
            this.tabSet.invConfig = false;
            this.tabSet.objMapping = true;

        } else if (tabName === "objMapping2") {

            this.tabSet = {};
            this.tabSet.invConfig = false;
            this.tabSet.objMapping = false;
            this.tabSet.objMapping2 = true;

        }

    }

}