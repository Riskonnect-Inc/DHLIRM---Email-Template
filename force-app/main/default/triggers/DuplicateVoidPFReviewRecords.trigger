/*Whenever a Patient_Satisfaction__c record's Status_of_Complaint__c is set to 'Duplicate' or 'Void' this trigger updates all of the Patient_Feedback_Review__c child record's Status__c to matach.*/

trigger DuplicateVoidPFReviewRecords on Patient_Satisfaction__c (after update) {
  for(Patient_Satisfaction__c pf : Trigger.new){
    Patient_Satisfaction__c oldPf = Trigger.oldMap.get(pf.Id);
    if(oldPf.Status_of_Complaint__c != pf.Status_of_Complaint__c && (pf.Status_of_Complaint__c != 'New' || pf.Status_of_Complaint__c != 'In Progress')){

      List<Patient_Feedback_Review__c> children = [SELECT Id, Patient_Feedback__r.Id, Status__c FROM Patient_Feedback_Review__c WHERE Patient_Feedback__r.Id = : pf.Id];

      List<Patient_Feedback_Review__c> newids = new List<Patient_Feedback_Review__c>();

      for(Patient_Feedback_Review__c rev : children){
        if(pf.Status_of_Complaint__c == 'Duplicate' || pf.Status_of_Complaint__c == 'Void'){
          rev.Status__c = pf.Status_of_Complaint__c;
          newids.add(rev);
        }
        if((pf.Status_of_Complaint__c == 'Closed - Resolved' || pf.Status_of_Complaint__c == 'Closed - Unresolved') && rev.Status__c != 'Completed'){
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