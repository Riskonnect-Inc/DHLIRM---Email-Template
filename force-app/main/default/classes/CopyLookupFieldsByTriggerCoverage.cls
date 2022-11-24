/*===========================================================================
     Added to RK base RMIS product as  02/25/2016
    ===========================================================================*/
@isTest
public class CopyLookupFieldsByTriggerCoverage {

    static testMethod void IntakeDetTest(){
        Intake__c test_Intake = new Intake__c();
        insert test_Intake;
        Intake_Detail__c test_Intake_Detail = new Intake_Detail__c(Intake__c = test_Intake.Id);
        insert test_Intake_Detail;
    }

    static testMethod void IntakeTest(){
        Intake__c test_Intake = new Intake__c(occur_on_company_premises__c='Yes');
        insert test_Intake;
    }

    static testMethod void PatientEventTest(){
        rkl__Form_Template__c ft = new rkl__Form_Template__c(Name = 'Initial Reported Patient Event');
        insert ft;
        Patient_Event__c test_PE = new Patient_Event__c();
        insert test_PE;
    }

    static testMethod void PatientFeedbackTest(){
        Patient_Satisfaction__c test_PF = new Patient_Satisfaction__c();
        insert test_PF;
    }

    static testMethod void PeerReviewTest(){
        Peer_Review__c test_PR = new Peer_Review__c();
        insert test_PR;
    }

    static testMethod void RootCauseAnalysisTest(){
        Root_Cause_Analysis__c test_RCA = new Root_Cause_Analysis__c();
        insert test_RCA;
    }
}