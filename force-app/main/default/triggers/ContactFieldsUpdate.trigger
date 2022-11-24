trigger ContactFieldsUpdate on Intake_Detail__c (before insert, before update) {
	
	rkl.CopyLookupFieldsByTrigger main = new rkl.CopyLookupFieldsByTrigger(Trigger.new, new Set<String>{'Injured_Employee__c','Company_Driver__c'}, 'Intake_Detail__c');  
}