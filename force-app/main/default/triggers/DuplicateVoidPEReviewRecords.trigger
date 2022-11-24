/*Whenever a Patient_Event__c record's Status__c is set to 'Duplicate' or 'Void' this trigger updates all of the Review__c child record's Status__c to match.*/

trigger DuplicateVoidPEReviewRecords on Patient_Event__c (after update) {
  for(Patient_Event__c pe : Trigger.new){
    Patient_Event__c oldPe = Trigger.oldMap.get(pe.Id);
    if(oldPe.Patient_Event_Status__c != pe.Patient_Event_Status__c && (pe.Patient_Event_Status__c != 'New' || pe.Patient_Event_Status__c != 'In Progress')){

      List<Review__c> children = [SELECT Id, Patient_Event__r.Id, Status__c FROM Review__c WHERE Patient_Event__r.Id = : pe.Id];

      List<Review__c> newids = new List<Review__c>();

      for(Review__c rev : children){
        if(pe.Patient_Event_Status__c == 'Duplicate' || pe.Patient_Event_Status__c == 'Void'){
          rev.Status__c = pe.Patient_Event_Status__c;
          newids.add(rev);
        }
        if(pe.Patient_Event_Status__c == 'Closed' && rev.Status__c != 'Completed'){
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