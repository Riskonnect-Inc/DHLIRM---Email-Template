public class extendReviewCustomSection {

	public List<Review__c> reviews {get; set;}
	public Review__c currentRecord {get; set;}

		public extendReviewCustomSection(ApexPages.StandardController stdController){
			currentRecord = [SELECT Id, Name, Patient_Event__r.Id FROM Review__c WHERE Id=:ApexPages.currentPage().getParameters().get('id')];

			reviews = [SELECT Id,
												Name,
												Assigned_Reviewer__r.Name,
												Recommended_changes_for_prevention__c,
												Reviewer_Comments__c,
												Status__c,
												Patient_Notified_of_Incident__c,
												Interventions_Taken__c,
												Associated_with_Hand_Off__c,
												Patient_Event__r.Id,
												Patient_Event_Record_Type__c,
                                                Exposure_Reviewer_Comments__c,
                                                Visitor_Notified_of_Event__c,
                                                Narcotic_Reviewer_Comments__c,
                                                Date__c,
                                                Why_did_this_event_occur__c
								 FROM Review__c
								 WHERE Patient_Event__r.Id=:currentRecord.Patient_Event__r.Id and id != :currentRecord.id];
		}
}