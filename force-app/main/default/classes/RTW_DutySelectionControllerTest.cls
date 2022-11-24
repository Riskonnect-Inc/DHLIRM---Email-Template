/*===========================================================================
     Added to RK base RMIS product as  04/29/2016
    ===========================================================================*/
    
@isTest 
public class RTW_DutySelectionControllerTest {
    static testMethod void testRTW_DutySelectionController1() {
        
        ICD9_Diagnosis__c ic = new ICD9_Diagnosis__c (Name='Invalid',Diagnosis_Code__c='Test');
        insert ic;
        
        RecordType rt = [SELECT id,name FROM RecordType WHERE developerName='WC' limit 1];
        Claim__c claim = new Claim__c(RecordTypeId=rt.Id,Name='Test',Coverage_Major__c='WC',Date_of_Loss__c=System.today(),Claimant_Last_Name__c='Test Last Name');
        insert claim;
        
        RTW_Assessment__c  a = new RTW_Assessment__c (Claim__c=claim.Id,Keyboarding__c='1',Kneeling_Squatting__c='6',Pushing_Pulling__c='4',Reaching__c='7');
        insert a;
        
        RTW_Duty__c d1 = new RTW_Duty__c(Name='Test Duty 1',Bending_Stooping__c='2',Keyboarding__c='0',Kneeling_Squatting__c='7',Pushing_Pulling__c='5',Reaching__c='1',Approved__c='Approved');
        insert d1;
        
        RTW_Duty__c d2 = new RTW_Duty__c(Name='Test Duty 2',Bending_Stooping__c='8',Keyboarding__c='0',Kneeling_Squatting__c='2',Pushing_Pulling__c='2',Reaching__c='1');
        insert d2;
        
        RTW_Duty__c d3 = new RTW_Duty__c(Name='Test Duty 3',Bending_Stooping__c='8',Keyboarding__c='0',Kneeling_Squatting__c='2',Pushing_Pulling__c='2',Reaching__c='1');
        RTW_Duty__c d4 = new RTW_Duty__c(Name='Test Duty 4',Bending_Stooping__c='8',Keyboarding__c='0',Kneeling_Squatting__c='2',Pushing_Pulling__c='2',Reaching__c='1');
        
        PageReference pageRef = Page.RTW_DutySelection;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(a);
        RTW_DutySelectionControllerDemo2 demo =new RTW_DutySelectionControllerDemo2(sc);
        
        demo.cancelGoBack();
        demo.saveAssessment();
        
        List<Map<string, Object>> pickVal =RTW_DutySelectionControllerDemo2.getFieldsInFieldSetForPicklist('Activities', 'RTW_Duty__c');
        List<String> Str = RTW_DutySelectionControllerDemo2.getPicklistValues('RTW_Duty__c', 'Keyboarding__c');
        String pos =RTW_DutySelectionControllerDemo2.getPostureFieldsAndValues(a.Id);
        String motion =RTW_DutySelectionControllerDemo2.getMotionFieldsAndValues(a.Id);
        String duty =RTW_DutySelectionControllerDemo2.getRTWDuty(a.Id);
        List<Id> idVal = new List<Id>();
        idVal.add(d1.Id);
        idVal.add(d2.Id);
        RTW_DutySelectionControllerDemo2.saveSelectedDuties(a.id,idVal);
        Boolean ignore =RTW_DutySelectionControllerDemo2.save(a.Id, d2);
        Boolean saveVal=RTW_DutySelectionControllerDemo2.save(a.Id, d3);
        Boolean saveValAgain =RTW_DutySelectionControllerDemo2.save(a.Id, d4);
        String dutyFirst =RTW_DutySelectionControllerDemo2.getRTWDuty(a.Id);
        System.assertEquals(true,saveVal);
    }
}