/*===========================================================================
     Added to RK base RMIS product as  11/05/2014
      ===========================================================================*/
  
public class StickyNoteController{
  
    public Id      recId      {get;set;} 
    public string  stickynote {get;set;}
    
    public StickyNoteController (ApexPages.StandardController ctlr) { 
      recId = UserInfo.getUserId();
      user uu = [Select id, stickynote__c From user where id = :recId limit 1];                                                               
      stickynote  = uu.stickynote__c ;       
    }
      
public Pagereference SaveRecord(){
        List<user> usr = new List<user>();
        user u = new user();
        u.id = recId;
        u.stickynote__c = stickynote;
        usr.add(u);              
        Try {Update usr; }
         Catch (Exception e1) {return null;}  
     return null; 
    }       
}