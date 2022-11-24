public class DemoPortal_Controller extends rkl.RKPortalController_2{

    public Contact employee {get; private set;}

    public String recordId {get; private set;}

    private rkl.PortalSecurity security;
    public rkl.PortalSecurity.Portal_Settings portalSettings {get; private set;}


    public DemoPortal_Controller(rkl.JS_Search ign) {

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

        List<Contact> contacts = [SELECT Id, Site_Access_Approved__c, FirstName, LastName, Phone, Location__c FROM Contact WHERE Id=:this.security.personId];
        if(contacts.size()==1 && recordId == null) {
            employee = contacts[0];  // Only set employee details for first record
        }

        return null;

    }

    @RemoteAction
    public static Object retrieveTemplate(Map<String, Object> config) {

        //Pull template name from config and do something with it
        String templateName = (String)config.get('templateName');

        // Retrieve Contact.Employee RecordTypeId for two lookup searches below
        String contactRecordTypeId = '';
        List<RecordType> recordTypes = [select id from RecordType where sobjecttype = 'Contact' and name = 'Employee'];
        if (recordTypes.size() == 1) {
            contactRecordTypeId = recordTypes[0].id;
        }

        // Template Definitions
        if (templateName == 'demoTemplate') {   // Main Template
            return demoTemplate();
        } else if (templateName == 'Employee_Injury') {   //Additional Templates
            return rkl.RKPBuilder.createBuilder('Employee_Injury', 'Intake_Detail__c', 'Employee_Injury')
                .fieldsetSection('Employee_Injuries_Injuries', 'Injuries')
                    .addFieldBefore('injured_employee__c', 'involved_party_name__c')
                    .pop()  // Or put addFieldBefore after configureMember done() below which pops you automatically back to fieldset
                    .configureMember('injured_employee__c')
                        .put('searchFields', new String[]{'Employee_ID__c', 'FirstName', 'LastName'})
                        .put('resultFields', 'Intake_Contact_Lookup_Grid')
                        .put('baseCondition', 'RecordTypeId = \'' + contactRecordTypeId +'\'')  //new rkl.GS_Soql.fieldCondition('RecordTypeId').EqualToVal(contactRecordTypeId))
                        .sub('mixin')
                            .put('src','Intake_Contact_Injured_Employee')
                            .put('dst','Intake_Detail_Injured_Employee')
                        .subdone()
                    .done()

                .fieldsetSection('Employee_Injury_OSHA', 'OSHA')
            .finalize();

        } else if (templateName == 'Auto_Non_Employee_Injury') {
            return rkl.RKPBuilder.createBuilder('Auto_Non_Employee_Injury', 'Intake_Detail__c', 'X3rd_Party_Auto_Bodily_Injury')
                .fieldsetSection('X3rd_Party_Auto_Bodily_Injury_Injuries', 'Auto Non Employee Injury')
            .finalize();

        } else if (templateName == 'Auto_Non_Employee_Property_Damage') {
            return rkl.RKPBuilder.createBuilder('Auto_Non_Employee_Property_Damage', 'Intake_Detail__c', 'X3rd_Party_Auto_Damage')
                .section('Auto_Non_Employee_Property_Damage', 'Auto Non Employee Property Damage')
                    .fieldset('X3rd_Party_Auto_Damage_3rd_Party_Vehicle')
                    .fieldset('X3rd_Party_Auto_Bodily_Injury_3rd_Party')
                .finalize();

        } else if (templateName == 'Auto_Company_Vehicle') {
            return rkl.RKPBuilder.createBuilder('Auto_Company_Vehicle', 'Intake_Detail__c', 'Company_Auto_Damage')
                .section('Auto_Company_Vehicle', 'Auto Company Vehicle')
                    .fieldset('Company_Auto_Damage_Company_Driver')
                        .configureMember('Company_Driver__c')
                            .put('searchFields', new String[]{'Employee_ID__c', 'FirstName', 'LastName'})
                            .put('resultFields', 'Intake_Contact_Lookup_Grid')
                            .put('baseCondition', 'RecordTypeId = \'' + contactRecordTypeId +'\'')  //new rkl.GS_Soql.fieldCondition('RecordTypeId').EqualToVal(contactRecordTypeId))
                            .sub('mixin')
                                .put('src','Intake_Contact_Company_Driver')
                                .put('dst','Intake_Detail_Company_Driver')
                            .subdone()
                        .done()
                    .fieldset('Company_Auto_Damage_Company_Vehicle')
                        .configureMember('Company_Vehicle_Lookup__c')
                            .put('searchFields', new List<String>{'Fleet_Number__c', 'Plate_Number__c', 'Plate_State__c', 'Make__c', 'Model__c'})
                            .put('resultFields', 'Intake_Vehicle_Lookup_Grid')
                            .sub('mixin')
                                .put('src','Intake_Asset_Company_Vehicle')
                                .put('dst','Intake_Detail_Company_Vehicle')
                            .subdone()
                        .done()
                .finalize();

        } else if (templateName == 'X3rd_Party_Bodily_Injury') {
            return rkl.RKPBuilder.createBuilder('3rd_Party_Bodily_Injury', 'Intake_Detail__c', 'X3rd_Party_Bodily_Injury')
                .fieldsetSection('X3rd_Party_Bodily_Injury_Injuries', '3rd Party Bodily Injury')
                .fieldsetSection('Product_Information', 'Product Information')
                    .configureMember('Product__c')
                        .put('searchFields', new List<String>{'Product_Name__c', 'SKU__c'})
                        .put('resultFields', 'Product_Lookup_Grid')
                    .done()
            .finalize();

        } else if (templateName == 'X3rd_Party_Property_Damage') {
            return rkl.RKPBuilder.createBuilder('3rd_Party_Property_Damage', 'Intake_Detail__c', 'X3rd_Party_Property_Damage')
                .fieldsetSection('X3rd_Party_Property_Damage_Property_Dama', '3rd Party Property Damage')
                .fieldsetSection('Product_Information', 'Product Information')
                    .configureMember('Product__c')
                        .put('searchFields', new List<String>{'Product_Name__c', 'SKU__c'})
                        .put('resultFields', 'Product_Lookup_Grid')
                    .done()
                .fieldsetSection('Property_Information', 'Property Information')
            .finalize();

        } else if (templateName == 'Company_Property_Damage') {
            return rkl.RKPBuilder.createBuilder('Company_Property_Damage', 'Intake_Detail__c', 'Company_Property_Damage')
                .fieldsetSection('Company_Property_Damage_Company_Property', 'Company Property Damage')
                    .configureMember('Company_Property__c')
                        .put('searchFields', new List<String>{'Property_ID__c', 'Name', 'Address_Line1__c', 'Address_Line2__c', 'city__c', 'state__c', 'country__c'})
                        .put('resultFields', 'Intake_Property_Lookup_Grid')
                    .done()
                .finalize();

        } else {
            return null;
        }  // End template definitions

    }


    public static Object demoTemplate() {

        return rkl.RKPBuilder.createBuilder('demoTemplate','Intake__c')
            .fieldsetSection('Intake_Description', 'General Incident Details')
                .configureMember('Incident_Location__c')
                    .put('searchFields', new String[]{'rkl__Node_Code__c', 'rkl__Node_Name__c', 'rkl__city__c', 'rkl__state__c', 'rkl__country__c'})
                    .put('resultFields', 'Intake_Location_Lookup_Grid')
                    .put('selectionValue', 'rkl__Node_Name__c')
                .done()
            .fieldsetSection('Involved_Parties', 'Involved Parties')
            .relatedSection('Employee_Injury','Employee Injury','Employee_Injury','Intake_Detail__c','intake__c')
            .section('Auto_Non_Employee_Injury', 'Auto Non Employee Injury')
                .relatedList('Auto_Non_Employee_Injury','Auto Non-Employee Injuries','Auto_Non_Employee_Injury','Intake_Detail__c','intake__c')
                    .configure()
                        .put('recordType', 'X3rd_Party_Auto_Bodily_Injury')
                        .put('resultFields','X3rd_Party_Auto_Bodily_Injury_List')
                        .sub('recordAmounts')
                                .put('min', '1')
                                .put('max', '2')
                        .subdone()
                    .done()
            .section('Auto_Non_Employee_Property_Damage', 'Auto Non Employee Property Damage')
                .relatedList('Auto_Non_Employee_Property_Damage','Auto Non-Employee Property Damage','Auto_Non_Employee_Property_Damage','Intake_Detail__c','intake__c')
                    .configure()
                        .put('recordType', 'X3rd_Party_Auto_Damage')
                        .put('resultFields','X3rd_Party_Auto_Damage_List')
                        .sub('recordAmounts')
                                .put('min', '1')
                                .put('max', '2')
                        .subdone()
                    .done()
            .section('Auto_Company_Vehicle', 'Auto Company Vehicle')
                .relatedList('Auto_Company_Vehicle','Auto Company Vehicle','Auto_Company_Vehicle','Intake_Detail__c','intake__c')
                    .configure()
                        .put('recordType', 'Company_Auto_Damage')
                        .put('resultFields','Company_Auto_Damage_List')
                        .sub('recordAmounts')
                                .put('min', '1')
                                .put('max', '2')
                        .subdone()
                    .done()
            .relatedSection('3rd_Party_Bodily_Injury','3rd Party Bodily Injury','X3rd_Party_Bodily_Injury','Intake_Detail__c','intake__c')
            .relatedSection('3rd_Party_Property_Damage','3rd Party Property Damage','X3rd_Party_Property_Damage','Intake_Detail__c','intake__c')
            .relatedSection('Company_Property_Damage','Company Property Damage','Company_Property_Damage','Intake_Detail__c','intake__c')
            .fieldsetSection('Near_Miss', 'Near Miss')
            .fieldsetSection('Witnesses')
            .section('Submit')
                .plainText('Submit_Instructions_1', 'Please review all preceding sections before clicking the \"Submit\" button below.')
                .plainText('Submit_Instructions_2', 'You will be unable to change your provided answers once \"Submit\" is clicked.')
                .attach('Attachments')
       .finalize();

    }

}