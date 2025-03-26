import {LightningElement, api, track} from "lwc";

export default class CircularProgressIndicator extends LightningElement {

    @api percent;

    @api content;

    @track fillpercent;

    @track isLong;

    @track arcX;

    @track arcY;

    @track svgURL = "";

    connectedCallback () {

        const arcX = 0,
            arcY = 0,
            isLong = 0;
        this.isLong = isLong;
        this.arcX = arcX;
        this.arcY = arcY;
        this.calculateProgress();

    }

    calculateProgress () {

        const {percent} = this,
            arcXVal = 2,
            arcYVal = 2,
            test1 = 0.5,
            test2 = 1,
            test3 = 0;

        if (typeof percent === "string") {

            this.fillpercent = parseInt(
                percent,
                10
            );

        } else {

            this.fillpercent = percent;

        }
        if (this.fillpercent > test1) {

            this.isLong = test2;

        } else {

            this.isLong = test3;

        }

        this.arcX = Math.cos(arcXVal * Math.PI * this.fillpercent);
        this.arcY = Math.sin(arcYVal * Math.PI * this.fillpercent);
        this.svgURL = `M 1 0 A 1 1 0 ${this.isLong} 1 ${this.arcX} ${this.arcY} L 0 0`;

    }
}