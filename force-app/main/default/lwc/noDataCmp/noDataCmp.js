import {LightningElement, api, track} from "lwc";
export default class NoDataCmp extends LightningElement {

    @api info;
    @track isNodata;
    connectedCallback(){
        if(this.info === 'No data found'){
            this.isNodata = true;
        }else{
            this.isNodata = false;
        }
    }

}