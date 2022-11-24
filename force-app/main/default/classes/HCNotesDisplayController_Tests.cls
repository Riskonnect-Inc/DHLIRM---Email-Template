@isTest
public class HCNotesDisplayController_Tests {
    public static testMethod void testControllerPE() {
        rkl__Form_Template__c ft = new rkl__Form_Template__c(Name = 'Initial Reported Patient Event');
        insert ft;
        Patient_Event__c testpe = new Patient_Event__c(Date_of_Event__c = Date.today());
        insert testpe;
        PageReference testPage = new PageReference('/apex/PatientEventNotesDialog');
        Test.setCurrentPage(testPage);
        PatientEventNotesDisplayController testControllerPE = new PatientEventNotesDisplayController(new ApexPages.StandardController(testpe));
        testControllerPE.getHtmlResultsWindowSize();
        testControllerPE.getCount();
        testControllerPE.getStatus();
        testControllerPE.getCreated();
        testControllerPE.getDue();
        testControllerPE.getAvailableValues();
        testControllerPE.getCreatedDateSortValues();
        testControllerPE.getDisplayFormatValues();
        testControllerPE.getDomainURL();
        testControllerPE.getSearchSettings();
        testControllerPE.setAttachments(testControllerPE.getAttachments());
        testControllerPE.setTaskStatus(testControllerPE.getTaskStatus());
        testControllerPE.setDateCreated(testControllerPE.getDateCreated());
        testControllerPE.setDateDue(testControllerPE.getDateDue());
        testControllerPE.setNotesCount(testControllerPE.getNotesCount());
        testControllerPE.setAvailableValue(testControllerPE.getAvailableValue());
        testControllerPE.setContainsSearch(testControllerPE.getContainsSearch());
        testControllerPE.setCreatedDateSort(testControllerPE.getCreatedDateSort());
        testControllerPE.setDisplayFormat(testControllerPE.getDisplayFormat());
        Patient_Event_Notes__c[] testActivities = testControllerPE.getActivities();
        
        PageReference testRun = testControllerPE.run();
        Patient_Event__c testPR2 = testControllerPE.getPE();
        String htmlResultsEmbeddedLinkTargetTest = testControllerPE.getHtmlResultsEmbeddedLinkTarget();
        testControllerPE.getDialogWindowHeight();
        testControllerPE.getDialogWindowWidth();
        testControllerPE.getHtmlResultsWindowWidth();
        testControllerPE.getHtmlResultsWindowHeight();
    }

    public static testMethod void testControllerPF() {
        Patient_Satisfaction__c testpf = new Patient_Satisfaction__c(Date_of_Event__c = Date.today());
        insert testpf;
        PageReference testPage = new PageReference('/apex/PatientFeedbackNotesDialog');
        Test.setCurrentPage(testPage);
        PatientFeedbackNotesDisplayController testControllerPF = new PatientFeedbackNotesDisplayController(new ApexPages.StandardController(testpf));
        testControllerPF.getHtmlResultsWindowSize();
        testControllerPF.getCount();
        testControllerPF.getStatus();
        testControllerPF.getCreated();
        testControllerPF.getDue();
        testControllerPF.getAvailableValues();
        testControllerPF.getCreatedDateSortValues();
        testControllerPF.getDisplayFormatValues();
        testControllerPF.getDomainURL();
        testControllerPF.getSearchSettings();
        testControllerPF.setAttachments(testControllerPF.getAttachments());
        testControllerPF.setTaskStatus(testControllerPF.getTaskStatus());
        testControllerPF.setDateCreated(testControllerPF.getDateCreated());
        testControllerPF.setDateDue(testControllerPF.getDateDue());
        testControllerPF.setNotesCount(testControllerPF.getNotesCount());
        testControllerPF.setAvailableValue(testControllerPF.getAvailableValue());
        testControllerPF.setContainsSearch(testControllerPF.getContainsSearch());
        testControllerPF.setCreatedDateSort(testControllerPF.getCreatedDateSort());
        testControllerPF.setDisplayFormat(testControllerPF.getDisplayFormat());
        Patient_Feedback_Notes__c[] testActivities = testControllerPF.getActivities();
        
        PageReference testRun = testControllerPF.run();
        Patient_Satisfaction__c testPR2 = testControllerPF.getPF();
        String htmlResultsEmbeddedLinkTargetTest = testControllerPF.getHtmlResultsEmbeddedLinkTarget();
        testControllerPF.getDialogWindowHeight();
        testControllerPF.getDialogWindowWidth();
        testControllerPF.getHtmlResultsWindowWidth();
        testControllerPF.getHtmlResultsWindowHeight();
    }

