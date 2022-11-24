/*===========================================================================
      Added to RK base RMIS product as 05/20/2014 
===========================================================================*/

@isTest
public class ClaimAbstractMulti_Test {
    public static testMethod void testClaimAbstractMultiConstructor() {
        Claim__c testClaim = new Claim__c();
        testClaim.Date_of_Loss__c = System.today();
        insert testClaim;

        PageReference testPage = new PageReference('/apex/claimabstractmulti');
        testPage.getParameters().put('adjusterNotesRendered', 'true');
        testPage.getParameters().put('transRendered', 'true');
        testPage.getParameters().put('attachmentsRendered', 'true');
        testPage.getParameters().put('tasksRendered', 'true');
        testPage.getParameters().put('taskHistoryRendered', 'true');
        testPage.getParameters().put('id', testClaim.ID);

        Test.setCurrentPage(testPage);
        ApexPages.StandardController controller = new ApexPages.StandardController(testClaim);
        ClaimAbstractMultiController currentController = new ClaimAbstractMultiController(controller);
    }


    public static testMethod void testClaimAbstractMultiConstructor2() {
        Claim__c testClaim = new Claim__c();
        testClaim.Date_of_Loss__c = System.today();
        insert testClaim;

        PageReference testPage = new PageReference('/apex/claimabstractmulti');
        testPage.getParameters().put('adjusterNotesRendered', 'false');
        testPage.getParameters().put('transRendered', 'false');
        testPage.getParameters().put('attachmentsRendered', 'false');
        testPage.getParameters().put('tasksRendered', 'false');
        testPage.getParameters().put('taskHistoryRendered', 'false');
        testPage.getParameters().put('id', testClaim.ID);

        Test.setCurrentPage(testPage);
        ApexPages.StandardController controller = new ApexPages.StandardController(testClaim);
        ClaimAbstractMultiController currentController = new ClaimAbstractMultiController(controller);
    }
}