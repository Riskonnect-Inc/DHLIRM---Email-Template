/* --- PD --- */
@isTest
private class ViewNotesQuickAction_Test {
	@testSetup
	static void setupTest() {
		ViewNotes__c viewNotes = new ViewNotes__c(Name = 'Claim__c');
		viewNotes.Note_Categories_API__c = 'Note_Category__c';
		viewNotes.Note_Created_Date_API__c = 'Note_Create_Date_Time__c';
		viewNotes.Note_Object_API__c = 'Adjuster_Notes__c';
		viewNotes.Parent_Fieldset__c = 'View_Notes_Header';
		insert viewNotes;
		Claim__c clm = new Claim__c(Date_Of_Loss__c = System.today());
		insert clm;
		Adjuster_Notes__c adj = new Adjuster_Notes__c(Note_Category__c = 'General', Claim__c = clm.Id, Note_Text_Rich__c = 'test');
		insert adj;
	}
	@isTest
	static void testgetViewNotes() {
		Claim__c clm = [SELECT Id FROM Claim__c LIMIT 1];
		Test.startTest();
		Object vCon = ViewNotesQuickAction_Controller.getViewNotes(clm.Id);
		Test.stopTest();

	}
	@isTest
	static void testgetObjectDetails() {
		Claim__c clm = [SELECT Id FROM Claim__c LIMIT 1];
		Test.setCurrentPageReference(new PageReference('Page.ViewNotesDownload'));
		System.currentPageReference().getParameters().put('mainObject', 'Claim__c');
		System.currentPageReference().getParameters().put('recId', clm.Id);
		Test.startTest();
		ViewNotesQuickAction_Controller cntrl = new ViewNotesQuickAction_Controller();
		sObject objDetails = cntrl.getObjectDetails();
		Test.stopTest();

	}
	@isTest
	static void testgetDownloadActivities() {
		Claim__c clm = [SELECT Id FROM Claim__c LIMIT 1];
		Test.setCurrentPageReference(new PageReference('Page.ViewNotesDownload'));
		System.currentPageReference().getParameters().put('recId', clm.Id);
		System.currentPageReference().getParameters().put('mainObject', 'Claim__c');
		System.currentPageReference().getParameters().put('orderBy', 'asc');
		System.currentPageReference().getParameters().put('dateRange', 'TODAY');
		System.currentPageReference().getParameters().put('category', null);
		System.currentPageReference().getParameters().put('limitNotes', '10');
		System.currentPageReference().getParameters().put('target', '__blank');
		Test.startTest();
		ViewNotesQuickAction_Controller cntrl = new ViewNotesQuickAction_Controller();
		sObject[] objDetails = cntrl.getDownloadActivities();
		cntrl.getDomainURL();
		Test.stopTest();

	}
}