    public static testMethod void testControllerPR() {
        Peer_Review__c testPR = new Peer_Review__c(Event_Date__c = Date.today());
        insert testPR;
        PageReference testPage = new PageReference('/apex/PeerReviewNotesDialog');
        Test.setCurrentPage(testPage);
        PeerReviewNotesDisplayController testControllerPR = new PeerReviewNotesDisplayController(new ApexPages.StandardController(testPR));
        testControllerPR.getHtmlResultsWindowSize();
        testControllerPR.getCount();
        testControllerPR.getStatus();
        testControllerPR.getCreated();
        testControllerPR.getDue();
        testControllerPR.getAvailableValues();
        testControllerPR.getCreatedDateSortValues();
        testControllerPR.getDisplayFormatValues();
        testControllerPR.getDomainURL();
        testControllerPR.getSearchSettings();
        testControllerPR.setAttachments(testControllerPR.getAttachments());
        testControllerPR.setTaskStatus(testControllerPR.getTaskStatus());
        testControllerPR.setDateCreated(testControllerPR.getDateCreated());
        testControllerPR.setDateDue(testControllerPR.getDateDue());
        testControllerPR.setNotesCount(testControllerPR.getNotesCount());
        testControllerPR.setAvailableValue(testControllerPR.getAvailableValue());
        testControllerPR.setContainsSearch(testControllerPR.getContainsSearch());
        testControllerPR.setCreatedDateSort(testControllerPR.getCreatedDateSort());
        testControllerPR.setDisplayFormat(testControllerPR.getDisplayFormat());
        Peer_Review_Notes__c[] testActivities = testControllerPR.getActivities();
        
        PageReference testRun = testControllerPR.run();
        Peer_Review__c testPR2 = testControllerPR.getPR();
        String htmlResultsEmbeddedLinkTargetTest = testControllerPR.getHtmlResultsEmbeddedLinkTarget();
        testControllerPR.getDialogWindowHeight();
        testControllerPR.getDialogWindowWidth();
        testControllerPR.getHtmlResultsWindowWidth();
        testControllerPR.getHtmlResultsWindowHeight();
    }

    public static testMethod void testControllerRCA() {
        Root_Cause_Analysis__c testRCA = new Root_Cause_Analysis__c(Date_of_Event__c = Date.today());
        insert testRCA;
        PageReference testPage = new PageReference('/apex/RCANotesDialog');
        Test.setCurrentPage(testPage);
        RCANotesDisplayController testControllerRCA = new RCANotesDisplayController(new ApexPages.StandardController(testRCA));
        testControllerRCA.getHtmlResultsWindowSize();
        testControllerRCA.getCount();
        testControllerRCA.getStatus();
        testControllerRCA.getCreated();
        testControllerRCA.getDue();
        testControllerRCA.getAvailableValues();
        testControllerRCA.getCreatedDateSortValues();
        testControllerRCA.getDisplayFormatValues();
        testControllerRCA.getDomainURL();
        testControllerRCA.getSearchSettings();
        testControllerRCA.setAttachments(testControllerRCA.getAttachments());
        testControllerRCA.setTaskStatus(testControllerRCA.getTaskStatus());
        testControllerRCA.setDateCreated(testControllerRCA.getDateCreated());
        testControllerRCA.setDateDue(testControllerRCA.getDateDue());
        testControllerRCA.setNotesCount(testControllerRCA.getNotesCount());
        testControllerRCA.setAvailableValue(testControllerRCA.getAvailableValue());
        testControllerRCA.setContainsSearch(testControllerRCA.getContainsSearch());
        testControllerRCA.setCreatedDateSort(testControllerRCA.getCreatedDateSort());
        testControllerRCA.setDisplayFormat(testControllerRCA.getDisplayFormat());
        RCA_Notes__c[] testActivities = testControllerRCA.getActivities();
        
        PageReference testRun = testControllerRCA.run();
        Root_Cause_Analysis__c testClaim2 = testControllerRCA.getRCA();
        String htmlResultsEmbeddedLinkTargetTest = testControllerRCA.getHtmlResultsEmbeddedLinkTarget();
        testControllerRCA.getDialogWindowHeight();
        testControllerRCA.getDialogWindowWidth();
        testControllerRCA.getHtmlResultsWindowWidth();
        testControllerRCA.getHtmlResultsWindowHeight();
    }
}