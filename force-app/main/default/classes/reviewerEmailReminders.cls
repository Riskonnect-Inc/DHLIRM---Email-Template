public with sharing class reviewerEmailReminders {

    public Map<String, List<Patient_Feedback_Review__c>> incompleteReview3Days {get; private set;}
    public Map<String, List<Patient_Feedback_Review__c>> incompleteReview5Days {get; private set;}
    public Map<String, List<Patient_Feedback_Review__c>> incompleteReview8Days {get; private set;}

    @TestVisible Map<String, User> userIds;
    Datetime currentDate, days3_Lower, days3_Upper, days6_Lower, days6_Upper, days8_Lower;
    String days3_LowerSTR, days3_UpperSTR, days6_LowerSTR, days6_UpperSTR, days8_LowerSTR;
    public List<Map<String, List<String>>> assignedReviewer {get; private set;}
    public List<Messaging.SingleEmailMessage> emails {get; private set;}

    private static String[] fields = new String[] {'Id', 'Name', 'CreatedDate', 'Assigned_Reviewer__c', 'Status__c', 'Due_Date__c'};

    private static String DT_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';

    public reviewerEmailReminders() {

        incompleteReview3Days = new Map<String, List<Patient_Feedback_Review__c>>();
        incompleteReview5Days = new Map<String, List<Patient_Feedback_Review__c>>();
        incompleteReview8Days = new Map<String, List<Patient_Feedback_Review__c>>();

        assignedReviewer = new List<Map<String, List<String>>>();
        assignedReviewer.add(new Map<String, List<String>>());
        assignedReviewer.add(new Map<String, List<String>>());
        assignedReviewer.add(new Map<String, List<String>>());

        userIds = new Map<String, User>();
        emails = new List<Messaging.SingleEmailMessage>();

        currentDate = System.now();
        
        DateTime daysAgo_3 = currentDate.addDays(-3);
        DateTime daysAgo_6 = currentDate.addDays(-6);
        Datetime daysAgo_8 = currentDate.addDays(-8);

        days3_Lower = DateTime.newInstance(daysAgo_3.year(), daysAgo_3.month(), daysAgo_3.day(), 0, 0, 0);
        days3_Upper = DateTime.newInstance(daysAgo_3.year(), daysAgo_3.month(), daysAgo_3.day(), 23, 59, 59);

        days3_LowerSTR = days3_Lower.formatGmt(DT_FORMAT);
        days3_UpperSTR = days3_Upper.formatGmt(DT_FORMAT);

        days6_Lower = DateTime.newInstance(daysAgo_6.year(), daysAgo_6.month(), daysAgo_6.day(), 0, 0, 0);
        days6_Upper = DateTime.newInstance(daysAgo_6.year(), daysAgo_6.month(), daysAgo_6.day(), 23, 59, 59);

        days6_LowerSTR = days6_Lower.formatGmt(DT_FORMAT);
        days6_UpperSTR = days6_Upper.formatGmt(DT_FORMAT);

        days8_Lower = Datetime.newInstance(daysAgo_8.year(), daysAgo_8.month(), daysAgo_8.day(), 0, 0, 0);
        

        days8_LowerSTR = days8_Lower.formatGmt(DT_FORMAT);

        getIncompleteReviews();
        getNeededUserData();
    }

    private void getNeededUserData() {
        Map<Id,User> userInfo;
        //User[] userInfo;
        Set<String> uIds = new Set<String>();
        uIds.addAll(incompleteReview3Days.keySet());
        uIds.addAll(incompleteReview5Days.keySet());
        uIds.addAll(incompleteReview8Days.keySet());
        System.debug('@USER IDS: ' + JSON.serialize(uIds));
        //userInfo = [SELECT Id, FirstName, LastName, Email FROM User WHERE Id In:uIds];
        //System.debug('@' + JSON.serialize(userInfo));
        userIds.putAll([SELECT Id, FirstName, LastName, Email FROM User WHERE Id In:uIds]);
    }
    public void getIncompleteReviews() {

        String soql = 'SELECT ' + String.join(fields, ',') + ' FROM Patient_Feedback_Review__c WHERE ' + 
            '(Status__c = \'In Progress\' OR Status__c = \'New\') AND Assigned_Reviewer__c != null AND ' +
            '((CreatedDate > ' + days3_LowerSTR + ' AND CreatedDate < ' + days3_UpperSTR + ') OR ' +
            '(CreatedDate > ' + days6_LowerSTR + ' AND CreatedDate < ' + days6_UpperSTR + ') OR ' + 
            '(CreatedDate <= ' + days8_LowerSTR + '))'; 

        System.debug('@QUERY: ' + soql);

        List<Patient_Feedback_Review__c> allIncompleteReviews = Database.query(soql);
       
        System.debug('@@@' + JSON.serialize(allIncompleteReviews));
        for (Patient_Feedback_Review__c pfr : allIncompleteReviews) {
            if (pfr.CreatedDate > days3_Lower && pfr.CreatedDate < days3_Upper) {
                if (!incompleteReview3Days.containsKey(pfr.Assigned_Reviewer__c)) {
                    incompleteReview3Days.put(pfr.Assigned_Reviewer__c, new List<Patient_Feedback_Review__c>());
                    incompleteReview3Days.get(pfr.Assigned_Reviewer__c).add(pfr);
                } else {
                    incompleteReview3Days.get(pfr.Assigned_Reviewer__c).add(pfr);
                }
            }
            if (pfr.CreatedDate > days6_Lower && pfr.CreatedDate < days6_Upper) {
                if (!incompleteReview5Days.containsKey(pfr.Assigned_Reviewer__c)) {
                    incompleteReview5Days.put(pfr.Assigned_Reviewer__c, new List<Patient_Feedback_Review__c>());
                    incompleteReview5Days.get(pfr.Assigned_Reviewer__c).add(pfr);
                } else {
                    incompleteReview5Days.get(pfr.Assigned_Reviewer__c).add(pfr);
                }
            }
            if (pfr.CreatedDate <= days8_Lower){
                if (!incompleteReview8Days.containsKey(pfr.Assigned_Reviewer__c)){
                    incompleteReview8Days.put(pfr.Assigned_Reviewer__c, new List<Patient_Feedback_Review__c>());
                    incompleteReview8Days.get(pfr.Assigned_Reviewer__c).add(pfr);
                } else{
                    incompleteReview8Days.get(pfr.Assigned_Reviewer__c).add(pfr);
                }
            }
        }
    }

    public void dueReviewer(Map<String, List<Patient_Feedback_Review__c>> incoming) {

        List<String> revs = new List<String>(incoming.keySet());
        for (String rev : revs) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<Patient_Feedback_Review__c> allReviewerRecs = incoming.get(rev);
            User userInfo = userIds.get(rev);
            if (userInfo.Email == null) {
                continue;
            }
            email.setToAddresses(new String[] {userInfo.Email});
            String subject = userInfo.FirstName + ' ' + userInfo.LastName + ', you have';
            if (allReviewerRecs.size() > 1) {
                subject += ' Patient Feedback Reviews awaiting your attention.';
            } else {
                subject += ' a review awaiting your attention.';
            }
            String body = userInfo.FirstName + ' <br/><br/>' +
                          'This email is to inform you of the following outstanding Patient Feedback Reviews that need to be completed.<br/><br/>';
            if (allReviewerRecs.size() > 1) {
                body += 'Patient Feedback Reviews</b></u><br/>';
                for (Patient_Feedback_Review__c pfr : allReviewerRecs) {
                    body += '<a href="' + URL.getSalesforceBaseURL().toExternalForm() + '/' + pfr.Id +'">' + pfr.Name + '</a><br/>';
                }
            } else {
                body += 'Patient Feedback Review</b></u><br/>' + '<a href="' + URL.getSalesforceBaseURL().toExternalForm() + '/' + allReviewerRecs[0].Id +'">' + allReviewerRecs[0].Name + '</a><br/>';
                //+ URL.getSalesforceBaseUrl().toExternalForm() + '/' + allReviewerRecs[0].Id;
            }

            email.setSubject(subject);
            email.setHtmlBody(body);

            emails.add(email);

        }
    }

    public void sendEmails() {
        Messaging.sendEmail(emails);
    }
}