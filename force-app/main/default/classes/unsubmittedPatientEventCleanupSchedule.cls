global class unsubmittedPatientEventCleanupSchedule implements Schedulable{

  global void execute(SchedulableContext SC) {
      String query = 'SELECT Id FROM Patient_Event__c WHERE IM_Delete_Flag__c = True';
        Database.executeBatch(new unsubmittedPortalRecordsCleanupBatchPE(query)); 
    }
    
}