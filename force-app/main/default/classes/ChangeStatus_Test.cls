@isTest
public class ChangeStatus_Test {
    public static testmethod void testCloseAllOpenTasks() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User (Username = 'testName@rkmail.com',
                           Alias = 'standa',
                           Email='testName@gmail.com',
                           EmailEncodingKey='UTF-8',
                           LanguageLocaleKey='en_US',
                           LocaleSidKey='en_US',
                           TimeZoneSidKey='America/Los_Angeles',
                           LastName='test',
                           ProfileId = p.Id);
        insert u;
        String claimJSON = '{"Accident_City__c":"Alpharetta","Claimant_Length_Service__c":"1","Self_Administered__c":false,"Date_of_Loss__c":"2008-11-12","OSHA_Recordable__c":"Yes","Date_Claimant_Born__c":"1983-11-17","Employee_Id__c":"M2241","Part__c":"Wrist, right","State_Fund_Recov_Indicator__c":"No","TPA_Carrier__c":"Self Administered","EPA_Reportable__c":false,"Cause__c":"Exertion loading / unloading","Subrogation_Indicator__c":"No","OSHA_Injury_Type__c":"Injury","Coverage_Minor_SRC__c":"WC","Termination_File_Sent__c":false,"Claimant_Marital_Status__c":"Single","Nature__c":"Carpal Tunnel Syndrome","Date_Closed__c":"2013-03-04","Controverted__c":"No","NCCI_Injury_Code__c":"5","Claimant_City__c":"RICHMOND","Claimant_State__c":"CA","Location_SRC__c":"L9000103","State_of_Jurisdiction__c":"GA","Date_Reported_to_Client__c":"2008-11-14","Employment_Status__c":"Terminated","NCCI_Loss_CovCode__c":"17","NCCI_Class_Code__c":"8006","Status__c":"Closed","Accident_State__c":"GA","Date_Hired__c":"2007-09-28","Status_Requested__c":false,"Number_of_Dependents__c":0,"Vehicle_Year__c":"0","Lost_Days__c":0,"Coverage_Major__c":"WC","Date_Opened__c":"2008-11-17","Attorney_Representation__c":"No","Claimant_Postal_Code__c":"94801","Claimant_Gender__c":"Female","Part_General__c":"Arm","Claim_Review_Status__c":"New","RTW_Status_Requested__c":false,"Cause_General__c":"Strain / Sprain / Exertion","NCCI_Type_Code__c":"1","Gift_Card__c":false,"Claimant_Country__c":"USA","Accident_Description__c":"Exertion - loading/unloading-Strain-Back, lower-Box, barrel, container","Claim_Type__c":"Medical Only","Date_Returned_to_Work__c":"2008-02-07","Average_Weekly_Wage__c":0.00,"Date_of_Maximum_Medical_Improvement__c":"2008-02-10","Return_to_Work_Conditions__c":"Restricted duty","OSHA_Classification__c":"3 - Job Transfer or Restriction","Date_Reported_to_TPA__c":"2008-11-15","OSHA_Privacy_Case__c":"No","Employer_Premises__c":"Yes","Coverage_Minor__c":"Workers Comp Medical Only","Takeover_Indicator__c":"N","Source__c":"Human Action NOC","Date_Data_Load_Update__c":"2008-11-30","Claimant_First_Name__c":"Kathryn","Nature_General__c":"Sprain / Strain","Accident_Country__c":"USA","Accident_Time__c":"1130"}';
        Claim__c claim = (Claim__c)JSON.deserialize(claimJSON, Claim__c.class);
        insert claim;
        
        claim_transaction__c trans = new claim_transaction__c(name='test',claim__c = claim.Id);
        //  insert trans;
        Task task = new Task();
        task.WhatId = claim.Id;
        task.Status = 'Started';
        task.OwnerId = u.Id;
        insert task;
        
        Peer_Review__c pr = new Peer_Review__c(Status__c = 'New');
        insert pr;
        Patient_Event__c pe = new Patient_Event__c(Patient_Event_Status__c = 'New');
        insert pe;
        Root_Cause_Analysis__c rc = new Root_Cause_Analysis__c(Status__c = 'New');
        insert rc;
        
        ChangeStatusHardCode__c hardCodes = new ChangeStatusHardCode__c(Name='ChangeClaimStatus',Close_Claim_Field__c='test',Open_Claim_Field__c='test',Reopen_Claim_Field__c='test',Void_Claim_Field__c='test');
        insert hardCodes;
        String transDate = '2017-12-12';
        ChangeStatus_Controller.updateClaim('Open', transDate, claim, true, claim.Id);
        ChangeStatus_Controller.getAccessiblePicklistValues();
        ChangeStatus_Controller.getApiInfo(pr.Id);
        ChangeStatus_Controller.getApiInfo(rc.Id);
        ChangeStatus_Controller.getApiInfo(pe.Id);
        ChangeStatus_Controller.getClaim(claim.Id);
        ChangeStatus_Controller.getClaimHardCode();
        ChangeStatus_Controller.getCurrentUserProfile();
        ChangeStatus_Controller.getLayoutFields();
        ChangeStatus_Controller.getPersonalSettings();
        ChangeStatus_Controller.getSelfAdmin(claim.Id);
        ChangeStatus_Controller.preventStatusChange();
        ChangeStatus_Controller.preventStatusChange();
        ChangeStatus_Controller.getPicklistValues('Peer_Review__c','Status__c');
        ChangeStatus_Controller.updateObject(pr.Id, 'Peer_Review__c', 'Status__c', 'Closed');
         ChangeStatus_Controller.updateObject(pe.Id, 'Patient_Event__c', 'Patient_Event_Status__c', 'Closed');
         ChangeStatus_Controller.updateObject(rc.Id, 'Root_Cause_Analysis__c', 'Status__c', 'New');
            
            task = [SELECT Id, OwnerId, Status FROM Task WHERE Id =: task.Id];
        System.assert(task.Status == 'Completed', task.OwnerId == u.Id);
    }
}