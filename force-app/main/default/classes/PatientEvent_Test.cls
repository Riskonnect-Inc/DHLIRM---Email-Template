@isTest
private class PatientEvent_Test {

    @isTest static void testSelectEvent_Controller() {
        Test.startTest();
        SelectEvent_Controller s = new SelectEvent_Controller();
        Test.stopTest();
    }

    @isTest static void testPatientEventController() {
        PageReference pg = new pageReference('PatientEvent');
        Test.setCurrentPage(pg);
        pg.getParameters().put('incID', '');
        PatientEvent_Controller patientEvent = new PatientEvent_Controller(new rkl.JS_Search());
        PageReference re = patientEvent.pageLoad();
        List<String> templatesLst = new List<String>{'Other','Laboratory','Anesthesia_Sedation','Perinatal','Medical_Equipment_Device',
            'Venous_Thromboembolism','Staff_Provider_Behavior','Treatment_Procedure','Surgery',
            'Skin_Integrity','Security','Privacy_Confidentiality','Restraints_Seclusion',
            'Patient_Behavior','Narcotic_Discrepancy','Medication_or_Other_Substance','Information_Systems',
            'IV_Related','Diagnostic_Radiology','Healthcare_associated_Infection','Fall',
            'Blood_or_Blood_Product','Adverse_Drug_Reaction','Facilities_Related','Visitor_Event','Complaint',
            'Compliment','General_Feedback'};
            for(String key : templatesLst){
                PatientEvent_Controller.retrieveTemplate(new Map<String,Object>{'templateName' => key});
            }
    }
    @isTest static void testPatientFeedbackController() {
        PageReference pg = new pageReference('PatientFeedback');
        Test.setCurrentPage(pg);
        pg.getParameters().put('incID', '');
        PatientFeedback_Controller patientfbd = new PatientFeedback_Controller(new rkl.JS_Search());
        PageReference re = patientfbd.pageLoad();
        List<String> templatesLst = new List<String>{'Visitor_Event','Complaint',
            'Compliment','General_Feedback'};
        for(String key : templatesLst){
            PatientFeedback_Controller.retrieveTemplate(new Map<String,Object>{'templateName' => key});
        }
    }

}