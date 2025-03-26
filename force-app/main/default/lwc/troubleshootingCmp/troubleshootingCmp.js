import {LightningElement, track} from "lwc";

export default class TroubleshootingCmp extends LightningElement {

    @track activeTab = "connection";

    tabSet = {
        "connectionTab": true,
        "logTab": false
    };

    handleActive (event) {

        const tabName = event.target.value;
        if (tabName === "connection") {

            this.tabSet = {};
            this.tabSet.connectionTab = true;

        } else if (tabName === "log") {

            this.tabSet = {};
            this.tabSet.connectionTab = false;
            this.tabSet.logTab = true;

        }

    }

}