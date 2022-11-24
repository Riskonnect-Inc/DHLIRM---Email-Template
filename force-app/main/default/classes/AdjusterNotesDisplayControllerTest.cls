/*===========================================================================
    Added to RK base RMIS product as 08/28/2013
===========================================================================*/

@isTest
public class AdjusterNotesDisplayControllerTest {
    public static testMethod void testController() {
        Claim__c testClaim = new Claim__c(Date_of_Loss__c = Date.today());
        insert testClaim;
        PageReference testPage = new PageReference('/apex/AdjusterNotesDialog');
        Test.setCurrentPage(testPage);
        AdjusterNotesDisplayController testController = new AdjusterNotesDisplayController(new ApexPages.StandardController(testClaim));
        testController.getHtmlResultsWindowSize();
        testController.getCount();
        testController.getStatus();
        testController.getCreated();
        testController.getDue();
        testController.getAvailableValues();
        testController.getCreatedDateSortValues();
        testController.getDisplayFormatValues();
        testController.getDomainURL();
        testController.getSearchSettings();
        testController.setAttachments(testController.getAttachments());
        testController.setTaskStatus(testController.getTaskStatus());
        testController.setDateCreated(testController.getDateCreated());
        testController.setDateDue(testController.getDateDue());
        testController.setNotesCount(testController.getNotesCount());
        testController.setAvailableValue(testController.getAvailableValue());
        testController.setContainsSearch(testController.getContainsSearch());
        testController.setCreatedDateSort(testController.getCreatedDateSort());
        testController.setDisplayFormat(testController.getDisplayFormat());
        Adjuster_Notes__c[] testActivities = testController.getActivities();
        
        PageReference testRun = testController.run();
        Claim__c testClaim2 = testController.getClaim();
        String htmlResultsEmbeddedLinkTargetTest = testController.getHtmlResultsEmbeddedLinkTarget();
        testController.getDialogWindowHeight();
        testController.getDialogWindowWidth();
        testController.getHtmlResultsWindowWidth();
        testController.getHtmlResultsWindowHeight();
    }
}