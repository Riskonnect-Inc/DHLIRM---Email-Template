trigger AdjusterNoteFields on Adjuster_Notes__c (before insert, before update) {

    List<Adjuster_Notes__c> adjn = new List<Adjuster_Notes__c>();

    List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
    String MyProflieName = PROFILE[0].Name;

    if(MyProflieName  !='RK Data Manager')
    {
        if(Trigger.IsInsert) {
            for(Adjuster_Notes__c adj : trigger.new)
            {
                adj.Date_Note_Added__c = Date.today();
                adj.Date_Note_Updated__c = Date.today();
                adj.Note_Create_Date_Time__c = DateTime.now();
                adj.Note_Author_Name__c = UserInfo.getFirstName() +' '+ UserInfo.getLastName();
                adj.Note_First_Line_of_Text__c = !(String.isBlank(adj.Note_Text_Rich__c.stripHtmlTags()))?adj.Note_Text_Rich__c.stripHtmlTags().left(78):'Note Blank';
                  
            }
        }
    
        if(Trigger.IsUpdate) {
            for(Adjuster_Notes__c adj : trigger.new)
            {
                adj.Date_Note_Updated__c= Date.today();
                adj.Note_First_Line_of_Text__c = !(String.isBlank(adj.Note_Text_Rich__c.stripHtmlTags()))?adj.Note_Text_Rich__c.stripHtmlTags().left(78):'Note Blank';
           
            }
        }
    }
   
}