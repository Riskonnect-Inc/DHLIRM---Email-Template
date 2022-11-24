/*===========================================================================
      Added to RK base RMIS product as 4/29/2016 
===========================================================================*/
    
@isTest
public class ClaimComparisonChartController_Test {
  public static testmethod void testClass() {
        String objectName = 'Claim__c';
        String claimJSON = '{"Accident_City__c":"Alpharetta","Claimant_Length_Service__c":"1","Self_Administered__c":false,"Date_of_Loss__c":"2008-11-12","OSHA_Recordable__c":"Yes","Date_Claimant_Born__c":"1983-11-17","Employee_Id__c":"M2241","Part__c":"Wrist, right","State_Fund_Recov_Indicator__c":"No","TPA_Carrier__c":"Self Administered","EPA_Reportable__c":false,"Cause__c":"Exertion loading / unloading","Subrogation_Indicator__c":"No","OSHA_Injury_Type__c":"Injury","Coverage_Minor_SRC__c":"WC","Deleted__c":"No","Work_Status_Total_Days__c":0,"Quick_Load__c":false,"Termination_File_Sent__c":false,"Claimant_Marital_Status__c":"Single","Nature__c":"Carpal Tunnel Syndrome","a_test_checkbox__c":false,"Date_Closed__c":"2013-03-04","Controverted__c":"No","NCCI_Injury_Code__c":"5","Claimant_City__c":"RICHMOND","Claimant_State__c":"CA","Location_SRC__c":"L9000103","State_of_Jurisdiction__c":"GA","Date_Reported_to_Client__c":"2008-11-14","Employment_Status__c":"Terminated","NCCI_Loss_CovCode__c":"17","NCCI_Class_Code__c":"8006","Status__c":"Closed","Accident_State__c":"GA","Date_Hired__c":"2007-09-28","Status_Requested__c":false,"Number_of_Dependents__c":0,"Vehicle_Year__c":"0","Lost_Days__c":0,"Coverage_Major__c":"WC","Date_Opened__c":"2008-11-17","Attorney_Representation__c":"No","Claimant_Postal_Code__c":"94801","Claimant_Gender__c":"Female","Part_General__c":"Arm","Claim_Review_Status__c":"New","RTW_Status_Requested__c":false,"Cause_General__c":"Strain / Sprain / Exertion","Work_Status_Adjustment_Days__c":0,"NCCI_Type_Code__c":"1","Gift_Card__c":false,"Claimant_Country__c":"USA","Accident_Description__c":"Exertion - loading/unloading-Strain-Back, lower-Box, barrel, container","Claim_Type__c":"Medical Only","Date_Returned_to_Work__c":"2008-02-07","IM_Cancellable__c":false,"Average_Weekly_Wage__c":0.00,"Date_of_Maximum_Medical_Improvement__c":"2008-02-10","Return_to_Work_Conditions__c":"Restricted duty","OSHA_Classification__c":"3 - Job Transfer or Restriction","Date_Reported_to_TPA__c":"2008-11-15","Occurrence_Count__c":1,"OSHA_Privacy_Case__c":"No","Employer_Premises__c":"Yes","Send_RCA__c":false,"Coverage_Minor__c":"Workers Comp Medical Only","Takeover_Indicator__c":"N","Source__c":"Human Action NOC","Date_Data_Load_Update__c":"2008-11-30","Claimant_First_Name__c":"Kathryn","Nature_General__c":"Sprain / Strain","Accident_Country__c":"USA","Accident_Time__c":"1130"}';
        
        Claim__c claim = (Claim__c)JSON.deserialize(claimJSON, Claim__c.class);
        insert claim;

        Map<String, Object> objectDescribe = ClaimComparisonChartController.getObjectDescribe(objectName);
        ClaimComparisonChartController.getObjectDescribe('');
        ClaimComparisonChartController.getObjectDescribe('TEST_DOES_NOT_EXIST');
        System.assert(objectDescribe.keySet().size() > 0);

        try {
            ClaimComparisonChartController.getFieldSettings(objectName, 'TEST');
        } catch (ClaimComparisonChartController.FieldSetQueryException e) {
            System.assertEquals(e.getMessage(), 'No matching field set: "TEST" on object: "' + objectName + '"');
        }

        List<String> testFieldNames = new List<String> {'Accident_City__c', 'Claimant_Length_Service__c', 'Date_of_Loss__c'};

        Map<String, Object> claimQueried = ClaimComparisonChartController.queryRecord(objectName, testFieldNames, claim.Id);

        try {
            ClaimComparisonChartController.queryRecord(null, null, null);
        } catch (ClaimComparisonChartController.RecordQueryException e) {}


        List<Map<String, Object>> testClaimSimilar = ClaimComparisonChartController.querySimilarRecords(objectName, testFieldNames, 'Id = \'' + claim.Id + '\'', null, 10);
        System.assert(testClaimSimilar.size() > 0);

        try {
            ClaimComparisonChartController.querySimilarRecords(null, null, null, null, null);
        } catch (ClaimComparisonChartController.RecordQueryException e) {}

        List<Map<String, Object>> testInDevClaims = ClaimComparisonChartController.getInDevelopmentClaims(testFieldNames, 'Id = \'' + claim.Id + '\'', 9999, null, 10);

        try {
            ClaimComparisonChartController.getInDevelopmentClaims(null, 'Id = \'' + claim.Id + '\'', 9999, null, 10);
        } catch (ClaimComparisonChartController.RecordQueryException e) {}
       
        ClaimComparisonChartController.roundIntegerToPlace(Double.valueOf(30.31), 0);

        ClaimComparisonChartController.formatMSInLocaleDateTime(System.now().getTime());
        ClaimComparisonChartController.formatMSInLocaleDate(System.now().getTime());
    }
}