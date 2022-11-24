trigger PatientFeedbackNoteFields on Patient_Feedback_Notes__c (before insert, before update) {

    List<Patient_Feedback_Notes__c> pfn = new List<Patient_Feedback_Notes__c>();

    List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
    String MyProflieName = PROFILE[0].Name;

    if(MyProflieName !='RK Data Manager')
    {
        if(Trigger.IsInsert) {
            for(Patient_Feedback_Notes__c pf : trigger.new)
            {
                pf.Date_Note_Added__c = Date.today();
                pf.Date_Note_Updated__c = Date.today();
                pf.Note_Create_Date_Time__c = DateTime.now();
                pf.Note_Author_Name__c = UserInfo.getFirstName() +' '+ UserInfo.getLastName();
                pf.Note_First_Line_of_Text__c = !(String.isBlank(pf.Note_Text_Rich__c.stripHtmlTags()))?pf.Note_Text_Rich__c.stripHtmlTags().left(78):'Note Blank';
                  
            }
        }
    
        if(Trigger.IsUpdate) {
            for(Patient_Feedback_Notes__c pf : trigger.new)
            {
                pf.Date_Note_Updated__c= Date.today();
                pf.Note_First_Line_of_Text__c = !(String.isBlank(pf.Note_Text_Rich__c.stripHtmlTags()))?pf.Note_Text_Rich__c.stripHtmlTags().left(78):'Note Blank';
           
            }
        }
    }
   
}