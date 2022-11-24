public with sharing class PatientFeedback_Controller extends rkl.RKPortalController_2{

    public String recordId {get; private set;}
    
    public PatientFeedback_Controller(rkl.JS_Search ign) {
        recordId = System.currentPagereference().getParameters().get('incId');
        if(recordId != null && recordId.trim() == '') {
            recordId = null;
        }            
    }
    
    public PageReference pageLoad(){          
        return null;        
    }
    
     @RemoteAction
    public static Object retrieveTemplate(Map<String, Object> config) {
        String templateName = (String)config.get('templateName');
        rkl.RKPBuilder builder = rkl.RKPBuilder.createBuilder('Patient_Satisfaction', 'Patient_Satisfaction__c', templateName);
        if(templateName == 'General_Feedback'){
            builder = builder
                        .fieldsetSection('General_Feedback','General Feedback');
        } else if(templateName == 'Compliment'){
            builder = builder
                    .fieldsetSection('Compliment','Compliment')
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
                    .addPlainTextBefore('Date_feedback_Received__c','instruction1','<p class="banner-bldUnderlne">Compliment Information</p>')
                    .fieldset('Compliment_2')
                    .addPlainTextBefore('Involved_Party_First__c','instruction2','<p class="banner-bldUnderlne">Involved Individual</p>')
                    .fieldset('Reporter')
                        .configureMember('reporter__c')
                            .put('searchFields', 'Reporter_Search_Fields')
                            .put('resultFields', 'Reporter_Results_Grid')
                            .put('baseCondition', 'Contact_Type__c = "Employee"')
                            .sub('mixin')
                                .put('src','Reporter_Autofill')
                                .put('dst','Reporter_Autofill')
                            .subdone()
                        .done()
                    .addPlainTextBefore('Reporter__c','instruction3','<p class="banner-bldUnderlne">Reporter</p>');   
        } else if(templateName == 'Complaint'){
            builder = builder
                    .fieldsetSection('General_Information','General Information')
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
                        .done()
                    .fieldsetSection('Individual_Providing_Feedback','Involved Parties')
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
        } else 
            return null;
        
        builder = builder
                    .section('Submit')
                    .plainText('Submit_Instructions_1', 'Please review all preceding sections before clicking the \"Submit\" button below.')
                    .plainText('Submit_Instructions_2', 'You will be unable to change your provided answers once \"Submit\" is clicked.')
                    .attach('Attachments');
        return builder.finalize(); 
    }
}