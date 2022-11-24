global class unsubmittedPortalRecordsCleanupBatchPF implements Database.Batchable<sObject>{
    
  global String Query;
 
    
    global unsubmittedPortalRecordsCleanupBatchPF(String q){
        Query = q;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
 
        return Database.getQueryLocator(Query);
    }
 
    global void execute(Database.BatchableContext BC, List<sObject> scope){
  
        
        
         for (sObject clm:scope)
        {
        
        
        clm.put('Status_of_Complaint__c','Void');
       
       }
       
         update scope;
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}