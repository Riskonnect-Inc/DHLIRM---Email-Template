public class DemoPortal_Old_Controller extends rkl.RKPortalController_2 {

    public Contact employee {get; private set;}

    private String contactRecordTypeId {get; set;}

    public String id {get; private set;}
    public String language {get; private set;}

    public DemoPortal_Old_Controller(rkl.JS_Search ign) {

        contactRecordTypeId = [select id from RecordType where sobjecttype = 'Contact' and name = 'Employee'].id;
        /*language = ApexPages.currentPage() != null ? ApexPages.currentPage().getHeaders().get('Accept-Language') : 'EN';
        if(language.indexOf(',') >= 0) {
            language = language.substring(0, language.indexOf(','));
        }*/

        id = System.currentPagereference().getParameters().get('incId');
        if(id != null && id.trim() == '') {
            id = null;
        }

    }

    public PageReference checkValidity() {
        if(authViaCookie()){
              // Passed so no redirect
              return null;
          } else {
              return Page.DemoLogin_Old;
          }
    }


    private Boolean authViaCookie(){
        Cookie cookieToken = ApexPages.currentPage().getCookies().get('TokenRK');
        if(cookieToken!=null){
            String cookieVal = decryptCookie(EncodingUtil.base64Decode(cookieToken.getValue()));
            List<String> cookieVals = cookieVal.split('!,!');
            Integer timeLengthValid = cookieToken.getMaxAge();//maybe should be hardcoded to avoid cookie tampering
            Datetime createdDate = Datetime.valueOfGmt(cookieVals[1]).addSeconds(timeLengthValid);
            if(createdDate<=Datetime.now()){
                List<Contact> contacts = [SELECT Id, Site_Access_Approved__c, FirstName, LastName, Phone, Location__c FROM Contact WHERE Id=:cookieVals[0]];
                if(contacts.size()==1 /*&& contacts[0].Site_Access_Approved__c==true*/){
                    if(id == null){
                        employee = contacts[0];
                    }
                    return true;
                }
            }
        }

        return false;
    }

    private String decryptCookie(Blob val){
        return Crypto.decrypt('AES128',Blob.valueOf('INeedSixTeenChar'),Blob.valueOf('INeedSixTeenChar'),val).toString();
    }

    public rkl.RKPortalBuilder.Section section(String name, String label, List<String> fieldSetNames) {
        rkl.RKPortalBuilder.Section sec = new rkl.RKPortalBuilder.Section(name, label);
        for(String fs: fieldSetNames) {
            sec.add(new rkl.RKPortalBuilder.FieldSet(fs));
        }
        return sec;
    }

    public rkl.RKPortalBuilder.SectionTemplate template(String name, String recType, String label, List<rkl.RKPortalBuilder.Section> sections) {
        rkl.RKPortalBuilder.SectionTemplate temp = new rkl.RKPortalBuilder.SectionTemplate('Intake_Detail__c', recType, 'intake__c', name, label);
        for(rkl.RKPortalBuilder.Section sec: sections) {
            temp.add(sec);
        }
        return temp;
    }

    public override String getUIBuilderJS() {
        rkl.RKPortalBuilder.Portal currentPortal = (new rkl.RKPortalBuilder.Portal('DemoPortal_Old_Controller', 'Intake__c','tocnav', id, '"#incidentPortalRoot"',language)
            .add(template('Employee_Injury', 'Employee_Injury', 'Employee Injury', new List<rkl.RKPortalBuilder.Section>{
                //section('Employee_Injury', 'Employee Injury', new List<String>{'Employee_Injuries_Injuries', 'Employee_Injury_OSHA'})
                section('Injuries', 'Injuries', new List<String>{'Employee_Injuries_Injuries'}),
                section('OSHA', 'OSHA', new List<String>{'Employee_Injury_OSHA'})
            }))
            .add(template('Auto_Non_Employee_Injury', 'X3rd_Party_Auto_Bodily_Injury', 'Auto Non Employee Injury', new List<rkl.RKPortalBuilder.Section>{
                section('Auto_Non_Employee_Injury', 'Auto Non Employee Injury', new List<String>{'X3rd_Party_Auto_Bodily_Injury_Injuries'})
            }))
            .add(template('Auto_Non_Employee_Property_Damage', 'X3rd_Party_Auto_Damage', 'Auto Non Employee Property Damage', new List<rkl.RKPortalBuilder.Section>{
                section('Auto_Non_Employee_Property_Damage', 'Auto Non Employee Property Damage', new List<String>{'X3rd_Party_Auto_Damage_3rd_Party_Vehicle', 'X3rd_Party_Auto_Bodily_Injury_3rd_Party'})
            }))
            .add(template('Auto_Company_Vehicle', 'Company_Auto_Damage', 'Auto Company Vehicle', new List<rkl.RKPortalBuilder.Section>{
                section('Auto_Company_Vehicle', 'Auto Company Vehicle', new List<String>{'Company_Auto_Damage_Company_Driver', 'Company_Auto_Damage_Company_Vehicle'})
            }))
            .add(template('3rd_Party_Bodily_Injury', 'X3rd_Party_Bodily_Injury', '3rd Party Bodily Injury', new List<rkl.RKPortalBuilder.Section>{
                section('3rd_Party_Bodily_Injury', '3rd Party Bodily Injury', new List<String>{ 'X3rd_Party_Bodily_Injury_Injuries'}),
                section('Product_Information', 'Product Information', new List<String>{ 'Product_Information'})
            }))
            .add(template('3rd_Party_Property_Damage', 'X3rd_Party_Property_Damage', '3rd Party Property Damage', new List<rkl.RKPortalBuilder.Section>{
                section('3rd_Party_Property_Damage', '3rd Party Property Damage', new List<String>{ 'X3rd_Party_Property_Damage_Property_Dama'}),
                section('Product_Information', 'Product Information', new List<String>{ 'Product_Information'}),
                section('Property_Information', 'Property Information', new List<String>{ 'Property_Information'})
            }))
            .add(template('Company_Property_Damage', 'Company_Property_Damage', 'Company Property Damage', new List<rkl.RKPortalBuilder.Section>{
                section('Company_Property_Damage', 'Company Property Damage', new List<String>{ 'Company_Property_Damage_Company_Property'})
            }))
            .add(section('Intake_Description', 'General Incident Details', new List<String>{'Intake_Description'}))
            .add(section('Involved_Parties', 'Involved Parties', new List<String>{'Involved_Parties'}))
            .add(new rkl.RKPortalBuilder.STGroup('Employee_Injury', 'Employee_Injury', 'Employee Injury'))
            .add(new rkl.RKPortalBuilder.STGroup('Auto_Non_Employee_Injury', 'Auto_Non_Employee_Injury', 'Auto Non-Employee Injury'))
            .add(new rkl.RKPortalBuilder.STGroup('Auto_Non_Employee_Property_Damage', 'Auto_Non_Employee_Property_Damage', 'Auto Non-Employee Property Damage'))
            .add(new rkl.RKPortalBuilder.STGroup('Auto_Company_Vehicle', 'Auto_Company_Vehicle', 'Auto Company Vehicle'))
            .add(new rkl.RKPortalBuilder.STGroup('3rd_Party_Bodily_Injury', '3rd_Party_Bodily_Injury', '3rd Party Bodily Injury'))
            .add(new rkl.RKPortalBuilder.STGroup('3rd_Party_Property_Damage', '3rd_Party_Property_Damage', '3rd Party Property Damage'))
            .add(new rkl.RKPortalBuilder.STGroup('Company_Property_Damage', 'Company_Property_Damage', 'Company Property Damage'))
            .add(section('Near_Miss', 'Near Miss', new List<String>{'Near_Miss'}))
            .add(section('Witnesses', 'Witnesses', new List<String>{'Witnesses'}))
            .add(new rkl.RKPortalBuilder.Section('Submit', 'Submit')
                .add(new rkl.RKPortalBuilder.PlainLabel('Submit_Instructions_1', 'Please review all preceding sections before clicking the \\"Submit\\" button below.'))
                .add(new rkl.RKPortalBuilder.PlainLabel('Submit_Instructions_2', 'You will be unable to change your provided answers once \\"Submit\\" is clicked.'))
                .add(new rkl.RKPortalBuilder.Attachments('Attachments', 'Attachments'))
            )
            .defineLookup('Intake_Description','Incident_Location__c', new rkl.RKPortalBuilder.LookupConfig(
                new rkl.JS_Search.InLineSearches()
                    .setFilters(new List<String>{'rkl__Node_Code__c', 'rkl__Node_Name__c', 'rkl__city__c', 'rkl__state__c', 'rkl__country__c'})
                    .setResults('FIELDSET::Intake_Location_Lookup_Grid')
                )
                .setRebindOnClear(true))
            .defineLookup('Company_Driver__c', new rkl.RKPortalBuilder.LookupConfig(
                new rkl.JS_Search.InLineSearches()
                    .setFilters(new List<String>{'Employee_ID__c', 'FirstName', 'LastName'})
                    .setResults('FIELDSET::Intake_Contact_Lookup_Grid')
                    .setMyWhere(new rkl.GS_Soql.fieldCondition('RecordTypeId').EqualToVal(contactRecordTypeId))
                    )
                .setMixinFieldSets('Intake_Contact_Company_Driver', 'Intake_Detail_Company_Driver'))
            .defineLookup('injured_employee__c', new rkl.RKPortalBuilder.LookupConfig(//'portalName__c'
                new rkl.JS_Search.InLineSearches()
                    .setFilters(new List<String>{'Employee_ID__c', 'FirstName', 'LastName'})
                    .setResults('FIELDSET::Intake_Contact_Lookup_Grid')
                    .setMyWhere(new rkl.GS_Soql.fieldCondition('RecordTypeId').EqualToVal(contactRecordTypeId))
                    )
                .setMixinFieldSets('Intake_Contact_Injured_Employee', 'Intake_Detail_Injured_Employee'))
            .defineLookup('company_vehicle_lookup__c', new rkl.RKPortalBuilder.LookupConfig(
                new rkl.JS_Search.InLineSearches()
                    .setFilters(new List<String>{'Fleet_Number__c', 'Plate_Number__c', 'Plate_State__c', 'Make__c', 'Model__c'})
                    .setResults('FIELDSET::Intake_Vehicle_Lookup_Grid'))
                .setMixinFieldSets('Intake_Asset_Company_Vehicle', 'Intake_Detail_Company_Vehicle'))
            .defineLookup('company_property__c', new rkl.RKPortalBuilder.LookupConfig(
                new rkl.JS_Search.InLineSearches()
                    .setFilters(new List<String>{'Property_ID__c', 'Name', 'Address_Line1__c', 'Address_Line2__c', 'city__c', 'state__c', 'country__c'})
                    .setResults('FIELDSET::Intake_Property_Lookup_Grid')))
            .defineLookup('Product__c', new rkl.RKPortalBuilder.LookupConfig(
                new rkl.JS_Search.InLineSearches()
                    .setFilters(new List<String>{'Product_Name__c', 'SKU__c'})
                    .setResults('FIELDSET::Product_Lookup_Grid')))

        );

        return currentPortal.toJS();
    }
}