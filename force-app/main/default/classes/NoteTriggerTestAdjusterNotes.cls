@isTest
private class NoteTriggerTestAdjusterNotes {
	
	@isTest static void test_adjusterNotes() {
		Adjuster_Notes__c adjn = new Adjuster_Notes__c();
		adjn.Note_Category__c = 'General';
		adjn.Note_Text_Rich__c = 'This is a test note.';
		insert adjn;

		adjn.Note_Text_Rich__c = 'This is an update';
		update adjn;
	}
	
}