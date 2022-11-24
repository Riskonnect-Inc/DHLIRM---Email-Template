global class ScheduledWorkStatusUpdateBatch implements Database.Batchable<SObject> {
  global Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator( [ SELECT Id FROM Work_Status__C ] );
  }
  
  global void execute(Database.BatchableContext context, List<SObject> scope) {
    update scope;
  }
  
  global void finish(Database.BatchableContext context) { }

/*  If you want to enable this test class, put an Id from a claim 4 lines below this line    
   @isTest
  static void testBatch() {
    Date d = Date.valueOf('2013-02-14');
    Work_Status__c ws = new Work_Status__c(Claim__c = 'a06E000000972Si',
                    Activity_Type__c = 'Record Only',
                    Activity_Type_Details__c = 'UE',
                    Return_to_Unrestricted_Work__c = d);
    insert ws;
    Work_Status__c modWs1 = [SELECT LastModifiedDate FROM Work_Status__c WHERE Id=:ws.Id];
    
    // Insert something to spin the server for a few seconds
    List<Integer> ints = new List<Integer>();
    for (Integer i = 0; i < 40000; ++i) {
      Integer ii = Integer.valueOf(Math.random() * 100);
      ints.add(ii);
    }
    
    for (Integer i = 0; i < 100; ++i) {
      ints.sort();
    }
    // End spin
    
    Test.startTest();
    ScheduledWorkStatusUpdateBatch batch = new ScheduledWorkStatusUpdateBatch();
    Id jobId = Database.executeBatch(batch);
    Test.stopTest();
    
    Work_Status__c modWs2 = [SELECT LastModifiedDate FROM Work_Status__c WHERE Id=:ws.Id];
    System.assert(modWs1.LastModifiedDate < modWs2.LastModifiedDate);
  } 
*/
}