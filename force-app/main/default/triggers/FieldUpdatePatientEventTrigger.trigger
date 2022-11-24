trigger FieldUpdatePatientEventTrigger on Patient_Event__c (before insert, before update) {

	rkl.CopyLookupFieldsByTrigger main = new rkl.CopyLookupFieldsByTrigger(Trigger.new, new Set<String>{'Patient_Visit__c','Reporter__c','Medication__c'}, 'Patient_Event__c');
}