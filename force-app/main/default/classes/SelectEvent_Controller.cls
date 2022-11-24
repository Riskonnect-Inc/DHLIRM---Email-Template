public class SelectEvent_Controller {

    public Integer rowSize {get; set;}
    public Map<String, String> patientEventRecordTypes {get; set;}
    public List<List<String>> patientEventRecordTypeRows {get; set;}
    public List<String> recTypes {get; set;}
    public List<string> feedbackDevloperNames {get;set;}
    public Map<String, String> feedbackRecordTypes {get; set;}
    public List<List<String>> patientFeedbackRecordTypeRows {get;set;}


    public SelectEvent_Controller(){

        // Order of list here determines display order in Request Center
        recTypes =  new List<String>{'Adverse_Drug_Reaction','Anesthesia_Sedation',
            'Blood_or_Blood_Product','Diagnostic_Radiology','Facilities_Related','Fall',
            'Healthcare_associated_Infection','Information_Systems','IV_Related',
            'Laboratory','Medical_Equipment_Device','Medication_or_Other_Substance','Narcotic_Discrepancy','Other',
            'Patient_Behavior','Perinatal','Privacy_Confidentiality','Restraints_Seclusion','Security',
            'Skin_Integrity','Staff_Provider_Behavior','Surgery','Treatment_Procedure','Venous_Thromboembolism'};

        feedbackDevloperNames = new List<String>{'General_Feedback','Compliment','Complaint'};

        recTypes.sort();
        feedbackDevloperNames.sort();

        patientEventRecordTypes = new Map<String, String>();
        feedbackRecordTypes = new Map<String, String>();
        for (RecordType rec : [select id, developerName, name from RecordType where SobjectType = 'Patient_Event__c' AND developerName in :recTypes ]) {
            patientEventRecordTypes.put(rec.developerName, rec.name);
        }
        for (RecordType rec : [select id, developerName, name from RecordType where SobjectType = 'Patient_Satisfaction__c' AND developerName in :feedbackDevloperNames ]) {
            feedbackRecordTypes.put(rec.developerName, rec.name);
        }

        rowSize = 4;
        patientEventRecordTypeRows = new List<List<String>>();
        List<String> safetycurrent;

        Integer offset = 0;
        while(offset < recTypes.size()) {
            if(Math.mod(offset, rowSize) == 0) {
                safetycurrent = new List<String>();
                patientEventRecordTypeRows.add(safetycurrent);
            }
            safetycurrent.add(recTypes[offset]);
            offset++;
        }

        patientFeedbackRecordTypeRows = new List<List<String>>();
        List<String> feedBackcurrent;

        offset = 0;
        while(offset < feedbackDevloperNames.size()) {
            if(Math.mod(offset, rowSize) == 0) {
                feedBackcurrent = new List<String>();
                patientFeedbackRecordTypeRows.add(feedBackcurrent);
            }
            feedBackcurrent.add(feedbackDevloperNames[offset]);
            offset++;
        }

    }
}