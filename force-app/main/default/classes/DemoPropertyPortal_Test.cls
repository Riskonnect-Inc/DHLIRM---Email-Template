@isTest
private class DemoPropertyPortal_Test {
	public DemoPropertyPortal_Test() {

	}

	@testSetup static void setup() {

		Contact employee = new Contact(LastName = 'Doe', Birthdate = Date.valueOf('1999-3-4'));
        insert employee;

        Property__c property = new Property__c(Property_ID__c = '1234');
        insert property;

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


    @isTest static void testPropertyPortalPage() {
		PageReference pg = new pageReference('Page.DemoPropertyPortal');
        Test.setCurrentPage(pg);

		Property__c property = [select id from Property__c limit 1];

		//Test bad security group i.e. not set yet
		DemoPropertyPortal_Controller badpc = new DemoPropertyPortal_Controller(new rkl.JS_Search());

        pg.getParameters().put('incID', property.Id);
		pg.getParameters().put('portalGroup', 'testGroup');

		DemoPropertyPortal_Controller pc = new DemoPropertyPortal_Controller(new rkl.JS_Search());

        pc.pageLoad();  // Test page load, only test User type security

		// Test templates
		String[] templates = new String[]{
			'propertyTemplate', 'badun'};

		for (String template: templates) {
			DemoPropertyPortal_Controller.retrieveTemplate(new Map<String, Object>{'templateName' => template});

		}
    }

    @isTest static void testPropertyLandingController() {
		PageReference pg = new pageReference('Page.DemoPropertyPortalLanding');
        Test.setCurrentPage(pg);

		// Test bad portal group i.e. not currently set
		DemoPropertyPortalLanding_Controller badlc = new DemoPropertyPortalLanding_Controller(new rkl.JS_Search());

		pg.getParameters().put('portalGroup', 'testGroup');

		DemoPropertyPortalLanding_Controller lc = new DemoPropertyPortalLanding_Controller(new rkl.JS_Search());

		lc.pageLoad();

    }

	@isTest static void testPropertyCreatePortalPage() {
		PageReference pg = new pageReference('Page.DemoPropertyCreatePortal');
        Test.setCurrentPage(pg);

		Property__c property = [select id from Property__c limit 1];

		//Test bad security group i.e. not set yet
		DemoPropertyCreatePortal_Controller badpc = new DemoPropertyCreatePortal_Controller(new rkl.JS_Search());

        pg.getParameters().put('incID', property.Id);
		pg.getParameters().put('portalGroup', 'testGroup');

		DemoPropertyCreatePortal_Controller pc = new DemoPropertyCreatePortal_Controller(new rkl.JS_Search());

        pc.pageLoad();  // Test page load, only test User type security

		// Test templates
		String[] templates = new String[]{
			'createPropertyTemplate', 'badun'};

		for (String template: templates) {
			DemoPropertyCreatePortal_Controller.retrieveTemplate(new Map<String, Object>{'templateName' => template});

		}
    }

}