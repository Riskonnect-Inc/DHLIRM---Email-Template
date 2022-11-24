@isTest
private class DemoPortal_Test {

	@testSetup static void setup() {

		Contact employee = new Contact(LastName = 'Doe', Birthdate = Date.valueOf('1999-3-4'));
        insert employee;

        Intake__c intake = new Intake__c(Incident_Date__c = Date.valueOf('2014-3-4'));
        insert intake;

		rkl__RK_Portal_Settings__c portalSettings = new rkl__RK_Portal_Settings__c(Name = 'testGroup', rkl__Security_Object__c = 'User', rkl__Security_Fieldset__c = 'Dummy', rkl__Landing_Page__c='/');
		insert portalSettings;

		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
      	User u = new User(Alias = 'standt', Email='standardrkuser@testrk.com',
      		EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
      		LocaleSidKey='en_US', ProfileId = p.Id,
      		TimeZoneSidKey='America/Los_Angeles', UserName='standardrkuser@testrk.com');
      	System.runAs(u) {

      }


	}

    private static void initCookie(){
        //In case encript/logic changes use PortalLogin to set up
        //but because current page is set in test, cookie will be applied there
        //rkl.PortalLogin_Controller plc = new rkl.PortalLogin_Controller();

        // Good Login
        //plc.userLastName = 'Doe';
        //plc.userYearofBirth = 1999;
        //plc.userMonthofBirth = 3;
        //plc.userDayofBirth = 4;
        //plc.validateSubmit();
    }


    @isTest static void testPortalPage() {
		PageReference pg = new pageReference('Page.DemoPortal');
        Test.setCurrentPage(pg);

		Intake__c intake = [select id from Intake__c limit 1];

		//Test bad security group i.e. not set yet
		DemoPortal_Controller badpc = new DemoPortal_Controller(new rkl.JS_Search());

        pg.getParameters().put('incID', intake.Id);
		pg.getParameters().put('portalGroup', 'testGroup');

		DemoPortal_Controller pc = new DemoPortal_Controller(new rkl.JS_Search());

        pc.pageLoad();  // Test page load, only test User type security

		// Test templates
		String[] templates = new String[]{
			'demoTemplate', 'Employee_Injury', 'Auto_Non_Employee_Injury',
			'Auto_Non_Employee_Property_Damage', 'Auto_Company_Vehicle',
			'X3rd_Party_Bodily_Injury', 'X3rd_Party_Property_Damage', 'Company_Property_Damage',
			'badun'};

		for (String template: templates) {
			DemoPortal_Controller.retrieveTemplate(new Map<String, Object>{'templateName' => template});

		}
    }


    @isTest static void testLandingController() {
		PageReference pg = new pageReference('Page.DemoPortalLanding');
        Test.setCurrentPage(pg);

		// Test bad portal group i.e. not currently set
		DemoPortalLanding_Controller badlc = new DemoPortalLanding_Controller(new rkl.JS_Search());

		pg.getParameters().put('portalGroup', 'testGroup');

		DemoPortalLanding_Controller lc = new DemoPortalLanding_Controller(new rkl.JS_Search());

		lc.pageLoad();


    }

    @isTest static void testSummaryController() {
        PageReference pg = new PageReference('Page.DemoPortalSummary');
        Test.setCurrentPage(pg);

		DemoPortalSummary_Controller badsc = new DemoPortalSummary_Controller();

		Intake__c intake = [select id from Intake__c limit 1];

        pg.getParameters().put('incID', intake.Id);
		pg.getParameters().put('portalGroup', 'testGroup');


        DemoPortalSummary_Controller sc = new DemoPortalSummary_Controller();

		sc.pageLoad();

    }

}