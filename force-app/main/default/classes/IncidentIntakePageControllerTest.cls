//RKDEV-10904 - Shrutika
@isTest
public class IncidentIntakePageControllerTest{
    @testSetup
    static void setup() {
        rkl__RK_Portal_Settings__c portalSettings = new rkl__RK_Portal_Settings__c(Name = 'testGroup', rkl__Security_Object__c = 'Contact', rkl__Security_Fieldset__c = 'Dummy', rkl__Landing_Page__c='/');
        insert portalSettings;
        Intake__c intake = new Intake__c(Incident_Date__c = Date.valueOf('2014-3-4'));
        insert intake;
    }
    @isTest
    static void methodone() {
        PageReference pg = new PageReference('Page.IncidentIntakePage');
        Test.setCurrentPage(pg);
        Intake__c intakeTest = [select id from Intake__c limit 1];
        Contact con = new Contact();
        con.lastname = 'test';
        insert con;
        IncidentIntakePageController badipc = new IncidentIntakePageController(new rkl.JS_Search());
        pg.getParameters().put('incID', intakeTest.Id);
        IncidentIntakePageController ipc = new IncidentIntakePageController(new rkl.JS_Search());
        ipc.pageLoad();  // Test page load, only test User type security
        // Test templates
        String[] templates = new String[]{
            'intakeTemplate'
                };
                    
                    for (String template: templates) {
                        IncidentIntakePageController.retrieveTemplate(new Map<String, Object>{'templateName' => template});
                        
                    }
    }
    @isTest
    static void methodonetwo() {
        PageReference pg = new PageReference('Page.IncidentIntakePage');
        Test.setCurrentPage(pg);
        Intake__c intakeTest = [select id from Intake__c limit 1];
        IncidentIntakePageController badipc = new IncidentIntakePageController(new rkl.JS_Search());
        pg.getParameters().put('incID', '');
        IncidentIntakePageController ipc = new IncidentIntakePageController(new rkl.JS_Search());
        ipc.pageLoad();  // Test page load, only test User type security
        // Test templates
        String[] templates = new String[]{
            'intakeTemplate13'
                };
                    
                    for (String template: templates) {
                        IncidentIntakePageController.retrieveTemplate(new Map<String, Object>{'templateName' => template});
                        
                    }
    }
    @isTest
    static void methodtwo() {
        PageReference pg = new pageReference('Page.IncidentIntakeLandingPage');
        Test.setCurrentPage(pg);
        // Test bad portal group i.e. not currently set
        IncidentIntakeLandingPageController badlc = new IncidentIntakeLandingPageController(new rkl.JS_Search());
        pg.getParameters().put('portalGroup', 'testGroup');
        IncidentIntakeLandingPageController lc = new IncidentIntakeLandingPageController(new rkl.JS_Search());
        lc.pageLoad();
        lc.init();
    }
    @isTest
    static void methodtwotwo() {
        PageReference pg = new pageReference('Page.IncidentIntakeLandingPage');
        Test.setCurrentPage(pg);
        // Test bad portal group i.e. not currently set
        IncidentIntakeLandingPageController badlc = new IncidentIntakeLandingPageController(new rkl.JS_Search());
        pg.getParameters().put('portalGroupa', 'testGroup');
        IncidentIntakeLandingPageController lc = new IncidentIntakeLandingPageController(new rkl.JS_Search());
        lc.pageLoad();
        //lc.init();
    }
}
//RKDEV-10904 - Shrutika