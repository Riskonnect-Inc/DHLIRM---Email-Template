trigger FieldUpdatePatientFeedbackTrigger on Patient_Satisfaction__c (before insert, before update) {

	rkl.CopyLookupFieldsByTrigger main = new rkl.CopyLookupFieldsByTrigger(Trigger.new, new Set<String>{'Patient_Visit__c','Reporter__c'}, 'Patient_Satisfaction__c');
}