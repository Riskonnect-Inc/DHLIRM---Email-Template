/*===========================================================================
     Added to RK base RMIS product as 02/04/2016
    ===========================================================================*/
    
public class DGDataTest_Utils {
    public class JobClassInfo {
        public Integer factor;
        public String[] fieldNames; // Minimal, optimal, max

        public JobClassInfo(Integer f, String[] fn) {
            this.factor = f;
            this.fieldNames = fn;
        }
    }

    public static Map<String, JobClassInfo> jobClassInfoMap = new Map<String, JobClassInfo> {
        'SEDENTARY'  => new JobClassInfo(1,
        new String[] {
            'Sedentary_Min__c',
            'Sedentary_Opt__c',
            'Sedentary_Max__c'
        }),
        'LIGHT'      => new JobClassInfo(2,
        new String[] {
            'Light_Min__c',
            'Light_Opt__c',
            'Light_Max__c'
        }),
        'MEDIUM'     => new JobClassInfo(3,
        new String[] {
            'Medium_Min__c',
            'Medium_Opt__c',
            'Medium_Max__c'
        }),
        'HEAVY'      => new JobClassInfo(4,
        new String[] {
            'Heavy_Min__c',
            'Heavy_Opt__c',
            'Heavy_Max__c'
        }),
        'VERY HEAVY' => new JobClassInfo(5,
        new String[] {
            'Very_Heavy_Min__c',
            'Very_Heavy_Opt__c',
            'Very_Heavy_Max__c'
        })
    };

    public static Integer numberOfClaimGroups = 2;

    public static RTW_Guidelines__c createGuideline(Id claimId, String type, String days, Id diagnosisId) {
        RTW_Guidelines__c g = new RTW_Guidelines__c(Claim__c = claimId,
                Job_Class__c = type,
                Predicted_Days_of_Disability__c = days,
                Salary__c = 30000,
                Date_Injury_Occurred__c = System.Today(),
                ICD_9_CM1__c = diagnosisId);

        Integer factor;

        for (String jobClass : jobClassInfoMap.keySet()) {
            String[] fieldNames = jobClassInfoMap.get(jobClass).fieldNames;

            // Minimal, optimal, max
            for (Integer i = 0; i < fieldNames.size(); i++) {
                g.put(fieldNames[i], String.valueOf(jobClassInfoMap.get(jobClass).factor * (i + 1)));
            }
        }

        return g;
    }

    public static ICD9_Diagnosis__c createICD9Diagnosis(String code) {
        ICD9_Diagnosis__c diagnosis = new ICD9_Diagnosis__c(Diagnosis_Code__c = code);

        return diagnosis;
    }

    public static Claim__c CreateClaim() {
        return new Claim__c(Coverage_Minor__c = 'GL',
                            Date_of_Loss__c = System.today(),
                            Claimant_Last_Name__c = 'McShane');
    }

}