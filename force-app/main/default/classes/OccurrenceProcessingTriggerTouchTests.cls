/*===========================================================================
     Added to RK base RMIS product as 06/01/2016
    ===========================================================================*/
    
@isTest
private class OccurrenceProcessingTriggerTouchTests {
    // This method covers a trigger on Claim__c. Add a test 
       // method like this for each OccurrenceProcessing trigger:
@isTest
    private static void touchClaim() {
        Claim__c c = new Claim__c();
        c.Date_of_Loss__c = System.today();
        insert c;
    }
    private static void touchClaimTransaction() {
        Claim_Transaction__c c = new Claim_Transaction__c();
             // TODO: populate required fields here...
        insert c;
    }

}