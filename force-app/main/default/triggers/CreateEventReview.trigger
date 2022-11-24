trigger CreateEventReview on Patient_Event__c (before insert, before update) {

	Id recTypeId = Schema.SObjectType.Patient_Event__c.getRecordTypeInfosByName().get('Staff/Provider Behavior').getRecordTypeId();

    if(Trigger.new.size() == 1 && Trigger.new[0].RecordTypeId != recTypeId){
    	CreateReviewRecord.makeEventReview();
  }
}