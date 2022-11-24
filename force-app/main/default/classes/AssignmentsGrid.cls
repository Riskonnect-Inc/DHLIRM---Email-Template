public with sharing class AssignmentsGrid {


    public Object patientEventCurrentData {get; private set;}
    public Object patientFeedbackCurrentData {get; private set;}
    public Object physicianReviewCurrentData {get; private set;}
    
    public Object patientEventHistoricData {get; private set;}
    public Object patientFeedbackHistoricData {get; private set;}
    public Object physicianReviewHistoricData {get; private set;}
    
    private String userId {get; set;}
    private Boolean links {get; set;}

    public AssignmentsGrid (rkl.JS_Search ignore) {

    }

    public PageReference pageLoad(){

        

        //Set email key but check the login type first
        if (UserInfo.getUserType() == 'Standard' && String.isNotBlank(UserInfo.getSessionId()) && String.isNotBlank(UserInfo.getUserId())) {
            this.userId = UserInfo.getUserId();
            this.links = false;
            //this.showLogout = false;
        } 
        //else {  //Change this if different object is used for user login
        //  List<Contact> contacts = [SELECT Email FROM Contact WHERE Id=:this.security.personId];
        //  if(contacts.size()==1) {
        //        this.emailAddress = contacts[0].Email;
        //    }
        //  this.links = false;
        //  this.showLogout = true;
        //}

        this.init();

        return null;

    }

    private void init() {
        patientEventCurrentData = JSON.serialize(
            rkl.RKSearch.consumeConfig (new Map<String, Object>{
                'resultFields' => 'AssignmentResults',
                //'searchFields' => 'AssignmentSearch',
                'title' => 'To Do List&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(Clicking the Column Headers will sort the data)',
                'type' => 'unRelatedList',
                'objectApi' => 'Review__c',
                'links' => this.links,
                'relOptions' => new Map<String,Object>{'del' => false, 'add' => false, 'edit' => true},
                'baseCondition' => 'assigned_reviewer__c  = "' + this.userId + '" && (status__c = "New" || status__c = "In Progress")'
            })
        );

        patientFeedbackCurrentData = JSON.serialize(
            rkl.RKSearch.consumeConfig (new Map<String, Object>{
                'resultFields' => 'AssignmentResults',
                //'searchFields' => 'AssignmentSearch',
                'title' => 'To Do List&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(Clicking the Column Headers will sort the data)',
                'type' => 'unRelatedList',
                'objectApi' => 'Patient_Feedback_Review__c',
                'links' => this.links,
                'relOptions' => new Map<String,Object>{'del' => false, 'add' => false, 'edit' => true},
                'baseCondition' => 'assigned_reviewer__c  = "' + this.userId + '" && (status__c = "New" || status__c = "In Progress")'
            })
        );

        physicianReviewCurrentData = JSON.serialize(
            rkl.RKSearch.consumeConfig (new Map<String, Object>{
                'resultFields' => 'AssignmentResults',
                //'searchFields' => 'AssignmentSearch',
                'title' => 'To Do List&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(Clicking the Column Headers will sort the data)',
                'type' => 'unRelatedList',
                'objectApi' => 'Physician_Review__c',
                'links' => this.links,
                'relOptions' => new Map<String,Object>{'del' => false, 'add' => false, 'edit' => true},
                'baseCondition' => 'assigned_reviewer__c  = "' + this.userId + '" && (status__c = "New" || status__c = "In Progress")'
            })
        );

        patientEventHistoricData = JSON.serialize(
            rkl.RKSearch.consumeConfig (new Map<String, Object>{
                'resultFields' => 'AssignmentResults',
                'searchFields' => 'AssignmentSearch',
                'title' => 'Historic Reviews', //&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(Click on the "up-arrow/filter" icon directly below this text for search filters.)',
                'type' => 'unRelatedList',
                'objectApi' => 'Review__c',
                'links' => this.links,
                'relOptions' => new Map<String,Object>{'del' => false, 'add' => false, 'edit' => true},
                'baseCondition' => 'assigned_reviewer__c  = "' + this.userId + '" && (status__c != "New" && status__c != "In Progress")',
                'filtersOpen' => true
            })
        );

        patientFeedbackHistoricData = JSON.serialize(
            rkl.RKSearch.consumeConfig (new Map<String, Object>{
                'resultFields' => 'AssignmentResults',
                'searchFields' => 'AssignmentSearch',
                'title' => 'Historic Reviews', //&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(Click on the "up-arrow/filter" icon directly below this text for search filters.)',
                'type' => 'unRelatedList',
                'objectApi' => 'Patient_Feedback_Review__c',
                'links' => this.links,
                'relOptions' => new Map<String,Object>{'del' => false, 'add' => false, 'edit' => true},
                'baseCondition' => 'assigned_reviewer__c  = "' + this.userId + '" && (status__c != "New" && status__c != "In Progress")',
                'filtersOpen' => 'true'
            })
        );

        physicianReviewHistoricData = JSON.serialize(
            rkl.RKSearch.consumeConfig (new Map<String, Object>{
                'resultFields' => 'AssignmentResults',
                'searchFields' => 'AssignmentSearch',
                'title' => 'Historic Reviews', //&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(Click on the "up-arrow/filter" icon directly below this text for search filters.)',
                'type' => 'unRelatedList',
                'objectApi' => 'Physician_Review__c',
                'links' => this.links,
                'relOptions' => new Map<String,Object>{'del' => false, 'add' => false, 'edit' => true},
                'baseCondition' => 'assigned_reviewer__c  = "' + this.userId + '" && (status__c != "New" && status__c != "In Progress")',
                'filtersOpen' => 'true'
            })
        );
    }
}