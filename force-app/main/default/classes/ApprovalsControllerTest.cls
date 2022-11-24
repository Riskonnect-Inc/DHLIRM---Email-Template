/*===========================================================================
    Added to RK base RMIS product as 05/14/2014
===========================================================================*/
@isTest
global class ApprovalsControllerTest{

    static testMethod void testMyApprovals() {
        ApprovalsController.runningInTestMode = true;
        ApprovalsController c= new ApprovalsController();        
    }
}