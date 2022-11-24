global class ScheduledWorkStatusUpdate implements Schedulable{
    
    // Objective: Refresh the Ids of all the claims each night to keep my workflows in place JDG 5/1/13
    
    // Constructor for the schedule. 
    global void execute(SchedulableContext SC) {
    ScheduledWorkStatusUpdateBatch batch = new ScheduledWorkStatusUpdateBatch();
    Database.executeBatch(batch);
    }
    
    static testMethod void testScheduledworkStatusUpdate() { 
      Test.startTest();
      SchedulableContext sc;
      ScheduledWorkStatusUpdate s = new ScheduledWorkStatusUpdate();
      s.execute(sc);
      Test.stopTest();
   }
}