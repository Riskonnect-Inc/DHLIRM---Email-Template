public class DemoPortalLanding_Controller {

    private rkl.PortalSecurity security;
    public rkl.PortalSecurity.Portal_Settings portalSettings {get; private set;}

    public Object pageData {get; private set;}
	public Boolean showLogout {get; private set;}
	private Boolean links {get; set;}

    public DemoPortalLanding_Controller(rkl.JS_Search ignore) {

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

        //Set options based on the login type first
		if (UserInfo.getUserType() == 'Standard' && String.isNotBlank(UserInfo.getSessionId()) && String.isNotBlank(UserInfo.getUserId())) {
			this.links = true;
			this.showLogout = false;
		} else {  //Change this if different object is used for user login
			this.links = false;
			this.showLogout = true;
		}

        this.init();

        return null;

    }

    private void init(){
        pageData = rkl.RKSearch.consumeConfig(new Map<String, Object>{
            'resultFields' => 'Landing_Results',
            'type' => 'unRelatedList',
            'objectApi' => 'Intake__c',
            'links' => this.links,
            'relOptions' => new Map<String,Object>{'del' => false},
            'title' => 'List of your incomplete incident reports',
            'baseCondition' => 'im_status__c != \'Completed\''
        });

        pageData = JSON.serialize(pageData);

    }

}