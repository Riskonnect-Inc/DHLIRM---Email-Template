//RKDEV-10904 - Shrutika
public class IncidentIntakePageController extends rkl.RKPortalController_2 {

    public Contact employee {get; private set;}
    public String recordId {get; private set;}
    private rkl.PortalSecurity security;
    public rkl.PortalSecurity.Portal_Settings portalSettings {get; private set;}

    public IncidentIntakePageController (rkl.JS_Search ign) {
    // Get the record ID from the URL
        recordId = System.currentPagereference().getParameters().get('incId');
        if (recordId != null && recordId.trim() == '') {
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

/*This method will run when  the page loads*/
    public PageReference pageLoad() {
        if (this.security == null) {
            return Page.rkl__PortalSecurityGroupError;
        }
        if (!this.security.authorized) {
            PageReference loginPage = Page.rkl__PortalLogin;
            loginPage.getParameters().put('portalGroup', this.security.portalSettings.portalGroup);
            loginPage.getParameters().put('errMsg', this.security.errMessage);
            return loginPage;
        }
  
        List<Contact> contacts = [SELECT Id, FirstName, MobilePhone, Phone, Email, LastName, Employee_ID__c FROM Contact WHERE Id = :this.security.personId ];

        if (contacts.size() == 1 && recordId == null) {
            employee = contacts[0];  // Only set employee details for first record
        }

        return null;
    }

    @RemoteAction
    public static Object retrieveTemplate(Map<String, Object> config) {
        String templateName = String.valueOf(config.get('templateName'));

        String contactRecordTypeId = '';
        List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND Name = 'Employee'];
        if (recordTypes.size() == 1) {
            contactRecordTypeId = recordTypes[0].id;
        }
        if (templateName == 'intakeTemplate') {
            return intakeTemplate();
        } 
        else {
            return null;
        }
        
    }
    
     public static Object intakeTemplate() {
        return rkl.RKPBuilder.createBuilder('intakeTemplate', 'Intake__c')
            .fieldSetSection('Claim_Information', 'Claim Information')
            .configureMember('business_unit__c')
                .put('searchFields','Intake_Location_Lookup_Grid')
                .put('resultFields', 'Intake_Location_Results_Grid')
                .put('baseCondition', 'rkl__Node_Level__c= 5')
                .done()
            .fieldSetSection('Description_of_Event', 'Description of Event')
            .fieldSetSection('Shipment_Information', 'Shipment Information')
            .configureMember('origin__c')
                .put('searchFields','Intake_Country_Lookup_Grid')
                .put('resultFields', 'Intake_Country_Results_Grid')
                .done()
            .configureMember('destination__c')
                .put('searchFields','Intake_Country_Lookup_Grid')
                .put('resultFields', 'Intake_Country_Results_Grid')
                .done()
            .fieldSetSection('Claimant', 'Claimant')
            .configureMember('customer__c')
                .put('searchFields','Intake_Account_Lookup_Grid')
                .put('resultFields', 'Intake_Account_Results_Grid')
                .put('baseCondition', 'RecordType.Name ="Customer"')  
                .done()
            .fieldSetSection('Responsible_Party', 'Responsible Party')
            .configureMember('sub_contractor__c')
                .put('searchFields','Intake_Account_Lookup_Grid')
                .put('resultFields', 'Intake_Account_Results_Grid')
                .put('baseCondition', 'RecordType.Name ="Sub-contractor"')  
                .done()
            .section('Submit')
                .plainText('Submit_Instructions_1', 'Please review all preceding sections before clicking the \"Submit\" button below.')
                .plainText('Submit_Instructions_2', 'You will be unable to change your provided answers once \"Submit\" is clicked.')
            //For Attachments
                .attach('Attachments')
                .finalize();
    }
}
//RKDEV-10904 - Shrutika