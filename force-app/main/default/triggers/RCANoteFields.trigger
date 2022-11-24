trigger RCANoteFields on RCA_Notes__c (before insert, before update) {

    List<RCA_Notes__c> racn = new List<RCA_Notes__c>();

    List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
    String MyProflieName = PROFILE[0].Name;

    if(MyProflieName  !='RK Data Manager')
    {
        if(Trigger.IsInsert) {
            for(RCA_Notes__c rca : trigger.new)
            {
                rca.Date_Note_Added__c = Date.today();
                rca.Date_Note_Updated__c = Date.today();
                rca.Note_Create_Date_Time__c = DateTime.now();
                rca.Note_Author_Name__c = UserInfo.getFirstName() +' '+ UserInfo.getLastName();
                rca.Note_First_Line_of_Text__c = !(String.isBlank(rca.Note_Text_Rich__c.stripHtmlTags()))?rca.Note_Text_Rich__c.stripHtmlTags().left(78):'Note Blank';
                  
            }
        }
    
        if(Trigger.IsUpdate) {
            for(RCA_Notes__c rca : trigger.new)
            {
                rca.Date_Note_Updated__c= Date.today();
                rca.Note_First_Line_of_Text__c = !(String.isBlank(rca.Note_Text_Rich__c.stripHtmlTags()))?rca.Note_Text_Rich__c.stripHtmlTags().left(78):'Note Blank';
           
            }
        }
    }
   
}