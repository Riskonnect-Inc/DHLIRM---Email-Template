trigger PatientEventNoteFields on Patient_Event_Notes__c (before insert, before update) {

    List<Patient_Event_Notes__c> pen = new List<Patient_Event_Notes__c>();

    List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
    String MyProflieName = PROFILE[0].Name;

    if(MyProflieName  !='RK Data Manager')
    {
        if(Trigger.IsInsert) {
            for(Patient_Event_Notes__c pe : trigger.new)
            {
                pe.Date_Note_Added__c = Date.today();
                pe.Date_Note_Updated__c = Date.today();
                pe.Note_Create_Date_Time__c = DateTime.now();
                pe.Note_Author_Name__c = UserInfo.getFirstName() +' '+ UserInfo.getLastName();
                pe.Note_First_Line_of_Text__c = !(String.isBlank(pe.Note_Text_Rich__c.stripHtmlTags()))?pe.Note_Text_Rich__c.stripHtmlTags().left(78):'Note Blank';
                  
            }
        }
    
        if(Trigger.IsUpdate) {
            for(Patient_Event_Notes__c pe : trigger.new)
            {
                pe.Date_Note_Updated__c= Date.today();
                pe.Note_First_Line_of_Text__c = !(String.isBlank(pe.Note_Text_Rich__c.stripHtmlTags()))?pe.Note_Text_Rich__c.stripHtmlTags().left(78):'Note Blank';
            }
        }
    }
   
}