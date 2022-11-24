@isTest
private class ReviewManagement_Test
{
	@isTest
	static void getReviewMgmtData_Test()
	{
		Map<String,Object> testData = new Map<String,Object>();
		testData.put('object1API','Review__c');
		testData.put('object2API', 'Patient_Feedback_Review__c');
		testData.put('object3API', 'Physician_Review__c');
		testData.put('statusFld1', 'Status__c');
		testData.put('statusFld2', 'Status__c');
		testData.put('statusFld3', 'Status__c');
		testData.put('newColumns', '{"Name":["Name","Name","Name"],"Creator":["CreatedById","CreatedById","CreatedById"]}');
		testData.put('progressColumns', '{"Reviewer":["Assigned_Reviewer__r.CompanyName","Assigned_Reviewer__r.CompanyName","Assigned_Reviewer__r.CompanyName"]}');
		Object testRecords = ReviewManagement_Controller.getReviewMgmtData(JSON.serialize(testData));

	}
}