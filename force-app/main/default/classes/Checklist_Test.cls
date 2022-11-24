@isTest
private class Checklist_Test {
    @isTest
    static void testClaimChecklist_Controller()
    {
        Claim__c testclaim = new Claim__c(Date_of_Loss__c=System.today());
        insert testClaim;
        Checklist_Controller.getRecord(testClaim.Id,'Claim__c','ClaimChecklist');
    }
}