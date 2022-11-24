global class unsubmittedPatFeedbackCleanupSchedule implements Schedulable{

  global void execute(SchedulableContext SC) {
      String query = 'SELECT Id FROM Patient_Satisfaction__c WHERE IM_Delete_Flag__c = True';
        Database.executeBatch(new unsubmittedPortalRecordsCleanupBatchPF(query)); 
    }
    
}