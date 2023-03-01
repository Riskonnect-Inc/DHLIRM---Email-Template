import { LightningElement, api } from 'lwc';
import getRecordInfo from "@salesforce/apex/SearchableActivityController.getRecordInfo";

import { loadStyle } from 'lightning/platformResourceLoader';
import claimStylesOn from '@salesforce/resourceUrl/claimStylesOn';
import claimStylesOff from '@salesforce/resourceUrl/claimStylesOff';

export default class UtilityStyleHack extends LightningElement {
    @api
    get recordId() {
        return this._recordId;
    }

    objType;

    set recordId(value) {
        //console.log('Setting Record ID: ' + value);
        this._recordId = value;
        getRecordInfo({ recordId: value })
            .then((result) => {
                console.log('Result: ' + JSON.stringify(result));
                this.objType = result.objectType;
                loadStyle(this, result.emailTargetType || result.objectType === 'Claim__c' ? claimStylesOn : claimStylesOff);
            }).catch(error => {
                console.error('Error: ' + JSON.stringify(error));
                loadStyle(this, claimStylesOff);
            });
    }
}