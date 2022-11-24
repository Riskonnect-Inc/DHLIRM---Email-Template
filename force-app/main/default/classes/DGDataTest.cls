/*===========================================================================
     Added to RK base RMIS product as 08/232013
    ===========================================================================*/
    
@isTest
private class DGDataTest {
    /*
    class JobClassInfo {
        public Integer factor;
        public String[] fieldNames; // Minimal, optimal, max

        public JobClassInfo(Integer f, String[] fn) {
            this.factor = f;
            this.fieldNames = fn;
        }
    }
    */

    /*
    static Map<String, JobClassInfo> DGDataTest_Utils.jobClassInfoMap = new Map<String, JobClassInfo> {
        'SEDENTARY'  => new JobClassInfo(1,
                                         new String[] {
                                             'Sedentary_Min__c',
                                             'Sedentary_Opt__c',
                                             'Sedentary_Max__c'}),
        'LIGHT'      => new JobClassInfo(2,
                                         new String[] {
                                             'Light_Min__c',
                                             'Light_Opt__c',
                                             'Light_Max__c'}),
        'MEDIUM'     => new JobClassInfo(3,
                                         new String[] {
                                             'Medium_Min__c',
                                             'Medium_Opt__c',
                                             'Medium_Max__c'}),
        'HEAVY'      => new JobClassInfo(4,
                                         new String[] {
                                             'Heavy_Min__c',
                                             'Heavy_Opt__c',
                                             'Heavy_Max__c'}),
        'VERY HEAVY' => new JobClassInfo(5,
                                         new String[] {
                                             'Very_Heavy_Min__c',
                                             'Very_Heavy_Opt__c',
                                             'Very_Heavy_Max__c'})
    };
    */

    /*
    static Integer DGDataTest_Utils.numberOfClaimGroups = 2;
    */

    /*
    static RTW_Guidelines__c DGDataTest_Utils.createGuideline(Id claimId, String type, String days, Id diagnosisId) {
        RTW_Guidelines__c g = new RTW_Guidelines__c(Claim__c=claimId,
                                                    Job_Class__c=type,
                                                    Predicted_Days_of_Disability__c=days,
                                                    Salary__c=30000,
                                                    Date_Injury_Occurred__c=System.Today(),
                                                    ICD_9_CM1__c=diagnosisId);

        Integer factor;

        for (String jobClass : DGDataTest_Utils.jobClassInfoMap.keySet()) {
            String[] fieldNames = DGDataTest_Utils.jobClassInfoMap.get(jobClass).fieldNames;

            // Minimal, optimal, max
            for (Integer i = 0; i < fieldNames.size(); i++) {
                g.put(fieldNames[i], String.valueOf(DGDataTest_Utils.jobClassInfoMap.get(jobClass).factor * (i + 1)));
            }
        }

        return g;
    }
    */

    /*
    static ICD9_Diagnosis__c DGDataTest_Utils.createICD9Diagnosis(String code) {
        ICD9_Diagnosis__c diagnosis = new ICD9_Diagnosis__c(Diagnosis_Code__c=code);

        return diagnosis;
    }
    */

    /*
    static Claim__c DGDataTest_Utils.createClaim() {
        return new Claim__c(Coverage_Minor__c='GL',
                            Date_of_Loss__c=System.today(),
                            Claimant_Last_Name__c='McShane');
    }
    */

    @isTest
    static void testDGData() {
        DGData dgd = new DGData('test');
        DGData dgd2 = new DGData('test');
        DGData.JobClass testJobClass = new DGData.JobClass(1.5, 1.5, 1.5);
        DGData.Monograph testMonograph = new DGData.Monograph('testMonographID', 'testMonograph', 'testMedicalCode', 'testMonographURL');
        DGData.PredictiveModel testPredictiveModel = new DGData.PredictiveModel('testTrendGraphDensityURL', 'testTrendGraphCumulativeURL', 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5);
        DGData.PhyFactor testPhyFactor = new DGData.PhyFactor('testFactorDetails', 1.5, 1.5, 1.5);
        DGData.Topic testTopic = new DGData.Topic('testName', 'testURL');
        DGData.MonographDetails testMonographDetails = new DGData.MonographDetails('testMonographName');
        DGData.SectionElement testSectionElement = new DGData.SectionElement('testSEctionID', 'testSectionName', 'testSectionContent');
        DGData.Illustration testIllustration = new DGData.Illustration('testIllustrationID', 'testIllustrationURL');
    }

    @isTest
    static void testDGDialogController() {
        // Create diagnosis codes.
        Map<String, ICD9_Diagnosis__c> diagnoses = new Map<String, ICD9_Diagnosis__c>();

        for (String jobClass : DGDataTest_Utils.jobClassInfoMap.keySet()) {
            ICD9_Diagnosis__c diagnosis = DGDataTest_Utils.createICD9Diagnosis(jobClass);
            diagnoses.put(jobClass, diagnosis);
        }

        insert diagnoses.values();

        // Create test claims.
        Map<String, List<Claim__c>> claims = new Map<String, List<Claim__c>>();
        for (String jobClass : DGDataTest_Utils.jobClassInfoMap.keySet()) {
            claims.put(jobClass, new List<Claim__c>());
        }

        for (Integer i = 0; i < DGDataTest_Utils.numberOfClaimGroups; i++) {
            for (String jobClass : DGDataTest_Utils.jobClassInfoMap.keySet()) {
                claims.get(jobClass).add(DGDataTest_Utils.createClaim());
            }
        }

        List<Claim__c> allClaims = new List<Claim__c>();

        for (List<Claim__c> claimList : claims.values()) {
            allClaims.addAll(claimList);
        }

        insert allClaims;

        // Bookkeeping so we can figure out claim jobClass later.
        Map<Id, String> claimJobClass = new Map<Id, String>();

        for (String jobClass : claims.keySet()) {
            List<Claim__c> claimList = claims.get(jobClass);

            for (Claim__c claim : claimList) {
                claimJobClass.put(claim.Id, jobClass);
            }
        }

        List<RTW_Guidelines__c> guidelines = new List<RTW_Guidelines__c>();
        for (String jobClass : claims.keySet()) {
            for (Claim__c claim : claims.get(jobClass)) {
                ICD9_Diagnosis__c diagnosis = diagnoses.get(jobClass);
                RTW_Guidelines__c g = DGDataTest_Utils.createGuideline(claim.Id,
                                                      jobClass,
                                                      String.valueOf(DGDataTest_Utils.jobClassInfoMap.get(jobClass).factor),
                                                      diagnosis.Id);
                guidelines.add(g);
            }
        }

        insert guidelines;

        ApexPages.StandardController sc = new ApexPages.StandardController(allClaims[0]);
        DGDialogController dgdc = new DGDialogController(sc);
        dgdc.searchInputs = guidelines[0];
        dgdc.searchAction();
        al.PageUtils.put('selectedRadio', 'Sedentary');
        try {
            dgdc.saveGuidelinesAction();
        } catch (Exception e) {
        }
        dgdc.cancel();
    }
}