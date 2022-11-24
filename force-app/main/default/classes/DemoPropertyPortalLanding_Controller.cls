public with sharing class DemoPropertyPortalLanding_Controller {

	private rkl.PortalSecurity security;
    public rkl.PortalSecurity.Portal_Settings portalSettings {get; private set;}

    public Object renewData {get; private set;}
	public Object propertyData {get; private set;}
	public Boolean showLogout {get; private set;}

	private String emailAddress {get; set;}
	private Boolean links {get; set;}

    public DemoPropertyPortalLanding_Controller(rkl.JS_Search ignore) {

        try {
            // Get login definition from url parameter
            this.security = new rkl.PortalSecurity(ApexPages.currentPage().getParameters().get('portalGroup'));
        } catch (rkl.PortalSecurity.InvalidPortalGroupException e) {
            this.security = null;
            return;  //could throw an error but would need to check how that works on vf pages
        }

        this.portalSettings = security.portalSettings;

    }

    public PageReference pageLoad(){

        if (this.security == null) {
            return Page.rkl__PortalSecurityGroupError;
        }

        if (!this.security.authorized) {
            PageReference loginPage = Page.rkl__PortalLogin;
            loginPage.getParameters().put('portalGroup', this.portalSettings.portalGroup);
            loginPage.getParameters().put('errMsg', this.security.errMessage);
            return loginPage;
        }

		//Set email key but check the login type first
		if (UserInfo.getUserType() == 'Standard' && String.isNotBlank(UserInfo.getSessionId()) && String.isNotBlank(UserInfo.getUserId())) {
			this.emailAddress = UserInfo.getUserEmail();
			this.links = true;
			this.showLogout = false;
		} else {  //Change this if different object is used for user login
			List<Contact> contacts = [SELECT Email FROM Contact WHERE Id=:this.security.personId];
			if(contacts.size()==1) {
	            this.emailAddress = contacts[0].Email;
	        }
			this.links = false;
			this.showLogout = true;
		}

        this.init();

        return null;

    }

    private void init() {
		renewData = JSON.serialize(
			rkl.RKSearch.consumeConfig (new Map<String, Object>{
	            'resultFields' => 'PVC_Landing_Grid_Pending',
	            'type' => 'unRelatedList',
	            'objectApi' => 'Property__c',
	            'links' => this.links,
	            'relOptions' => new Map<String,Object>{'del' => false, 'add' => false},
	            'title' => 'List of your properties ready for renewal',
	            'baseCondition' => 'values_collection_Email__c = "' + this.emailAddress + '" AND Values_Collection_Flag__c = true AND PVC_Status__c != "Completed"'
	        })
		);

		propertyData = JSON.serialize(
			rkl.RKSearch.consumeConfig (new Map<String, Object>{
	            'resultFields' => 'PVC_Landing_Grid',
	            'type' => 'unRelatedList',
	            'objectApi' => 'Property__c',
	            'links' => this.links,
	            'relOptions' => new Map<String,Object>{'del' => false, 'edit' => false},
	            'title' => 'List of properties assigned to you, click + to add a new property',
	            'baseCondition' => 'values_collection_Email__c = "' + this.emailAddress + '"'
	        })
		);
	}
}