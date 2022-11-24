public with sharing class DemoPropertyCreatePortal_Controller extends rkl.RKPortalController_2 {

	public Contact employee {get; private set;}
	public String emailAddress {get; set;}

    public String recordId {get; private set;}

    private rkl.PortalSecurity security;
    public rkl.PortalSecurity.Portal_Settings portalSettings {get; private set;}


    public DemoPropertyCreatePortal_Controller(rkl.JS_Search ign) {

        recordId = System.currentPagereference().getParameters().get('incId');
        if(recordId != null && recordId.trim() == '') {
            recordId = null;
        }

        try {
            // Get login definition from url parameter
            this.security = new rkl.PortalSecurity(ApexPages.currentPage().getParameters().get('portalGroup'));
        } catch (rkl.PortalSecurity.InvalidPortalGroupException e) {
            this.security = null;
            return;
        }

        this.portalSettings = security.portalSettings;

    }

    public PageReference pageLoad(){

        if (this.security == null) {
            return Page.rkl__PortalSecurityGroupError;
        }

        if (!this.security.authorized) {
            PageReference loginPage = Page.rkl__PortalLogin;
            loginPage.getParameters().put('portalGroup', this.security.portalSettings.portalGroup);
            loginPage.getParameters().put('errMsg', this.security.errMessage);
            return loginPage;
        }

        //Set email key but check the login type first
		if (UserInfo.getUserType() == 'Standard' && String.isNotBlank(UserInfo.getSessionId()) && String.isNotBlank(UserInfo.getUserId())) {
			this.emailAddress = UserInfo.getUserEmail();
			System.debug(this.emailAddress);
		} else {  //Change this if different object is used for user login
			List<Contact> contacts = [SELECT Email FROM Contact WHERE Id=:this.security.personId];
			if(contacts.size()==1) {
	            this.emailAddress = contacts[0].Email;
	        }
		}

        return null;

    }

    @RemoteAction
    public static Object retrieveTemplate(Map<String, Object> config) {

        //Pull template name from config and do something with it
        String templateName = (String)config.get('templateName');

        // Template Definitions
        if (templateName == 'createPropertyTemplate') {   // Main Template
            return rkl.RKPBuilder.createBuilder('Property', 'Property__c')
				.fieldSetSection('New_Property_Information', 'Property Information')
				.fieldSetSection('PVC_COPE', 'COPE')
				.section('Submit')
	                .plainText('Submit_Instructions_1', 'Please review all preceding sections before clicking the \"Submit\" button below.')
	                .plainText('Submit_Instructions_2', 'You will be unable to change your provided answers once \"Submit\" is clicked.')
	                .attach('Attachments')
        	.finalize();

        } else {
            return null;
        }  // End template definitions

    }
}