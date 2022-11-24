/*===========================================================================
     Added to RK base RMIS product as 05/20/2014 
===========================================================================*/
@isTest
public class ClaimAbstractController_Test {
    public static testMethod void testClaimAbstractController() {
        Claim__c testClaim = new Claim__c();
        testClaim.Date_of_Loss__c = System.today();
        insert testClaim;

        PageReference testPage = new PageReference('/apex/claim_abstract');
        Test.setCurrentPage(testPage);

        ClaimAbstractController testController = new ClaimAbstractController();
        PageReference testReference = testController.showClaimAbstract();
        System.assertEquals(testReference.getUrl(), '/apex/ClaimAbstractMulti?adjusterNotesRendered=false&attachmentsRendered=false&taskHistoryRendered=false&tasksRendered=false&transRendered=false');
    }
}