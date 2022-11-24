public class AddEntity_Controller extends rkl.RKPortalController_2{
    
    private rkl.PortalSecurity security;

    public rkl.PortalSecurity.Portal_Settings portalSettings {get; private set;}
    public String userId {get; private set;}

    public AddEntity_Controller(){this(null);}
    public AddEntity_Controller(rkl.JS_Search ign){
        System.debug(ApexPages.currentPage().getParameters().get('portalGroup'));
        System.debug(JSON.serialize(ApexPages.currentPage().getCookies().keyset()));
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
        this.userId = this.security.personId;
        return null;
    }

    @RemoteAction
    public static Object retrieveTemplate(Map<String, Object> config) {

        //Pull template name from config and do something with it
        String templateName = (String)config.get('templateName');
        if(templateName=='property'){
            return rkl.RKPBuilder.createBuilder('property','Property__c')
                .fieldsetSection('Renewal_New_Property', '')
           .finalize();
        } else if(templateName=='hierarchy'){
            return rkl.RKPBuilder.createBuilder('hierarchy','rkl__RK_Hierarchy_Node__c')
                .fieldsetSection('Renewal_New_Hierarchy', '')
           .finalize();
        }
        return null;
    }

    @RemoteAction
    public static Object kickOffAddEntity(Id renewalControlId, Id renewalHierarchyId, Id newEntityId){
        rkl.AssignmentGenerator.AddedEntityRequest addEntityRequest = new rkl.AssignmentGenerator.AddedEntityRequest()
            .control(renewalControlId)
            .orgLevel(renewalHierarchyId)
            .entity(newEntityId);

        rkl.AssignmentGenerator.kickoffAddedEntity(addEntityRequest);

        return new Map<String, Boolean>{'success' => true};
    }

    @RemoteAction
    public static Object pollAddEntityProcess(Id renewalControlId, Id renewalHierarchyId, Id newEntityId){
        rkl.AssignmentGenerator.EntityStatus entityStatus = rkl.AssignmentGenerator.getEntityStatus(new rkl.AssignmentGenerator.AddedEntityRequest()
            .control(renewalControlId)
            .orgLevel(renewalHierarchyId)
            .entity(newEntityId));
        return new Map<String, String> {
            'statusCode' => entityStatus.statusCode
        };
    }

}