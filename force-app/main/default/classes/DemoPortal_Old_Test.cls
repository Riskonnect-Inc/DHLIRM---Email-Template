@isTest
private class DemoPortal_Old_Test {

    @testSetup static void setup() {

        Contact employee = new Contact(LastName = 'Doe', Birthdate = Date.valueOf('1999-3-4'));
        insert employee;

        Intake__c intake = new Intake__c(Incident_Date__c = Date.valueOf('2014-3-4'));
        insert intake;

    }

    private static void initCookie(){
        //In case encript/logic changes use PortalLogin to set up
        //but because current page is set in test, cookie will be applied there
        DemoLogin_Old_Controller plc = new DemoLogin_Old_Controller();

        // Good Login
        plc.userLastName = 'Doe';
        plc.userYearofBirth = 1999;
        plc.userMonthofBirth = 3;
        plc.userDayofBirth = 4;
        plc.validateSubmit();
    }

    @isTest static void testPortalLogin() {
        Test.setCurrentPage(new pageReference('Page.DemoLogin_Old'));
        DemoLogin_Old_Controller plc = new DemoLogin_Old_Controller();

        plc.checkValidity();

        // Fail Login
        plc.userLastName = 'Doe';
        plc.userYearofBirth = 1998;  //Bad Year
        plc.userMonthofBirth = 3;
        plc.userDayofBirth = 4;
        plc.validateSubmit();
        System.assertEquals('Invalid name or date of birth', plc.message);

        // Good Login
        plc.userLastName = 'Doe';
        plc.userYearofBirth = 1999;
        plc.userMonthofBirth = 3;
        plc.userDayofBirth = 4;
        plc.validateSubmit();

        //Recheck Validity for code coverage
        System.assertNotEquals(null, plc.checkValidity());

    }

    @isTest static void testIntakeController() {
        Test.setCurrentPage(new pageReference('Page.DemoPortal_Old'));
        DemoPortal_Old_Controller ic = new DemoPortal_Old_Controller(new rkl.JS_Search());

        //Fail Login
        ic.checkValidity();
        System.assertNotEquals(null, ic.checkValidity());

        //Check Good Login
        initCookie();
        System.assertEquals(null, ic.checkValidity());

        ic.getUIBuilderJS();

    }

    @isTest static void testIntakeControllerExistingRecord() {
        PageReference pg = new pageReference('Page.DemoPortal_Old');
        Test.setCurrentPage(pg);

        Intake__c intake = [select id from Intake__c limit 1];

        pg.getParameters().put('incID', intake.Id);

        DemoPortal_Old_Controller ic = new DemoPortal_Old_Controller(new rkl.JS_Search());

        System.assertEquals(intake.id, ic.id);
    }

    @isTest static void testIntakeLandingController() {
        Test.setCurrentPage(new pageReference('Demo_Portal_Landing'));
        DemoPortalLanding_Old_Controller icl = new DemoPortalLanding_Old_Controller(new rkl.JS_Search());

        //Fail Login
        icl.checkValidity();
        System.assertNotEquals(null, icl.checkValidity());

        //Check Good Login
        initCookie();
        System.assertEquals(null, icl.checkValidity());

    }

    @isTest static void testIntakeSummaryController() {
        PageReference pg = new PageReference('DemoPortalSummary_Old');
        Test.setCurrentPage(pg);

        Intake__c intake = [select id from Intake__c limit 1];

        pg.getParameters().put('incID', intake.Id);

        DemoPortalSummary_Old_Controller isc = new DemoPortalSummary_Old_Controller();

    }

}