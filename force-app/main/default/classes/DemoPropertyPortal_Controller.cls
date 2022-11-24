public with sharing class DemoPropertyPortal_Controller extends rkl.RKPortalController_2{

    public Contact employee {get; private set;}

    public String recordId {get; private set;}

    private rkl.PortalSecurity security;
    public rkl.PortalSecurity.Portal_Settings portalSettings {get; private set;}


    public DemoPropertyPortal_Controller(rkl.JS_Search ign) {

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

        return null;

    }

    @RemoteAction
    public static Object retrieveTemplate(Map<String, Object> config) {

        //Pull template name from config and do something with it
        String templateName = (String)config.get('templateName');

        // Template Definitions
        if (templateName == 'propertyTemplate') {   // Main Template
            return rkl.RKPBuilder.createBuilder('Property', 'Property__c')
				.fieldSetSection('PVC_Property_Information', 'Property Information')
				.fieldSetSection('PVC_COPE', 'COPE')
				.valuesSection('PVC_Values', 'Property Value Collection', 'Property_Value__c')
                    .addColumn('prior_property_value__c', 'Previous', true) //must be lower case
                    .addColumn('current_property_value__c', 'Current', false) //must be lower case
                    .configure()
	                    .put('Finder', 'rkl.portal.ui.CmtCommentFieldFinder')
	                	.sub('cfConfig')	// Empty Config
                        .subdone()
                    .done()
                    .configure()
                        .put('Validator', 'rkl.portal.ui.ControlRecordValidator')
                    	.sub('cvConfig')
                        	.put('controlRecordName', 'property_value_control__c')
                        	.put('controlFieldName', 'property_value_control__c')
							.put('minimumThresholdFieldName', 'change_threshold__c')
                        .subdone()
                    .done()
                    .fieldSet('PVC_Values')
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