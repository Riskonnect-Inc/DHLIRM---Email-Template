import { LightningElement,api,track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';

//import { loadStyle } from 'lightning/platformResourceLoader';
//import customStyles from '@salesforce/resourceUrl/searchableActivity_styleHacks';

//import findItems from "@salesforce/apex/SearchableActivityController.findItems";
import loadItems from "@salesforce/apex/SearchableActivityController.loadItems";
import filterLoadResult from "@salesforce/apex/SearchableActivityController.filterLoadResult";
import loadEmailDetails from "@salesforce/apex/SearchableActivityController.loadEmailDetails";
import getActivityDigest from "@salesforce/apex/SearchableActivityController.getActivityDigest";
//import { containsScrollingElement } from '../positionLibrary/util';

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
    @track showSearchResult = false; empty = false; empty1 = false; emptyList = false; isLinked = false; isFilterOpen = false; emptyUpcomingList = false;
    @track showLoadResult = true;
    @track showFilterResult = false;
    @track dateRange = ''; emailsToShow = '';activitiesToShow = ''; sortActivities = ''; activityType = ''; order = 'desc'; maxItems = '3';
    @track loadType = 'load'; //There are 3 types: Load, Search and Filter. By default it is load
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
    upcomingOverdueItems2 = [];
    emails2 = [];
    tasks2 = [];
    upcomingOverdueTasks2 = [];
    showSpinner2 = false;
    showSpinner1 = false;
    showSpinner = false;
    activitiesList;
    emailId;
    emailType;

    @track isEmailChecked = true;
    @track isTaskChecked = true;
    @track isCheckboxEmpty = false;
    @track isApplyDisabled = false
    filters = false;
    buttonClick = false;
    @track showActivityButton = false;
    @track toggle;

    @track searchKeyword = '';
    //Radio button values
    dateRangeValue = 'allTime';
    activityGroupValue  = '';
    emailGroupValue = '';
    activitySortValue = '';
    activityTypeValue = ['emails', 'tasks'];

    poller;
    activityDigest;

    loadError;
    loadErrorMessage;
    hasActivitiesData;

    filtersDigest;
    get hasFiltersDigest() {
        return !!this.filtersDigest;
    }

    get notEmptyList() {
        return !this.emptyList;
    }

    get noUpcomingOrOverdue() {
        return this.emptyUpcomingList;
    }

    //Raghil: A huge testing workaround to see if we can use 1 wire method for Load, Search and Filter
    @wire(loadItems, {
        claimId: '$recordId',
        type: '$loadType',
        searchText: '$searchKeyword',
        dateRange: '$dateRange', 
        emailsToShow: '$emailsToShow', 
        emailStatus: '$activitiesToShow', 
        sortActivites: '$sortActivities',
        isEmailChecked: '$isEmailChecked',
        isTaskChecked: '$isTaskChecked'
    })
    wiredRecs(loadActivities) {
        this.showSpinner = true;
        this.activitiesList = loadActivities;
        const {error, data} = loadActivities;
        if (error) {
            //console.log('Error:');
            //console.log(error);
            this.items = [];
            this.upcomingOverdueItems = [];
            this.loadError = true;
            this.loadErrorMessage = 'Unexpected error while loading activities: ' + error.body.message;
            this.emptyList = false;
            this.emptyUpcomingList = false;
            this.showSpinner = false;
            this.hasActivitiesData = false;
            this.filtersDigest = null;
        } else if (data) {
            this.filtersDigest = data.filtersDigest;
            if (data.searchTextError != null) {
                //console.log('Search error: ' + data.searchTextError);
                this.loadError = true;
                this.loadErrorMessage = data.searchTextError;
            } else {
                //console.log('No search error');
                this.loadError = false;
                this.loadErrorMessage = null;
            }            
            this.activityDigest = data.activityDigest;
            this.emails = data.emailList;
            this.tasks = data.taskList;
            this.upcomingOverdueTasks = data.upcomingOverdueTaskList;
            let upcomingOverdueListObj = [];
            let emailListObj = [];
            this.actionList = [
                { label: "Delete", name: "delete-item" },
                { label: "Link and Categorize Attachments", name: "link-attachments" },              
            ];
            if(this.emails != null || this.emails != undefined) {
                for(i = 0; i< this.emails.length; i++) {  
                    //console.log(this.emails[i].title, this.emails[i].datetimeValue);
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
            }
            
            if(this.tasks != null || this.tasks != undefined) {
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
            }
            
            if(this.upcomingOverdueTasks != null || this.upcomingOverdueTasks != undefined) {
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
            }
            
            this.items = emailListObj;
            this.upcomingOverdueItems = upcomingOverdueListObj;
            this.emptyList = (this.items.length == 0 && this.upcomingOverdueItems.length == 0) ?  true: false;
            this.emptyUpcomingList = (this.upcomingOverdueItems.length == 0) ? true : false;
            this.hasActivitiesData = !this.emptyList;
            this.showSpinner = false;
        } 
    }

    connectedCallback() {
        //if(!this.filters) {
        //    this.resetFilterValues();
        //} 
        if (typeof this.toggle === 'undefined') this.toggle = true;
        this.filters = {};
        this.resetFilterValues();
        this.poller = new InterruptiblePoller(this, 5000, 1000);
        this.poller.start();
    }

    getEmailAndTask(event){
		this.searchKeyword = event.target.value;
        // MDU: DON'T reset the filter values:
        //this.resetFilterValues();
        this.loadType = 'Search';
        //this.activityTypeValue = ['emails', 'tasks'];
        if(this.searchKeyword.length == 0){
            this.loadType = 'Load';
        }
        refreshApex(this.activitiesList);
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
            { label: 'Next 7 days', value: 'nextSeven' },
            { label: 'Last 30 days', value: 'lastThirty' },
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
            { label: 'All Statuses', value: 'all' },
            { label: 'Read', value: 'read' },
            { label: 'Unread', value: 'unread' }
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
            { label: 'Received Emails', value: 'receivedEmails' },
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
            { label: 'Newest dates first', value: 'newDate' },
        ]
    }
    get activitySortOptions2() {
        return [
            { label: 'Newest dates first', value: 'newDate' },
        ]
    }
    get activityTypeOptions1() {
        return [
            /*{ label: 'All Types', value: 'allTypes' }
            { label: 'List Email', value: 'listEmail' },*/
            { label: 'Emails', value: 'emails' },
        ]
    }
    get activityTypeOptions2() {
        return [
            /*{ label: 'Logged Calls', value: 'loggedCalls' },
            { label: 'Events', value: 'events' },*/
            { label: 'Tasks', value: 'tasks' }
        ]
    }

    emailAction(event) {
        this.emailId = event.detail.name;
        this.emailType = event.detail.buttonName;
        this.replyOrForwardEmail(this.emailId, this.emailType);
    }

    attachLinkAction(event) {
        this.isLinked = true;
        this.emailId = event.detail.name;
    }

    get inputVariables() {
        return [
            {
                name: 'debuggingOnly_RecordId',
                type: 'String',
                value: this.emailId
            }
        ];
    }

    async replyOrForwardEmail(id, type) {
        let attachmentIds = [];
        try {
            const response = await loadEmailDetails({
                emailId : id,
                emailType : type,
                browserTimeZone: Intl && Intl.DateTimeFormat && Intl.DateTimeFormat().resolvedOptions().timeZone
            });
            //console.log(Intl && Intl.DateTimeFormat && Intl.DateTimeFormat().resolvedOptions().timeZone);
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
                    const replyOrForwardEvent = new CustomEvent('replyforwardevent', {
                        detail: { 
                            Id: recId,
                            toAddress: toAddress, 
                            ccAddress: ccAddress,
                            bccAddress: bccAddress,
                            htmlBody: htmlBody,
                            subject: subject,
                            //attachmentIds: attachmentIds /*isSuccess: response.isSuccess, name: response.emailList[0].toAddress*/ 
                        },
                    });
                    this.dispatchEvent(replyOrForwardEvent);
                }
            }
        } catch (e) {
            console.log(e);
        } finally {
            this.isLoading = false;
        }     
    }

    handleSuccess() {
        this.loadType = 'Filter';
        this.assignFilterValues();
        this.order = (this.sortActivities == 'oldDate') ? 'asc' : 'desc';
        // MDU: Hack to close the filter pop-up when "Apply" is clicked:
        let filterElmt = this.template.querySelector('div[data-id="filterSettings"] lightning-button-menu');
        window.setTimeout(function() {
            filterElmt.click();
            //filterElmt && filterElmt.classList.remove('slds-is-open');
        }, 0);

        //console.log(this.sortActivities)
        if(!this.filters['isTaskChecked'] && !this.filters['isEmailChecked']) {
            this.isCheckboxEmpty = true;
        } else {
            this.isCheckboxEmpty = false;
            refreshApex(this.activitiesList);
            //console.log('Clover: Dispatching Event');
            //document.querySelector('div').click();
            //this.dispatchEvent(new Event('mouseleave'));
            //console.log('Ending Event');
            //console.log(document.querySelector('div'));
            //console.log(this.template);
            //console.log(this.template.querySelector('div[clover-customs="clover"]'));
        }      
    }

    handleRestoreDefault(){
        this.resetFilterValues();
        this.showLoadResult = true;
        this.isCheckboxEmpty = false;
        this.isApplyDisabled = false;
        this.loadType = 'Filter';
        this.order = 'desc';
        this.activityTypeValue = ['emails', 'tasks'];
        refreshApex(this.activitiesList);
    }
    handleDateChange(event){
        var dateRange1 = event.target.value;
        this.filters['dateRange'] = dateRange1;
        this.syncFilter();
        //console.log(this.filters);
    }
    //@track dateRange; emailToShow;activitiesToShow; sortActivities; activityType;
    handleEmailChange(event){
        var emailChange1 = event.target.value;
        this.filters['emailsToShow'] = emailChange1;
        this.syncFilter();
        //console.log(this.filters);
    }
    handleActivityChange(event){
        var activityChange1 = event.target.value;
        this.filters['activitiesToShow'] = activityChange1;
        this.syncFilter();
        //console.log(this.filters);
    }
    handleSortActivityChange(event){
        var sortActivityChange1 = event.target.value;
        this.filters['sortActivities'] = sortActivityChange1;
        this.syncFilter();
        //console.log(this.filters);
    }
    handleActivityTypeChange1(event){
        var activityType1 = event.detail.value;
        if(activityType1 == 'emails') {
            this.filters['isEmailChecked'] = true;
        } else {
            this.filters['isEmailChecked'] = false;
        }
        if(!this.filters['isEmailChecked'] && !this.filters['isTaskChecked']) {
            this.isCheckboxEmpty = true;
            this.isApplyDisabled = true;
        } else {
            this.isCheckboxEmpty = false;
            this.isApplyDisabled = false;
        }
    }
    handleActivityTypeChange2(event){
        var activityType2 = event.detail.value;
        if(activityType2 == 'tasks') {
            this.filters['isTaskChecked'] = true;
        } else {
            this.filters['isTaskChecked'] = false;
        }
        if(!this.filters['isEmailChecked'] && !this.filters['isTaskChecked']) {
            this.isCheckboxEmpty = true;
            this.isApplyDisabled = true;
        } else {
            this.isCheckboxEmpty = false;
            this.isApplyDisabled = false;
        }
    }
    //Clover Willis - RKDEV-44215 - Override mouseleave event
    handleFilterMouseLeave(event){
        event.stopPropagation();
    }
    handleUnbindMouseLeave(event){
        //console.log('Clover test');
        let domElement2 = this.template.querySelector('#clovercustoms');
        //console.log(domElement2);
        //console.log(this.template);
    }
    //END RKDEV-44215

    closeModal() {
        this.isLinked = false;
    }

    syncFilter() {
        this.dateRangeValue = this.filters['dateRange'];
        this.emailGroupValue = this.filters['emailsToShow'];
        this.activityGroupValue = this.filters['activitiesToShow'];
        this.activitySortValue = this.filters['sortActivities'];
        this.isEmailChecked = this.filters['isEmailChecked'];
        this.isTaskChecked = this.filters['isTaskChecked'];
    }

    assignFilterValues() {
        this.toggle = true;
        this.dateRange = this.dateRangeValue = this.filters['dateRange'];
        this.emailsToShow = this.emailGroupValue = this.filters['emailsToShow'];
        this.activitiesToShow = this.activityGroupValue = this.filters['activitiesToShow'];
        this.sortActivities = this.activitySortValue = this.filters['sortActivities'];
        this.isEmailChecked = this.filters['isEmailChecked'];
        this.isTaskChecked = this.filters['isTaskChecked'];
        if(this.dateRange == 'allTime' && this.emailsToShow == 'allEmails' && this.activitiesToShow == 'all' && this.sortActivities == 'newDate' && this.isEmailChecked && this.isTaskChecked) {
            this.showActivityButton = false;
        } else {
            this.showActivityButton = true;
        }
    }

    resetFilterValues() {
        this.toggle = true;
        let filterUpdate = !!this.filters
        this.filters = {
            dateRange: 'allTime',
            emailsToShow: 'allEmails', //'',
            activitiesToShow: 'all', //'',
            sortActivities: 'newDate', //'',
            isEmailChecked: true,
            isTaskChecked: true
        };
        this.showActivityButton = false;
        if(filterUpdate) {
            this.assignFilterValues();
        }
    }

    get sectionClass() {
        return this.toggle ? 'slds-section slds-is-open' : 'slds-section';
    }

    toggleIcon() {
        this.toggle = !this.toggle;
    }
}