import { LightningElement,api,track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';

import { loadStyle } from 'lightning/platformResourceLoader';
import customStyles from '@salesforce/resourceUrl/searchableActivity_styleHacks';

import findItems from "@salesforce/apex/SearchableActivityController.findItems";
import loadItems from "@salesforce/apex/SearchableActivityController.loadItems";
import filterLoadResult from "@salesforce/apex/SearchableActivityController.filterLoadResult";
import loadEmailDetails from "@salesforce/apex/SearchableActivityController.loadEmailDetails";
import getActivityDigest from "@salesforce/apex/SearchableActivityController.getActivityDigest";

class InterruptiblePoller {
    context;
    
    constructor(context, interval=5000, maxFires) {
        this.context = context;
        // Fire every 5 seconds (default value) after the last worker call completed:
        this.interval = interval;
        // How many times we've fired the worker call so far:
        this.fires = 0;
        this.maxFires = maxFires;

        this.working = false;
        this.workingFiresNext = false;
    }

    async start(whenLambo) {
        if (this.working) {
            this.workingFiresNext = true;
            return;
        }
        if (this.timeoutId) {
            window.clearTimeout(this.timeoutId);
        }
        if (typeof this.maxFires === "number" && this.fires >= this.maxFires) {
            this.stop();
            return;
        }
        this.timeoutId = window.setTimeout(async () => {
            try {
                this.working = true;
                await this.doWork();
            } finally {
                this.working = false;
                if (this.workingFiresNext) {
                    this.workingFiresNext = false;
                    this.start(0);
                }
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
        let newActivityDigest = await getActivityDigest({ claimId: this.context.recordId });
        if (newActivityDigest != this.context.activityDigest) {
            this.context.activityDigest = newActivityDigest;
            refreshApex(this.context.activitiesList);
        }
    }
}

let i = 0;
export default class SearchableActivityTimeline extends NavigationMixin(LightningElement) {

    @track showSearchResult = false; empty = false; empty1 = false; emptyList = false;
    @track showLoadResult = true;
    @track showFilterResult = false;
    @track dateRange; emailToShow;activitiesToShow; sortActivities; activityType; order = 'asc';
    @api recordId;
    actionList = [];
    searchValue;
    _allEmails;
    _received = [];
    _sent = [];
    items = [];
    upcomingOverdueItems = [];
    emails = [];
    tasks = [];
    upcomingOverdueTasks = [];
    items1 = [];
    upcomingOverdueItems1 = [];
    emails1 = [];
    tasks1 = [];
    upcomingOverdueTasks1 = [];
    items2 = [];
    emails2 = [];
    tasks2 = [];
    showSpinner2 = false;
    showSpinner1 = false;
    showSpinner = false;
    activitiesList;
    emailId;
    emailType;

    @track searchKeyword;
    //Radio button values
    dateRangeValue = '';
    activityGroupValue  = '';
    emailGroupValue = '';
    activitySortValue = '';
    activityTypeValue = '';

    poller;
    activityDigest;

    @wire(loadItems, {
        claimId: '$recordId'
    })
    wiredRecs(loadActivities) {
        this.showSpinner = true;
        this.activitiesList = loadActivities;
        const {error, data} = loadActivities;
        if (data) {
            this.activityDigest = data.activityDigest;
            this.emails = data.emailList;
            this.tasks = data.taskList;
            this.upcomingOverdueTasks = data.upcomingOverdueTaskList;
            let upcomingOverdueListObj = [];
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
                    canMark: this.emails[i].canMark,
                    isUnread: (this.emails[i].canMark && !this.emails[i].open) ? true : false,
                    datetimeValue: this.emails[i].datetimeValue,
                    href: '/lightning/r/'+this.emails[i].name+'/view',
                    iconName: 'standard:email',
                    closed: true,
                    icons: [
                        {
                            iconName: (this.emails[i].canMark && this.emails[i].open) ? 'utility:email_open' : 'utility:email',
                            alternativeText: (this.emails[i].canMark && this.emails[i].open) ? 'Mark as Unread' : 'Mark as Read'
                        }
                    ],
                    bounced: this.emails[i].bounced,
                    bouncedMessage: (this.emails[i].bounced) ? this.emails[i].bouncedMessage : '',
                    hasAttachment: this.emails[i].hasAttachment,
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
                    ],
                    buttons: [
                        {
                            buttonLabel: "Reply",
                            buttonName: "reply", 
                            iconName: "utility:reply"
                        },
                        {
                            buttonLabel: 'Reply All', 
                            buttonName: 'reply-all', 
                            iconName: 'utility:reply_all'
                        },
                        {
                            buttonLabel: "Forward", 
                            buttonName: "reply-all", 
                            iconName: "utility:forward"
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
                    upcoming: this.tasks[i].upcoming,
                    overdue: this.tasks[i].overdue,
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
            for(i = 0; i < this.upcomingOverdueTasks.length; i++) {
                let upcomingOverdueTaskObj = {
                    name: this.upcomingOverdueTasks[i].name,
                    title: this.upcomingOverdueTasks[i].title,
                    description: this.upcomingOverdueTasks[i].description,
                    datetimeValue: this.upcomingOverdueTasks[i].datetimeValue,
                    itemType: 'task',
                    upcoming: this.upcomingOverdueTasks[i].upcoming,
                    overdue: this.upcomingOverdueTasks[i].overdue,
                    href: '/lightning/r/'+this.upcomingOverdueTasks[i].name+'/view',
                    iconName: 'standard:task',
                    closed: true,
                    fields: [
                        {
                            label: 'Status',
                            value: this.upcomingOverdueTasks[i].status,
                            type: 'text',
                            typeAttributes: {
                                label: this.upcomingOverdueTasks[i].status
                            }
                        },
                        {
                            label: 'Priority',
                            value: this.upcomingOverdueTasks[i].priority,
                            type: 'text',
                            typeAttributes: {
                                label: this.upcomingOverdueTasks[i].priority
                            }
                        },
                        {
                            label: 'Assigned To',
                            value: '/lightning/r/'+this.upcomingOverdueTasks[i].assignedId+'/view',
                            type: 'url',
                            typeAttributes: {
                                label: this.upcomingOverdueTasks[i].assignedTo
                            }
                        },
                        {
                            label: 'Description',
                            value: this.upcomingOverdueTasks[i].description,
                            type: 'text'
                        }
                    ]
                };
                upcomingOverdueListObj.push(upcomingOverdueTaskObj);
            }
            this.items = emailListObj;
            this.upcomingOverdueItems = upcomingOverdueListObj;
            this.emptyList = (this.items.length == 0 && this.upcomingOverdueItems.length == 0) ?  true: false;
            this.showSpinner = false;
        } 
    }

    connectedCallback() {
        loadStyle(this, customStyles);
        this.poller = new InterruptiblePoller(this, 5000, 1000);
        this.poller.start();
    }

    getEmailAndTask(event){
		this.searchKeyword = event.target.value;
        if(this.searchKeyword.length == 0){
            this.showSearchResult = false;
            this.showLoadResult = true;
        }else{
            //console.log('Search Text: [' + this.searchKeyword + ']');
            findItems({ searchText: this.searchKeyword, recordId: this.recordId })
		.then(result => {
            this.showSpinner1 = true;
        //this.activitiesList = loadActivities;
        if (result.isSuccess) {
            //console.log('Results: ' + result.emailList.length + ' emails ' + result.taskList.length + ' tasks');
            this.showLoadResult = false;
            this.showSearchResult = true;
            this.emails1 = result.emailList;
            this.tasks1 = result.taskList;
            this.upcomingOverdueTasks1 = result.upcomingOverdueTaskList;
            let upcomingOverdueListObj1 = [];
            let emailListObj1 = [];
            this.actionList = [
                { label: "Link and Categorize Attachments", name: "link-attachments" }, 
                { label: "Delete", name: "delete-item" }
            ];
            for(i = 0; i< this.emails1.length; i++) { 
                let emailObj = 
                {
                    name: this.emails1[i].name,
                    title: this.emails1[i].title,
                    description: this.emails1[i].description,
                    received: this.emails1[i].received,
                    itemType: 'email',
                    datetimeValue: this.emails1[i].datetimeValue,
                    href: '/lightning/r/'+this.emails1[i].name+'/view',
                    iconName: 'standard:email',
                    closed: true,
                    canMark: this.emails1[i].canMark,
                    isUnread: (this.emails1[i].canMark && !this.emails1[i].open) ? true : false,
                    icons: [
                        {
                            iconName: (this.emails1[i].canMark && this.emails1[i].open) ? 'utility:email_open' : 'utility:email',
                            alternativeText: (this.emails1[i].canMark && this.emails1[i].open) ? 'Mark as Unread' : 'Mark as Read'
                        }
                    ],
                    bounced: this.emails1[i].bounced,
                    bouncedMessage: (this.emails1[i].bounced) ? this.emails1[i].bouncedMessage : '',
                    hasAttachment: this.emails1[i].hasAttachment,
                    fields: [
                        {
                            label: 'From Address',
                            value: this.emails1[i].fromAddress,
                            type: 'url',
                            typeAttributes: {
                                label: this.emails1[i].fromAddress
                            },           
                        },
                        {
                            label: 'To Address',
                            value: this.emails1[i].toAddress,
                            type: 'text',
                            typeAttributes: {
                                label: this.emails1[i].toAddress
                            }
                        },
                        {
                            label: 'Text Body',
                            value: this.emails1[i].textBody,
                            type: 'text'
                        }
                    ],
                    buttons: [
                        {
                            buttonLabel: "Reply",
                            buttonName: "reply", 
                            iconName: "utility:reply"
                        },
                        {
                            buttonLabel: 'Reply All', 
                            buttonName: 'reply-all', 
                            iconName: 'utility:reply_all'
                        },
                        {
                            buttonLabel: "Forward", 
                            buttonName: "reply-all", 
                            iconName: "utility:forward"
                        }
                    ]
                };
                emailListObj1.push(emailObj);
            }
            for(i = 0; i < this.tasks1.length; i++) {
                let taskObj = {
                    name: this.tasks1[i].name,
                    title: this.tasks1[i].title,
                    description: this.tasks1[i].description,
                    datetimeValue: this.tasks1[i].datetimeValue,
                    itemType: 'task',
                    href: '/lightning/r/'+this.tasks1[i].name+'/view',
                    iconName: 'standard:task',
                    closed: true,
                    upcoming: this.tasks1[i].upcoming,
                    overdue: this.tasks1[i].overdue,
                    fields: [
                        {
                            label: 'Status',
                            value: this.tasks1[i].status,
                            type: 'text',
                            typeAttributes: {
                                label: this.tasks1[i].status
                            }
                        },
                        {
                            label: 'Priority',
                            value: this.tasks1[i].priority,
                            type: 'text',
                            typeAttributes: {
                                label: this.tasks1[i].priority
                            }
                        },
                        {
                            label: 'Assigned To',
                            value: '/lightning/r/'+this.tasks1[i].assignedId+'/view',
                            type: 'url',
                            typeAttributes: {
                                label: this.tasks1[i].assignedTo
                            }
                        },
                        {
                            label: 'Description',
                            value: this.tasks1[i].description,
                            type: 'text'
                        }
                    ]
                };
                emailListObj1.push(taskObj);
            }
            for(i = 0; i < this.upcomingOverdueTasks1.length; i++) {
                let upcomingOverdueTaskObj = {
                    name: this.upcomingOverdueTasks1[i].name,
                    title: this.upcomingOverdueTasks1[i].title,
                    description: this.upcomingOverdueTasks1[i].description,
                    datetimeValue: this.upcomingOverdueTasks1[i].datetimeValue,
                    itemType: 'task',
                    upcoming: this.upcomingOverdueTasks1[i].upcoming,
                    overdue: this.upcomingOverdueTasks1[i].overdue,
                    href: '/lightning/r/'+this.upcomingOverdueTasks1[i].name+'/view',
                    iconName: 'standard:task',
                    closed: true,
                    fields: [
                        {
                            label: 'Status',
                            value: this.upcomingOverdueTasks1[i].status,
                            type: 'text',
                            typeAttributes: {
                                label: this.upcomingOverdueTasks1[i].status
                            }
                        },
                        {
                            label: 'Priority',
                            value: this.upcomingOverdueTasks1[i].priority,
                            type: 'text',
                            typeAttributes: {
                                label: this.upcomingOverdueTasks1[i].priority
                            }
                        },
                        {
                            label: 'Assigned To',
                            value: '/lightning/r/'+this.upcomingOverdueTasks1[i].assignedId+'/view',
                            type: 'url',
                            typeAttributes: {
                                label: this.upcomingOverdueTasks1[i].assignedTo
                            }
                        },
                        {
                            label: 'Description',
                            value: this.upcomingOverdueTasks1[i].description,
                            type: 'text'
                        }
                    ]
                };
                upcomingOverdueListObj1.push(upcomingOverdueTaskObj);
            }
            this.items1 = emailListObj1;
            this.upcomingOverdueItems1 = upcomingOverdueListObj1;
            this.empty = (this.items1.length == 0 && this.upcomingOverdueItems1.length == 0) ?  true: false;
            this.showSpinner1 = false;
        }
		})
		.catch(error => {
            //('Error: ' + JSON.stringify(error));
            this.showSearchResult = false;
            //debugger;
			this.error = error;
		})
        }
		
	} 

    timelineChange() {
        refreshApex(this.activitiesList);
    }

    timelineChangeFilter(){
        this.handleSuccess();
    }

    timelineChangeSearch(){

    
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
//        let pol = new InterruptiblePoller(5000, 10);
//        pol.start();
        // Schedule an "interrupt" fire in 6 seconds, regardless of where the poller currently stands (it will 
        // have fired once so far, and was ~ 1 second into the next 5-second wait). Note the next worker call 
        // after this interrupt call will resume exactly 5 seconds later - i.e. this very simple poller dynamically 
        // regulates itself!
//        setTimeout(() => { pol.fireNow() }, 6000);
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
//        let pol = new InterruptiblePoller(5000, 10);
//        pol.start();
        // Schedule an "interrupt" fire in 6 seconds, regardless of where the poller currently stands (it will 
        // have fired once so far, and was ~ 1 second into the next 5-second wait). Note the next worker call 
        // after this interrupt call will resume exactly 5 seconds later - i.e. this very simple poller dynamically 
        // regulates itself!
//        setTimeout(() => { pol.fireNow() }, 6000);
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
            { label: 'Read', value: 'read' }
        ];
    }
    get activityGroupOptions2() {
        return [
            { label: 'Unread', value: 'unread' },
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

    emailAction(event) {
        this.emailId = event.detail.name;
        this.emailType = event.detail.buttonName
        this.replyOrForwardEmail(this.emailId, this.emailType);
    }

    async replyOrForwardEmail(id, type) {
        let attachmentIds = [];
        try {
            const response = await loadEmailDetails({
                emailId : id,
                emailType : type
            });
            if(response.isSuccess) {
                let recId = response.emailList[0].Id;
                let toAddress = response.emailList[0].toAddress;
                let ccAddress = response.emailList[0].ccAddress;
                let bccAddress = response.emailList[0].bccAddress;
                let htmlBody = response.emailList[0].body;
                let subject = response.emailList[0].subject;
                attachmentIds.push(response.emailList[0].attachments);
                if(type == 'Forward') {
                    const replyOrForwardEvent = new CustomEvent('replyforwardevent', {
                        detail: { 
                            Id: recId,
                            toAddress: toAddress, 
                            ccAddress: ccAddress,
                            bccAddress: bccAddress,
                            htmlBody: htmlBody,
                            subject: subject,
                            attachmentIds: attachmentIds /*isSuccess: response.isSuccess, name: response.emailList[0].toAddress*/ 
                        },
                    });
                    this.dispatchEvent(replyOrForwardEvent);
                } else {
                    var pageRef = {
                        type: "standard__quickAction",
                        attributes: {
                            apiName: "Global.SendEmail"
                        },
                        state: {
                            recordId: this.recordId,
                            defaultFieldValues: 
                            encodeDefaultFieldValues({
                                ToAddress : response.emailList[0].toAddress,
                                CcAddress : response.emailList[0].ccAddress,
                                BccAddress : response.emailList[0].bccAddress,
                                HtmlBody : response.emailList[0].body, 
                                Subject : response.emailList[0].subject,
                                //ContentDocumentIds : '0697Z000002doqDQAQ'
                            }),
                        },
                    };
                    this[NavigationMixin.Navigate](pageRef);
//                    let pol = new InterruptiblePoller(5000, 10);
//                    pol.start();
                    // Schedule an "interrupt" fire in 6 seconds, regardless of where the poller currently stands (it will 
                    // have fired once so far, and was ~ 1 second into the next 5-second wait). Note the next worker call 
                    // after this interrupt call will resume exactly 5 seconds later - i.e. this very simple poller dynamically 
                    // regulates itself!
//                    setTimeout(() => { pol.fireNow() }, 6000);
                }
                
                //attachmentIds.push(response.emailList[0].attachments)
                /*console.log(JSON.parse(JSON.stringify(attachmentIds)));
                var pageRef = {
                    type: "standard__quickAction",
                    attributes: {
                        apiName: "Global.SendEmail"
                    },
                    state: {
                        recordId: this.recordId,
                        
                        defaultFieldValues: 
                        encodeDefaultFieldValues({
                            ToAddress : response.emailList[0].toAddress,
                            CcAddress : response.emailList[0].ccAddress,
                            BccAddress : response.emailList[0].bccAddress,
                            HtmlBody : response.emailList[0].body, 
                            Subject : response.emailList[0].subject,
                            //ContentDocumentIds : '0697Z000002doqDQAQ'
                        }),
                        
                    },
                };
                this[NavigationMixin.Navigate](pageRef);
                let pol = new InterruptiblePoller(5000, 10);
                pol.start();
                // Schedule an "interrupt" fire in 6 seconds, regardless of where the poller currently stands (it will 
                // have fired once so far, and was ~ 1 second into the next 5-second wait). Note the next worker call 
                // after this interrupt call will resume exactly 5 seconds later - i.e. this very simple poller dynamically 
                // regulates itself!
                setTimeout(() => { pol.fireNow() }, 6000);*/
            }
        } catch (e) {
            console.log(e);
        } finally {
            this.isLoading = false;
        }     
    }

    handleSuccess(){
        filterLoadResult({ recordId: this.recordId , dateRange: this.dateRange, emailsToShow: this.emailToShow, activitiesToShow: this.activitiesToShow, sortActivites: this.sortActivities})
		.then(result => {
            this.showSpinner1 = true;
        //this.activitiesList = loadActivities;
        if (result.isSuccess) {
            this.showLoadResult = false;
            this.showSearchResult = false;
            this.showFilterResult = true;
            this.emails2 = result.emailList;
            //this.tasks2 = result.taskList;
            let emailListObj2 = [];
            this.actionList = [
                { label: "Link and Categorize Attachments", name: "link-attachments" }, 
                { label: "Delete", name: "delete-item" }
            ];
            for(i = 0; i< this.emails2.length; i++) { 
                let emailObj = 
                {
                    name: this.emails2[i].name,
                    title: this.emails2[i].title,
                    description: this.emails2[i].description,
                    received: this.emails2[i].received,
                    itemType: 'email',
                    datetimeValue: this.emails2[i].datetimeValue,
                    href: '/lightning/r/'+this.emails2[i].name+'/view',
                    iconName: 'standard:email',
                    closed: true,
                    canMark: this.emails2[i].canMark,
                    isUnread: (this.emails2[i].canMark && !this.emails2[i].open) ? true : false,
                    icons: [
                        {
                            iconName: (this.emails2[i].canMark && this.emails2[i].open) ? 'utility:email_open' : 'utility:email',
                            alternativeText: (this.emails2[i].canMark && this.emails2[i].open) ? 'Mark as Unread' : 'Mark as Read'
                        }
                    ],
                    bounced: this.emails2[i].bounced,
                    bouncedMessage: (this.emails2[i].bounced) ? this.emails2[i].bouncedMessage : '',
                    hasAttachment: this.emails2[i].hasAttachment,
                    fields: [
                        {
                            label: 'From Address',
                            value: this.emails2[i].fromAddress,
                            type: 'url',
                            typeAttributes: {
                                label: this.emails2[i].fromAddress
                            },           
                        },
                        {
                            label: 'To Address',
                            value: this.emails2[i].toAddress,
                            type: 'text',
                            typeAttributes: {
                                label: this.emails2[i].toAddress
                            }
                        },
                        {
                            label: 'Text Body',
                            value: this.emails2[i].textBody,
                            type: 'text'
                        }
                    ],
                    buttons: [
                        {
                            buttonLabel: "Reply",
                            buttonName: "reply", 
                            iconName: "utility:reply"
                        },
                        {
                            buttonLabel: 'Reply All', 
                            buttonName: 'reply-all', 
                            iconName: 'utility:reply_all'
                        },
                        {
                            buttonLabel: "Forward", 
                            buttonName: "reply-all", 
                            iconName: "utility:forward"
                        }
                    ]
                };
                emailListObj2.push(emailObj);
            }
            /*for(i = 0; i < this.tasks2.length; i++) {
                let taskObj = {
                    name: this.tasks2[i].name,
                    title: this.tasks2[i].title,
                    description: this.tasks2[i].description,
                    datetimeValue: this.tasks2[i].datetimeValue,
                    itemType: 'task',
                    href: '/lightning/r/'+this.tasks2[i].name+'/view',
                    iconName: 'standard:task',
                    closed: true,
                    upcoming: this.tasks2[i].upcoming,
                    overdue: this.tasks2[i].overdue,
                    fields: [
                        {
                            label: 'Status',
                            value: this.tasks2[i].status,
                            type: 'text',
                            typeAttributes: {
                                label: this.tasks2[i].status
                            }
                        },
                        {
                            label: 'Priority',
                            value: this.tasks2[i].priority,
                            type: 'text',
                            typeAttributes: {
                                label: this.tasks2[i].priority
                            }
                        },
                        {
                            label: 'Assigned To',
                            value: '/lightning/r/'+this.tasks2[i].assignedId+'/view',
                            type: 'url',
                            typeAttributes: {
                                label: this.tasks2[i].assignedTo
                            }
                        },
                        {
                            label: 'Description',
                            value: this.tasks2[i].description,
                            type: 'text'
                        }
                    ]
                };
                emailListObj2.push(taskObj);
            }*/
            this.items2 = emailListObj2;
            this.empty1 = this.items2.length == 0 ?  true: false;
            this.showSpinner1 = false;
        }
		})
		.catch(error => {
            this.showSearchResult = false;
            //debugger;
			this.error = error;
		})
        
    }

    handleRestoreDefault(){
        this.dateRangeValue = undefined;
        this.emailGroupValue = undefined;
        this.activityGroupValue = undefined;
        this.activitySortValue = undefined;
        this.showLoadResult = true;
        this.showFilterResult = false;
        this.showSearchResult = false;
        //debugger;
    }
    handleDateChange(event){
        var dateRange1 = event.target.value;
        this.dateRange = dateRange1;
    }
    //@track dateRange; emailToShow;activitiesToShow; sortActivities; activityType;
    handleEmailChange(event){
        var emailChange1 = event.target.value;
        this.emailToShow = emailChange1;
    }
    handleActivityChange(event){
        var activityChange1 = event.target.value;
        this.activitiesToShow = activityChange1;
    }
    handleSortActivityChange(event){
        var sortActivityChange1 = event.target.value;
        this.sortActivities = sortActivityChange1;
    }
    handleActivityTypeChange(event){
        var activityType1 = event.target.value;
        this.activityType = activityType1;
    }
}