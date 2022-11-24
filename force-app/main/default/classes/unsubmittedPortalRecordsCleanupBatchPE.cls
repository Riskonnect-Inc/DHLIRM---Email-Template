global class unsubmittedPortalRecordsCleanupBatchPE implements Database.Batchable<sObject>{
    
  global String Query;
 
    
    global unsubmittedPortalRecordsCleanupBatchPE(String q){
        Query = q;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
 
        return Database.getQueryLocator(Query);
    }
 
    global void execute(Database.BatchableContext BC, List<sObject> scope){
  
        
        
         for (sObject pe:scope)
        {
        
        pe.put('Patient_Event_Status__c','Void');
       
       }
       
         update scope;
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}