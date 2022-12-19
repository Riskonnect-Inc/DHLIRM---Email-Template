import { LightningElement,api,track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';

//import findItems from "@salesforce/apex/SearchableActivityController.findItems";
import loadItems from "@salesforce/apex/SearchableActivityController.loadItems";

class InterruptiblePoller {
    constructor(interval=5000, maxFires) {
        // Fire every 5 seconds (default value) after the last worker call completed:
        this.interval = interval;
        // How many times we've fired the worker call so far:
        this.fires = 0;
        this.maxFires = maxFires;
    }

    async start(whenLambo) {
        if (this.timeoutId) {
            window.clearTimeout(this.timeoutId);
        } else {
        }
        if (typeof this.maxFires === "number" && this.fires >= this.maxFires) {
            this.stop();
            return;
        }
        this.timeoutId = window.setTimeout(async () => {
            try {
                await this.doWork();
            } finally {
                this.fires++;
                this.start();
            }
        }, typeof whenLambo === "number" ? whenLambo : this.interval);
        return;
    }

    stop() {
        window.clearTimeout(this.timeoutId);
    }

    // Call this method directly to "interrupt" the poller with an immediate worker call. It will seamlessly 
    // resume the usual polling interval afterwards. You can call this method whenever and as often as you 
    // like!
    fireNow() {
        this.start(0);
    }

    // Do the thing!
    // This simple method is just for demonstration. It doesn't need to be declared async just for a simple 
    // console.log call, but in practice we will usually be doing an asynchronous server-side callout here
    // (e.g. query for new emails or tasks). The "Got lambo" is a joke referencing the "when lambo?" meme 
    // used to make fun of crypto bros ;)
    async doWork() {
    }
}

let i = 0;
export default class SearchableActivityTimeline extends NavigationMixin(LightningElement) {
    @api recordId;
    actionList = [];
    searchValue;
    _allEmails;
    _received = [];
    _sent = [];
    items = [];
    emails = [];
    tasks = [];
    showSpinner = false;
    activitiesList;

    //Radio button values
    dateRangeValue = '';
    activityGroupValue  = '';
    emailGroupValue = '';
    activitySortValue = '';
    activityTypeValue = '';

    @wire(loadItems, {
        claimId: '$recordId'
    })
    wiredRecs(loadActivities) {
        this.showSpinner = true;
        this.activitiesList = loadActivities;
        const {error, data} = loadActivities;
        if (data) {
            this.emails = data.emailList;
            this.tasks = data.taskList;
            let emailListObj = [];
            this.actionList = [
                { label: "Link and Categorize Attachments", name: "link-attachments" }, 
                { label: "Delete", name: "delete-item" }
            ];
            for(i = 0; i< this.emails.length; i++) {  
                let emailObj = 
                {
                    name: this.emails[i].name,
                    title: this.emails[i].title,
                    description: this.emails[i].description,
                    received: this.emails[i].received,
                    itemType: 'email',
                    datetimeValue: this.emails[i].datetimeValue,
                    href: '/lightning/r/'+this.emails[i].name+'/view',
                    iconName: 'standard:email',
                    closed: true,
                    //icons: ['utility:refresh'],
                    fields: [
                        {
                            label: 'From Address',
                            value: this.emails[i].fromAddress,
                            type: 'url',
                            typeAttributes: {
                                label: this.emails[i].fromAddress
                            },           
                        },
                        {
                            label: 'To Address',
                            value: this.emails[i].toAddress,
                            type: 'text',
                            typeAttributes: {
                                label: this.emails[i].toAddress
                            }
                        },
                        {
                            label: 'Text Body',
                            value: this.emails[i].textBody,
                            type: 'text'
                        }
                    ]
                };
                emailListObj.push(emailObj);
            }
            for(i = 0; i < this.tasks.length; i++) {
                let taskObj = {
                    name: this.tasks[i].name,
                    title: this.tasks[i].title,
                    description: this.tasks[i].description,
                    datetimeValue: this.tasks[i].datetimeValue,
                    itemType: 'task',
                    href: '/lightning/r/'+this.tasks[i].name+'/view',
                    iconName: 'standard:task',
                    closed: true,
                    fields: [
                        {
                            label: 'Status',
                            value: this.tasks[i].status,
                            type: 'text',
                            typeAttributes: {
                                label: this.tasks[i].status
                            }
                        },
                        {
                            label: 'Priority',
                            value: this.tasks[i].priority,
                            type: 'text',
                            typeAttributes: {
                                label: this.tasks[i].priority
                            }
                        },
                        {
                            label: 'Assigned To',
                            value: '/lightning/r/'+this.tasks[i].assignedId+'/view',
                            type: 'url',
                            typeAttributes: {
                                label: this.tasks[i].assignedTo
                            }
                        },
                        {
                            label: 'Description',
                            value: this.tasks[i].description,
                            type: 'text'
                        }
                    ]
                };
                emailListObj.push(taskObj);
            }
            this.items = emailListObj;
            this.showSpinner = false;
        } 
    } 

    timelineChange() {
        refreshApex(this.activitiesList);
    }

    newEmail() {
        var pageRef = {
            type: "standard__quickAction",
            attributes: {
                apiName: "Global.SendEmail"
            },
            state: {
                recordId: this.recordId,
                defaultFieldValues:
                encodeDefaultFieldValues({
                    HtmlBody : "", 
                    Subject : ""
                })
            },
        };
        this[NavigationMixin.Navigate](pageRef);
        // Start a new interruptable poller with an interval of 5 seconds and a max of 10 worker call fires:
        let pol = new InterruptiblePoller(5000, 10);
        pol.start();
        // Schedule an "interrupt" fire in 6 seconds, regardless of where the poller currently stands (it will 
        // have fired once so far, and was ~ 1 second into the next 5-second wait). Note the next worker call 
        // after this interrupt call will resume exactly 5 seconds later - i.e. this very simple poller dynamically 
        // regulates itself!
        setTimeout(() => { pol.fireNow() }, 6000);
        /*let emailCount = this.activitiesList.data.emailList.length;
        let intervalComponent1 = setInterval(() => {
            console.log(emailCount);
            console.log(this.activitiesList.data.emailList.length); 
            refreshApex(this.activitiesList);
            if(emailCount != this.activitiesList.data.emailList.length) {
                clearInterval(intervalComponent1);
            }                   
        }, 5000);*/
    }

    newTask() {
        var pageRef = {
            type: "standard__objectPage",
            attributes: {
                objectApiName: "Task",
                actionName: "new"
            },
            state: {
                recordId: this.recordId,
                defaultFieldValues:
                encodeDefaultFieldValues({
                    WhatId : this.recordId,
                    Status : 'Not Started'
                })
            }
        };
        this[NavigationMixin.Navigate](pageRef);
        // Start a new interruptable poller with an interval of 5 seconds and a max of 10 worker call fires:
        let pol = new InterruptiblePoller(5000, 10);
        pol.start();
        // Schedule an "interrupt" fire in 6 seconds, regardless of where the poller currently stands (it will 
        // have fired once so far, and was ~ 1 second into the next 5-second wait). Note the next worker call 
        // after this interrupt call will resume exactly 5 seconds later - i.e. this very simple poller dynamically 
        // regulates itself!
        setTimeout(() => { pol.fireNow() }, 6000);
        /*let taskCount = this.activitiesList.data.taskList.length;
        let intervalComponent2 = setInterval(() => {
            console.log(taskCount);
            console.log(this.activitiesList.data.taskList.length); 
            refreshApex(this.activitiesList);
            if(taskCount != this.activitiesList.data.taskList.length) {
                clearInterval(intervalComponent2);
            }      
        }, 5000);*/
        /*setTimeout(() => {
            console.log('Timeout');
            clearInterval(intervalComponent2);
        }, 120000);*/
    }

    //Radio buttons options
    get dateRangeOptions1() {
        return [
            { label: 'All Time', value: 'allTime' },
            { label: 'Last 7 days', value: 'lastSeven' },
        ];
    }

    get dateRangeOptions2() {
        return [
            { label: 'Next 7 days', value: 'nextSeven' },
            { label: 'Last 30 days', value: 'lastThirty' },
        ];
    }

    get activityGroupOptions1() {
        return [
            { label: 'All Activities', value: 'allActivities' },
            { label: 'My Activities', value: 'myActivities' },
        ];
    }
    get activityGroupOptions2() {
        return [
            { label: 'My Activities', value: 'myActivities' },
        ];
    }

    get emailGroupOptions1() {
        return [
            { label: 'All Emails', value: 'allEmails' },
            { label: 'Sent Emails', value: 'sentEmails' },
        ];
    }
    get emailGroupOptions2() {
        return [
            { label: 'Received Emails', value: 'receivedEmails' },
        ];
    }
    get activitySortOptions1() {
        return [
            { label: 'Oldest dates first', value: 'oldDate' },
        ]
    }
    get activitySortOptions2() {
        return [
            { label: 'Newest dates first', value: 'newDate' },
        ]
    }
    get activityTypeOptions1() {
        return [
            { label: 'All Types', value: 'allTypes' },
            { label: 'List Email', value: 'listEmail' },
            { label: 'Email', value: 'emails' },
        ]
    }
    get activityTypeOptions2() {
        return [
            { label: 'Logged Calls', value: 'loggedCalls' },
            { label: 'Events', value: 'events' },
            { label: 'Tasks', value: 'tasks' },
        ]
    }
}