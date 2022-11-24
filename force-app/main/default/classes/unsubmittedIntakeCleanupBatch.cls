/*===========================================================================
     Added to RK base RMIS product as  02/24/2015
   ===========================================================================*/
    
global class unsubmittedIntakeCleanupBatch implements Database.Batchable<sObject>{
    
  global String Query;
    
    global unsubmittedIntakeCleanupBatch(String q){
        Query = q;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(Query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        System.debug('Scope'+scope);
        delete scope;
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}