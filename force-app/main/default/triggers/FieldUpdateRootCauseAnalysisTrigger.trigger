trigger FieldUpdateRootCauseAnalysisTrigger on Root_Cause_Analysis__c (before insert, before update) {

	rkl.CopyLookupFieldsByTrigger main = new rkl.CopyLookupFieldsByTrigger(Trigger.new, new Set<String>{'Patient_Visit__c','Patient_Safety_Incident__c'}, 'Root_Cause_Analysis__c');
}