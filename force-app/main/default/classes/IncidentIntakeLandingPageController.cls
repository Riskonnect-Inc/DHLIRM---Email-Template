//RKDEV-10904 - Shrutika
public with sharing class IncidentIntakeLandingPageController{
    private rkl.PortalSecurity security;
    public rkl.PortalSecurity.Portal_Settings portalSettings {get; private set;}

    public Object pageData {get; private set;}

    public IncidentIntakeLandingPageController(rkl.JS_Search ignore) {
        try {
            // Get login definition from url parameter
            this.security = new rkl.PortalSecurity(ApexPages.currentPage().getParameters().get('portalGroup'));
        } catch (rkl.PortalSecurity.InvalidPortalGroupException e) {
            this.security = null;
            return; //could throw an error but would need to check how that works on vf pages
        }

        this.portalSettings = security.portalSettings;
    }

    public PageReference pageLoad() {
        if (this.security == null) {
            return Page.rkl__PortalSecurityGroupError;
        }

        if (!this.security.authorized) {
            PageReference loginPage = Page.rkl__PortalLogin;
            loginPage.getParameters().put('portalGroup', this.portalSettings.portalGroup);
            loginPage.getParameters().put('errMsg', this.security.errMessage);
            return loginPage;
        }
        this.init();
        return null;
    }

    @TestVisible 
    private void init() {
        String userID = this.security.personId;  //returns the logged in users ID.
        pageData = rkl.RKSearch.consumeConfig(new Map <String, Object> {
            'resultFields' => 'Landing_Results',   // Fieldset Name containing fields that needs to be displayed on the page
            'type' => 'unRelatedList',
            'objectApi' => 'Intake__c', //API name of the incident object
            'links' => false, //Setting the ‘links’ to true will enable the user to redirect to that particular incident record in the org
            'relOptions' => new Map <String, Object> {'del' => false, 'edit' => true},  //setting ‘del’ to true will enable the users to delete the incomplete incidents from the landing page
            'title' => 'List of your incomplete incident reports',
            //'baseCondition' => '(im_status__c != \'Void\' AND im_status__c !=\'Converted\' AND im_status__c !=\'Closed\') AND reported_by_contact__c =\''+userId+'\''  
             'baseCondition' => 'reported_by_contact__c =\''+userId+'\''
        });

        pageData = JSON.serialize(pageData);
    }
}
//RKDEV-10904 - Shrutika