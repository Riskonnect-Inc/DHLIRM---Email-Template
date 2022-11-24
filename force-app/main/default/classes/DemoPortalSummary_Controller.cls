public class DemoPortalSummary_Controller {

	private rkl.PortalSecurity security;
	public rkl.PortalSecurity.Portal_Settings portalSettings {get; private set;}

	public Intake__c incident {get; private set;}

    public DemoPortalSummary_Controller() {

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

		String incID = System.currentPagereference().getParameters().get('incId');

        if (this.security == null) {
            return Page.rkl__PortalSecurityGroupError;
        }

		if (!this.security.authorized) {
            PageReference loginPage = Page.rkl__PortalLogin;
            loginPage.getParameters().put('portalGroup', this.portalSettings.portalGroup);
            loginPage.getParameters().put('errMsg', this.security.errMessage);
            return loginPage;
		}

		List<Intake__c> intakes = [ SELECT Name FROM Intake__c WHERE Id =:incID ];
	    if(intakes.size() == 1){
	      incident = intakes[0];
	    }
		else {
			// Could do something here to return error message, but not necessarily needed
			// since this page is a direct result of a successfull add
		}

		return null;

    }
}