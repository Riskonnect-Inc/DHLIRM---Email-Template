public with sharing class reviewerEmailRemindersPE {

public Map<String, List<Review__c>> incompleteReview3Days {get; private set;}
public Map<String, List<Review__c>> incompleteReview7Days {get; private set;}
public Map<String, List<Review__c>> incompleteReview10Days {get; private set;}
public Map<String, List<Review__c>> incompleteReview12Days {get; private set;}

@TestVisible Map<String, User> userIds;
Datetime currentDate, days3_Lower, days3_Upper, days7_Lower, days7_Upper,days10_Lower, days10_Upper, days12_Lower;
String days3_LowerSTR, days3_UpperSTR, days7_LowerSTR, days7_UpperSTR,days10_LowerSTR, days10_UpperSTR, days12_LowerSTR;
public List<Map<String, List<String>>> assignedReviewer {get; private set;}
public List<Messaging.SingleEmailMessage> emails {get; private set;}

private static String[] fields = new String[] {'Id', 'Name', 'CreatedDate', 'Assigned_Reviewer__c','Status__c', 'Due_Date__c'};

private static String DT_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';

public reviewerEmailRemindersPE() {

    incompleteReview3Days = new Map<String, List<Review__c>>();
    incompleteReview7Days = new Map<String, List<Review__c>>();
    incompleteReview10Days = new Map<String, List<Review__c>>();
    incompleteReview12Days = new Map<String, List<Review__c>>();
    
    assignedReviewer = new List<Map<String, List<String>>>();
    assignedReviewer.add(new Map<String, List<String>>());
    assignedReviewer.add(new Map<String, List<String>>());
    assignedReviewer.add(new Map<String, List<String>>());
    assignedReviewer.add(new Map<String, List<String>>());
    
    userIds = new Map<String, User>();
    emails = new List<Messaging.SingleEmailMessage>();

    currentDate = System.now();
    
    DateTime daysAgo_3 = currentDate.addDays(-3);
    DateTime daysAgo_7 = currentDate.addDays(-7);
    DateTime daysAgo_10 = currentDate.addDays(-10);
    Datetime daysAgo_12 = currentDate.addDays(-12);

    days3_Lower = DateTime.newInstance(daysAgo_3.year(), daysAgo_3.month(), daysAgo_3.day(), 0, 0, 0);
    days3_Upper = DateTime.newInstance(daysAgo_3.year(), daysAgo_3.month(), daysAgo_3.day(), 23, 59, 59);

    days3_LowerSTR = days3_Lower.formatGmt(DT_FORMAT);
    days3_UpperSTR = days3_Upper.formatGmt(DT_FORMAT);

    days7_Lower = DateTime.newInstance(daysAgo_7.year(), daysAgo_7.month(), daysAgo_7.day(), 0, 0, 0);
    days7_Upper = DateTime.newInstance(daysAgo_7.year(), daysAgo_7.month(), daysAgo_7.day(), 23, 59, 59);

    days7_LowerSTR = days7_Lower.formatGmt(DT_FORMAT);
    days7_UpperSTR = days7_Upper.formatGmt(DT_FORMAT);
    
    days10_Lower = DateTime.newInstance(daysAgo_10.year(), daysAgo_10.month(), daysAgo_10.day(), 0, 0, 0);
    days10_Upper = DateTime.newInstance(daysAgo_10.year(), daysAgo_10.month(), daysAgo_10.day(), 23, 59, 59);

    days10_LowerSTR = days10_Lower.formatGmt(DT_FORMAT);
    days10_UpperSTR = days10_Upper.formatGmt(DT_FORMAT);

    days12_Lower = Datetime.newInstance(daysAgo_12.year(), daysAgo_12.month(), daysAgo_12.day(), 0, 0, 0);

    days12_LowerSTR = days12_Lower.formatGmt(DT_FORMAT);
    
    getIncompleteReviews();
    getNeededUserData();
}


private void getNeededUserData() {
        Map<Id,User> userInfo;
//        User[] userInfo;
        Set<String> uIds = new Set<String>();
        uIds.addAll(incompleteReview3Days.keySet());
        uIds.addAll(incompleteReview7Days.keySet());
        uIds.addAll(incompleteReview10Days.keySet());
        uIds.addAll(incompleteReview12Days.keySet());
        System.debug('@USER IDS: ' + JSON.serialize(uIds));
      //  userInfo = [SELECT Id, FirstName, LastName, Email FROM User WHERE Id In:uIds];
      //  System.debug('@' + JSON.serialize(userInfo));
        userIds.putAll([SELECT Id, FirstName, LastName, Email FROM User WHERE Id In:uIds]);
    }

    
public void getIncompleteReviews() {

    String soql = 'SELECT ' + String.join(fields, ',') + ' FROM Review__c WHERE ' + 
            '(Status__c = \'In Progress\' OR Status__c = \'New\') AND Assigned_Reviewer__c != null AND ' +
            '((CreatedDate > ' + days3_LowerSTR + ' AND CreatedDate < ' + days3_UpperSTR + ') OR ' +
            '(CreatedDate > ' + days7_LowerSTR + ' AND CreatedDate < ' + days7_UpperSTR + ') OR ' +
            '(CreatedDate > ' + days10_LowerSTR + ' AND CreatedDate < ' + days10_UpperSTR + ') OR ' +
            '(CreatedDate <= ' + days12_LowerSTR + '))';

        System.debug('@QUERY: ' + soql);
    
     List<Review__c> allIncompleteReviews = Database.query(soql);
     System.debug('@@@' + JSON.serialize(allIncompleteReviews));
     for (Review__c pfr : allIncompleteReviews) {
     
      if (pfr.CreatedDate > days3_Lower && pfr.CreatedDate < days3_Upper) {
                if (!incompleteReview3Days.containsKey(pfr.Assigned_Reviewer__c)) {
                    incompleteReview3Days.put(pfr.Assigned_Reviewer__c, new List<Review__c>());
                    incompleteReview3Days.get(pfr.Assigned_Reviewer__c).add(pfr);
                } else {
                    incompleteReview3Days.get(pfr.Assigned_Reviewer__c).add(pfr);
                }
            }
            
     if (pfr.CreatedDate > days7_Lower && pfr.CreatedDate < days7_Upper) {
                if (!incompleteReview7Days.containsKey(pfr.Assigned_Reviewer__c)) {
                    incompleteReview7Days.put(pfr.Assigned_Reviewer__c, new List<Review__c>());
                    incompleteReview7Days.get(pfr.Assigned_Reviewer__c).add(pfr);
                } else {
                    incompleteReview7Days.get(pfr.Assigned_Reviewer__c).add(pfr);
                }
            }
        
        
    if (pfr.CreatedDate > days10_Lower && pfr.CreatedDate < days10_Upper) {
                if (!incompleteReview10Days.containsKey(pfr.Assigned_Reviewer__c)) {
                    incompleteReview10Days.put(pfr.Assigned_Reviewer__c, new List<Review__c>());
                    incompleteReview10Days.get(pfr.Assigned_Reviewer__c).add(pfr);
                } else {
                    incompleteReview10Days.get(pfr.Assigned_Reviewer__c).add(pfr);
                }
            }
    if (pfr.CreatedDate <= days12_Lower) {
                if (!incompleteReview12Days.containsKey(pfr.Assigned_Reviewer__c)){
                    incompleteReview12Days.put(pfr.Assigned_Reviewer__c, new List<Review__c>());
                    incompleteReview12Days.get(pfr.Assigned_Reviewer__c).add(pfr);
                } else {
                    incompleteReview12Days.get(pfr.Assigned_Reviewer__c).add(pfr);
                }
            }
        }
    }
    
    
public void dueReviewer(Map<String, List<Review__c>> incoming) {

        List<String> revs = new List<String>(incoming.keySet());
        for (String rev : revs) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<Review__c> allReviewerRecs = incoming.get(rev);
            User userInfo = userIds.get(rev);
            if (userInfo.Email == null) {
           
                continue;
            }
            
            email.setToAddresses(new String[] {userInfo.Email});
            String subject = userInfo.FirstName + ' ' + userInfo.LastName + ' You have';
             if (allReviewerRecs.size() > 1) {
                subject += ' Patient Event Reviews awaiting your attention.';
            } else {
                subject += ' a review awaiting your attention.';
            }
            
            
            String body = userInfo.FirstName + ' <br/><br/>' +
                          'This email is to inform you of the following outstanding Patient Event Reviews that need to be completed.<br/><br/>';
            if (allReviewerRecs.size() > 1) {
                body += 'Patient Event Reviews</b></u><br/>';
                for (Review__c pfr : allReviewerRecs) {
                    body += '<a href="' + URL.getSalesforceBaseURL().toExternalForm() + '/' + pfr.Id +'">' + pfr.Name + '</a><br/>';
                }
            } else {
                body += 'Patient Event Review</b></u><br/>'  + '<a href="' + URL.getSalesforceBaseURL().toExternalForm() + '/' + allReviewerRecs[0].Id +'">' + allReviewerRecs[0].Name + '</a><br/>';
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