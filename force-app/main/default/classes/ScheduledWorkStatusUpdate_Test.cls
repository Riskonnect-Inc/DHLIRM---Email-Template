@isTest
public class ScheduledWorkStatusUpdate_Test{
    public static testmethod void scheduledWorkStatusUpdateTest() {
      Test.startTest();
        Claim__c testClaim = new Claim__c(Date_of_Loss__c=Date.today());
        insert testClaim;
        Work_Status__c testWorkStatus = new Work_Status__c(Claim__c=testClaim.id);
        insert testWorkStatus;
      SchedulableContext sc;
      ScheduledWorkStatusUpdate s = new ScheduledWorkStatusUpdate();
      s.execute(sc);
        
        ScheduledWorkStatusUpdateBatch newBatch = new ScheduledWorkStatusUpdateBatch();
        Database.BatchableContext bc;
        newBatch.execute(bc, new SObject[]{testWorkStatus});
      Test.stopTest();
    }
}