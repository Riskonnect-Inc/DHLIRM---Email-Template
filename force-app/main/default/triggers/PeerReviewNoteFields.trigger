trigger PeerReviewNoteFields on Peer_Review_Notes__c (before insert, before update) {

    List<Peer_Review_Notes__c> prn = new List<Peer_Review_Notes__c>();

    List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
    String MyProflieName = PROFILE[0].Name;

    if(MyProflieName  !='RK Data Manager')
    {
        if(Trigger.IsInsert) {
            for(Peer_Review_Notes__c pr : trigger.new)
            {
                pr.Date_Note_Added__c = Date.today();
                pr.Date_Note_Updated__c = Date.today();
                pr.Note_Create_Date_Time__c = DateTime.now();
                pr.Note_Author_Name__c = UserInfo.getFirstName() +' '+ UserInfo.getLastName();
                pr.Note_First_Line_of_Text__c = !(String.isBlank(pr.Note_Text_Rich__c.stripHtmlTags()))?pr.Note_Text_Rich__c.stripHtmlTags().left(78):'Note Blank';
                  
            }
        }
    
        if(Trigger.IsUpdate) {
            for(Peer_Review_Notes__c pr : trigger.new)
            {
                pr.Date_Note_Updated__c= Date.today();
                pr.Note_First_Line_of_Text__c = !(String.isBlank(pr.Note_Text_Rich__c.stripHtmlTags()))?pr.Note_Text_Rich__c.stripHtmlTags().left(78):'Note Blank';
           
            }
        }
    }
   
}