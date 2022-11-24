/*===========================================================================
     Added to RK base RMIS product as 05/29/2013
    ===========================================================================*/
    
public with sharing class DGDialogController {

    //AD 3/6/2013
      
    @TestVisible public RTW_Guidelines__c searchInputs {get; private set;}
    public String domestic = 'YES';  //we are only tracking domestic claims
    public String wc = 'YES'; //we are only doing WC
    public String postalCode {get; set;}  //only the first number of the postal code is required
    public String age {get;set;} 
    public String gender {get;set;}
    public String yearIncurred {get;set;}
    public DGData2.DurationTable[] durTables {get; set;}
    public DGData2.Monograph[] monographInfo {get; set;}  
    public DGData2.PredictiveModel predictiveModelInfo {get; set;}   
    public DGData2.MonographDetails[] monographDetailsList = new DGData2.MonographDetails[]{}; 
    public Id claimId {get; set;}
    public Claim__c claim {get;set;}
    public String selectedRadioValue {get; private set;}
                
    public DGDialogController(ApexPages.StandardController controller) {
        searchInputs = new RTW_Guidelines__c ();
        claimId = controller.getId();
        claim = [Select Claimant_Age__c, Date_Of_Loss__c, Date_of_First_Medical_Visit__c, 
                        Claimant_Gender__c, Claimant_Postal_Code__c, Coverage_Major__c                      
                 From   Claim__c
                 Where  Id =: claimId];
        if (claim.Claimant_Postal_Code__c != null) this.postalCode = claim.Claimant_Postal_Code__c.substring(0,1);
        this.gender = claim.Claimant_Gender__c;
        this.age = String.valueOf(claim.Claimant_Age__c);
        this.yearIncurred = String.valueOf(claim.Date_Of_Loss__c.year());
    }

    public PageReference searchAction () {

        durTables = null;
        monographInfo = null;
        predictiveModelInfo = null;
        String comorbidity1;
        String comorbidity2;
        String comorbidity3;
        
        ICD9_Diagnosis__c icd9 = [Select Diagnosis_Code__c, icd_indicator__c From ICD9_Diagnosis__c Where Id =: searchInputs.ICD_9_CM1__c];
        String icd_type = icd9.icd_indicator__c;
        String[] icd_inconsistents = new String[]{};
        String icd9Code = icd9.Diagnosis_Code__c;

        if (searchInputs.ICD9_Diagnosis_Co_Existing_Condition_1__c != null) {
            ICD9_Diagnosis__c coicd91 = [Select Diagnosis_Code__c, icd_indicator__c From ICD9_Diagnosis__c Where Id =: searchInputs.ICD9_Diagnosis_Co_Existing_Condition_1__c];
            comorbidity1 = coicd91.Diagnosis_Code__c; 
            if(icd_type != coicd91.icd_indicator__c) {
                icd_inconsistents.add('Comorbid Code 1');
            }
        }
        if (searchInputs.ICD9_Diagnosis_Co_Existing_Condition_2__c != null) {        
            ICD9_Diagnosis__c coicd92 = [Select Diagnosis_Code__c, icd_indicator__c From ICD9_Diagnosis__c Where Id =: searchInputs.ICD9_Diagnosis_Co_Existing_Condition_2__c];
            comorbidity2 = coicd92.Diagnosis_Code__c;               
            if(icd_type != coicd92.icd_indicator__c) {
                icd_inconsistents.add('Comorbid Code 2');
            }
        }
        if (searchInputs.ICD9_Diagnosis_Co_Existing_Condition_3__c != null) {
            ICD9_Diagnosis__c coicd93 = [Select Diagnosis_Code__c, icd_indicator__c From ICD9_Diagnosis__c Where Id =: searchInputs.ICD9_Diagnosis_Co_Existing_Condition_3__c];
            comorbidity3 = icd9.Diagnosis_Code__c;         
            if(icd_type != coicd93.icd_indicator__c) {
                icd_inconsistents.add('Comorbid Code 3');
            }
        }
        
        if(icd_inconsistents.size() > 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, 'The following comorbid codes are not ' + icd_type + ': ' + String.join(icd_inconsistents, ', '))); 
            return null;
        }
        
        try {   
            //Get duration tables info
            DGData2 rt = new DGData2(icd9Code, icd_type, searchInputs.Job_Class__c);
            durTables = rt.loadDurationTables();
            monographInfo = rt.loadMonograph();

            // Get Monographs details info
            for(DGData2.Monograph m: monographInfo) {
                //System.debug('MID: ' + m.monographId);
                //rt = new DGData2(m.monographId);
                System.debug('MURL: ' + m.monographUrl);
                rt = new DGData2(m.monographURL);
                
                DGData2.MonographDetails md = rt.loadMonographDetails();   
                System.debug('MID Name: ' + md.monographName);      
                monographDetailsList.add(md);   
            }
                       
            // Get predictive model info
            rt = new DGData2(icd9Code, icd_type, searchInputs.Job_Class__c,comorbidity1,comorbidity2,comorbidity3,'','',age,gender,postalCode,wc,domestic,yearIncurred);
            predictiveModelInfo = rt.loadPredictiveModel();               
                  
        } catch (Exception e) {
            if(e.getMessage() == 'Expected the "DisabilityDurationResponse.DurationTables" property to be an array type; got: null' && 
               age == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, 'Claimant Age cannot be null: check the Claim data.')); 
            } else if(e.getMessage() == 'Expected the "DisabilityDurationResponse.DurationTables" property to be an array type; got: null' && 
               gender == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, 'Claimant Gender cannot be null: check the Claim data.')); 
            } else if(e.getMessage() == 'Expected the "DisabilityDurationResponse.DurationTables" property to be an array type; got: null' && 
               postalCode == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, 'Postal code cannot be null: check the Claim data.')); 
            } 
            System.debug(e);
            return null;
        } 
        return ApexPages.currentPage();
    }      
            
    public PageReference saveGuidelinesAction () {
        
        DG_Monograph__c[] monographs = new DG_Monograph__c[]{};
        searchInputs.Claim__c = claimId;
        selectedRadioValue = al.PageUtils.get('selectedRadio');
        
        if (selectedRadioValue != null) {
            for(DGData2.DurationTable d : durTables) {
                if (d.factor == selectedRadioValue) {
                    searchInputs.Sedentary_Min__c = String.valueof(d.jobs[0].minVal);
                    searchInputs.Sedentary_Max__c = String.valueof(d.jobs[0].maxVal);
                    searchInputs.Sedentary_Opt__c = String.valueof(d.jobs[0].optimum);
                    searchInputs.Light_Min__c = String.valueof(d.jobs[1].minVal);
                    searchInputs.Light_Max__c = String.valueof(d.jobs[1].maxVal);
                    searchInputs.Light_Opt__c = String.valueof(d.jobs[1].optimum); 
                    searchInputs.Medium_Min__c = String.valueof(d.jobs[2].minVal);
                    searchInputs.Medium_Max__c = String.valueof(d.jobs[2].maxVal);
                    searchInputs.Medium_Opt__c = String.valueof(d.jobs[2].optimum);    
                    searchInputs.Heavy_Min__c = String.valueof(d.jobs[3].minVal);
                    searchInputs.Heavy_Max__c = String.valueof(d.jobs[3].maxVal);
                    searchInputs.Heavy_Opt__c = String.valueof(d.jobs[3].optimum);  
                    searchInputs.Very_Heavy_Min__c = String.valueof(d.jobs[4].minVal);
                    searchInputs.Very_Heavy_Max__c = String.valueof(d.jobs[4].maxVal);
                    searchInputs.Very_Heavy_Opt__c = String.valueof(d.jobs[4].optimum);                                                                 
                }
            }
            
            if (predictiveModelInfo != null) {
                searchInputs.Days_Age__c = String.valueof(predictiveModelInfo.ageValue);
                searchInputs.Days_Comorbid_1__c  = String.valueof(predictiveModelInfo.comorbid1Value);
                searchInputs.Days_Comorbid_2__c  = String.valueof(predictiveModelInfo.comorbid2Value);
                searchInputs.Days_Comorbid_3__c  = String.valueof(predictiveModelInfo.comorbid3Value);
                searchInputs.Days_Gender__c  = String.valueof(predictiveModelInfo.genderValue);
                searchInputs.Days_Job_Class__c  = String.valueof(predictiveModelInfo.jobClassValue);
                searchInputs.Days_Medical_Code__c  = String.valueof(predictiveModelInfo.icd9Value);
                searchInputs.Days_Year__c  = String.valueof(predictiveModelInfo.yearIncurredValue);
                searchInputs.Days_Zip_Code__c = String.valueof(predictiveModelInfo.geographicValue);  
                searchInputs.Days_WC__c = String.valueof(predictiveModelInfo.workersCompValue);
                searchInputs.Predicted_Days_of_Disability__c = String.valueof(predictiveModelInfo.predictiveValue);
            }
                    
            searchInputs.Date_Injury_Occurred__c = claim.Date_Of_Loss__c;
            if (claim.Claimant_Age__c != null) searchInputs.Age__c = claim.Claimant_Age__c;
            searchInputs.Salary__c = 0.0;
            if (claim.Date_of_First_Medical_Visit__c != null) searchInputs.Date_of_first_Doctor_Visit__c = claim.Date_of_First_Medical_Visit__c;
            if (claim.Claimant_Postal_Code__c != null) searchInputs.Zip_Code__c = claim.Claimant_Postal_Code__c;
            if (claim.Claimant_Gender__c != null) searchInputs.Gender__c = claim.Claimant_Gender__c;
            searchInputs.Duration_Table_Factor__c = selectedRadioValue;
            searchInputs.Workers_Comp__c = 'Yes';
    
            insert searchInputs;
             
            for(DGData2.MonographDetails md : monographDetailsList) {
                String monographImage;
                String monographImageLink;
                String definition;
                String treatment;
                String prognosis;
                String specialists;
                String rehabilitation;    
                String returnToWorkResAcc;
                String comorbidConditions;
                String complications;
                String factorsInflDuration;
                String lenghtOfDisability;
                String failureToRecover;
                String risk;
                String incidenceAndPrevalence;
                String history;
                String physicalExams;
                String tests;
                String rehabDisclaimer;
                String reDiagnosis;
                String reTreatment;
                String rePrognosis;         
                String differentialDiagnoses;
                String monographName = md.monographName;
                
                for(DGData2.SectionElement se : md.sectionElements)  {  
                    if(se.sectionId == 'definition') definition = se.sectionContent; 
                    if(se.sectionId == 'differential-diagnoses') differentialDiagnoses = se.sectionContent;
                    if(se.sectionId == 'treatment') treatment = se.sectionContent;   
                    if(se.sectionId == 'prognosis') prognosis = se.sectionContent;                  
                    if(se.sectionId == 'specialists') specialists = se.sectionContent; 
                    if(se.sectionId == 'rehabilitation') rehabilitation = se.sectionContent;
                    if(se.sectionId == 'return-to-work-restrictions-accommodations') returnToWorkResAcc = se.sectionContent;     
                    if(se.sectionId == 'comorbid-conditions') comorbidConditions = se.sectionContent;                   
                    if(se.sectionId == 'complications') complications = se.sectionContent; 
                    if(se.sectionId == 'factors-influencing-duration') factorsInflDuration = se.sectionContent;
                    if(se.sectionId == 'length-of-disability') lenghtOfDisability = se.sectionContent;   
                    if(se.sectionId == 'failure-to-recover') failureToRecover = se.sectionContent;                  
                    if(se.sectionId == 'risk') risk = se.sectionContent; 
                    if(se.sectionId == 'incidence-and-prevalence') incidenceAndPrevalence = se.sectionContent;
                    if(se.sectionId == 'history') history = se.sectionContent;   
                    if(se.sectionId == 'physical-exam') physicalExams = se.sectionContent;
                    if(se.sectionId == 'tests') tests = se.sectionContent;                      
                    if(se.sectionId == 'rehabilitation-disclaimer') rehabDisclaimer = se.sectionContent;     
                    if(se.sectionId == 'regarding-diagnosis') reDiagnosis = se.sectionContent;                  
                    if(se.sectionId == 'regarding-treatment') reTreatment = se.sectionContent; 
                    if(se.sectionId == 'regarding-prognosis') rePrognosis = se.sectionContent;                                                                                      
                }    
                 
                /*
                if (md.illustrations.size() > 0) {
                    monographImage = '<img alt="' + md.illustrations[0].illustrationId + '" src="' + md.illustrations[0].illustrationUrl + '"></img>';
                    monographImageLink = md.illustrations[0].illustrationUrl;   
                }
                */

                DG_Monograph__c m0 = new DG_Monograph__c(RTW_Guidelines__c = searchInputs.Id, 
                                                        Monograph_Image__c = monographImage,
                                                        Image_Link__c = monographImageLink,
                                                        Monograph_Name__c = monographName,
                                                        Definition__c = definition,
                                                        Differential_Diagnosis__c = differentialDiagnoses,
                                                        Treatment__c = treatment,
                                                        Prognosis__c = prognosis,
                                                        Specialists__c = specialists,
                                                        Rehabilitation__c = rehabilitation,
                                                        Return_to_Work_Restrictions_Accomodation__c = returnToWorkResAcc,
                                                        Comorbid_Conditions__c = comorbidConditions,
                                                        Complications__c = complications,
                                                        Factors_Influencing_Duration__c = factorsInflDuration,
                                                        Length_of_Disabiilty__c = lenghtOfDisability,
                                                        Failure_to_Recover__c = failureToRecover,
                                                        Risk__c = risk,
                                                        Incidence_and_Prevalence__c = incidenceAndPrevalence,
                                                        History__c = history,
                                                        Physical_Exam__c = physicalExams,
                                                        Tests__c = tests,
                                                        Rehabilitation_Disclaimer__c = rehabDisclaimer,
                                                        Regarding_Diagnosis__c = reDiagnosis,
                                                        Regarding_Prognosis__c = reTreatment,
                                                        Regarding_Treatment__c = rePrognosis);
                monographs.add(m0);
            }
            
            insert monographs;
            
            PageReference p = new PageReference('/' + searchInputs.Id);
            p.setRedirect(true);
            return p;
        }    
        else { 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, 'Please select a guidelines table before saving this record.'));
            return null;
        }
    }
    
    public PageReference cancel () {
        PageReference p = new PageReference('/' + claimId);
        return p;
    }
    
}