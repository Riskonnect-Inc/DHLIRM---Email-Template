@isTest
private class NoteTriggersTestHC {
	
	@isTest static void test_pe_notes() {
		Patient_Event_Notes__c pen = new Patient_Event_Notes__c();
		pen.Note_Category__c = 'General';
		pen.Note_Text_Rich__c = 'This is a test.';
		insert pen;

		pen.Note_Text_Rich__c = 'This is an update to the note.';
		update pen;

	}
	
	@isTest static void test_pf_notes() {
		Patient_Feedback_Notes__c pfn = new Patient_Feedback_Notes__c();
		pfn.Note_Category__c = 'General';
		pfn.Note_Text_Rich__c = 'This is a test.';
		insert pfn;

		pfn.Note_Text_Rich__c = 'This is an updated note';
		update pfn;
	}

	@isTest static void test_pr_notes() {
		Peer_Review_Notes__c prn = new Peer_Review_Notes__c();
		prn.Note_Category__c = 'General';
		prn.Note_Text_Rich__c = 'This is a test.';
		insert prn;

		prn.Note_Text_Rich__c = 'This is an update.';
		update prn;
	}

	@isTest static void test_rca_notes() {
		RCA_Notes__c rcan = new RCA_Notes__c();
		rcan.Note_Category__c = 'General';
		rcan.Note_Text_Rich__c = 'This is a test';
		insert rcan;

		rcan.Note_Text_Rich__c = 'This is an update.';
		update rcan;
	}
}