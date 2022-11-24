@isTest 
private class emailremindertest{
    static testMethod void validateemailreminderPF() {

        Patient_Satisfaction__c patientFeedback = new Patient_Satisfaction__c();
        patientFeedback.IM_Status__c = 'In Progress';
        insert patientFeedback;
         
        Patient_Feedback_Review__c pf = new Patient_Feedback_Review__c(Patient_Feedback__c=patientFeedback.ID, Assigned_Reviewer__c= UserInfo.getUserId(), Status__c='New');     
        insert pf;
        Datetime days = Datetime.now().addDays(-3);
        Test.setCreatedDate(pf.Id, days);
        Map<String, List<Patient_Feedback_Review__c>> incoming = new Map<String, List<Patient_Feedback_Review__c>>();
        incoming.put(UserInfo.getUserId(), new List<Patient_Feedback_Review__c>{pf});
               
        reviewerEmailReminders r= new reviewerEmailReminders ();
        User usr= [SELECT ID,Name,username,FirstName,LastName,email FROM user WHERE Id= :UserInfo.getUserId() LIMIT 1];
        r.userIds.put(UserInfo.getUserId(),usr);
        r.dueReviewer(incoming);
        r.sendEmails();
        
    }
    
    
    static testMethod void validateemailreminderPE() {
        
        rkl__Form_Template__c ft = new rkl__Form_Template__c(Name='Initial Reported Patient Event');
        insert ft;
        
        Patient_Event__c patientEvent = new Patient_Event__c();
        patientEvent.IM_Status__c = 'In Progress';
        insert patientEvent ;
      
        Review__c pe = new Review__c( Patient_Event__c=patientEvent.ID, Assigned_Reviewer__c= UserInfo.getUserId(), Status__c='New');     
        insert pe;
        Datetime days = Datetime.now().addDays(-3);
        Test.setCreatedDate(pe.Id, days);
        Map<String, List<Review__c>> incoming = new Map<String, List<Review__c>>();
        incoming.put(UserInfo.getUserId(), new List<Review__c>{pe});
               
        reviewerEmailRemindersPE r= new reviewerEmailRemindersPE ();
        User usr= [SELECT ID,Name,username,FirstName,LastName,email FROM user WHERE Id= :UserInfo.getUserId() LIMIT 1];
        r.userIds.put(UserInfo.getUserId(),usr);
        r.dueReviewer(incoming);
        r.sendEmails();
         
    } 
    
    /*
     static testMethod void validateemailreminderPR() {
        Physician_Review__c pr = new Physician_Review__c( Assigned_Reviewer__c= UserInfo.getUserId(), Status__c='In Progress', Due_Date__c=Date.today().addDays(1));     
        insert pr;
        //Map<String, List<Physician_Review__c>>
        
        Datetime days = Datetime.now().addDays(+1);
        Test.setCreatedDate(pr.Id, days);
        Map<String, List<Physician_Review__c>> incoming = new Map<String, List<Physician_Review__c>>();
        incoming.put(UserInfo.getUserId(), new List<Physician_Review__c>{pr});
               
        reviewerEmailRemindersPR r= new reviewerEmailRemindersPR ();
        User usr= [SELECT ID,Name,username,FirstName,LastName,email FROM user WHERE Id= :UserInfo.getUserId() LIMIT 1];
        r.userIds.put(UserInfo.getUserId(),usr);
        r.dueReviewer(incoming);
        r.sendEmails();
                
    }*/
    
  
}