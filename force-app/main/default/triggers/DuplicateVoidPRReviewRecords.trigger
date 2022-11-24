/*Whenever a Peer_Review__c record's Status__c is set to 'Duplicate' or 'Void' this trigger updates all of the Physician_Review__c child record's Status__c to match.*/

trigger DuplicateVoidPRReviewRecords on Peer_Review__c (after update) {
  for(Peer_Review__c pr : Trigger.new){
    Peer_Review__c oldPr = Trigger.oldMap.get(pr.Id);
    if(oldPr.Status__c != pr.Status__c && (pr.Status__c == 'Closed' || pr.Status__c == 'Duplicate' || pr.Status__c == 'Void')){
    
      List<Physician_Review__c> children = [SELECT Id, Peer_Review__r.Id, Status__c FROM Physician_Review__c WHERE Peer_Review__r.Id = : pr.Id];

      List<Physician_Review__c> newids = new List<Physician_Review__c>();

      for(Physician_Review__c rev : children){
        if(pr.Status__c == 'Duplicate' || pr.Status__c == 'Void'){
          rev.Status__c = pr.Status__c;
          newids.add(rev);
        }
        if(pr.Status__c == 'Closed' && rev.Status__c != 'Completed'){
          rev.Status__c = 'Auto - Closed';
          newids.add(rev);
        }
      }
      if(newids.isEmpty() == false){
        update newids;
      }
    }
  }
}