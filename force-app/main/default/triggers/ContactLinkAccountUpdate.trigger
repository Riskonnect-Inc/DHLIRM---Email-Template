trigger ContactLinkAccountUpdate on Contact_Roles__c (before insert, before update) {
Hard_Codes__c  hc = Hard_Codes__c.getInstance();
boolean UpdateIt = true;
 List<contact> contUpdateList = new List<contact>();

    Set<id> cIds = new Set<id>();
    for(Contact_Roles__c cc : Trigger.new) 
         cIds.add(cc.contact__c);
 
     Map<id, contact> conMap = new Map<id, contact>(
          [SELECT id,accountId FROM contact WHERE Id IN :cIds]);
 
     for (Contact_Roles__c cc : Trigger.new) {
        if (cc.account__c == Null && conMap.get(cc.Contact__c).Accountid == hc.DefaultAccountId__c )
          cc.account__c = hc.DefaultAccountId__c ;
          
         if (cc.account__c == Null && conMap.get(cc.Contact__c).Accountid <> hc.DefaultAccountId__c )
          cc.account__c = conMap.get(cc.Contact__c).Accountid;
        
       if (cc.account__c <> Null && conMap.get(cc.Contact__c).Accountid <> cc.account__c
          && conMap.get(cc.Contact__c).Accountid <> Null ){
          cc.account__c = conMap.get(cc.Contact__c).Accountid;
          UpdateIt = false;}
          else 
          UpdateIt = true;
        
           
        
          
   if (UpdateIt && cc.account__c <> conMap.get(cc.Contact__c).Accountid && cc.account__c != Null ){
                    contact[] conList = [Select id, accountId
                                          From   contact
                                          Where  id = :cc.Contact__c ];
    
        for (contact c : conList){  
          contact newCont = new contact (id = c.id, accountId = cc.account__C);
          contUpdateList.add(newCont);     
        }
     update contUpdateList;
   }     
  }       
 }