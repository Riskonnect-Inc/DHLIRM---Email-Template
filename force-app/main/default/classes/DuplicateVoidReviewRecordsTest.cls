@isTest
private class DuplicateVoidReviewRecordsTest {
	
	@isTest static void test_pe() {
		rkl__Form_Template__c ft = new rkl__Form_Template__c(Name = 'Initial Reported Patient Event');
        insert ft;
		Patient_Event__c pe = new Patient_Event__c();
		pe.Patient_Event_Status__c = 'New';
		insert pe;

		Review__c per = new Review__c();
		per.Patient_Event__c = pe.Id;
		insert per;

		pe.Patient_Event_Status__c = 'Duplicate';
		update pe;

		pe.Patient_Event_Status__c = 'Closed';
		update pe;
	}
	
	@isTest static void test_pf() {
		Patient_Satisfaction__c pf = new Patient_Satisfaction__c();
		pf.Status_of_Complaint__c = 'New';
		insert pf;

		Patient_Feedback_Review__c pfr = new Patient_Feedback_Review__c();
		pfr.Patient_Feedback__c = pf.Id;
		insert pfr;

		pf.Status_of_Complaint__c = 'Duplicate';
		update pf;

		pf.Status_of_Complaint__c = 'Closed - Resolved';
		update pf;
	}

	@isTest static void test_pr(){
		Peer_Review__c pr = new Peer_Review__c();
		pr.Status__c = 'New';
		insert pr;

		Physician_Review__c prr = new Physician_Review__c();
		prr.Peer_Review__c = pr.Id;
		insert prr;

		pr.Status__c = 'Duplicate';
		update pr;
	}
	
}