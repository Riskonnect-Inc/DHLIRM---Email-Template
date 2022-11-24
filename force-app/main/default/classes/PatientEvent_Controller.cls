public with sharing class PatientEvent_Controller extends rkl.RKPortalController_2{
    
    public String recordId {get; private set;}
    public String[] genericFieldset {get;set;}
    
    public PatientEvent_Controller(rkl.JS_Search ign) {
        recordId = System.currentPagereference().getParameters().get('incId');
        if(recordId != null && recordId.trim() == '') {
            recordId = null;
        }
        genericFieldset=readFieldSet('Generic_Medication','Patient_Event__c');            
    }
    
    public PageReference pageLoad(){          
        return null;        
    }
    
    @RemoteAction
    public static Object retrieveTemplate(Map<String, Object> config) {
        String templateName = (String)config.get('templateName');
        Map<String, String[]> portals = new Map<String, String[]> {
            'Other' => new String[]{'no', '', '','General_Information','General Information'},
            'Laboratory' => new String[]{'yes', 'Laboratory','Laboratory'},
            'Anesthesia_Sedation' => new String[]{'yes', 'Anesthesia_Sedation','Anesthesia/Sedation'},
            'Perinatal' => new String[]{'yes', 'Perinatal','Perinatal','General_Information_Perinatal','General Information'},
            'Medical_Equipment_Device' => new String[]{'yes', 'Medical_Equipment_Device','Medical Equipment/Device'},
            'Venous_Thromboembolism' => new String[]{'yes','Venous_Thromboembolism','Venous Thromboembolism'},
            'Staff_Provider_Behavior' =>new String[]{'no', '', '','Staff_Provider_Behavior','General Information'},
            'Treatment_Procedure' => new String[]{'yes', 'Treatment_Procedure','Treatment/Procedure'},
            'Surgery' => new String[]{'yes', 'Surgery','Surgery'},
            'Skin_Integrity' => new String[]{'yes', 'Skin_Integrity','Skin Integrity'},
            'Security' => new String[]{'yes', 'Security', 'Security'},
            'Privacy_Confidentiality'=> new String[]{'no', '','','General_Information_Privacy_Confidential','General Information'},
            'Restraints_Seclusion'=>new String[]{'yes', 'Restraints_Seclusion','Restraints/Seclusion'},
            'Patient_Behavior'=>new String[]{'yes', 'Patient_Behavior','Patient Behavior'},
            'Narcotic_Discrepancy' => new String[]{'yes', 'Narcotic_Discrepancy', 'Narcotic Discrepancy','General_Information_Narcotic_Discrepancy', 'General Information'},
            'Medication_or_Other_Substance' => new String[]{'yes','Medication','Medication or Other Substance'},
            'Information_Systems'=>new String[]{'yes','Information_Systems','Information Systems'},
            'IV_Related'=>new String[]{'yes','IV_Related_Initial_Signs','IV Related Initial Signs'},
            'Diagnostic_Radiology'=>new String[]{'yes','Diagnostic_Radiology','Diagnostic Radiology'},
            'Healthcare_associated_Infection'=>new String[]{'yes','Healthcare_Associated_Infection','Healthcare-Associated Infection'},
            'Fall' => new String[]{'yes', 'Fall','Fall'},
            'Blood_or_Blood_Product'=>new String[]{'yes', 'Blood_or_Blood_Product','Blood or Blood Product'},
            'Adverse_Drug_Reaction'=>new String[]{'yes', 'ADR','Adverse Drug Reaction'},
            'Facilities_Related'=>new String[]{'yes', 'Facilities_Related','Facilities Related'},
            'Visitor_Event'=>new String[]{'yes', 'Involved_Party','Involved Party Information','Visitor','Visitor Event'}
        }; 
    // Template Definitions
        if (portals.containsKey(templateName)) {
            
            String[] subSection = portals.get(templateName);
            String generalInfoFSet, generalInfoLabel;
            
            // Configure General Information Section
            if (subSection.size() > 3) {
                generalInfoFSet = subSection[3];
                generalInfoLabel = subSection[4];
            } else {
                generalInfoFSet = 'General_Information';
                generalInfoLabel = 'General Information';
            }
         // Add General Information section
            rkl.RKPBuilder builder = rkl.RKPBuilder.createBuilder('Patient_Event', 'Patient_Event__c', templateName)
                .fieldsetSection(generalInfoFSet, generalInfoLabel)
                .configureMember('primary_facility__c')
                    .put('searchFields', 'Location_Lookup')
                    .put('resultFields', 'Location_Lookup')
                    .put('baseCondition', 'rkl__node_level__c = 3')
                    .put('recordAmounts', new Map<String,Object>{'page' => 200})
                .done()
                .configureMember('primary_location__c')
                    .put('searchFields', 'Location_Lookup')
                    .put('resultFields', 'Location_Lookup')
                    .put('baseCondition', 'rkl__node_level__c = 4')
                    .put('recordAmounts', new Map<String,Object>{'page' => 200})
                    .put('dependentField', new List<Map<String,Object>>{new Map<String,Object>{'srcField' => 'primary_facility__c','qryField' => 'rkl__Parent_Node__c','qryOperator' => '='}})
                .done()
                .configureMember('reporter__c')
                    .put('searchFields', 'Reporter_Search_Fields')
                    .put('resultFields', 'Reporter_Results_Grid')
                    .put('baseCondition', 'Contact_Type__c = "Employee"')
                    .sub('mixin')
                        .put('src','Reporter_Autofill')
                        .put('dst','Reporter_Autofill')
                    .subdone()
                .done();
             
            if(templateName == 'Narcotic_Discrepancy' ||templateName == 'Privacy_Confidentiality'){
                builder= builder
                    .configureMember('Patient_Visit__c')
                        .put('searchFields', 'Patient_Search_Fields')
                        .put('resultFields', 'Patient_Search_Results')
                        .put('recordAmounts', new Map<String,Object>{'page' => 200})
                        .put('operatorOrders', new Map<String,Object>{
                            'Text' => new List<String>{'='},
                            'Date' => new List<String>{'='}
                        })
                        .sub('mixin')
                            .put('src','Patient_Lookup_Autofill')
                            .put('dst','Patient_Lookup_Autofill')
                        .subdone()
                    .done();
            } else if(templateName == 'Staff_Provider_Behavior'){
                builder= primaryEmpLkp(builder);
            } else if(templateName != 'Visitor_Event'){
                builder= builder
                    .configureMember('patient_visit__c')
                        .put('searchFields', 'Patient_Search_Fields')
                        .put('resultFields', 'Patient_Search_Results')
                        .put('operatorOrders', new Map<String,Object>{
                            'Text' => new List<String>{'='},
                            'Date' => new List<String>{'='}
                        })
                        .sub('mixin')
                            .put('src','Patient_Lookup_Autofill')
                            .put('dst','Patient_Lookup_Autofill') 
                        .subdone()
                    .done()
                    .configureMember('secondary_facility__c')
                        .put('searchFields', 'Location_Lookup')
                        .put('resultFields', 'Location_Lookup')
                        .put('baseCondition', 'rkl__node_level__c = 3')
                        .put('recordAmounts', new Map<String,Object>{'page' => 200})
                    .done()
                    .configureMember('secondary_location__c')
                        .put('searchFields', 'Location_Lookup')
                        .put('resultFields', 'Location_Lookup')
                        .put('baseCondition', 'rkl__node_level__c = 4')
                        .put('recordAmounts', new Map<String,Object>{'page' => 200})
                        .put('dependentField', new List<Map<String,Object>>{new Map<String,Object>{'srcField' => 'secondary_facility__c','qryField' => 'rkl__Parent_Node__c','qryOperator' => '='}})
                    .done();
                if(templateName == 'Perinatal'){
                builder =builder
                    .configureMember('Neonate__c')
                        .put('searchFields', 'Patient_Search_Fields')
                        .put('resultFields', 'Patient_Search_Results')
                        .put('operatorOrders', new Map<String,Object>{
                            'Text' => new List<String>{'='},
                            'Date' => new List<String>{'='}
                        })
                        .sub('mixin')
                            .put('src','Neonate_Auto_fill')
                            .put('dst','Neonate_Auto_fill')
                        .subdone()
                    .done();
                }
            }
            if (subsection[0] == 'yes') {
                builder =builder
                    .fieldsetSection(subsection[1], subsection[2]);
                    if(templateName == 'Narcotic_Discrepancy'){
                        builder = primaryEmpLkp(builder)
                            .configureMember('Secondary_Employee__c')
                                .put('searchFields', 'Reporter_Search_Fields')
                                .put('resultFields', 'Reporter_Results_Grid')
                                .put('baseCondition', 'Contact_Type__c = "Employee"')
                        .done();
                    } else if(templateName == 'Medication_or_Other_Substance' || templateName== 'Medical_Equipment_Device' || templateName =='IV_Related'){
                    if(templateName == 'IV_Related'){
                        builder =builder
                            .fieldset('IV_Related_Details')
                            .addPlainTextBefore('location_of_catheter_cannula__c','instruction4','<p class="banner-bldUnderlne">IV Related Details</p>')
                            .plainText('medication','Medication')
                            .fieldset('Generic_Medication');                            
                        }
                        if(templateName  == 'Medical_Equipment_Device'){
                        builder =builder
                            .fieldset('Generic_Medication');
                            
                        }
                        builder =builder
                            .configureMember('Medication__c')
                                .put('searchFields', 'Medication_Search')
                                .put('resultFields', 'Medication_Results')
                                .sub('mixin')
                                    .put('src','Medication_FieldsPopulated')
                                    .put('dst','Medication_FieldsPopulated')
                                .subdone()
                            .done();
                    if(templateName== 'Medical_Equipment_Device' || templateName =='IV_Related'){
                        builder =builder
                        .addPlainTextBefore('Medication__c','instruction4','<p class="banner-bldUnderlne">Medication</p>');
                    }
                }
                else if(templateName == 'Adverse_Drug_Reaction'){
                    builder =builder
                        .configureMember('Medication__c')
                            .put('searchFields', 'Medication_Search')
                            .put('resultFields', 'Medication_Results')
                            .sub('mixin')
                                .put('src','Medication_FieldsPopulated')
                                .put('dst','Generic_Medication_Lookup_Auto_fill')
                            .subdone()
                        .done();
                }
            }
            builder = builder
                .section('Submit')
                .plainText('Submit_Instructions_1', 'Please review all preceding sections before clicking the \"Submit\" button below.')
                .plainText('Submit_Instructions_2', 'You will be unable to change your provided answers once \"Submit\" is clicked.')
                .attach('Attachments');
            return builder.finalize(); 

        }else
        return null; 
    }
    public static rkl.RKPBuilder primaryEmpLkp(rkl.RKPBuilder builder) {
        builder = builder
                    .configureMember('Primary_Employee__c')
                        .put('searchFields', 'Primary_Employee_Search_Fields')
                        .put('resultFields', 'Primary_Employee_Results_Grid')
                        .put('baseCondition', 'Contact_Type__c = "Employee"')
                        .put('recordAmounts', new Map<String,Object>{'page' => 200})
                        .sub('mixin')
                            .put('src','Primary_Employee_Auto_fill')
                            .put('dst','Primary_Employee_Auto_fill')
                        .subdone()
                    .done();
        return builder;
    }
     
    public List<String> readFieldSet(String fieldSetName, String ObjectName) {
        List<String> fieldPath= new List<String>() ;
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();

        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetObj.getFields()) {
            fieldPath.add('"'+fieldSetMemberObj.getFieldPath()+'"');
        }
        return fieldPath; 
    }  
    
}