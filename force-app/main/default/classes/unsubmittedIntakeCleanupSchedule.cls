/*===========================================================================
     Added to RK base RMIS product as  02/24/2015
   ===========================================================================*/
    
global class unsubmittedIntakeCleanupSchedule implements Schedulable{

  global void execute(SchedulableContext SC) {
      String query = 'SELECT Id FROM Intake__c WHERE IM_Delete_Flag__c = True';
        Database.executeBatch(new unsubmittedIntakeCleanupBatch(query)); 
    }
    
}