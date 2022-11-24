/*====================================================================================================
     Added to RK base RMIS product as  08/28/2013

    ======= Modification Log =======
    Date                            Author                  Description
    December 14th, 2016 2:44 PM     Jason Bradley           Updated to interact appropriately with test code.
====================================================================================================*/
    
public class TimeDimensionUtils {
    public static final String customPeriod1Name = getSettings().Custom_Period_1_Name__c;
    public static final String customPeriod1Description = getSettings().Custom_Period_1_Description__c;
    public static final String customPeriod1EndDate = getSettings().Custom_Period_1_End_Date__c;
    public static final String customPeriod1Quarter = getSettings().Custom_Period_1_Quarter__c;
    public static final String customPeriod1StartDate = getSettings().Custom_Period_1_Start_Date__c;
    public static final String customPeriod1Year = getSettings().Custom_Period_1_Year__c;
    
    public static final String customPeriod2Name = getSettings().Custom_Period_2_Name__c;
    public static final String customPeriod2Description = getSettings().Custom_Period_2_Description__c;
    public static final String customPeriod2EndDate = getSettings().Custom_Period_2_End_Date__c;
    public static final String customPeriod2Quarter = getSettings().Custom_Period_2_Quarter__c;
    public static final String customPeriod2StartDate = getSettings().Custom_Period_2_Start_Date__c;
    public static final String customPeriod2Year = getSettings().Custom_Period_2_Year__c;
    
    public static final Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    public static final Map<String, Schema.SObjectField> timeDimensionFieldMap = globalDescribe.get('Time_Dimension__c').getDescribe().fields.getMap();
    
    public static final Map<String, Schema.SObjectField> dummyTimeDimensionInputFieldMap = globalDescribe.get('DummyTimeDimensionDataInput__c').getDescribe().fields.getMap();
    
    public static final String customField1 = getSettings().Custom_Period_1_Input_Name__c;
    public static final String customField2 = getSettings().Custom_Period_2_Input_Name__c;

    private static Time_Dimension_Generator_Settings__c testSettings;
    public static Time_Dimension_Generator_Settings__c getSettings() {
        if (Test.isRunningTest()) {
            if (testSettings == null) {
                testSettings = new Time_Dimension_Generator_Settings__c();

                testSettings.Custom_Period_1_Input_Name__c = 'Custom_Period_1_Input_Name__c';
                testSettings.Custom_Period_1_Name__c = 'Custom_Period_1__c';
                testSettings.Custom_Period_1_Description__c = 'Custom_Period_1_Description__c';
                testSettings.Custom_Period_1_Start_Date__c = 'Custom_Period_1_Start_Date__c';
                testSettings.Custom_Period_1_End_Date__c = 'Custom_Period_1_End_Date__c';
                testSettings.Custom_Period_1_Quarter__c = 'Custom_Period_1_Quarter__c';
                testSettings.Custom_Period_1_Year__c = 'Custom_Period_1_Year__c';

                /*testSettings.Custom_Period_2_Input_Name__c = 'Custom_Period_2_Input_Name__c';
                testSettings.Custom_Period_2_Name__c = 'Custom_Period_2__c';
                testSettings.Custom_Period_2_Description__c = 'Custom_Period_2_Description__c';
                testSettings.Custom_Period_2_Start_Date__c = 'Custom_Period_2_Start_Date__c';
                testSettings.Custom_Period_2_End_Date__c = 'Custom_Period_2_End_Date__c';
                testSettings.Custom_Period_2_Quarter__c = 'Custom_Period_2_Quarter__c';
                testSettings.Custom_Period_2_Year__c = 'Custom_Period_2_Year__c';*/

                insert testSettings;
            }
            return testSettings;
        } else {
            return Time_Dimension_Generator_Settings__c.getInstance();
        }
    }

    public static PageReference getApexJobsPage() {
        PageReference apexJobsPage = new PageReference('/apexpages/setup/listAsyncApexJobs.apexp');
        apexJobsPage.setRedirect(true);
        return apexJobsPage;
    }
}