trigger FieldUpdateIntakeTrigger on Intake__c (before insert, before update) {

	if(Trigger.new.size()==1 && Trigger.new[0].occur_on_company_premises__c=='Yes'){
    	rkl.CopyLookupFieldsByTrigger main = new rkl.CopyLookupFieldsByTrigger(Trigger.new, new Set<String>{'Incident_Location__c'}, 'Intake__c');
	}  
}